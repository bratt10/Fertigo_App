import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ferti_go/main.dart';

void main() {
  testWidgets('App inicia correctamente', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp()); 

    // Verifica que la app se carga
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}