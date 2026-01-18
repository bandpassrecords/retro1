import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../services/video_generator_service.dart';
import '../services/hive_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

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

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.getSettings();
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar Vídeos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isGenerating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Gerando vídeo... Isso pode levar alguns minutos.'),
                  ],
                ),
              ),
            )
          else if (_generatedVideoPath != null)
            _buildSuccessCard()
          else ...[
            _buildAudioSelectionCard(),
            _buildSectionHeader('Gerar por Período'),
            _buildGenerateButton(
              icon: Icons.calendar_month,
              title: 'Mês Atual',
              subtitle: DateFormat('MMMM yyyy', 'pt')
                  .format(DateTime(currentYear, currentMonth)),
              onTap: () => _generateMonthVideo(currentYear, currentMonth),
            ),
            _buildGenerateButton(
              icon: Icons.calendar_today,
              title: 'Ano Atual',
              subtitle: currentYear.toString(),
              onTap: () => _generateYearVideo(currentYear),
            ),
            _buildGenerateButton(
              icon: Icons.date_range,
              title: 'Intervalo Customizado',
              subtitle: 'Escolha as datas',
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

  Widget _buildSuccessCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Vídeo gerado com sucesso!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _shareVideo,
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _generatedVideoPath = null;
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Novo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateMonthVideo(int year, int month) async {
    final entries = HiveService.getEntriesByMonth(year, month);
    if (entries.isEmpty) {
      setState(() {
        _errorMessage = 'Nenhuma entrada encontrada para este mês.';
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
        setState(() {
          _generatedVideoPath = path;
          _isGenerating = false;
        });
      } else {
        throw Exception('Erro ao gerar vídeo');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao gerar vídeo: $e';
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _generateYearVideo(int year) async {
    final entries = HiveService.getEntriesByYear(year);
    if (entries.isEmpty) {
      setState(() {
        _errorMessage = 'Nenhuma entrada encontrada para este ano.';
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
        setState(() {
          _generatedVideoPath = path;
          _isGenerating = false;
        });
      } else {
        throw Exception('Erro ao gerar vídeo');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao gerar vídeo: $e';
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
      setState(() {
        _errorMessage = 'Nenhuma entrada encontrada para este período.';
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
        setState(() {
          _generatedVideoPath = path;
          _isGenerating = false;
        });
      } else {
        throw Exception('Erro ao gerar vídeo');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao gerar vídeo: $e';
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _shareVideo() async {
    if (_generatedVideoPath == null) return;

    try {
      await Share.shareXFiles(
        [XFile(_generatedVideoPath!)],
        text: 'Meu vídeo do One Second Per Day',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar áudio: $e')),
        );
      }
    }
  }

  String _getFileName(String path) {
    final file = File(path);
    return file.path.split('/').last.split('\\').last;
  }
}
