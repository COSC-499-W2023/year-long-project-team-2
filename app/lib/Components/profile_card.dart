import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:FoodHood/Screens/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

class ProfileCard extends StatefulWidget {
  const ProfileCard({Key? key}) : super(key: key);

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  String photo = '';
  bool isLoading = true;
  Map<String, dynamic> profileData = {};

  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
  }

  void _initializeUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          _updateProfileData(snapshot.data()!);
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      },
      onError: (e) {
        if (mounted) {
          print('Error listening to user data changes: $e');
          setState(() => isLoading = false);
        }
      },
    );
  }

  void _updateProfileData(Map<String, dynamic> data) {
    if (mounted) {
      setState(() {
        profileData = data;
        photo = data['profileImagePath'] as String? ?? '';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
            context, CupertinoPageRoute(builder: (context) => ProfileScreen()));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.tertiarySystemBackground, context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _buildProfileContent(context),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final String fullName =
        "${profileData['firstName'] ?? ''} ${profileData['lastName'] ?? ''}"
            .trim();
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ClipOval(child: _profileImage()),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Aligning children vertically
            children: [
              _buildProfileText(
                  fullName.isNotEmpty ? fullName : 'FoodHood User',
                  22,
                  FontWeight.w600),
              const SizedBox(height: 4),
              _buildDescriptiveText(
                  "Edit Account & Posts", 12, FontWeight.w500),
            ],
          ),
        ),
        Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey),
      ],
    );
  }

  Widget _profileImage() {
    return CachedNetworkImage(
      imageUrl: photo,
      fit: BoxFit.cover,
      width: 64,
      height: 64,
      maxHeightDiskCache: 200, // Set maximum height for disk caching
      maxWidthDiskCache: 200, // Set maximum width for disk caching
      placeholder: (context, url) => const CupertinoActivityIndicator(),
      errorWidget: (context, url, error) => Image.asset(
        'assets/images/sampleProfile.png',
        width: 64,
        height: 64,
      ),
    );
  }

  Widget _buildProfileText(
      String text, double fontSize, FontWeight fontWeight) {
    return Text(
      text,
      style: TextStyle(
        color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -1.2,
      ),
    );
  }

  Widget _buildDescriptiveText(
      String text, double fontSize, FontWeight fontWeight) {
    return Text(
      text,
      style: TextStyle(
        color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondaryLabel, context),
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
