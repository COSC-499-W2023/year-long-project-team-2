import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'signup.dart'; // Import the signup screen
import 'home.dart'; // Import the home screen
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthWrapper(), // Use AuthWrapper as the root widget
      routes: {
        '/signup': (context) => SignupScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user == null) {
            // User is not logged in, display the LoginScreen
            return LoginScreen();
          } else {
            // User is logged in, display the HomeScreen
            return HomeScreen();
          }
        }
        // By default, show a loading screen while checking the user's authentication state
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Implement login functionality
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Implement forgot password functionality
              },
              child: Text('Forgot Password?'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup'); // Navigate to the signup screen
              },
              child: Text('Create an Account'),
            ),
          ],
        ),
      ),
    );
  }
}
