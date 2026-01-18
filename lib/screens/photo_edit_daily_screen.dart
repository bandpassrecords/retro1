import 'dart:io';
import 'package:flutter/material.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import '../services/image_editor_service.dart';

class PhotoEditDailyScreen extends StatefulWidget {
  final DailyEntry entry;

  const PhotoEditDailyScreen({super.key, required this.entry});

  @override
  State<PhotoEditDailyScreen> createState() => _PhotoEditDailyScreenState();
}

class _PhotoEditDailyScreenState extends State<PhotoEditDailyScreen> {
  late DailyEntry _entry;
  bool _isProcessing = false;
  int _currentRotation = 0;
  String _currentAnimation = 'none';
  String? _currentFilter = 'none';

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    // Para DailyEntry, não temos campos de edição, então vamos usar variáveis locais
    _currentRotation = 0;
    _currentAnimation = 'none';
    _currentFilter = 'none';
  }

  Future<void> _rotateImage(int degrees) async {
    setState(() {
      _isProcessing = true;
      _currentRotation = degrees;
    });

    try {
      // Usar thumbnailPath se disponível (foto original), senão usar originalPath
      final imagePath = _entry.thumbnailPath ?? _entry.originalPath;
      final rotatedPath = await ImageEditorService.rotateImage(
        inputPath: imagePath,
        degrees: degrees,
      );

      if (rotatedPath != null) {
        setState(() {
          _entry = DailyEntry(
            id: _entry.id,
            date: _entry.date,
            mediaType: _entry.mediaType,
            originalPath: rotatedPath,
            startTimeMs: _entry.startTimeMs,
            durationMs: _entry.durationMs,
            caption: _entry.caption,
            createdAt: _entry.createdAt,
            timezone: _entry.timezone,
            thumbnailPath: rotatedPath, // Usar a imagem rotacionada como thumbnail
            hasAudio: _entry.hasAudio,
          );
        });
        await HiveService.saveEntry(_entry);
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
      // Usar thumbnailPath se disponível (foto original), senão usar originalPath
      final imagePath = _entry.thumbnailPath ?? _entry.originalPath;
      final filteredPath = await ImageEditorService.applyFilter(
        inputPath: imagePath,
        filterType: filter,
      );

      if (filteredPath != null) {
        // Atualizar thumbnailPath com a imagem editada
        // Manter originalPath como está (pode ser o vídeo convertido)
        setState(() {
          _entry = DailyEntry(
            id: _entry.id,
            date: _entry.date,
            mediaType: _entry.mediaType,
            originalPath: _entry.originalPath, // Manter o caminho original (vídeo)
            startTimeMs: _entry.startTimeMs,
            durationMs: _entry.durationMs,
            caption: _entry.caption,
            createdAt: _entry.createdAt,
            timezone: _entry.timezone,
            thumbnailPath: filteredPath, // Atualizar com a imagem editada
            hasAudio: _entry.hasAudio,
          );
        });
        await HiveService.saveEntry(_entry);
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

  @override
  Widget build(BuildContext context) {
    // Usar thumbnailPath se disponível (foto original), senão usar originalPath
    final imagePath = _entry.thumbnailPath ?? _entry.originalPath;

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
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                          );
                        },
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
      onSelected: (_) {
        setState(() {
          _currentAnimation = type;
        });
        // TODO: Aplicar animação quando converter foto para vídeo
      },
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
