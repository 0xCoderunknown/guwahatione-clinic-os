import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(
      text: widget.provider.dashboardSearchQuery,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
              const Spacer(),
              // Active Doctor Chamber count indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.meeting_room_rounded,
                      size: 13,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.provider.doctors.length} Doctors Active',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Instant Patient Phone / Name / Token Search
          TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              widget.provider.setDashboardSearchQuery(val);
              setState(() {});
            },
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              hintText:
                  'Instant Queue Search: Type 10-digit phone, patient name, or token #...',
              hintStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
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
                  : null,
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
