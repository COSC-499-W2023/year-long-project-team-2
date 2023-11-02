import 'package:FoodHood/LogInScreen.dart';
import 'package:flutter/material.dart';
import 'package:FoodHood/RegistrationScreen.dart';
import 'package:FoodHood/WelcomeScreen.dart';
import 'package:flutter/cupertino.dart';


void main() {
  runApp(const FoodHoodApp());
}

class FoodHoodApp extends StatelessWidget {
  const FoodHoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/signup':
            return CupertinoPageRoute(
              builder: (context) => RegistrationScreen(),
            );
          case '/signin':
            return CupertinoPageRoute(
              builder: (context) => LogInScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}


