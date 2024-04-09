import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

class GoogleMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;
  final bool isCurrentLocation; // New boolean parameter

  GoogleMapWidget({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
    this.isCurrentLocation = true,
  }) : super(key: key);

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? mapController;
  String? _mapStyle;
  LatLng _currentCenter = LatLng(49.8875, -119.4961);
  Marker _centerMarker = Marker(
    markerId: MarkerId("centerMarker"),
    position: LatLng(49.8875, -119.4961),
    infoWindow: InfoWindow(title: "Center Location"),
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrentLocation) {
      _determinePosition().then((position) {
        if (position != null) {
          LatLng myLocation = LatLng(position.latitude, position.longitude);
          _updatePosition(myLocation);
        }
      }).catchError((e) {
        _useDefaultOrInitialLocation();
      });
    } else {
      _useDefaultOrInitialLocation();
    }
  }

  void _useDefaultOrInitialLocation() {
    setState(() {
      _currentCenter = widget.initialLocation!;
      _centerMarker = _centerMarker.copyWith(
          positionParam: _currentCenter); // Update marker position
      _isLoading = false;
    });
  }

  void _updatePosition(LatLng newPosition) {
    setState(() {
      _currentCenter = newPosition;
      _centerMarker = _centerMarker.copyWith(
          positionParam: newPosition); // Update marker position
      _isLoading = false;
    });
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
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

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _goToMyLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng myLocation = LatLng(position.latitude, position.longitude);
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(myLocation, 14));
      setState(() {
        _currentCenter = myLocation;
        _centerMarker = _centerMarker.copyWith(positionParam: myLocation);
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _setMapStyle().then((_) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentCenter, zoom: 16.0),
        ),
      );
    });
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentCenter = position.target;
      _centerMarker = _centerMarker.copyWith(positionParam: _currentCenter);
    });
    widget.onLocationSelected(_currentCenter);
  }

  Future<void> _setMapStyle() async {
    String style = await rootBundle.loadString(
        MediaQuery.of(context).platformBrightness == Brightness.dark
            ? 'assets/map_style_dark.json'
            : 'assets/map_style_light.json');
    if (_mapStyle != style) {
      setState(() {
        _mapStyle = style;
      });
      mapController?.setMapStyle(_mapStyle);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CupertinoActivityIndicator());
    }
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition:
              CameraPosition(target: _currentCenter, zoom: 12.0),
          onCameraMove: _onCameraMove,
          markers: {_centerMarker},
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          gestureRecognizers: Set()
            ..add(Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer())),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: CupertinoButton(
            onPressed: _goToMyLocation,
            color: CupertinoColors.tertiarySystemBackground,
            borderRadius: BorderRadius.circular(100.0),
            padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
            child: Icon(CupertinoIcons.location_fill,
                size: 18, color: CupertinoColors.activeBlue),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
