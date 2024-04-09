import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/settings_screen.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_switch/flutter_switch.dart';

void main() {

  // This ensures the following firebase setup and initialization code runs only once.
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
  testWidgets('Settings Screen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: ChangeNotifierProvider(
          create: (context) => TextScaleProvider(),
          child: SettingsScreen(),
        ),
      ),
    );

    // Verify that the back button is there
    expect(find.byIcon(FeatherIcons.chevronLeft), findsOneWidget, reason: "Back arrow icon not found");

    // Verify that the switch is there
    expect(find.byType(FlutterSwitch), findsOneWidget, reason: "Switch button not found");

    // Verify that the Edit FoodHood profile text is there
    expect(find.text('Edit FoodHood Profile'), findsOneWidget);
    
    // Verify that "Account Settings" text is there
    expect(find.text('Account Settings'), findsNWidgets(1), reason: "Account Settings text not found");

    // Verify that all buttons (Accessibility, Help, Sign Out, Reset Password, and Delete Account) are present
    expect(find.byType(CupertinoButton), findsNWidgets(5), reason: "1 or more buttons not found");
    
  });
}
