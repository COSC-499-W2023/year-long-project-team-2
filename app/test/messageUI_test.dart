import 'package:FoodHood/Screens/message_screen.dart';
import 'package:flutter/cupertino.dart';
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
    // await tester.pumpWidget(CupertinoApp(
    //   home: MessageScreenPage(),
    // ));
    // expect(find.byType(CupertinoSearchTextField), findsOneWidget);
    //expect(find.byType(CupertinoButton), findsWidgets);
    //expect(find.byType(SingleChildScrollView), findsWidgets);
  });
}
