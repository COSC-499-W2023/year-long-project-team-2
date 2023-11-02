import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class RegistrationScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();

  RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemBackground,
        navigationBar: _buildNavigationBar(context),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: _buildSignupForm(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar(BuildContext context) {
    return CupertinoNavigationBar(
      backgroundColor: CupertinoColors.systemBackground,
      border: const Border(bottom: BorderSide(color: Colors.transparent)),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(CupertinoIcons.back, color: Color(0xFF337586)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Column _buildSignupForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildText('Create an account', 34, FontWeight.w600, -1.36),
        const SizedBox(height: 50),
        _buildTwoFieldsRow(
          'First Name', _firstNameController,
          'Last Name', _lastNameController,
        ),
        const SizedBox(height: 20),
        _buildCupertinoTextField('Email Address', _emailController, false),
        const SizedBox(height: 20),
        _buildCupertinoTextField('Password', _passwordController, true),
        const SizedBox(height: 20),
        _buildTwoFieldsRow(
          'Province', _provinceController,
          'City', _cityController,
        ),
        const SizedBox(height: 20),
        _buildCupertinoButton(
            'Create account', const Color(0xFF337586), Colors.white),
        const SizedBox(height: 20),
        _buildGoogleSignInButton(),
        const SizedBox(height: 20),
        _buildSignInText(context),
      ],
    );
  }

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

  // ...

  Widget _buildSignInText(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF337586),
            fontFamily: 'Inter',
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
        fontSize: 18,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildCupertinoButton(String text, Color backgroundColor, Color textColor) {
    return CupertinoButton(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          // Implement signup functionality
        }
      },
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildText(String text, double fontSize, FontWeight fontWeight, double letterSpacing) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'Inter',
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
          color: Colors.grey, // Color of the border
          width: 1, // Thickness of the border
        ),
        borderRadius:
            BorderRadius.circular(14), // Border radius of the container
      ),
      child: CupertinoButton(
        onPressed: () {},
        color: Colors.white,
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
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

