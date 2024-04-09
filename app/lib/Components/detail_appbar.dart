import 'package:FoodHood/Components/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:FoodHood/Screens/photo_gallery_screen.dart';
import 'package:flutter/services.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DetailAppBar extends StatefulWidget {
  final String postId;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final List<Map<String, String>> imagesWithAltText;

  const DetailAppBar({
    Key? key,
    required this.postId,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.imagesWithAltText,
  }) : super(key: key);

  @override
  _DetailAppBarState createState() => _DetailAppBarState();
}

class _DetailAppBarState extends State<DetailAppBar> {
  final PageController _pageController = PageController();

  bool _showIndicator = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _pageController.removeListener(_scrollListener);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> shareDynamicLink() async {
    final Uri dynamicLink = await createDynamicLink(widget.postId);
    Share.share(dynamicLink.toString());
  }

  // Method to create a dynamic link
  Future<Uri> createDynamicLink(String postId) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://foodhood.page.link',
      link: Uri.parse('https://foodhood.page.link/post/$postId'),
      androidParameters: AndroidParameters(
        packageName: 'com.example.foodhood',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(bundleId: 'com.example.foodhood'),
    );

    final ShortDynamicLink shortDynamicLink =
        await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    final Uri dynamicUrl = shortDynamicLink.shortUrl;

    return dynamicUrl;
  }

  void _scrollListener() {
    if (_pageController.page != null) {
      if (!_showIndicator) {
        if (mounted) {
          setState(() => _showIndicator = true);
        }
      }
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showIndicator = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      scrolledUnderElevation: 0.0,
      backgroundColor:
          CupertinoDynamicColor.resolve(detailsBackgroundColor, context),
      expandedHeight: 280,
      elevation: 0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: [StretchMode.zoomBackground],
        background: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _buildBackgroundImage(),
            AnimatedOpacity(
              opacity: _showIndicator ? 1.0 : 0.0,
              duration: Duration(milliseconds: 400),
              child: _buildPageIndicator(
                  _pageController,
                  CupertinoDynamicColor.resolve(detailsBackgroundColor, context)
                      .withOpacity(0.8)),
            ),
          ],
        ),
      ),
      leading: _buildLeading(context),
      actions: [_buildFavoriteButton(context), _buildShareButton(context)],
    );
  }

  Widget _buildLeading(BuildContext context) {
    return blurEffect(
      CircleAvatar(
        backgroundColor: Colors.transparent,
        child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(FeatherIcons.chevronLeft,
                size: 20, color: CupertinoColors.label.resolveFrom(context)),
            onPressed: () =>
                {HapticFeedback.selectionClick(), Navigator.of(context).pop()}),
      ),
      CupertinoDynamicColor.resolve(detailsBackgroundColor, context)
          .withOpacity(0.8),
      () => Navigator.of(context).pop(),
    );
  }

  Widget _buildBackgroundImage() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.imagesWithAltText.length,
      itemBuilder: (context, index) {
        final String imageUrl = widget.imagesWithAltText[index]['url']!;
        return GestureDetector(
          onTap: () => _openPhotoGalleryView(context, index),
          child: Hero(
            tag: 'imageHero${widget.imagesWithAltText[index]['url']}',
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => Icon(
                  Icons.broken_image_rounded,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                  size: 60),
            ),
          ),
        );
      },
    );
  }

  Route smoothRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = 0.0;
        var end = 1.0;
        var curve = Curves.fastOutSlowIn;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var opacityAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: opacityAnimation,
          child: child,
        );
      },
    );
  }

  void _openPhotoGalleryView(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      smoothRoute(
        PhotoGalleryScreen(
          imagesWithAltText: widget.imagesWithAltText,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return blurEffect(
      Icon(
        widget.isFavorite ? Icons.bookmark : Icons.bookmark_outline_outlined,
        size: 20,
        color: widget.isFavorite
            ? CupertinoColors.systemOrange
            : CupertinoColors.label.resolveFrom(context),
      ),
      CupertinoDynamicColor.resolve(detailsBackgroundColor, context)
          .withOpacity(0.8),
      () async {
        HapticFeedback.selectionClick();
        widget.onFavoritePressed();
      },
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return blurEffect(
      Icon(FeatherIcons.share,
          size: 18, color: CupertinoColors.label.resolveFrom(context)),
      CupertinoDynamicColor.resolve(detailsBackgroundColor, context)
          .withOpacity(0.8),
      () async {
        HapticFeedback.selectionClick();
        final Uri dynamicLink = await createDynamicLink(widget.postId);
        Share.shareUri(dynamicLink);
      },
    );
  }

  Widget blurEffect(
      Widget child, Color backgroundColor, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
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
                      activeDotColor: CupertinoColors.label
                          .resolveFrom(context)),
                ),
              )),
        ),
      ),
    );
  }
}