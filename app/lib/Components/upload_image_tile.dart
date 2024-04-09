import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'Create Post/alt_text_editor.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;
  final Function(String altText) onAltTextChanged;
  final bool hasAltText;
  final String altText;

  const ImageTile({
    Key? key,
    required this.imagePath,
    required this.onRemove,
    required this.onAltTextChanged,
    this.hasAltText = false,
    this.altText = '',
  }) : super(key: key);

  void _showAltTextModal(BuildContext context) {
    HapticFeedback.mediumImpact();
    showCupertinoModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return AltTextEditor(
          imagePath: imagePath,
          existingAltText: altText,
          onAltTextSaved: (newAltText) {
            onAltTextChanged(newAltText);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: imagePath.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: imagePath,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                )
              : Image.file(
                  File(imagePath),
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
        ),
        _blurEffect(
          Icon(
            Icons.close,
            size: 16,
            color: CupertinoColors.label.resolveFrom(context).withOpacity(0.9),
          ),
          CupertinoColors.systemGrey6.resolveFrom(context).withOpacity(0.8),
          onRemove,
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: GestureDetector(
            onTap: () {
              _showAltTextModal(context);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: hasAltText
                            ? Colors.blue
                            : CupertinoColors.systemGrey6
                                .resolveFrom(context)
                                .withOpacity(0.9)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        '+ ALT',
                        style: TextStyle(
                          color: hasAltText
                              ? Colors.white
                              : CupertinoColors.label.resolveFrom(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _blurEffect(Widget child, Color backgroundColor, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              padding: EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
