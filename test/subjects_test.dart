import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_buddy_app/screens/register_screen.dart';
import 'package:learn_buddy_app/state/app_settings.dart';

void main() {
  testWidgets('Subjects update on class change', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AppLocale(
        notifier: languageNotifier,
        child: const RegisterScreen(),
      ),
    ));
    // Run all timers
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Verify Class 10 subjects are present
    expect(find.text('Mathematics'), findsWidgets);
    
    // Tap Class 12
    await tester.tap(find.text('Class 12'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Tap PCB
    await tester.tap(find.text('Science (PCB)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Verify PCB subjects are present
    expect(find.text('Physics'), findsWidgets);
  });
}
