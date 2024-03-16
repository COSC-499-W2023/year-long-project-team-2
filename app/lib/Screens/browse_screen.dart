// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

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
import 'package:FoodHood/Components/search_navigationBar.dart';
import 'package:FoodHood/firestore_service.dart';
import 'package:FoodHood/Components/filter_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sf_symbols/sf_symbols.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
  static Color circleFillColor = Colors.blue;
  static const double circleFillOpacity = 0.1;
  static Color circleStrokeColor = Colors.blue;
  static const int circleStrokeWidth = 4;
  static const double zoomThreshold = 16.0;

  // State variables
  double _searchRadius = baseSearchRadius;
  // mapBottomPadding is the bottom safe area padding
  double mapBottomPadding = 0;
  double mapTopPadding = 0;
  double currentZoomLevel = defaultZoomLevel;
  String? _mapStyle;
  Set<Marker> _markers = {};
  bool _showPostCard = false;
  MarkerId? _selectedMarkerId;
  Map<String, dynamic> _selectedPostData = {};
  CameraPosition? _lastKnownCameraPosition;
  late StreamSubscription<bool> keyboardVisibilitySubscription;
  bool isKeyboardVisible = false;
  bool _isZooming = false; // Adding the _isZooming variable here
  Map<String, Color> tagColors = {};
  List<Map<String, dynamic>> allPosts = [];
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  Timer? _debounce;
  List<Map<String, dynamic>> postsInCircle = [];

  BitmapDescriptor defaultIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor selectedIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentLocationFuture = _determineCurrentLocation();
    _setupKeyboardVisibilityListener();
    createCustomMarkerIcon(color: accentColor, isSelected: false);
    createCustomMarkerIcon(color: Colors.orange, isSelected: true);
    _fetchAllMarkers();
    _requestLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mapBottomPadding = MediaQuery.of(context).padding.bottom;
    mapTopPadding = MediaQuery.of(context).padding.top;
  }

  void _setupKeyboardVisibilityListener() {
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardVisibilitySubscription = keyboardVisibilityController.onChange
        .listen(_keyboardVisibilityChanged);
  }

  void _keyboardVisibilityChanged(bool visible) {
    _debounceKeyboardHandling(visible);
  }

  Future<void> createCustomMarkerIcon(
      {required Color color, bool isSelected = false}) async {
    const double markerSize = 100.0; // Marker size including shadow and border
    const double shadowSize = 10.0; // Shadow size
    const double borderSize = 10.0; // White border size
    final double circleSize =
        markerSize - shadowSize - borderSize; // Inner circle size

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, shadowSize);
    canvas.drawCircle(
        Offset(markerSize / 2, markerSize / 2), circleSize / 2, shadowPaint);

    // White border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderSize;
    canvas.drawCircle(
        Offset(markerSize / 2, markerSize / 2), circleSize / 2, borderPaint);

    // Inner circle
    final Paint circlePaint = Paint()..color = color;
    canvas.drawCircle(Offset(markerSize / 2, markerSize / 2),
        (circleSize - borderSize) / 2, circlePaint);

    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage(markerSize.toInt(), markerSize.toInt());
    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    // Update the appropriate icon based on whether it's selected or not
    setState(() {
      if (isSelected) {
        selectedIcon = BitmapDescriptor.fromBytes(uint8List);
      } else {
        defaultIcon = BitmapDescriptor.fromBytes(uint8List);
      }
    });
  }

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
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentLocationFuture =
          Future.value(LatLng(position.latitude, position.longitude));
    });
  }

  Future<LatLng> _fetchCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return fallbackLocation;
    }
  }

  Future<LatLng?> _determineCurrentLocation() async {
    try {
      LatLng currentLocation = await _fetchCurrentLocation();
      _updateSearchAreaCircle(currentLocation);
      return currentLocation;
    } catch (e) {
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
        circleId: const CircleId('searchArea'),
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
      // If the search text is empty, show all markers
      _fetchAllMarkers();
      return;
    }
    FirebaseFirestore.instance
        .collection('post_details')
        .where('title',
            isEqualTo:
                searchText) // Adjust the field name as per your Firestore collection
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
            icon: _selectedMarkerId == MarkerId(doc.id)
                ? selectedIcon
                : defaultIcon,
            onTap: () => _onMarkerTapped(doc.id));

        filteredMarkers.add(marker);
      }
      setState(() => _markers = filteredMarkers);
    }).catchError((error) {});
  }

  void _onMarkerTapped(String markerId) {
    final MarkerId tappedMarkerId = MarkerId(markerId);

    setState(() {
      // Toggle the selected marker state
      if (_selectedMarkerId == tappedMarkerId) {
        _selectedMarkerId = null;
      } else {
        _selectedMarkerId = tappedMarkerId;
      }
    });

    // Now refresh the marker to update the icon
    _updateMarkerIcon(tappedMarkerId);
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
    }).catchError((error) {});
  }

  void _updateMarkerIcon(MarkerId tappedMarkerId) {
    final Marker? tappedMarker = _markers.firstWhere(
      (m) => m.markerId == tappedMarkerId,
      orElse: () => Marker(markerId: MarkerId('default')),
    );

    if (tappedMarker != null) {
      // Create a new Marker with updated icon property
      final Marker updatedMarker = tappedMarker.copyWith(
        iconParam:
            (_selectedMarkerId == tappedMarkerId) ? selectedIcon : defaultIcon,
      );

      // Update the markers set with the new marker
      setState(() {
        _markers.removeWhere((m) => m.markerId == tappedMarkerId);
        _markers.add(updatedMarker);
      });
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
              onTap: () => _onMarkerTapped(doc.id),
              icon: _selectedMarkerId == MarkerId(doc.id)
                  ? selectedIcon
                  : defaultIcon,
            );
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
    }).catchError((error) {});
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop()),
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
          return const Center(child: CupertinoActivityIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Error fetching location'));
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
      return const SizedBox.shrink();
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
    return Stack(
      children: [
        Positioned(
          bottom: mapBottomPadding + 16,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 20,
                    offset: Offset(0, 0),
                  ),
                ],
                borderRadius: BorderRadius.circular(
                    100.0), // Match button's border radius
              ),
              child: CupertinoButton(
                  onPressed: _currentLocation,
                  color: CupertinoColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(100.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 14.0),
                  child: _isZooming
                      ? _zoomButtonContent()
                      : _locationButtonContent()),
            ),
          ),
        ),
        Positioned(
          bottom: mapBottomPadding + 16,
          right: 20,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 20,
                    offset: Offset(0, 0),
                  ),
                ],
                borderRadius: BorderRadius.circular(100.0),
              ),
              child: CupertinoButton(
                onPressed: () => _showFeelingLuckyModal(context),
                color: CupertinoColors.tertiarySystemBackground,
                borderRadius: BorderRadius.circular(100.0),
                padding: EdgeInsets.all(14.0),
                child: _RandomPostContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFeelingLuckyModal(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
            child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: _buildModalContent(context),
        ));
      },
    );
  }

  Row _zoomButtonContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(FeatherIcons.maximize2,
            size: 18, color: CupertinoColors.activeOrange),
        const SizedBox(width: 8.0),
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
        const Icon(CupertinoIcons.location_fill,
            size: 18, color: CupertinoColors.activeBlue),
        const SizedBox(width: 8.0),
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

  Row _RandomPostContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SfSymbol(
          size: 18,
          weight: FontWeight.w400,
          color: orange.resolveFrom(context),
          name: 'dice.fill',
        ),
      ],
    );
  }

  Widget _buildOverlayUI() {
    return Stack(
      children: [
        CupertinoSearchNavigationBar(
          title: "Browse",
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

  void _fetchAllMarkers() async {
    FirebaseFirestore.instance
        .collection('post_details')
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
          final markerId = MarkerId(doc.id);

          final marker = Marker(
            markerId: markerId,
            position: postLatLng,
            onTap: () => _onMarkerTapped(doc.id),
            icon: _selectedMarkerId == markerId ? selectedIcon : defaultIcon,
          );
          allMarkers.add(marker);
        }
        allPosts.add(data);
      }
      setState(() => _markers = allMarkers);
    }).catchError((error) {});
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

  Widget _buildModalContent(BuildContext context) {
    // Define commonly used text styles to avoid redundancy
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 22,
      letterSpacing: -0.6,
    );

    final descriptionStyle = TextStyle(
      fontSize: 16,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
      letterSpacing: -0.6,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Fit content
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Image(
                  image: AssetImage('assets/images/dice.png'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text("Can't make up your mind?", style: titleStyle),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                "Let us decide for you!",
                textAlign: TextAlign.center,
                style: descriptionStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 0), // Adjust the padding if needed
              child: SizedBox(
                width: double
                    .infinity, // Forces the button to expand to fill the width
                child: CupertinoButton(
                  color:
                      secondaryColor, // Ensure this variable is defined or replace it with a specific color
                  child: Text(
                    'Pick for me', // Changed 'Connect' to 'Pick for me' to match the context
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.8,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _pickRandomPost();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
