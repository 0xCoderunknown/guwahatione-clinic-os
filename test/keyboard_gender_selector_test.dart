import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_app/widgets/booking/booking_patient_fields.dart';

void main() {
  group('KeyboardGenderSelector Tab Traversal & Shortcut Tests', () {
    testWidgets('M/F/O keys select gender and Tab moves directly to next focus node',
        (tester) async {
      String? selectedGender;
      final genderFocus = FocusNode();
      final nextFieldFocus = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KeyboardGenderSelector(
                  selectedGender: selectedGender,
                  onGenderChanged: (g) => selectedGender = g,
                  focusNode: genderFocus,
                ),
                TextField(
                  focusNode: nextFieldFocus,
                  decoration: const InputDecoration(labelText: 'Guardian'),
                ),
              ],
            ),
          ),
        ),
      );

      // 1. Focus the gender selector
      genderFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(genderFocus.hasFocus, isTrue);

      // 2. Press 'M' key -> Male selected
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pumpAndSettle();
      expect(selectedGender, 'Male');

      // 3. Press Tab -> Focus MUST jump immediately to nextFieldFocus (Guardian)
      // and NOT cycle through Female/Other InkWells!
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(nextFieldFocus.hasFocus, isTrue,
          reason: 'Tab should directly focus next form field, not inner gender InkWells');
      expect(genderFocus.hasFocus, isFalse);
    });
  });
}
