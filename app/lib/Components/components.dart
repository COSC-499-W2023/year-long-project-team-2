// component.dart
// Themeing components

import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:FoodHood/Models/PostDetailViewModel.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Styles {
  static TextStyle titleStyle = TextStyle(
    color: CupertinoColors.label,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.36,
  );

  static TextStyle descriptionStyle = TextStyle(
    color: CupertinoColors.secondaryLabel,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.80,
  );

  static TextStyle buttonTextStyle = TextStyle(
    color: CupertinoColors.systemBackground,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.90,
  );

  static TextStyle signUpTextStyle = TextStyle(
    color: accentColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.20,
  );

  static TextStyle signUpLinkStyle = TextStyle(
    color: secondaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.20,
  );
}

CupertinoNavigationBar buildNavigationBar(BuildContext context) {
  return CupertinoNavigationBar(
    backgroundColor: groupedBackgroundColor,
    border: Border(
      bottom: BorderSide.none,
    ),
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Icon(FeatherIcons.chevronLeft,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context)),
    ),
  );
}

CupertinoSliverNavigationBar buildMainNavigationBar(
    BuildContext context, String title) {
  return CupertinoSliverNavigationBar(
    transitionBetweenRoutes: false,
    backgroundColor:
        CupertinoDynamicColor.resolve(groupedBackgroundColor, context)
            .withOpacity(0.8),
    border: const Border(
      bottom: BorderSide.none,
    ),
    largeTitle: Text(
      title,
    ),
    stretch: true, // Enable stretch behavior
  );
}

CupertinoNavigationBar buildBackNavigationBar(BuildContext context) {
  return CupertinoNavigationBar(
    backgroundColor: groupedBackgroundColor,
    border: const Border(
      bottom: BorderSide.none,
    ),
    leading: GestureDetector(
      child: Icon(FeatherIcons.chevronLeft,
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
          size: 24),
      onTap: () => Navigator.pop(context),
    ),
  );
}

Widget buildGoogleSignInButton(BuildContext context) {
  return Container(
    width: double.infinity,
    height: 50,
    decoration: BoxDecoration(
      border: Border.all(
        color:
            CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: CupertinoButton(
      onPressed: () {},
      color: CupertinoDynamicColor.resolve(
          CupertinoColors.tertiarySystemBackground, context),
      borderRadius: BorderRadius.circular(14),
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/google.png', width: 20, height: 20),
          const SizedBox(width: 2),
          Text(
            'Sign in with Google',
            style: TextStyle(
              color:
                  CupertinoDynamicColor.resolve(CupertinoColors.label, context),
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
    String placeholder,
    TextEditingController controller,
    BuildContext context,
    List<String> autofillHints,
    {String? errorText,
    Function(String)? liveValidation}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        padding: EdgeInsets.all(16.0),
        textAlign: TextAlign.left,
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        placeholderStyle: TextStyle(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.placeholderText, context),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        autofillHints: autofillHints,
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.tertiarySystemBackground, context),
          borderRadius: BorderRadius.circular(12),
          border: errorText != null
              ? Border.all(color: CupertinoColors.systemRed)
              : null,
        ),
        onChanged: (value) {
          if (liveValidation != null) {
            liveValidation(value);
          }
        },
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: Text(errorText,
              style: TextStyle(
                  color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemRed, context),
                  fontSize: 12)), // Display error text if not null
        ),
    ],
  );
}

