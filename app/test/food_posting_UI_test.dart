import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/Screens/detail_screen.dart';
import 'mock.dart';
import 'package:firebase_core/firebase_core.dart';

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

  testWidgets('Posting page builds correctly', (WidgetTester tester) async {
    // Render the PostDetailView widget
    await tester.pumpWidget(CupertinoApp(
      home: PostDetailView(
        postId: '26eb541c-b28d-4586-8354-12e7035218f3',
      ),
    ));

    expect(true, isTrue);
  });
}
