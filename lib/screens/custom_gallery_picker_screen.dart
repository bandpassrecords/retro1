import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../services/timeline_prefs.dart';
import 'video_trimmer_screen.dart';

class GalleryPickerResult {
  final String path;
  final String mediaType; // 'video' or 'photo'
  final bool muteAudio;
  const GalleryPickerResult({
    required this.path,
    required this.mediaType,
    this.muteAudio = false,
  });
}

class CustomGalleryPickerScreen extends StatefulWidget {
  /// When set, only media created on this date will be shown.
  final DateTime? filterDate;

  const CustomGalleryPickerScreen({super.key, this.filterDate});

  @override
  State<CustomGalleryPickerScreen> createState() =>
      _CustomGalleryPickerScreenState();
}

enum _MediaFilter { all, photos, videos }

class _CustomGalleryPickerScreenState
    extends State<CustomGalleryPickerScreen> {
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  int _currentPage = 0;
  static const int _pageSize = 80;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  _MediaFilter _mediaFilter = _MediaFilter.all;
  bool _filterByDate = false; // only relevant when widget.filterDate != null

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _assets = [];
      _currentPage = 0;
      _hasMore = true;
    });

    // Clear cached album data so new media is always visible
    await PhotoManager.clearFileCache();

    final permission = await PhotoManager.requestPermissionExtend();
    // hasAccess covers both 'authorized' and 'limited' (Android 14+ partial access)
    if (!permission.hasAccess) {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
      return;
    }

    setState(() => _hasPermission = true);
    await _fetchPage(0);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchPage(int page) async {
    final date = widget.filterDate;

    final orders = [
      const OrderOption(type: OrderOptionType.createDate, asc: false)
    ];
    FilterOptionGroup filterOption;
    if (date != null && _filterByDate) {
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
      filterOption = FilterOptionGroup(
        createTimeCond: DateTimeCond(min: dayStart, max: dayEnd),
        orders: orders,
      );
    } else {
      filterOption = FilterOptionGroup(orders: orders);
    }

    final requestType = switch (_mediaFilter) {
      _MediaFilter.all => RequestType.common,
      _MediaFilter.photos => RequestType.image,
      _MediaFilter.videos => RequestType.video,
    };

    final albums = await PhotoManager.getAssetPathList(
      type: requestType,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      setState(() => _hasMore = false);
      return;
    }

    final assets = await albums.first.getAssetListPaged(
      page: page,
      size: _pageSize,
    );

    setState(() {
      if (page == 0) {
        _assets = assets;
      } else {
        _assets = [..._assets, ...assets];
      }
      _hasMore = assets.length == _pageSize;
      _currentPage = page;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _fetchPage(_currentPage + 1);
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.browseGallery),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadAssets,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(widget.filterDate != null ? 96 : 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<_MediaFilter>(
                  segments: [
                    ButtonSegment(
                      value: _MediaFilter.all,
                      icon: const Icon(Icons.perm_media, size: 16),
                      label: Text(l10n.mediaFilterAll),
                    ),
                    ButtonSegment(
                      value: _MediaFilter.photos,
                      icon: const Icon(Icons.photo, size: 16),
                      label: Text(l10n.mediaFilterPhotos),
                    ),
                    ButtonSegment(
                      value: _MediaFilter.videos,
                      icon: const Icon(Icons.videocam, size: 16),
                      label: Text(l10n.mediaFilterVideos),
                    ),
                  ],
                  selected: {_mediaFilter},
                  onSelectionChanged: (selection) {
                    setState(() => _mediaFilter = selection.first);
                    _loadAssets();
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (widget.filterDate != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      label: Text(AppLocalizations.of(context)!.today),
                      avatar: const Icon(Icons.today, size: 14),
                      selected: _filterByDate,
                      onSelected: (value) {
                        setState(() => _filterByDate = value);
                        _loadAssets();
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.permissionDenied, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAssets,
              child: Text(l10n.refresh),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await PhotoManager.openSetting();
                await _loadAssets();
              },
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
    }

    if (_assets.isEmpty) {
      return Center(child: Text(l10n.noMediaFound));
    }

    return ValueListenableBuilder<String?>(
      valueListenable: ThumbnailSizePrefs.notifier,
      builder: (context, _, __) => GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ThumbnailSizePrefs.crossAxisCount,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _assets.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _assets.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _AssetThumbnail(
          asset: _assets[index],
          onTap: () => _onAssetTapped(_assets[index]),
        );
      },
    ),
    );
  }

  Future<void> _onAssetTapped(AssetEntity asset) async {
    if (!mounted) return;

    // Show loading while fetching the file from the device
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final file = await asset.file;

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading dialog

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.errorAccessingFile)),
      );
      return;
    }

    if (asset.type == AssetType.video) {
      // Videos go straight to the trimmer — user picks the 1-second window
      // before the file is imported into the app.
      final result = await Navigator.push<({String path, bool muted})>(
        context,
        MaterialPageRoute(
          builder: (_) => VideoTrimmerScreen(videoPath: file.path),
        ),
      );
      if (result != null && mounted) {
        Navigator.pop(
          context,
          GalleryPickerResult(
            path: result.path,
            mediaType: 'video',
            muteAudio: result.muted,
          ),
        );
      }
    } else {
      // Photos: show the existing preview sheet for confirmation.
      final selected = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _MediaPreviewSheet(asset: asset, file: file),
      );
      if (selected == true && mounted) {
        Navigator.pop(
          context,
          GalleryPickerResult(path: file.path, mediaType: 'photo'),
        );
      }
    }
  }
}

