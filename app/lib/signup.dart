import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildTextFormField('Email', _emailController, false),
              buildTextFormField('Password', _passwordController, true),
              buildTextFormField(
                  'Confirm Password', _confirmPasswordController, true),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // Implement signup functionality
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

  TextFormField buildTextFormField(
      String label, TextEditingController controller, bool obscureText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) return '$label cannot be empty';
        return null;
      },
    );
  }
}