Widget buildText(String text, double fontSize, FontWeight fontWeight) {
  return Text(
    text,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -1.40,
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

Widget buildSignUpText(
    BuildContext context, String description, String link, String destination) {
  return Align(
    alignment: Alignment.center,
    child: GestureDetector(
      onTap: () => Navigator.pushNamed(context, destination),
      child: RichText(
        text: TextSpan(
          text: description,
          style: TextStyle(
            color: accentColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.20,
          ),
          children: <TextSpan>[
            TextSpan(
              text: link,
              style: TextStyle(
                color: CupertinoColors.systemCyan,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String determineDate(DateTime messageDate) {
  final today = DateTime.now();
  final yesterday = DateTime.now().subtract(Duration(days: 1));

  if (messageDate.year == today.year &&
      messageDate.month == today.month &&
      messageDate.day == today.day) {
    return 'Today'.toUpperCase();
  } else if (messageDate.year == yesterday.year &&
             messageDate.month == yesterday.month &&
             messageDate.day == yesterday.day) {
    return 'Yesterday'.toUpperCase();
  } else {
    return DateFormat('MMMM dd, yyyy').format(messageDate).toUpperCase();
  }
}


String determineDateTime(Timestamp timestamp) {
  final now = DateTime.now();
  DateTime date = timestamp.toDate();
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime messageDate = DateTime(date.year, date.month, date.day);
  DateTime yesterday = today.subtract(const Duration(days: 1));

  String formattedDate;

  if (messageDate == today) {
    formattedDate = "Today, ${DateFormat('h:mm a').format(date)}";
  } else if (messageDate == yesterday) {
    formattedDate = "Yesterday, ${DateFormat('h:mm a').format(date)}";
  } else {
    formattedDate = DateFormat('MMM d, h:mm a').format(date);
  }
  return formattedDate;
}

Widget buildCenteredText(String text, double fontSize, FontWeight fontWeight) {
  return Center(
    child: Text(
      text.toUpperCase(), // Convert text to uppercase
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.4,
      ),
    ),
  );
}

Widget buildImageFailedPlaceHolder(BuildContext context, bool isCompact) {
  return isCompact
      ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded,
                size: 40,
                color: CupertinoColors.secondaryLabel.resolveFrom(context)),
          ],
        )
      : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(padding: EdgeInsets.only(top: 80)),
            //broken image icon
            Icon(Icons.broken_image_rounded,
                size: 60,
                color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            SizedBox(height: 8.0), // Add some spacing
            Text(
              'Image failed to load',
              style: TextStyle(
                  fontSize: 16,
                  letterSpacing: -0.5,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            )
          ],
        );
}

class IconPlaceholder extends StatelessWidget {
  final String imageUrl;
  IconPlaceholder({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      child: ClipOval(
        child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              )
            : Image.asset(
                'assets/images/sampleProfile.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class CombinedTexts extends StatelessWidget {
  final String firstName;
  final String lastName;
  final DateTime postTimestamp;
  final PostDetailViewModel viewModel;

  const CombinedTexts({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.postTimestamp,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Posted by $firstName $lastName  ${viewModel.timeAgoSinceDate(postTimestamp)}',
          style: TextStyle(
            color: CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.48,
          ),
        ),
        Text("  "),
        RatingText(viewModel: viewModel),
      ],
    );
  }
}

class InfoText extends StatelessWidget {
  final String firstName;
  final String lastName;
  final DateTime postTimestamp;
  final PostDetailViewModel viewModel;

  const InfoText({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.postTimestamp,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      overflow: TextOverflow.fade,
      text: TextSpan(
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.48,
        ),
        children: <TextSpan>[
          TextSpan(text: 'Prepared by $firstName $lastName'),
          TextSpan(text: '   '),
          TextSpan(
            text: 'Posted ${viewModel.timeAgoSinceDate(postTimestamp)}',
            style: TextStyle(letterSpacing: -0.48),
          ),
        ],
      ),
    );
  }
}

class RatingText extends StatelessWidget {
  final PostDetailViewModel viewModel;

  const RatingText({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: secondaryColor,
          size: 14,
        ),
        const SizedBox(width: 3),
        Text(
          '${viewModel.rating} Rating',
          style: TextStyle(
            overflow: TextOverflow.fade,
            color: CupertinoColors.label.resolveFrom(context).withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.48,
          ),
        ),
      ],
    );
  }
}

class PasswordCupertinoTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final List<String>? autofillHints;
  final String? errorText;
  final BuildContext? context;
  final Function(String)? liveValidation;
  final bool? showHint;

  const PasswordCupertinoTextField({
    Key? key,
    this.controller,
    this.placeholder,
    this.context,
    this.autofillHints,
    this.errorText,
    this.liveValidation,
    this.showHint = false,
  }) : super(key: key);

  @override
  _PasswordCupertinoTextFieldState createState() =>
      _PasswordCupertinoTextFieldState();
}

class _PasswordCupertinoTextFieldState
    extends State<PasswordCupertinoTextField> {
  bool _obscureText = true;
  FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    // Add focus listener to manage hint text visibility
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _isFocused) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoTextField(
          focusNode: _focusNode, // Use the focus node
          controller: widget.controller,
          obscureText: _obscureText,
          placeholder: widget.placeholder,
          padding: EdgeInsets.all(16.0),
          textAlign: TextAlign.left,
          style: TextStyle(
            color:
                CupertinoDynamicColor.resolve(CupertinoColors.label, context),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          placeholderStyle: TextStyle(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.placeholderText, context),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          autofillHints: widget.autofillHints,
          decoration: BoxDecoration(
            color: CupertinoDynamicColor.resolve(
                CupertinoColors.tertiarySystemBackground, context),
            borderRadius: BorderRadius.circular(12),
            border: widget.errorText != null
                ? Border.all(color: CupertinoColors.systemRed)
                : null,
          ),
          onChanged: (value) {
            if (widget.liveValidation != null) {
              widget.liveValidation!(value);
            }
          },
          suffix: widget.placeholder == 'Password'
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                          _obscureText ? FeatherIcons.eyeOff : FeatherIcons.eye,
                          color: CupertinoDynamicColor.resolve(
                              CupertinoColors.placeholderText, context),
                          size: 20)),
                )
              : null,
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            child: Text(widget.errorText!,
                style:
                    TextStyle(color: CupertinoColors.systemRed, fontSize: 12)),
          ),
        // Display hint text based on focus state and showHint flag
        if (_isFocused && widget.showHint!)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
            child: Text(
              'Password must be at least 8 letters long, with one upper case letter, one lower case letter, and one number.',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

String timeAgoSinceDate(DateTime dateTime) {
  final duration = DateTime.now().difference(dateTime);
  if (duration.inDays > 8) {
    return 'on ${DateFormat('MMMM dd, yyyy').format(dateTime)}';
  } else if (duration.inDays >= 1) {
    return '${duration.inDays} days ago';
  } else if (duration.inHours >= 1) {
    return '${duration.inHours} hours ago';
  } else if (duration.inMinutes >= 1) {
    return '${duration.inMinutes} minutes ago';
  } else {
    return 'Just now';
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;

  const Tag({Key? key, required this.text, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(color, context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.computeLuminance() > 0.5
              ? CupertinoColors.black
              : CupertinoColors.white,
          fontSize: 10,
          letterSpacing: -0.40,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
