import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import 'dart:async';

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
  int _monthsToShow = 2; // Começar com 2 meses (últimos ~60 dias)

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _generateMonths();
    
    // Garantir que o calendário mostre o dia atual ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToCurrentMonth();
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
    // Gerar apenas os últimos N meses (começando com 2 meses = ~60 dias)
    // Sempre incluir o mês atual e os meses anteriores
    _months = [];
    
    // Começar do mês atual e ir para trás
    var current = DateTime(today.year, today.month, 1);
    
    for (int i = 0; i < _monthsToShow; i++) {
      _months.add(DateTime(current.year, current.month, 1));
      // Ir para o mês anterior
      if (current.month == 1) {
        current = DateTime(current.year - 1, 12, 1);
      } else {
        current = DateTime(current.year, current.month - 1, 1);
      }
    }
    
    // Reverter para mostrar do mais antigo para o mais recente (topo para baixo)
    _months = _months.reversed.toList();
    
    // Criar/atualizar keys para cada mês
    for (int i = 0; i < _months.length; i++) {
      if (!_monthKeys.containsKey(i)) {
        _monthKeys[i] = GlobalKey();
      }
    }
  }

  void _loadMoreMonths() {
    setState(() {
      _monthsToShow += 2; // Carregar mais 2 meses
      _generateMonths();
    });
  }

  void _scrollToCurrentMonth() {
    // Como sempre mostramos o mês atual no final da lista, scroll para o final
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
  
  // Método público para focar no dia atual (chamado pelo botão Today)
  void focusOnToday() {
    _scrollToCurrentMonth();
  }

  // Método público para forçar refresh do calendário
  void refresh() {
    if (mounted) {
      setState(() {});
    }
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
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _months.length + 1, // +1 para o botão "Load More" no topo
        itemBuilder: (context, index) {
          // Se for o primeiro item (index 0), mostrar botão "Load More"
          if (index == 0) {
            return _buildLoadMoreButton();
          }
          
          // Ajustar index para acessar os meses (index - 1 porque o primeiro é o botão)
          final monthIndex = index - 1;
          return _MonthView(
            key: _monthKeys[monthIndex],
            month: _months[monthIndex],
            selectedDay: widget.selectedDay,
            onDayTap: widget.onDayTap,
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: _loadMoreMonths,
          icon: const Icon(Icons.expand_more),
          label: Text(l10n.loadMoreDays),
        ),
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
    final l10n = AppLocalizations.of(context)!;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    
    var firstWeekday = firstDayOfMonth.weekday - 1;
    final daysInMonth = lastDayOfMonth.day;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    
    // Obter locale do contexto para formatação do mês
    final locale = Localizations.localeOf(context);
    final monthName = DateFormat('MMMM yyyy', locale.toString()).format(month);
    
    // Dias da semana
    final weekdays = [
      l10n.mondayShort,
      l10n.tuesdayShort,
      l10n.wednesdayShort,
      l10n.thursdayShort,
      l10n.fridayShort,
      l10n.saturdayShort,
      l10n.sundayShort,
    ];
    
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
              monthName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Cabeçalho dos dias da semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
              final dayDateOnly = DateTime(day.year, day.month, day.day);
              
              // Não mostrar dias futuros
              if (dayDateOnly.isAfter(todayDateOnly)) {
                return const SizedBox.shrink();
              }
              
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
    
    // Verificar se é uma imagem (não um vídeo)
    final extension = thumbnailPath.toLowerCase();
    final isImage = extension.endsWith('.jpg') || 
                    extension.endsWith('.jpeg') || 
                    extension.endsWith('.png') || 
                    extension.endsWith('.bmp') || 
                    extension.endsWith('.webp');
    
    // Se não for uma imagem, não tentar exibir como Image.file
    if (!isImage) {
      print('[MonthlyCalendar] WARNING: thumbnailPath is not an image: $thumbnailPath');
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
          print('[MonthlyCalendar] Error loading thumbnail: $error');
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
