import 'dart:async';

import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/profile_appbar.dart';
import 'package:FoodHood/Components/profile_post_card.dart';
import 'package:FoodHood/Screens/post_edit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AboutSection extends StatelessWidget {
  final String? firstName;
  final String? aboutMe;

  const AboutSection({super.key, this.firstName, this.aboutMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text('About ${firstName ?? "User"}',
              style: TextStyle(
                color:
                    CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.70,
              )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color:
                CupertinoColors.tertiarySystemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 10,
                offset: Offset(0, 0),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(aboutMe ?? "No description Available",
                style: TextStyle(
                  color: CupertinoColors.label
                      .resolveFrom(context)
                      .withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.40,
                )),
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class RecentPostsTab extends StatelessWidget {
  final List<Map<String, dynamic>> recentPosts;
  final String? userId;
  final Function(String) onRemove;
  final Function(String) onEdit;

  const RecentPostsTab(
      {super.key,
      required this.recentPosts,
      this.userId,
      required this.onRemove,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return recentPosts.isEmpty
        ? const Center(child: Text("No posts available"))
        : ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 20),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentPosts.length,
            itemBuilder: (context, index) {
              final post = recentPosts[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: fetchUserDetails(post['user_id']),
                builder: (context, snapshot) {
                  final imagesWithAltText =
                      post['images'] as List<dynamic>? ?? [];
                  final firstImage = imagesWithAltText.isNotEmpty
                      ? imagesWithAltText[0]
                      : null;
                  final createdAt =
                      (post['post_timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                  List<String> tags = (post['categories'] as String?)
                          ?.split(',')
                          .map((tag) => tag.trim())
                          .toList() ??
                      [];

                  return ProfilePostCard(
                    imagesWithAltText: firstImage != null
                        ? [
                            {
                              'url': firstImage['url'],
                              'alt_text': firstImage['alt_text'] ?? ''
                            }
                          ]
                        : [],
                    title: post['title']!,
                    tags: tags,
                    orderInfo: 'Posted on ${timeAgoSinceDate(createdAt)}',
                    onTap: (postId) {
                      print('Tapped on post: $postId');
                    },
                    postId: post['postId']!,
                    onRemove: () => onRemove(post['postId']!),
                    onEdit: () => onEdit(post['postId']!),
                    isCurrentUser:
                        userId == FirebaseAuth.instance.currentUser?.uid,
                  );
                },
              );
            },
          );
  }

  Future<Map<String, dynamic>> fetchUserDetails(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      return userDoc.exists
          ? userDoc.data() as Map<String, dynamic>
          : {'firstName': 'Unknown', 'lastName': '', 'profileImagePath': ''};
    } catch (e) {
      print('Error fetching user details: $e');
      return {'firstName': 'Error', 'lastName': '', 'profileImagePath': ''};
    }
  }

  String timeAgoSinceDate(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 7) {
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    } else if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays > 1 ? "s" : ""} ago';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? "s" : ""} ago';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? "s" : ""} ago';
    } else {
      return 'Just now';
    }
  }
}

class ReviewItem extends StatelessWidget {
  final String review;
  const ReviewItem({super.key, required this.review});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage('assets/images/sampleProfile.png')),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                  color:
                      CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(review,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                      color: CupertinoColors.label.resolveFrom(context))),
            )
          ],
        ));
  }
}

class ReviewsTab extends StatelessWidget {
  final String? userId;
  final String imageUrl;

