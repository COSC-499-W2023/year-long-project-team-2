import 'package:flutter_test/flutter_test.dart';
import 'package:FoodHood/main.dart';
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

  testWidgets('FoodHoodApp builds correctly', (WidgetTester tester) async {
    await tester.pumpWidget(FoodHoodApp());
    expect(find.byType(FoodHoodApp), findsOneWidget);
  });
}
