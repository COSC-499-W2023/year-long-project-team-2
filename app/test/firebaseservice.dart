import 'package:mockito/mockito.dart';

class FirestoreService {
  Future<void> addAllergensCategoriesAndPL() async {
    // Your mock implementation for addAllergensCategoriesAndPL
    print("Mocked allergens, categories, and pickup locations added successfully!");
  }

  Future<void> addDocument({
    required String collectionName,
    required String filename,
    required List<String> fieldNames,
    required List<dynamic> fieldValues,
  }) async {
    // Your mock implementation for addDocument
    print('Mocked document added successfully!');
  }

  Future<Map<String, dynamic>?> readDocument({
    required String collectionName,
    required String docName,
  }) async {
    return null;
    }
}

class MockFirestoreService extends Mock implements FirestoreService {
  bool simulateSuccess = true;
  Map<String, Map<String, dynamic>> mockDatabase = {};

  @override
  Future<void> addAllergensCategoriesAndPL() {
    // Your mock implementation for addAllergensCategoriesAndPL
    return Future.value();
  }

  @override
  Future<void> addDocument({
    required String collectionName,
    required String filename,
    required List<String> fieldNames,
    required List<dynamic> fieldValues,
  }) {
    // Mock implementation for addDocument
    if (simulateSuccess) {
      // Create a map representing the document and add it to the mock database
      final documentData = Map.fromIterables(fieldNames, fieldValues);
      mockDatabase[collectionName + '/' + filename] = documentData;
      return Future.value();
    } else {
      // Simulate failure by throwing an error
      return Future.error('Simulated failure');
    }
  }

  @override
  Future<Map<String, dynamic>?> readDocument({
    required String collectionName,
    required String docName,
  }) {
    // Your mock implementation for readDocument
    return Future.value(mockDatabase[collectionName + '/' + docName]);
  }
}