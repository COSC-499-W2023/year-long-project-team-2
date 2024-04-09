import 'package:mockito/mockito.dart';

class FirestoreService {
  Future<void> addAllergensCategoriesAndPL() async {
    print("Mocked allergens, categories, and pickup locations added successfully!");
  }

  Future<void> addDocument({
    required String collectionName,
    required String filename,
    required List<String> fieldNames,
    required List<dynamic> fieldValues,
  }) async {
    print('Mocked document added successfully!');
  }

  Future<void> readDocument({
    required String collectionName,
    required String docName,
  }) async {
    // Mock implementation for readDocument
    print('Mocked document read successfully!');
  }
}

class MockFirestoreService extends Mock implements FirestoreService {
  bool simulateSuccess = true;
  Map<String, Map<String, dynamic>> mockDatabase = {};

  @override
  Future<void> addAllergensCategoriesAndPL() {
    return Future.value();
  }

  @override
  Future<void> addDocument({
    required String collectionName,
    required String filename,
    required List<String> fieldNames,
    required List<dynamic> fieldValues,
  }) {
    if (simulateSuccess) {
      final documentData = Map.fromIterables(fieldNames, fieldValues);
      mockDatabase[collectionName + '/' + filename] = documentData;
      return Future.value();
    } else {
      return Future.error('Simulated failure');
    }
  }

  @override
  Future<Map<String, dynamic>?> readDocument({
    required String collectionName,
    required String docName,
  }) {
    return Future.value(mockDatabase[collectionName + '/' + docName]);
  }
}
