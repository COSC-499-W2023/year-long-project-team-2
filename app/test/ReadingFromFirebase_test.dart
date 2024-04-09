import 'package:flutter_test/flutter_test.dart';
import 'mock_firestore_service.dart';

void main() {
  group('Firestore Service Tests', () {
    MockFirestoreService? firestoreService;

    setUp(() {
      firestoreService = MockFirestoreService();
    });

    test('Read Document from Mock Firestore', () async {
      final service = firestoreService!;

      //adding a document to firestore
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

      //reading from the firebase
      final document = await service.readDocument(
        collectionName: collectionName,
        docName: documentName,
      );

      //check if the document has the data
      expect(document, isNotNull, reason: "Document should not be null");
      expect(document?['name'], 'TestName',
          reason: "Document should contain the correct 'name' field");
      expect(document?['value'], 'TestValue',
          reason: "Document should contain the correct 'value' field");
    });
  });
}
