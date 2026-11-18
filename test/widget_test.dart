import 'package:flutter_test/flutter_test.dart';
import 'package:gram_seva/main.dart';

void main() {
  testWidgets('GRAM SEVA app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GramSevaApp());

    expect(find.text('GRAM SEVA'), findsOneWidget);
  });
}
