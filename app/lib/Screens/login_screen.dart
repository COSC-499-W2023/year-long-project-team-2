import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:FoodHood/Components/colors.dart';
import 'package:FoodHood/Screens/reset_pwd_screen.dart';
import '../Components/components.dart';

class LogInScreen extends StatefulWidget {
  @override
  _LogInScreenState createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _emailErrorText;
  String? _passwordErrorText;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: groupedBackgroundColor,
      navigationBar: buildBackNavigationBar(context),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildLoginForm(context),
                buildBottomGroup(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildText('Log in', 34, FontWeight.w600),
        const SizedBox(height: 50),
        buildCupertinoTextField(
          'Email Address',
          emailController,
          context,
          [AutofillHints.email],
          errorText: _emailErrorText,
        ),
        const SizedBox(height: 16),
        PasswordCupertinoTextField(
            placeholder: 'Password',
            controller: passwordController,
            context: context,
            autofillHints: [AutofillHints.password],
            errorText: _passwordErrorText),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (context) => ForgotPasswordScreen())),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: const Color(0xFF337586),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        buildContinueButton(
            context, 'Continue', accentColor, CupertinoColors.white),
      ],
    );
  }

  Widget buildContinueButton(BuildContext context, String text,
      Color backgroundColor, Color textColor) {
    return CupertinoButton(
      onPressed: _validateAndLogin,
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

  void _validateAndLogin() async {
    // Reset error messages
    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    bool isFormValid = true;

    // Check if the email field is empty
    if (emailController.text.isEmpty) {
      _emailErrorText = "Email is required.";
      isFormValid = false;
    }
    // Check if the email format is valid
    else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailController.text)) {
      _emailErrorText = "Please enter a valid email address.";
      isFormValid = false;
    }

    // Check if the password field is empty
    if (passwordController.text.isEmpty) {
      _passwordErrorText = "Password is required.";
      isFormValid = false;
    }

    // Update the UI to display error messages
    setState(() {});

    // If form is valid, proceed to log in
    if (isFormValid) {
      _login();
    }
  }

  Future<void> _login() async {
    try {
      showLoadingDialog(context);
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.of(context).pop();
      Navigator.of(context).pushNamedAndRemoveUntil('/nav', (route) => false,
          arguments: {'selectedIndex': 0});
    } catch (e) {
      Navigator.of(context).pop();

      setState(() {
        _emailErrorText = "Your email or password is incorrect.";
      });
    }
  }

  Widget buildBottomGroup(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        buildCenteredText('or', 12, FontWeight.w600),
        const SizedBox(height: 12),
        buildGoogleSignInButton(context),
        const SizedBox(height: 16),
        buildAppleSignInButton(context),
        const SizedBox(height: 26),
        buildSignUpText(
            context, "Don't have an account? ", 'Sign up', '/signup'),
      ],
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
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/nav', (route) => false,
                arguments: {'selectedIndex': 0});
          } catch (e) {
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
            Navigator.of(context).pushNamedAndRemoveUntil(
                '/nav', (route) => false,
                arguments: {'selectedIndex': 0});
          } catch (e) {
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
            child: Column(
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

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    final AuthorizationCredentialAppleID appleIdCredential =
        await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    //  if (appleIdCredential.fullName != null) {
    // final userFullName =
    // '${appleIdCredential.fullName.givenName} ${appleIdCredential.fullName.familyName}';
    // return userFullName;
    //  } else {
    // If the user did not provide a full name, return an empty string or handle it accordingly
    //  }

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleIdCredential.identityToken,
      accessToken: appleIdCredential.authorizationCode,
    );

    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }
}
