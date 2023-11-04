// component.dart
// Themeing components

import 'package:flutter/cupertino.dart';

class Styles {
  static const TextStyle titleStyle = TextStyle(
    color: CupertinoColors.label,
    fontSize: 28,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    letterSpacing: -1.36,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: CupertinoColors.secondaryLabel,
    fontSize: 16,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    letterSpacing: -0.80,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: CupertinoColors.systemBackground,
    fontSize: 18,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    letterSpacing: -0.90,
  );

  static const TextStyle signUpTextStyle = TextStyle(
    color: Color(0xFF337586),
    fontSize: 12,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    letterSpacing: -0.20,
  );

  static const TextStyle signUpLinkStyle = TextStyle(
    color: Color(0xFF42BCDB),
    fontSize: 12,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    letterSpacing: -0.20,
  );
}


CupertinoNavigationBar buildNavigationBar(BuildContext context) {
  return CupertinoNavigationBar(
    backgroundColor: CupertinoColors.systemGroupedBackground,
    border: const Border(
      bottom: BorderSide.none,
    ),
    leading: CupertinoButton(
      padding: EdgeInsets.zero,
      child: const Icon(CupertinoIcons.back, color: Color(0xFF337586)),
      onPressed: () => Navigator.pop(context),
    ),
  );
}

CupertinoSliverNavigationBar buildMainNavigationBar(
    BuildContext context, String title) {
  return CupertinoSliverNavigationBar(
    backgroundColor: CupertinoColors.systemGroupedBackground,
    border: const Border(
      bottom: BorderSide.none,
    ),
    largeTitle: Text(
      title,
      style: TextStyle(
        letterSpacing: -1.36,
      ),
    ),
  );
}

CupertinoNavigationBar buildBackNavigationBar(BuildContext context) {
  return CupertinoNavigationBar(
    backgroundColor: CupertinoColors.systemBackground,
    border: const Border(
      bottom: BorderSide.none,
    ),
    leading: CupertinoButton(
      padding: EdgeInsets.zero,
      child: const Icon(CupertinoIcons.back, color: Color(0xFF337586)),
      onPressed: () => Navigator.pop(context),
    ),
  );
}

Widget buildGoogleSignInButton() {
  return Container(
    width: double.infinity,
    height: 50,
    decoration: BoxDecoration(
      border: Border.all(
        color: CupertinoColors.systemGrey,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(14),
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
          const Text(
            'Sign in with Google',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildCupertinoTextField(
    String placeholder, TextEditingController controller, bool obscureText) {
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

Widget buildText(String text, double fontSize, FontWeight fontWeight) {
  return Text(
    text,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
    ),
  );
}

Widget buildTextButton(String text, Alignment alignment, Color color,
    double fontSize, FontWeight fontWeight) {
  return Align(
    alignment: alignment,
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    ),
  );
}


Widget buildSignUpText(BuildContext context, String description, String link, String destination) {
  return Align(
    alignment: Alignment.center,
    child: GestureDetector(
      onTap: () => Navigator.pushNamed(context, destination),
      child: RichText(
        text: TextSpan(
          text: description,
          style: TextStyle(
            color: Color(0xFF337586),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          children: <TextSpan>[
            TextSpan(
              text: link,
              style: TextStyle(
                color: Color(0xFF43BDDC),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget buildCenteredText(
      String text, double fontSize, FontWeight fontWeight) {
    return Center(
      child: buildText(text, fontSize, fontWeight),
    );
  }