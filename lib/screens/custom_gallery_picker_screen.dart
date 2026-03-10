import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:retro1/l10n/app_localizations.dart';

enum GalleryFilter { all, videos, photos }

class CustomGalleryPickerScreen extends StatefulWidget {
  final GalleryFilter initialFilter;

  const CustomGalleryPickerScreen({
    super.key,
    this.initialFilter = GalleryFilter.all,
  });

  @override
  State<CustomGalleryPickerScreen> createState() =>
      _CustomGalleryPickerScreenState();
}

class _CustomGalleryPickerScreenState
    extends State<CustomGalleryPickerScreen> {
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  late GalleryFilter _currentFilter;

  int _currentPage = 0;
  static const int _pageSize = 80;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
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

  RequestType get _requestType {
    switch (_currentFilter) {
      case GalleryFilter.videos:
        return RequestType.video;
      case GalleryFilter.photos:
        return RequestType.image;
      case GalleryFilter.all:
        return RequestType.common;
    }
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _assets = [];
      _currentPage = 0;
      _hasMore = true;
    });

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
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
    final albums = await PhotoManager.getAssetPathList(
      type: _requestType,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false)
        ],
      ),
    );

    if (albums.isEmpty) {
      setState(() => _hasMore = false);
      return;
    }

    final recentAlbum = albums.first;
    final assets = await recentAlbum.getAssetListPaged(
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

  void _setFilter(GalleryFilter filter) {
    if (filter == _currentFilter) return;
    setState(() => _currentFilter = filter);
    _loadAssets();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectFromGallery),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterBar(l10n),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip(l10n.all, GalleryFilter.all),
          const SizedBox(width: 8),
          _filterChip(l10n.video, GalleryFilter.videos),
          const SizedBox(width: 8),
          _filterChip(l10n.photo, GalleryFilter.photos),
        ],
      ),
    );
  }

  Widget _filterChip(String label, GalleryFilter filter) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _setFilter(filter),
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
            Text(l10n.permissionDenied,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => PhotoManager.openSetting(),
              child: Text(l10n.openSettings),
            ),
          ],
        ),
      );
    }

    if (_assets.isEmpty) {
      return Center(child: Text(l10n.noMediaFound));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
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
          onTap: () => _selectAsset(_assets[index]),
        );
      },
    );
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorAccessingFile)),
        );
      }
      return;
    }
    if (mounted) {
      Navigator.pop(context, file.path);
    }
  }
}

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
    final date = widget.asset.createDateTime;
    final dateStr = DateFormat('MMM d').format(date);
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

          // Date overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
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

          // Video badge (duration) at top-right
          if (isVideo)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
