import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/clinic_provider.dart';

/// Instant patient phone, name, or token search bar with keyboard accelerator.
class DashboardHeaderBar extends StatefulWidget {
  final ClinicProvider provider;

  const DashboardHeaderBar({super.key, required this.provider});

  @override
  State<DashboardHeaderBar> createState() => _DashboardHeaderBarState();
}

class _DashboardHeaderBarState extends State<DashboardHeaderBar> {
  late final TextEditingController _searchCtrl;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(
      text: widget.provider.dashboardSearchQuery,
    );
    HardwareKeyboard.instance.addHandler(_handlePhysicalKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handlePhysicalKey);
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _handlePhysicalKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.slash ||
            event.character == '/') &&
        !_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchCtrl,
      focusNode: _searchFocusNode,
      onChanged: (val) {
        widget.provider.setDashboardSearchQuery(val);
        setState(() {});
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: 'Instant Queue Search: Type 10-digit phone, patient name, or token #...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 19,
          color: Colors.teal,
        ),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                onPressed: () {
                  _searchCtrl.clear();
                  widget.provider.clearDashboardSearchQuery();
                  setState(() {});
                },
              )
            : Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Type / anywhere to search',
                      child: InkWell(
                        onTap: () => _searchFocusNode.requestFocus(),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Text(
                            '/',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
