import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elcarni/main.dart';

void main() {
  testWidgets('Dashboard loads with bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(const ElCarniApp());
    await tester.pumpAndSettle();

    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Élèves actifs'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Prochaines séances'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Prochaines séances'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.groups));
    await tester.pumpAndSettle();

    expect(find.text('Groupes'), findsWidgets);
  });
}
