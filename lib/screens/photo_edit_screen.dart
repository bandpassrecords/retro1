import 'dart:io';
import 'package:flutter/material.dart';
import '../models/project_media_item.dart';
import '../services/hive_service.dart';
import '../services/image_editor_service.dart';

class PhotoEditScreen extends StatefulWidget {
  final ProjectMediaItem mediaItem;

  const PhotoEditScreen({super.key, required this.mediaItem});

  @override
  State<PhotoEditScreen> createState() => _PhotoEditScreenState();
}

class _PhotoEditScreenState extends State<PhotoEditScreen> {
  late ProjectMediaItem _item;
  bool _isProcessing = false;
  int _currentRotation = 0;
  String _currentAnimation = 'none';
  String? _currentFilter = 'none';

  @override
  void initState() {
    super.initState();
    _item = widget.mediaItem;
    _currentRotation = _item.rotation;
    _currentAnimation = _item.animationType ?? 'none';
    _currentFilter = _item.filter ?? 'none';
  }

  Future<void> _rotateImage(int degrees) async {
    setState(() {
      _isProcessing = true;
      _currentRotation = degrees;
    });

    try {
      final rotatedPath = await ImageEditorService.rotateImage(
        inputPath: _item.editedPath ?? _item.originalPath,
        degrees: degrees,
      );

      if (rotatedPath != null) {
        setState(() {
          _item.editedPath = rotatedPath;
          _item.rotation = degrees;
        });
        await HiveService.saveProjectMediaItem(_item);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rotating image: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _applyFilter(String filter) async {
    setState(() {
      _isProcessing = true;
      _currentFilter = filter;
    });

    try {
      final filteredPath = await ImageEditorService.applyFilter(
        inputPath: _item.editedPath ?? _item.originalPath,
        filterType: filter,
      );

      if (filteredPath != null) {
        setState(() {
          _item.editedPath = filteredPath;
          _item.filter = filter;
        });
        await HiveService.saveProjectMediaItem(_item);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying filter: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _setAnimation(String animationType) async {
    setState(() {
      _currentAnimation = animationType;
      _item.animationType = animationType;
    });
    await HiveService.saveProjectMediaItem(_item);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _item.editedPath ?? _item.originalPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: InteractiveViewer(
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Rotação
                _buildSection(
                  title: 'Rotation',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRotationButton(0, Icons.rotate_right),
                      _buildRotationButton(90, Icons.rotate_right),
                      _buildRotationButton(180, Icons.rotate_right),
                      _buildRotationButton(270, Icons.rotate_right),
                    ],
                  ),
                ),
                // Animações
                _buildSection(
                  title: 'Animation',
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildAnimationButton('none', 'None'),
                      _buildAnimationButton('zoom', 'Zoom'),
                      _buildAnimationButton('pan', 'Pan'),
                      _buildAnimationButton('ken_burns', 'Ken Burns'),
                      _buildAnimationButton('fade', 'Fade'),
                    ],
                  ),
                ),
                // Filtros
                _buildSection(
                  title: 'Filters',
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterButton('none', 'Original'),
                      _buildFilterButton('vintage', 'Vintage'),
                      _buildFilterButton('blackwhite', 'B&W'),
                      _buildFilterButton('sepia', 'Sepia'),
                      _buildFilterButton('bright', 'Bright'),
                      _buildFilterButton('warm', 'Warm'),
                      _buildFilterButton('cool', 'Cool'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildRotationButton(int degrees, IconData icon) {
    final isSelected = _currentRotation == degrees;
    return IconButton(
      icon: Icon(icon),
      onPressed: () => _rotateImage(degrees),
      color: isSelected ? Theme.of(context).colorScheme.primary : null,
      tooltip: '${degrees}°',
    );
  }

  Widget _buildAnimationButton(String type, String label) {
    final isSelected = _currentAnimation == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setAnimation(type),
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyFilter(filter),
    );
  }
}
