import 'package:flutter/cupertino.dart';
import 'dart:io';

class ImageDisplayBox extends StatelessWidget {
  final String? imagePath;

  const ImageDisplayBox({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return imagePath != null
        ? Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x01000000),
                  blurRadius: 20,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 17.0),
            height: 250,
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: FileImage(File(imagePath!)),
                fit: BoxFit.cover,
              ),
            ),
          )
        : Container();
  }
}