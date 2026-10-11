import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form fields for patient demographic data (Phone with search trigger, Name, Age, Sex).
/// Ergonomically optimized for 100% keyboard navigation and mouse-free workflow.
class BookingPatientFields extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController nameController;
  final TextEditingController ageController;
  final String? selectedGender;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onPhoneChanged;
  final bool isLoading;
  final FocusNode phoneFocusNode;
  final FocusNode nameFocusNode;
  final FocusNode ageFocusNode;
  final FocusNode genderFocusNode;
  final bool genderHasError;
  final VoidCallback? onSubmitted;

  const BookingPatientFields({
    super.key,
    required this.phoneController,
    required this.nameController,
    required this.ageController,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.onPhoneChanged,
    required this.isLoading,
    required this.phoneFocusNode,
    required this.nameFocusNode,
    required this.ageFocusNode,
    required this.genderFocusNode,
    this.genderHasError = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Phone Input with Discovery Spinner
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: phoneController,
                focusNode: phoneFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '10-digit mobile number',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (val) =>
                    (val == null || val.length < 10) ? 'Enter valid 10-digit phone' : null,
                onChanged: onPhoneChanged,
                onFieldSubmitted: (_) => nameFocusNode.requestFocus(),
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Patient Name (Full width for long names)
        TextFormField(
          controller: nameController,
          focusNode: nameFocusNode,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Patient Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (val) =>
              (val == null || val.trim().isEmpty) ? 'Patient name is required' : null,
          onFieldSubmitted: (_) => ageFocusNode.requestFocus(),
        ),
        const SizedBox(height: 14),

        // 3. Age & Keyboard-First Sex Selector
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Age Field
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: ageController,
                focusNode: ageFocusNode,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Required' : null,
                onFieldSubmitted: (_) => genderFocusNode.requestFocus(),
              ),
            ),
            const SizedBox(width: 10),

            // Keyboard-Driven Sex Segmented Selector
            Expanded(
              flex: 7,
              child: KeyboardGenderSelector(
                selectedGender: selectedGender,
                onGenderChanged: onGenderChanged,
                focusNode: genderFocusNode,
                hasError: genderHasError,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 3-way focusable toggle row for Patient Sex with zero mouse dependency.
/// Supports Tab focus, M/F/O keys, Arrow Left/Right cycling, and direct click.
class KeyboardGenderSelector extends StatefulWidget {
  final String? selectedGender;
  final ValueChanged<String> onGenderChanged;
  final FocusNode focusNode;
  final bool hasError;

  const KeyboardGenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
    required this.focusNode,
    this.hasError = false,
  });

  @override
  State<KeyboardGenderSelector> createState() => _KeyboardGenderSelectorState();
}

class _KeyboardGenderSelectorState extends State<KeyboardGenderSelector> {
  static const _options = ['Male', 'Female', 'Other'];

  void _cycle(int delta) {
    final currentIndex = _options.indexOf(widget.selectedGender ?? '');
    if (currentIndex == -1) {
      widget.onGenderChanged(_options.first);
      return;
    }
    var newIndex = (currentIndex + delta) % _options.length;
    if (newIndex < 0) newIndex += _options.length;
    widget.onGenderChanged(_options[newIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = widget.focusNode.hasFocus;
    final theme = Theme.of(context);

    Color borderColor;
    double borderWidth = 1.0;
    if (widget.hasError) {
      borderColor = theme.colorScheme.error;
      borderWidth = 1.5;
    } else if (hasFocus) {
      borderColor = Colors.teal;
      borderWidth = 2.0;
    } else {
      borderColor = Colors.grey.shade400;
    }

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (_) => setState(() {}),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          final char = event.character?.toLowerCase();
          if (key == LogicalKeyboardKey.keyM || char == 'm') {
            widget.onGenderChanged('Male');
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.keyF || char == 'f') {
            widget.onGenderChanged('Female');
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.keyO || char == 'o') {
            widget.onGenderChanged('Other');
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.arrowDown) {
            _cycle(1);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowUp) {
            _cycle(-1);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
                  hasFocus ? Colors.teal.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            child: Row(
              children: _options.map((option) {
                final isSelected = widget.selectedGender == option;
                final shortcut = option == 'Male'
                    ? 'M'
                    : option == 'Female'
                        ? 'F'
                        : 'O';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () {
                        widget.focusNode.requestFocus();
                        widget.onGenderChanged(option);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.teal : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade800,
                            ),
                            children: [
                              TextSpan(text: option),
                              TextSpan(
                                text: ' ($shortcut)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (widget.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6),
              child: Text(
                'Please select sex (M / F / O)',
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
