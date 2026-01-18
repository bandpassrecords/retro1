import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/project_media_item.dart';
import '../services/hive_service.dart';
import '../services/video_editor_service.dart';

class VideoEditScreen extends StatefulWidget {
  final ProjectMediaItem mediaItem;

  const VideoEditScreen({super.key, required this.mediaItem});

  @override
  State<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends State<VideoEditScreen> {
  late ProjectMediaItem _item;
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  int _selectedStartTimeMs = 0;
  Duration? _videoDuration;
  double _playbackSpeed = 1.0;
  bool _muteAudio = false;
  String? _currentFilter = 'none';

  @override
  void initState() {
    super.initState();
    _item = widget.mediaItem;
    _selectedStartTimeMs = _item.startTimeMs;
    _playbackSpeed = _item.playbackSpeed ?? 1.0;
    _muteAudio = _item.muteAudio ?? false;
    _currentFilter = _item.filter ?? 'none';
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(
        File(_item.originalPath),
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
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  void _seekToSelectedTime() {
    if (_controller == null || !_isInitialized) return;
    _controller!.seekTo(Duration(milliseconds: _selectedStartTimeMs));
  }

  void _playOneSecond() {
    if (_controller == null || !_isInitialized) return;

    _controller!.seekTo(Duration(milliseconds: _selectedStartTimeMs));
    _controller!.play();
    _controller!.setPlaybackSpeed(_playbackSpeed);

    Timer(const Duration(milliseconds: 1000), () {
      _controller!.pause();
      _controller!.seekTo(Duration(milliseconds: _selectedStartTimeMs));
    });
  }

  Future<void> _saveEdits() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      _item.startTimeMs = _selectedStartTimeMs;
      _item.playbackSpeed = _playbackSpeed;
      _item.muteAudio = _muteAudio;
      _item.filter = _currentFilter;
      
      await HiveService.saveProjectMediaItem(_item);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edits saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Video'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEdits,
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Preview
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
                      // Slider de tempo
                      Text('Start Time: ${_selectedStartTimeMs}ms'),
                      Slider(
                        value: _selectedStartTimeMs.toDouble(),
                        min: 0,
                        max: (_videoDuration!.inMilliseconds - 1000).clamp(0, double.infinity).toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStartTimeMs = value.toInt();
                          });
                          _seekToSelectedTime();
                        },
                      ),
                      // Velocidade
                      Row(
                        children: [
                          const Text('Speed: '),
                          Expanded(
                            child: Slider(
                              value: _playbackSpeed,
                              min: 0.25,
                              max: 2.0,
                              divisions: 7,
                              label: '${_playbackSpeed}x',
                              onChanged: (value) {
                                setState(() {
                                  _playbackSpeed = value;
                                });
                              },
                            ),
                          ),
                          Text('${_playbackSpeed}x'),
                        ],
                      ),
                      // Mute
                      SwitchListTile(
                        title: const Text('Mute Audio'),
                        value: _muteAudio,
                        onChanged: (value) {
                          setState(() {
                            _muteAudio = value;
                          });
                        },
                      ),
                      // Botão play
                      ElevatedButton.icon(
                        onPressed: _playOneSecond,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Preview 1s'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
