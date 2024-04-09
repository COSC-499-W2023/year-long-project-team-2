import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase libraries can be imported', () {
    expect(Firebase, isNotNull);
    expect(FirebaseAuth, isNotNull);
  });
}
