import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Services/AuthService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:FoodHood/Screens/reset_sent_screen.dart';
import '../Components/components.dart'; // Assuming this file contains common UI components

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      navigationBar: buildBackNavigationBar(context),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildText('Forgot Password?', 34, FontWeight.w600),
                        const SizedBox(height: 40),
                        Text(
                          'Don’t worry! It happens. Please enter the address associated with your account.',
                          style: TextStyle(
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel, context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                buildCupertinoTextField('Email Address', _emailController,
                    context, [AutofillHints.email]), // Email text field
                const SizedBox(height: 120),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildContinueButton(context, 'Submit', accentColor,
                        CupertinoColors.white), // Submit button
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Continue button
  Widget buildContinueButton(BuildContext context, String text,
      Color backgroundColor, Color textColor) {
    final AuthService authService = AuthService();

    return CupertinoButton(
      onPressed: () async {
        if (_emailController.text.trim().isEmpty) {
          // Show error prompt if email input is empty
          showErrorDialog(
              context, 'Email Required', 'Please enter your email address.');
          return;
        }

        //if not an email address
        if (!_emailController.text.trim().contains('@') ||
            !_emailController.text.trim().contains('.')) {
          showErrorDialog(
              context, 'Invalid Email', 'Please enter a valid email address.');
          return;
        }

        showLoadingDialog(context); // Show loading dialog
        try {
          await authService
              .sendPasswordResetEmail(_emailController.text.trim());
          Navigator.of(context).pop(); // Dismiss loading dialog
          navigateToSuccessScreen(context);
          print('Password reset email sent successfully.');
        } catch (e) {
          Navigator.of(context).pop(); // Dismiss loading dialog on error
          String errorMessage = extractFirebaseErrorMessage(e as Exception);
          showErrorDialog(context, 'Reset Error', errorMessage);
          print('Error resetting password: $e');
        }
      },
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String extractFirebaseErrorMessage(Exception e) {
    String errorMessage = e.toString();
    // Extract Firebase error message
    errorMessage = errorMessage.replaceAll(RegExp(r'\[.*?\]\s'), '');
    return errorMessage;
  }

  void navigateToSuccessScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SuccessScreen(message: 'Email sent :)'),
      ),
    );
  }

  // Method to show a loading dialog
  void showLoadingDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 24),
                Text(
                  'Sending Email',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
