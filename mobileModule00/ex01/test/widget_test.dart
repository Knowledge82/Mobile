import 'package:flutter_test/flutter_test.dart';
import 'package:ex01/main.dart';

void main() {
  testWidgets('toggles the text on every button press',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('A simple text'), findsOneWidget);
    expect(find.text('Hello World!'), findsNothing);

    await tester.tap(find.text('Click me'));
    await tester.pump();
    expect(find.text('Hello World!'), findsOneWidget);
    expect(find.text('A simple text'), findsNothing);

    await tester.tap(find.text('Click me'));
    await tester.pump();
    expect(find.text('A simple text'), findsOneWidget);
    expect(find.text('Hello World!'), findsNothing);
  });
}
