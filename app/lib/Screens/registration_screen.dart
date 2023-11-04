// registration_screen.dart
// a screen that allows users to register for an account

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Global key for input validation
  // Create controllers for each text field
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();

  // Dispose of controllers when the widget is disposed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // main body of the screen
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: buildBackNavigationBar(context), // navigation bar
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              // Form widget for input validation
              key: _formKey,
              child: _buildSignupForm(context),
            ),
          ),
        ),
      ),
    );
  }

  // Sign up form
  Column _buildSignupForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildText('Create an account', 34, FontWeight.w600, -1.36),
        const SizedBox(height: 50),
        _buildTwoFieldsRow(
          'First Name',
          _firstNameController,
          'Last Name',
          _lastNameController,
        ),
        const SizedBox(height: 20),
        _buildCupertinoTextField('Email Address', _emailController, false),
        const SizedBox(height: 20),
        _buildCupertinoTextField('Password', _passwordController, true),
        const SizedBox(height: 20),
        _buildTwoFieldsRow(
          'Province',
          _provinceController,
          'City',
          _cityController,
        ),
        const SizedBox(height: 20),
        _buildCupertinoButton(
            'Create account', const Color(0xFF337586), CupertinoColors.white),
        const SizedBox(height: 20),
        buildCenteredText('or', 14, FontWeight.w600), // Or text
        const SizedBox(height: 20),
        _buildGoogleSignInButton(),
        const SizedBox(height: 20),
        _buildSignInText(context),
      ],
    );
  }

  /* Helper functions 
   _buildTwoFieldsRow Build a row with two text fields 
   _buildSignInText Build the sign in text at the bottom of the screen
   _buildCupertinoTextField Build a Cupertino text field
   _buildCupertinoButton Build a Cupertino button
   _buildText Build a text widget
   _buildGoogleSignInButton Build a Google sign in button
   */

  Row _buildTwoFieldsRow(
    String placeholder1,
    TextEditingController controller1,
    String placeholder2,
    TextEditingController controller2,
  ) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: _buildCupertinoTextField(placeholder1, controller1, false),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: _buildCupertinoTextField(placeholder2, controller2, false),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInText(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF337586),
            fontWeight: FontWeight.w600,
            letterSpacing: -0.20,
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Sign in',
              style: const TextStyle(
                color: Color(0xFF42BCDB),
                fontWeight: FontWeight.w600,
                letterSpacing: -0.20,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, '/signin');
                },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCupertinoTextField(
    String placeholder,
    TextEditingController controller,
    bool obscureText,
  ) {
    return CupertinoTextField(
      controller: controller,
      obscureText: obscureText,
      placeholder: placeholder,
      padding: const EdgeInsets.all(16.0),
      placeholderStyle: const TextStyle(
        color: Color(0xFFA1A1A1),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildCupertinoButton(
      String text, Color backgroundColor, Color textColor) {
    return CupertinoButton(
      onPressed: () async {
        if (_formKey.currentState?.validate() ?? false) {
          try {
            UserCredential userCredential =
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

            // User registration successful
            print('User registered: ${userCredential.user?.uid}');
          } catch (e) {
            // Handle registration errors
            print('Registration failed: $e');
          }
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

  Widget _buildText(String text, double fontSize, FontWeight fontWeight,
      double letterSpacing) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: CupertinoColors.systemGrey, // Border color
          width: 1, // Thickness of the border
        ),
        borderRadius:
            BorderRadius.circular(14), // Border radius of the container
      ),
      child: CupertinoButton(
        onPressed: () {},
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'http://pngimg.com/uploads/google/google_PNG19635.png',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 2),
            const Text('Sign in with Google',
                style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
