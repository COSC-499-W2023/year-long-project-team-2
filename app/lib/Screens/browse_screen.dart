import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/compact_post_card.dart';
import 'package:FoodHood/Components/components.dart';
import 'package:FoodHood/Components/filter_sheet.dart';
import 'package:FoodHood/Components/search_navigationBar.dart';
import 'package:FoodHood/Services/FirebaseService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sf_symbols/sf_symbols.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  _BrowseScreenState createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const double defaultZoomLevel = 14.0;
  static const LatLng fallbackLocation = LatLng(49.2827, -123.1207);
  static const double baseSearchRadius = 1000;
  static Color circleFillColor = Colors.blue;

  static const double circleFillOpacity = 0.1;
  static Color circleStrokeColor = Colors.blue;
  static const int circleStrokeWidth = 4;
  static const double zoomThreshold = 16.0;
  GoogleMapController? mapController;
  Future<LatLng?>? currentLocationFuture;
  Circle? searchAreaCircle;
  TextEditingController searchController = TextEditingController();

  double _searchRadius = baseSearchRadius;
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
  bool _isZooming = false;
  Map<String, Color> tagColors = {};
  List<Map<String, dynamic>> allPosts = [];
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  Timer? _debounce;
  List<Map<String, dynamic>> postsInCircle = [];

  BitmapDescriptor defaultIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor selectedIcon = BitmapDescriptor.defaultMarker;

  @override
  Widget build(BuildContext context) {
    double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    double updatedMapBottomPadding = bottomInset > 0 ? 0 : mapBottomPadding;

    _checkAndUpdateMapStyle();
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      resizeToAvoidBottomInset: false,
      child: Stack(
        children: [
          _buildFullScreenMap(updatedMapBottomPadding),
          _buildOverlayUI(),
        ],
      ),
    );
  }

  Future<void> createCustomMarkerIcon(
      {required Color color, bool isSelected = false}) async {
    const double markerSize = 100.0;
    const double shadowSize = 10.0;
    const double borderSize = 10.0;
    const double circleSize = markerSize - shadowSize - borderSize;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, shadowSize);
    canvas.drawCircle(const Offset(markerSize / 2, markerSize / 2),
        circleSize / 2, shadowPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderSize;
    canvas.drawCircle(const Offset(markerSize / 2, markerSize / 2),
        circleSize / 2, borderPaint);

    final Paint circlePaint = Paint()..color = color;
    canvas.drawCircle(const Offset(markerSize / 2, markerSize / 2),
        (circleSize - borderSize) / 2, circlePaint);

    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage(markerSize.toInt(), markerSize.toInt());
    final ByteData? byteData =
        await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    setState(() {
      if (isSelected) {
        selectedIcon = BitmapDescriptor.fromBytes(uint8List);
      } else {
        defaultIcon = BitmapDescriptor.fromBytes(uint8List);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    mapBottomPadding = MediaQuery.of(context).padding.bottom;
    mapTopPadding = MediaQuery.of(context).padding.top;
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _checkAndUpdateMapStyle();
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

  Row locationButtonContent() {
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

  Row randomPostContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.casino_rounded,
            size: 20, color: CupertinoColors.activeOrange),
      ],
    );
  }

  void showFeelingLuckyModal(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: _buildModalContent(context),
        ));
      },
    );
  }

  Row zoomButtonContent() {
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

  Widget _buildBottomButton() {
    final BoxDecoration buttonDecoration = BoxDecoration(
      boxShadow: const [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: 20,
          offset: Offset(0, 0),
        ),
      ],
      borderRadius: BorderRadius.circular(100.0),
    );

    Widget buildButton({
      required VoidCallback onPressed,
      required Widget child,
      EdgeInsetsGeometry padding = const EdgeInsets.all(14.0),
      AlignmentGeometry alignment = Alignment.bottomCenter,
      EdgeInsetsGeometry margin = EdgeInsets.zero,
    }) {
      return Align(
        alignment: alignment,
        child: Container(
          decoration: buttonDecoration,
          margin: margin,
          child: CupertinoButton(
            onPressed: onPressed,
            color: CupertinoColors.tertiarySystemBackground,
            borderRadius: BorderRadius.circular(100.0),
            padding: padding,
            child: child,
          ),
        ),
      );
    }

    return Stack(
      children: [
        buildButton(
          onPressed: _currentLocation,
          child: _isZooming ? zoomButtonContent() : locationButtonContent(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        buildButton(
          onPressed: () => showFeelingLuckyModal(context),
          child: randomPostContent(),
          alignment: Alignment.bottomRight,
          margin: const EdgeInsets.only(right: 16.0),
          ),
      ],
    );
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
            Positioned(
              bottom: mapBottomPadding + 26,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showPostCard ? _buildPostCard() : _buildBottomButton(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalContent(BuildContext context) {
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Image.asset(
                  MediaQuery.of(context).platformBrightness == Brightness.dark
                      ? 'assets/images/dice_dark.png'
                      : 'assets/images/dice.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                "Can't make up your mind?",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                "Let us decide for you!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: secondaryColor,
                  child: const Text(
                    'Pick for me',
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

    return GestureDetector(
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
    );
  }

  double _calculateSearchRadius(double newZoomLevel) {
    double scale = math.pow(2, defaultZoomLevel - newZoomLevel).toDouble();
    return baseSearchRadius * scale;
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

  void _debounceKeyboardHandling(bool visible) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
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

  Future<LatLng?> _determineCurrentLocation() async {
    try {
      LatLng currentLocation = await _fetchCurrentLocation();
      _updateSearchAreaCircle(currentLocation);
      return currentLocation;
    } catch (e) {
      return fallbackLocation;
    }
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

  void _filterMarkersByTitle(String searchText) {
    if (searchText.isEmpty) {
      _fetchAllMarkers();
      return;
    }
    FirebaseFirestore.instance
        .collection('post_details')
        .where('title', isEqualTo: searchText)
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

  String _formatSearchRadius(double radius) {
    if (radius < 1000) {
      return '${radius.toStringAsFixed(0)} m';
    } else {
      return '${(radius / 1000).toStringAsFixed(1)} km';
    }
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

  void _handleSearchBarTapped() {
    _resetUIState();
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

  void _keyboardVisibilityChanged(bool visible) {
    _debounceKeyboardHandling(visible);
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
      _updateMarkersBasedOnCircle();
    });
  }

  void _onCameraMove(CameraPosition position) {
    double newZoomLevel = position.zoom;
    _lastKnownCameraPosition = position;

    setState(() {
      currentZoomLevel = newZoomLevel;
      _searchRadius = _calculateSearchRadius(newZoomLevel);
      if (newZoomLevel > zoomThreshold) {
        searchAreaCircle = null;
      } else {
        _updateSearchAreaCircle(position.target);
      }
      _updateMarkersBasedOnCircle();
    });
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

  void _onMarkerTapped(String markerId) {
    final MarkerId tappedMarkerId = MarkerId(markerId);

    setState(() {
      if (_selectedMarkerId == tappedMarkerId) {
        _selectedMarkerId = null;
      } else {
        _selectedMarkerId = tappedMarkerId;
      }
    });

    _updateMarkerIcon(tappedMarkerId);
    FirebaseFirestore.instance
        .collection('post_details')
        .doc(markerId)
        .get()
        .then((postDocument) async {
      if (postDocument.exists && postDocument.data() != null) {
        Map<String, dynamic> postData = postDocument.data()!;

        String title = postData['title'] ?? 'No Title';
        DateTime createdAt =
            (postData['post_timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now();
        List<String> tags = postData['categories'].split(',');

        List<Color> assignedColors = tags.map((tag) {
          tag = tag.trim();
          if (!tagColors.containsKey(tag)) {
            tagColors[tag] = _getRandomColor();
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
              'profileURL': userData?['profileImagePath'] ?? '',
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

  void _pickRandomPost() {
    if (allPosts.isEmpty) {
      return;
    }

    var random = math.Random();
    var randomPostIndex = random.nextInt(allPosts.length);
    var randomPost = allPosts[randomPostIndex];
    GeoPoint location = randomPost['post_location'];
    LatLng latLng = LatLng(location.latitude, location.longitude);
    _zoomToPostLocation(latLng);
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _fetchAndSetCurrentLocation();
    }
  }

  void _resetUIState() {
    setState(() {
      _showPostCard = false;
      _selectedPostData = {};
    });
  }

  void _setupKeyboardVisibilityListener() {
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardVisibilitySubscription = keyboardVisibilityController.onChange
        .listen(_keyboardVisibilityChanged);
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

  void _showFilterSheet() {
    showCupertinoModalBottomSheet(
      context: context,
      backgroundColor:
          CupertinoDynamicColor.resolve(groupedBackgroundColor, context),
      builder: (context) => SafeArea(child: FilterSheet()),
    );
  }

  void _updateMarkerIcon(MarkerId tappedMarkerId) {
    final Marker tappedMarker = _markers.firstWhere(
      (m) => m.markerId == tappedMarkerId,
      orElse: () => const Marker(markerId: MarkerId('default')),
    );
    final Marker updatedMarker = tappedMarker.copyWith(
      iconParam:
          (_selectedMarkerId == tappedMarkerId) ? selectedIcon : defaultIcon,
    );
    setState(() {
      _markers.removeWhere((m) => m.markerId == tappedMarkerId);
      _markers.add(updatedMarker);
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
        _resetUIState();
      }

      setState(() => _markers = newMarkers);
    }).catchError((error) {});
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

  void _zoomOutToDefault([LatLng? customTarget]) {
    LatLng target = customTarget ?? searchAreaCircle!.center;
    mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: defaultZoomLevel)));
  }

  void _zoomToPostLocation(LatLng postLatLng) {
    if (mapController == null) return;

    mapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: postLatLng,
        zoom: 16.0,
      ),
    ));
  }
}
