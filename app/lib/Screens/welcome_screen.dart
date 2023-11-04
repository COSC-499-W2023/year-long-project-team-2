// welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import '../components.dart';

// TODO: Implement WelcomeScreen
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildImageSection(),
          Expanded(
            child: _buildTextSection(context),
          ),
        ],
      ),
    );
  }

  // welcome screen image 
  Widget _buildImageSection() {
    return AspectRatio(
      aspectRatio: 430 / 359,
      child: Image.asset(
        "assets/images/smilelyface.png",
        fit: BoxFit.cover,
      ),
    );
  }

  // Intro texts
  Widget _buildTextSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Welcome to FoodHood',
              textAlign: TextAlign.center, style: Styles.titleStyle),
          const SizedBox(height: 28),
          const Text(
            'FoodHood is a platform where one can donate or receive extra home-made food.',
            textAlign: TextAlign.center,
            style: Styles.descriptionStyle,
          ),
          const SizedBox(height: 28),
          CupertinoButton(
            color: const Color(0xFF337586),
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(14),
            onPressed: () {
              Navigator.pushNamed(context, '/signin');
            },
            child: const Text('Log in', style: Styles.buttonTextStyle),
          ),
          const SizedBox(height: 28),
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Not a member? Sign up ',
                    style: Styles.signUpTextStyle,
                  ),
                  TextSpan(
                    text: 'here',
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushNamed(context, '/signup');
                      },
                    style: Styles.signUpLinkStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
