// auth_wrapper.dart 
// wrapper widget that determines whether to display the WelcomeScreen or the NavigationScreen

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:FoodHood/Screens/welcome_screen.dart';
import 'package:FoodHood/Screens/navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            // User is not logged in, display the WelcomeScreen
            return WelcomeScreen();
          } else {
            // User is logged in, display the NavigationScreen with the first tab selected
            return NavigationScreen(selectedIndex: 0, onItemTapped: (int index) {
              // Handle navigation tab changes here if necessary
            });
          }
        }
        
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
