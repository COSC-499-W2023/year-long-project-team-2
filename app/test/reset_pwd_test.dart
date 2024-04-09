import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:FoodHood/Screens/reset_pwd_screen.dart';
import 'mock.dart';

void main(){
  // This ensures the following firebase setup and initialization code runs only once.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseAnalyticsMocks();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  });

  testWidgets('Reset Password Screen UI Test', (WidgetTester tester) async {

     // Build our app and trigger a frame.
      await tester.pumpWidget(CupertinoApp(
        home: ForgotPasswordScreen(),
      ));

    // Verify that the Text field is rendered.
    expect(find.byType(CupertinoTextField), findsOneWidget, reason: "Text field not found");

    // Verify that the submit button and back buttons are rendered.
    expect(find.byType(CupertinoButton), findsNWidgets(2), reason: "Submit and back button not found");

  });
}
