import 'package:flutter_test/flutter_test.dart';
import 'package:ex00/main.dart';

void main() {
  testWidgets('shows text and a button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('A simple text'), findsOneWidget);
    expect(find.text('Click me'), findsOneWidget);
  });
}
