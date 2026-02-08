import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avodah/app.dart';

void main() {
  testWidgets('App loads with Tasks screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AvodahApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify we're on the Tasks screen
    expect(find.text('Tasks'), findsWidgets);
  });
}
