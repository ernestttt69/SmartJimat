import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assignment/screens/welcome_screen.dart';
import 'package:mobile_assignment/screens/customer_register_screen.dart';
import 'package:mobile_assignment/screens/login_screen.dart';

void main() {
  testWidgets('welcome opens login and customer registration', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('REGISTER AS CUSTOMER'), findsOneWidget);
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('REGISTER AS CUSTOMER'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomerRegisterScreen), findsOneWidget);
  });
}
