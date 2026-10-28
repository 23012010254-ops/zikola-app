
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zikola/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ZikolaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
