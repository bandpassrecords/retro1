import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/media_service.dart';
import '../services/hive_service.dart';
import '../services/video_editor_service.dart';
import '../services/notification_service.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordFor(DateFormat('dd/MM/yyyy').format(widget.selectedDate))),
      ),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.chooseHowToRecord,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildCaptureOption(
                    icon: Icons.videocam,
                    label: l10n.recordVideo,
                    color: Colors.grey[700]!,
                    onTap: () => _captureVideo(),
                  ),
                  const SizedBox(height: 16),
                  _buildCaptureOption(
                    icon: Icons.camera_alt,
                    label: l10n.takePhoto,
                    color: Colors.grey[700]!,
                    onTap: () => _capturePhoto(),
                  ),
                  const SizedBox(height: 16),
                  _buildCaptureOption(
                    icon: Icons.video_library,
                    label: l10n.videoFromGallery,
                    color: Colors.grey[700]!,
                    onTap: () => _pickVideoFromGallery(),
                  ),
                  const SizedBox(height: 16),
                  _buildCaptureOption(
                    icon: Icons.photo_library,
                    label: l10n.photoFromGallery,
                    color: Colors.grey[700]!,
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
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.noVideoCaptured);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.errorCapturingVideo(e.toString()));
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
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.noPhotoCaptured);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.errorCapturingPhoto(e.toString()));
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
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.noVideoSelected);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.errorSelectingVideo(e.toString()));
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
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.noPhotoSelected);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.errorSelectingPhoto(e.toString()));
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
          final l10n = AppLocalizations.of(context)!;
          final shouldEdit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.photoAdded),
              content: Text(l10n.doYouWantToEdit),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.skip),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.edit),
                ),
              ],
            ),
          );

          if (shouldEdit == true) {
            // Salvar primeiro
            await HiveService.saveEntry(entry);
            // Cancelar notificações para este dia
            await NotificationService.checkAndCancelNotificationsForDate(entry.date);
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
            // Cancelar notificações para este dia
            await NotificationService.checkAndCancelNotificationsForDate(entry.date);
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.errorProcessingMedia(e.toString()));
      }
    }
  }

  Future<bool> _confirmReplace() async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.entryAlreadyExists),
            content: Text(l10n.entryAlreadyExistsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.replace),
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
