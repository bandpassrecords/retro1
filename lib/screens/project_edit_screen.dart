import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/free_project.dart';
import '../models/project_media_item.dart';
import '../models/daily_entry.dart';
import '../models/rendered_video.dart';
import '../services/hive_service.dart';
import '../services/media_service.dart';
import '../services/timeline_prefs.dart';
import '../services/video_editor_service.dart';
import '../services/video_generator_service.dart';
import 'custom_gallery_picker_screen.dart';
import 'photo_edit_screen.dart';
import 'video_edit_screen.dart';
import 'video_preview_screen.dart';
import 'video_trimmer_screen.dart';

class ProjectEditScreen extends StatefulWidget {
  final String projectId;

  const ProjectEditScreen({super.key, required this.projectId});

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  FreeProject? _project;
  List<ProjectMediaItem> _mediaItems = [];
  bool _isGeneratingVideo = false;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  void _loadProject() {
    setState(() {
      _project = HiveService.getProject(widget.projectId);
      if (_project != null) {
        _mediaItems = HiveService.getAllMediaItemsForProject(widget.projectId);
      }
    });
  }

  /// Pick and process media, then insert at [insertAtIndex].
  /// Pass [insertAtIndex] == _mediaItems.length to append at end.
  Future<void> _addMediaAt(int insertAtIndex) async {
    final l10n = AppLocalizations.of(context)!;

    // Same bottom-sheet picker as capture_screen
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(l10n.recordVideo),
              onTap: () => Navigator.pop(ctx, 'video_camera'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, 'photo_camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.browseGallery),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null || _project == null) return;

    try {
      String? filePath;
      String mediaType = 'photo';
      bool alreadyTrimmed = false;

      if (source == 'video_camera') {
        final f = await MediaService.captureVideo();
        if (f == null || !mounted) return;
        // Trim + crop before importing
        final trimmedPath = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => VideoTrimmerScreen(videoPath: f.path),
          ),
        );
        if (trimmedPath == null || !mounted) return;
        filePath = trimmedPath;
        mediaType = 'video';
        alreadyTrimmed = true;
      } else if (source == 'photo_camera') {
        final f = await MediaService.capturePhoto();
        filePath = f?.path;
        mediaType = 'photo';
      } else if (source == 'gallery') {
        final result = await _pickFromGallery();
        filePath = result?.path;
        mediaType = result?.mediaType ?? 'photo';
        alreadyTrimmed = result?.mediaType == 'video';
      }

      if (filePath == null) return;

      final copiedPath = await MediaService.copyToAppDirectory(filePath);
      final bool isPhoto = mediaType == 'photo';

      String? videoPathForPhoto;
      if (isPhoto) {
        videoPathForPhoto = await VideoEditorService.convertPhotoToVideo(
          photoPath: copiedPath,
        );
      }

      String? thumbnailPath;
      if (mediaType == 'video') {
        thumbnailPath = await VideoEditorService.generateThumbnail(
          videoPath: copiedPath,
          timeMs: 0,
        );
      } else {
        thumbnailPath = copiedPath;
      }

      final mediaItem = ProjectMediaItem(
        id: const Uuid().v4(),
        mediaType: mediaType,
        originalPath: copiedPath,
        editedPath: isPhoto ? videoPathForPhoto : null,
        startTimeMs: 0,
        durationMs: 1000,
        order: insertAtIndex,
        createdAt: DateTime.now(),
        thumbnailPath: thumbnailPath,
      );

      await HiveService.saveProjectMediaItem(mediaItem);

      final currentIds = List<String>.from(_project!.mediaItemIds);
      currentIds.insert(insertAtIndex, mediaItem.id);
      await HiveService.reorderProjectMediaItems(_project!.id, currentIds);

      _loadProject();

      if (mounted) {
        if (isPhoto) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoEditScreen(mediaItem: mediaItem),
            ),
          ).then((_) => _loadProject());
        } else if (!alreadyTrimmed) {
          // Fallback: video not yet trimmed — open editor
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoEditScreen(mediaItem: mediaItem),
            ),
          ).then((_) => _loadProject());
        }
        // Already trimmed videos need no further editing
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorAddingMedia(e.toString()))),
        );
      }
    }
  }

  Future<GalleryPickerResult?> _pickFromGallery() async {
    final l10n = AppLocalizations.of(context)!;
    if (MediaPickerPrefs.current == MediaPickerPrefs.systemPicker) {
      // System picker: ask photo or video first
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.videocam),
                title: Text(l10n.videoFromGallery),
                onTap: () => Navigator.pop(ctx, 'video'),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: Text(l10n.photoFromGallery),
                onTap: () => Navigator.pop(ctx, 'photo'),
              ),
            ],
          ),
        ),
      );
      if (choice == null) return null;
      try {
        if (choice == 'video') {
          final f = await MediaService.pickVideoFromGallery();
          if (f == null || !mounted) return null;
          final trimmedPath = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => VideoTrimmerScreen(videoPath: f.path),
            ),
          );
          if (trimmedPath == null) return null;
          return GalleryPickerResult(path: trimmedPath, mediaType: 'video');
        } else {
          final f = await MediaService.pickPhotoFromGallery();
          if (f == null) return null;
          return GalleryPickerResult(path: f.path, mediaType: 'photo');
        }
      } catch (_) {
        return null;
      }
    } else {
      // Custom in-app gallery picker
      if (!mounted) return null;
      return await Navigator.push<GalleryPickerResult>(
        context,
        MaterialPageRoute(builder: (_) => const CustomGalleryPickerScreen()),
      );
    }
  }

  void _showItemOptions(ProjectMediaItem item, int index) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Small drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.view),
              onTap: () {
                Navigator.pop(context);
                _openEditor(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text(l10n.addBefore),
              onTap: () {
                Navigator.pop(context);
                _addMediaAt(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text(l10n.addAfter),
              onTap: () {
                Navigator.pop(context);
                _addMediaAt(index + 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteMediaItem(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(ProjectMediaItem item) {
    if (item.mediaType == 'photo') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PhotoEditScreen(mediaItem: item)),
      ).then((_) => _loadProject());
    } else {
      final videoPath = item.editedPath ?? item.originalPath;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _SimpleVideoPlayerScreen(videoPath: videoPath),
        ),
      );
    }
  }

  Future<void> _deleteMediaItem(ProjectMediaItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteItem),
        content: Text(l10n.deleteItemConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && _project != null) {
      await HiveService.removeMediaItemFromProject(_project!.id, item.id);
      _loadProject();
    }
  }

  Future<void> _renderProjectVideo() async {
    if (_mediaItems.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renderProjectVideo),
        content: Text(l10n.renderProjectVideoConfirm(_mediaItems.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.render),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isGeneratingVideo = true);

    try {
      final videoPath = await VideoGeneratorService.generateProjectVideo(
        mediaItems: _mediaItems,
        projectName: _project!.name,
      );

      if (mounted) {
        setState(() => _isGeneratingVideo = false);

        if (videoPath != null) {
          final thumbnailPath = await VideoEditorService.generateThumbnail(
            videoPath: videoPath,
            timeMs: 0,
          );
          final duration = await VideoEditorService.getVideoDuration(videoPath);
          final renderedVideo = RenderedVideo(
            id: const Uuid().v4(),
            videoPath: videoPath,
            title: _project!.name,
            type: 'project',
            createdAt: DateTime.now(),
            thumbnailPath: thumbnailPath,
            durationSeconds: duration?.inSeconds ?? 0,
            projectId: _project!.id,
            metadata: {
              'projectName': _project!.name,
              'mediaItemsCount': _mediaItems.length,
            },
          );
          await HiveService.saveRenderedVideo(renderedVideo);

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(
                entry: DailyEntry(
                  id: const Uuid().v4(),
                  date: DateTime.now(),
                  mediaType: 'video',
                  originalPath: videoPath,
                  startTimeMs: 0,
                  durationMs: 1000,
                  createdAt: DateTime.now(),
                  timezone: DateTime.now().timeZoneName,
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneratingVideo('Unknown error'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingVideo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.errorGeneratingVideo(e.toString()))),
        );
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (_project == null) return;
    final items = List<ProjectMediaItem>.from(_mediaItems);
    final item = items.removeAt(oldIndex);
    final insertAt = newIndex.clamp(0, items.length);
    items.insert(insertAt, item);
    setState(() => _mediaItems = items);
    await HiveService.reorderProjectMediaItems(
      _project!.id,
      items.map((e) => e.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_project!.name),
      ),
      body: _ProjectDragGrid(
        items: _mediaItems,
        onTap: (item, index) => _showItemOptions(item, index),
        onAddTap: () => _addMediaAt(_mediaItems.length),
        onReorder: _onReorder,
      ),
      bottomNavigationBar: _mediaItems.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingVideo ? null : _renderProjectVideo,
                    icon: _isGeneratingVideo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.movie_creation),
                    label: Text(l10n.renderProjectVideo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ── Single media cell ──────────────────────────────────────────────────────

class _ProjectMediaCell extends StatelessWidget {
  final ProjectMediaItem item;
  final int index;
  final VoidCallback onTap;

  const _ProjectMediaCell({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildThumb(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              color: Colors.black.withValues(alpha: 0.55),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.mediaType == 'video' ? Icons.play_arrow : Icons.image,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb() {
    final path = item.thumbnailPath;
    if (path == null) return _placeholder();
    final file = File(path);
    if (!file.existsSync()) return _placeholder();
    final ext = path.toLowerCase();
    final isImage = ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp');
    if (!isImage) return _placeholder();
    return Image.file(
      file,
      fit: BoxFit.cover,
      cacheWidth: 300,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.grey[900]!,
      child: Center(
        child: Icon(
          item.mediaType == 'video' ? Icons.videocam : Icons.camera_alt,
          color: Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }
}

// ── Add placeholder cell ────────────────────────────────────────────────────

class _AddPlaceholderCell extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPlaceholderCell({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: Colors.grey[900]!,
        child: Center(
          child: Icon(Icons.add, color: Colors.grey[600], size: 28),
        ),
      ),
    );
  }
}

// ── Drag-and-drop grid ──────────────────────────────────────────────────────

class _ProjectDragGrid extends StatefulWidget {
  final List<ProjectMediaItem> items;
  final void Function(ProjectMediaItem item, int index) onTap;
  final VoidCallback onAddTap;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _ProjectDragGrid({
    required this.items,
    required this.onTap,
    required this.onAddTap,
    required this.onReorder,
  });

  @override
  State<_ProjectDragGrid> createState() => _ProjectDragGridState();
}

class _ProjectDragGridState extends State<_ProjectDragGrid> {
  int? _draggingIndex;
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length + 1; // +1 for "+" cell

    return ValueListenableBuilder<String?>(
      valueListenable: ThumbnailSizePrefs.notifier,
      builder: (context, _, __) {
        final cols = ThumbnailSizePrefs.crossAxisCount;
        final cellSize = MediaQuery.of(context).size.width / cols - 1;
        return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // "+" placeholder — not draggable
        if (index == widget.items.length) {
          return _AddPlaceholderCell(
            key: const ValueKey('__add__'),
            onTap: widget.onAddTap,
          );
        }

        final item = widget.items[index];
        final isDragging = _draggingIndex == index;
        final isHovered = _hoverIndex == index && _draggingIndex != null && _draggingIndex != index;

        return DragTarget<int>(
          key: ValueKey(item.id),
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) {
            setState(() => _hoverIndex = null);
            widget.onReorder(details.data, index);
          },
          onMove: (_) => setState(() => _hoverIndex = index),
          onLeave: (_) => setState(() => _hoverIndex = null),
          builder: (context, candidateData, rejectedData) {
            return LongPressDraggable<int>(
              data: index,
              delay: const Duration(milliseconds: 300),
              onDragStarted: () => setState(() => _draggingIndex = index),
              onDragEnd: (_) => setState(() {
                _draggingIndex = null;
                _hoverIndex = null;
              }),
              onDraggableCanceled: (_, __) => setState(() {
                _draggingIndex = null;
                _hoverIndex = null;
              }),
              feedback: SizedBox(
                width: cellSize,
                height: cellSize,
                child: Opacity(
                  opacity: 0.85,
                  child: _ProjectMediaCell(item: item, index: index, onTap: () {}),
                ),
              ),
              childWhenDragging: ColoredBox(
                color: Colors.grey[850]!,
                child: Center(
                  child: Icon(Icons.drag_indicator, color: Colors.grey[700], size: 24),
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: isHovered
                    ? BoxDecoration(
                        border: Border.all(color: Colors.deepPurpleAccent, width: 2),
                      )
                    : null,
                child: Opacity(
                  opacity: isDragging ? 0.4 : 1.0,
                  child: _ProjectMediaCell(
                    key: ValueKey('cell_${item.id}'),
                    item: item,
                    index: index,
                    onTap: () => widget.onTap(item, index),
                  ),
                ),
              ),
            );
          },
        );
      },
        );
      },
    );
  }
}

// ── Simple video player screen ───────────────────────────────────────────────

class _SimpleVideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  const _SimpleVideoPlayerScreen({required this.videoPath});

  @override
  State<_SimpleVideoPlayerScreen> createState() =>
      _SimpleVideoPlayerScreenState();
}

class _SimpleVideoPlayerScreenState extends State<_SimpleVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.setLooping(true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _initialized
            ? GestureDetector(
                onTap: () => setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                }),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller,
                      builder: (_, v, __) => AnimatedOpacity(
                        opacity: v.isPlaying ? 0 : 0.7,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.play_circle_fill,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
