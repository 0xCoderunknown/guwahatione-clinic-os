import 'package:flutter/material.dart';

/// Doctor Chamber Handshake Control Banner.
///
/// Coordinates the 2-way handshake protocol between Doctor and Reception:
/// - Informs doctor when consultation has concluded so they can take an essential breather.
/// - Provides the primary "NEXT PATIENT" trigger that signals Reception to call the next present patient.
/// - Displays incoming patient status when Reception admits a verified patient into the chamber.
class ChamberControlBanner extends StatelessWidget {
  final String status;
  final int? lastCompletedQueueNumber;
  final String? lastCompletedPatientName;
  final int? activeQueueNumber;
  final String? activePatientName;
  final bool isBusy;
  final VoidCallback onNextPatient;
  final VoidCallback? onOpenActivePatient;

  const ChamberControlBanner({
    super.key,
    required this.status,
    this.lastCompletedQueueNumber,
    this.lastCompletedPatientName,
    this.activeQueueNumber,
    this.activePatientName,
    this.isBusy = false,
    required this.onNextPatient,
    this.onOpenActivePatient,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'consultation_ended') {
      return _buildConsultationEndedCard(context);
    } else if (status == 'ready_for_next') {
      return _buildReadyForNextCard(context);
    } else if (status == 'calling') {
      return _buildCallingIncomingCard(context);
    } else if (status == 'in_consultation') {
      return _buildInConsultationCard(context);
    } else {
      return _buildIdleCard(context);
    }
  }

  Widget _buildConsultationEndedCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft warm amber
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Icon(
              Icons.coffee_rounded,
              color: Color(0xFFB45309),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Consultation Ended: Token #${lastCompletedQueueNumber?.toString().padLeft(2, '0') ?? '--'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    if (lastCompletedPatientName != null &&
                        lastCompletedPatientName!.isNotEmpty)
                      Text(
                        '($lastCompletedPatientName)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Take your breather (sip water, sanitize). Reception is holding the queue until you call next.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E), // Teal-700
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 20),
            label: const Text(
              'NEXT PATIENT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: isBusy ? null : onNextPatient,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyForNextCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Soft emerald
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF22C55E)),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Color(0xFF15803D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      'Chamber Ready for Next Patient',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF166534),
                      ),
                    ),
                    Badge(
                      label: Text(
                        'SIGNAL SENT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Color(0xFF15803D),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Reception desk notified. Receptionist is verifying physical presence outside before sending the patient in.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF14532D)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F766E),
              side: const BorderSide(color: Color(0xFF0F766E)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Re-Signal Reception', style: TextStyle(fontSize: 12)),
            onPressed: onNextPatient,
          ),
        ],
      ),
    );
  }

  Widget _buildCallingIncomingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3B82F6)),
            ),
            child: const Icon(
              Icons.door_front_door_rounded,
              color: Color(0xFF1D4ED8),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Incoming: Token #${activeQueueNumber?.toString().padLeft(2, '0') ?? '--'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    if (activePatientName != null && activePatientName!.isNotEmpty)
                      Text(
                        '($activePatientName)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Admitted by Reception. Patient is entering the chamber now.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
          ),
          if (onOpenActivePatient != null) ...[
            const SizedBox(width: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.file_open_rounded, size: 18),
              label: const Text('Open Clinical File',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: onOpenActivePatient,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInConsultationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_services_outlined,
              color: Color(0xFF475569), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Consultation in progress with Token #${activeQueueNumber?.toString().padLeft(2, '0') ?? '--'} (${activePatientName ?? 'Patient'})',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.meeting_room_outlined,
              color: Colors.teal.shade800,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPD Chamber Open',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Press "Ready for Next Patient" when ready to begin taking patients.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text(
              'READY FOR FIRST PATIENT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: isBusy ? null : onNextPatient,
          ),
        ],
      ),
    );
  }
}
