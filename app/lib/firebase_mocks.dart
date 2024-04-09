import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseApp extends Mock implements FirebaseApp {}

Future<FirebaseApp> setupFirebaseMocks() async {
  // Create a mock FirebaseApp
  final firebaseApp = MockFirebaseApp();
  // Mock the Firebase.initializeApp to return the mock FirebaseApp
  when(Firebase.initializeApp()).thenAnswer((_) async => firebaseApp);
  // Call the mocked Firebase.initializeApp
  return Firebase.initializeApp();
}