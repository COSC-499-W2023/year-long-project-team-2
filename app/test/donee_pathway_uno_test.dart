import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/donee_screen.dart';

import 'mock.dart';

void main() {
  setUpAll(() async {
    // Ensure the test environment is set up correctly
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase Analytics
    setupFirebaseAnalyticsMocks();

    // Initialize Firebase only if it hasn't been initialized yet
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  });
  testWidgets('DoneePath UI Test', (WidgetTester tester) async {
    // Build the DoneePath widget
    await tester.pumpWidget(CupertinoApp(
      home: DoneePath(
        postId: '0da23dff-bdf2-4379-8bd5-c2b4cb67d873',
      ),
    ));

    // Wait for data to load
    await tester.pump();

    // Verify if the title text is displayed
    expect(find.text('Reservation'), findsOneWidget);

    // Verify if the back button is displayed
    expect(find.byType(CupertinoNavigationBarBackButton), findsOneWidget);

    // Verify if the 'Message' button is displayed
    expect(find.byType(CupertinoButton),
        findsWidgets); // Update the text according to your actual logic

    // Verify if the Leave a Review button is displayed
    // expect(find.text('Leave a Review'), findsOneWidget);

    // Verify if the Cancel Reservation button is displayed
    // expect(find.text('Cancel Reservation'), findsOneWidget);

    // Verify if the image is displayed
    //expect(find.byType(Image), findsOneWidget);

    // Verify if the text containing post details is displayed
    //expect(find.textContaining('You have reserved'), findsOneWidget);

    // Verify if the text containing user details is displayed
    // expect(find.textContaining('Made by'), findsOneWidget);
  });
}
