import 'package:flutter_test/flutter_test.dart';
import 'mock_firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart';
import 'package:FoodHood/Screens/create_post.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';

void main() {

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseAnalyticsMocks();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  });
  group('Create Post Tests', () {
    testWidgets('Create Post Screen UI Test', (WidgetTester tester) async {

      await tester.pumpWidget(
        CupertinoApp(
          home: ChangeNotifierProvider(
          create: (context) => TextScaleProvider(),
          child: CreatePostScreen(),
        ),
        )
      );

      // Verify that both buttons (save and cancel) are present
      expect(find.byType(CupertinoButton), findsNWidgets(2),
          reason: "Save or Cancel button not found");

      // Verify that the text input fields for title, description, and pickup instructions are present
      expect(find.byType(CupertinoTextField), findsWidgets,
          reason: "1 or more text input fields are missing");

      // Test functionality upon clicking on the "Save" button
      // Find the "Save" button and tap it
      await tester.tap(find.text('Save'));
      // Wait for animations to complete
      await tester.pumpAndSettle();
      // Verify that the confirmation dialogue appears
      expect(find.text('Missing Information'), findsOneWidget);
      expect(find.text('Please enter all the information before saving.'),
          findsOneWidget);
      // Tap the "OK" button in the confirmation dialogue
      await tester.tap(find.text('OK'));
      // Wait for animations to complete
      await tester.pumpAndSettle();
      // Verify that the screen is still open (not popped)
      expect(find.byType(CreatePostScreen), findsOneWidget);
    });

    test('Simulate Successful Document Addition', () async {
      // Arrange - setup phase for preparing the necessary preconditions and inputs for the test
      final firestoreService = MockFirestoreService();
      // Set simulateSuccess to true to simulate a successful operation
      firestoreService.simulateSuccess = true;

      // Act - Call the method that needs to be tested
      await firestoreService.addDocument(
        collectionName: 'mockCollection',
        filename: 'mockFilename',
        fieldNames: ['field1'],
        fieldValues: ['value1'],
      );

      // Asserts - Verifying the actual outcome matches the expected ones
      // Assert 1 - Check if simulateSuccess is still true after the operation
      expect(firestoreService.simulateSuccess, isTrue);

      // Retrieve the data from the mock service
      final addedData = await firestoreService.readDocument(
        collectionName: 'mockCollection',
        docName: 'mockFilename',
      );
      // Assert 2 - Check if the data contains the expected field name and value
      expect(addedData?['field1'], 'value1');
    });

    test('Simulate Document Addition Failure', () async {
      // Arrange
      final firestoreService = MockFirestoreService();
      // Set simulateSuccess to false to simulate a failure
      firestoreService.simulateSuccess = false;

      // Act and Assert
      // Using expectLater handle the asynchronous nature
      expectLater(
        () => firestoreService.addDocument(
          collectionName: 'mockCollection',
          filename: 'mockFilename',
          fieldNames: ['field1'],
          fieldValues: ['value1'],
        ),
        throwsA(isInstanceOf<String>()),
      );

      // Check if simulateSuccess is still false after the operation
      expect(firestoreService.simulateSuccess, isFalse);

      //check if the data is not present after the failure
      final addedDataAfterFailure = await firestoreService.readDocument(
        collectionName: 'mockCollection',
        docName: 'mockFilename',
      );
      expect(addedDataAfterFailure, isNull);
      expect(true, isTrue);
    });
  });
}
