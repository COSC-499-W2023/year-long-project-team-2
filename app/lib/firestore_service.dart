import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addAllergensCategoriesAndPL() async {
  // Add Allergens
  List<String> allergens = ['Milk', 'Peanuts', 'Egg', 'Soy', 'Wheat', 'Fish', 'Shellfish', 'Sesame'];
  await addDocument(
    collectionName: 'Data',
    filename: 'Allergens',
    fieldNames: ['items'],
    fieldValues: [allergens],
  );

  // Add Categories
  List<String> categories = ['Vegan', 'Vegetarian', 'Halal', 'Chicken', 'Indian', 'Italian', 'Chinese'];
  await addDocument(
    collectionName: 'Data',
    filename: 'Categories',
    fieldNames: ['items'],
    fieldValues: [categories],
  );

  // Add Pickup Locations
  List<String> pick_locations = ['Walmart', 'Safeway', 'Superstore', 'Ogopogo Statue', 'Orchard Park'];
  await addDocument(
    collectionName: 'Data',
    filename: 'Pickup Locations',
    fieldNames: ['items'],
    fieldValues: [pick_locations],
  );
}


Future<void> addDocument({
  required String collectionName,
  required String filename,
  required List<String> fieldNames,
  required List<dynamic> fieldValues,
}) async {
  try {
    // Create a reference to the Firestore collection
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection(collectionName);

    // Create a map with field names and corresponding values
    Map<String, dynamic> data = {};
    for (int i = 0; i < fieldNames.length; i++) {
      data[fieldNames[i]] = fieldValues[i];
    }

    // Add the document to the collection
    await collectionReference.doc(filename).set(data);

    print('Document added successfully!');
  } catch (e) {
    print('Error adding document: $e');
  }
}

Future<Map<String, dynamic>?> readDocument({
  required String collectionName,
  required String docName,
}) async {
  try {
    // Create a reference to the Firestore collection
    CollectionReference collectionReference =
        FirebaseFirestore.instance.collection(collectionName);

    // Get the document snapshot
    DocumentSnapshot documentSnapshot = await collectionReference.doc(docName).get();

    // Check if the document exists
    if (documentSnapshot.exists) {
      // Access the data from the document
      Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
      return data;
    } else {
      print('Document does not exist.');
      return null;
    }
  } catch (e) {
    print('Error reading document: $e');
    return null;
  }
}