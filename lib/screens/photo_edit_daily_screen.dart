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
  String? _selectedFilter; // null = original

  static const _filters = [
    ('original', null),
    ('vintage', 'vintage'),
    ('blackwhite', 'blackwhite'),
    ('sepia', 'sepia'),
    ('bright', 'bright'),
    ('warm', 'warm'),
    ('cool', 'cool'),
  ];

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  String get _currentImagePath => _entry.thumbnailPath ?? _entry.originalPath;

  Future<void> _updatePath(String newPath) async {
    final updated = DailyEntry(
      id: _entry.id,
      date: _entry.date,
      mediaType: _entry.mediaType,
      originalPath: newPath,
      startTimeMs: _entry.startTimeMs,
      durationMs: _entry.durationMs,
      caption: _entry.caption,
      createdAt: _entry.createdAt,
      timezone: _entry.timezone,
      thumbnailPath: newPath,
      hasAudio: _entry.hasAudio,
    );
    await HiveService.saveEntry(updated);
    await NotificationService.checkAndCancelNotificationsForDate(updated.date);
    if (mounted) setState(() => _entry = updated);
  }

  Future<void> _applyFilter(String? filterType) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _selectedFilter = filterType;
    });

    try {
      String? processedPath;
      if (filterType == null) {
        // For photo entries, originalPath is the converted .mp4; the actual
        // image is in thumbnailPath. Fall back to originalPath only if needed.
        processedPath = widget.entry.thumbnailPath ?? widget.entry.originalPath;
      } else {
        processedPath = await ImageEditorService.applyFilter(
          inputPath: _currentImagePath,
          filterType: filterType,
        );
      }
      if (processedPath != null) await _updatePath(processedPath);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorApplyingFilter(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cropPhoto() async {
    if (_isProcessing) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _currentImagePath,
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
        IOSUiSettings(title: AppLocalizations.of(context)!.cropImage),
      ],
    );

    if (croppedFile == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _updatePath(croppedFile.path);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rotatePhoto() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final rotatedPath = await ImageEditorService.rotateImage(
        inputPath: _currentImagePath,
        degrees: 90,
      );
      if (rotatedPath != null) await _updatePath(rotatedPath);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorRotatingImage(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _addText() async {
    if (_isProcessing) return;

    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addText),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.enterYourText),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.applyCrop),
          ),
        ],
      ),
    );

    if (confirmed != true || controller.text.trim().isEmpty || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final resultPath = await ImageEditorService.addTextToImage(
        inputPath: _currentImagePath,
        text: controller.text.trim(),
      );
      if (resultPath != null) {
        await _updatePath(resultPath);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorApplyingText('Failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorApplyingText(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editPhotoDaily)),
      body: Column(
        children: [
          // Photo preview
          Expanded(
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    child: Center(
                      child: Image.file(
                        File(_currentImagePath),
                        key: ValueKey(_currentImagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image,
                              size: 64, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
          ),

          // Editing panel
          _buildEditingPanel(l10n),
        ],
      ),
    );
  }

  Widget _buildEditingPanel(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter strip
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            child: SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _filters.map((f) {
                  final key = f.$1;
                  final type = f.$2;
                  final label = _filterLabel(l10n, key);
                  final isSelected = _selectedFilter == type;
                  return _FilterChip(
                    label: label,
                    isSelected: isSelected,
                    onTap: _isProcessing ? null : () => _applyFilter(type),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Action buttons row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.crop,
                  label: l10n.cropImage,
                  onTap: _isProcessing ? null : _cropPhoto,
                ),
                _ActionButton(
                  icon: Icons.rotate_right,
                  label: l10n.rotate,
                  onTap: _isProcessing ? null : _rotatePhoto,
                ),
                _ActionButton(
                  icon: Icons.text_fields,
                  label: l10n.addText,
                  onTap: _isProcessing ? null : _addText,
                ),
              ],
            ),
          ),

          // Done button
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 4, 16, MediaQuery.of(context).padding.bottom + 16),
            child: FilledButton(
              onPressed:
                  _isProcessing ? null : () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: Text(l10n.done,
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'original':
        return l10n.filterOriginal;
      case 'vintage':
        return l10n.filterVintage;
      case 'blackwhite':
        return l10n.filterBlackWhite;
      case 'sepia':
        return l10n.filterSepia;
      case 'bright':
        return l10n.filterBright;
      case 'warm':
        return l10n.filterWarm;
      case 'cool':
        return l10n.filterCool;
      default:
        return key;
    }
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : null,
          ),
        ),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
