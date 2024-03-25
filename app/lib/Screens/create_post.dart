import 'dart:convert';
import 'dart:io';

import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Components/maps_marker_widget.dart';
import 'package:FoodHood/Components/upload_image_tile.dart';
import 'package:FoodHood/Models/CreatePostViewModel.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pull_down_button/pull_down_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

enum SectionType { date, time }

class _CreatePostPageState extends State<CreatePostScreen>
    with WidgetsBindingObserver {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController pickupInstrController = TextEditingController();

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTime selectedTime = DateTime.now().add(const Duration(hours: 1));
  List<String> allergensList = [], categoriesList = [];
  List<String> selectedAllergens = [], selectedCategories = [];
  LatLng? selectedLocation;
  final Map<String, String> _selectedImagesWithAltText = {};
  CreatePostViewModel viewModel = CreatePostViewModel();
  final double _defaultFontSize = 16.0;
  double _textScaleFactor = 1.0;
  double adjustedFontSize = 16.0;
  LatLng? initialLocation;
  GoogleMapController? mapController;
  String instructionText = 'Move the map to select a location';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        backgroundColor: groupedBackgroundColor,
        navigationBar: _buildNavigationBar(context),
        child: SafeArea(
            child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
          ),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: CustomScrollView(
              slivers: <Widget>[
                const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                buildImageSection(
                    context, _selectedImagesWithAltText.keys.toList()),
                _buildPhotoSection(context),
                const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                buildTextField('Title'),
                buildTextInputField(
                  context,
                  titleController,
                  'What\'s cooking?',
                  capitalize: true,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                buildTextField('Description'),
                buildTextInputField(
                  context,
                  descController,
                  'Is there anything special about your dish?',
                  height: 160.0,
                  capitalize: true,
                ),
                buildDateTimeSection(
                  context: context,
                  sectionType: SectionType.date,
                  selectedDateTime: selectedDate,
                  adjustedFontSize: adjustedFontSize,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                buildTextField('Allergens'),
                buildCupertinoChipSelection(
                  allergensList,
                  selectedAllergens,
                ),
                buildTextField('Category'),
                buildCupertinoChipSelection(
                  categoriesList,
                  selectedCategories,
                ),
                buildTextField('Pickup Location'),
                buildMapSection(),
                buildInstructionText(),
                buildDateTimeSection(
                  context: context,
                  sectionType: SectionType.time,
                  selectedDateTime: selectedTime,
                  adjustedFontSize: adjustedFontSize,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10.0)),
                buildTextInputField(
                  context,
                  pickupInstrController,
                  'Provide pickup instructions here so they can find you',
                  height: 120.0,
                ),
              ],
            ),
          ),
        )));
  }

  SliverToBoxAdapter buildCupertinoChipSelection(
    List<String> itemList,
    List<String> selectedItems,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: DottedBorder(
          borderType: BorderType.RRect, // Rounded rectangle border
          radius: const Radius.circular(12), // Border corner radius
          padding: const EdgeInsets.all(10), // Padding inside the border
          dashPattern: const [6, 4], // Pattern of dashes and gaps
          strokeWidth: 2, // Width of the dashes
          color: CupertinoColors.systemGrey
              .withOpacity(0.4), // Color of the dashes
          child: Wrap(
            spacing: 8.0, // gap between adjacent chips
            runSpacing: 4.0, // gap between lines
            children: itemList.map((item) {
              final isSelected = selectedItems.contains(item);
              return CupertinoButton(
                  onPressed: () {
                    setState(() {
                      if (isSelected) {
                        selectedItems.remove(item);
                      } else {
                        selectedItems.add(item);
                      }
                    });
                  },
                  padding: EdgeInsets.zero,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.resolveFrom(context).withOpacity(0.3)
                            : CupertinoColors.tertiarySystemBackground
                                .resolveFrom(context),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item, // Capitalize the first letter of each word
                            style: TextStyle(
                              color: isSelected
                                  ? MediaQuery.of(context).platformBrightness ==
                                          Brightness.light
                                      ? darken(
                                          accentColor.resolveFrom(context), 0.3)
                                      : lighten(
                                          accentColor.resolveFrom(context), 0.3)
                                  : CupertinoColors.label.resolveFrom(context),
                              fontSize: adjustedFontSize - 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )));
            }).toList(),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter buildDateSection(
      DateTime selectedDate, Function(BuildContext) showPicker) {
    String formattedDate =
        DateFormat('yyyy-MM-dd').format(selectedDate); // Format the date
    return SliverToBoxAdapter(
      child: CupertinoButton(
        onPressed: () => showPicker(context),
        child: Text(formattedDate),
      ),
    );
  }

  SliverToBoxAdapter buildDateTimeSection({
    required BuildContext context,
    required SectionType sectionType,
    required DateTime selectedDateTime,
    required double
        adjustedFontSize, // Ensure this variable is defined and passed
  }) {
    String title =
        sectionType == SectionType.date ? 'Expiration Date' : 'Pickup Time';
    String formattedDateTime = sectionType == SectionType.date
        ? DateFormat('yyyy-MM-dd').format(selectedDateTime)
        : DateFormat('h:mm a').format(selectedDateTime);

    onTapHandler() => showPickerModal(
          context,
          isDatePicker: sectionType == SectionType.date,
        );

    EdgeInsets padding = sectionType == SectionType.date
        ? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0)
        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0);

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 16.0, bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: adjustedFontSize, fontWeight: FontWeight.w500)),
            GestureDetector(
              onTap: onTapHandler,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemBackground
                      .resolveFrom(context),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  formattedDateTime,
                  style: TextStyle(
                    fontSize: adjustedFontSize,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImageSection(BuildContext context, List<String> imagePaths) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: imagePaths.isEmpty
            ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1, // Maintains square aspect ratio for images
          ),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            String imagePath = imagePaths[index];
            return ImageTile(
              imagePath: imagePath,
              onRemove: () {
                setState(() {
                  imagePaths.removeAt(index);
                  _selectedImagesWithAltText.remove(
                      imagePath); // Remove alt text entry for this image
                });
              },
              onAltTextChanged: (altText) {
                setState(() {
                  _selectedImagesWithAltText[imagePath] =
                      altText; // Update alt text for this image
                });
              },
              hasAltText: checkIfImageHasAltText(
                  imagePath), // Implement this method to check if an image has alt text
              altText: getAltTextForImage(imagePath),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter buildInstructionText() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          instructionText,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: adjustedFontSize - 4,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget buildMapSection() {
    return SliverToBoxAdapter(
      child: Container(
        height: 250.0,
        margin: const EdgeInsets.all(16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: GoogleMapWidget(
            initialLocation: initialLocation, // Make sure this is not null
            onLocationSelected:
                _onLocationSelected, // Here you listen for changes
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter buildTextField(String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 10.0),
        child: Text(
          text,
          style: TextStyle(
              fontSize: adjustedFontSize, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  SliverToBoxAdapter buildTextInputField(BuildContext context,
      TextEditingController controller, String placeholder,
      {double? height, bool capitalize = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 5.0, right: 16.0),
        child: SizedBox(
          height:
              height, // This allows the container to auto-size if height is null.
          child: CupertinoTextField(
            controller: controller,
            maxLines: height != null ? null : 1,
            textAlignVertical: height != null ? TextAlignVertical.top : null,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
            placeholder: placeholder,
            style: TextStyle(
              color:
                  CupertinoDynamicColor.resolve(CupertinoColors.label, context),
              fontSize:
                  16, // AdjustedFontSize is not defined in the provided code snippet. Replace 16 with adjustedFontSize or define it.
              fontWeight: FontWeight.w500,
            ),
            placeholderStyle: TextStyle(
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.placeholderText, context),
              fontSize: 16, // Same as above regarding adjustedFontSize.
              fontWeight: FontWeight.w500,
            ),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.tertiarySystemBackground, context),
              borderRadius: BorderRadius.circular(16),
            ),
            textCapitalization: capitalize
                ? TextCapitalization.sentences
                : TextCapitalization.none,
          ),
        ),
      ),
    );
  }

  bool checkIfImageHasAltText(String imagePath) {
    return _selectedImagesWithAltText[imagePath] != null &&
        _selectedImagesWithAltText[imagePath]!.isNotEmpty;
  }

  @override
  void dispose() {
    super.dispose();
    viewModel.disposeControllers();
  }

  Future<String> getAddressFromLatLng(LatLng position) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyC9ZK3lbbGSIpFOI_dl-JON4zrBKjMlw2A');
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

  String getAltTextForImage(String imagePath) {
    return _selectedImagesWithAltText[imagePath] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _textScaleFactor =
        Provider.of<TextScaleProvider>(context, listen: false).textScaleFactor;
    _updateAdjustedFontSize();
    setInitialLocation();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      allergensList =
          await viewModel.fetchDocumentData('Allergens', 'allergens');
      categoriesList =
          await viewModel.fetchDocumentData('Categories', 'categories');
      setState(
          () {}); // Call setState to update the UI after the data is fetched
    } catch (e) {
      // Handle any errors here
    }
  }

  Future<void> setInitialLocation() async {
    Position position = await viewModel.determinePosition();
    setState(
        () => initialLocation = LatLng(position.latitude, position.longitude));
  }

  void showLoadingDialog(BuildContext context,
      {String loadingMessage = 'Loading'}) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(),
                const SizedBox(height: 24),
                Text(
                  loadingMessage, // Customizable message
                  style: TextStyle(
                    fontSize: adjustedFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showPickerModal(BuildContext context, {required bool isDatePicker}) {
    DateTime tempSelected = isDatePicker ? selectedDate : selectedTime;
    CupertinoDatePickerMode mode = isDatePicker
        ? CupertinoDatePickerMode.date
        : CupertinoDatePickerMode.time;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.tertiarySystemBackground, context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('Cancel',
                        style: TextStyle(
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel, context))),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: Text('Done',
                        style: TextStyle(
                            color: CupertinoDynamicColor.resolve(
                                CupertinoColors.label, context))),
                    onPressed: () {
                      if (isDatePicker) {
                        setState(() => selectedDate = tempSelected);
                      } else {
                        setState(() => selectedTime = tempSelected);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: mode,
                  initialDateTime: isDatePicker ? selectedDate : selectedTime,
                  onDateTimeChanged: (DateTime newValue) {
                    tempSelected = newValue;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  CupertinoNavigationBar _buildNavigationBar(BuildContext context) {
    return CupertinoNavigationBar(
      transitionBetweenRoutes: false,
      backgroundColor: groupedBackgroundColor,
      middle: Text('New Post',
          style:
              _textStyle(CupertinoColors.label.resolveFrom(context)).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          )),
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cancel',
                style: _textStyle(CupertinoColors.label.resolveFrom(context))
                    .copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
      trailing: GestureDetector(
        onTap: () => _savePost(),
        child: const Text('Post'),
      ),
      border: null,
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return SliverToBoxAdapter(
        child: Padding(
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
        buttonBuilder: (context, showMenu) => CupertinoButton(
          onPressed: showMenu,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            decoration: BoxDecoration(
              color: blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_rounded,
                    size: 28,
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.light
                        ? darken(blue.resolveFrom(context), 0.4)
                        : lighten(blue.resolveFrom(context), 0.4)),
                const SizedBox(width: 10),
                Text(
                  'Select Photos',
                  style: TextStyle(
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.light
                        ? darken(blue.resolveFrom(context), 0.4)
                        : lighten(blue.resolveFrom(context), 0.4),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  void _onLocationSelected(LatLng location) async {
    String address = await getAddressFromLatLng(location);
    setState(() {
      selectedLocation = location;
      instructionText = address;
    });
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImagesWithAltText[image.path] = "";
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    setState(() {
      for (var image in images) {
        _selectedImagesWithAltText[image.path] = "";
      }
    });
  }

  Future<void> _savePost() async {
    // Only checking if title, description, and pickup instructions are empty
    bool isAnyFieldEmpty = titleController.text.isEmpty ||
        descController.text.isEmpty ||
        pickupInstrController.text.isEmpty;

    // Checking if no images are selected
    bool isNoImageSelected = _selectedImagesWithAltText.isEmpty;

    // Check if a location has been picked
    bool isLocationNotPicked = selectedLocation == null;

    // Combine all error messages into one to display in the dialog
    List<String> errorMessages = [];
    if (isAnyFieldEmpty) {
      errorMessages.add("fill in all fields");
    }
    if (isNoImageSelected) {
      errorMessages.add("upload at least one image");
    }
    if (isLocationNotPicked) {
      errorMessages.add("pick a location on the map");
    }

    if (errorMessages.isNotEmpty) {
      String errorMessage =
          "Please ${errorMessages.join(", ")} before posting.";
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Oops! Something's missing"),
          content: Text(errorMessage),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showLoadingDialog(context);

    try {
      List<File> imageFiles =
          _selectedImagesWithAltText.keys.map((path) => File(path)).toList();

      Map<String, String> imageUrlsWithPaths =
          await viewModel.uploadImagesToFirebase(imageFiles);

      // The alt text is no longer mandatory, so provide a default empty string if it's missing
      Map<String, String> imageUrlsWithAltText = imageUrlsWithPaths.map(
          (url, path) => MapEntry(url, _selectedImagesWithAltText[path] ?? ""));

      bool success = await viewModel.savePost(
        title: titleController.text,
        description: descController.text,
        allergens: selectedAllergens,
        categories: selectedCategories,
        expirationDate: selectedDate,
        pickupInstructions: pickupInstrController.text,
        pickupTime: selectedTime,
        postLocation: selectedLocation!,
        imageUrlsWithAltText: imageUrlsWithAltText,
      );
      if (success) {
        if (mounted) {
          Navigator.pop(context); // Close loading indicator
        }
        Navigator.pop(context); // Close the create post screen
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text("Post published",
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: -0.2,
                  fontWeight: FontWeight.w600,
                )),
            content: const Text("Your post has been posted successfully."),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Error"),
          content: const Text("An error occurred while saving the post."),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  TextStyle _textStyle(Color color) {
    return TextStyle(
        color: color, fontSize: adjustedFontSize, fontWeight: FontWeight.w600);
  }

  void _updateAdjustedFontSize() {
    adjustedFontSize = _defaultFontSize * _textScaleFactor;
  }
}
