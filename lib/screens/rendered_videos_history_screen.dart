import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:video_player/video_player.dart';
import '../models/rendered_video.dart';
import '../services/hive_service.dart';
import '../services/video_editor_service.dart';
import 'rendered_video_player_screen.dart';

class RenderedVideosHistoryScreen extends StatefulWidget {
  const RenderedVideosHistoryScreen({super.key});

  @override
  State<RenderedVideosHistoryScreen> createState() => _RenderedVideosHistoryScreenState();
}

class _RenderedVideosHistoryScreenState extends State<RenderedVideosHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RenderedVideo> _calendarVideos = [];
  List<RenderedVideo> _projectVideos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVideos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    // Pequeno delay para mostrar o indicador de refresh
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _calendarVideos = HiveService.getRenderedVideosByType('calendar');
        _projectVideos = HiveService.getRenderedVideosByType('project');
      });
    }
  }

  Future<void> _shareVideo(RenderedVideo video) async {
    try {
      final file = File(video.videoPath);
      if (!await file.exists()) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.videoFileNotFound)),
          );
        }
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      await Share.shareXFiles(
        [XFile(video.videoPath)],
        text: l10n.renderedVideo,
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSharing(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteVideo(RenderedVideo video) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(l10n.confirmDeleteRenderedVideo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Deletar arquivo de vídeo
      try {
        final file = File(video.videoPath);
        if (await file.exists()) {
          await file.delete();
        }
        // Deletar thumbnail se existir
        if (video.thumbnailPath != null) {
          final thumbFile = File(video.thumbnailPath!);
          if (await thumbFile.exists()) {
            await thumbFile.delete();
          }
        }
      } catch (e) {
        print('[RenderedVideosHistory] Error deleting files: $e');
      }

      // Deletar do banco de dados
      await HiveService.deleteRenderedVideo(video.id);
      _loadVideos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.videoDeleted)),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.renderedVideosHistory),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.calendar),
            Tab(text: l10n.projects),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideoList(_calendarVideos, locale),
          _buildVideoList(_projectVideos, locale),
        ],
      ),
    );
  }

  Widget _buildVideoList(List<RenderedVideo> videos, Locale locale) {
    if (videos.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return RefreshIndicator(
        onRefresh: _loadVideos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noRenderedVideos,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return _buildVideoCard(video, locale);
        },
      ),
    );
  }

  Widget _buildVideoCard(RenderedVideo video, Locale locale) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', locale.toString());
    final file = File(video.videoPath);
    final exists = file.existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: _buildThumbnail(video),
        title: Text(
          video.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(video.createdAt)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(video.durationSeconds),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (!exists) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.warning, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    l10n.fileNotFound,
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: exists,
              child: Row(
                children: [
                  const Icon(Icons.share),
                  const SizedBox(width: 8),
                  Text(l10n.share),
                ],
              ),
              onTap: exists ? () => _shareVideo(video) : null,
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => _deleteVideo(video),
            ),
          ],
        ),
        onTap: exists
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RenderedVideoPlayerScreen(
                      videoPath: video.videoPath,
                      title: video.title,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Widget _buildThumbnail(RenderedVideo video) {
    if (video.thumbnailPath != null) {
      final thumbFile = File(video.thumbnailPath!);
      if (thumbFile.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(
            thumbFile,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderThumbnail();
            },
          ),
        );
      }
    }
    return _buildPlaceholderThumbnail();
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.videocam, color: Colors.grey),
    );
  }
}
