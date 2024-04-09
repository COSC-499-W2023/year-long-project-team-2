import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/accessibility_screen.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart';

void main(){
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
          child: AccessibilityScreen(),
        ),
      ),
    );

    // Verify that the back button is there
    expect(find.byIcon(FeatherIcons.chevronLeft), findsOneWidget, reason: "Back arrow icon not found");
    
    // Verify that "Text Size" text is there
    expect(find.text('Text Size'), findsOneWidget, reason: "Text Size not found");

    // Verify that the slider is present
    expect(find.byType(CupertinoSlider), findsOneWidget, reason: "Slider not found");
    
  });
}