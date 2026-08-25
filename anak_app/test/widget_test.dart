
import 'package:flutter_test/flutter_test.dart';
import 'package:zikola/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ZikolaApp());
    expect(find.text('Zikola'), findsOneWidget);
  });
}
