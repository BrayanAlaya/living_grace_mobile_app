import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:living_grace_bad/main.dart';

void main() {
  testWidgets('arranca la app espagueti', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AppTodaMezclada()),
    );
    expect(find.text('Cargando...'), findsOneWidget);
    expect(find.text('Grace'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
