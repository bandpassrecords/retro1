import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import '../services/timeline_prefs.dart';
import '../widgets/monthly_calendar.dart';
import '../widgets/thumbnail_grid.dart';
import 'capture_screen.dart';
import 'settings_screen.dart';
import 'video_preview_screen.dart';
import 'projects_screen.dart';
import 'video_generator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupQuickActions();
  }

  void _setupQuickActions() {
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((shortcutType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Switch to timeline tab and open capture
        setState(() => _selectedIndex = 0);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaptureScreen(
              selectedDate: DateTime.now(),
              autoAction: shortcutType,
            ),
          ),
        );
      });
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'record_video',
        localizedTitle: 'Record Video',
        icon: 'ic_shortcut_video',
      ),
      const ShortcutItem(
        type: 'take_photo',
        localizedTitle: 'Take Photo',
        icon: 'ic_shortcut_photo',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _TimelineTab(),
          ProjectsScreen(),
          VideoGeneratorScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.photo_library_outlined),
            selectedIcon: const Icon(Icons.photo_library),
            label: l10n.timeline,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: l10n.projects,
          ),
          NavigationDestination(
            icon: const Icon(Icons.movie_creation_outlined),
            selectedIcon: const Icon(Icons.movie_creation),
            label: l10n.generate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}

// ── Timeline tab ───────────────────────────────────────────────────────────

class _TimelineTab extends StatefulWidget {
  const _TimelineTab();

  @override
  State<_TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<_TimelineTab> {
  final GlobalKey<ThumbnailGridState> _gridKey = GlobalKey<ThumbnailGridState>();
  final GlobalKey<MonthlyCalendarState> _calendarKey = GlobalKey<MonthlyCalendarState>();
  bool _isRefreshing = false;
  DateTime? _calendarSelectedDay;

  @override
  void initState() {
    super.initState();
    if (TimelinePrefs.current == TimelinePrefs.gridView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gridKey.currentState?.scrollToToday();
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {});
      _gridKey.currentState?.refresh();
      _calendarKey.currentState?.refresh();
    }
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _refreshGrid() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {});
      _gridKey.currentState?.refresh();
      _calendarKey.currentState?.refresh();
    }
  }

  void _goToToday() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (TimelinePrefs.current == TimelinePrefs.gridView) {
        _gridKey.currentState?.scrollToToday();
      } else {
        _calendarKey.currentState?.focusOnToday();
      }
    });
  }

  void _openCapture(DateTime day) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CaptureScreen(selectedDate: day)),
    );
    if (result == true || mounted) _refreshGrid();
  }

  void _openEntry(DateTime day, DailyEntry entry) async {
    final entries = HiveService.getAllEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(
          entry: entry,
          allEntries: entries,
          initialIndex: index < 0 ? 0 : index,
          onReplaceEntry: (e) => _openCapture(e.date),
          onDeleteEntry: (e) async {
            await HiveService.deleteEntry(e.id);
            _refreshGrid();
          },
        ),
      ),
    );
    _refreshGrid();
  }

  void _showDayOptions(DateTime day, DailyEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle),
              title: Text(l10n.view),
              onTap: () {
                Navigator.pop(context);
                _openEntry(day, entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.replace),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaptureScreen(selectedDate: day),
                  ),
                );
                _refreshGrid();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(l10n.delete),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(DailyEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(l10n.confirmDeletionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              HiveService.deleteEntry(entry.id);
              Navigator.pop(context);
              _refreshGrid();
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final hasTodayEntry = HiveService.hasEntryForDate(today);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/icons/app_icon.png', height: 32),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _isRefreshing ? null : _handleRefresh,
            tooltip: l10n.refresh,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today, size: 18),
              label: Text(l10n.today),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orangeAccent
                    : Colors.deepPurple,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orangeAccent.withValues(alpha: 0.2)
                    : Colors.deepPurple.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<String?>(
        valueListenable: TimelinePrefs.notifier,
        builder: (context, view, _) {
          if ((view ?? TimelinePrefs.calendarView) == TimelinePrefs.gridView) {
            return ThumbnailGrid(
              key: _gridKey,
              onEntryTap: (day, entry) => _openEntry(day, entry),
              onEntryLongPress: (day, entry) => _showDayOptions(day, entry),
              onEmptyDayTap: (day) => _openCapture(day),
            );
          }
          return MonthlyCalendar(
            key: _calendarKey,
            selectedDay: _calendarSelectedDay,
            focusedMonth: today,
            onDayTap: (day, entry) {
              setState(() => _calendarSelectedDay = day);
              if (entry != null) {
                _showDayOptions(day, entry);
              } else {
                _openCapture(day);
              }
            },
            onDayLongPress: (day, entry) => _showDayOptions(day, entry),
          );
        },
      ),
      floatingActionButton: hasTodayEntry
          ? null
          : FloatingActionButton(
              heroTag: 'home_fab',
              onPressed: () => _openCapture(DateTime.now()),
              tooltip: l10n.recordToday,
              backgroundColor: const Color(0xFF66BB6A),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
