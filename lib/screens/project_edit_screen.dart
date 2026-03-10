import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/free_project.dart';
import '../models/project_media_item.dart';
import '../models/daily_entry.dart';
import '../models/rendered_video.dart';
import '../services/hive_service.dart';
import '../services/media_service.dart';
import '../services/video_editor_service.dart';
import '../services/video_generator_service.dart';
import 'photo_edit_screen.dart';
import 'video_edit_screen.dart';
import 'video_preview_screen.dart';

class ProjectEditScreen extends StatefulWidget {
  final String projectId;

  const ProjectEditScreen({super.key, required this.projectId});

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  FreeProject? _project;
  List<ProjectMediaItem> _mediaItems = [];
  final ImagePicker _picker = ImagePicker();
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
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addMedia),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, 'photo_camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.photoFromGallery),
              onTap: () => Navigator.pop(context, 'photo_gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(l10n.recordVideo),
              onTap: () => Navigator.pop(context, 'video_camera'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: Text(l10n.videoFromGallery),
              onTap: () => Navigator.pop(context, 'video_gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null || _project == null) return;

    try {
      XFile? file;
      String mediaType = 'photo';

      switch (source) {
        case 'photo_camera':
          file = await _picker.pickImage(source: ImageSource.camera);
          mediaType = 'photo';
          break;
        case 'photo_gallery':
          file = await _picker.pickImage(source: ImageSource.gallery);
          mediaType = 'photo';
          break;
        case 'video_camera':
          file = await _picker.pickVideo(source: ImageSource.camera);
          mediaType = 'video';
          break;
        case 'video_gallery':
          file = await _picker.pickVideo(source: ImageSource.gallery);
          mediaType = 'video';
          break;
      }

      if (file == null) return;

      final copiedPath = await MediaService.copyToAppDirectory(file.path);
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
        originalPath: isPhoto ? copiedPath : copiedPath,
        editedPath: isPhoto ? videoPathForPhoto : null,
        startTimeMs: 0,
        durationMs: 1000,
        order: insertAtIndex,
        createdAt: DateTime.now(),
        thumbnailPath: thumbnailPath,
      );

      // Insert at the requested position and shift later items
      await HiveService.saveProjectMediaItem(mediaItem);

      // Add to project and reorder so new item ends up at insertAtIndex
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
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoEditScreen(mediaItem: mediaItem),
            ),
          ).then((_) => _loadProject());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorAddingMedia(e.toString()))),
        );
      }
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
              title: const Text('Add before'),
              onTap: () {
                Navigator.pop(context);
                _addMediaAt(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Add after'),
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VideoEditScreen(mediaItem: item)),
      ).then((_) => _loadProject());
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_project == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_project!.name),
        actions: [
          if (_mediaItems.isNotEmpty)
            IconButton(
              icon: _isGeneratingVideo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.movie_creation),
              onPressed: _isGeneratingVideo ? null : _renderProjectVideo,
              tooltip: l10n.renderProjectVideo,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addMediaAt(_mediaItems.length),
            tooltip: l10n.addMedia,
          ),
        ],
      ),
      body: _mediaItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(l10n.noMediaItemsYet,
                      style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _addMediaAt(0),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addMedia),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                childAspectRatio: 1,
              ),
              itemCount: _mediaItems.length,
              itemBuilder: (context, index) {
                final item = _mediaItems[index];
                return _ProjectMediaCell(
                  item: item,
                  index: index,
                  onTap: () => _showItemOptions(item, index),
                );
              },
            ),
    );
  }
}

// ── Single media cell ──────────────────────────────────────────────────────

class _ProjectMediaCell extends StatelessWidget {
  final ProjectMediaItem item;
  final int index;
  final VoidCallback onTap;

  const _ProjectMediaCell({
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
