import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';

/// Top clinic greeting, live date bar, and instant patient phone/token search bar.
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
    final todayStr = AppFormatters.dateWithDay(DateTime.now());
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 14,
        vertical: isDesktop ? 12 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.today_rounded,
                  color: Colors.teal.shade700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    todayStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text(
                    'OPD Consultation Chamber & Reception Desk',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Instant Patient Phone / Name / Token Search
          TextField(
            controller: _searchCtrl,
            focusNode: _searchFocusNode,
            onChanged: (val) {
              widget.provider.setDashboardSearchQuery(val);
              setState(() {});
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText: 'Instant Queue Search: Type 10-digit phone, patient name, or token #...',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
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
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                  ),
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
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.teal, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
