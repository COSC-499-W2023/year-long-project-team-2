import 'dart:io';

class ImageUploadModel {
  bool isUploaded;
  bool uploading;
  File imageFile;
  String imageUrl;

  ImageUploadModel({
    this.isUploaded = false,
    this.uploading = false,
    required this.imageFile,
    this.imageUrl = '',
  });
}
