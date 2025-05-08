import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namer_app/main.dart';

void main() {
  testWidgets('Prueba la página principal', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MyHomePage), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(GeneratorPage), findsOneWidget);
    expect(find.byType(BigCard), findsOneWidget);
  });

  testWidgets('Prueba el botón Siguiente', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    final initialWordFinder = find.descendant(
      of: find.byType(BigCard),
      matching: find.byType(Text),
    );
    final initialText = (tester.widget(initialWordFinder) as Text).data;
    
    await tester.tap(find.text('Siguiente registro'));
    await tester.pump();
    
    final newText = (tester.widget(initialWordFinder) as Text).data;
    expect(newText, isNot(equals(initialText)));
  });

  testWidgets('Prueba el botón Guardar', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    
    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });
}