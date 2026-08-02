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
    await tester.pump(const Duration(milliseconds: 500)); // allow animations
    
    // Tap Class 12
    await tester.tap(find.text('Class 12'));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap PCB
    await tester.tap(find.text('Science (PCB)'));
    await tester.pump(const Duration(milliseconds: 500));

    // PCB has Biology
    expect(find.text('Biology'), findsWidgets);
  });
}
