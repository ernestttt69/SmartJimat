import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_assignment/main.dart';

void main() {
  testWidgets('SmartJimat app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SmartJimat'), findsOneWidget);
  });
}