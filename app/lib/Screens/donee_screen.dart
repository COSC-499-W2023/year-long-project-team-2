import 'dart:convert';
import 'dart:io' show Platform;

import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/progress_bar.dart';
import 'package:FoodHood/Models/PostDetailViewModel.dart';
import 'package:FoodHood/Screens/detail_screen.dart';
import 'package:FoodHood/Screens/donor_rating.dart';
import 'package:FoodHood/Screens/donor_screen.dart';
import 'package:FoodHood/Screens/message_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DoneePath extends StatefulWidget {
  final String postId;
  const DoneePath({super.key, required this.postId});
  @override
  _DoneePathState createState() => _DoneePathState();
}

class _DoneePathState extends State<DoneePath> {
  late PostDetailViewModel viewModel;
  late LatLng pickupLatLng = const LatLng(49.8862, -119.4971);
  bool isLoading = true;
  OrderState orderState = OrderState.reserved;
  final Map<LatLng, String> _addressCache = {};

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        backgroundColor: detailsBackgroundColor,
        navigationBar: _buildNavigationBar(),
        child: SafeArea(child: _buildContent()));
  }

  Future<String> getAddressFromLatLng(LatLng position) async {
    if (_addressCache.containsKey(position)) {
      return _addressCache[position]!;
    }

    String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['results'] != null &&
          jsonResponse['results'].length > 0) {
        _addressCache[position] =
            jsonResponse['results'][0]['formatted_address'];
        return _addressCache[position]!;
      } else {
        return 'Address not found';
      }
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  BoxDecoration getShadowDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(100.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(16, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 0),
            spreadRadius: 2,
          )
        ],
      );

  @override
  void initState() {
    super.initState();
    viewModel = PostDetailViewModel(widget.postId);
    viewModel.fetchData(widget.postId).then((_) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  Widget _buildCancelButton() {
    return Container(
      width: double.infinity,
      height: 60.0,
      decoration: getShadowDecoration(),
      child: CupertinoButton(
        onPressed: _handleCancelReservation,
        color: CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(100.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(FeatherIcons.x,
                color: CupertinoColors.destructiveRed, size: 24.0),
            const SizedBox(width: 8.0),
            Text('Cancel Reservation',
                style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 18.0,
                    letterSpacing: -0.72,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('post_details')
          .doc(widget.postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const Center(child: Text('Order not found.'));
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        var postStatus = data['post_status'] ?? 'not reserved';
        orderState = _mapStatusToOrderState(postStatus);
        pickupLatLng = _getLatLngFromGeoPoint(data['post_location']);
        return _buildDetailsScrollView(data, postStatus);
      },
    );
  }

  Widget _buildDetailsScrollView(Map<String, dynamic> data, String postStatus) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPostDetailsSection(postStatus),
            if (postStatus == 'confirmed' ||
                postStatus == 'delivering' ||
                postStatus == 'readyToPickUp') ...[
              _buildMapAndAddressSection(),
              const SizedBox(height: 16),
              _buildDonorMessageSection(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildNavigateButton()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildReviewButton()),
                ],
              )
            ],
            if (postStatus == 'pending') ...[
              _buildImageSection(),
              const SizedBox(height: 32),
              _buildPendingConfirmationButton(),
              const SizedBox(height: 16),
              _buildCancelButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDonorMessageSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SizedBox(
                width: 30.0,
                height: 30.0,
                child: //clipoval
                    IconPlaceholder(imageUrl: viewModel.profileURL)),
          ),
          Expanded(
            child: MessageBox(
                context: context, text: viewModel.pickupInstructions),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    String imageUrl = viewModel.imagesWithAltText.isNotEmpty
        ? viewModel.imagesWithAltText[0]['url'] ?? ''
        : '';

    return SizedBox(
      height: 220,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => const CupertinoActivityIndicator(),
          errorWidget: (context, url, error) =>
              const CupertinoActivityIndicator(),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(child: CupertinoActivityIndicator());
  }

  Widget _buildMap(LatLng position) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: SizedBox(
        height: 240,
        child: GoogleMap(
          initialCameraPosition:
              CameraPosition(target: position, zoom: 14.4746),
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          markers: {
            Marker(
                markerId: const MarkerId("pickupLocation"),
                position: position,
                infoWindow: const InfoWindow(title: "Pickup Location")),
          },
        ),
      ),
    );
  }

  Widget _buildMapAndAddressSection() {
    return Column(
      children: [
        _buildMap(pickupLatLng),
        const SizedBox(height: 16),
        FutureBuilder<String>(
          future: getAddressFromLatLng(pickupLatLng),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CupertinoActivityIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text(snapshot.data ?? '',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.56,
                  ));
            }
          },
        ),
      ],
    );
  }

  Widget _buildNavigateButton() {
    return Container(
        height: 60.0,
        decoration: getShadowDecoration(),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _launchMapUrl(pickupLatLng),
          color: CupertinoColors.tertiarySystemBackground,
          borderRadius: BorderRadius.circular(100.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.location_fill,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                  size: 22.0),
              const SizedBox(width: 8.0),
              Text('Directions',
                  style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 18.0,
                      letterSpacing: -0.72,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ));
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: detailsBackgroundColor,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Icon(FeatherIcons.x,
            size: 24, color: CupertinoColors.label.resolveFrom(context)),
      ),
      trailing: isLoading
          ? const CupertinoActivityIndicator()
          : CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) =>
                            MessageScreen(receiverID: viewModel.userid)));
              },
              child: Text('Message ${viewModel.firstName}',
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w500)),
            ),
      border: null,
    );
  }

  Widget _buildPendingConfirmationButton() {
    return PendingConfirmationWithTimer(
      durationInSeconds: 60,
      postId: widget.postId,
    );
  }

  Widget _buildPostDetailsSection(String postStatus) {
    String titleText = postStatus == "readyToPickUp"
        ? 'Your order from ${viewModel.firstName} is ready to pick up'
        : 'You have reserved the ${viewModel.title} from ${viewModel.firstName}';

    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          titleText,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 32,
              letterSpacing: -1.8,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: ClipOval(
                  child: viewModel.profileURL.isNotEmpty &&
                          viewModel.profileURL.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: viewModel.profileURL,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CupertinoActivityIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Image.asset('assets/images/sampleProfile.png',
                          fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Posted by ${viewModel.firstName} ${viewModel.lastName}  ${viewModel.timeAgoSinceDate(viewModel.postTimestamp)}',
                style: TextStyle(
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context)
                        .withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.48),
              ),
              const SizedBox(width: 8),
              Icon(Icons.star, color: secondaryColor, size: 14),
              Text(
                ' ${viewModel.rating} Rating',
                style: TextStyle(
                  overflow: TextOverflow.fade,
                  color: CupertinoColors.secondaryLabel
                      .resolveFrom(context)
                      .withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.48,
                ),
              ),
            ]),
        const SizedBox(height: 24),
        ProgressBar(
            progress: _calculateProgress(),
            labels: const ["Reserved", "Confirmed", "Delivering", "Dropped Off"],
            color: accentColor,
            isReserved: true,
            currentState: orderState),
      ],
    );
  }

  Widget _buildReviewButton() {
    return Container(
      height: 60.0,
      decoration: getShadowDecoration(),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _navigateToRatingPage,
        color: CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(100.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.star_fill, color: yellow, size: 24.0),
            const SizedBox(width: 8.0),
            Text('Review',
                style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 18.0,
                    letterSpacing: -0.72,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDependentButtons(String postStatus) {
    return Row(
      children: [
        if (postStatus == "confirmed" ||
            postStatus == "delivering" ||
            postStatus == "readyToPickUp")
          Expanded(child: _buildNavigateButton()),
        if (postStatus == "pending" || postStatus == "not reserved")
          Expanded(
              child: PendingConfirmationWithTimer(
                  durationInSeconds: 60, postId: widget.postId)),
      ],
    );
  }

  double _calculateProgress() {
    switch (orderState) {
      case OrderState.reserved:
        return 0.25; // Progress for reserved state
      case OrderState.confirmed:
        return 0.5; // Progress for confirmed state
      case OrderState.delivering:
        return 0.75; // Progress for delivering state
      case OrderState.readyToPickUp:
        return 1.0; // Progress for readyToPickUp state
      default:
        return 0.0; // Default progress
    }
  }

  LatLng _getLatLngFromGeoPoint(dynamic postLocation) {
    if (postLocation is GeoPoint) {
      return LatLng(postLocation.latitude, postLocation.longitude);
    } else {
      return const LatLng(49.8862, -119.4971); // Default location
    }
  }

  void _handleCancelReservation() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      if (userSnapshot.exists) {
        List<String> reservedPosts =
            List<String>.from(userSnapshot.data()?['reserved_posts'] ?? []);
        reservedPosts.remove(widget.postId);
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .update({'reserved_posts': reservedPosts});
      }
      await FirebaseFirestore.instance
          .collection('post_details')
          .doc(widget.postId)
          .update({
        'reserved_by': FieldValue.delete(),
        'post_status': "not reserved"
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reservation cancelled successfully.'),
          duration: Duration(seconds: 2)));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to cancel reservation. Please try again.'),
          duration: Duration(seconds: 2)));
    }
  }

  Future<void> _launchMapUrl(LatLng locationCoordinates) async {
    final Uri uri = Platform.isIOS
        ? Uri.parse(
            'http://maps.apple.com/?q=${locationCoordinates.latitude},${locationCoordinates.longitude}')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${locationCoordinates.latitude},${locationCoordinates.longitude}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $uri';
    }
  }

  OrderState _mapStatusToOrderState(String postStatus) {
    switch (postStatus) {
      case 'pending':
        return OrderState.reserved;
      case 'confirmed':
        return OrderState.confirmed;
      case 'delivering':
        return OrderState.delivering;
      case 'readyToPickUp':
        return OrderState.readyToPickUp;
      default:
        return OrderState.reserved;
    }
  }

  void _navigateToRatingPage() {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => DonorRatingPage(
                postId: widget.postId, receiverID: 
                viewModel.userid)));
  }
}

