import 'package:flutter_test/flutter_test.dart';

import 'package:foodhood2/main.dart';

void main() {
  testWidgets('Main App Test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Ensure that the app is successfully built.
    expect(find.byType(MyApp), findsOneWidget);
  });
}