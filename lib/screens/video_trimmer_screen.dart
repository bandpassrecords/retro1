import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../services/video_editor_service.dart';

/// Full-screen trimmer with a scrollable filmstrip.
/// The user scrolls the thumbnail strip to pick a 1-second window.
/// Pops with the path of the extracted 1-second clip, or null if cancelled.
class VideoTrimmerScreen extends StatefulWidget {
  final String videoPath;
  const VideoTrimmerScreen({super.key, required this.videoPath});

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  // ── Video player ───────────────────────────────────────────────────────────
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;

  // ── Trim state ─────────────────────────────────────────────────────────────
  int _selectedStartMs = 0;
  int _totalDurationMs = 0;

  // ── Filmstrip ──────────────────────────────────────────────────────────────
  final ScrollController _filmscroll = ScrollController();
  final Map<int, String?> _thumbs = {}; // secondIndex → file path (null = loading)
  final Set<int> _requested = {};

  static const double _cellW = 56.0;
  static const double _stripH = 60.0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _filmscroll.addListener(_onFilmscrollChanged);
    _initVideo();
  }

  @override
  void dispose() {
    _filmscroll.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.file(File(widget.videoPath));
      await ctrl.initialize();
      _controller = ctrl;
      _totalDurationMs = ctrl.value.duration.inMilliseconds;
      if (!mounted) return;
      setState(() => _isInitialized = true);
      ctrl.play();
      // Pre-load first batch of thumbnails
      for (int i = 0; i < 10; i++) {
        _loadThumb(i);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  // ── Thumbnail loading ──────────────────────────────────────────────────────

  void _loadThumb(int sec) {
    if (sec < 0 || _requested.contains(sec)) return;
    final maxSec = (_totalDurationMs / 1000).ceil();
    if (sec >= maxSec) return;
    _requested.add(sec);

    VideoEditorService.generateThumbnail(
      videoPath: widget.videoPath,
      timeMs: sec * 1000,
    ).then((path) {
      if (mounted) setState(() => _thumbs[sec] = path);
    });
  }

  // ── Filmstrip scroll ───────────────────────────────────────────────────────
  //
  // With symmetric horizontal padding = (screenW - cellW) / 2,
  // the center of cell[k] is on-screen when scrollOffset == k * cellW.
  // So: selectedSec = (scrollOffset / cellW).round()

  void _onFilmscrollChanged() {
    final offset = _filmscroll.offset.clamp(0.0, double.infinity);
    final rawSec = (offset / _cellW).round();
    final maxSec = ((_totalDurationMs - 1000) / 1000).floor().clamp(0, 999999);
    final selectedSec = rawSec.clamp(0, maxSec);
    final newStartMs = selectedSec * 1000;

    if (newStartMs != _selectedStartMs) {
      _selectedStartMs = newStartMs;
      _controller?.seekTo(Duration(milliseconds: newStartMs));

      // Lazily load thumbnails around the visible area
      for (int i = selectedSec - 2; i <= selectedSec + 6; i++) {
        _loadThumb(i);
      }

      if (mounted) setState(() {});
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _controller!.value.isPlaying
          ? _controller!.pause()
          : _controller!.play();
    });
  }

  Future<void> _trimAndUse() async {
    if (_isProcessing) return;
    _controller?.pause();
    setState(() => _isProcessing = true);
    try {
      final path = await VideoEditorService.extractOneSecond(
        inputPath: widget.videoPath,
        startTimeMs: _selectedStartMs,
      );
      if (path == null) throw Exception('Failed to trim video');
      if (mounted) Navigator.pop(context, path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error trimming: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.editorChooseSecond),
      ),
      body: Stack(
        children: [
          if (_isInitialized && _controller != null)
            Column(
              children: [
                // ── Video preview ────────────────────────────────────────
                Expanded(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                        // Play/pause icon overlay
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller!,
                          builder: (_, v, __) => AnimatedOpacity(
                            opacity: v.isPlaying ? 0 : 0.7,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.play_circle_fill,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Time range label ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    '${_fmt(_selectedStartMs)}  →  ${_fmt(_selectedStartMs + 1000)}'
                    '   /   ${_fmt(_totalDurationMs)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // ── Filmstrip ────────────────────────────────────────────
                _buildFilmstrip(context),

                const SizedBox(height: 16),

                // ── Save button ──────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _trimAndUse,
                    icon: const Icon(Icons.content_cut),
                    label: Text(l10n.save),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
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

  // ── Filmstrip widget ───────────────────────────────────────────────────────

  Widget _buildFilmstrip(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Pad both sides so the first/last cell can be centered under the indicator.
    final sidePad = (screenW - _cellW) / 2;
    final totalSecs = (_totalDurationMs / 1000).ceil().clamp(1, 999999);

    return SizedBox(
      height: _stripH + 16, // 16 for the indicator border overflow
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Thumbnail scroll ───────────────────────────────────────────
          ListView.builder(
            controller: _filmscroll,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            itemCount: totalSecs,
            itemBuilder: (_, i) {
              _loadThumb(i); // lazy load when cell enters the viewport
              final thumb = _thumbs[i];

              return SizedBox(
                width: _cellW,
                height: _stripH,
                child: thumb != null
                    ? Image.file(
                        File(thumb),
                        fit: BoxFit.cover,
                        width: _cellW,
                        height: _stripH,
                        gaplessPlayback: true,
                      )
                    : const ColoredBox(
                        color: Color(0xFF262626),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),

          // ── Fixed 1-second selection indicator ────────────────────────
          IgnorePointer(
            child: Container(
              width: _cellW,
              height: _stripH + 8,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // ── Left / right gradient fade ─────────────────────────────────
          IgnorePointer(
            child: Row(
              children: [
                _buildFade(fromLeft: true, width: sidePad * 0.6),
                const Spacer(),
                _buildFade(fromLeft: false, width: sidePad * 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFade({required bool fromLeft, required double width}) {
    return SizedBox(
      width: width,
      height: _stripH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
            end: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
            colors: [Colors.black, Colors.transparent],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    final frac = ms % 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}.'
        '${frac ~/ 100}';
  }
}
