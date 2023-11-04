import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../components.dart'; 

class BrowseScreen extends StatefulWidget {
  @override
  _BrowseScreenState createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController textController = TextEditingController();
  final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.77483, -122.41942), // Coordinates for San Francisco
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground, // background color
      child: CustomScrollView(
        slivers: <Widget>[
          SliverMainAxisGroup(
            slivers: <Widget>[
              buildMainNavigationBar(context, 'Browse'), // navigation bar
              SliverFillRemaining(
                child: GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  mapType: MapType.normal,
                  scrollGesturesEnabled:
                      true, // This ensures that the map can be panned
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
