//donor_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/donor_order_info.dart';
import 'package:FoodHood/Components/image_display_box.dart';
import 'package:FoodHood/Components/progress_bar.dart';
import 'package:FoodHood/Models/PostDetailViewModel.dart';
import 'package:FoodHood/Screens/donee_rating.dart';
import 'package:FoodHood/Screens/message_screen.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:pull_down_button/pull_down_button.dart';

const double _iconSize = 22.0;
const double _defaultHeadingFontSize = 32.0;
const double _defaultFontSize = 16.0;
const double _defaultOrderInfoFontSize = 12.0;

// Define enum to represent different states
enum OrderState { notReserved, reserved, confirmed, delivering, readyToPickUp, completed }

class DonorScreen extends StatefulWidget {
  final String postId;
  const DonorScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _DonorScreenState createState() => _DonorScreenState();
}

class _DonorScreenState extends State<DonorScreen> {
  String? reservedByName; // Variable to store the reserved by user name
  String? reservedByLastName;
  double rating = 0.0;
  String pickupLocation = '';
  String photo = '';
  String? reservedByUserId = '';
  OrderState orderState = OrderState.notReserved;
  late double _textScaleFactor;
  late double adjustedFontSize;
  late double adjustedHeadingFontSize;
  late double adjustedOrderInfoFontSize;
  late LatLng pickupLatLng;
  late PostDetailViewModel viewModel;
  String location = "";
  String postStatus = 'not reserved';
  String? _selectedImagePath;
  String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    
    // Initialize the pickup location coordinates to downtown Kelowna
    pickupLatLng = LatLng(49.8862, -119.4971); 
    
    // Incorporate the font size change accessibility functionality
    _textScaleFactor =
        Provider.of<TextScaleProvider>(context, listen: false).textScaleFactor;
    _updateAdjustedFontSize();
    
