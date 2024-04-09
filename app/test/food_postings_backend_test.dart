import 'package:flutter_test/flutter_test.dart';
import 'mock_firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    setupFirebaseAnalyticsMocks();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  });

  group('Posting page tests', () {
    test('reading added doc correctly', () async {
      final postFirestoreService = MockFirestoreService();
      postFirestoreService.simulateSuccess = true;
      await postFirestoreService.addDocument(
        collectionName: 'mockCollection',
        filename: 'mockFilename',
        fieldNames: ['testField'],
        fieldValues: ['testValue'],
      );

      expect(postFirestoreService.simulateSuccess, isTrue);

      final addedData = await postFirestoreService.readDocument(
        collectionName: 'mockCollection',
        docName: 'mockFilename',
      );
      expect(addedData?['testField'], 'testValue');
    });

    test('reading an added doc incorrectly', () async {
      final postFirestoreService = MockFirestoreService();
      postFirestoreService.simulateSuccess = false;
      expectLater(
        () => postFirestoreService.addDocument(
          collectionName: 'mockCollection',
          filename: 'mockFilename',
          fieldNames: ['testField'],
          fieldValues: ['testValue'],
        ),
        throwsA(isInstanceOf<String>()),
      );

      expect(postFirestoreService.simulateSuccess, isFalse);
      final addedDataAfterFailure = await postFirestoreService.readDocument(
        collectionName: 'mockCollection',
        docName: 'mockFilename',
      );
      expect(addedDataAfterFailure, isNull);
    });
  });
}
