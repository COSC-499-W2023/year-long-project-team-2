// main.dart
// entry point of the app

import 'package:FoodHood/Screens/login_screen.dart';
import 'package:FoodHood/Screens/registration_screen.dart';
import 'package:FoodHood/Screens/welcome_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:FoodHood/Screens/home_screen.dart';
import 'package:FoodHood/auth_wrapper.dart';

void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Run the app
  runApp(FoodHoodApp());
}

class FoodHoodApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: AuthWrapper(), // Use AuthWrapper as the root widget
      debugShowCheckedModeBanner: false, // Hide the debug banner in Preview mode
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return CupertinoPageRoute(
              builder: (context) => WelcomeScreen(), // Root route
            );
          case '/signup':
            return CupertinoPageRoute(
              builder: (context) => RegistrationScreen(), // Signup route
            );
          case '/signin':
            return CupertinoPageRoute(
              builder: (context) => LogInScreen(), // Signin route
            );
          case '/home':
            return CupertinoPageRoute(
              builder: (context) => HomeScreen(), // Home route
            );
          default:
            return null;
        }
      },
    );
  }
}



