import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart';
import 'mock_firestore_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseAnalyticsMocks();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  });

  group('Firestore Service Tests', () {
    MockFirestoreService? firestoreService;

    setUp(() {
      firestoreService = MockFirestoreService();
    });

    test('Read Document from Mock Firestore', () async {
      final service = firestoreService!;
      const collectionName = 'testCollection';
      const documentName = 'testDocument';
      const fieldNames = ['name', 'value'];
      const fieldValues = ['TestName', 'TestValue'];
      await service.addDocument(
        collectionName: collectionName,
        filename: documentName,
        fieldNames: fieldNames,
        fieldValues: fieldValues,
      );

      final document = await service.readDocument(
        collectionName: collectionName,
        docName: documentName,
      );

      expect(document, isNotNull);
      expect(
        document?['value'],
        'TestValue',
        reason: "Document should contain the correct 'value' field",
      );
    });
  });
}
