import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import 'photo_edit_daily_screen.dart';

class VideoPreviewScreen extends StatefulWidget {
  final DailyEntry entry;

  /// When provided, enables swipe left/right to navigate between entries.
  final List<DailyEntry>? allEntries;
  final int initialIndex;

  /// Called when the user taps Replace for the currently displayed entry.
  final void Function(DailyEntry entry)? onReplaceEntry;

  /// Called after the user confirms deletion of the currently displayed entry.
  final Future<void> Function(DailyEntry entry)? onDeleteEntry;

  const VideoPreviewScreen({
    super.key,
    required this.entry,
    this.allEntries,
    this.initialIndex = 0,
    this.onReplaceEntry,
    this.onDeleteEntry,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen>
    with SingleTickerProviderStateMixin {
  late List<DailyEntry> _entries;
  late int _currentIndex;

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPhoto = false;

  // Swipe animation
  late AnimationController _slideController;
  double _dragOffset = 0.0;
  bool _isAnimating = false;

  DailyEntry get _current => _entries[_currentIndex];

  @override
  void initState() {
    super.initState();
    _entries = widget.allEntries ?? [widget.entry];
    _currentIndex = widget.initialIndex.clamp(0, _entries.length - 1);
    _slideController = AnimationController(vsync: this);
    _slideController.addListener(_onSlideControllerUpdate);
    _loadEntry();
  }

  void _onSlideControllerUpdate() => setState(() {});

  void _loadEntry() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isPhoto = _current.mediaType == 'photo';

    if (_isPhoto) {
      setState(() => _isInitialized = true);
    } else {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.file(File(_current.originalPath));
      await controller.initialize();
      controller.setLooping(true);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.errorLoadingVideo(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    _slideController.removeListener(_onSlideControllerUpdate);
    _slideController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    final atStart = _currentIndex == 0;
    final atEnd = _currentIndex == _entries.length - 1;
    var delta = details.delta.dy;
    // Add resistance when swiping past the first or last entry
    if ((atEnd && delta < 0) || (atStart && delta > 0)) {
      delta *= 0.2;
    }
    setState(() => _dragOffset += delta);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final velocity = details.primaryVelocity ?? 0;
    final screenH = MediaQuery.sizeOf(context).height;
    final threshold = screenH * 0.25;

    final goNext = (velocity < -500 || _dragOffset < -threshold) &&
        _currentIndex < _entries.length - 1;
    final goPrev = (velocity > 500 || _dragOffset > threshold) &&
        _currentIndex > 0;

    if (goNext) {
      _completeSlide(goNext: true);
    } else if (goPrev) {
      _completeSlide(goNext: false);
    } else {
      _snapBack();
    }
  }

  void _completeSlide({required bool goNext}) {
    _isAnimating = true;
    final screenH = MediaQuery.sizeOf(context).height;
    final slideOutTarget = goNext ? -screenH : screenH;

    // Phase 1: slide current content off screen
    _slideController.duration = const Duration(milliseconds: 180);
    final phase1 = Tween<double>(begin: _dragOffset, end: slideOutTarget)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeIn));

    void p1Listener() => _dragOffset = phase1.value;
    _slideController.addListener(p1Listener);
    _slideController.forward(from: 0).whenComplete(() {
      _slideController.removeListener(p1Listener);

      // Load new entry; position off screen on the opposite side
      setState(() {
        if (goNext) _currentIndex++;
        else _currentIndex--;
        _dragOffset = -slideOutTarget;
      });
      _loadEntry();

      // Phase 2: slide new content in from opposite side
      _slideController.duration = const Duration(milliseconds: 250);
      final phase2 = Tween<double>(begin: _dragOffset, end: 0.0)
          .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

      void p2Listener() => _dragOffset = phase2.value;
      _slideController.addListener(p2Listener);
      _slideController.forward(from: 0).whenComplete(() {
        _slideController.removeListener(p2Listener);
        setState(() {
          _dragOffset = 0.0;
          _isAnimating = false;
        });
      });
    });
  }

  void _snapBack() {
    _isAnimating = true;
    _slideController.duration = const Duration(milliseconds: 350);
    final anim = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    void listener() => _dragOffset = anim.value;
    _slideController.addListener(listener);
    _slideController.forward(from: 0).whenComplete(() {
      _slideController.removeListener(listener);
      setState(() {
        _dragOffset = 0.0;
        _isAnimating = false;
      });
    });
  }

  Future<void> _replace() async {
    final cb = widget.onReplaceEntry;
    if (cb != null) {
      Navigator.pop(context);
      cb(_current);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(l10n.confirmDeletionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final cb = widget.onDeleteEntry;
    if (cb != null) await cb(_current);

    if (!mounted) return;

    // If there are adjacent entries, move to one; otherwise pop.
    if (_entries.length > 1) {
      final entry = _current;
      setState(() {
        _entries = List.of(_entries)..remove(entry);
        _currentIndex = _currentIndex.clamp(0, _entries.length - 1);
      });
      _loadEntry();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat('dd/MM/yyyy', locale.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text(dateFormat.format(_current.date)),
        actions: [
          if (_current.mediaType == 'video')
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareVideo,
              tooltip: l10n.share,
            ),
          if (_current.mediaType == 'photo')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PhotoEditDailyScreen(entry: _current),
                  ),
                ).then((_) {
                  // Reload entry from storage in case it was edited
                  final updated = HiveService.getEntry(_current.id);
                  if (updated != null && mounted) {
                    setState(() {
                      _entries = List.of(_entries)..[_currentIndex] = updated;
                    });
                  }
                });
              },
            ),
          // 3-dot menu: Replace + Delete
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'replace') _replace();
              if (value == 'delete') _delete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'replace',
                child: Row(children: [
                  const Icon(Icons.swap_horiz),
                  const SizedBox(width: 12),
                  Text(l10n.replace),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(l10n.delete,
                      style: const TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragUpdate: _isAnimating ? null : _onVerticalDragUpdate,
        onVerticalDragEnd: _isAnimating ? null : _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: _isInitialized
            ? Column(
                children: [
                  Expanded(
                    child: Center(
                      child: _isPhoto
                          ? _buildPhotoPreview()
                          : _buildVideoPreview(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMMd(locale.toString())
                              .format(_current.date),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_current.caption != null &&
                            _current.caption!.isNotEmpty)
                          Text(_current.caption!,
                              style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _current.mediaType == 'video'
                                  ? Icons.videocam
                                  : Icons.camera_alt,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _current.mediaType == 'video'
                                  ? l10n.video
                                  : l10n.photo,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (_entries.length > 1) ...[
                              const Spacer(),
                              Text(
                                '${_currentIndex + 1} / ${_entries.length}',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    final imagePath = _current.thumbnailPath ?? _current.originalPath;
    final imageFile = File(imagePath);

    if (!imageFile.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.imageNotFound,
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final ext = imagePath.toLowerCase();
    final isImage = ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.bmp') ||
        ext.endsWith('.webp');

    if (!isImage) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.errorLoadingImage,
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.file(imageFile, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64)),
    );
  }

  Widget _buildVideoPreview() {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: _togglePlayPause,
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller!),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (_, value, __) => value.isPlaying
                  ? const SizedBox.shrink()
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_circle_filled,
                          size: 64, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareVideo() async {
    final path = _current.originalPath;
    if (!File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .errorSharing('Video file not found'))),
        );
      }
      return;
    }
    try {
      final l10n = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context);
      final dateFormat = DateFormat('dd/MM/yyyy', locale.toString());
      await Share.shareXFiles(
        [XFile(path)],
        text: '${l10n.appTitle} - ${dateFormat.format(_current.date)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.errorSharing(e.toString()))),
        );
      }
    }
  }
}