// ─── Preview bottom sheet ────────────────────────────────────────────────────

class _MediaPreviewSheet extends StatefulWidget {
  final AssetEntity asset;
  final File file;

  const _MediaPreviewSheet({required this.asset, required this.file});

  @override
  State<_MediaPreviewSheet> createState() => _MediaPreviewSheetState();
}

class _MediaPreviewSheetState extends State<_MediaPreviewSheet> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.asset.type == AssetType.video) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.file(widget.file);
    _videoController = controller;
    await controller.initialize();
    await controller.setLooping(true);
    await controller.play();
    if (mounted) setState(() => _videoReady = true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.asset.type == AssetType.video;
    final dateStr =
        DateFormat('MMMM d, yyyy').format(widget.asset.createDateTime);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Media content
            Expanded(
              child: isVideo ? _buildVideoPreview() : _buildPhotoPreview(),
            ),

            // Date + action bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Metadata row
                  Row(
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.photo,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(dateStr,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
                      if (isVideo) ...[
                        const SizedBox(width: 12),
                        Text(
                          _formatDuration(widget.asset.duration),
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Seek slider + play/pause for videos
                  if (isVideo && _videoReady)
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _videoController!,
                      builder: (_, value, __) {
                        final totalMs =
                            value.duration.inMilliseconds.toDouble();
                        final posMs = value.position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, totalMs > 0 ? totalMs : 1.0);

                        return Column(
                          children: [
                            // Slider row with time labels
                            Row(
                              children: [
                                Text(
                                  _formatMs(posMs.toInt()),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: posMs,
                                    max: totalMs > 0 ? totalMs : 1.0,
                                    onChanged: (v) => _videoController!
                                        .seekTo(Duration(
                                            milliseconds: v.toInt())),
                                  ),
                                ),
                                Text(
                                  _formatMs(totalMs.toInt()),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            // Play / pause button
                            IconButton(
                              iconSize: 44,
                              icon: Icon(
                                value.isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                              ),
                              onPressed: () => value.isPlaying
                                  ? _videoController!.pause()
                                  : _videoController!.play(),
                            ),
                          ],
                        );
                      },
                    ),

                  if (isVideo && _videoReady) const SizedBox(height: 8),

                  // Select button
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      isVideo ? 'Select this video' : 'Select this photo',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_videoReady) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return InteractiveViewer(
      child: Center(
        child: Image.file(widget.file, fit: BoxFit.contain),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatMs(int ms) {
    final m = (ms ~/ 60000).toString();
    final s = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─── Thumbnail grid cell ─────────────────────────────────────────────────────

class _AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _AssetThumbnail({required this.asset, required this.onTap});

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Uint8List? _thumb;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    final thumb = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
    if (mounted) {
      setState(() {
        _thumb = thumb;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMM d').format(widget.asset.createDateTime);
    final isVideo = widget.asset.type == AssetType.video;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_loading)
            Container(color: Colors.grey[850])
          else if (_thumb != null)
            Image.memory(_thumb!, fit: BoxFit.cover)
          else
            Container(
              color: Colors.grey[850],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),

          // Date overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              color: Colors.black54,
              child: Text(
                dateStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Video duration badge
          if (isVideo)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow,
                        color: Colors.white, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(widget.asset.duration),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
