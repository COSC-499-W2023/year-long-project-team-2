import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:feather_icons/feather_icons.dart';
import 'dart:ui';
import 'package:FoodHood/Components/colors.dart';
import 'package:flutter/services.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final List<Map<String, String>> imagesWithAltText;
  final int initialIndex;

  const PhotoGalleryScreen({
    Key? key,
    required this.imagesWithAltText,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late final PageController _galleryPageController;
  bool _showAltText = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _galleryPageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex; // Initialize with the initial index
  }

  @override
  void dispose() {
    _galleryPageController.dispose();
    super.dispose();
  }

  void _toggleAltText() {
    setState(() {
      _showAltText = !_showAltText;
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: blurEffect(
          Icon(FeatherIcons.x, size: 20, color: CupertinoColors.white),
          CupertinoColors.darkBackgroundGray.withOpacity(0.7),
          () => Navigator.of(context).pop(),
        ),
        actions: [_buildAltButton()],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PhotoViewGallery.builder(
            pageController: _galleryPageController,
            itemCount: widget.imagesWithAltText.length,
            builder: (context, index) {
              final item = widget.imagesWithAltText[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(item['url']!),
                heroAttributes:
                    PhotoViewHeroAttributes(tag: 'imageHero${item['url']}'),
                onTapUp: (context, details, controllerValue) {
                  if (_showAltText) {
                    _toggleAltText(); // Hide alt text when image is tapped
                  }
                },
              );
            },
            onPageChanged: _onPageChanged,
            scrollPhysics: const BouncingScrollPhysics(),
          ),
          SafeArea(
            child: _buildPageIndicator(
              _galleryPageController,
              CupertinoColors.darkBackgroundGray.withOpacity(0.7),
            ),
          ),
          if (_showAltText) _buildAltTextBox(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(
      PageController pageController, Color backgroundColor) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: backgroundColor),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: SmoothPageIndicator(
                  controller: pageController,
                  count: widget.imagesWithAltText.length,
                  effect: WormEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      type: WormType.underground,
                      dotColor:
                          CupertinoColors.systemGrey2.resolveFrom(context),
                      activeDotColor: CupertinoColors.white),
                ),
              )),
        ),
      ),
    );
  }

  Widget _buildAltButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: _showAltText ? blue : CupertinoColors.darkBackgroundGray.withOpacity(0.7)),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _showAltText = !_showAltText;
              });
            },
            child: Text(
              'ALT',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAltTextBox() {
    final altText =
        widget.imagesWithAltText[_currentIndex]['alt_text']?.trim() ?? '';

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16, // Ensure the text box is within screen bounds
      child: _showAltText && altText.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: CupertinoColors.darkBackgroundGray.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  altText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            )
          : SizedBox.shrink(),
    );
  }

  Widget blurEffect(
      Widget child, Color backgroundColor, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: child,
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
