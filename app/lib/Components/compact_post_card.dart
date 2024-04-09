import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:FoodHood/Screens/detail_screen.dart'; // Update this import
import 'package:cached_network_image/cached_network_image.dart'; // Add this import

class CompactPostCard extends StatelessWidget {
  final String imageLocation;
  final String firstname;
  final String lastname;
  final String title;
  final List<String> tags;
  final List<Color> tagColors;
  final String timeAgo;
  final Function(String) onTap; // New callback parameter
  final String postId;
  final profileURL; // New parameter to store the profile image URL
  final bool
      showTags; // New parameter to indicate whether to show tags or notxx

  CompactPostCard({
    Key? key,
    required this.imageLocation,
    required this.title,
    required this.tags,
    required this.tagColors,
    required this.firstname,
    required this.lastname,
    required this.timeAgo,
    required this.onTap,
    required this.postId,
    required this.profileURL,
    this.showTags = true, // Default value to show tags
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          onTap(postId);
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => PostDetailView(postId: postId),
            ),
          );
        },
        child: Container(
          decoration: _buildBoxDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitleSection(context),
              SizedBox(height: 10),
              _buildOrderInfoSection(context, profileURL),
            ],
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
          blurRadius: 10,
          offset: Offset(0, 0),
        ),
      ],
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        title,
        style: TextStyle(
          overflow: TextOverflow.ellipsis,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
          fontSize: 18,
          letterSpacing: -0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection(BuildContext context, String avatarUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          ClipOval(
              child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: 20,
            height: 20,
            fit: BoxFit.cover,
            placeholder: (context, url) => CupertinoActivityIndicator(),
            errorWidget: (context, url, error) => Image.asset(
                'assets/images/sampleProfile.png',
                width: 20,
                height: 20,
                fit: BoxFit.cover),
          )),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Posted by $firstname $lastname $timeAgo', // Ensure variables `firstname`, `lastname`, and `timeAgo` are defined and accessible
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.secondaryLabel, context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
