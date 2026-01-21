import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:retro1/l10n/app_localizations.dart';

class RenderedVideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String title;

  const RenderedVideoPlayerScreen({
    super.key,
    required this.videoPath,
    required this.title,
  });

  @override
  State<RenderedVideoPlayerScreen> createState() => _RenderedVideoPlayerScreenState();
}

class _RenderedVideoPlayerScreenState extends State<RenderedVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isFullscreen = false;
  bool _showControls = true;
  bool _wasPlayingBeforeFullscreen = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not found';
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      _controller!.setLooping(false);
      
      // Add listener to update UI when video state changes
      _controller!.addListener(_videoListener);
      
      setState(() {
        _isInitialized = true;
      });
      
      _startHideControlsTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _videoListener() {
    if (_controller != null && mounted) {
      setState(() {});
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_controller?.value.isPlaying == true) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _controller?.value.isPlaying == true) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    // Exit fullscreen if active
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
        _startHideControlsTimer();
      } else {
        _controller!.play();
        _showControls = true;
        _startHideControlsTimer();
      }
    });
  }

  void _toggleFullscreen() async {
    if (!_isFullscreen) {
      // Enter fullscreen
      _wasPlayingBeforeFullscreen = _controller?.value.isPlaying ?? false;
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
      setState(() {
        _isFullscreen = true;
        _showControls = true;
      });
      _startHideControlsTimer();
    } else {
      // Exit fullscreen
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      setState(() {
        _isFullscreen = false;
        _showControls = true;
      });
      _startHideControlsTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _seekTo(Duration position) {
    _controller?.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        if (_isFullscreen) {
          _toggleFullscreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullscreen
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
        body: _hasError
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? l10n.errorLoadingVideo('Unknown error'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              )
            : !_isInitialized
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        _showControls = !_showControls;
                      });
                      if (_showControls) {
                        _startHideControlsTimer();
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller?.value.aspectRatio ?? 16 / 9,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                        if (_showControls) _buildControls(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildControls() {
    if (_controller == null) return const SizedBox.shrink();

    final duration = _controller!.value.duration;
    final position = _controller!.value.position;
    final isPlaying = _controller!.value.isPlaying;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top controls
          if (!_isFullscreen)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: _toggleFullscreen,
                    ),
                  ],
                ),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                      onPressed: _toggleFullscreen,
                    ),
                  ],
                ),
              ),
            ),

          // Center play/pause button
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),

          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Seekbar
                VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.red,
                    bufferedColor: Colors.grey[300]!,
                    backgroundColor: Colors.grey[600]!,
                  ),
                ),
                const SizedBox(height: 8),
                // Time and controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        if (!_isFullscreen)
                          IconButton(
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                            onPressed: _toggleFullscreen,
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                            onPressed: _toggleFullscreen,
                          ),
                      ],
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
