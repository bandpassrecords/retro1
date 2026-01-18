import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';

class MonthlyCalendar extends StatefulWidget {
  final DateTime? selectedDay;
  final Function(DateTime day, DailyEntry? entry) onDayTap;
  final DateTime focusedMonth;
  final GlobalKey<MonthlyCalendarState>? calendarKey;

  const MonthlyCalendar({
    super.key,
    this.selectedDay,
    required this.onDayTap,
    required this.focusedMonth,
    this.calendarKey,
  });

  @override
  MonthlyCalendarState createState() => MonthlyCalendarState();

  // Método estático para criar a key
  static GlobalKey<MonthlyCalendarState> createKey() {
    return GlobalKey<MonthlyCalendarState>();
  }
}

class MonthlyCalendarState extends State<MonthlyCalendar> {
  late ScrollController _scrollController;
  late List<DateTime> _months;
  final Map<int, GlobalKey> _monthKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateMonths();
    // Aguardar que o layout esteja pronto antes de fazer scroll
    // Usar múltiplos callbacks para garantir que o layout está completamente renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _scrollToCurrentMonth();
          });
        });
      });
    });
  }

  @override
  void didUpdateWidget(MonthlyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedMonth.year != widget.focusedMonth.year ||
        oldWidget.focusedMonth.month != widget.focusedMonth.month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToMonth(widget.focusedMonth);
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _generateMonths() {
    final today = DateTime.now();
    // Gerar meses: 2 anos atrás até 2 anos à frente
    final start = DateTime(today.year - 2, 1, 1);
    final end = DateTime(today.year + 2, 12, 1);
    
    _months = [];
    var current = DateTime(start.year, start.month, 1);
    final endDate = DateTime(end.year, end.month, 1);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      _months.add(DateTime(current.year, current.month, 1));
      current = DateTime(current.year, current.month + 1, 1);
    }
    
    // Criar keys para cada mês
    for (int i = 0; i < _months.length; i++) {
      _monthKeys[i] = GlobalKey();
    }
  }

  void _scrollToCurrentMonth() {
    _scrollToMonth(DateTime.now());
  }
  
  // Método público para focar no dia atual (chamado pelo botão Today)
  void focusOnToday() {
    final today = DateTime.now();
    _scrollToMonth(today);
  }

  void _scrollToMonth(DateTime month) {
    if (!_scrollController.hasClients) {
      // Se o controller ainda não está pronto, tentar novamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _scrollToMonth(month);
        });
      });
      return;
    }
    
    final targetMonth = DateTime(month.year, month.month, 1);
    final index = _months.indexWhere((m) =>
        m.year == targetMonth.year && m.month == targetMonth.month);
    
    print('[MonthlyCalendar] Looking for month: $targetMonth, found at index: $index');
    print('[MonthlyCalendar] Total months: ${_months.length}');
    if (index >= 0 && index < _months.length) {
      print('[MonthlyCalendar] Month at index $index: ${_months[index]}');
    }
    
    if (index != -1) {
      // Aguardar um frame adicional para garantir que o widget está renderizado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Tentar usar a key do mês para scroll preciso
        final monthKey = _monthKeys[index];
        if (monthKey?.currentContext != null) {
          try {
            Scrollable.ensureVisible(
              monthKey!.currentContext!,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: 0.0, // Alinhar no topo
            );
            print('[MonthlyCalendar] Scrolled to month $index (${_months[index]}) using ensureVisible');
            return;
          } catch (e) {
            print('[MonthlyCalendar] Error using ensureVisible: $e');
          }
        }
        
        // Fallback: tentar calcular a posição real somando as alturas dos meses anteriores
        // Isso só funciona se os meses anteriores já foram renderizados
        double calculatedPosition = 0.0;
        bool canCalculate = true;
        
        for (int i = 0; i < index; i++) {
          final prevMonthKey = _monthKeys[i];
          if (prevMonthKey?.currentContext != null) {
            final renderBox = prevMonthKey!.currentContext!.findRenderObject() as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              calculatedPosition += renderBox.size.height;
            } else {
              canCalculate = false;
              break;
            }
          } else {
            canCalculate = false;
            break;
          }
        }
        
        if (canCalculate && calculatedPosition > 0) {
          print('[MonthlyCalendar] Scrolling to month $index at calculated position: $calculatedPosition');
          _scrollController.animateTo(
            calculatedPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          // Último fallback: usar estimativa baseada na altura média
          // Calcular altura média dos meses já renderizados
          double totalHeight = 0.0;
          int renderedCount = 0;
          
          for (int i = 0; i < index && i < _months.length; i++) {
            final prevMonthKey = _monthKeys[i];
            if (prevMonthKey?.currentContext != null) {
              final renderBox = prevMonthKey!.currentContext!.findRenderObject() as RenderBox?;
              if (renderBox != null && renderBox.hasSize) {
                totalHeight += renderBox.size.height;
                renderedCount++;
              }
            }
          }
          
          double averageHeight = renderedCount > 0 
              ? totalHeight / renderedCount 
              : 300.0; // Fallback para altura média se nenhum mês foi renderizado
          
          final estimatedPosition = index * averageHeight;
          print('[MonthlyCalendar] Scrolling to month $index at estimated position: $estimatedPosition (avg height: $averageHeight)');
          _scrollController.animateTo(
            estimatedPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    } else {
      print('[MonthlyCalendar] ERROR: Month not found in list: $targetMonth');
      print('[MonthlyCalendar] Available months (first 5): ${_months.take(5).toList()}');
      print('[MonthlyCalendar] Available months (last 5): ${_months.skip(_months.length - 5).toList()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dias da semana
        _buildWeekdayHeaders(),
        
        // Calendário scrollável
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _months.length,
            itemBuilder: (context, index) {
              return _MonthView(
                key: _monthKeys[index],
                month: _months[index],
                selectedDay: widget.selectedDay,
                onDayTap: widget.onDayTap,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthView extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDay;
  final Function(DateTime day, DailyEntry? entry) onDayTap;

  const _MonthView({
    super.key,
    required this.month,
    this.selectedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    
    var firstWeekday = firstDayOfMonth.weekday - 1;
    final daysInMonth = lastDayOfMonth.day;
    final today = DateTime.now();
    
    final totalCells = firstWeekday + daysInMonth;
    final weeks = (totalCells / 7).ceil();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          // Título do mês
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              DateFormat('MMMM yyyy', 'en').format(month),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Grade do calendário
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: weeks * 7,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return const SizedBox.shrink();
              }
              
              final dayOfMonth = index - firstWeekday + 1;
              if (dayOfMonth > daysInMonth) {
                return const SizedBox.shrink();
              }
              
              final day = DateTime(month.year, month.month, dayOfMonth);
              final entry = HiveService.getEntryByDate(day);
              final isSelected = selectedDay != null &&
                  _isSameDay(selectedDay!, day);
              final isToday = _isSameDay(today, day);
              
              return _DayCell(
                day: day,
                dayOfMonth: dayOfMonth,
                entry: entry,
                isSelected: isSelected,
                isToday: isToday,
                onTap: () => onDayTap(day, entry),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final int dayOfMonth;
  final DailyEntry? entry;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.dayOfMonth,
    this.entry,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : isToday
                    ? Colors.blue
                    : Colors.grey[300]!,
            width: isSelected ? 2 : isToday ? 1.5 : 1,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : isToday
                  ? Colors.blue.withOpacity(0.05)
                  : Colors.transparent,
        ),
        child: Stack(
          children: [
            // Thumbnail ou placeholder
            if (entry != null && entry!.thumbnailPath != null)
              _buildThumbnail(entry!.thumbnailPath!)
            else
              _buildPlaceholder(),
            
            // Número do dia
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.blue
                      : isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dayOfMonth.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Ícone de tipo de mídia
            if (entry != null)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    entry!.mediaType == 'video'
                        ? Icons.videocam
                        : Icons.camera_alt,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String thumbnailPath) {
    final file = File(thumbnailPath);
    
    if (!file.existsSync()) {
      return _buildPlaceholder();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    // Remover fundo cinza - deixar transparente ou preto
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparente em vez de cinza
        borderRadius: BorderRadius.circular(7),
      ),
      child: entry != null
          ? Center(
              child: Icon(
                entry!.mediaType == 'video'
                    ? Icons.videocam
                    : Icons.camera_alt,
                size: 16,
                color: Colors.grey[400],
              ),
            )
          : null, // Não mostrar nada quando não há entrada
    );
  }
}
