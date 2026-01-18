import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_entry.dart';
import 'photo_edit_daily_screen.dart';

class VideoPreviewScreen extends StatefulWidget {
  final DailyEntry entry;

  const VideoPreviewScreen({super.key, required this.entry});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPhoto = false;

  @override
  void initState() {
    super.initState();
    _isPhoto = widget.entry.mediaType == 'photo';
    if (!_isPhoto) {
      _initializeVideo();
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(
        File(widget.entry.originalPath),
      );
      await _controller!.initialize();
      _controller!.setLooping(true);
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingVideo(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('dd/MM/yyyy').format(widget.entry.date)),
        actions: [
          // Botão de compartilhar para vídeos
          if (widget.entry.mediaType == 'video')
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareVideo,
              tooltip: AppLocalizations.of(context)!.share,
            ),
          if (widget.entry.mediaType == 'photo')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoEditDailyScreen(entry: widget.entry),
                  ),
                ).then((_) {
                  // Recarregar a entrada atualizada
                  setState(() {});
                });
              },
            ),
        ],
      ),
      body: _isInitialized
          ? Column(
              children: [
                // Preview do vídeo ou foto
                Expanded(
                  child: Center(
                    child: _isPhoto
                        ? _buildPhotoPreview()
                        : _buildVideoPreview(),
                  ),
                ),

                // Informações
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd de MMMM de yyyy', 'pt')
                            .format(widget.entry.date),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.entry.caption != null &&
                          widget.entry.caption!.isNotEmpty)
                        Text(
                          widget.entry.caption!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            widget.entry.mediaType == 'video'
                                ? Icons.videocam
                                : Icons.camera_alt,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.entry.mediaType == 'video' ? 'Vídeo' : 'Foto',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildPhotoPreview() {
    // Para fotos, usar thumbnailPath se disponível (que contém a foto original)
    // ou originalPath se não houver thumbnail
    final imagePath = widget.entry.thumbnailPath ?? widget.entry.originalPath;
    final imageFile = File(imagePath);
    
    // Verificar se o arquivo existe
    if (!imageFile.existsSync()) {
      print('[VideoPreview] Image file does not exist: $imagePath');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.imageNotFound,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              imagePath,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Verificar se é uma imagem (não um vídeo)
    final extension = imagePath.toLowerCase();
    final isImage = extension.endsWith('.jpg') || 
                    extension.endsWith('.jpeg') || 
                    extension.endsWith('.png') || 
                    extension.endsWith('.bmp') || 
                    extension.endsWith('.webp');
    
    // Se não for uma imagem, mostrar erro
    if (!isImage) {
      print('[VideoPreview] WARNING: imagePath is not an image: $imagePath');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.errorLoadingImage,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'File is not an image: $imagePath',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.file(
        imageFile,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('[VideoPreview] Error loading image: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingImage,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
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
            // Mostrar botão de play apenas quando não estiver reproduzindo
            if (!_isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  size: 64,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareVideo() async {
    if (!File(widget.entry.originalPath).existsSync()) {
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSharing('Video file not found'))),
        );
      }
      return;
    }

    try {
      final l10n = AppLocalizations.of(context)!;
      await Share.shareXFiles(
        [XFile(widget.entry.originalPath)],
        text: '${l10n.appTitle} - ${DateFormat('dd/MM/yyyy').format(widget.entry.date)}',
      );
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSharing(e.toString()))),
        );
      }
    }
  }
}
