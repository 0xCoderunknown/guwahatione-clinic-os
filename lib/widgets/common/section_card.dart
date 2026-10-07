import 'package:flutter/material.dart';

/// Standardized card container with clean borders, header icon, and optional collapsible toggle.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Widget? badge;
  final Widget child;
  final bool? isExpanded;
  final VoidCallback? onToggleExpand;
  final EdgeInsetsGeometry contentPadding;
  final Color? headerBgColor;

  const SectionCard({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.badge,
    required this.child,
    this.isExpanded,
    this.onToggleExpand,
    this.contentPadding = const EdgeInsets.all(16.0),
    this.headerBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final showContent = isExpanded ?? true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: Radius.circular(showContent ? 0 : 12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: headerBgColor ?? const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(showContent ? 0 : 12),
                ),
                border: showContent
                    ? const Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))
                    : null,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: const Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge!,
                        ],
                      ],
                    ),
                  ),
                  ?trailing,
                  if (onToggleExpand != null)
                    Icon(
                      showContent ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                ],
              ),
            ),
          ),

          // Content Area
          if (showContent)
            Padding(
              padding: contentPadding,
              child: child,
            ),
        ],
      ),
    );
  }
}
