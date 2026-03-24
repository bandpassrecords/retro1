import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../services/video_editor_service.dart';

enum _AspectOption { original, landscape, square, portrait }

/// Full-screen trimmer with filmstrip + aspect-ratio crop overlay.
/// Pops with ({String path, bool muted}) or null if cancelled.
class VideoTrimmerScreen extends StatefulWidget {
  final String videoPath;
  const VideoTrimmerScreen({super.key, required this.videoPath});

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  // ── Video player ───────────────────────────────────────────────────────────
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isPlaying = true;

  // ── Trim state ─────────────────────────────────────────────────────────────
  int _selectedStartMs = 0;
  int _totalDurationMs = 0;

  // ── Audio ───────────────────────────────────────────────────────────────────
  bool _muteAudio = false;

  // ── Crop state ─────────────────────────────────────────────────────────────
  _AspectOption _aspectOption = _AspectOption.original;
  double _cropOffset = 0.5; // 0 = top/left  1 = bottom/right along draggable axis

  // Stored each frame layout build so drag callbacks can use it
  Size _videoDisplaySize = Size.zero;

  // ── Filmstrip ──────────────────────────────────────────────────────────────
  final ScrollController _filmscroll = ScrollController();
  final Map<int, String?> _thumbs = {};
  final Set<int> _requested = {};

