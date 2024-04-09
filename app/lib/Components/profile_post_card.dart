import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:FoodHood/Components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share_plus/share_plus.dart';

const double _defaultTextFontSize = 14.0;
const double _defaultTitleFontSize = 16.0;
const double _defaultTagFontSize = 10.0;
const double _defaultOrderInfoFontSize = 12.0;
const double _defaultStatusFontSize = 10.0;

class ProfilePostCard extends StatelessWidget {
  final List<Map<String, String>> imagesWithAltText;
  final String title;
  final bool isCurrentUser;
  final List<String> tags;
  final String orderInfo;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final Function(String) onTap;
  final String postId;
  final VoidCallback? onStatusPressed;

  ProfilePostCard({
    Key? key,
    required this.imagesWithAltText,
    required this.title,
    required this.isCurrentUser,
    required this.tags,
    required this.orderInfo,
    required this.onTap,
    required this.postId,
    this.onEdit,
    this.onRemove,
    this.onStatusPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _textScaleFactor =
        Provider.of<TextScaleProvider>(context).textScaleFactor;
    double adjustedTitleFontSize = _defaultTitleFontSize * _textScaleFactor;
    double adjustedTagFontSize = _defaultTagFontSize * _textScaleFactor;
    double adjustedOrderInfoFontSize =
        _defaultOrderInfoFontSize * _textScaleFactor;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          HapticFeedback.selectionClick();
          onStatusPressed?.call();
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => PostDetailView(postId: postId),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemBackground, context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildImageSection(context, imagesWithAltText, postId),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitleSection(
                                    context, title, adjustedTitleFontSize),
                                const SizedBox(height: 4),
                                _buildOrderInfoSection(context, orderInfo,
                                    adjustedOrderInfoFontSize),
                                const SizedBox(height: 4),
                                _buildTagSection(
                                    context, tags, adjustedTagFontSize),
                              ],
                            ),
                          ),
                        ),
                      ]),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PullDownButton(
                      itemBuilder: (context) => [
                        if (isCurrentUser) ...[
                          PullDownMenuItem(
                            title: 'Edit',
                            onTap: () {
                              onEdit?.call();
                            },
                            icon: CupertinoIcons.pencil,
                          ),
                        ],
                        PullDownMenuItem(
                          title: 'Share',
                          subtitle: 'Forward as a link to others',
                          onTap: () {
                            shareDynamicLink();
                          },
                          icon: CupertinoIcons.share,
                        ),
                        if (isCurrentUser) ...[
                          PullDownMenuItem(
                            onTap: () {
                              _showDeletePostConfirmation(context);
                            },
                            title: 'Delete Post',
                            isDestructive: true,
                            icon: CupertinoIcons.delete,
                          ),
                        ],
                      ],
                      buttonBuilder: (context, showMenu) => CupertinoButton(
                        onPressed: showMenu,
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          FeatherIcons.moreHorizontal,
                          size: 20,
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.secondaryLabel, context),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> shareDynamicLink() async {
    final Uri dynamicLink = await createDynamicLink(postId);
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

  void _showDeletePostConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Delete Post'),
          content: Text(
              'Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                onRemove?.call();
              },
            ),
          ],
        );
      },
    );
  }

  void _onCardTap(BuildContext context, String postId) {
    HapticFeedback.selectionClick();
    onTap(postId);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => PostDetailView(postId: postId),
      ),
    );
  }

  static Widget _buildImageSection(BuildContext context,
      List<Map<String, String>> imagesWithAltText, String postId) {
    final String imageToShow = imagesWithAltText.isNotEmpty
        ? imagesWithAltText[0]['url'] ?? ''
        : 'assets/images/sampleFoodPic.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: imageToShow,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => CupertinoActivityIndicator(),
        errorWidget: (context, url, error) =>
            buildImageFailedPlaceHolder(context, true),
      ),
    );
  }

  static Widget _buildTitleSection(
      BuildContext context, String title, double adjustedTitleFontSize) {
    return Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
        fontSize: adjustedTitleFontSize,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static Widget _buildTagSection(
      BuildContext context, List<String> tags, double adjustedTagFontSize) {
    const int maxDisplayTags = 2;
    List<Widget> tagWidgets = [];
    int displayedTagsCount =
        tags.length > maxDisplayTags ? maxDisplayTags : tags.length;
    int truncatedTags = tags.length - displayedTagsCount;

    for (int i = 0; i < displayedTagsCount; i++) {
      tagWidgets.add(
        Tag(text: tags[i], color: _generateTagColor(i)),
      );
    }
    if (truncatedTags > 0) {
      tagWidgets.add(
        Tag(
          text: '+$truncatedTags',
          color: CupertinoDynamicColor.resolve(blue, context),
        ),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 0,
      children: tagWidgets,
    );
  }

  static Color _generateTagColor(int index) {
    List<Color> availableColors = [yellow, orange, blue, babyPink, Cyan];
    return availableColors[index % availableColors.length];
  }

  static Widget _buildTag(String text, Color color, BuildContext context,
      double adjustedTagFontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4), // Adjusted padding
      decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(color, context),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(
          color: color.computeLuminance() > 0.5
              ? CupertinoDynamicColor.resolve(CupertinoColors.black, context)
              : CupertinoDynamicColor.resolve(CupertinoColors.white, context),
          fontSize: adjustedTagFontSize,
          letterSpacing: -0.40,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow
            .ellipsis, // Changed to ellipsis to handle very long text
      ),
    );
  }

  static Widget _buildOrderInfoSection(BuildContext context, String orderInfo,
      double adjustedOrderInfoFontSize) {
    return Text(
      orderInfo,
      style: TextStyle(
        color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondaryLabel, context),
        fontSize: adjustedOrderInfoFontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
