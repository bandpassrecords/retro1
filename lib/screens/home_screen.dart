import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import '../services/media_service.dart';
import '../widgets/monthly_calendar.dart';
import 'capture_screen.dart';
import 'timeline_screen.dart';
import 'settings_screen.dart';
import 'video_preview_screen.dart';
import 'projects_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedMonth;
  final GlobalKey<MonthlyCalendarState> _calendarKey = MonthlyCalendar.createKey();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = now;
    _focusedMonth = DateTime(now.year, now.month, 1); // Garantir que começa no primeiro dia do mês atual
    _checkTodayEntry();
  }

  void _checkTodayEntry() {
    final today = DateTime.now();
    if (!HiveService.hasEntryForDate(today)) {
      // Pode mostrar um banner ou notificação
    }
  }

  void _refreshCalendar() {
    if (mounted) {
      setState(() {});
    }
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _focusedMonth = DateTime(today.year, today.month, 1);
    });
    // Focar no dia atual no calendário
    _calendarKey.currentState?.focusOnToday();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final hasTodayEntry = HiveService.hasEntryForDate(today);
    final totalEntries = HiveService.getTotalEntries();
    final yearEntries = HiveService.getEntriesCountForYear(today.year);

    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          // Botão Today alinhado à direita
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today, size: 18),
              label: Text(l10n.today),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProjectsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TimelineScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Estatísticas rápidas
          _buildStatsCard(hasTodayEntry, totalEntries, yearEntries),
          
          // Calendário mensal com thumbnails
          Expanded(
            child: MonthlyCalendar(
              key: _calendarKey,
              selectedDay: _selectedDay,
              focusedMonth: _focusedMonth,
              onDayTap: _onDaySelected,
              calendarKey: _calendarKey,
            ),
          ),

          // Botão de ação rápida
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildQuickActionButton(hasTodayEntry),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool hasToday, int total, int year) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Hoje',
              hasToday ? '✓' : '✗',
              hasToday ? Colors.green : Colors.orange,
            ),
            _buildStatItem('Total', total.toString(), Colors.blue),
            _buildStatItem('${DateTime.now().year}', year.toString(), Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(bool hasTodayEntry) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _handleQuickAction(hasTodayEntry),
        icon: Icon(hasTodayEntry ? Icons.swap_horiz : Icons.camera_alt),
        label: Text(hasTodayEntry ? l10n.replace : l10n.recordToday),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _handleQuickAction(bool hasTodayEntry) async {
    final today = DateTime.now();
    // Sempre abrir a tela de captura (para adicionar ou trocar)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaptureScreen(selectedDate: today),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DailyEntry? entry) {
    setState(() {
      _selectedDay = selectedDay;
      // Atualizar mês focado se necessário
      if (selectedDay.year != _focusedMonth.year ||
          selectedDay.month != _focusedMonth.month) {
        _focusedMonth = DateTime(selectedDay.year, selectedDay.month, 1);
      }
    });

    if (entry != null) {
      _showDayOptions(selectedDay, entry);
    } else if (_isSameDay(selectedDay, DateTime.now()) ||
        selectedDay.isBefore(DateTime.now())) {
      _showAddEntryDialog(selectedDay);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPreviewScreen(entry: entry),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.replace),
              onTap: () {
                Navigator.pop(context);
                // Abrir diretamente a tela de captura para trocar a mídia
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaptureScreen(selectedDate: day),
                  ),
                );
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

  void _showAddEntryDialog(DateTime day) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addEntryFor(DateFormat('dd/MM/yyyy').format(day))),
        content: Text(l10n.captureOrImport),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CaptureScreen(selectedDate: day),
                ),
              );
            },
            child: Text(l10n.yes),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
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
              _refreshCalendar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.entryDeleted)),
              );
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
