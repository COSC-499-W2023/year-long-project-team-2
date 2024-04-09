import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/accessibility_screen.dart';
import 'package:FoodHood/Screens/reset_pwd_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:FoodHood/Screens/profile_edit_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

// Constants for styling
const double _defaultPadding = 20.0;
const double _defaultMargin = 16.0;
const double _defaultFontSize = 16.0;
const double _iconSize = 22.0;
const double _spacing = 15.0;
const double _buttonBorderRadius = 16.0;
const double _switchHeight = 29.0;
const double _switchWidth = 52.0;
const double _switchPadding = 4.0;
const double _switchToggleSize = 22.0;
const double _switchBorderRadius = 100.0;

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotificationsEnabled = false;
  late double _textScaleFactor;
  late double adjustedFontSize;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _textScaleFactor =
        Provider.of<TextScaleProvider>(context, listen: false).textScaleFactor;
    _updateAdjustedFontSize();
    checkNotificationPermissionStatus();
  }

  void _updateAdjustedFontSize() {
    adjustedFontSize = _defaultFontSize * _textScaleFactor;
  }

  void checkNotificationPermissionStatus() async {
    NotificationSettings settings = await messaging.getNotificationSettings();
    setState(() {
      pushNotificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    });
  }

  @override
  Widget build(BuildContext context) {
    _textScaleFactor = Provider.of<TextScaleProvider>(context).textScaleFactor;
    _updateAdjustedFontSize();
    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      navigationBar: _buildNavigationBar(context),
      child: SafeArea(
        bottom: false,
        child: ListView(children: [
          SizedBox(height: 16),
          _buildSettingOption('Push Notifications', _buildSwitch()),
          SizedBox(height: 16),
          _buildSettingButton('Accessibility', FeatherIcons.eye, () {
            _navigateToPage(context, AccessibilityScreen());
          }, CupertinoColors.activeGreen),
          SizedBox(height: 14),
          _buildSettingButton('Help', FeatherIcons.helpCircle, () {},
              CupertinoColors.systemCyan),
          SizedBox(height: 16),
          Container(
            margin: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Text(
                    "Account Settings",
                    style: TextStyle(
                        fontSize: adjustedFontSize,
                        letterSpacing: -0.8,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          _buildSettingButton('Sign out', FeatherIcons.logOut, () {
            _showActionSheet(
              context,
              'Sign Out',
              'Are you sure you want to sign out?',
              () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              },
            );
          }, CupertinoColors.activeOrange),
          SizedBox(height: 14),
          _buildSettingButton('Reset Password', FeatherIcons.refreshCw, () {
            _navigateToPage(context, ForgotPasswordScreen());
          }, CupertinoColors.activeBlue),
          SizedBox(height: 14),
          _buildSettingButton('Delete Account', FeatherIcons.trash2, () {
            _showActionSheet(
              context,
              'Delete Account',
              'Are you sure you want to delete your account?',
              () async {
                try {
                  User user = FirebaseAuth.instance.currentUser!;
                  await user.delete();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                } catch (e) {
                  print('Error deleting account: $e');
                }
              },
            );
          }, CupertinoColors.destructiveRed),
        ]),
      ),
    );
  }

  // Method to build the Edit Profile button
  Widget _buildEditProfileButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        color: accentColor,
        borderRadius: BorderRadius.circular(12),
        padding: EdgeInsets.symmetric(vertical: 16),
        onPressed: () => {
          HapticFeedback.selectionClick(),
          _navigateToPage(context, EditProfileScreen()),
        },
        child: Text(
          'Edit FoodHood Profile',
          style: TextStyle(
            fontSize: adjustedFontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.8,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => page),
    );
  }

  ObstructingPreferredSizeWidget _buildNavigationBar(BuildContext context) {
    return CupertinoNavigationBar(
      transitionBetweenRoutes: false,
      backgroundColor: groupedBackgroundColor,
      middle: Text('Settings', style: TextStyle(fontSize: adjustedFontSize)),
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Icon(FeatherIcons.chevronLeft,
            size: _iconSize * _textScaleFactor,
            color: CupertinoColors.label.resolveFrom(context)),
      ),
      border: const Border(bottom: BorderSide.none),
    );
  }

  Widget _buildSettingOption(String title, Widget trailing) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _defaultMargin),
      padding: EdgeInsets.symmetric(
          horizontal: _defaultPadding, vertical: _defaultPadding / 1.25),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(_buttonBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(FeatherIcons.bell,
                  size: _iconSize,
                  color: CupertinoColors.systemOrange.resolveFrom(context)),
              SizedBox(width: _spacing),
              Text(
                title,
                style: TextStyle(
                    fontSize: adjustedFontSize,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.label.resolveFrom(context)),
              ),
            ],
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSwitch() {
    return FlutterSwitch(
      height: _switchHeight,
      width: _switchWidth,
      padding: _switchPadding,
      toggleSize: _switchToggleSize,
      borderRadius: _switchBorderRadius,
      activeColor: accentColor,
      value: pushNotificationsEnabled,
      onToggle: (value) {
        setState(() => pushNotificationsEnabled = value);
        if (value) {
          requestNotificationPermission();
        } else {
          unsubscribeFromAllTopics();
          updateBackendNotificationPreference(false);
        }
      },
    );
  }

  Future<void> unsubscribeFromAllTopics() async {
    const topics = ['news', 'updates', 'alerts'];
    for (String topic in topics) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
  }

  Future<void> updateBackendNotificationPreference(bool enabled) async {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final Uri backendUrl =
        Uri.parse('https://yourbackend.example.com/updatePreference');

    try {
      await http.post(backendUrl, body: {
        'userId': userId,
        'notificationsEnabled': enabled.toString(),
      });
    } catch (e) {
      print('Failed to update notification preference: $e');
    }
  }

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // Optionally subscribe the user to a topic for push notifications
      messaging.subscribeToTopic('general');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Widget _buildSettingButton(
    String title,
    IconData icon,
    VoidCallback onPressed,
    Color? color, // Make color optional
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _defaultMargin),
      child: CupertinoButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        color: CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(_buttonBorderRadius),
        padding: EdgeInsets.symmetric(
            horizontal: _defaultPadding, vertical: _defaultPadding / 1.25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: _iconSize,
                    color: color ??
                        CupertinoColors.label.resolveFrom(
                            context)), // Use color if provided, else default
                SizedBox(width: _spacing),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: adjustedFontSize,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context)),
                ),
              ],
            ),
            Icon(FeatherIcons.chevronRight,
                color: CupertinoColors.label.resolveFrom(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      String title, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        width: double.infinity,
        child: CupertinoButton(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.tertiarySystemBackground, context),
          borderRadius: BorderRadius.circular(12),
          onPressed: onPressed,
          child: Text(
            title,
            style: TextStyle(
                fontSize: adjustedFontSize,
                color: color,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context, String title, String message,
      VoidCallback onConfirm) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label.resolveFrom(context),
            fontSize: 16,
            letterSpacing: -0.60,
          ),
        ),
        message: Text(message,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 14,
              letterSpacing: -0.40,
              fontWeight: FontWeight.w500,
            )),
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
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
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
}
