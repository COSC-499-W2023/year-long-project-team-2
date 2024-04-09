import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; 

  AuthService();

  // Stream to listen to auth state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Function to sign up a new user and send an email verification.
  Future<void> signUp({required String email, required String password}) async {
    UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    User? user = userCredential.user;
    // Directly check if the user's email is verified to send a verification email.
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Function to get the current user's ID.
  Future<String?> getUserId() async {
    User? user = _firebaseAuth.currentUser;
    return user?.uid; // Directly return the user ID or null.
  }

  // Function to send a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
