import 'package:flutter/material.dart';

/// Standardized queue / token avatar badge for GuwahatiOne Clinic OS.
class TokenBadge extends StatelessWidget {
  final int queueNumber;
  final bool isCalling;
  final bool isCompleted;
  final bool isAbsent;
  final double size;

  const TokenBadge({
    super.key,
    required this.queueNumber,
    this.isCalling = false,
    this.isCompleted = false,
    this.isAbsent = false,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color borderColor;

    if (isCalling) {
      bg = const Color(0xFF2563EB);
      textColor = Colors.white;
      borderColor = const Color(0xFF1D4ED8);
    } else if (isAbsent) {
      bg = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFB91C1C);
      borderColor = const Color(0xFFFCA5A5);
    } else if (isCompleted) {
      bg = const Color(0xFFECFDF5);
      textColor = const Color(0xFF047857);
      borderColor = const Color(0xFFA7F3D0);
    } else {
      bg = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF0F172A);
      borderColor = const Color(0xFFCBD5E1);
    }

    final fontSize = size * 0.42;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: borderColor, width: isCalling ? 2 : 1),
        boxShadow: isCalling
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        "#$queueNumber",
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