  const ReviewsTab({super.key, this.userId, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final String effectiveUserId =
        userId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    return FutureBuilder<List<String>>(
      future: fetchComments(effectiveUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading reviews'));
        } else if (snapshot.data!.isEmpty) {
          return const Center(child: Text("No reviews available"));
        } else {
          return ListView.separated(
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10), // Spacing between items
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
                vertical: 20), // Padding at the start and end of the list
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final comment = snapshot.data![index];
              return ReviewItem(review: comment);
            },
          );
        }
      },
    );
  }

  Future<List<String>> fetchComments(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      return List<String>.from(userDoc['comments'] ?? []);
    } catch (e) {
      print(
          e); // Ideally, use a logging framework or handle the error appropriately.
      return [];
    }
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? firstName;
  String? lastName;
  String? aboutMe;
  String imageUrl = "";
  bool isLoading = true;
  List<Map<String, dynamic>> recentPosts = [];
  int segmentedControlGroupValue = 0;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? userId;

  @override
  Widget build(BuildContext context) {
    Widget contentWidget;

    // Method to handle post deletion
    void removePost(String postId) async {
      try {
        // Delete the post document from the post_details collection
        await firestore.collection('post_details').doc(postId).delete();
        
        // Get the user document
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance
                .collection('user')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .get();

        // Check if data exists
        if (userSnapshot.exists) {
          // Get the current posts of the user
          List<String> posts = List<String>.from(userSnapshot.data()?['posts'] ?? []);

          // Remove the postId of the deleted order
          posts.remove(postId);

          // Update the user document with the updated posts list
          await FirebaseFirestore.instance
              .collection('user')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .update({'posts': posts});
        }
        setState(() {
          recentPosts.removeWhere((post) => post['postId'] == postId);
        });
      } catch (e) {
        print("Error removing post: $e");
        // Show an error message if needed
      }
    }

    switch (segmentedControlGroupValue) {
      case 0:
        contentWidget = RecentPostsTab(
          recentPosts: recentPosts,
          userId: userId,
          onRemove: removePost, 
          onEdit: (postId) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => EditPostScreen(postId: postId)),
            );
          },
        );
        break;
      case 1:
        contentWidget = ReviewsTab(userId: userId, imageUrl: imageUrl);
        break;
      default:
        contentWidget = Container();
    }

    Map<int, Widget> segmentedControlChildren = {
      0: Text(
        "Recent Posts",
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 14,
          letterSpacing: -0.6,
          fontWeight: FontWeight.w500,
        ),
      ),
      1: Text("Reviews",
          style: TextStyle(
            color: CupertinoColors.label.resolveFrom(context),
            fontSize: 14,
            letterSpacing: -0.6,
            fontWeight: FontWeight.w500,
          )),
    };

    return Scaffold(
      backgroundColor:
          CupertinoDynamicColor.resolve(detailsBackgroundColor, context),
      body: CustomScrollView(
        slivers: <Widget>[
          ProfileAppBar(
              isCurrentUser: false,
              isBlocked: false,
              imageUrl: imageUrl,
              userId: userId,
              firstName: firstName,
              lastName: lastName,
              onBlockPressed: () {}),
          SliverToBoxAdapter(
            child: Column(
              children: <Widget>[
                AboutSection(firstName: firstName, aboutMe: aboutMe),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  width: MediaQuery.of(context).size.width,
                  child: CupertinoSlidingSegmentedControl<int>(
                    children: segmentedControlChildren,
                    onValueChanged: (value) {
                      setState(() {
                        segmentedControlGroupValue = value!;
                      });
                    },
                    groupValue: segmentedControlGroupValue,
                  ),
                ),
                SafeArea(top: false, child: contentWidget),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> determineUserId() async {
    userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
  }

  void fetchRecentPosts() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('post_details')
        .where('user_id', isEqualTo: userId)
        .get();
    if (mounted) {
      setState(() {
        recentPosts = snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'postId': doc.id,
                })
            .toList();
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void setUpStreamListener(String userId) {
    firestore.collection('user').doc(userId).snapshots().listen((snapshot) {
      if (mounted && snapshot.exists) {
        updateProfileData(snapshot.data()!);
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  void updateProfileData(Map<String, dynamic> documentData) {
    if (mounted) {
      setState(() {
        firstName = documentData['firstName'] as String? ?? '';
        lastName = documentData['lastName'] as String?;
        aboutMe = documentData['aboutMe'] as String? ?? '';
        imageUrl = documentData['profileImagePath'] as String? ?? '';
        if (aboutMe == null || aboutMe!.trim().isEmpty) {
          aboutMe = "No description available";
        }
        isLoading = false;
      });
    }
  }

  void _initializeData() {
    determineUserId().then((_) {
      if (userId != null) {
        setUpStreamListener(userId!);
        fetchRecentPosts();
      } else {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    });
  }
}
