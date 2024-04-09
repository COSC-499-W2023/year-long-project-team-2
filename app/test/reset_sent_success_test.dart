import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/reset_sent_screen.dart';
import 'package:mockito/mockito.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  group('SuccessScreen UI Tests', () {
    late NavigatorObserver mockObserver;

    setUp(() {
      mockObserver = MockNavigatorObserver();
    });

    testWidgets('Check if all elements are present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: SuccessScreen(message: 'Test Message'),
          navigatorObservers: [mockObserver],
        ),
      );

      // Verify that the text "Success" is present
      expect(find.text('Success!'), findsOneWidget);

      // Verify that the text is present
      expect(find.text("A password reset link has been sent to your email address."),findsOneWidget);

      // Verify that the text "Continue to FoodHood" on the button is present
      expect(find.text('Continue to FoodHood'), findsOneWidget);

      // Verify that the submit button and back buttons are rendered.
      expect(find.byType(CupertinoButton), findsNWidgets(2), reason: "Submit and back button not found");
    });
  });
}
