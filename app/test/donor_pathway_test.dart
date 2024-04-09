import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/donor_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mock.dart';
import 'package:FoodHood/text_scale_provider.dart';
import 'package:provider/provider.dart';

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

  testWidgets('Donor Screen UI Test', (WidgetTester tester) async {
    await tester.pumpWidget(CupertinoApp(
      home: ChangeNotifierProvider(
        create: (context) => TextScaleProvider(),
        child: DonorScreen(
          postId: 'dummyPostId',
        ),
      ),
    ));

    // Verify that the back button is there
    expect(find.byIcon(FeatherIcons.x), findsOneWidget,
        reason: "X icon not found");

    // Verify that the 2 buttons (Message donee and the Status Change button) are there.
    //expect(find.byType(CupertinoButton), findsNWidgets(2), reason: "Button not found");

    // Verify that the first button (the option to "confirm" is present)
    //expect(find.text("Confirm"), findsOneWidget);
  });
}
