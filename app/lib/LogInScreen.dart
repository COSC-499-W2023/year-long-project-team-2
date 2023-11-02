import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LogInScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  LogInScreen({super.key});

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
              child: _buildLoginForm(context),
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

  Column _buildLoginForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildText('Log in', 34, FontWeight.w600, -1.36),
            const SizedBox(height: 50),
            _buildCupertinoTextField('Email Address', emailController, false),
            const SizedBox(height: 20),
            _buildCupertinoTextField('Password', passwordController, true),
            const SizedBox(height: 20),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextButton('Forgot Password?', Alignment.centerRight,
                const Color(0xFF337586), 12, FontWeight.w500),
            const SizedBox(height: 20),
            _buildCupertinoButton('Continue', const Color(0xFF337586), Colors.white),
            const SizedBox(height: 20),
            _buildCenteredText('or', 14, FontWeight.w600),
            const SizedBox(height: 20),
            _buildGoogleSignInButton(),
            const SizedBox(height: 20),
            _buildSignUpText(context),
          ],
        ),
      ],
    );
  }

  Widget _buildText(String text, double fontSize, FontWeight fontWeight,
      double letterSpacing) {
    return Text(
      text,
      style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Inter',
          fontWeight: fontWeight,
          letterSpacing: letterSpacing),
    );
  }

  Widget _buildTextButton(String text, Alignment alignment, Color color,
      double fontSize, FontWeight fontWeight) {
    return Align(
      alignment: alignment,
      child: Text(
        text,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: 'Inter',
            fontWeight: fontWeight),
      ),
    );
  }

  Widget _buildCupertinoButton(
      String text, Color backgroundColor, Color textColor) {
    return CupertinoButton(
      onPressed: () {},
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: Text(text,
          style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCupertinoTextField(
      String placeholder, TextEditingController controller, bool obscureText) {
    return CupertinoTextField(
      controller: controller,
      obscureText: obscureText,
      placeholder: placeholder,
      padding: const EdgeInsets.all(16.0),
      placeholderStyle: const TextStyle(
          color: Color(0xFFA1A1A1),
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500),
      decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildCenteredText(
      String text, double fontSize, FontWeight fontWeight) {
    return Center(child: _buildText(text, fontSize, fontWeight, 0));
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

  Widget _buildSignUpText(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/signup'),
        child: RichText(
          text: const TextSpan(
            text: "Don't have an account? ",
            style: TextStyle(
                color: Color(0xFF337586),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500),
            children: <TextSpan>[
              TextSpan(
                text: 'Sign up',
                style: TextStyle(
                    color: Color(0xFF43BDDC), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