class PendingConfirmationWithTimer extends StatefulWidget {
  final int durationInSeconds;
  final String postId;

  const PendingConfirmationWithTimer({
    super.key,
    required this.durationInSeconds,
    required this.postId,
  });

  @override
  _PendingConfirmationWithTimerState createState() =>
      _PendingConfirmationWithTimerState();
}

class _PendingConfirmationWithTimerState
    extends State<PendingConfirmationWithTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  String _printDuration(Duration duration) {
    int totalSeconds = widget.durationInSeconds - duration.inSeconds;
    return "$totalSeconds s left";
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationInSeconds),
    )
      ..addListener(() {
        setState(() {});
        if (_controller.isCompleted) {
          _updatePostStatusAndPop();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(16, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 0),
            spreadRadius: 2,
          )
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          // Do nothing
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100.0),
          child: Stack(
            children: <Widget>[
              LinearProgressIndicator(
                  value: _controller.value,
                  backgroundColor: CupertinoColors.tertiarySystemBackground
                      .resolveFrom(context),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      secondaryColor.resolveFrom(context)),
                  minHeight: 60),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Pending Confirmation',
                        style: TextStyle(
                          color: CupertinoColors.label.resolveFrom(context),
                          fontSize: 18,
                          letterSpacing: -0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _printDuration(Duration(
                            seconds:
                                (widget.durationInSeconds * _controller.value)
                                    .round())),
                        style: TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                          letterSpacing: -0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updatePostStatusAndPop() async {
    try {
      // Attempt to update the Firestore document
      await FirebaseFirestore.instance
          .collection('post_details')
          .doc(widget.postId)
          .update({
        'post_status': 'not reserved',
        'reserved_by': FieldValue.delete(),
      });

      // Use a mounted check to ensure that the widget is still in the widget tree
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (error) {
      // Handle any errors here, for example, by showing a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update post status. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
