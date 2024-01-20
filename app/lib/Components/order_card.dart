import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/posting_detail.dart';
import 'package:flutter/cupertino.dart';

class OrderCard extends StatelessWidget {
  final String imageLocation;
  final String title;
  final List<String> tags;
  final String orderInfo;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final Function(String) onTap; // New callback parameter
  final String postId;

  OrderCard({
    required this.imageLocation,
    required this.title,
    required this.tags,
    required this.orderInfo,
    required this.onTap,
    required this.postId,
    this.onEdit, // Optional callback for editing
    this.onCancel, // Optional callback for canceling
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: CupertinoContextMenu(
        actions: <Widget>[
          // Edit Order Action
          CupertinoContextMenuAction(
            child: Text('Edit Order'),
            trailingIcon: CupertinoIcons.pencil,
            onPressed: () {
              onEdit?.call(); // Call the edit callback if it's provided
              Navigator.pop(context);
            },
          ),
          // Cancel Order Action
          CupertinoContextMenuAction(
            child: Text('Cancel Order'),
            trailingIcon: CupertinoIcons.trash,
            isDestructiveAction: true,
            onPressed: () {
              onCancel?.call(); // Call the cancel callback if it's provided
              Navigator.pop(context);
            },
          ),
        ],
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            onTap(postId);
            Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => PostDetailView(
                        postId: postId,
                      )),
            );
          },
          child: Container(
            decoration: _buildBoxDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(context),
                _buildTitleSection(context),
                _buildTagSection(context),
                _buildOrderInfoSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: CupertinoDynamicColor.resolve(
          CupertinoColors.tertiarySystemBackground, context),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: 20,
          offset: Offset(0, 0),
        ),
      ],
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      child: Image.asset(
        imageLocation,
        width: MediaQuery.of(context).size.width,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        title,
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTagSection(BuildContext context) {
    const double horizontalSpacing = 7.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: List.generate(tags.length, (index) {
          return Row(
            children: [
              _buildTag(tags[index], _generateTagColor(index), context),
              SizedBox(width: horizontalSpacing),
            ],
          );
        }),
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(CupertinoColors.black, context),
          fontSize: 10,
          letterSpacing: -0.40,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        orderInfo,
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.secondaryLabel, context),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
