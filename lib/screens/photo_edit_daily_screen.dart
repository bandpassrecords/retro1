import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import '../services/image_editor_service.dart';
import '../services/notification_service.dart';

class PhotoEditDailyScreen extends StatefulWidget {
  final DailyEntry entry;

  const PhotoEditDailyScreen({super.key, required this.entry});

  @override
  State<PhotoEditDailyScreen> createState() => _PhotoEditDailyScreenState();
}

class _PhotoEditDailyScreenState extends State<PhotoEditDailyScreen> {
  late DailyEntry _entry;
  bool _isProcessing = false;
  bool _isPortrait = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _checkOrientation();
  }

  Future<void> _checkOrientation() async {
    try {
      final imagePath = _entry.thumbnailPath ?? _entry.originalPath;
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        final image = await ImageEditorService.getImageDimensions(imagePath);
        if (image != null) {
          setState(() {
            _isPortrait = image['height']! > image['width']!;
          });
        }
      }
    } catch (e) {
      print('[PhotoEdit] Error checking orientation: $e');
    }
  }

  Future<void> _convertToLandscape({bool useCrop = false}) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final imagePath = _entry.thumbnailPath ?? _entry.originalPath;
      String? processedPath;

      if (useCrop) {
        // Usar image_cropper para permitir que o usuário escolha a área de crop
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: imagePath,
          aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: AppLocalizations.of(context)!.cropImage,
              toolbarColor: Colors.black,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: Colors.orange,
              initAspectRatio: CropAspectRatioPreset.ratio16x9,
              lockAspectRatio: true,
              hideBottomControls: false,
              showCropGrid: true,
              statusBarLight: false,
              navBarLight: false,
            ),
            IOSUiSettings(
              title: AppLocalizations.of(context)!.cropImage,
            ),
          ],
        );

        if (croppedFile != null) {
          processedPath = croppedFile.path;
        } else {
          // Usuário cancelou o crop
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      } else {
        // Converter sem crop - apenas rotacionar 90 graus
        processedPath = await ImageEditorService.rotateImage(
          inputPath: imagePath,
          degrees: 90,
        );
      }

      if (processedPath != null) {
        final finalPath = processedPath;
        setState(() {
          _entry = DailyEntry(
            id: _entry.id,
            date: _entry.date,
            mediaType: _entry.mediaType,
            originalPath: finalPath,
            startTimeMs: _entry.startTimeMs,
            durationMs: _entry.durationMs,
            caption: _entry.caption,
            createdAt: _entry.createdAt,
            timezone: _entry.timezone,
            thumbnailPath: finalPath,
            hasAudio: _entry.hasAudio,
          );
        });
        await HiveService.saveEntry(_entry);
        await NotificationService.checkAndCancelNotificationsForDate(_entry.date);
        
        // Atualizar orientação
        await _checkOrientation();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorConvertingImage(e.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    final imagePath = _entry.thumbnailPath ?? _entry.originalPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editPhotoDaily),
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
                // Opções apenas se for portrait
                if (_isPortrait)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.convertToLandscape,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _convertToLandscape(useCrop: true),
                          icon: const Icon(Icons.crop),
                          label: Text(l10n.convertWithCrop),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _convertToLandscape(useCrop: false),
                          icon: const Icon(Icons.rotate_right),
                          label: Text(l10n.convertWithoutCrop),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.imageAlreadyLandscape,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
    );
  }
}
