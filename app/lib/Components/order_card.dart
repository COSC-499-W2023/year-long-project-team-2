import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/donor_pathway_1.dart';
import 'package:FoodHood/Screens/posting_detail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';

import 'package:palette_generator/palette_generator.dart';

//Constants for styling
const double _defaultTextFontSize = 16.0;
const double _defaultTitleFontSize = 18.0;
const double _defaultTagFontSize = 10.0;
const double _defaultOrderInfoFontSize = 12.0;

enum OrderState { reserved, confirmed, delivering, readyToPickUp }

// ignore: must_be_immutable
class OrderCard extends StatelessWidget {
  final String imageLocation;
  final String title;
  final List<String> tags;
  final String orderInfo;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final Function(String) onTap;
  final String postId;
  final VoidCallback? onStatusPressed;
  late double _textScaleFactor;
  late double adjustedTextFontSize;
  late double adjustedTitleFontSize;
  late double adjustedTagFontSize;
  late double adjustedOrderInfoFontSize;
  final OrderState orderState;

  OrderCard({
    Key? key,
    required this.imageLocation,
    required this.title,
    required this.tags,
    required this.orderInfo,
    required this.onTap,
    required this.postId,
    this.onEdit,
    this.onCancel,
    this.onStatusPressed,
    required this.orderState,
  }) : super(key: key);

  void _updateAdjustedFontSize() {
    adjustedTextFontSize = _defaultTextFontSize * _textScaleFactor;
    adjustedTitleFontSize = _defaultTitleFontSize * _textScaleFactor;
    adjustedTagFontSize = _defaultTagFontSize * _textScaleFactor;
    adjustedOrderInfoFontSize = _defaultOrderInfoFontSize * _textScaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    _textScaleFactor = Provider.of<TextScaleProvider>(context).textScaleFactor;
    _updateAdjustedFontSize();

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _onCardTap(context),
        child: _buildCardBody(context),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, VoidCallback action) {
    action();
    Navigator.pop(context);
  }

  Future<PaletteGenerator> _updatePaletteGenerator(String imageLocation) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(imageLocation),
      size: Size(200, 100), // Adjust according to your image size
    );
    return paletteGenerator;
  }

  void _onCardTap(BuildContext context) {
    onTap(postId);
    Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => PostDetailView(postId: postId),
        ));
  }

  Widget _buildCardBody(BuildContext context) {
    return Container(
      decoration: _buildBoxDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(context),
          _buildImageSection(context, imageLocation),
          _buildTitleSection(context),
          _buildTagSection(context),
          _buildOrderInfoSection(context),
        ],
      ),
    );
  }

  BoxDecoration _buildBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: CupertinoDynamicColor.resolve(
          CupertinoColors.tertiarySystemBackground, context),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 20)],
    );
  }

  Widget _buildImageSection(BuildContext context, String imageLocation) {
    final isNetworkImage = imageLocation.startsWith('http');

    return ClipRRect(
      child: isNetworkImage
          ? CachedNetworkImage(
              imageUrl: imageLocation,
              width: MediaQuery.of(context).size.width,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => CupertinoActivityIndicator(),
              errorWidget: (context, url, error) => Image.asset(
                'assets/images/sampleFoodPic.png',
                width: MediaQuery.of(context).size.width,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
          : Image.asset(
              'assets/images/sampleFoodPic.png',
              width: MediaQuery.of(context).size.width,
              height: 100,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(title,
          style: TextStyle(
              color:
                  CupertinoDynamicColor.resolve(CupertinoColors.label, context),
              fontSize: adjustedTitleFontSize,
              letterSpacing: -0.8,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTagSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 7,
        children: tags
            .map((tag) =>
                _buildTag(tag, _generateTagColor(tags.indexOf(tag)), context))
            .toList(),
      ),
    );
  }

  Color _generateTagColor(int index) {
    List<Color> availableColors = [yellow, orange, blue, babyPink, Cyan];
    return availableColors[index % availableColors.length];
  }

  Widget _buildTag(String text, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              color:
                  CupertinoDynamicColor.resolve(CupertinoColors.black, context),
              fontSize: adjustedTagFontSize,
              letterSpacing: -0.40,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildOrderInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(orderInfo,
          style: TextStyle(
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel, context),
              fontSize: adjustedOrderInfoFontSize,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusText(context),
          _buildStatusButton(context),
        ],
      ),
    );
  }

   Widget _buildStatusText(BuildContext context) {
    // Modify this method to display status based on orderState
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
        statusColor = CupertinoColors.systemOrange;
        break;
      case OrderState.readyToPickUp:
        statusText = 'Ready to Pick Up';
        statusColor = CupertinoColors.systemCyan;
        break;
    }

    return Row(
      children: [
        Icon(CupertinoIcons.circle_fill, color: statusColor, size: 14),
        const SizedBox(width: 8),
        Text(statusText, style: TextStyle(
            color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
            fontWeight: FontWeight.w500,
            fontSize: 14)),
      ],
    );
  }

  Widget _buildStatusButton(BuildContext context) {
    return SizedBox(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _handleStatusPress(context),
        child: Row(
          children: [
            Text('Status',
                style: TextStyle(
                    color: CupertinoDynamicColor.resolve(
                        CupertinoColors.label, context),
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
            const SizedBox(width: 4),
            Icon(FeatherIcons.chevronRight,
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.label, context),
                size: 16),
          ],
        ),
      ),
    );
  }

  void _handleStatusPress(BuildContext context) {
    onStatusPressed?.call();
    Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => DonorScreen(postId: postId),
        ));
  }
}
