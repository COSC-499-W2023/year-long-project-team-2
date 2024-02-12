import 'package:FoodHood/Components/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'dart:ui'; // Needed for ImageFilter

class CupertinoSearchNavigationBar extends StatefulWidget {
  final String title;
  final Widget? trailing;
  final TextEditingController textController;
  final Function(String) onSearchTextChanged;
  final Widget Function() buildFilterButton;
  final VoidCallback onSearchBarTapped;
  final VoidCallback? onFeelingLuckyPressed;

  const CupertinoSearchNavigationBar({
    Key? key,
    required this.title,
    this.trailing,
    required this.textController,
    required this.onSearchTextChanged,
    required this.buildFilterButton,
    required this.onSearchBarTapped,
    this.onFeelingLuckyPressed,
  }) : super(key: key);

  @override
  _CupertinoSearchNavigationBarState createState() =>
      _CupertinoSearchNavigationBarState();
}

class _CupertinoSearchNavigationBarState
    extends State<CupertinoSearchNavigationBar> {
  late FocusNode _focusNode;
  bool _showCancelButton = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onSearchBarFocusChange);
    widget.textController.addListener(_updateCancelButtonVisibility);
  }

  void _onSearchBarFocusChange() {
    if (_focusNode.hasFocus) {
      // When the search bar gains focus, show the cancel button and trigger onSearchBarTapped.
      setState(() {
        _showCancelButton = true;
      });
      widget.onSearchBarTapped();
    } else {
      // Optionally, you could handle logic for when the search bar loses focus here,
      // such as hiding the cancel button if the text field is empty.
      _updateCancelButtonVisibility();
    }
  }

  void _updateCancelButtonVisibility() {
    final shouldShow = widget.textController.text.isNotEmpty ||
        _focusNode.hasFocus; // Update to include focus check
    if (_showCancelButton != shouldShow) {
      setState(() {
        _showCancelButton = shouldShow;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onSearchBarFocusChange);
    _focusNode.dispose();
    widget.textController.removeListener(_updateCancelButtonVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(groupedBackgroundColor, context)
              .withOpacity(0.4),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitle(context),
                  const SizedBox(height: 8),
                  _buildSearchBar(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showFeelingLuckyModal(context),
              child: Text(
                "Feeling Lucky?",
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.6,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 36,
                  letterSpacing: -1.3,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                overflow:
                    TextOverflow.ellipsis, // This applies to the Text widget
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFeelingLuckyModal(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FeatherIcons.frown, size: 42, color: blue),
                    const SizedBox(height: 16),
                    Text(
                      "Struggling to decide?",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Let us pick a place for you!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      color: accentColor,
                      child: Text(
                        'Pick for me',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.8,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // BrowseScreen._pickRandomPost();
                        widget.onFeelingLuckyPressed?.call();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CupertinoSearchTextField(
            suffixIcon: Icon(
              FeatherIcons.x,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 20,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.only(left: 6.0, top: 2.0),
              child: Icon(
                FeatherIcons.search,
                size: 18.0,
              ),
            ),
            placeholder: 'Search Nearby',
            placeholderStyle: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            style: TextStyle(
              fontSize: 18,
              color: CupertinoColors.label.resolveFrom(context),
            ),
            backgroundColor: CupertinoColors.tertiarySystemBackground,
            controller: widget.textController,
            onChanged: (text) {
              widget.onSearchTextChanged(text);
              _updateCancelButtonVisibility();
            },
            focusNode: _focusNode,
          ),
        ),
        const SizedBox(width: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          child: _showCancelButton
              ? _buildCancelButton(context)
              : widget.buildFilterButton(),
          key: ValueKey(_showCancelButton),
        ),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return SizedBox(
      height: 20,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          widget.textController.clear();
          widget.onSearchTextChanged(
              ''); // Clear the text and pass an empty string to the callback
          _focusNode.unfocus(); // Add this line to hide the keyboard
          _updateCancelButtonVisibility();
        },
        child: Text(
          'Cancel',
          style: TextStyle(
            color: accentColor,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
