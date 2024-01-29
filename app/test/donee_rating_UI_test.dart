import 'package:FoodHood/Screens/donee_rating.dart';
import 'package:FoodHood/Screens/donor_rating.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/home_screen.dart';
import 'mock.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseAnalyticsMocks();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  });
  testWidgets('Check for search bar, buttons, and list in MyWidget',
      (WidgetTester tester) async {
    await tester.pumpWidget(CupertinoApp(
      home: DoneeRatingPage(
        postId: '0423e12c-792f-4986-a723-c701f3cf5332',
      ),
    ));
    expect(find.byType(CupertinoTextField), findsOneWidget);
    expect(find.byType(CupertinoButton), findsWidgets);
    expect(find.byType(Icon), findsWidgets);
  });
}
