import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple prompt dialog for entering custom course duration in days.
class CustomDurationDialog extends StatefulWidget {
  final int? initialDays;
  final ValueChanged<int> onApply;

  const CustomDurationDialog({
    super.key,
    this.initialDays,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    int? initialDays,
    required ValueChanged<int> onApply,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CustomDurationDialog(
        initialDays: initialDays,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<CustomDurationDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialDays != null && widget.initialDays! > 0
          ? widget.initialDays.toString()
          : '10',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final text = _controller.text.trim();
    final parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter a valid number of days (e.g. 10)');
      return;
    }
    widget.onApply(parsed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_calendar_rounded, size: 20, color: Color(0xFF0F766E)),
          SizedBox(width: 8),
          Text('Custom Duration', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter prescription course duration in days:',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Duration (Days)',
              hintText: 'e.g. 10',
              errorText: _error,
              suffixText: 'Days',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onSubmitted: (_) => _apply(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
          ),
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
