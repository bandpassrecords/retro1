import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import '../services/video_editor_service.dart';
import '../services/notification_service.dart';

class EditorScreen extends StatefulWidget {
  final DailyEntry entry;
  final bool isNewEntry;

  const EditorScreen({
    super.key,
    required this.entry,
    this.isNewEntry = false,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  int _selectedStartTimeMs = 0;
  bool _isDragging = false;

  /// Tracks the working video path (may change after crop).
  late String _workingPath;

  @override
  void initState() {
    super.initState();
    _workingPath = widget.entry.originalPath;
    _selectedStartTimeMs = widget.entry.startTimeMs;
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.file(File(_workingPath));
      await controller.initialize();
      _controller?.dispose();
      _controller = controller;

      // Clamp start time to valid range
      final totalMs = controller.value.duration.inMilliseconds;
      _selectedStartTimeMs =
          _selectedStartTimeMs.clamp(0, (totalMs - 1000).clamp(0, totalMs));

      setState(() => _isInitialized = true);
      await controller.seekTo(Duration(milliseconds: _selectedStartTimeMs));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingVideo(e.toString()))),
        );
      }
    }
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      // Snap the selected start to current position on pause
      setState(() {
        _selectedStartTimeMs = _controller!.value.position.inMilliseconds;
      });
    } else {
      _controller!.play();
    }
    setState(() {});
  }

  void _seekRelative(int deltaMs) {
    if (_controller == null || !_isInitialized) return;
    final totalMs = _controller!.value.duration.inMilliseconds;
    final current = _controller!.value.position.inMilliseconds;
    final target = (current + deltaMs).clamp(0, totalMs);
    _controller!.seekTo(Duration(milliseconds: target));
    setState(() => _selectedStartTimeMs = target);
  }

  Future<void> _cropVideo() async {
    if (!_isInitialized || _controller == null) return;

    final size = _controller!.value.size;
    final aspectRatio = _controller!.value.aspectRatio;

    // Only offer crop when the video isn't already 16:9
    if ((aspectRatio - 16 / 9).abs() < 0.05) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video is already 16:9')),
      );
      return;
    }

    // Generate thumbnail for the crop preview
    setState(() => _isProcessing = true);
    final thumbPath = await VideoEditorService.generateThumbnail(
      videoPath: _workingPath,
      timeMs: _selectedStartTimeMs,
    );
    setState(() => _isProcessing = false);

    if (!mounted) return;

    final position = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VideoCropSheet(
        aspectRatio: aspectRatio,
        thumbnailPath: thumbPath,
      ),
    );

    if (position == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final croppedPath = await VideoEditorService.cropVideoTo16x9(
        inputPath: _workingPath,
        videoWidth: size.width.toInt(),
        videoHeight: size.height.toInt(),
        position: position,
      );
      if (croppedPath != null) {
        _workingPath = croppedPath;
        _isInitialized = false;
        await _initializeVideo();
      } else if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorApplyingCrop('Failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorApplyingCrop(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editorChooseSecond)),
      body: Stack(
        children: [
          if (_isInitialized && _controller != null)
            Column(
              children: [
                // ── Video preview ──────────────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                ),

                // ── Controls ───────────────────────────────────────────────
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (_, value, __) {
                    final totalMs =
                        value.duration.inMilliseconds.toDouble();
                    final posMs = _isDragging
                        ? _selectedStartTimeMs.toDouble()
                        : value.position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, totalMs > 0 ? totalMs : 1.0);

                    // Keep selection in sync while playing (not dragging)
                    if (value.isPlaying && !_isDragging) {
                      _selectedStartTimeMs = posMs.toInt();
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Time display
                          Text(
                            '${_formatTime(posMs.toInt())}  /  ${_formatTime(totalMs.toInt())}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Seek slider
                          Slider(
                            value: posMs,
                            max: totalMs > 0 ? totalMs : 1.0,
                            onChangeStart: (_) {
                              setState(() => _isDragging = true);
                              _controller!.pause();
                            },
                            onChanged: (v) {
                              setState(
                                  () => _selectedStartTimeMs = v.toInt());
                              _controller!.seekTo(
                                  Duration(milliseconds: v.toInt()));
                            },
                            onChangeEnd: (v) {
                              setState(() {
                                _isDragging = false;
                                _selectedStartTimeMs = v.toInt();
                              });
                            },
                          ),

                          // Play controls row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // -1s
                              _SeekButton(
                                label: '-1s',
                                icon: Icons.skip_previous,
                                onTap: () => _seekRelative(-1000),
                              ),
                              const SizedBox(width: 8),
                              // Play / Pause
                              IconButton(
                                iconSize: 56,
                                icon: Icon(
                                  value.isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                ),
                                onPressed: _togglePlay,
                              ),
                              const SizedBox(width: 8),
                              // +1s
                              _SeekButton(
                                label: '+1s',
                                icon: Icons.skip_next,
                                onTap: () => _seekRelative(1000),
                              ),
                            ],
                          ),

                          // Selected start time hint
                          Text(
                            'Selected: ${_formatTime(_selectedStartTimeMs)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // ── Bottom action buttons ──────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      MediaQuery.of(context).padding.bottom + 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _cropVideo,
                          icon: const Icon(Icons.crop),
                          label: Text(l10n.cropVideo),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _isProcessing ? null : _saveEntry,
                          icon: const Icon(Icons.check),
                          label: Text(l10n.save),
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final ms = milliseconds % 1000;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}.'
        '${(ms ~/ 100)}';
  }

  Future<void> _saveEntry() async {
    if (_isProcessing) return;
    // Pause before saving
    _controller?.pause();
    setState(() => _isProcessing = true);

    try {
      final extractedPath = await VideoEditorService.extractOneSecond(
        inputPath: _workingPath,
        startTimeMs: _selectedStartTimeMs,
      );

      if (extractedPath == null) {
        throw Exception('Failed to extract 1 second from video');
      }

      final thumbnailPath = await VideoEditorService.generateThumbnail(
        videoPath: extractedPath,
        timeMs: 0,
      );

      final updatedEntry = DailyEntry(
        id: widget.entry.id,
        date: widget.entry.date,
        mediaType: widget.entry.mediaType,
        originalPath: extractedPath,
        startTimeMs: _selectedStartTimeMs,
        durationMs: 1000,
        caption: widget.entry.caption,
        createdAt: widget.entry.createdAt,
        timezone: widget.entry.timezone,
        thumbnailPath: thumbnailPath,
        hasAudio: widget.entry.hasAudio,
      );

      await HiveService.saveEntry(updatedEntry);
      await NotificationService.checkAndCancelNotificationsForDate(
          updatedEntry.date);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSaving(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

// ─── Seek button ──────────────────────────────────────────────────────────────

class _SeekButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SeekButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── Video crop bottom sheet ──────────────────────────────────────────────────

class _VideoCropSheet extends StatefulWidget {
  final double aspectRatio;
  final String? thumbnailPath;

  const _VideoCropSheet({required this.aspectRatio, this.thumbnailPath});

  @override
  State<_VideoCropSheet> createState() => _VideoCropSheetState();
}

class _VideoCropSheetState extends State<_VideoCropSheet> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPortrait = widget.aspectRatio < 16 / 9;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.cropTo16x9,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (widget.thumbnailPath != null)
            _CropPreview(
              thumbnailPath: widget.thumbnailPath!,
              videoAspectRatio: widget.aspectRatio,
              position: _position,
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(isPortrait ? 'Top' : 'Left',
                  style: const TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _position,
                  onChanged: (v) => setState(() => _position = v),
                ),
              ),
              Text(isPortrait ? 'Bottom' : 'Right',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _position),
                  child: Text(l10n.applyCrop),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CropPreview extends StatelessWidget {
  final String thumbnailPath;
  final double videoAspectRatio;
  final double position;

  const _CropPreview({
    required this.thumbnailPath,
    required this.videoAspectRatio,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final isPortrait = videoAspectRatio < 16 / 9;

    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final previewW = isPortrait ? maxW * 0.5 : maxW;
      final previewH = previewW / videoAspectRatio;

      double cropW, cropH, cropX, cropY;
      if (isPortrait) {
        cropW = previewW;
        cropH = previewW * 9 / 16;
        cropX = 0;
        cropY = (previewH - cropH) * position;
      } else {
        cropH = previewH;
        cropW = previewH * 16 / 9;
        cropX = (previewW - cropW) * position;
        cropY = 0;
      }

      return Center(
        child: SizedBox(
          width: previewW,
          height: previewH,
          child: Stack(
            children: [
              SizedBox(
                width: previewW,
                height: previewH,
                child: Image.file(File(thumbnailPath), fit: BoxFit.fill),
              ),
              Positioned.fill(
                child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.55)),
              ),
              // Crop window — show unmasked thumbnail within the box
              Positioned(
                left: cropX,
                top: cropY,
                width: cropW,
                height: cropH,
                child: ClipRect(
                  child: OverflowBox(
                    maxWidth: previewW,
                    maxHeight: previewH,
                    alignment: Alignment.topLeft,
                    child: Transform.translate(
                      offset: Offset(-cropX, -cropY),
                      child: Image.file(
                        File(thumbnailPath),
                        width: previewW,
                        height: previewH,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
              // White border around crop window
              Positioned(
                left: cropX,
                top: cropY,
                width: cropW,
                height: cropH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
