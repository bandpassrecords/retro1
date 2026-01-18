import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/daily_entry.dart';
import '../services/media_service.dart';
import '../services/hive_service.dart';
import '../services/video_editor_service.dart';
import 'editor_screen.dart';
import 'photo_edit_daily_screen.dart';

class CaptureScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CaptureScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar - ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}'),
      ),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Escolha como deseja registrar seu momento:',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildCaptureOption(
                    icon: Icons.videocam,
                    label: 'Gravar Vídeo',
                    color: Colors.red,
                    onTap: () => _captureVideo(),
                  ),
                  const SizedBox(height: 16),
                  _buildCaptureOption(
                    icon: Icons.camera_alt,
                    label: 'Tirar Foto',
                    color: Colors.blue,
                    onTap: () => _capturePhoto(),
                  ),
                  const SizedBox(height: 16),
                  _buildCaptureOption(
                    icon: Icons.video_library,
                    label: 'Vídeo da Galeria',
                    color: Colors.purple,
                    onTap: () => _pickVideoFromGallery(),
                  ),
                  const SizedBox(height: 16),
                  _buildCaptureOption(
                    icon: Icons.photo_library,
                    label: 'Foto da Galeria',
                    color: Colors.green,
                    onTap: () => _pickPhotoFromGallery(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCaptureOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 250,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 32),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _captureVideo() async {
    setState(() => _isProcessing = true);

    try {
      final video = await MediaService.captureVideo();
      if (video != null && mounted) {
        await _processMedia(video.path, 'video');
      } else if (mounted) {
        _showError('Nenhum vídeo foi capturado');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao capturar vídeo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _isProcessing = true);

    try {
      final photo = await MediaService.capturePhoto();
      if (photo != null && mounted) {
        await _processMedia(photo.path, 'photo');
      } else if (mounted) {
        _showError('Nenhuma foto foi capturada');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao capturar foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    setState(() => _isProcessing = true);

    try {
      final video = await MediaService.pickVideoFromGallery();
      if (video != null && mounted) {
        await _processMedia(video.path, 'video');
      } else if (mounted) {
        _showError('Nenhum vídeo foi selecionado');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao selecionar vídeo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    setState(() => _isProcessing = true);

    try {
      final photo = await MediaService.pickPhotoFromGallery();
      if (photo != null && mounted) {
        await _processMedia(photo.path, 'photo');
      } else if (mounted) {
        _showError('Nenhuma foto foi selecionada');
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao selecionar foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processMedia(String mediaPath, String mediaType) async {
    try {
      // Verificar se já existe entrada para este dia
      final existingEntry = HiveService.getEntryByDate(widget.selectedDate);
      if (existingEntry != null) {
        final shouldReplace = await _confirmReplace();
        if (!shouldReplace) {
          return;
        }
        // Deletar entrada antiga
        await HiveService.deleteEntry(existingEntry.id);
      }

      // Copiar arquivo para diretório do app
      final copiedPath = await MediaService.copyToAppDirectory(mediaPath);

      // Se for foto, converter para vídeo de 1 segundo
      String finalPath = copiedPath;
      if (mediaType == 'photo') {
        final convertedPath = await VideoEditorService.convertPhotoToVideo(
          photoPath: copiedPath,
        );
        if (convertedPath != null) {
          finalPath = convertedPath;
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
        thumbnailPath = copiedPath; // Para fotos, usar a foto como thumbnail
      }

      // Criar entrada
      final entry = DailyEntry(
        id: const Uuid().v4(),
        date: widget.selectedDate,
        mediaType: mediaType,
        originalPath: finalPath,
        startTimeMs: 0,
        durationMs: 1000,
        createdAt: DateTime.now(),
        timezone: DateTime.now().timeZoneName,
        thumbnailPath: thumbnailPath,
        hasAudio: mediaType == 'video',
      );

      // Se for vídeo, abrir editor para escolher o segundo
      if (mediaType == 'video') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EditorScreen(entry: entry, isNewEntry: true),
            ),
          );
        }
      } else {
        // Se for foto, perguntar se quer editar
        if (mounted) {
          final shouldEdit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Photo Added'),
              content: const Text('Do you want to edit the photo now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Skip'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Edit'),
                ),
              ],
            ),
          );

          if (shouldEdit == true) {
            // Salvar primeiro
            await HiveService.saveEntry(entry);
            // Abrir editor de foto
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoEditDailyScreen(entry: entry),
              ),
            );
          } else {
            // Salvar e voltar
            await HiveService.saveEntry(entry);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entry saved successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao processar mídia: $e');
      }
    }
  }

  Future<bool> _confirmReplace() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Já existe uma entrada'),
            content: const Text(
              'Já existe uma entrada para este dia. Deseja substituir?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Substituir'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