  static const double _cellW = 56.0;
  static const double _stripH = 64.0;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _filmscroll.addListener(_onFilmscrollChanged);
    _initVideo();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _filmscroll.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.file(File(widget.videoPath));
      await ctrl.initialize();
      _controller = ctrl;
      _totalDurationMs = ctrl.value.duration.inMilliseconds;
      ctrl.addListener(_onVideoTick);
      if (!mounted) return;
      setState(() => _isInitialized = true);
      ctrl.play();
      for (int i = 0; i < 10; i++) {
        _loadThumb(i);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  // ── 1-second loop ──────────────────────────────────────────────────────────

  void _onVideoTick() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isPlaying) return;
    if (ctrl.value.position.inMilliseconds >= _selectedStartMs + 1000) {
      ctrl.seekTo(Duration(milliseconds: _selectedStartMs));
    }
  }

  // ── Thumbnail loading ──────────────────────────────────────────────────────

  void _loadThumb(int sec) {
    if (sec < 0 || _requested.contains(sec)) return;
    final maxSec = (_totalDurationMs / 1000).ceil();
    if (sec >= maxSec) return;
    _requested.add(sec);

    VideoEditorService.generateThumbnail(
      videoPath: widget.videoPath,
      timeMs: sec * 1000,
    ).then((path) {
      if (mounted) setState(() => _thumbs[sec] = path);
    });
  }

  // ── Filmstrip scroll ───────────────────────────────────────────────────────

  void _onFilmscrollChanged() {
    final offset = _filmscroll.offset.clamp(0.0, double.infinity);
    final rawSec = (offset / _cellW).round();
    final maxSec = ((_totalDurationMs - 1000) / 1000).floor().clamp(0, 999999);
    final selectedSec = rawSec.clamp(0, maxSec);
    final newStartMs = selectedSec * 1000;

    if (newStartMs != _selectedStartMs) {
      _selectedStartMs = newStartMs;
      _controller?.seekTo(Duration(milliseconds: newStartMs));
      if (_isPlaying) _controller?.play();

      for (int i = selectedSec - 2; i <= selectedSec + 6; i++) {
        _loadThumb(i);
      }
      if (mounted) setState(() {});
    }
  }

  // ── Crop helpers ───────────────────────────────────────────────────────────

  Size _computeVideoDisplaySize(BoxConstraints c, double ar) {
    final w = c.maxWidth;
    final h = c.maxHeight;
    final fittedH = w / ar;
    return fittedH <= h ? Size(w, fittedH) : Size(h * ar, h);
  }

  // Returns crop in native video pixels (always even for H.264).
  ({int x, int y, int w, int h})? _nativeCrop() {
    if (_aspectOption == _AspectOption.original || !_isInitialized) return null;
    final size = _controller!.value.size;
    if (size.width == 0 || size.height == 0) return null;
    final vw = (size.width ~/ 2) * 2;
    final vh = (size.height ~/ 2) * 2;

    int even(double v) => (v ~/ 2) * 2;

    switch (_aspectOption) {
      case _AspectOption.landscape:
        const ar = 16.0 / 9.0;
        if (vw / vh >= ar) {
          final cropW = even(vh * ar);
          final x = even((vw - cropW) * _cropOffset);
          return (x: x, y: 0, w: cropW, h: vh);
        } else {
          final cropH = even(vw / ar);
          final y = even((vh - cropH) * _cropOffset);
          return (x: 0, y: y, w: vw, h: cropH);
        }

      case _AspectOption.portrait:
        const ar = 9.0 / 16.0;
        if (vw / vh <= ar) {
          final cropH = even(vw / ar);
          final y = even((vh - cropH) * _cropOffset);
          return (x: 0, y: y, w: vw, h: cropH);
        } else {
          final cropW = even(vh * ar);
          final x = even((vw - cropW) * _cropOffset);
          return (x: x, y: 0, w: cropW, h: vh);
        }

      case _AspectOption.square:
        if (vw >= vh) {
          final cropW = vh;
          final x = even((vw - cropW) * _cropOffset);
          return (x: x, y: 0, w: cropW, h: vh);
        } else {
          final cropH = vw;
          final y = even((vh - cropH) * _cropOffset);
          return (x: 0, y: y, w: vw, h: cropH);
        }

      case _AspectOption.original:
        return null;
    }
  }

  Rect _displayCropRect(Size displaySize) {
    final nc = _nativeCrop();
    if (nc == null || !_isInitialized) {
      return Rect.fromLTWH(0, 0, displaySize.width, displaySize.height);
    }
    final ns = _controller!.value.size;
    if (ns.width == 0 || ns.height == 0) {
      return Rect.fromLTWH(0, 0, displaySize.width, displaySize.height);
    }
    final sx = displaySize.width / ns.width;
    final sy = displaySize.height / ns.height;
    return Rect.fromLTWH(nc.x * sx, nc.y * sy, nc.w * sx, nc.h * sy);
  }

  void _onCropDrag(DragUpdateDetails d) {
    final nc = _nativeCrop();
    if (nc == null || !_isInitialized || _videoDisplaySize == Size.zero) return;
    final ns = _controller!.value.size;
    final ds = _videoDisplaySize;

    final displayCropW = ds.width * nc.w / ns.width;
    final displayCropH = ds.height * nc.h / ns.height;
    final rangeX = ds.width - displayCropW;
    final rangeY = ds.height - displayCropH;

    setState(() {
      if (rangeY > 1) {
        _cropOffset = (_cropOffset + d.delta.dy / rangeY).clamp(0.0, 1.0);
      } else if (rangeX > 1) {
        _cropOffset = (_cropOffset + d.delta.dx / rangeX).clamp(0.0, 1.0);
      }
    });
  }

  CropParams? _buildCropParams() {
    final nc = _nativeCrop();
    if (nc == null) return null;
    final (outW, outH) = switch (_aspectOption) {
      _AspectOption.landscape => (1920, 1080),
      _AspectOption.portrait => (1080, 1920),
      _AspectOption.square => (1080, 1080),
      _AspectOption.original => (0, 0),
    };
    return CropParams(
      x: nc.x, y: nc.y, width: nc.w, height: nc.h,
      outWidth: outW, outHeight: outH,
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.seekTo(Duration(milliseconds: _selectedStartMs));
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  Future<void> _trimAndUse() async {
    if (_isProcessing) return;
    _controller?.pause();
    setState(() => _isProcessing = true);
    try {
      final path = await VideoEditorService.extractOneSecond(
        inputPath: widget.videoPath,
        startTimeMs: _selectedStartMs,
        crop: _buildCropParams(),
        muteAudio: _muteAudio,
      );
      if (path == null) throw Exception('Failed to trim video');
      if (mounted) Navigator.pop(context, (path: path, muted: _muteAudio));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error trimming: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.editorChooseSecond),
      ),
      body: Stack(
        children: [
          if (_isInitialized && _controller != null)
            Column(
              children: [
                // ── Video preview + crop overlay ──────────────────────────
                Expanded(
                  child: LayoutBuilder(builder: (ctx, constraints) {
                    final ar = _controller!.value.aspectRatio;
                    final displaySize =
                        _computeVideoDisplaySize(constraints, ar);
                    _videoDisplaySize = displaySize;
                    final cropRect = _displayCropRect(displaySize);
                    final hasCrop = _aspectOption != _AspectOption.original;

                    return GestureDetector(
                      onTap: _togglePlay,
                      onPanUpdate: hasCrop ? _onCropDrag : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: ar,
                            child: VideoPlayer(_controller!),
                          ),

                          // Crop overlay
                          if (hasCrop)
                            IgnorePointer(
                              child: SizedBox.fromSize(
                                size: displaySize,
                                child: CustomPaint(
                                  painter: _CropOverlayPainter(
                                    cropRect: cropRect,
                                    borderColor: primary,
                                  ),
                                ),
                              ),
                            ),

                          // Play/pause icon
                          ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: _controller!,
                            builder: (_, v, __) => AnimatedOpacity(
                              opacity: v.isPlaying ? 0 : 0.7,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.play_circle_fill,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

                // ── Progress bar + time label ─────────────────────────────
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (_, v, __) {
                    final posMs = v.position.inMilliseconds
                        .clamp(_selectedStartMs, _selectedStartMs + 1000);
                    final progress = (posMs - _selectedStartMs) / 1000.0;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.white12,
                              color: primary,
                              minHeight: 3,
                            ),
                          ),
                        ),
                        Text(
                          '${_fmt(_selectedStartMs)}  →  ${_fmt(_selectedStartMs + 1000)}'
                          '   /   ${_fmt(_totalDurationMs)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    );
                  },
                ),

                // ── Filmstrip ─────────────────────────────────────────────
                _buildFilmstrip(context),

                const SizedBox(height: 8),

                // ── Aspect ratio selector + mute toggle ───────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _AspectOption.values.map((opt) {
                            final selected = _aspectOption == opt;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _aspectOption = opt;
                                  _cropOffset = 0.5;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? primary.withValues(alpha: 0.25)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected ? primary : Colors.white24,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    _aspectLabel(opt),
                                    style: TextStyle(
                                      color: selected ? primary : Colors.white60,
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _muteAudio ? Icons.volume_off : Icons.volume_up,
                          color: _muteAudio ? primary : Colors.white54,
                        ),
                        onPressed: () => setState(() => _muteAudio = !_muteAudio),
                        tooltip: _muteAudio ? 'Unmute' : 'Mute',
                      ),
                    ],
                  ),
                ),

                // ── Save button ───────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _trimAndUse,
                    icon: const Icon(Icons.content_cut),
                    label: Text(l10n.save),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Filmstrip ──────────────────────────────────────────────────────────────

  Widget _buildFilmstrip(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final sidePad = (screenW - _cellW) / 2;
    final totalSecs = (_totalDurationMs / 1000).ceil().clamp(1, 999999);

    return SizedBox(
      height: _stripH + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ListView.builder(
            controller: _filmscroll,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            itemCount: totalSecs,
            itemBuilder: (_, i) {
              _loadThumb(i);
              final thumb = _thumbs[i];
              return SizedBox(
                width: _cellW,
                height: _stripH,
                child: thumb != null
                    ? Image.file(
                        File(thumb),
                        fit: BoxFit.cover,
                        width: _cellW,
                        height: _stripH,
                        gaplessPlayback: true,
                      )
                    : const ColoredBox(
                        color: Color(0xFF262626),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),

          // Fixed 1-second indicator
          IgnorePointer(
            child: Container(
              width: _cellW,
              height: _stripH + 8,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Gradient fades
          IgnorePointer(
            child: Row(
              children: [
                _buildFade(fromLeft: true, width: sidePad * 0.6),
                const Spacer(),
                _buildFade(fromLeft: false, width: sidePad * 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFade({required bool fromLeft, required double width}) {
    return SizedBox(
      width: width,
      height: _stripH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
            end: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
            colors: const [Colors.black, Colors.transparent],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _aspectLabel(_AspectOption opt) => switch (opt) {
        _AspectOption.original => 'Original',
        _AspectOption.landscape => 'Landscape',
        _AspectOption.square => 'Square',
        _AspectOption.portrait => 'Portrait',
      };

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    final frac = ms % 1000;
    return '${m.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}.'
        '${frac ~/ 100}';
  }
}

// ── Crop overlay painter ──────────────────────────────────────────────────────

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Color borderColor;

  const _CropOverlayPainter({required this.cropRect, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (!cropRect.isFinite || size.isEmpty) return;
    final fullRect = Offset.zero & size;

    // Dark mask with hole cut out
    final maskPath = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // Crop border
    canvas.drawRect(
      cropRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Corner handles
    const hs = 14.0;
    const hw = 3.0;
    final hp = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = hw
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(hs, 0), hp);
    canvas.drawLine(cropRect.topLeft, cropRect.topLeft + const Offset(0, hs), hp);
    // Top-right
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(-hs, 0), hp);
    canvas.drawLine(cropRect.topRight, cropRect.topRight + const Offset(0, hs), hp);
    // Bottom-left
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(hs, 0), hp);
    canvas.drawLine(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(0, -hs), hp);
    // Bottom-right
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(-hs, 0), hp);
    canvas.drawLine(cropRect.bottomRight, cropRect.bottomRight + const Offset(0, -hs), hp);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) =>
      old.cropRect != cropRect || old.borderColor != borderColor;
}
