// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Screens/profile_edit_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:feather_icons/feather_icons.dart';
import 'mock_firestore_service.dart';
import 'mock.dart';
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

  group('Edit Profile Test', () {
    testWidgets('Edit Profile Screen UI Test', (WidgetTester tester) async {
      await tester.pumpWidget(CupertinoApp(
        home: ChangeNotifierProvider(
          create: (context) => TextScaleProvider(),
          child: EditProfileScreen(),
        ),
      ));

      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsNWidgets(4));
      expect(find.text('Upload Profile Picture'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      //await tester.tap(find.byIcon(FeatherIcons.x));
      //await tester.pumpAndSettle();

      //expect(find.byType(EditProfilePage), findsNothing);
    });

    test('Simulate Successful Document Addition', () async {
      final firestoreService = MockFirestoreService();
      firestoreService.simulateSuccess = true;

      await firestoreService.addDocument(
        collectionName: 'mockCollection',
        filename: 'mockFilename',
        fieldNames: ['field1'],
        fieldValues: ['value1'],
      );

      expect(firestoreService.simulateSuccess, isTrue);

      final addedData = await firestoreService.readDocument(
        collectionName: 'mockCollection',
        docName: 'mockFilename',
      );
      expect(addedData?['field1'], 'value1');
    });

    group('Firestore Service Tests', () {
      late MockFirestoreService mockFirestoreService;

      setUp(() {
        mockFirestoreService = MockFirestoreService();
      });

      test('Simulate Successful Document Addition', () async {
        mockFirestoreService.simulateSuccess = true;
        final fieldNames = ['field1'];
        final fieldValues = ['value1'];

        await mockFirestoreService.addDocument(
          collectionName: 'mockCollection',
          filename: 'mockFilename',
          fieldNames: fieldNames,
          fieldValues: fieldValues,
        );

        final addedData = await mockFirestoreService.readDocument(
          collectionName: 'mockCollection',
          docName: 'mockFilename',
        );
        expect(addedData, isNotNull);
        expect(addedData?['field1'], 'value1');
      });

      test('Simulate Document Addition Failure', () async {
        final firestoreService = MockFirestoreService();
        firestoreService.simulateSuccess = false;

        expectLater(
          () => firestoreService.addDocument(
            collectionName: 'mockCollection',
            filename: 'mockFilename',
            fieldNames: ['field1'],
            fieldValues: ['value1'],
          ),
          throwsA(isInstanceOf<String>()),
        );

        expect(firestoreService.simulateSuccess, isFalse);

        final addedDataAfterFailure = await firestoreService.readDocument(
          collectionName: 'mockCollection',
          docName: 'mockFilename',
        );
        expect(addedDataAfterFailure, isNull);
      });
    });
  });
}
