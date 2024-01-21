import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/home_screen.dart';
import 'package:FoodHood/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components/profile_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:FoodHood/Screens/forgot_password_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text('Settings', style: TextStyle(letterSpacing: -1.34)),
            border: Border(bottom: BorderSide.none),
            backgroundColor: groupedBackgroundColor,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(FeatherIcons.chevronLeft,
                  size: _iconSize, color: CupertinoColors.label.resolveFrom(context)),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 10),
                ProfileCard(),
                SizedBox(height: 10),
                _buildSettingOption('Push Notifications', _buildSwitch()),
                SizedBox(height: 16),
                _buildSettingButton('Accessibility', FeatherIcons.eye, () {}),
                SizedBox(height: 14),
                _buildSettingButton('Help', FeatherIcons.helpCircle, () {}),
                SizedBox(height: 14),
                _buildSettingButton('Sign out', FeatherIcons.logOut, () {
                  //showSignOutConfirmationSheet(context);
                  _showActionSheet(
                    context,
                    'Sign Out',
                    'Are you sure you want to sign out?',
                    () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                  );
                }),
                
                SizedBox(height: 36.0,),

                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.only(right: _spacing), 
                        child: Text(
                          "Account Settings",
                          style: TextStyle(
                            fontSize: _defaultFontSize,
                            letterSpacing: -0.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
                  child: _buildActionButtons(
                    'Reset Password',
                    CupertinoColors.activeBlue,
                    () => _showActionSheet(
                      context,
                      'Reset Password',
                      'Are you sure you want to reset your password?',
                      () async {
                        // Add logic for resetting password
                        
                        print("called");
                        // Navigator.of(context).push(
                        //   CupertinoPageRoute(
                        //     builder: (context) => CreatePostScreen(),
                        //   ),
                        // );
                        Navigator.pop(context);
                        //await Future.delayed(Duration(milliseconds: 500));
                        // Navigator.pushReplacement(
                        //   context,
                        //   CupertinoPageRoute(
                        //     builder: (context) => ForgotPasswordScreen(),
                        //   ),
                        // );
                        //Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                        print("called again");
                        //Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        // Navigator.pushAndRemoveUntil(
                        //   context,
                        //   CupertinoPageRoute(
                        //     builder: (context) => ForgotPasswordScreen(),
                        //   ),
                        //   (route) => false,
                        // );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildActionButtons(
                    'Delete Account',
                    CupertinoColors.destructiveRed,
                    () => _showActionSheet(
                      context,
                      'Delete Account',
                      'Are you sure you want to delete your account?',
                      () async {
                        try {
                          User user = FirebaseAuth.instance.currentUser!;
                          await user.delete();
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        } catch (e) {
                          print('Error deleting account: $e');
                        }
                      },
                    ),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  // ObstructingPreferredSizeWidget _buildNavigationBar(BuildContext context) {
  //   return CupertinoNavigationBar(
  //     transitionBetweenRoutes: false,
  //     backgroundColor: groupedBackgroundColor,
  //     middle: Text('Settings'),
  //     leading: GestureDetector(
  //       onTap: () => Navigator.of(context).pop(),
  //       child: Icon(FeatherIcons.arrowLeft,
  //           size: _iconSize, color: CupertinoColors.label.resolveFrom(context)),
  //     ),
  //     border: const Border(bottom: BorderSide.none),
  //   );
  // }

  Widget _buildSettingOption(String title, Widget trailing) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: _defaultPadding, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: _defaultFontSize,
                  letterSpacing: -0.8,
                  fontWeight: FontWeight.w600)),
          trailing
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
      onToggle: (value) => setState(() => pushNotificationsEnabled = value),
    );
  }

  Widget _buildSettingButton(
      String title, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _defaultMargin),
      child: CupertinoButton(
        onPressed: onPressed,
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
                    color: CupertinoColors.label.resolveFrom(context)),
                SizedBox(width: _spacing),
                Text(title,
                    style: TextStyle(
                        fontSize: _defaultFontSize,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label.resolveFrom(context))),
              ],
            ),
            Icon(FeatherIcons.chevronRight,
                color: CupertinoColors.label.resolveFrom(context)),
          ],
        ),
      ),
    );
  }

  // void showSignOutConfirmationSheet(BuildContext context) {
  //   showCupertinoModalPopup(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return CupertinoActionSheet(
  //         title: Text(
  //           'Are you sure you want to Sign out?',
  //           style: TextStyle(
  //             fontSize: 13,
  //             letterSpacing: -0.6,
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //         actions: <Widget>[
  //           CupertinoActionSheetAction(
  //             child: Text(
  //               'Sign Out',
  //               style: TextStyle(
  //                   letterSpacing: -0.6,
  //                   fontWeight: FontWeight.w500,
  //                   fontSize: 18),
  //             ),
  //             isDestructiveAction: true,
  //             onPressed: () async {
  //               Navigator.of(context).pop(); // Close the action sheet
  //               await FirebaseAuth.instance.signOut();
  //               Navigator.of(context)
  //                   .pushNamedAndRemoveUntil('/', (route) => false);
  //             },
  //           ),
  //         ],
  //         cancelButton: CupertinoActionSheetAction(
  //           child: Text(
  //             'Cancel',
  //             style: TextStyle(
  //                 fontWeight: FontWeight.w500,
  //                 letterSpacing: -0.6,
  //                 fontSize: 18),
  //           ),
  //           onPressed: () {
  //             Navigator.of(context).pop(); // Close the action sheet
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildActionButtons(
      String title, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        width: double.infinity, // Makes the button take full width
        child: CupertinoButton(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.tertiarySystemBackground, context),
          borderRadius: BorderRadius.circular(12),
          onPressed: onPressed,
          child: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: CupertinoColors.secondaryLabel,
            fontSize: 16,
            letterSpacing: -0.80,
          ),
        ),
        message: Text(message),
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
