import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../services/video_generator_service.dart';
import '../services/hive_service.dart';
import '../models/rendered_video.dart';
import '../services/video_editor_service.dart';
import 'rendered_videos_history_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';

class VideoGeneratorScreen extends StatefulWidget {
  const VideoGeneratorScreen({super.key});

  @override
  State<VideoGeneratorScreen> createState() => _VideoGeneratorScreenState();
}

class _VideoGeneratorScreenState extends State<VideoGeneratorScreen> {
  bool _isGenerating = false;
  String? _generatedVideoPath;
  String? _errorMessage;
  String? _selectedAudioPath;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.generateVideos),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RenderedVideosHistoryScreen(),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.renderedVideosHistory,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isGenerating)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.generatingVideo),
                  ],
                ),
              ),
            )
          else if (_generatedVideoPath != null)
            _buildSuccessCard()
          else ...[
            _buildAudioSelectionCard(),
            _buildSectionHeader(AppLocalizations.of(context)!.generateByPeriod),
            _buildGenerateButton(
              icon: Icons.calendar_month,
              title: AppLocalizations.of(context)!.currentMonth,
              subtitle: DateFormat('MMMM yyyy', Localizations.localeOf(context).toString())
                  .format(DateTime(currentYear, currentMonth)),
              onTap: () => _showMonthPicker(currentYear, currentMonth),
            ),
            _buildGenerateButton(
              icon: Icons.calendar_today,
              title: AppLocalizations.of(context)!.currentYear,
              subtitle: currentYear.toString(),
              onTap: () => _showYearPicker(currentYear),
            ),
            _buildGenerateButton(
              icon: Icons.date_range,
              title: AppLocalizations.of(context)!.customRange,
              subtitle: AppLocalizations.of(context)!.chooseDates,
              onTap: _showCustomRangeDialog,
            ),
          ],

          if (_errorMessage != null)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildGenerateButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPreview() async {
    if (_generatedVideoPath == null) return;

    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(File(_generatedVideoPath!));
      await _videoController!.initialize();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('[VideoGenerator] Error initializing video preview: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  Widget _buildSuccessCard() {
    // Inicializar vídeo quando o card for exibido
    if (_generatedVideoPath != null && !_isVideoInitialized && _videoController == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeVideoPreview();
      });
    }

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.videoGeneratedSuccess,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Preview do vídeo
            if (_isVideoInitialized && _videoController != null)
              _buildVideoPreview()
            else if (_generatedVideoPath != null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _shareVideo,
                  icon: const Icon(Icons.share),
                  label: Text(AppLocalizations.of(context)!.share),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _videoController?.dispose();
                    _videoController = null;
                    setState(() {
                      _generatedVideoPath = null;
                      _errorMessage = null;
                      _isVideoInitialized = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.newButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_isVideoInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              // Controles de play/pause
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateMonthVideo(int year, int month) async {
    final entries = HiveService.getEntriesByMonth(year, month);
    if (entries.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.noEntriesForMonth;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedVideoPath = null;
    });

    try {
      final settings = HiveService.getSettings();
      final path = await VideoGeneratorService.generateMonthVideo(
        year: year,
        month: month,
        quality: settings.videoQuality,
        showDateOverlay: settings.showDateOverlay,
        externalAudioPath: _selectedAudioPath,
      );

      if (path != null && mounted) {
        // Gerar thumbnail
        final thumbnailPath = await VideoEditorService.generateThumbnail(
          videoPath: path,
          timeMs: 0,
        );
        
        // Obter duração do vídeo
        final duration = await VideoEditorService.getVideoDuration(path);
        final durationSeconds = duration?.inSeconds ?? 0;
        
        // Salvar vídeo renderizado no histórico
        final renderedVideo = RenderedVideo(
          id: const Uuid().v4(),
          videoPath: path,
          title: DateFormat('MMMM yyyy', Localizations.localeOf(context).toString())
              .format(DateTime(year, month, 1)),
          type: 'calendar',
          createdAt: DateTime.now(),
          thumbnailPath: thumbnailPath,
          durationSeconds: durationSeconds,
          metadata: {
            'year': year,
            'month': month,
            'quality': settings.videoQuality,
            'showDateOverlay': settings.showDateOverlay,
          },
        );
        await HiveService.saveRenderedVideo(renderedVideo);
        
        setState(() {
          _generatedVideoPath = path;
          _isGenerating = false;
          _isVideoInitialized = false;
        });
      } else {
        final l10n = AppLocalizations.of(context)!;
        throw Exception(l10n.errorGeneratingVideo('Unknown error'));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.errorGeneratingVideo(e.toString());
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _generateYearVideo(int year) async {
    final entries = HiveService.getEntriesByYear(year);
    if (entries.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.noEntriesForYear;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedVideoPath = null;
    });

    try {
      final settings = HiveService.getSettings();
      final path = await VideoGeneratorService.generateYearVideo(
        year: year,
        quality: settings.videoQuality,
        showDateOverlay: settings.showDateOverlay,
        externalAudioPath: _selectedAudioPath,
      );

      if (path != null && mounted) {
        // Gerar thumbnail
        final thumbnailPath = await VideoEditorService.generateThumbnail(
          videoPath: path,
          timeMs: 0,
        );
        
        // Obter duração do vídeo
        final duration = await VideoEditorService.getVideoDuration(path);
        final durationSeconds = duration?.inSeconds ?? 0;
        
        // Salvar vídeo renderizado no histórico
        final renderedVideo = RenderedVideo(
          id: const Uuid().v4(),
          videoPath: path,
          title: year.toString(),
          type: 'calendar',
          createdAt: DateTime.now(),
          thumbnailPath: thumbnailPath,
          durationSeconds: durationSeconds.toInt(),
          metadata: {
            'year': year,
            'quality': settings.videoQuality,
            'showDateOverlay': settings.showDateOverlay,
          },
        );
        await HiveService.saveRenderedVideo(renderedVideo);
        
        setState(() {
          _generatedVideoPath = path;
          _isGenerating = false;
          _isVideoInitialized = false;
        });
      } else {
        final l10n = AppLocalizations.of(context)!;
        throw Exception(l10n.errorGeneratingVideo('Unknown error'));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.errorGeneratingVideo(e.toString());
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _showCustomRangeDialog() async {
    final startDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (startDate == null) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: startDate.add(const Duration(days: 30)),
      firstDate: startDate,
      lastDate: DateTime.now(),
    );

    if (endDate == null) return;

    final entries = HiveService.getEntriesByDateRange(startDate, endDate);
    if (entries.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.noEntriesFound;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedVideoPath = null;
    });

    try {
      final settings = HiveService.getSettings();
      final path = await VideoGeneratorService.generateCustomVideo(
        startDate: startDate,
        endDate: endDate,
        quality: settings.videoQuality,
        showDateOverlay: settings.showDateOverlay,
        externalAudioPath: _selectedAudioPath,
      );

      if (path != null && mounted) {
        // Gerar thumbnail
        final thumbnailPath = await VideoEditorService.generateThumbnail(
          videoPath: path,
          timeMs: 0,
        );
        
        // Obter duração do vídeo
        final duration = await VideoEditorService.getVideoDuration(path);
        final durationSeconds = duration?.inSeconds ?? 0;
        
        // Salvar vídeo renderizado no histórico
        final dateFormat = DateFormat('dd-MM-yyyy', Localizations.localeOf(context).toString());
        final renderedVideo = RenderedVideo(
          id: const Uuid().v4(),
          videoPath: path,
          title: '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
          type: 'calendar',
          createdAt: DateTime.now(),
          thumbnailPath: thumbnailPath,
          durationSeconds: durationSeconds.toInt(),
          metadata: {
            'startDate': startDate.toIso8601String(),
            'endDate': endDate.toIso8601String(),
            'quality': settings.videoQuality,
            'showDateOverlay': settings.showDateOverlay,
          },
        );
        await HiveService.saveRenderedVideo(renderedVideo);
        
        setState(() {
          _generatedVideoPath = path;
          _isGenerating = false;
          _isVideoInitialized = false;
        });
      } else {
        final l10n = AppLocalizations.of(context)!;
        throw Exception(l10n.errorGeneratingVideo('Unknown error'));
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.errorGeneratingVideo(e.toString());
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _shareVideo() async {
    if (_generatedVideoPath == null) return;

    try {
      final l10n = AppLocalizations.of(context)!;
      await Share.shareXFiles(
        [XFile(_generatedVideoPath!)],
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

  Widget _buildAudioSelectionCard() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.useExternalAudio,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedAudioPath != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.audioFileSelected}: ${_getFileName(_selectedAudioPath!)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedAudioPath = null;
                      });
                    },
                    tooltip: l10n.removeAudio,
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _selectAudioFile,
                icon: const Icon(Icons.audiotrack),
                label: Text(l10n.selectAudioFile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudioPath = result.files.single.path!;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSelectingAudio(e.toString()))),
        );
      }
    }
  }

  String _getFileName(String path) {
    final file = File(path);
    return file.path.split('/').last.split('\\').last;
  }

  Future<void> _showMonthPicker(int defaultYear, int defaultMonth) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    int selectedYear = defaultYear;
    int selectedMonth = defaultMonth;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        l10n.selectMonth,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Seletor de ano
                      ListTile(
                        title: Text(l10n.year),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: selectedYear > 2020
                                  ? () {
                                      setDialogState(() {
                                        selectedYear--;
                                      });
                                    }
                                  : null,
                            ),
                            Text(
                              selectedYear.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: selectedYear < now.year
                                  ? () {
                                      setDialogState(() {
                                        selectedYear++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Grid de meses
                      SizedBox(
                        height: 200, // Altura fixa para o grid
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final month = index + 1;
                            final isSelected = month == selectedMonth;
                            final monthName = DateFormat('MMM', Localizations.localeOf(context).toString())
                                .format(DateTime(selectedYear, month));
                            
                            // Desabilitar meses futuros
                            final isFuture = selectedYear == now.year && month > now.month;
                            
                            return InkWell(
                              onTap: isFuture ? null : () {
                                setDialogState(() {
                                  selectedMonth = month;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    monthName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isFuture ? Colors.grey[400] : Colors.black),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Botões
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancel),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, {
                                'year': selectedYear,
                                'month': selectedMonth,
                              });
                            },
                            child: Text(l10n.generate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      _generateMonthVideo(result['year']!, result['month']!);
    }
  }

  Future<void> _showYearPicker(int defaultYear) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    int selectedYear = defaultYear;

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  maxHeight: 500,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        l10n.selectYear,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Lista de anos disponíveis
                      Flexible(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: now.year - 2020 + 1,
                            itemBuilder: (context, index) {
                              final year = now.year - index;
                              final isSelected = year == selectedYear;
                              
                              return ListTile(
                                title: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Theme.of(context).colorScheme.primary,
                                      )
                                    : null,
                                onTap: () {
                                  setDialogState(() {
                                    selectedYear = year;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Botões
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancel),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, selectedYear);
                            },
                            child: Text(l10n.generate),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      _generateYearVideo(result);
    }
  }
}
