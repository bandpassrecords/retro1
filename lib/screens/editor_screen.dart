import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/daily_entry.dart';
import '../services/hive_service.dart';
import '../services/video_editor_service.dart';

class EditorScreen extends StatefulWidget {
  final DailyEntry entry;
  final bool isNewEntry;

  const EditorScreen({
    super.key,
    required this.entry,
    this.isNewEntry = false,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  int _selectedStartTimeMs = 0;
  Duration? _videoDuration;
  Timer? _playbackTimer;
  bool _isPlaying = false;
  bool _isDragging = false;
  Timer? _seekDebounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedStartTimeMs = widget.entry.startTimeMs;
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(
        File(widget.entry.originalPath),
      );
      await _controller!.initialize();
      _videoDuration = _controller!.value.duration;
      _selectedStartTimeMs = _selectedStartTimeMs.clamp(
        0,
        (_videoDuration!.inMilliseconds - 1000).clamp(0, double.infinity).toInt(),
      );
      
      setState(() {
        _isInitialized = true;
      });
      
      _seekToSelectedTime();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar vídeo: $e')),
        );
      }
    }
  }

  void _seekToSelectedTime({bool immediate = false}) {
    if (_controller == null || !_isInitialized) return;
    
    // Se não for imediato e estiver arrastando, usar debounce
    if (!immediate && _isDragging) {
      _seekDebounceTimer?.cancel();
      _seekDebounceTimer = Timer(const Duration(milliseconds: 150), () {
        if (_controller != null && _isInitialized) {
          _controller!.seekTo(Duration(milliseconds: _selectedStartTimeMs));
        }
      });
      return;
    }
    
    // Seek imediato
    _controller!.seekTo(Duration(milliseconds: _selectedStartTimeMs));
  }

  void _playOneSecond() {
    if (_controller == null || !_isInitialized) return;

    _controller!.seekTo(Duration(milliseconds: _selectedStartTimeMs));
    _controller!.play();
    _isPlaying = true;

    _playbackTimer?.cancel();
    _playbackTimer = Timer(const Duration(milliseconds: 1000), () {
      _controller!.pause();
      _controller!.seekTo(Duration(milliseconds: _selectedStartTimeMs));
      setState(() {
        _isPlaying = false;
      });
    });

    setState(() {});
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _seekDebounceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor - Escolha 1 Segundo'),
        actions: [
          if (_isInitialized)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isProcessing ? null : _saveEntry,
            ),
        ],
      ),
      body: _isInitialized && _controller != null
          ? Column(
              children: [
                // Preview do vídeo
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),

                // Controles
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Slider para escolher o segundo
                      Text(
                        'Posição: ${_formatTime(_selectedStartTimeMs)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _selectedStartTimeMs.toDouble(),
                        min: 0,
                        max: (_videoDuration!.inMilliseconds - 1000)
                            .clamp(0, double.infinity)
                            .toDouble(),
                        divisions: (_videoDuration!.inMilliseconds / 100).floor(),
                        label: _formatTime(_selectedStartTimeMs),
                        onChangeStart: (value) {
                          setState(() {
                            _isDragging = true;
                            _selectedStartTimeMs = value.toInt();
                          });
                          // Pausar durante o arrasto para evitar conflitos
                          if (_controller != null && _controller!.value.isPlaying) {
                            _controller!.pause();
                          }
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedStartTimeMs = value.toInt();
                          });
                          // Seek com debounce durante o arrasto
                          _seekToSelectedTime();
                        },
                        onChangeEnd: (value) {
                          setState(() {
                            _isDragging = false;
                            _selectedStartTimeMs = value.toInt();
                          });
                          // Cancelar debounce e fazer seek imediato
                          _seekDebounceTimer?.cancel();
                          _seekToSelectedTime(immediate: true);
                        },
                      ),

                      // Botão de preview
                      ElevatedButton.icon(
                        onPressed: _playOneSecond,
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPlaying ? 'Reproduzindo...' : 'Preview (1s)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Informações
                      Text(
                        'Duração total: ${_formatTime(_videoDuration!.inMilliseconds)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  String _formatTime(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final ms = milliseconds % 1000;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}.'
        '${(ms ~/ 100).toString().padLeft(1, '0')}';
  }

  Future<void> _saveEntry() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Extrair o segundo selecionado
      final extractedPath = await VideoEditorService.extractOneSecond(
        inputPath: widget.entry.originalPath,
        startTimeMs: _selectedStartTimeMs,
      );

      if (extractedPath == null) {
        throw Exception('Erro ao extrair segundo do vídeo');
      }

      // Gerar thumbnail
      final thumbnailPath = await VideoEditorService.generateThumbnail(
        videoPath: extractedPath,
        timeMs: 0,
      );

      // Atualizar entrada
      final updatedEntry = DailyEntry(
        id: widget.entry.id,
        date: widget.entry.date,
        mediaType: widget.entry.mediaType,
        originalPath: extractedPath,
        startTimeMs: _selectedStartTimeMs,
        durationMs: 1000,
        caption: widget.entry.caption,
        createdAt: widget.entry.createdAt,
        timezone: widget.entry.timezone,
        thumbnailPath: thumbnailPath,
        hasAudio: widget.entry.hasAudio,
      );

      // Salvar
      await HiveService.saveEntry(updatedEntry);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrada salva com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
