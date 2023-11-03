import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    UserCredential userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailController.text,
                      password: passwordController.text,
                    );

                    // User registration successful
                    print('User registered: ${userCredential.user?.uid}');
                  } catch (e) {
                    // Handle registration errors
                    print('Registration failed: $e');
                  }
                },
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
