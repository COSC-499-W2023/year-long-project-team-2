import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:FoodHood/Services/FirebaseService.dart';

class CreatePostViewModel {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final pickupInstrController = TextEditingController();
  final altTextController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  DateTime selectedTime = DateTime.now();
  List<String> selectedAllergens = [], selectedCategories = [];
  String? selectedImagePath;
  Set<Marker> markers = {};

  void updateMarker(LatLng position) {
    markers = {
      Marker(
        markerId: MarkerId('centerMarker'),
        position: position,
      ),
    };
  }

  Future<Position> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = basename(imageFile.path);
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child('uploads/$fileName');
      UploadTask uploadTask = firebaseStorageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Map<String, String>> uploadImagesToFirebase(
      List<File> imageFiles) async {
    Map<String, String> urlToPathMap = {};
    for (File imageFile in imageFiles) {
      try {
        String fileName = 'post_${Uuid().v4()}.jpg';
        Reference storageRef =
            FirebaseStorage.instance.ref().child('post_images/$fileName');
        UploadTask uploadTask = storageRef.putFile(imageFile);
        await uploadTask;
        String downloadUrl = await storageRef.getDownloadURL();
        String httpsUrl =
            downloadUrl.replaceFirst(RegExp(r'^http://'), 'https://');
        urlToPathMap[httpsUrl] =
            imageFile.path; // Map the HTTPS URL to local path
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
    return urlToPathMap;
  }

  Future<List<String>> fetchDocumentData(
      String docName, String fieldName) async {
    try {
      var data = await readDocument(collectionName: 'Data', docName: docName);
      if (data != null && data.containsKey(fieldName)) {
        return List<String>.from(data[fieldName].cast<String>());
      } else {
        print('$docName document or $fieldName field not found.');
        return [];
      }
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String title,
    required String description,
    required List<String> allergens,
    required List<String> categories,
    required DateTime expirationDate,
    required String pickupInstructions,
    required DateTime pickupTime,
    required LatLng postLocation,
    required Map<String, String> imageUrlsWithAltText,
  }) async {
    try {
      List<Map<String, String>> imagesWithAltTextList =
          imageUrlsWithAltText.entries.map((entry) {
        return {
          'url': entry.key,
          'alt_text': entry.value,
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('post_details')
          .doc(postId)
          .update({
        'title': title,
        'description': description,
        'allergens': allergens.join(', '),
        'categories': categories.join(', '),
        'expiration_date': Timestamp.fromDate(expirationDate),
        'pickup_instructions': pickupInstructions,
        'pickup_time': Timestamp.fromDate(pickupTime),
        'post_location':
            GeoPoint(postLocation.latitude, postLocation.longitude),
        'images': imagesWithAltTextList,
      });

      return true;
    } catch (e) {
      print("Error updating post: $e");
      return false;
    }
  }

  Future<bool> savePost({
    required String title,
    required String description,
    required List<String> allergens,
    required List<String> categories,
    required DateTime expirationDate,
    required String pickupInstructions,
    required DateTime pickupTime,
    required LatLng postLocation,
    required Map<String, String> imageUrlsWithAltText,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String userId = user?.uid ?? 'default uid';
      String documentId = Uuid().v4();

      List<Map<String, String>> imagesWithAltTextList =
          imageUrlsWithAltText.entries.map((entry) {
        return {
          'url': entry.key,
          'alt_text': entry.value,
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('post_details')
          .doc(documentId)
          .set({
        'title': title,
        'description': description,
        'allergens': allergens.join(', '),
        'categories': categories.join(', '),
        'expiration_date': Timestamp.fromDate(expirationDate),
        'pickup_instructions': pickupInstructions,
        'pickup_time': Timestamp.fromDate(pickupTime),
        'user_id': userId,
        'post_location':
            GeoPoint(postLocation.latitude, postLocation.longitude),
        'post_timestamp': FieldValue.serverTimestamp(),
        'images': imagesWithAltTextList,
        'post_status': "not reserved",
      });
      await FirebaseFirestore.instance.collection('user').doc(userId).update({
        'posts': FieldValue.arrayUnion([documentId]),
      });

      return true;
    } catch (e) {
      print("Error saving post: $e");
      return false;
    }
  }

  void disposeControllers() {
    titleController.dispose();
    descController.dispose();
    pickupInstrController.dispose();
    altTextController.dispose();
  }
}
