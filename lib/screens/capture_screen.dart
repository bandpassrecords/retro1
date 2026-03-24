import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/media_service.dart';
import '../services/hive_service.dart';
import '../services/timeline_prefs.dart';
import '../services/video_editor_service.dart';
import '../services/notification_service.dart';
import 'editor_screen.dart';
import 'photo_edit_daily_screen.dart';
import 'custom_gallery_picker_screen.dart';
import 'video_trimmer_screen.dart';

class CaptureScreen extends StatefulWidget {
  final DateTime selectedDate;

  /// When set, automatically triggers that action on open (used by quick actions).
  /// Values: 'record_video', 'take_photo'
  final String? autoAction;

  const CaptureScreen({
    super.key,
    required this.selectedDate,
    this.autoAction,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        switch (widget.autoAction) {
          case 'record_video':
            _captureVideo();
          case 'take_photo':
            _capturePhoto();
        }
      });
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
        widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    return selected == today;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isToday = _isToday;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            l10n.recordFor(DateFormat('dd/MM/yyyy').format(widget.selectedDate))),
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
                  // Camera options only available for today
                  if (isToday) ...[
                    _buildCaptureOption(
                      icon: Icons.videocam,
                      label: l10n.recordVideo,
                      color: Colors.grey[700]!,
                      onTap: _captureVideo,
                    ),
                    const SizedBox(height: 16),
                    _buildCaptureOption(
                      icon: Icons.camera_alt,
                      label: l10n.takePhoto,
                      color: Colors.grey[700]!,
                      onTap: _capturePhoto,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildCaptureOption(
                    icon: Icons.photo_library,
                    label: l10n.browseGallery,
                    color: Colors.grey[700]!,
                    onTap: _pickFromGallery,
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
      if (video == null || !mounted) {
        if (mounted) _showError(AppLocalizations.of(context)!.noVideoCaptured);
        return;
      }
      setState(() => _isProcessing = false);

      // Trim before importing
      final trimResult = await Navigator.push<({String path, bool muted})>(
        context,
        MaterialPageRoute(
          builder: (_) => VideoTrimmerScreen(videoPath: video.path),
        ),
      );
      if (trimResult == null || !mounted) return;

      setState(() => _isProcessing = true);
      await _processMedia(
        trimResult.path,
        'video',
        alreadyTrimmed: true,
        muteAudio: trimResult.muted,
      );
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.errorCapturingVideo(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _isProcessing = true);
    try {
      final photo = await MediaService.capturePhoto();
      if (photo != null && mounted) {
        await _processMedia(photo.path, 'photo');
      } else if (mounted) {
        _showError(AppLocalizations.of(context)!.noPhotoCaptured);
      }
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.errorCapturingPhoto(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    GalleryPickerResult? result;

    if (MediaPickerPrefs.current == MediaPickerPrefs.systemPicker) {
      result = await _pickWithSystemPicker();
    } else {
      result = await Navigator.push<GalleryPickerResult>(
        context,
        MaterialPageRoute(
          builder: (_) => CustomGalleryPickerScreen(
            filterDate: widget.selectedDate,
          ),
        ),
      );
    }

    if (result == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      // Videos from the gallery are always pre-trimmed by VideoTrimmerScreen.
      await _processMedia(
        result.path,
        result.mediaType,
        alreadyTrimmed: result.mediaType == 'video',
        muteAudio: result.muteAudio,
      );
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.errorSelectingMedia(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<GalleryPickerResult?> _pickWithSystemPicker() async {
    final l10n = AppLocalizations.of(context)!;
    // Ask the user whether they want a photo or a video, then open the
    // native Android / iOS picker (Google Photos on Android).
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
        final file = await MediaService.pickVideoFromGallery();
        if (file == null || !mounted) return null;
        // Trim before importing
        final trimResult = await Navigator.push<({String path, bool muted})>(
          context,
          MaterialPageRoute(
            builder: (_) => VideoTrimmerScreen(videoPath: file.path),
          ),
        );
        if (trimResult == null) return null;
        return GalleryPickerResult(
          path: trimResult.path,
          mediaType: 'video',
          muteAudio: trimResult.muted,
        );
      } else {
        final file = await MediaService.pickPhotoFromGallery();
        if (file == null) return null;
        return GalleryPickerResult(path: file.path, mediaType: 'photo');
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _processMedia(
    String mediaPath,
    String mediaType, {
    bool alreadyTrimmed = false,
    bool muteAudio = false,
  }) async {
    try {
      // Check if entry already exists for this day
      final existingEntry = HiveService.getEntryByDate(widget.selectedDate);
      if (existingEntry != null) {
        final shouldReplace = await _confirmReplace();
        if (!shouldReplace) return;
        await HiveService.deleteEntry(existingEntry.id);
      }

      final copiedPath = await MediaService.copyToAppDirectory(mediaPath);

      String finalPath = copiedPath;
      if (mediaType == 'photo') {
        final convertedPath = await VideoEditorService.convertPhotoToVideo(
          photoPath: copiedPath,
        );
        if (convertedPath != null) finalPath = convertedPath;
      }

      String? thumbnailPath;
      if (mediaType == 'video') {
        thumbnailPath = await VideoEditorService.generateThumbnail(
          videoPath: finalPath,
          timeMs: 0,
        );
      } else {
        thumbnailPath = copiedPath;
      }

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
        hasAudio: mediaType == 'video' && !muteAudio,
      );

      await HiveService.saveEntry(entry);
      await NotificationService.checkAndCancelNotificationsForDate(entry.date);

      if (mounted) {
        if (mediaType == 'video' && !alreadyTrimmed) {
          // Long-form video not yet trimmed: open the editor so the user can
          // pick which second to keep (legacy path, e.g. direct camera imports
          // that skipped the trimmer screen for some reason).
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditorScreen(entry: entry, isNewEntry: true),
            ),
          );
        } else if (mediaType == 'photo') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoEditDailyScreen(entry: entry),
            ),
          );
        } else {
          // Video already trimmed to 1 second — go back to the previous screen.
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.errorProcessingMedia(e.toString()));
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
