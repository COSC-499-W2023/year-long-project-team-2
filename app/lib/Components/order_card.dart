import 'package:FoodHood/Screens/donee_pathway_uno.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/donor_screen.dart';
import 'package:FoodHood/Screens/posting_detail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:FoodHood/Components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double _defaultTextFontSize = 14.0;
const double _defaultTitleFontSize = 16.0;
const double _defaultTagFontSize = 10.0;
const double _defaultOrderInfoFontSize = 12.0;
const double _defaultStatusFontSize = 9.0;

enum OrderState {
  reserved,
  confirmed,
  delivering,
  readyToPickUp,
  pending,
  notReserved
}

class OrderCard extends StatelessWidget {
  final List<Map<String, String>> imagesWithAltText;
  final String title;
  final List<String> tags;
  final String orderInfo;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final Function(String) onTap;
  final String postId;
  final VoidCallback? onStatusPressed;
  final OrderState orderState;
  final bool isDonation;

  OrderCard({
    Key? key,
    required this.imagesWithAltText,
    required this.title,
    required this.tags,
    required this.orderInfo,
    required this.onTap,
    required this.postId,
    this.onEdit,
    this.onCancel,
    this.onStatusPressed,
    required this.orderState,
    required this.isDonation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _textScaleFactor =
        Provider.of<TextScaleProvider>(context).textScaleFactor;

    double adjustedTitleFontSize = _defaultTitleFontSize * _textScaleFactor;
    double adjustedTagFontSize = _defaultTagFontSize * _textScaleFactor;
    double adjustedOrderInfoFontSize =
        _defaultOrderInfoFontSize * _textScaleFactor;
    double adjustedStatusFontSize = _defaultStatusFontSize * _textScaleFactor;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => PostDetailView(postId: postId),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemBackground, context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildImageSection(context, imagesWithAltText, postId),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusText(
                              context, adjustedStatusFontSize, orderState),
                          const SizedBox(height: 4),
                          _buildTitleSection(
                              context, title, adjustedTitleFontSize),
                          const SizedBox(height: 4),
                          _buildOrderInfoSection(
                              context, orderInfo, adjustedOrderInfoFontSize),
                          const SizedBox(height: 4),
                          _buildTagSection(context, tags, adjustedTagFontSize),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onStatusPressed?.call();
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => isDonation
                                ? DonorScreen(postId: postId)
                                : DoneePath(postId: postId),
                            //DonorScreen(postId: postId),
                          ),
                        );
                      },
                      child: Icon(FeatherIcons.chevronRight,
                          size: 24,
                          color:
                              CupertinoColors.systemGrey.resolveFrom(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
        width: 88,
        height: 88,
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
            color: _generateTagColor(displayedTagsCount)),
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

  static Widget _buildStatusText(BuildContext context,
      double adjustedStatusFontSize, OrderState orderState) {
    String statusText = '';
    Color statusColor = CupertinoColors.systemGreen; // Default color

    switch (orderState) {
      case OrderState.reserved:
        statusText = 'Reserved';
        statusColor = CupertinoColors.systemYellow;
        break;
      case OrderState.confirmed:
        statusText = 'Confirmed';
        statusColor = CupertinoColors.systemGreen;
        break;
      case OrderState.delivering:
        statusText = 'Delivering';
        statusColor = CupertinoColors.systemBlue;
        break;
      case OrderState.readyToPickUp:
        statusText = 'Ready to Pick Up';
        statusColor = CupertinoColors.systemGreen;
        break;
      case OrderState.pending:
        statusText = 'Pending';
        statusColor = CupertinoColors.systemOrange;
        break;
      case OrderState.notReserved:
        statusText = 'Not Reserved';
        statusColor = CupertinoColors.systemGrey;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: statusColor.withOpacity(0.2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
                child: Container(
              color: statusColor,
              width: 8,
              height: 8,
            )),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(statusText,
                    style: TextStyle(
                      color: MediaQuery.platformBrightnessOf(context) ==
                              Brightness.dark
                          ? lighten(statusColor, 0.4)
                          : darken(statusColor, 0.4),
                      fontSize: adjustedStatusFontSize,
                      letterSpacing: -0.4,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
