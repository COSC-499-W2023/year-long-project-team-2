// welcome_screen.dart

import 'package:FoodHood/Components/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../Components/components.dart';

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
      aspectRatio: 6 / 5,
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
          Text('Welcome to FoodHood',
              textAlign: TextAlign.center, style: Styles.titleStyle),
          SizedBox(height: 28),
          Text(
            'FoodHood is a platform where one can donate or receive extra home-made food.',
            textAlign: TextAlign.center,
            style: Styles.descriptionStyle,
          ),
          SizedBox(height: 28),
          CupertinoButton(
            color: accentColor,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(14),
            onPressed: () {
              Navigator.pushNamed(context, '/signin');
            },
            child: Text('Log in', style: Styles.buttonTextStyle),
          ),
          const SizedBox(height: 14),
          CupertinoButton(
            color: secondaryColor.withOpacity(0.2),
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(14),
            onPressed: () {
              Navigator.pushNamed(context, '/signup');
            },
            child: Text(
              'Sign up',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(accentColor, context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.90,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
