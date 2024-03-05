import 'dart:async';
import 'dart:math' as math;

import 'package:FoodHood/Components/compact_post_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/cupertinoSearchNavigationBar.dart';
import 'package:FoodHood/firestore_service.dart';
import 'package:FoodHood/Components/filtersheet.dart';
import 'package:permission_handler/permission_handler.dart';

class BrowseScreen extends StatefulWidget {
  @override
  _BrowseScreenState createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  Future<LatLng?>? currentLocationFuture;
  Circle? searchAreaCircle;
  TextEditingController searchController = TextEditingController();

  // Constants for map configurations
  static const double defaultZoomLevel = 14.0;
  static const LatLng fallbackLocation = LatLng(49.2827, -123.1207);
  static const double baseSearchRadius = 1000;
  static const Color circleFillColor = Colors.blue;
  static const double circleFillOpacity = 0.2;
  static const Color circleStrokeColor = Colors.blue;
  static const int circleStrokeWidth = 3;
  static const double zoomThreshold = 16.0;
  static const double maxZoomOutLevel = 10.0;

  // State variables
  double _searchRadius = baseSearchRadius;
  double mapBottomPadding = 80; // Default padding
  double mapTopPadding = 80;
  double currentZoomLevel = defaultZoomLevel;
  String? _mapStyle;
  Set<Marker> _markers = {};
  bool _showPostCard = false;
  Map<String, dynamic> _selectedPostData = {};
  CameraPosition? _lastKnownCameraPosition;
  late StreamSubscription<bool> keyboardVisibilitySubscription;
  bool isKeyboardVisible = false;
  bool _isZooming = false; // Adding the _isZooming variable here
  Map<String, Color> tagColors = {};
  List<Map<String, dynamic>> allPosts = [];

