// login_screen.dart
// a page that allows the user to log in to the app

import 'package:flutter/cupertino.dart';
import '../components.dart';

class LogInScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController(); // text controller for email
  final TextEditingController passwordController = TextEditingController(); // text controller for password 

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground, // background color
      navigationBar: buildBackNavigationBar(context), // navigation bar
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: buildLoginForm(context),
          ),
        ),
      ),
    );
  }

  // Log in form
  Column buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildText('Log in', 34, FontWeight.w600), // Log in text
        const SizedBox(height: 50),
        buildCupertinoTextField('Email Address', emailController, false), // Email text field
        const SizedBox(height: 20),
        buildCupertinoTextField('Password', passwordController, true), // Password text field
        const SizedBox(height: 20),
        buildTextButton('Forgot Password?', Alignment.centerRight,
            const Color(0xFF337586), 12, FontWeight.w500), // Forgot password text
        const SizedBox(height: 20),
        buildContinueButton('Continue', const Color(0xFF337586), CupertinoColors.white), // Continue button
        const SizedBox(height: 20),
        buildCenteredText('or', 14, FontWeight.w600), // Or text
        const SizedBox(height: 20),
        buildGoogleSignInButton(), // Google sign in button
        const SizedBox(height: 20),
        buildSignUpText(context, "Don't have an account? ", 'Sign up', '/signup'), // Sign up text
      ],
    );
  }
  
  // Continue button
  Widget buildContinueButton(
      String text, Color backgroundColor, Color textColor) {
    return CupertinoButton(
      onPressed: () {},
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
}
