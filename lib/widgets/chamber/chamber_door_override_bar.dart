import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../utils/formatters.dart';
import '../common/token_badge.dart';

/// Ultra-minimal "Next at Door" Emergency Runway.
///
/// Restricted fallback when the reception desk is momentarily away or offline.
/// Strictly capped to the next 1–2 patients who are:
/// 1. `VisitStatus.waitingInLobby` (physically present and checked in at reception)
/// 2. `PaymentType != unpaid` (fee confirmed paid, post-pay, or verified free waiver)
/// 3. `AppointmentStatus.pending`
class ChamberDoorOverrideBar extends StatelessWidget {
  final List<Appointment> eligibleTokens;
  final ValueChanged<Appointment> onAdmit;
  final bool isBusy;

  const ChamberDoorOverrideBar({
    super.key,
    required this.eligibleTokens,
    required this.onAdmit,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    // If no verified, lobby-checked-in patient is waiting at the door, render nothing.
    if (eligibleTokens.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 16,
                    color: Colors.blueGrey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next at Door (Lobby Checked-In)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey.shade800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text(
                  'Emergency Self-Call',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isDesktop && eligibleTokens.length > 1)
            Row(
              children: [
                Expanded(child: _buildTokenItem(context, eligibleTokens[0])),
                const SizedBox(width: 12),
                Expanded(child: _buildTokenItem(context, eligibleTokens[1])),
              ],
            )
          else
            Column(
              children: eligibleTokens.map((appt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTokenItem(context, appt),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTokenItem(BuildContext context, Appointment appt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          TokenBadge(
            queueNumber: appt.queueNumber,
            size: 34,
            isCalling: false,
            isCompleted: false,
            isAbsent: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appt.patientName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      appt.paymentType.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: appt.amountCollected > 0
                            ? const Color(0xFF15803D)
                            : Colors.blueGrey.shade600,
                      ),
                    ),
                    if (appt.amountCollected > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${AppFormatters.currency(appt.amountCollected)})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.login_rounded, size: 14),
            label: const Text(
              'Admit',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: isBusy ? null : () => _confirmAndAdmit(context, appt),
          ),
        ],
      ),
    );
  }

  void _confirmAndAdmit(BuildContext context, Appointment appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.meeting_room_rounded, color: Colors.teal.shade800),
            const SizedBox(width: 8),
            const Text('Emergency Door Admission'),
          ],
        ),
        content: Text(
          'Admit Token #${appt.queueNumber} (${appt.patientName}) directly into chamber?\n\n'
          'Status: Lobby Checked-In • ${appt.paymentType.displayName}\n'
          'Use this fallback when reception desk is momentarily away.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onAdmit(appt);
            },
            child: const Text('Admit Now'),
          ),
        ],
      ),
    );
  }
}
