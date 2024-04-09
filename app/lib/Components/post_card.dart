import 'package:FoodHood/Components/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:FoodHood/Screens/detail_screen.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';

class PostCard extends StatelessWidget {
  final List<Map<String, String>> imagesWithAltText;
  final String firstName;
  final String lastName;
  final String title;
  final List<String> tags;
  final List<Color> tagColors;
  final String timeAgo;
  final Function(String) onTap;
  final String postId;
  final String profileURL;
  final bool showTags;
  final double imageHeight;
  final bool showShadow;

  PostCard({
    Key? key,
    required this.imagesWithAltText,
    required this.title,
    required this.tags,
    required this.tagColors,
    required this.firstName,
    required this.lastName,
    required this.timeAgo,
    required this.onTap,
    required this.postId,
    required this.profileURL,
    this.showTags = true,
    this.imageHeight = 100.0,
    this.showShadow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => {
          HapticFeedback.selectionClick(),
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailView(
                postId: postId,
              ),
            ),
          ),
        },
        child: Container(
          decoration: BoxDecoration(
            color:
                CupertinoColors.tertiarySystemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: imagesWithAltText.isNotEmpty
                      ? imagesWithAltText[0]['url'] ?? ''
                      : 'assets/images/sampleFoodPic.jpg',
                  width: MediaQuery.of(context).size.width,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) =>
                      buildImageFailedPlaceHolder(context, true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(title,
                    style: TextStyle(
                        color: CupertinoDynamicColor.resolve(
                            CupertinoColors.label, context),
                        fontSize: 18,
                        letterSpacing: -0.8,
                        fontWeight: FontWeight.w600)),
              ),
              if (showTags) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                          child: Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: _buildTags(context),
                      ))
                    ],
                  ),
                ),
                const SizedBox(height: 2),
              ] else ...[
                const SizedBox(height: 10),
              ],
              _buildOrderInfoSection(
                  context, profileURL, firstName, lastName, timeAgo),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTags(BuildContext context) {
    int tagCount = tags.length;
    int displayedTags = tagCount > 4 ? 4 : tagCount;
    int truncatedTags = tagCount - displayedTags;
    List<Widget> tagWidgets =
        tags.take(displayedTags).toList().asMap().entries.map((entry) {
      int idx = entry.key;
      String tag = entry.value;
      return Container(child: Tag(text: tag, color: tagColors[idx]));
    }).toList();
    if (truncatedTags > 0) {
      tagWidgets.add(Tag(text: '+$truncatedTags', color: blue));
    }
    return tagWidgets;
  }

  Color _generateTagColor(int index) {
    List<Color> availableColors = [yellow, orange, blue, babyPink, Cyan];
    return availableColors[index % availableColors.length];
  }

  Widget _buildOrderInfoSection(BuildContext context, String avatarUrl,
      String firstname, String lastname, String timeAgo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 8,
            backgroundImage: avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(avatarUrl)
                : Image.asset('assets/images/sampleProfilePic.jpg').image,
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 8),
          Text('Posted by $firstname $lastname  $timeAgo',
              style: TextStyle(
                  color: CupertinoDynamicColor.resolve(
                      CupertinoColors.secondaryLabel, context),
                  fontSize: 12,
                  letterSpacing: -0.40,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
