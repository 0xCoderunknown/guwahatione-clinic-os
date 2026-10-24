import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/clinic_provider.dart';
import '../../services/services.dart';
import '../../utils/formatters.dart';
import '../dashboard/clinic_data_export_dialog.dart';
import '../dashboard/daily_cash_handover_dialog.dart';
import '../dashboard/security_settings_dialog.dart';

/// Top desktop AppBar rendered inside OwnerShell.
/// Contains view title, Indian date, owner step-down button, cash handover,
/// sound announcer toggle, and F2 walk-in registration trigger.
class OwnerShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedIndex;
  final bool isOwner;
  final VoidCallback? onWalkInBooking;
  final VoidCallback onStepDown;

  const OwnerShellAppBar({
    super.key,
    required this.selectedIndex,
    required this.isOwner,
    this.onWalkInBooking,
    required this.onStepDown,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getTitleForIndex(int index, bool isOwner) {
    if (isOwner) {
      switch (index) {
        case 0:
          return 'Overview Dashboard';
        case 1:
          return 'Live Appointment Queue';
        case 2:
          return 'Patient Directory & Lookup';
        case 3:
          return 'Doctors & Chamber PINs';
        case 4:
          return 'Payments & Reports';
        case 5:
          return 'Medicine Catalogue';
        default:
          return 'GuwahatiOne Clinic';
      }
    } else {
      switch (index) {
        case 0:
          return 'Overview Dashboard';
        case 1:
          return 'Live Appointment Queue';
        case 2:
          return 'Patient Directory & Lookup';
        case 3:
          return 'Doctor Schedules (Read-Only)';
        case 4:
          return 'Medicine Catalogue';
        default:
          return 'GuwahatiOne Clinic';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _getTitleForIndex(selectedIndex, isOwner),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (selectedIndex == 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•  ${AppFormatters.dateWithDay(DateTime.now())}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                if (selectedIndex == 0)
                  const Text(
                    'OPD Consultation Chamber & Reception Desk',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Security & PIN Settings Button for Owner
          if (isOwner) ...[
            if (screenWidth < 1150) ...[
              PopupMenuButton<String>(
                tooltip: 'Owner Admin & Data Options',
                icon: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Color(0xFF0F766E),
                  size: 20,
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'security',
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Color(0xFF0F766E),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Security & PINs',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 16,
                          color: Color(0xFF0F766E),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Export Data',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'lock',
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lock to Reception',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'security') {
                    SecuritySettingsDialog.show(context);
                  } else if (val == 'export') {
                    ClinicDataExportDialog.show(context);
                  } else if (val == 'lock') {
                    onStepDown();
                  }
                },
              ),
              const SizedBox(width: 10),
            ] else ...[
              Tooltip(
                message: 'Configure Receptionist PIN & Owner Master Passkey',
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    backgroundColor: const Color(0xFFF0FDFA),
                    side: const BorderSide(color: Color(0xFF99F6E4)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => SecuritySettingsDialog.show(context),
                  icon: const Icon(Icons.shield_outlined, size: 16),
                  label: const Text(
                    'Security & PINs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message:
                    'Export Clinic Data & Revenue Ledger to CSV (Tax Audits / Backups)',
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    backgroundColor: const Color(0xFFF0FDFA),
                    side: const BorderSide(color: Color(0xFF99F6E4)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => ClinicDataExportDialog.show(context),
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text(
                    'Export Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade900,
                  backgroundColor: Colors.amber.shade50,
                  side: BorderSide(color: Colors.amber.shade400),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: onStepDown,
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text(
                  'Lock to Reception',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ],

          // End-of-Day Cash Handover Button (Subtle Outline / Ghost)
          Tooltip(
            message: 'End-of-Day Cash Handover & Note Reconciliation',
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final clinic = Provider.of<ClinicProvider>(
                  context,
                  listen: false,
                );
                DailyCashHandoverDialog.show(context, clinic);
              },
              icon: const Icon(
                Icons.receipt_long_rounded,
                size: 15,
                color: Color(0xFF64748B),
              ),
              label: const Text(
                'Cash Handover',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Lobby Sound Announcer Toggle (Compact Icon Button)
          Consumer<SoundService>(
            builder: (_, sound, _) => Tooltip(
              message: sound.isMuted
                  ? 'Lobby Announcer Muted (Click to Unmute)'
                  : 'Lobby Announcer Active (Click to Mute)',
              child: IconButton(
                onPressed: () => sound.toggleMute(),
                icon: Icon(
                  sound.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  size: 19,
                  color: sound.isMuted
                      ? const Color(0xFF94A3B8)
                      : Colors.teal.shade700,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: sound.isMuted
                      ? const Color(0xFFF1F5F9)
                      : Colors.teal.shade50,
                  side: BorderSide(
                    color: sound.isMuted
                        ? const Color(0xFFE2E8F0)
                        : Colors.teal.shade200,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ),
          ),
          // Primary Walk-In Patient Entry Point (Hotkey: F2) - shown if callback provided
          if (onWalkInBooking != null) ...[
            const SizedBox(width: 14),
            Tooltip(
              message: 'Register Walk-In Patient (Hotkey: F2)',
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onWalkInBooking,
                icon: const Icon(Icons.add, size: 18),
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Book Walk-In',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '(F2)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
