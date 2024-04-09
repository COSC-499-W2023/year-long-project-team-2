import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/login_screen.dart'; 
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseAnalyticsMocks();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  });

  testWidgets('Check for at least one Text widget and one ElevatedButton in LogInScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: LogInScreen(),
      ),
    );

    expect(find.byType(Text), findsWidgets);
    expect(find.byType(CupertinoButton), findsWidgets);
  });
}
