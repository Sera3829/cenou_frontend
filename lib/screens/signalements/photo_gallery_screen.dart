import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../services/signalement_service.dart';

/// Galerie photo plein écran d'un signalement.
class PhotoGalleryScreen extends StatefulWidget {
  final int signalementId;
  final int photoCount;
  final int initialIndex;
  final String token;
  final List<String> photos;
  final bool isDark;

  const PhotoGalleryScreen({
    super.key,
    required this.signalementId,
    required this.photoCount,
    required this.initialIndex,
    required this.token,
    required this.photos,
    required this.isDark,
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = SignalementService();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photoCount}'),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (_, index) {
          final url =
              svc.getPhotoUrl(widget.signalementId, index, widget.photos);
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(url,
                headers: {'Authorization': 'Bearer ${widget.token}'}),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        itemCount: widget.photoCount,
        loadingBuilder: (_, __) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        pageController: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
