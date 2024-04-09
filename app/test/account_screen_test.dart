import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/account_screen.dart';
import 'package:FoodHood/Components/profile_card.dart';
import 'package:firebase_core/firebase_core.dart';
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

  group('AccountScreen Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      setupFirebaseAnalyticsMocks();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    });

    testWidgets('AccountScreen should display the necessary widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: ChangeNotifierProvider(
          create: (context) => TextScaleProvider(),
          child: AccountScreen(),
        ),
        )
      );

      expect(find.byType(ProfileCard), findsOneWidget);
      expect(find.text('Active Orders'), findsOneWidget);
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
