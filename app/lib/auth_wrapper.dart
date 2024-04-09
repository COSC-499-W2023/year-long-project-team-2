import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:FoodHood/Screens/welcome_screen.dart';
import 'package:FoodHood/Screens/navigation_screen.dart';

class AuthWrapper extends StatelessWidget {
  final PendingDynamicLinkData? initialLink;

  AuthWrapper({this.initialLink});

  @override
  Widget build(BuildContext context) {
    // Handle initial dynamic link if it exists
    if (initialLink != null) {
      final Uri deepLink = initialLink!.link;
      
      // Example dynamic link handling logic
      // You might need to adjust this logic to fit your app's navigation structure
      // For instance, navigate to a specific screen based on the deep link path
      Future.microtask(() => Navigator.pushNamed(context, deepLink.path));
    }

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
            return NavigationScreen(
                selectedIndex: 0,
                onItemTapped: (int index) {
                  // Handle navigation tab changes here if necessary
                });
          }
        }
        return CupertinoPageScaffold(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        );
      },
    );
  }
}
