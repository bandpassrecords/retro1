import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/free_project.dart';
import '../models/project_media_item.dart';
import '../services/hive_service.dart';
import '../services/media_service.dart';
import 'photo_edit_screen.dart';
import 'video_edit_screen.dart';

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

  Future<void> _addMedia() async {
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'photo_camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo from Gallery'),
              onTap: () => Navigator.pop(context, 'photo_gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () => Navigator.pop(context, 'video_camera'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Video from Gallery'),
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

      if (file != null) {
        // Copiar arquivo para o diretório do app
        final copiedPath = await MediaService.copyToAppDirectory(file.path);

        // Criar media item
        final mediaItem = ProjectMediaItem(
          id: const Uuid().v4(),
          mediaType: mediaType,
          originalPath: copiedPath,
          order: _mediaItems.length,
          createdAt: DateTime.now(),
        );

        await HiveService.saveProjectMediaItem(mediaItem);
        await HiveService.addMediaItemToProject(_project!.id, mediaItem.id);

        _loadProject();

        // Abrir editor baseado no tipo
        if (mounted) {
          if (mediaType == 'photo') {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding media: $e')),
        );
      }
    }
  }

  Future<void> _deleteMediaItem(ProjectMediaItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _project != null) {
      await HiveService.removeMediaItemFromProject(_project!.id, item.id);
      _loadProject();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_project!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMedia,
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
                  const Text(
                    'No media items yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addMedia,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Media'),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              itemCount: _mediaItems.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final item = _mediaItems.removeAt(oldIndex);
                _mediaItems.insert(newIndex, item);
                // Atualizar ordem
                final newOrder = _mediaItems.map((e) => e.id).toList();
                await HiveService.reorderProjectMediaItems(_project!.id, newOrder);
                setState(() {});
              },
              itemBuilder: (context, index) {
                final item = _mediaItems[index];
                return ListTile(
                  key: ValueKey(item.id),
                  leading: item.thumbnailPath != null
                      ? Image.file(File(item.thumbnailPath!), width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                  title: Text('Item ${index + 1}'),
                  subtitle: Text('${item.mediaType} • ${item.hasEdits ? "Edited" : "Original"}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteMediaItem(item),
                  ),
                  onTap: () {
                    if (item.mediaType == 'photo') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoEditScreen(mediaItem: item),
                        ),
                      ).then((_) => _loadProject());
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoEditScreen(mediaItem: item),
                        ),
                      ).then((_) => _loadProject());
                    }
                  },
                );
              },
            ),
    );
  }
}