    // Set up a stream listener for changes to the 'post_status' field to sync changes in real time
    FirebaseFirestore.instance
        .collection('post_details')
        .doc(widget.postId)
        .snapshots()
        .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.exists) {
        // Extract post_status and update orderState accordingly
        final String post_status = snapshot.data()?['post_status'];
        final String? reserved_by = snapshot.data()?['reserved_by'];

        setState(() {
          postStatus = post_status;
          
          if (reserved_by != null) {
            // Read post details
            fetchPostInformation();
          } else {
            reservedByName = null; // Reset the reservedByName if reserved_by is null
            reservedByLastName = null;
            rating = 0.0;
            photo = '';
          }

          switch (postStatus) {
            case 'not reserved':
              orderState = OrderState.notReserved;
              break;
            case 'pending':
              orderState = OrderState.reserved;
              break;
            case 'confirmed':
              orderState = OrderState.confirmed;
              break;
            case 'delivering':
              orderState = OrderState.delivering;
              break;
            case 'readyToPickUp':
              orderState = OrderState.readyToPickUp;
              break;
            case 'completed':
              orderState = OrderState.completed;
              break;
            default:
              orderState = OrderState.notReserved;
          }
        });
      } else {
        // Handle case where document does not exist
      }
    });
    
  }

  // Reading post information
  Future<void> fetchPostInformation() async {
    final CollectionReference postDetailsCollection =
        FirebaseFirestore.instance.collection('post_details');

    // Retrieve the reserved_by user ID from your current data
    final String postId = widget.postId;
    try {
      // Fetch the post details document
      final DocumentSnapshot postSnapshot =
          await postDetailsCollection.doc(postId).get();

      if (postSnapshot.exists) {
        // Extract the pickup location coordinates
        if (postSnapshot['post_location'] is GeoPoint) {
          GeoPoint geoPoint = postSnapshot['post_location'] as GeoPoint;
          setState(() {
            pickupLatLng = LatLng(geoPoint.latitude, geoPoint.longitude);
          });
        } else {
          // Provide a default location
          setState(() {
            pickupLatLng = LatLng(49.8862, -119.4971);
          });
        }

        // Extract the reserved_by user ID from the post details
        reservedByUserId = postSnapshot['reserved_by'];
        
        print(pickupLatLng);

        // Fetch the user document using reserved_by user ID if it exists
        if (reservedByUserId != null) {
          final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('user')
              .doc(reservedByUserId)
              .get();

          if (userSnapshot.exists) {
            // Extract the user name from the user document
            final userName = userSnapshot['firstName'];
            final userLastName = userSnapshot['lastName'];
            final userRating = userSnapshot['avgRating'];

            setState(() {
              reservedByName = userName;
              reservedByLastName = userLastName;
              rating = userRating;
              photo = userSnapshot['profileImagePath'] as String? ?? '';
            });
          } else {
            print(
                'User document does not exist for reserved by user ID: $reservedByUserId');
          }
        }

        // Extract post_status and set orderState accordingly
        final String post_status = postSnapshot['post_status'];

        setState(() {
          postStatus = post_status;
          switch (postStatus) {
            case 'not reserved':
              orderState = OrderState.notReserved;
              break;
            case 'pending':
              orderState = OrderState.reserved;
              break;
            case 'confirmed':
              orderState = OrderState.confirmed;
              break;
            case 'delivering':
              orderState = OrderState.delivering;
              break;
            case 'readyToPickUp':
              orderState = OrderState.readyToPickUp;
              break;
            case 'completed':
              orderState = OrderState.completed;
              break;
          }
        });
      } else {
        // Handle the case where the post details document doesn't exist
        print('Post details document does not exist for ID: $postId');
      }
    } catch (error) {
      print('Error fetching reserved by user name: $error');
    }
  }

  // Incorportate the font size change accessibility functionality
  void _updateAdjustedFontSize() {
    adjustedFontSize = _defaultFontSize * _textScaleFactor;
    adjustedHeadingFontSize = _defaultHeadingFontSize * _textScaleFactor;
    adjustedOrderInfoFontSize = _defaultOrderInfoFontSize * _textScaleFactor;
  }

  // Use the Google Maps Geocoding API to convert pickup coordinates to an address
  Future<String> getAddressFromLatLng(LatLng position) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['results'] != null &&
          jsonResponse['results'].length > 0) {
        String address = jsonResponse['results'][0]['formatted_address'];
        return address;
      } else {
        return 'Location not found';
      }
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  // Method to upload the delivery photo to Firebase storage
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      String fileName =
          'post_${Uuid().v4()}.jpg'; // Unique file name for the image
      Reference storageRef =
          FirebaseStorage.instance.ref().child('delivered_post_images/$fileName');

      UploadTask uploadTask = storageRef.putFile(imageFile);
      await uploadTask;
      String downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // Method to enable users to click an image using their camera
  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  // Method to enable users to pick an image from their gallery
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: detailsBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: detailsBackgroundColor,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            FeatherIcons.x,
            size: _iconSize,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),

        // Show the "Message [donee]" button if the post has been reserved
        trailing: orderState != OrderState.notReserved
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text("Message ${reservedByName ?? 'Unknown User'}",
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: accentColor)),
                onPressed: () {
                  // Close the current screen
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => MessageScreen(
                            receiverID: reservedByUserId!
                            )),
                  );
                },
              )
            : null,
        border: null,
      ),
      child: SafeArea(
        child: Container(
          margin: EdgeInsets.all(16.0),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                 
                 // Heading Text
                  __buildHeadingTextField(text: _buildHeadingText()),
                  //_buildHeadingTextField(),
                  
                  SizedBox(height: 16.0),

                  //Only show the order info section if the order has been reserved.
                  if (orderState != OrderState.notReserved)
                    OrderInfoSection(
                      reservedByName: reservedByName,
                      reservedByLastName: reservedByLastName,
                      adjustedOrderInfoFontSize: adjustedOrderInfoFontSize,
                      rating: rating,
                      photo: photo,
                    ),

                  SizedBox(height: 10.0),

                  // Progress Bar
                  ProgressBar(
                    progress: _calculateProgress(),
                    labels: [
                      "Reserved",
                      "Confirmed",
                      "Delivering",
                      "Ready to Pick Up"
                    ],
                    color: accentColor,
                    isReserved: postStatus != 'not reserved',
                    currentState: orderState,
                  ),

                  // SizedBox(height: 25,),

                  // Map showing the pickup location for all order states except ready to pick up
                  Visibility(
                    visible: (orderState != OrderState.readyToPickUp && orderState != OrderState.completed),
                    child: _buildMap(context),
                  ),

                  // Text showing the written address of the pickup location for all order states except ready to pick up
                  if (orderState != OrderState.readyToPickUp && orderState != OrderState.completed)
                    FutureBuilder<String>(
                      future: getAddressFromLatLng(pickupLatLng),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CupertinoActivityIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return __buildTextField(
                              text: "Pickup from ${snapshot.data}");
                        }
                      },
                    ),

                  // Display the option to upload pictures if the state is ready to pick up
                  if (orderState == OrderState.readyToPickUp)
                    buildImageSection(context, _selectedImagePath),

                  // Display the delivery photo if the state is completed
                  if (orderState == OrderState.completed)
                   buildDeliveredImageSection(context)

                ],
              ),

              // Show the buttons if the order has been reserved
              if (orderState != OrderState.notReserved)
                _buildButtonAndCancelButtonRow(),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable widget to build the text fields
  Widget __buildHeadingTextField({
    required String text,
  }) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -1.0,
          fontSize: adjustedHeadingFontSize,
        ),
      ),
    );
  }

  // Method to build heading text based on order state
  String _buildHeadingText() {
    switch (orderState) {
      case OrderState.notReserved:
        return "Your order has not been reserved yet";
      case OrderState.reserved:
        return "Your order has been reserved by ${reservedByName ?? 'Unknown User'}";
      case OrderState.confirmed:
        return "Your order has been confirmed for ${reservedByName ?? 'Unknown User'}";
      case OrderState.delivering:
        return "Your order is out for delivery for ${reservedByName ?? 'Unknown User'}";
      case OrderState.readyToPickUp:
        return "Your order for ${reservedByName ?? 'Unknown User'} is ready to pick up";
      case OrderState.completed:
        return "Your order for ${reservedByName ?? 'Unknown User'} is completed";
      default:
        return "Your order has not been reserved yet";
    }
  }

  // Method to calculate progress for the progress bar based on order state
  double _calculateProgress() {
    switch (orderState) {
      case OrderState.reserved:
        return 0.25; // Progress for reserved state
      case OrderState.confirmed:
        return 0.5; // Progress for confirmed state
      case OrderState.delivering:
        return 0.75; // Progress for delivering state
      case OrderState.readyToPickUp:
      case OrderState.completed:
        return 1.0; // Progress for readyToPickUp state
      default:
        return 0.0; // Default progress
    }
  }

  Widget _buildMap(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: 100)), // Add a small delay
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CupertinoActivityIndicator(); // Show loading indicator
        } else {
          final LatLng? locationCoordinates = pickupLatLng;

          if (locationCoordinates != null) {
            return ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
                bottom: Radius.circular(15),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 250.0,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: locationCoordinates, // Set initial position to marker location
                    zoom: 12.0,
                  ),
                  markers: Set.from([
                    Marker(
                      markerId: MarkerId('pickupLocation'),
                      position: locationCoordinates,
                    ),
                  ]),
                  onMapCreated: (GoogleMapController controller) {
                    // Move camera to focus on marker
                    controller.moveCamera(
                      CameraUpdate.newLatLngZoom(
                        locationCoordinates, 
                        15.0, // Zoom level
                      ),
                    );
                  },
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  myLocationEnabled: false,
                  mapType: MapType.normal,
                  myLocationButtonEnabled: false,
                ),
              ),
            );
          } else {
            return Container(
              width: double.infinity,
              height: 250.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                color: CupertinoColors.systemGrey4,
              ),
              alignment: Alignment.center,
              child: Text('Map Placeholder'),
            );
          }
        }
      },
    );
  }

  Widget __buildTextField({
    required String text,
  }) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: adjustedFontSize - 2.0,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w500),
        ),
      );
  }

  // Widget to build the delivery photo section
  Widget buildImageSection(BuildContext context, String? imagePath) {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('post_details').doc(widget.postId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CupertinoActivityIndicator();
        } 
        else if (snapshot.hasData) {
          final data = snapshot.data?.data();
          if (data != null && data.containsKey('delivered_image')) {
            // Delivered image URL is available, an image has already been saved
            final deliveredImageURL = data['delivered_image'];
            
            // Display the image
            return Container(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.network(
                  deliveredImageURL,
                  fit: BoxFit.cover,
                  width: double.infinity
                ),
              ), 
            );
          } 
          else {
            // Delivered image URL not available
            // If there isn't any delivery photo already saved, display the option to select and save one
            return Column(
              children: [
                // Display the selected image 
                ImageDisplayBox(imagePath: imagePath),
                
                // Display the buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: _buildUploadPhotoSection(context)
                      ),
 
                      // Show the "Save" button if an image is selected
                      if (imagePath != null)
                        CupertinoButton(
                          onPressed: () async {
                            if (_selectedImagePath != null) {
                              // Upload the image to Firebase Storage
                              String? imageUrl =
                                  await _uploadImageToFirebase(File(_selectedImagePath!));
                              if (imageUrl != null) {
                                // Save the image URL to the firestore document
                                await FirebaseFirestore.instance
                                    .collection('post_details')
                                    .doc(widget.postId)
                                    .update({'delivered_image': imageUrl});
                              } else {
                                // Handle error
                              }
                            }
                          },
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }
        } 
        else if (snapshot.hasError) {
          // Error retrieving data
          return Container();
        } 
        else {
          // No data found
          return Container();
        }
      },
    );
  }

  // Widget to build the upload photo button
  Widget _buildUploadPhotoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PullDownButton(
        itemBuilder: (context) => [
          PullDownMenuItem(
            title: 'From Gallery',
            icon: CupertinoIcons.photo,
            onTap: () {
              _pickImageFromGallery();
            },
          ),
          PullDownMenuItem(
              title: 'From Camera',
              icon: CupertinoIcons.camera,
              onTap: () {
                _pickImageFromCamera();
              }),
        ],
        buttonBuilder: (context, showMenu) => Expanded(
          child: CupertinoButton(
            onPressed: showMenu,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              decoration: BoxDecoration(
                color: accentColor.resolveFrom(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 28,
                    color:
                      // if current mode is darkmode, use lighten, else use darken
                      MediaQuery.of(context).platformBrightness ==
                              Brightness.light
                          ? darken(accentColor.resolveFrom(context), 0.3)
                          : lighten(accentColor.resolveFrom(context), 0.3)
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Upload a delivery photo',
                    style: TextStyle(
                      color: MediaQuery.of(context).platformBrightness ==
                              Brightness.light
                          ? darken(accentColor.resolveFrom(context), 0.3)
                          : lighten(accentColor.resolveFrom(context), 0.3),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Method to build the delivered image section for the completed order state
  Widget buildDeliveredImageSection(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection('post_details').doc(widget.postId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CupertinoActivityIndicator();
        } else if (snapshot.hasData) {
          final data = snapshot.data?.data();
          if (data != null && data.containsKey('delivered_image')) {
            // Delivered image URL is available
            final deliveredImageURL = data['delivered_image'];
            return Container(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.network(
                  deliveredImageURL,
                  fit: BoxFit.cover,
                  width: double.infinity
                ),
              ), 
            );

          } else {
            // Delivered image URL not available, display alternative UI
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0x01000000),
                    blurRadius: 20,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 17.0),
              height: 200,
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No delivery photo was uploaded',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context)
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else if (snapshot.hasError) {
          // Error retrieving data
          return Container(
          );
        } else {
          // No data found
          return Container(
          );
        }
      },
    );
  }

  BoxDecoration _buttonBoxDecoration() {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: 20,
          offset: Offset(0, 0),
        ),
      ],
    );
  }

  TextStyle _buttonTextStyle() {
    return TextStyle(
      fontSize: adjustedFontSize,
      color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
    );
  }

  Widget _buildButton() {   
    if (orderState == OrderState.readyToPickUp) {
      return _buildCancelButton();
    } 

    else if (orderState == OrderState.completed){
      // Display the leave a review button
      return _buildCustomButton(
        onPressed: () {
          _navigateToRatingScreen(context);
        }, 
        icon: FeatherIcons.edit, 
        buttonText: "Leave a review", 
        iconSize: 21
      );
    }

    else {
      return _buildStatusUpdateButton();
    }
  }

  Widget _buildCustomButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String buttonText,
    required double iconSize,
  }) {
    return Container(
      decoration: _buttonBoxDecoration(),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(100.0),
        color: CupertinoColors.tertiarySystemBackground,
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: icon == FeatherIcons.x 
                ? CupertinoColors.systemRed 
                : CupertinoDynamicColor.resolve(CupertinoColors.label, context),
              size: iconSize,
            ),
            SizedBox(width: 8),
            Text(
              buttonText,
              style: _buttonTextStyle(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRatingScreen(BuildContext context) {
    Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => DoneeRatingPage(
            postId: widget.postId,
            receiverID: reservedByUserId!,
          ),
        ),
      );
  }
  
  Widget _buildStatusUpdateButton() {
    String buttonText = _buildButtonText();
    return Container(
      decoration: _buttonBoxDecoration(),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        color: CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(100.0),
        onPressed: () {
          setState(() {
            _handlePostStatus();
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FeatherIcons.check,
              color: CupertinoColors.systemGreen,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              buttonText,
              style: _buttonTextStyle(),
            ),
          ],
        ),
      ),
    );
  }

  String _buildButtonText() {
    switch (orderState) {
      case OrderState.reserved:
        return "Confirm";
      case OrderState.confirmed:
        return "Delivering";
      case OrderState.delivering:
        return "Ready to Pick Up";
      default:
        return "Confirm";
    }
  }

  void _handlePostStatus() async {
    try {
      String newStatus;
      switch (orderState) {
        case OrderState.reserved:
          newStatus = 'confirmed'; // Update post_status to 'confirmed'
          orderState = OrderState.confirmed;
          break;
        case OrderState.confirmed:
          newStatus = 'delivering'; // Update post_status to 'delivering'
          orderState = OrderState.delivering;
          break;
        case OrderState.delivering:
          newStatus = 'readyToPickUp'; // Update post_status to 'readyToPickUp'
          orderState = OrderState.readyToPickUp;
          break;
        case OrderState.readyToPickUp:
          newStatus = 'confirmed'; // Update post_status back to 'confirmed'
          orderState = OrderState.confirmed;
          break;
        default:
          newStatus = 'pending';
          orderState = OrderState.notReserved;
      }

      // Update the post_status field in Firestore
      await FirebaseFirestore.instance
          .collection('post_details')
          .doc(widget.postId)
          .update({'post_status': newStatus});

      setState(() {});
    } catch (error) {
      print('Error updating post status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update post status. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCancelButton(){
    return _buildCustomButton(
      onPressed: _handleCancelOrder,
      icon: FeatherIcons.x,
      buttonText: "Cancel",
      iconSize: 23
    );
  }

  void _handleCancelOrder() async {
    // Show a confirmation dialog
    bool confirmCancel = await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Cancel Order"),
          content: Text("Are you sure you want to cancel this order?"),
          actions: [
            CupertinoDialogAction(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(
                    context, false); // Return false to indicate cancel
              },
            ),
            CupertinoDialogAction(
              child: Text("Confirm"),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context, true); // Return true to indicate confirm
              },
            ),
          ],
        );
      },
    );

    // If the user confirms the cancelation, proceed with canceling the order
    if (confirmCancel == true) {
      try {
        // Get the user document
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance
                .collection('user')
                .doc(reservedByUserId)
                .get();

        // Check if data exists
        if (userSnapshot.exists) {
          // Get the current reserved posts of the user
          List<String> reservedPosts =
              List<String>.from(userSnapshot.data()?['reserved_posts'] ?? []);

          // Remove the postId of the canceled order
          reservedPosts.remove(widget.postId);

          // Update the user document with the updated reserved_posts list
          await FirebaseFirestore.instance
              .collection('user')
              .doc(reservedByUserId)
              .update({'reserved_posts': reservedPosts});
        }

        // Update the reserved_by and post_status fields in the post_details document
        await FirebaseFirestore.instance
            .collection('post_details')
            .doc(widget.postId)
            .update({
          'reserved_by': FieldValue.delete(),
          'post_status': "not reserved"
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (error) {
        print('Error cancelling order: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildButtonAndCancelButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildButton(),
        ),
        SizedBox(width: 8), // Add some space between the buttons
        if (orderState != OrderState.readyToPickUp && orderState != OrderState.completed)
          Expanded(
            child: _buildCancelButton(),
          ),
      ],
    );
  }
}
