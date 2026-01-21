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

  Future<void> _addMedia() async {
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

      if (file != null) {
        // Copiar arquivo para o diretório do app
        final copiedPath = await MediaService.copyToAppDirectory(file.path);

        // Processar mídia ANTES de criar o media item (igual ao calendário)
        String finalPath = copiedPath;
        String? videoPathForPhoto; // Armazenar vídeo convertido separadamente para fotos
        bool isPhoto = mediaType == 'photo';
        
        if (isPhoto) {
          // Converter foto para vídeo de 1 segundo IMEDIATAMENTE (igual ao calendário)
          final convertedPath = await VideoEditorService.convertPhotoToVideo(
            photoPath: copiedPath,
          );
          if (convertedPath != null) {
            videoPathForPhoto = convertedPath;
          }
        }

        // Gerar thumbnail
        String? thumbnailPath;
        if (mediaType == 'video') {
          thumbnailPath = await VideoEditorService.generateThumbnail(
            videoPath: finalPath,
            timeMs: 0,
          );
        } else {
          // Para fotos, usar a própria foto como thumbnail
          thumbnailPath = copiedPath;
        }

        // Criar media item
        // Para fotos: originalPath = foto original, editedPath = vídeo convertido (será usado na renderização)
        // Para vídeos: originalPath = vídeo completo (será cortado no editor)
        final mediaItem = ProjectMediaItem(
          id: const Uuid().v4(),
          mediaType: mediaType,
          originalPath: isPhoto ? copiedPath : finalPath, // Foto original ou vídeo completo
          editedPath: isPhoto ? videoPathForPhoto : null, // Vídeo convertido para fotos
          startTimeMs: 0,
          durationMs: 1000, // Sempre 1 segundo
          order: _mediaItems.length,
          createdAt: DateTime.now(),
          thumbnailPath: thumbnailPath,
        );

        await HiveService.saveProjectMediaItem(mediaItem);
        await HiveService.addMediaItemToProject(_project!.id, mediaItem.id);

        _loadProject();

        // Abrir editor baseado no tipo
        if (mounted) {
          if (isPhoto) {
            // Para fotos, abrir editor de foto
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoEditScreen(mediaItem: mediaItem),
              ),
            ).then((_) => _loadProject());
          } else {
            // Para vídeos, abrir editor para escolher o segundo (igual ao calendário)
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
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorAddingMedia(e.toString()))),
        );
      }
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

    setState(() {
      _isGeneratingVideo = true;
    });

    try {
      // Converter ProjectMediaItem para formato que o VideoGeneratorService pode usar
      // Criar uma lista temporária de "entries" para o gerador de vídeo
      final videoPath = await VideoGeneratorService.generateProjectVideo(
        mediaItems: _mediaItems,
        projectName: _project!.name,
      );

      if (mounted) {
        setState(() {
          _isGeneratingVideo = false;
        });

        if (videoPath != null) {
          // Gerar thumbnail
          final thumbnailPath = await VideoEditorService.generateThumbnail(
            videoPath: videoPath,
            timeMs: 0,
          );
          
          // Obter duração do vídeo
          final duration = await VideoEditorService.getVideoDuration(videoPath);
          final durationSeconds = duration?.inSeconds ?? 0;
          
          // Salvar vídeo renderizado no histórico
          final renderedVideo = RenderedVideo(
            id: const Uuid().v4(),
            videoPath: videoPath,
            title: _project!.name,
            type: 'project',
            createdAt: DateTime.now(),
            thumbnailPath: thumbnailPath,
            durationSeconds: durationSeconds,
            projectId: _project!.id,
            metadata: {
              'projectName': _project!.name,
              'mediaItemsCount': _mediaItems.length,
            },
          );
          await HiveService.saveRenderedVideo(renderedVideo);
          
          // Mostrar preview do vídeo gerado
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
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        setState(() {
          _isGeneratingVideo = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneratingVideo(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_project == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                  : const Icon(Icons.video_library),
              onPressed: _isGeneratingVideo ? null : _renderProjectVideo,
              tooltip: l10n.renderProjectVideo,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMedia,
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
                  Text(
                    l10n.noMediaItemsYet,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addMedia,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addMedia),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Aumentado de 3 para 4 para boxes menores
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemCount: _mediaItems.length,
              itemBuilder: (context, index) {
                final item = _mediaItems[index];
                return _buildDraggableMediaThumbnail(item, index);
              },
            ),
    );
  }

  Widget _buildDraggableMediaThumbnail(ProjectMediaItem item, int index) {
    return DragTarget<int>(
      onWillAccept: (data) => data != null && data != index,
      onAcceptWithDetails: (details) {
        _reorderItems(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            shadowColor: Colors.blue,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue[100],
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: _buildThumbnailContent(item, index, isDragging: true),
            ),
          ),
          childWhenDragging: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: Opacity(
              opacity: 0.3,
              child: _buildThumbnailContent(item, index),
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isTargeted
                  ? Border.all(color: Colors.blue, width: 3)
                  : null,
              color: isTargeted ? Colors.blue[50] : Colors.transparent,
            ),
            child: _buildMediaThumbnail(item, index),
          ),
        );
      },
    );
  }

  Future<void> _reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex || oldIndex < 0 || newIndex < 0 || 
        oldIndex >= _mediaItems.length || newIndex >= _mediaItems.length) {
      return;
    }
    
    // Calcular o novo índice considerando a remoção
    int adjustedNewIndex = newIndex;
    if (oldIndex < newIndex) {
      adjustedNewIndex = newIndex;
    }
    
    setState(() {
      final item = _mediaItems.removeAt(oldIndex);
      _mediaItems.insert(adjustedNewIndex, item);
    });
    
    // Atualizar a ordem de todos os itens e salvar no Hive
    final newOrder = <String>[];
    for (int i = 0; i < _mediaItems.length; i++) {
      _mediaItems[i].order = i;
      await HiveService.saveProjectMediaItem(_mediaItems[i]);
      newOrder.add(_mediaItems[i].id);
    }
    
    // Atualizar a ordem no projeto
    if (_project != null) {
      await HiveService.reorderProjectMediaItems(_project!.id, newOrder);
      // Não recarregar o projeto para manter a animação suave
      // _loadProject(); 
    }
  }

  Widget _buildMediaThumbnail(ProjectMediaItem item, int index) {
    return GestureDetector(
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
      // Removido onLongPress para permitir drag and drop
      // O usuário pode deletar através de um menu de contexto ou botão
      child: _buildThumbnailContent(item, index),
    );
  }

  Widget _buildThumbnailContent(ProjectMediaItem item, int index, {bool isDragging = false}) {
    return Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.thumbnailPath != null && File(item.thumbnailPath!).existsSync()
                ? _buildThumbnailImage(item.thumbnailPath!, item.mediaType)
                : _buildPlaceholder(item.mediaType),
          ),
          // Overlay com informações
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.mediaType == 'photo' ? Icons.image : Icons.videocam,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Indicador de edição e botão de deletar
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.hasEdits)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                GestureDetector(
                  onTap: () => _deleteMediaItem(item),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
    );
  }

  Widget _buildThumbnailImage(String thumbnailPath, String mediaType) {
    final file = File(thumbnailPath);
    
    // Verificar se é uma imagem (não um vídeo)
    final extension = thumbnailPath.toLowerCase();
    final isImage = extension.endsWith('.jpg') || 
                    extension.endsWith('.jpeg') || 
                    extension.endsWith('.png') || 
                    extension.endsWith('.bmp') || 
                    extension.endsWith('.webp');
    
    // Se não for uma imagem, mostrar placeholder
    if (!isImage) {
      print('[ProjectEditScreen] WARNING: thumbnailPath is not an image: $thumbnailPath');
      return _buildPlaceholder(mediaType);
    }
    
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('[ProjectEditScreen] Error loading thumbnail: $error');
        return _buildPlaceholder(mediaType);
      },
    );
  }

  Widget _buildPlaceholder(String mediaType) {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        mediaType == 'photo' ? Icons.image : Icons.videocam,
        size: 40,
        color: Colors.grey[600],
      ),
    );
  }
}
