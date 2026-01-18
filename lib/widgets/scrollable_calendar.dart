import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';

class ScrollableCalendar extends StatelessWidget {
  final DateTime? selectedDay;
  final Function(DateTime day, DailyEntry? entry) onDayTap;
  final DateTime startDate;
  final DateTime endDate;

  ScrollableCalendar({
    super.key,
    this.selectedDay,
    required this.onDayTap,
    DateTime? startDate,
    DateTime? endDate,
  })  : startDate = startDate ?? DateTime(2020, 1, 1),
        endDate = endDate ?? DateTime(2030, 12, 31);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = _generateDaysList();
    
    return ListView.builder(
      itemCount: days.length,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemBuilder: (context, index) {
        final day = days[index];
        final entry = HiveService.getEntryByDate(day);
        final isSelected = selectedDay != null && 
            _isSameDay(selectedDay!, day);
        final isToday = _isSameDay(today, day);
        
        return _DayTile(
          day: day,
          entry: entry,
          isSelected: isSelected,
          isToday: isToday,
          onTap: () => onDayTap(day, entry),
        );
      },
    );
  }

  List<DateTime> _generateDaysList() {
    final days = <DateTime>[];
    final today = DateTime.now();
    // Mostrar apenas os últimos 2 anos e próximos 2 anos (para performance)
    final start = DateTime(today.year - 2, 1, 1);
    final end = DateTime(today.year + 2, 12, 31);
    
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(DateTime(current.year, current.month, current.day));
      current = current.add(const Duration(days: 1));
    }
    
    // Reverter para mostrar os dias mais recentes primeiro
    return days.reversed.toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayTile extends StatelessWidget {
  final DateTime day;
  final DailyEntry? entry;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayTile({
    required this.day,
    this.entry,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'en');
    final shortDateFormat = DateFormat('dd/MM/yyyy');
    final weekdayFormat = DateFormat('EEEE', 'en');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Thumbnail
              _buildThumbnail(context),
              
              const SizedBox(width: 12),
              
              // Informações do dia
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dateFormat.format(day),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortDateFormat.format(day),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (entry != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            entry!.mediaType == 'video'
                                ? Icons.videocam
                                : Icons.camera_alt,
                            size: 14,
                            color: entry!.mediaType == 'video'
                                ? Colors.red
                                : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry!.mediaType == 'video' ? 'Video' : 'Photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (entry!.caption != null &&
                              entry!.caption!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry!.caption!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'No entry',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Ícone de ação
              Icon(
                entry != null ? Icons.play_circle_outline : Icons.add_circle_outline,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: entry != null && entry!.thumbnailPath != null
            ? _buildThumbnailImage(entry!.thumbnailPath!)
            : _buildPlaceholder(entry),
      ),
    );
  }

  Widget _buildThumbnailImage(String thumbnailPath) {
    final file = File(thumbnailPath);
    
    if (!file.existsSync()) {
      return _buildPlaceholder(entry);
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
      print('[ScrollableCalendar] WARNING: thumbnailPath is not an image: $thumbnailPath');
      return _buildPlaceholder(entry);
    }
    
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('[ScrollableCalendar] Error loading thumbnail: $error');
        return _buildPlaceholder(entry);
      },
    );
  }

  Widget _buildPlaceholder(DailyEntry? entry) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: entry != null
            ? Icon(
                entry.mediaType == 'video'
                    ? Icons.videocam
                    : Icons.camera_alt,
                size: 32,
                color: entry.mediaType == 'video'
                    ? Colors.red[300]
                    : Colors.blue[300],
              )
            : Icon(
                Icons.calendar_today,
                size: 32,
                color: Colors.grey[400],
              ),
      ),
    );
  }
}
