import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AltTextEditor extends StatefulWidget {
  final String imagePath;
  final Function(String altText) onAltTextSaved; // Add this line
  final String? existingAltText; // Add this line

  const AltTextEditor({
    Key? key,
    required this.imagePath,
    required this.onAltTextSaved,
    this.existingAltText, // Add this line
  }) : super(key: key);

  @override
  _AltTextEditorState createState() => _AltTextEditorState();
}

class _AltTextEditorState extends State<AltTextEditor> {
  final TextEditingController _altTextController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _charCount = ValueNotifier(0);
  final int _maxLength = 1000;

  @override
  void initState() {
    super.initState();
    if (widget.existingAltText != null) {
      // Check if existing alt text is provided
      _altTextController.text =
          widget.existingAltText!; // Set it as the initial text
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _altTextController.addListener(() {
      _charCount.value = _altTextController.text.length;
      if (_altTextController.text.length > _maxLength) {
        // Truncate the text to enforce max length without directly setting state
        _altTextController.text =
            _altTextController.text.substring(0, _maxLength);
        // Correctly position the cursor at the end after truncation
        _altTextController.selection =
            TextSelection.fromPosition(TextPosition(offset: _maxLength));
      }
    });
  }

  @override
  void dispose() {
    _altTextController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _charCount.dispose(); // Dispose of the ValueNotifier
    super.dispose();
  }

  void _handleSave() {
    widget.onAltTextSaved(_altTextController.text); // Modify this line
    Navigator.pop(context);
  }

  _determineImageProvider(String path) {
    return path.startsWith('http')
        ? CachedNetworkImageProvider(path)
        : FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDragHandle(),
        Expanded(
          child: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              backgroundColor:
                  CupertinoColors.systemBackground.resolveFrom(context),
              middle: Text('Write alt text'),
              transitionBetweenRoutes: false,
              border: Border(bottom: BorderSide.none),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    )),
                onPressed: _handleSave,
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text('Cancel',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: CupertinoColors.label.resolveFrom(context))),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  if (_focusNode.hasFocus) {
                    _focusNode.unfocus();
                  }
                },
                child: Container(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Image(
                              image: _determineImageProvider(widget.imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Text('What\'s an image description?',
                                        style: TextStyle(
                                            color: accentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    onPressed: () {
                                      _showImageDescriptionInfo(context);
                                    },
                                  ),
                                  ValueListenableBuilder<int>(
                                    valueListenable: _charCount,
                                    builder: (_, value, __) => Text(
                                        '$value/$_maxLength',
                                        style: TextStyle(
                                            color: CupertinoColors.systemGrey,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                              CupertinoTextField(
                                padding: EdgeInsets.only(bottom: 16),
                                controller: _altTextController,
                                focusNode: _focusNode,
                                placeholder: 'Image description',
                                placeholderStyle: TextStyle(
                                    color: CupertinoColors.placeholderText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                decoration: BoxDecoration(
                                    color: CupertinoColors.systemBackground
                                        .resolveFrom(context),
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDragHandle() {
    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
        child: Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
                color: CupertinoColors.systemGrey,
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }

  void _showImageDescriptionInfo(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add descriptions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You can add a description, sometimes called alt-text, to your photos so they’re accessible to even more people, including those who are blind or low vision.\n\n'
                        'Good descriptions are concise, but present what’s in your photos accurately enough to understand their context.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text('No, thanks',
                                  style: TextStyle(
                                      color: CupertinoColors.systemGrey)),
                              color: CupertinoColors.quaternarySystemFill,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: CupertinoButton(
                              color: accentColor,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                // Handle "Sure" action
                                Navigator.pop(context);
                              },
                              child: Text('Sure',
                                  style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ],
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
