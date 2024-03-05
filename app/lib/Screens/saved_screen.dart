import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/post_card.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';

const double _defaultFontSize = 16.0;
const double _defaultPostCountFontSize = 14.0;

class SavedScreen extends StatefulWidget {
  @override
  _SavedScreenState createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List<String> savedPostIds = [];
  bool isLoading = true;
  StreamSubscription? _savedPostsSubscription;

  late double _textScaleFactor;
  late double adjustedFontSize;
  late double adjustedPostCountFontSize;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      child: CustomScrollView(
        slivers: <Widget>[
          _buildNavigationBar(),
          if (isLoading) // If it's loading, show the loading indicator
            _buildLoadingSliver()
          else if (savedPostIds
              .isEmpty) // If there are no saved posts, show the empty message
            _buildNoSavedPostsMessage()
          else // If there are saved posts, show the list
            _buildSavedPostsList(savedPostIds),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchSavedPosts();
    _listenForSavedPosts();
    _textScaleFactor =
        Provider.of<TextScaleProvider>(context, listen: false).textScaleFactor;
    _updateAdjustedFontSize();
  }

  void _updateAdjustedFontSize() {
    adjustedFontSize = _defaultFontSize * _textScaleFactor;
    adjustedPostCountFontSize = _defaultPostCountFontSize * _textScaleFactor;
  }

  Future<void> _fetchSavedPosts() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    var document =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    if (document.exists && document.data()!.containsKey('saved_posts')) {
      savedPostIds = List<String>.from(document.data()!['saved_posts']);
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _listenForSavedPosts() {
    _savedPostsSubscription = FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .snapshots()
        .listen(
      (document) {
        if (mounted) {
          if (document.exists && document.data()!.containsKey('saved_posts')) {
            setState(() {
              savedPostIds = List<String>.from(document.data()!['saved_posts']);
              isLoading = false;
            });
          }
        }
      },
      onError: (error) => print("Error listening to saved posts: $error"),
    );
  }

  @override
  void dispose() {
    _savedPostsSubscription?.cancel(); // Cancel the stream subscription
    super.dispose();
  }

  CupertinoSliverNavigationBar _buildNavigationBar() {
    return CupertinoSliverNavigationBar(
      backgroundColor: groupedBackgroundColor,
      largeTitle: Text('Bookmarks'),
      border: Border(bottom: BorderSide.none),
      stretch: true,
    );
  }

  SliverFillRemaining _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(child: CupertinoActivityIndicator()),
    );
  }

  SliverList _buildSavedPostsList(List<String> savedPostIds) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          // Check if the current index is the last item in the list
          if (index < savedPostIds.length) {
            return _buildPostItem(context, savedPostIds[index]);
          } else if (index == savedPostIds.length && savedPostIds.isNotEmpty) {
            // If it's the last item and the list is not empty, display the post count
            return Column(
              children: [
                _buildPostCountIndicator(savedPostIds.length),
                SizedBox(height: 100),
              ],
            );
          }
          return null; // Return null for indices beyond the data range
        },
        childCount: savedPostIds.isEmpty
            ? 0
            : savedPostIds.length + 1, // Add +1 for the post count indicator
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, String postId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('post_details')
          .doc(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return SizedBox
              .shrink(); // No post details exist, return an empty widget
        }

        var postData = snapshot.data!.data() as Map<String, dynamic>?;
        if (postData == null) {
          return SizedBox.shrink(); // Post data is null, return an empty widget
        }

        // Check if the post is reserved by someone and exclude it from the saved posts list
        if (postData.containsKey('reserved_by')) {
          return SizedBox
              .shrink(); // This post is reserved, so do not display it
        }

        // Extract the first image URL from the imagesWithAltText list
        List<Map<String, String>> imagesWithAltText = [];
        if (postData.containsKey('images') && postData['images'] is List) {
          imagesWithAltText = List<Map<String, String>>.from(
            (postData['images'] as List).map((image) {
              return {
                'url': image['url'] as String? ?? '',
                'alt_text': image['alt_text'] as String? ?? '',
              };
            }),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('user')
              .doc(postData['user_id'])
              .get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return SizedBox
                  .shrink(); // No user data exists, return an empty widget
            }

            var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) {
              return SizedBox
                  .shrink(); // User data is null, return an empty widget
            }

            // Now we can safely use postData and userData, knowing they're not null and are properly formatted
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: PostCard(
                imagesWithAltText: imagesWithAltText,
                title: postData['title'] ?? 'No Title',
                tags: (postData['categories'] as String)
                    .split(',')
                    .map((tag) => tag.trim())
                    .toList(),
                tagColors: _assignedColors(),
                firstname: userData['firstName'] ?? 'Unknown',
                lastname: userData['lastName'] ?? 'Unknown',
                timeAgo: timeAgoSinceDate(
                    (postData['post_timestamp'] as Timestamp).toDate()),
                onTap: (postId) => _onPostCardTap(postId),
                postId: postId,
                profileURL: userData['profileImagePath'] ?? '',
                showTags: true, // Assuming showTags is true by default
                imageHeight: 100.0, // Assuming a default height
                showShadow: false, // Assuming no shadow by default
              ),
            );
          },
        );
      },
    );
  }

  SliverFillRemaining _buildNoSavedPostsMessage() {
    return SliverFillRemaining(
      hasScrollBody: false, // Prevents the message from being scrollable
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(FeatherIcons.bookmark,
                size: 42,
                color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            SizedBox(height: 10),
            Text(
              'No Bookmarks Found',
              style: TextStyle(
                fontSize: adjustedFontSize,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCountIndicator(int postCount) {
    String postCountText =
        '$postCount Bookmarked ' + (postCount > 1 ? 'Posts' : 'Post');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(postCountText,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: adjustedPostCountFontSize,
              fontWeight: FontWeight.w500,
            )),
      ),
    );
  }

  void _onPostCardTap(String postId) {
    print('Post ID: $postId');
  }

  String timeAgoSinceDate(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 8) {
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    } else if (duration.inDays >= 1) {
      return '${duration.inDays} days ago';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} hours ago';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  List<Color> _assignedColors() {
    return [yellow, orange, blue, babyPink, Cyan];
  }
}
