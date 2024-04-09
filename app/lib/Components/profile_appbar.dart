import 'package:FoodHood/Models/AppBarVisibilityController.dart';
import 'package:FoodHood/Screens/profile_edit_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class ProfileAppBar extends StatefulWidget {
  final VoidCallback onBlockPressed;
  final bool isBlocked;
  final bool isCurrentUser;
  final String imageUrl;
  final String? userId;
  final String? firstName;
  final String? lastName;

  const ProfileAppBar({
    Key? key,
    required this.onBlockPressed,
    required this.isBlocked,
    required this.isCurrentUser,
    required this.imageUrl,
    this.firstName,
    this.lastName,
    this.userId,
  }) : super(key: key);

  @override
  _ProfileAppBarState createState() => _ProfileAppBarState();
}

class _ProfileAppBarState extends State<ProfileAppBar> {
  Color? _backgroundColor;
  String? _firstName;
  String? _lastName;
  String? _city;
  String? _province;
  double? _rating;
  String? _imageUrl;
  int _postsSold = 0;
  bool isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    isCurrentUser = widget.userId == currentUser?.uid;
    if (widget.userId != null) {
      _fetchUserDetails(widget.userId!).then((_) {
        _updatePaletteGenerator();
      });
      _fetchPostsSoldCount(widget.userId!);
    } else {
      _updatePaletteGenerator();
    }
  }

  Future<void> _blockUser(String userIdToBlock) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('user').doc(currentUser.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (userDoc.exists) {
          List<dynamic> blockedUsers = userDoc.data()?['blocked'] ?? [];
          if (!blockedUsers.contains(userIdToBlock)) {
            blockedUsers.add(userIdToBlock);
            transaction.update(userRef, {'blocked': blockedUsers});
          }
        }
      });
    } catch (e) {}
  }

  Future<void> _fetchUserDetails(String userId) async {
    final userData =
        await FirebaseFirestore.instance.collection('user').doc(userId).get();
    if (userData.exists) {
      setState(() {
        _firstName = userData.data()?['firstName'] as String?;
        _lastName = userData.data()?['lastName'] as String?;
        _city = userData.data()?['city'] as String?;
        _province = userData.data()?['province'] as String?;
        _rating = userData.data()?['avgRating']?.toDouble();
        _imageUrl = userData.data()?['profileImagePath'] as String?;
      });
    }
  }

  Future<void> _fetchPostsSoldCount(String userId) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('post_details')
        .where('user_id', isEqualTo: userId)
        .where('post_status', isEqualTo: "completed")
        .get();

    if (mounted) {
      setState(() {
        _postsSold = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _updatePaletteGenerator() async {
    if (_imageUrl == null || _imageUrl!.isEmpty || _backgroundColor != null) {
      return;
    }

    ImageProvider imageProvider;
    if (_imageUrl!.startsWith('http')) {
      imageProvider = ResizeImage(CachedNetworkImageProvider(_imageUrl!),
          height: 5, width: 5);
    } else {
      imageProvider = AssetImage(_imageUrl!);
    }

    PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
      imageProvider,
      size: Size(200, 100),
    );

// Attempt to choose the best color based on availability
    Color? chosenColor = generator.vibrantColor?.color ??
        generator.lightVibrantColor?.color ??
        CupertinoColors.systemGrey; // Fallback color

    if (mounted) {
      setState(() {
        _backgroundColor = chosenColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      scrolledUnderElevation: 0.0,
      backgroundColor:
          CupertinoDynamicColor.resolve(detailsBackgroundColor, context),
      expandedHeight: 250,
      elevation: 0,
      stretch: true,
      pinned: true,
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: [StretchMode.fadeTitle],
        background: _buildGradientBackground(),
        expandedTitleScale: 1.0,
        title: VisibilityController(
          expandedChild: _buildUserInfoRow(),
          collapsedChild: _buildCollapsedUserInfo(),
        ),
        centerTitle: false,
        titlePadding: EdgeInsets.only(left: 20.0, bottom: 16.0),
      ),
      leading: _buildLeading(context),
      actions: [
        if (!isCurrentUser) buildBlockButton(context),
      ],
    );
  }

  Widget _buildCollapsedUserInfo() {
    return Text(
      '${_firstName ?? "Loading..."} ${_lastName ?? ""}',
      style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.label.resolveFrom(context)),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return CupertinoButton(
      child: Icon(FeatherIcons.chevronLeft,
          size: 24, color: CupertinoColors.label.resolveFrom(context)),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildGradientBackground() {
    final backgroundColor =
        _backgroundColor ?? CupertinoColors.systemBackground;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            CupertinoDynamicColor.resolve(detailsBackgroundColor, context),
          ],
        ),
      ),
    );
  }

  Widget buildBlockButton(BuildContext context) {
    return CupertinoButton(
      child: Text('Block',
          style: TextStyle(color: CupertinoColors.label.resolveFrom(context))),
      onPressed: () => _showBlockMenu(context),
    );
  }

  Widget _buildUserInfoRow() {
    String location = 'unknown';
    String displayName = 'User';
    if (_firstName != null && _lastName != null) {
      displayName = '$_firstName $_lastName';
    }
    if (_city != null && _province != null) {
      location = '$_city, $_province';
    }
    ImageProvider<Object> _getAvatarImageProvider() {
      if (widget.imageUrl.isNotEmpty) {
        return CachedNetworkImageProvider(widget.imageUrl);
      } else {
        return AssetImage('assets/images/sampleProfile.png');
      }
    }

    List<Widget> stars = [];
    Color starColor = _backgroundColor ?? CupertinoColors.systemOrange;
    for (int i = 0; i < 5; i++) {
      stars.add(Icon(
        _rating != null && i < _rating!
            ? CupertinoIcons.star_fill
            : CupertinoIcons.star,
        color: starColor,
        size: 14,
      ));
    }

    String ratingText = _rating != null
        ? '  ${_rating!.toStringAsFixed(1)} Ratings, '
        : '  No rating, ';
    String postsSoldText = '$_postsSold items sold';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: ClipOval(
                child: CupertinoContextMenu.builder(
                  enableHapticFeedback: true,
                  actions: [
                    CupertinoContextMenuAction(
                      child: Text('Edit Profile'),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  builder: (BuildContext context, Animation<double> animation) {
                    final Animation<BorderRadius?> borderRadiusAnimation =
                        BorderRadiusTween(
                      begin: BorderRadius.circular(0.0),
                      end: BorderRadius.circular(
                          CupertinoContextMenu.kOpenBorderRadius),
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Interval(
                          CupertinoContextMenu.animationOpensAt,
                          1.0,
                        ),
                      ),
                    );

                    final Animation<Decoration> boxDecorationAnimation =
                        DecorationTween(
                      begin: const BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        boxShadow: <BoxShadow>[],
                      ),
                      end: const BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        boxShadow: CupertinoContextMenu.kEndBoxShadow,
                      ),
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Interval(
                        0.0,
                        CupertinoContextMenu.animationOpensAt,
                      ),
                    ));

                    return Container(
                      decoration: animation.value <
                              CupertinoContextMenu.animationOpensAt
                          ? boxDecorationAnimation.value
                          : null,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: ClipRRect(
                            borderRadius: borderRadiusAnimation.value ??
                                BorderRadius.circular(0.0),
                            child: widget.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.imageUrl,
                                    placeholder: (context, url) => Center(
                                      child: CupertinoActivityIndicator(),
                                    ),
                                    fit: BoxFit.cover,
                                    width:
                                        MediaQuery.of(context).size.width / 1.4,
                                    height:
                                        MediaQuery.of(context).size.width / 1.4,
                                  )
                                : Image.asset(
                                    'assets/images/sampleProfile.png',
                                    width:
                                        MediaQuery.of(context).size.width / 1.4,
                                    height:
                                        MediaQuery.of(context).size.width / 1.4,
                                    fit: BoxFit.cover,
                                  )),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                        fontSize: 24,
                        letterSpacing: -0.4,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    location,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context)),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: stars.followedBy([
                      Text(
                        ratingText,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        postsSoldText,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ]).toList(),
                  ),
                ],
              ),
            ),
            if (isCurrentUser)
              Container(
                margin: EdgeInsets.only(right: 20),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _backgroundColor ??
                          CupertinoColors
                              .systemGrey, // Use _backgroundColor or a fallback
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: _backgroundColor != null &&
                                _backgroundColor!.computeLuminance() < 0.5
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  onPressed: () {
                    //navigate to edit profile
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                          builder: (context) => EditProfileScreen()),
                    );
                  },
                ),
              ),
          ],
        )
      ],
    );
  }

  void _showBlockMenu(BuildContext context) {
    String displayName = _firstName ?? 'User';
    if (_firstName != null && _lastName != null) {
      displayName = '$_firstName $_lastName';
    }
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Block $displayName',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label.resolveFrom(context),
            fontSize: 18,
            letterSpacing: -0.60,
          ),
        ),
        message: Text(
          'You will no longer see any posts from $displayName.',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 14,
            letterSpacing: -0.40,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: Text(
              'Confirm',
              style: TextStyle(
                color: CupertinoColors.destructiveRed,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.80,
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (widget.userId != null) {
                try {
                  await _blockUser(widget.userId!);
                  if (mounted) {
                    _showSuccessDialog(context);
                  }
                } catch (error) {
                  print("Error blocking user: $error");
                }
              }
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 3), () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop(true); // Closes the dialog
          }
        });
        return AlertDialog(
          content: Text('You have successfully blocked this user'),
        );
      },
    );
  }
}
