import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/message_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DonorRatingPage extends StatefulWidget {
  final String postId;
  final String receiverID;
  const DonorRatingPage(
      {Key? key, required this.postId, required this.receiverID})
      : super(key: key);
  @override
  _DonorRatingPageState createState() => _DonorRatingPageState();
}

class _DonorRatingPageState extends State<DonorRatingPage> {
  String? createdByName;
  String? image;
  String reservedByID = '';
  int _rating = 0;
  bool _isLoading = true;

  TextEditingController _commentController = TextEditingController();

  bool get _isPublishButtonEnabled {
    return _rating > 0 && _commentController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        navigationBar: CupertinoNavigationBar(
          border: null,
          backgroundColor: backgroundColor,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(FeatherIcons.x,
                size: 22, color: CupertinoColors.label.resolveFrom(context)),
          ),
          trailing: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => MessageScreen(
                    receiverID: reservedByID,
                  ),
                ),
              );
            },
            child: Text('Message ${createdByName ?? ""}',
                style: TextStyle(
                    color: accentColor.resolveFrom(context),
                    fontWeight: FontWeight.w500,
                )
            ),
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "How was your experience with ${createdByName ?? ""}?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                          fontSize: 32,
                          letterSpacing: -1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CircleAvatar(
                        radius: 50,
                        backgroundImage: CachedNetworkImageProvider(image!)),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                              index >= _rating
                                  ? CupertinoIcons.star
                                  : CupertinoIcons.star_fill,
                              color: index >= _rating
                                  ? tertiaryColor.resolveFrom(context)
                                  : accentColor.resolveFrom(context)),
                          iconSize: 36,
                          onPressed: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 100.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: CupertinoTextField(
                          controller: _commentController,
                          onChanged: (_) => setState(() {}),
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.top,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontSize: 16,
                            letterSpacing: -0.5,
                            fontWeight: FontWeight.w500,
                          ),
                          placeholder:
                              'Write a review for ${createdByName ?? ""}',
                          decoration: BoxDecoration(
                            color: CupertinoColors.tertiarySystemFill
                                .resolveFrom(context),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          placeholderStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.8,
                            color: CupertinoColors.placeholderText
                                .resolveFrom(context),
                          ),
                          padding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildButton(context, "Publish", FeatherIcons.edit),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> fetchCreatedByName() async {
    try {
      final DocumentSnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('post_details')
          .doc(widget.postId)
          .get();
      if (postSnapshot.exists) {
        final String createdByUserId = postSnapshot['user_id'];
        final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .doc(createdByUserId)
            .get();

        if (userSnapshot.exists) {
          final userName = userSnapshot['firstName'];
          setState(() {
            createdByName = userName;
            image = userSnapshot['profileImagePath'] as String? ?? '';
          });
        } else {
          print(
              'User document does not exist for reserved by user ID: $createdByUserId');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching creator name: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLoadingScreen() {
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    reservedByID = widget.receiverID;
    fetchCreatedByName();
  }

  Widget _buildButton(BuildContext context, String text, IconData icon) {
    return Container(
      height: 60.0,
      child: CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          borderRadius: BorderRadius.circular(100.0),
          color: _isPublishButtonEnabled
              ? yellow.resolveFrom(context).withOpacity(0.2)
              : CupertinoColors.tertiarySystemFill.resolveFrom(context),
          onPressed: _isPublishButtonEnabled
              ? () async {
                  await _storeCommentInDatabase();
                }
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: _isPublishButtonEnabled
                    ? yellow.resolveFrom(context)
                    : CupertinoColors.inactiveGray,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: _isPublishButtonEnabled
                      ? CupertinoColors.label.resolveFrom(context)
                      : CupertinoColors.inactiveGray,
                  fontSize: 18,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )),
    );
  }

  Future<void> _storeCommentInDatabase() async {
    try {
      DocumentReference postDocRef = FirebaseFirestore.instance
          .collection('post_details')
          .doc(widget.postId);
      DocumentSnapshot postDoc = await postDocRef.get();

      if (postDoc.exists && postDoc.data() is Map<String, dynamic>) {
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        String userId = postData['user_id'];

        DocumentReference userDocRef =
            FirebaseFirestore.instance.collection('user').doc(userId);
        DocumentSnapshot userDoc = await userDocRef.get();

        if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          List<dynamic> comments = List.from(userData['comments'] ?? []);
          List<dynamic> ratings = List.from(userData['ratings'] ?? []);

          comments.add(_commentController.text);
          ratings.add(_rating);

          double avgRating = ratings.isNotEmpty
              ? ratings.reduce((a, b) => a + b) / ratings.length
              : 0.0;
          avgRating = double.parse(avgRating.toStringAsFixed(2));

          await userDocRef.update({
            'comments': comments,
            'ratings': ratings,
            'avgRating': avgRating
          });

          Navigator.of(context).pushNamedAndRemoveUntil(
              '/nav', (route) => false,
              arguments: {'selectedIndex': 0});
        }
      }
    } catch (e) {
      print("Error updating document: $e");
    }
  }
}
