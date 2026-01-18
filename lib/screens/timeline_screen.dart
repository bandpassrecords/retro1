import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import 'video_preview_screen.dart';
import 'editor_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int _selectedYear = DateTime.now().year;
  String _filter = 'all'; // 'all', 'video', 'photo'

  @override
  Widget build(BuildContext context) {
    final entries = _getFilteredEntries();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.timeline),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text(AppLocalizations.of(context)!.all)),
              PopupMenuItem(value: 'video', child: Text(AppLocalizations.of(context)!.videosOnly)),
              PopupMenuItem(value: 'photo', child: Text(AppLocalizations.of(context)!.photosOnly)),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de ano
          _buildYearSelector(),
          
          // Lista de entradas
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma entrada encontrada',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return _buildEntryTile(entries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (i) => currentYear - i);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = year == _selectedYear;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilterChip(
              label: Text(year.toString()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedYear = year;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntryTile(DailyEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.mediaType == 'video'
              ? Colors.red
              : Colors.blue,
          child: Icon(
            entry.mediaType == 'video' ? Icons.videocam : Icons.camera_alt,
            color: Colors.white,
          ),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy - EEEE', 'pt').format(entry.date),
        ),
        subtitle: entry.caption != null && entry.caption!.isNotEmpty
            ? Text(entry.caption!)
            : Text(
                entry.mediaType == 'video' ? 'Vídeo' : 'Foto',
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(entry: entry),
            ),
          );
        },
        onLongPress: () {
          _showEntryOptions(entry);
        },
      ),
    );
  }

  List<DailyEntry> _getFilteredEntries() {
    List<DailyEntry> entries = HiveService.getEntriesByYear(_selectedYear);

    if (_filter == 'video') {
      entries = entries.where((e) => e.mediaType == 'video').toList();
    } else if (_filter == 'photo') {
      entries = entries.where((e) => e.mediaType == 'photo').toList();
    }

    return entries;
  }

  void _showEntryOptions(DailyEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppLocalizations.of(context)!.edit),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditorScreen(entry: entry),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(AppLocalizations.of(context)!.delete),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Text(AppLocalizations.of(context)!.confirmDeletionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              HiveService.deleteEntry(entry.id);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.entryDeleted)),
              );
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
