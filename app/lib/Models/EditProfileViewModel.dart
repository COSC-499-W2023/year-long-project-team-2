import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:flutter/Cupertino.dart';
import 'package:path_provider/path_provider.dart';


class EditProfileViewModel extends ChangeNotifier {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool isLoading = false;
  String profileImagePath = '';
  String selectedProvince = '';
  String selectedCity = '';
  List<String> provinces = [];
  Map<String, List<String>> cities = {};

  EditProfileViewModel() {
    fetchUserDetails();
    fetchProvincesAndCities();
  }

  Future<void> fetchProvincesAndCities() async {
    try {
      var documentSnapshot = await _firestore
          .collection('location')
          .doc('rLxaYnbNB4x6Rpvil1Oe')
          .get();
      if (documentSnapshot.exists) {
        Map<String, dynamic> data = documentSnapshot.get('location');
        Map<String, List<String>> fetchedCities = {};
        data.forEach((province, citiesList) {
          if (citiesList is List) {
            fetchedCities[province] = List<String>.from(citiesList);
          }
        });
        if (fetchedCities.isNotEmpty) {
          provinces = fetchedCities.keys.toList();
          cities = fetchedCities;
        }
        notifyListeners();
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  Future<void> fetchUserDetails() async {
    isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('user').doc(user.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          aboutMeController.text = data['aboutMe'] ?? '';
          emailController.text = user.email ?? data['email'] ?? '';
          selectedProvince = data['province'] ?? selectedProvince;
          selectedCity = data['city'] ?? selectedCity;
          profileImagePath = data['profileImagePath'] ?? profileImagePath;
        }
      } catch (e) {
        print("Error fetching user details: $e");
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(VoidCallback onComplete) async {
    try {
      String userId = _auth.currentUser!.uid;
      Map<String, dynamic> updateData = {
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'aboutMe': aboutMeController.text,
        'email': emailController.text,
        'province': selectedProvince,
        'city': selectedCity,
      };
      if (_isImageChanged) {
        updateData['profileImagePath'] =
            await uploadImageToFirebase(File(profileImagePath));
      }
      await _firestore.collection('user').doc(userId).update(updateData);
      print("Profile updated successfully");
      onComplete();
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      String userId = _auth.currentUser!.uid;
      String fileName = 'profile_$userId.jpg';
      Reference storageRef =
          _storage.ref().child('profile_images').child(fileName);

      // Compress the image
      final Uint8List? compressedImage =
          await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 500, // Adjust based on your requirements
        minHeight: 500,
        quality: 85, // Adjust based on your requirements
      );

      if (compressedImage == null) {
        print("Error compressing image");
        return null;
      }

      // Create a temporary file to store the compressed image
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/temp_$fileName');
      await tempFile.writeAsBytes(compressedImage);

      // Upload the compressed image
      UploadTask uploadTask = storageRef.putFile(tempFile);
      await uploadTask.whenComplete(() => null);
      String downloadUrl = await storageRef.getDownloadURL();

      // Optionally, delete the temporary file after uploading
      await tempFile.delete();

      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void updateProfileImagePath(String newPath) {
    profileImagePath = newPath;
    notifyListeners();
  }

  bool _isImageChanged = false;

  void setImageChanged(bool value) {
    _isImageChanged = value;
    notifyListeners();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    aboutMeController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
