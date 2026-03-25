import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import '../services/timeline_prefs.dart';

/// Full-screen grid of days from the first recorded entry through today.
/// Filled days show a thumbnail; empty days show a tappable placeholder.
/// Cells are edge-to-edge and always square.
class ThumbnailGrid extends StatefulWidget {
  final Function(DateTime day, DailyEntry entry) onEntryTap;
  final Function(DateTime day, DailyEntry entry) onEntryLongPress;
  final Function(DateTime day) onEmptyDayTap;

  const ThumbnailGrid({
    super.key,
    required this.onEntryTap,
    required this.onEntryLongPress,
    required this.onEmptyDayTap,
  });

  @override
  ThumbnailGridState createState() => ThumbnailGridState();
}

class ThumbnailGridState extends State<ThumbnailGrid> {
  final ScrollController _scrollController = ScrollController();
  // Extra days loaded before the first entry date.
  int _extraDaysBefore = 0;
  static const int _loadMoreStep = 30;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  /// Jump to today instantly (used on initial load — no visible animation).
  void jumpToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// Animate to today (used when the user taps the "Today" button).
  void scrollToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _loadMore() {
    setState(() => _extraDaysBefore += _loadMoreStep);
  }

  List<DateTime> _dayRange(DateTime first, DateTime last) {
    final days = <DateTime>[];
    var current = DateTime(first.year, first.month, first.day);
    final end = DateTime(last.year, last.month, last.day);
    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final entries = HiveService.getAllEntries(); // sorted ascending
    final today = DateTime.now();

    if (entries.isEmpty) {
      // No entries yet: show a prompt with a load-more button at the top
      return Column(
        children: [
          _LoadMoreButton(onTap: _loadMore),
          const Expanded(
            child: Center(child: Icon(Icons.camera_alt, size: 64, color: Colors.grey)),
          ),
        ],
      );
    }

    final entryMap = <String, DailyEntry>{};
    for (final e in entries) {
      final key =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      entryMap[key] = e;
    }

    final rangeStart = entries.first.date.subtract(Duration(days: _extraDaysBefore));
    final days = _dayRange(rangeStart, today);

    // Total items = load-more button (1) + day cells
    final itemCount = days.length + 1;

    return ValueListenableBuilder<String?>(
      valueListenable: ThumbnailSizePrefs.notifier,
      builder: (context, _, __) => GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ThumbnailSizePrefs.crossAxisCount,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // First item spans the full row as a "Load more" button
        if (index == 0) {
          return _LoadMoreButton(onTap: _loadMore);
        }

        final day = days[index - 1];
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final entry = entryMap[key];
        if (entry != null) {
          return _ThumbnailCell(
            entry: entry,
            onTap: () => widget.onEntryTap(day, entry),
            onLongPress: () => widget.onEntryLongPress(day, entry),
          );
        } else {
          return _EmptyDayCell(
            day: day,
            onTap: () => widget.onEmptyDayTap(day),
          );
        }
      },
    ),
    );
  }
}

// ── Filled cell ────────────────────────────────────────────────────────────

class _ThumbnailCell extends StatelessWidget {
  final DailyEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ThumbnailCell({required this.entry, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d').format(entry.date);
    final isVideo = entry.mediaType == 'video';
    final thumbPath = entry.thumbnailPath;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildThumb(thumbPath),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              color: Colors.black.withValues(alpha: 0.55),
              child: Text(
                dateLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          if (isVideo)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumb(String? path) {
    if (path == null) return _placeholder();
    final file = File(path);
    if (!file.existsSync()) return _placeholder();
    final ext = path.toLowerCase();
    final isImage = ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp');
    if (!isImage) return _placeholder();
    return Image.file(
      file,
      fit: BoxFit.cover,
      cacheWidth: 300,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: Colors.grey[900]!,
      child: Center(
        child: Icon(
          entry.mediaType == 'video' ? Icons.videocam : Icons.camera_alt,
          color: Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }
}

// ── Empty cell ─────────────────────────────────────────────────────────────

class _EmptyDayCell extends StatelessWidget {
  final DateTime day;
  final VoidCallback onTap;

  const _EmptyDayCell({required this.day, required this.onTap});

  bool get _isToday {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d').format(day);

    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: _isToday
            ? Colors.deepPurple.withValues(alpha: 0.15)
            : Colors.grey[900]!,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Icon(
                Icons.add,
                color: _isToday ? Colors.deepPurpleAccent : Colors.grey[700],
                size: 22,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                color: Colors.black.withValues(alpha: 0.45),
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    color: _isToday ? Colors.deepPurpleAccent : Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Load more button ───────────────────────────────────────────────────────

class _LoadMoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LoadMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: Colors.grey[850]!,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 20),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.loadMoreDays,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
