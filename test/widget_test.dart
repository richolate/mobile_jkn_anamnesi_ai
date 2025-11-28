// Mobile JKN Anamnesa AI - Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_jkn/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app loads without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
