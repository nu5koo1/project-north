import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VILLMARK title is displayed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('VILLMARK'))),
    );

    expect(find.text('VILLMARK'), findsOneWidget);
  });
}
