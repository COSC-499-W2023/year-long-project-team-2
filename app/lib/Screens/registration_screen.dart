// registration_screen.dart
// a screen that allows users to register for an account

import 'package:FoodHood/Components/colors.dart';
import 'package:flutter/cupertino.dart';
import '../Components/components.dart';
import '../Services/AuthService.dart';
import '../Services/FirebaseService.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegistrationScreen extends StatefulWidget {
  final AuthService auth;

  RegistrationScreen({Key? key, required this.auth}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confPasswordController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedProvince = '';
  String _selectedCity = '';

  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confPasswordErrorText;
  String? _firstNameErrorText;
  String? _lastNameErrorText;

  List<String> provinces = []; // Updated to be fetched from Firestore
  Map<String, List<String>> cities = {}; // Updated to be fetched from Firestore

  @override
  void initState() {
    super.initState();
    fetchProvincesAndCities();

    // Set default values here
    if (provinces.isNotEmpty) {
      _selectedProvince = provinces.first;
      if (cities.containsKey(_selectedProvince) &&
          cities[_selectedProvince]!.isNotEmpty) {
        _selectedCity = cities[_selectedProvince]!.first;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      navigationBar: buildBackNavigationBar(context),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: _buildSignupForm(context),
            ),
          ),
        ),
      ),
    );
  }

  // Sign up form
  Column _buildSignupForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildText(
            'Create an account', 34, FontWeight.w600), // Create an account text
        SizedBox(height: 30),
        buildTwoFieldsRow(
          'First Name',
          _firstNameController,
          'Last Name',
          _lastNameController,
        ),
        const SizedBox(height: 16),
        buildCupertinoTextField(
            'Email Address', _emailController, context, [AutofillHints.email],
            errorText: _emailErrorText),
        const SizedBox(height: 16),
        PasswordCupertinoTextField(
            placeholder: 'Password',
            controller: _passwordController,
            context: context,
            showHint: true,
            autofillHints: [AutofillHints.password],
            errorText: _passwordErrorText),
        const SizedBox(height: 16),
        PasswordCupertinoTextField(
            placeholder: 'Confirm Password',
            controller: _confPasswordController,
            context: context,
            showHint: true,
            autofillHints: [AutofillHints.password],
            errorText: _confPasswordErrorText),
        const SizedBox(height: 16),
        buildTwoPickerFieldsRow(
          'Province',
          _selectedProvince,
          provinces,
          (value) {
            setState(() {
              _selectedProvince = value;
              _selectedCity = cities[_selectedProvince]?.first ?? '';
            });
          },
          'City',
          _selectedCity,
          cities[_selectedProvince] ?? [],
          (value) {
            setState(() {
              _selectedCity = value;
            });
          },
        ),
        const SizedBox(height: 36),
        _buildContinueButton(
            context, 'Register', accentColor, CupertinoColors.white),
        const SizedBox(height: 12),
        buildCenteredText('or', 12, FontWeight.w600), // Or text
        const SizedBox(height: 12),
        buildGoogleSignInButton(context), // Google sign in button
        const SizedBox(height: 16),
        buildAppleSignInButton(context), // Apple sign in button
        const SizedBox(height: 24),
        buildSignUpText(context, "Already have an account? ", 'Log in',
            '/signin'), // Sign up text
      ],
    );
  }

  Row buildTwoFieldsRow(
    String placeholder1,
    TextEditingController controller1,
    String placeholder2,
    TextEditingController controller2,
  ) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: buildCupertinoTextField(
                placeholder1, controller1, context, [],
                errorText: _firstNameErrorText),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: buildCupertinoTextField(
                placeholder2, controller2, context, [],
                errorText: _lastNameErrorText),
          ),
        ),
      ],
    );
  }

  Row buildTwoPickerFieldsRow(
    String placeholder1,
    String currentValue1,
    List<String> options1,
    ValueChanged<String> onSelectedItemChanged1,
    String placeholder2,
    String currentValue2,
    List<String> options2,
    ValueChanged<String> onSelectedItemChanged2,
  ) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: buildPickerField(context, placeholder1, currentValue1,
                options1, onSelectedItemChanged1),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: buildPickerField(context, placeholder2, currentValue2,
                options2, onSelectedItemChanged2),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context, String text,
      Color backgroundColor, Color textColor) {
    return CupertinoButton(
      onPressed:
          _validateAndSubmit, // Pass the function reference directly without braces
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _validateAndSubmit() async {
    bool isFormValid = true;

    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
      _confPasswordErrorText = null;
      _firstNameErrorText = null;
      _lastNameErrorText = null;
    });

    if (_firstNameController.text.isEmpty) {
      _firstNameErrorText = "First name is required.";
      isFormValid = false;
    }
    if (_lastNameController.text.isEmpty) {
      _lastNameErrorText = "Last name is required.";
      isFormValid = false;
    }
    if (_emailController.text.isEmpty) {
      _emailErrorText = "Email is required.";
      isFormValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      _emailErrorText = "Please enter a valid email address.";
      isFormValid = false;
    }

    if (_passwordController.text.isEmpty) {
      _passwordErrorText = "Password is required.";
      isFormValid = false;
    }
    if (_confPasswordController.text.isEmpty) {
      _confPasswordErrorText = "Please confirm your password.";
      isFormValid = false;
    }
    if (_passwordController.text != _confPasswordController.text) {
      _passwordErrorText = 'The passwords do not match.';
      _confPasswordErrorText = 'The passwords do not match.';
      isFormValid = false;
    }

//updated validation rules for password
    if (_passwordController.text.length < 8 ||
        !_passwordController.text.contains(RegExp(r'[a-z]')) ||
        !_passwordController.text.contains(RegExp(r'[A-Z]')) ||
        !_passwordController.text.contains(RegExp(r'[0-9]'))) {
      _passwordErrorText = "Password is weak.";
      isFormValid = false;
    }

    bool isValidForm = _formKey.currentState?.validate() ?? false;
    isFormValid = isFormValid && isValidForm;

    if (!isFormValid) {
      setState(() {});
      return;
    }

    await registerUser();
  }

  Future<void> registerUser() async {
    showLoadingDialog(context);

    try {
      await widget.auth.signUp(
          email: _emailController.text, password: _passwordController.text);
      // Registration successful, continue with further steps
      String? userID = await widget.auth.getUserId();
      if (userID != null) {
        await addDocumentToFirestore(userID);
        Navigator.of(context).pop(); // Close loading dialog
        navigateToHomeScreen(); // Navigate to home screen
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      handleFirebaseAuthException(
          e); // Handle FirebaseAuth exceptions including weak password
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      showGeneralErrorDialog(e.toString()); // Handle other exceptions
    }
  }

  void navigateToHomeScreen() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/nav', (route) => false, arguments: {
      'selectedIndex': 0,
    });
  }

  Future<void> addDocumentToFirestore(String userID) async {
    // Reference to Firestore
    String? userID = await widget.auth.getUserId();
    if (userID == null) {
      print("User ID is null");
      return;
    }
    try {
      await addDocument(
        collectionName: 'user',
        filename: userID,
        fieldNames: [
          'firstName',
          'lastName',
          'province',
          'city',
          'email',
          'itemsSold',
          'description',
          'posts',
          'avgRating',
          'ratings',
          'comments',
          'profileImagePath'
        ],
        fieldValues: [
          _firstNameController.text,
          _lastNameController.text,
          _selectedProvince, // Use the selected province
          _selectedCity, // Use the selected city
          _emailController.text,
          [],
          '',
          [],
          0.0,
          [0],
          [],
          ''
        ],
      );

      print("User document added successfully.");
    } catch (e) {
      print("Error adding user document: $e");
      throw e; // Rethrow the exception to be handled elsewhere
    }
  }

  void handleFirebaseAuthException(FirebaseAuthException e) {
    // Set state for specific error messages based on the exception code
    setState(() {
      if (e.code == 'email-already-in-use')
        _emailErrorText = 'This email address is already in use.';
      else if (e.code == 'invalid-email')
        _emailErrorText = 'Please enter a valid email address.';
      else if (e.code == 'weak-password')
        _passwordErrorText = 'The password is too weak.';
      else
        _emailErrorText = 'An unexpected error occurred.';
    });
  }

  void showGeneralErrorDialog(dynamic e) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text('Registration Failed'),
        content: Text('An unexpected error occurred: $e'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void fetchProvincesAndCities() async {
    try {
      // Use the readDocument function to get the location data
      Map<String, dynamic>? locationData = await readDocument(
        collectionName: 'location',
        docName: 'rLxaYnbNB4x6Rpvil1Oe',
      );

      if (locationData != null) {
        // Access the 'location' field in the fetched data
        Map<String, dynamic> data = locationData['location'];

        Map<String, List<String>> fetchedCities = {};

        data.forEach((province, citiesList) {
          if (citiesList is List) {
            // Sort cities alphabetically
            List<String> sortedCities = List<String>.from(citiesList);
            sortedCities.sort((a, b) => a.compareTo(b));
            fetchedCities[province] = sortedCities;
          }
        });

        // Sort provinces alphabetically
        List<String> sortedProvinces = fetchedCities.keys.toList()
          ..sort((a, b) => a.compareTo(b));

        if (sortedProvinces.isNotEmpty) {
          setState(() {
            provinces = sortedProvinces;
            cities = fetchedCities;

            _selectedProvince = provinces.first;
            _selectedCity = cities[_selectedProvince]?.first ?? '';
          });
        }
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  Widget buildPickerField(
      BuildContext context,
      String label,
      String currentValue,
      List<String> options,
      ValueChanged<String> onSelectedItemChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoButton(
          padding: EdgeInsets.all(16),
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.tertiarySystemBackground, context),
          borderRadius: BorderRadius.circular(12),
          onPressed: () => _showCupertinoPicker(
              context, options, currentValue, onSelectedItemChanged),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(currentValue,
                    style: TextStyle(
                      color: currentValue == label
                          ? CupertinoDynamicColor.resolve(
                              CupertinoColors.placeholderText, context)
                          : CupertinoDynamicColor.resolve(
                              CupertinoColors.label, context),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )), // Use systemGrey if it's a placeholder, otherwise black
              ),
              Icon(FeatherIcons.chevronDown,
                  size: 18,
                  color: CupertinoDynamicColor.resolve(
                      CupertinoColors.secondaryLabel, context)),
            ],
          ),
        ),
      ],
    );
  }

  void _showCupertinoPicker(BuildContext context, List<String> options,
      String? currentValue, ValueChanged<String>? onSelectedItemChanged) {
    int initialItem = 0;
    if (currentValue != null && options.contains(currentValue)) {
      initialItem = options.indexOf(currentValue);
    }

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 320,
        color: CupertinoColors.tertiarySystemBackground.resolveFrom(context),
        child: Column(
          children: [
            // Button Bar for Done and Cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: CupertinoDynamicColor.resolve(
                          CupertinoColors.label, context),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: CupertinoDynamicColor.resolve(
                          CupertinoColors.label, context),
                    ),
                  ),
                  onPressed: () {
                    if (onSelectedItemChanged != null) {
                      onSelectedItemChanged(options[initialItem]);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            // Picker
            Expanded(
              child: CupertinoPicker(
                itemExtent: 30,
                scrollController: FixedExtentScrollController(
                  initialItem: initialItem,
                ),
                children: options.map((e) => Text(e)).toList(),
                onSelectedItemChanged: (index) {
                  initialItem = index;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text, double fontSize, FontWeight fontWeight,
      double letterSpacing) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      ),
    );
  }

  Widget buildGoogleSignInButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemGrey2, context),
          width: 0.6,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CupertinoButton(
        onPressed: () async {
          try {
            await signInWithGoogle();
            // Navigate to home or desired screen
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/nav',
              (route) => false,
              arguments: {'selectedIndex': 0},
            );
          } catch (e) {
            // Handle exceptions like user cancellation or network issues
            print('Google Sign-In error: $e');
          }
        },
        color: CupertinoDynamicColor.resolve(
            CupertinoColors.tertiarySystemBackground, context),
        borderRadius: BorderRadius.circular(14),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/google.png', width: 20, height: 20),
            const SizedBox(width: 2),
            Text(
              'Sign in with Google',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.label, context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    String displayName = googleUser.displayName ?? '';
    List<String> names = displayName.split(' ');
    String firstName = names.first;
    String lastName = names.length > 1 ? names.last : '';

    // Create an account in your system using the fetched details
    await createAccount(userCredential, firstName, lastName);

    return userCredential;
  }

  Future<UserCredential> signInWithApple() async {
    final appleIdCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleIdCredential.identityToken,
      accessToken: appleIdCredential.authorizationCode,
    );

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);

    await createAccount(userCredential, appleIdCredential.givenName ?? '',
        appleIdCredential.familyName ?? '');

    print(userCredential.user?.displayName);
    print(userCredential.user?.email);

    return userCredential;
  }

  Future<void> createAccount(
      UserCredential userCredential, String firstName, String lastName) async {
    print("Attempting to create account..."); // Debugging print

    try {
      String? userID = userCredential.user?.uid;
      print("User ID: $userID"); // Debugging print

      if (userID != null) {
        // Add the user data to Firestore
        await addDocument(
          collectionName: 'user',
          filename: userID,
          fieldNames: [
            'firstName',
            'lastName',
            'province',
            'city',
            'email',
            'itemsSold',
            'description',
            'posts'
          ],
          fieldValues: [
            firstName,
            lastName,
            '',
            '',
            userCredential.user?.email ?? '',
            [],
            '',
            []
          ],
        );
        print("Account created for social sign-in"); // Success print
      } else {
        print("User ID is null"); // Debugging print for null userID
      }
    } catch (e) {
      print("Failed to create account for social sign-in: $e"); // Error print
    }
  }

  Widget buildAppleSignInButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: CupertinoColors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      child: CupertinoButton(
        onPressed: () async {
          try {
            await signInWithApple();
            // Navigate to home or desired screen
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/nav',
              (route) => false,
              arguments: {'selectedIndex': 0},
            );
          } catch (e) {
            // Handle exceptions
            print('Apple Sign-In error: $e');
          }
        },
        color: CupertinoColors.black,
        borderRadius: BorderRadius.circular(14),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/apple.png', width: 16, height: 16),
            const SizedBox(width: 8),
            Text(
              'Sign in with Apple',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show a loading dialog
  void showLoadingDialog(BuildContext context) {
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
            child:
                //indicator and the text below it
                Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 24),
                Text(
                  'Logging in',
                  style: TextStyle(
                    fontSize: 16,
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
}
