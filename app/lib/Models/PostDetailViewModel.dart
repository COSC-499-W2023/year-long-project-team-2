import 'dart:convert'; // For JSON decoding

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PostDetailViewModel extends ChangeNotifier {
  late String firstName;
  late String lastName;
  late String allergens;
  late String description;
  late DateTime pickupTime;
  late DateTime expirationDate;
  late String pickupLocation;
  late String pickupInstructions;
  late String title;
  late double rating;
  late String userid;
  late DateTime postTimestamp;
  late bool isReserved;
  late LatLng pickupLatLng;
  late List<String> tags;
  late String imageUrl;
  late String profileURL;
  late String postLocation;
  late List<Map<String, String>> imagesWithAltText = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isFavorite = false;
  final Map<LatLng, String> _geocodeCache = {};

  PostDetailViewModel(String postId) {
    _initializeFields();
    fetchData(postId);
  }

  void _initializeFields() {
    firstName = '';
    lastName = '';
    allergens = '';
    description = '';
    pickupTime = DateTime.now();
    expirationDate = DateTime.now();
    pickupLocation = '';
    pickupInstructions = '';
    title = '';
    rating = 0.0;
    userid = '';
    imageUrl = ''; // Set the image URL
    profileURL = '';
    postTimestamp = DateTime.now();
    isReserved = false;
    pickupLatLng = LatLng(0, 0);
    tags = [];
  }

  Future<void> fetchData(String postId) async {
    try {
      var documentSnapshot = await firestore.collection('post_details').doc(postId).get();
      if (documentSnapshot.exists) {
        var documentData = documentSnapshot.data() as Map<String, dynamic>;
        await Future.wait([
          _updatePostDetails(documentData),
          _fetchAndUpdateUserDetails(documentData['user_id']),
        ]);
        await checkIfFavorite(postId);
      }
    } catch (e) {
      print('Error fetching post details: $e');
    }
  }

  Future<void> _fetchAndUpdateUserDetails(String userId) async {
    try {
      var userDocumentSnapshot = await firestore.collection('user').doc(userId).get();
      if (userDocumentSnapshot.exists) {
        var userDocumentData = userDocumentSnapshot.data() as Map<String, dynamic>;
        _updateUserDetails(userDocumentData);
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> checkIfFavorite(String postId) async {
    String userId = getCurrentUserUID();
    if (userId.isNotEmpty) {
      var userDoc = await firestore.collection('user').doc(userId).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> savedPosts = userData['saved_posts'] ?? [];
        isFavorite = savedPosts.contains(postId);
        notifyListeners();
      }
    }
  }

  Future<void> _updatePostDetails(Map<String, dynamic> documentData) async {
    allergens = documentData['allergens'] ?? '';
    description = documentData['description'] ?? '';
    title = documentData['title'] ?? '';
    pickupInstructions = documentData['pickup_instructions'] ?? '';
    userid = documentData['user_id'] ?? '';
    isReserved = documentData['post_status'] != 'not reserved';

    GeoPoint geoPoint = documentData['post_location'] as GeoPoint;
    pickupLatLng = LatLng(geoPoint.latitude, geoPoint.longitude);

    await _reverseGeocodeLatLng(pickupLatLng);

    if (documentData.containsKey('images') && documentData['images'] is List) {
      imagesWithAltText = List<Map<String, String>>.from(
        (documentData['images'] as List).map((imageMap) {
          Map<String, dynamic> image = imageMap as Map<String, dynamic>;
          return {
            'url': image['url'] as String? ?? '',
            'alt_text': image['alt_text'] as String? ?? '',
          };
        }),
      );
    } else {
      imagesWithAltText = [];
    }
    pickupTime = (documentData['pickup_time'] as Timestamp).toDate();
    expirationDate = (documentData['expiration_date'] as Timestamp).toDate();
    postTimestamp = (documentData['post_timestamp'] as Timestamp).toDate();
    tags = (documentData['categories'] as String?)?.split(',') ?? [];
    notifyListeners();
  }

  void _updateUserDetails(Map<String, dynamic> userDocument) {
    firstName = userDocument['firstName'] ?? '';
    lastName = userDocument['lastName'] ?? '';
    rating = userDocument['avgRating']?.toDouble();
    profileURL = userDocument['profileImagePath'] ?? '';
    notifyListeners();
  }

  Future<void> _reverseGeocodeLatLng(LatLng coordinates) async {
    if (_geocodeCache.containsKey(coordinates)) {
      pickupLocation = _geocodeCache[coordinates]!;
      notifyListeners();
      return;
    }

    String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
    String url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${coordinates.latitude},${coordinates.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['results'] != null && jsonResponse['results'].length > 0) {
          String formattedAddress = jsonResponse['results'][0]['formatted_address'];
          pickupLocation = formattedAddress; // Update the pickupLocation
          _geocodeCache[coordinates] = formattedAddress; // Cache the result
          notifyListeners();
        }
      } else {
        print('Failed to load the address data');
      }
    } catch (e) {
      print('Error occurred while reverse geocoding: $e');
    }
  }

  Future<void> savePost(String postId) async {
    try {
      String userId = getCurrentUserUID();
      if (userId.isNotEmpty) {
        await firestore.collection('user').doc(userId).set({
          'saved_posts': FieldValue.arrayUnion([postId]),
        }, SetOptions(merge: true));

        isFavorite = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error saving post: $e');
    }
  }

  Future<void> unsavePost(String postId) async {
    try {
      String userId = getCurrentUserUID();
      if (userId.isNotEmpty) {
        await firestore.collection('user').doc(userId).update({
          'saved_posts': FieldValue.arrayRemove([postId]),
        });

        isFavorite = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error unsaving post: $e');
    }
  }

  String getCurrentUserUID() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  String timeAgoSinceDate(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 8) {
      return "on " + DateFormat('MMM d').format(dateTime);
    } else if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