  List<Map<String, dynamic>> postsInCircle = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentLocationFuture = _determineCurrentLocation();
    _setupKeyboardVisibilityListener();
    _fetchAllMarkers();
    _requestLocationPermission(); // Request location permission
  }

  void _setupKeyboardVisibilityListener() {
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardVisibilitySubscription = keyboardVisibilityController.onChange
        .listen(_keyboardVisibilityChanged);
  }

  void _keyboardVisibilityChanged(bool visible) {
    _debounceKeyboardHandling(visible);
  }

  // Method to retrieve posts within the circle's radius
  Future<void> _retrievePostsInCircle() async {
    if (searchAreaCircle == null) {
      postsInCircle = [];
      return;
    }

    var querySnapshot = await FirebaseFirestore.instance
        .collection('post_details')
        .where('reserved_by', isNull: true) // Exclude posts with 'reserved_by'
        .get();
    List<Map<String, dynamic>> retrievedPosts = [];

    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      LatLng postLatLng = LatLng(data['latitude'], data['longitude']);
      double distance = Geolocator.distanceBetween(
          searchAreaCircle!.center.latitude,
          searchAreaCircle!.center.longitude,
          postLatLng.latitude,
          postLatLng.longitude);

      if (distance <= searchAreaCircle!.radius) {
        retrievedPosts.add(data);
      }
    }

    setState(() {
      postsInCircle = retrievedPosts;
    });
  }

  Timer? _debounce;

  void _debounceKeyboardHandling(bool visible) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          if (visible) {
            mapBottomPadding = 0;
            mapTopPadding = 0;
          } else {
            mapBottomPadding = 80;
            mapTopPadding = 80;
          }
        });
      }
    });
  }

  void _pickRandomPost() {
    if (allPosts.isEmpty) {
      print("No posts available to pick from.");
      return; // Return if there are no posts
    }

    var random = math.Random();
    var randomPostIndex = random.nextInt(allPosts.length);
    var randomPost = allPosts[randomPostIndex];

    // Assuming 'post_location' is stored as GeoPoint in Firestore
    GeoPoint location = randomPost['post_location'];
    LatLng latLng = LatLng(location.latitude, location.longitude);
    _zoomToPostLocation(latLng); // Navigate to the selected post's location
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    keyboardVisibilitySubscription.cancel();
    searchController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _checkAndUpdateMapStyle();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      // If granted, fetch the current location
      _fetchAndSetCurrentLocation();
    }
  }

  Future<void> _fetchAndSetCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLocationFuture =
            Future.value(LatLng(position.latitude, position.longitude));
      });
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<LatLng> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Error fetching location: $e");
      return fallbackLocation;
    }
  }

  Future<LatLng?> _determineCurrentLocation() async {
    try {
      LatLng currentLocation = await _fetchCurrentLocation();
      _updateSearchAreaCircle(currentLocation);
      return currentLocation;
    } catch (e) {
      _showErrorDialog(context, 'Location Error',
          'Enable location services in System Settings and try again.');
      return fallbackLocation;
    }
  }

  void _checkAndUpdateMapStyle() async {
    String stylePath =
        MediaQuery.of(context).platformBrightness == Brightness.dark
            ? 'assets/map_style_dark.json'
            : 'assets/map_style_light.json';
    String style = await rootBundle.loadString(stylePath);
    if (_mapStyle != style) {
      setState(() => _mapStyle = style);
      mapController?.setMapStyle(_mapStyle);
    }
  }

  void _onCameraMove(CameraPosition position) {
    double newZoomLevel = position.zoom;
    _lastKnownCameraPosition = position;

    // Update the state with the new zoom level and adjust the search radius and circle as needed
    setState(() {
      currentZoomLevel = newZoomLevel; // Update current zoom level
      _searchRadius = _calculateSearchRadius(newZoomLevel);
      if (newZoomLevel > zoomThreshold) {
        searchAreaCircle = null;
      } else {
        _updateSearchAreaCircle(position.target);
      }
      _updateMarkersBasedOnCircle();
    });
  }

  bool _isZoomingIn(double newZoomLevel) {
    // Determine if the user is zooming in by comparing new zoom level with the last known zoom level
    return newZoomLevel > currentZoomLevel;
  }

  void _onCameraIdle() {
    setState(() {
      _isZooming = false;
      if (_lastKnownCameraPosition != null) {
        double currentZoomLevel = _lastKnownCameraPosition!.zoom;
        if (currentZoomLevel <= zoomThreshold && searchAreaCircle == null) {
          _updateSearchAreaCircle(_lastKnownCameraPosition!.target);
        }
      }
      _updateMarkersBasedOnCircle(); // Update this method call
    });
  }

  double _calculateSearchRadius(double newZoomLevel) {
    double scale = math.pow(2, defaultZoomLevel - newZoomLevel).toDouble();
    return baseSearchRadius * scale;
  }

  void _updateSearchAreaCircle(LatLng location) {
    setState(() {
      searchAreaCircle = Circle(
        circleId: CircleId('searchArea'),
        center: location,
        radius: _searchRadius,
        fillColor: circleFillColor.withOpacity(circleFillOpacity),
        strokeColor: circleStrokeColor,
        strokeWidth: circleStrokeWidth,
      );
    });
  }

  void _filterMarkersByTitle(String searchText) {
    if (searchText.isEmpty) {
      _fetchAllMarkers();
      return;
    }
    FirebaseFirestore.instance
        .collection('post_details')
        .where('title', isEqualTo: searchText)
        .where('reserved_by', isNull: true) // Exclude posts with 'reserved_by'
        .get()
        .then((querySnapshot) {
      Set<Marker> filteredMarkers = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final LatLng postLatLng = LatLng(
            double.parse(data['latitude'].toString()),
            double.parse(data['longitude'].toString()));

        final marker = Marker(
            markerId: MarkerId(doc.id),
            position: postLatLng,
            onTap: () => _onMarkerTapped(doc.id));

        filteredMarkers.add(marker);
      }
      setState(() => _markers = filteredMarkers);
    }).catchError((error) {
      print("Error fetching filtered post details: $error");
    });
  }

  void _onMarkerTapped(String markerId) {
    FirebaseFirestore.instance
        .collection('post_details')
        .doc(markerId)
        .get()
        .then((postDocument) async {
      if (postDocument.exists && postDocument.data() != null) {
        Map<String, dynamic> postData = postDocument.data()!;

        // Extract fields safely
        String title = postData['title'] ?? 'No Title';
        DateTime createdAt =
            (postData['post_timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now();
        List<String> tags = postData['categories'].split(',');

        // Assign colors to tags
        List<Color> assignedColors = tags.map((tag) {
          tag = tag.trim();
          if (!tagColors.containsKey(tag)) {
            tagColors[tag] =
                _getRandomColor(); // Assign a new color if not already assigned
          }
          return tagColors[tag]!;
        }).toList();

        String userId = postData['user_id'] ?? 'Unknown';

        await readDocument(collectionName: 'user', docName: userId)
            .then((userData) {
          setState(() {
            _showPostCard = true;

            _selectedPostData = {
              'image_url':
                  postData['image_url'] ?? 'assets/images/sampleFoodPic.png',
              'title': title,
              'tags': tags,
              'profileURL':
                  userData?['profileImagePath'] ?? '', // Add this line
              'tagColors': assignedColors,
              'firstname': userData?['firstName'] ?? 'Unknown',
              'lastname': userData?['lastName'] ?? 'Unknown',
              'timeAgo': timeAgoSinceDate(createdAt),
              'postId': postDocument.id
            };
            GeoPoint? postLocationGeoPoint =
                postData['post_location'] as GeoPoint?;
            if (postLocationGeoPoint != null) {
              LatLng postLatLng = LatLng(postLocationGeoPoint.latitude,
                  postLocationGeoPoint.longitude);
              _zoomToPostLocation(postLatLng);
            }
          });
        });
      }
    }).catchError((error) {
      print("Error fetching post details: $error");
    });
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

  void _zoomToPostLocation(LatLng postLatLng) {
    if (mapController == null) return;

    mapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: postLatLng,
        zoom: 16.0, // You can adjust this zoom level as needed
      ),
    ));
  }

  void _resetUIState() {
    setState(() {
      _showPostCard = false;
      _selectedPostData = {};
    });
  }

  void _updateMarkersBasedOnCircle() {
    if (searchAreaCircle == null) return;
    FirebaseFirestore.instance
        .collection('post_details')
        .get()
        .then((querySnapshot) {
      Set<Marker> newMarkers = {};
      bool selectedMarkerInsideCircle = false;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final GeoPoint? postLocationGeoPoint =
            data['post_location'] as GeoPoint?;
        if (postLocationGeoPoint != null) {
          final postLatLng = LatLng(
              postLocationGeoPoint.latitude, postLocationGeoPoint.longitude);

          final double distance = Geolocator.distanceBetween(
              searchAreaCircle!.center.latitude,
              searchAreaCircle!.center.longitude,
              postLatLng.latitude,
              postLatLng.longitude);

          if (distance <= _searchRadius) {
            final marker = Marker(
                markerId: MarkerId(doc.id),
                position: postLatLng,
                onTap: () => _onMarkerTapped(doc.id));
            newMarkers.add(marker);

            if (_selectedPostData.isNotEmpty &&
                doc.id == _selectedPostData['postId']) {
              selectedMarkerInsideCircle = true;
            }
          }
        }
      }

      if (!selectedMarkerInsideCircle) {
        _resetUIState(); // Reset UI state if the selected marker is outside the circle
      }

      setState(() => _markers = newMarkers);
    }).catchError((error) {
      print("Error fetching post details: $error");
    });
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          CupertinoDialogAction(
              child: Text('OK'), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    double updatedMapBottomPadding = bottomInset > 0 ? 0 : mapBottomPadding;

    _checkAndUpdateMapStyle();
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: Stack(
        children: [
          _buildFullScreenMap(updatedMapBottomPadding),
          _buildOverlayUI(),
        ],
      ),
    );
  }

  Widget _buildFullScreenMap(double bottomPadding) {
    return FutureBuilder<LatLng?>(
      future: currentLocationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CupertinoActivityIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('Error fetching location'));
        }
        if (snapshot.hasData) {
          mapController?.setMapStyle(_mapStyle);
        }

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onMapTapped,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              markers: _markers,
              initialCameraPosition: CameraPosition(
                target: snapshot.data!,
                zoom: currentZoomLevel,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              circles: searchAreaCircle != null ? {searchAreaCircle!} : {},
              padding:
                  EdgeInsets.only(bottom: mapBottomPadding, top: mapTopPadding),
            ),
            if (_showPostCard) _buildPostCard(),
            if (!_showPostCard) _buildBottomButton(),
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController?.setMapStyle(_mapStyle);

    currentLocationFuture?.then((currentLocation) {
      if (currentLocation != null) {
        mapController?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(target: currentLocation, zoom: defaultZoomLevel)));
      }
    });
  }

  void _onMapTapped(LatLng tapLocation) {
    if (_lastKnownCameraPosition == null) return;
    double currentZoomLevel = _lastKnownCameraPosition!.zoom;
    if (currentZoomLevel > zoomThreshold) {
      bool isOutside = _isOutsideSearchArea(tapLocation);
      _zoomOutToDefault(isOutside ? tapLocation : null);
      _resetUIState();
    } else {
      _resetUIState();
    }
  }

  bool _isOutsideSearchArea(LatLng tapLocation) {
    if (searchAreaCircle == null) return true;
    final double distance = Geolocator.distanceBetween(
        searchAreaCircle!.center.latitude,
        searchAreaCircle!.center.longitude,
        tapLocation.latitude,
        tapLocation.longitude);
    return distance > _searchRadius;
  }

  void _zoomOutToDefault([LatLng? customTarget]) {
    LatLng target = customTarget ?? searchAreaCircle!.center;
    mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: defaultZoomLevel)));
  }

  Widget _buildPostCard() {
    if (_selectedPostData.isEmpty) {
      return SizedBox.shrink();
    }
    String imageLocation =
        _selectedPostData['image_url'] ?? 'assets/images/sampleFoodPic.png';
    String title = _selectedPostData['title'] ?? 'Title Not Found';
    List<String> tags = List<String>.from(_selectedPostData['tags'] ?? []);
    String firstname = _selectedPostData['firstname'] ?? 'Unknown';
    String lastname = _selectedPostData['lastname'] ?? 'Unknown';
    String timeAgo = _selectedPostData['timeAgo'] ?? 'Unknown';
    String postId = _selectedPostData['postId'] ?? '0';
    String profileURL = _selectedPostData['profileURL'] ?? '';

    return Positioned(
      bottom: mapBottomPadding + 24,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 10) {
            _zoomOutToDefault(null);
            _resetUIState();
          }
        },
        onTap: () => _resetUIState(),
        child: CompactPostCard(
          imageLocation: imageLocation,
          title: title,
          tags: tags,
          tagColors: _generateTagColors(tags.length),
          firstname: firstname,
          lastname: lastname,
          timeAgo: timeAgo,
          onTap: (postId) => _onMarkerTapped(postId),
          postId: postId,
          profileURL: profileURL,
          showTags: false,
        ),
      ),
    );
  }

  List<Color> _generateTagColors(int numberOfTags) {
    List<Color> tagColors = [];
    List<Color> availableColors = [
      Colors.lightGreenAccent,
      Colors.lightBlueAccent,
      Colors.pinkAccent[100]!,
      Colors.yellowAccent[100]!
    ];
    for (int i = 0; i < numberOfTags; i++) {
      tagColors.add(availableColors[i % availableColors.length]);
    }
    return tagColors;
  }

  Widget _buildBottomButton() {
    return Positioned(
      bottom: mapBottomPadding + 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 20,
                offset: Offset(0, 0),
              ),
            ],
            borderRadius:
                BorderRadius.circular(100.0), // Match button's border radius
          ),
          child: CupertinoButton(
            onPressed: _currentLocation,
            color: CupertinoColors.tertiarySystemBackground,
            borderRadius: BorderRadius.circular(100.0),
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: _isZooming ? _zoomButtonContent() : _locationButtonContent(),
          ),
        ),
      ),
    );
  }

  Row _zoomButtonContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(FeatherIcons.maximize2,
            size: 18, color: CupertinoColors.activeOrange),
        SizedBox(width: 8.0),
        Text(
          _formatSearchRadius(_searchRadius * 2),
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.8,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        )
      ],
    );
  }

  Row _locationButtonContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.location_fill,
            size: 18, color: CupertinoColors.activeBlue),
        SizedBox(width: 8.0),
        Text(
          'Current Location',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.8,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayUI() {
    return Stack(
      children: [
        CupertinoSearchNavigationBar(
          title: "Browse",
          onFeelingLuckyPressed: _pickRandomPost,
          textController: searchController,
          onSearchTextChanged: (text) {
            if (text.isEmpty) {
              _fetchAllMarkers();
            } else {
              _filterMarkersByTitle(text);
            }
          },
          buildFilterButton: () => _buildFilterButton(),
          onSearchBarTapped: _handleSearchBarTapped,
        ),
      ],
    );
  }

  void _fetchAllMarkers() {
    FirebaseFirestore.instance
        .collection('post_details')
        .where('reserved_by', isNull: true) // Exclude posts with 'reserved_by'
        .get()
        .then((querySnapshot) {
      Set<Marker> allMarkers = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        double? latitude = double.tryParse(data['latitude']?.toString() ?? '');
        double? longitude =
            double.tryParse(data['longitude']?.toString() ?? '');

        if (latitude != null && longitude != null) {
          final LatLng postLatLng = LatLng(latitude, longitude);

          final marker = Marker(
              markerId: MarkerId(doc.id),
              position: postLatLng,
              onTap: () => _onMarkerTapped(doc.id));

          allMarkers.add(marker);
        }

        allPosts.add(data); // Add post data to the list
      }
      setState(() => _markers = allMarkers);
    }).catchError((error) {
      print("Error fetching all post details: $error");
    });
  }

  void _handleSearchBarTapped() {
    _resetUIState();
  }

  Widget _buildFilterButton() {
    return GestureDetector(
      onTap: _showFilterSheet,
      child: Container(
        height: 37,
        width: 37,
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(FeatherIcons.filter,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            size: 20),
      ),
    );
  }

  void _currentLocation() async {
    if (mapController == null) return;
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng latLng = LatLng(position.latitude, position.longitude);
      mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: defaultZoomLevel)));
      _updateSearchAreaCircle(latLng);
    } catch (e) {
      _showErrorDialog(context, 'Location Error',
          'Enable location services in System Settings and try again.');
    }
  }

  void _showFilterSheet() {
    showCupertinoModalBottomSheet(
      context: context,
      backgroundColor:
          CupertinoDynamicColor.resolve(groupedBackgroundColor, context),
      builder: (context) => SafeArea(child: FilterSheet()),
    );
  }

  String _formatSearchRadius(double radius) {
    if (radius < 1000) {
      return '${radius.toStringAsFixed(0)} m';
    } else {
      return '${(radius / 1000).toStringAsFixed(1)} km';
    }
  }

  Color _getRandomColor() {
    var random = math.Random();
    var colors = [
      yellow,
      orange,
      blue,
      babyPink,
    ];
    return colors[random.nextInt(colors.length)];
  }
}
