import 'package:flutter/material.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
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
  bool _isRefreshing = false;

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

  Future<void> _refreshCalendar() async {
    // Pequeno delay para mostrar o indicador de refresh
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {});
      // Também forçar refresh do widget do calendário
      _calendarKey.currentState?.refresh();
    }
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDay = today;
      _focusedMonth = DateTime(today.year, today.month, 1);
    });
    // Aguardar um frame para garantir que o setState foi processado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Focar no dia atual no calendário
      _calendarKey.currentState?.focusOnToday();
    });
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
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orangeAccent // Cor laranja para tema escuro
                    : Colors.deepPurple, // Cor roxa para tema claro
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orangeAccent.withValues(alpha: 0.2) // Fundo sutil para tema escuro
                    : Colors.deepPurple.withValues(alpha: 0.1), // Fundo sutil para tema claro
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
          
          // Calendário mensal com thumbnails e pull-to-refresh de baixo para cima
          Expanded(
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      final metrics = notification.metrics;
                      // Detectar quando está no final e puxando para cima
                      if (metrics.pixels >= metrics.maxScrollExtent - 10 && 
                          notification.scrollDelta != null &&
                          notification.scrollDelta! < 0 &&
                          !_isRefreshing) {
                        _isRefreshing = true;
                        setState(() {});
                        _refreshCalendar().then((_) {
                          if (mounted) {
                            setState(() {
                              _isRefreshing = false;
                            });
                          }
                        });
                      }
                    }
                    return false;
                  },
                  child: MonthlyCalendar(
                    key: _calendarKey,
                    selectedDay: _selectedDay,
                    focusedMonth: _focusedMonth,
                    onDayTap: _onDaySelected,
                    calendarKey: _calendarKey,
                  ),
                ),
                // Indicador de refresh na parte inferior
                if (_isRefreshing)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Botão de ação rápida (apenas se não houver entrada para hoje)
          if (!hasTodayEntry)
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
              AppLocalizations.of(context)!.today,
              hasToday ? '✓' : '✗',
              hasToday ? Colors.green : Colors.orange,
            ),
            _buildStatItem(AppLocalizations.of(context)!.totalEntries, total.toString(), Colors.blue),
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaptureScreen(selectedDate: today),
      ),
    );
    // Atualizar calendário quando voltar (sempre, mas especialmente se foi salvo)
    if (result == true || mounted) {
      _refreshCalendar();
    }
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
      // Abrir diretamente a tela de captura sem diálogo de confirmação
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaptureScreen(selectedDate: selectedDay),
        ),
      ).then((result) {
        // Atualizar calendário quando voltar (sempre, mas especialmente se foi salvo)
        if (result == true || mounted) {
          _refreshCalendar();
        }
      });
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
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPreviewScreen(entry: entry),
                  ),
                );
                // Atualizar calendário quando voltar (pode ter editado a foto)
                _refreshCalendar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l10n.replace),
              onTap: () async {
                Navigator.pop(context);
                // Abrir diretamente a tela de captura para trocar a mídia
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CaptureScreen(selectedDate: day),
                  ),
                );
                // Atualizar calendário quando voltar
                _refreshCalendar();
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
              _refreshCalendar();
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
