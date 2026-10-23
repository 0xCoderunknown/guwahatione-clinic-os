import 'package:flutter/material.dart';

import '../../models/chamber_session.dart';

/// Doctor Chamber Handshake Control Banner.
///
/// Coordinates the 2-way handshake protocol between Doctor and Reception:
/// - Informs doctor when consultation has concluded so they can take an essential breather.
/// - Provides the primary "NEXT PATIENT" trigger that signals Reception to call the next present patient.
/// - Displays incoming patient status when Reception admits a verified patient into the chamber.
class ChamberControlBanner extends StatelessWidget {
  final ChamberStatus status;
  final int? lastCompletedQueueNumber;
  final String? lastCompletedPatientName;
  final int? activeQueueNumber;
  final String? activePatientName;
  final bool isBusy;
  final VoidCallback onNextPatient;
  final VoidCallback? onOpenActivePatient;
  final VoidCallback? onEndShift;
  final VoidCallback? onReopenShift;

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
    this.onEndShift,
    this.onReopenShift,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        switch (status) {
          case ChamberStatus.consultationEnded:
            return _ConsultationEndedCard(
              isCompact: isCompact,
              lastCompletedQueueNumber: lastCompletedQueueNumber,
              lastCompletedPatientName: lastCompletedPatientName,
              isBusy: isBusy,
              onNextPatient: onNextPatient,
            );
          case ChamberStatus.readyForNext:
            return _ReadyForNextCard(
              isCompact: isCompact,
            );
          case ChamberStatus.calling:
            return _CallingIncomingCard(
              isCompact: isCompact,
              activeQueueNumber: activeQueueNumber,
              activePatientName: activePatientName,
              onOpenActivePatient: onOpenActivePatient,
            );
          case ChamberStatus.inConsultation:
            return _InConsultationCard(
              isCompact: isCompact,
              activeQueueNumber: activeQueueNumber,
              activePatientName: activePatientName,
            );
          case ChamberStatus.shiftEnded:
            return _ShiftEndedCard(
              isCompact: isCompact,
              lastCompletedQueueNumber: lastCompletedQueueNumber,
              isBusy: isBusy,
              onReopenShift: onReopenShift,
            );
          case ChamberStatus.idle:
            return _IdleChamberCard(
              isCompact: isCompact,
              isBusy: isBusy,
              onNextPatient: onNextPatient,
            );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Discrete Card Subwidgets
// ─────────────────────────────────────────────────────────────────────────────

class _ConsultationEndedCard extends StatelessWidget {
  final bool isCompact;
  final int? lastCompletedQueueNumber;
  final String? lastCompletedPatientName;
  final bool isBusy;
  final VoidCallback onNextPatient;

  const _ConsultationEndedCard({
    required this.isCompact,
    required this.lastCompletedQueueNumber,
    required this.lastCompletedPatientName,
    required this.isBusy,
    required this.onNextPatient,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
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
    );

    final textWidget = Column(
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
                style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Take your breather (sip water, sanitize). Reception is holding the queue until you call next.',
          style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
        ),
      ],
    );

    final buttonWidget = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );

    final actionsWidget = isCompact
        ? SizedBox(width: double.infinity, child: buttonWidget)
        : buttonWidget;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
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
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(child: textWidget),
                  ],
                ),
                const SizedBox(height: 12),
                actionsWidget,
              ],
            )
          : Row(
              children: [
                iconWidget,
                const SizedBox(width: 16),
                Expanded(child: textWidget),
                const SizedBox(width: 16),
                actionsWidget,
              ],
            ),
    );
  }
}

class _ReadyForNextCard extends StatelessWidget {
  final bool isCompact;

  const _ReadyForNextCard({
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
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
    );

    const textWidget = Column(
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
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
          iconWidget,
          const SizedBox(width: 14),
          const Expanded(child: textWidget),
        ],
      ),
    );
  }
}

class _CallingIncomingCard extends StatelessWidget {
  final bool isCompact;
  final int? activeQueueNumber;
  final String? activePatientName;
  final VoidCallback? onOpenActivePatient;

  const _CallingIncomingCard({
    required this.isCompact,
    required this.activeQueueNumber,
    required this.activePatientName,
    required this.onOpenActivePatient,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
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
    );

    final textWidget = Column(
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
    );

    final buttonWidget = onOpenActivePatient != null
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.file_open_rounded, size: 18),
            label: const Text(
              'Open Clinical File',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: onOpenActivePatient,
          )
        : null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
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
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(child: textWidget),
                  ],
                ),
                if (buttonWidget != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: buttonWidget),
                ],
              ],
            )
          : Row(
              children: [
                iconWidget,
                const SizedBox(width: 16),
                Expanded(child: textWidget),
                if (buttonWidget != null) ...[
                  const SizedBox(width: 16),
                  buttonWidget,
                ],
              ],
            ),
    );
  }
}

class _InConsultationCard extends StatelessWidget {
  final bool isCompact;
  final int? activeQueueNumber;
  final String? activePatientName;

  const _InConsultationCard({
    required this.isCompact,
    required this.activeQueueNumber,
    required this.activePatientName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.medical_services_outlined,
            color: Color(0xFF475569),
            size: 22,
          ),
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
}

class _IdleChamberCard extends StatelessWidget {
  final bool isCompact;
  final bool isBusy;
  final VoidCallback onNextPatient;

  const _IdleChamberCard({
    required this.isCompact,
    required this.isBusy,
    required this.onNextPatient,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
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
    );

    const textWidget = Column(
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
    );

    final buttonWidget = FilledButton.icon(
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
    );

    final actionsWidget = isCompact
        ? SizedBox(width: double.infinity, child: buttonWidget)
        : buttonWidget;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    const Expanded(child: textWidget),
                  ],
                ),
                const SizedBox(height: 12),
                actionsWidget,
              ],
            )
          : Row(
              children: [
                iconWidget,
                const SizedBox(width: 14),
                const Expanded(child: textWidget),
                const SizedBox(width: 14),
                actionsWidget,
              ],
            ),
    );
  }
}

class _ShiftEndedCard extends StatelessWidget {
  final bool isCompact;
  final int? lastCompletedQueueNumber;
  final bool isBusy;
  final VoidCallback? onReopenShift;

  const _ShiftEndedCard({
    required this.isCompact,
    required this.lastCompletedQueueNumber,
    required this.isBusy,
    required this.onReopenShift,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF94A3B8)),
      ),
      child: const Icon(
        Icons.nightlife_rounded,
        color: Color(0xFF334155),
        size: 24,
      ),
    );

    final textWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'OPD Shift Concluded for Today',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            Badge(
              label: Text(
                'SHIFT ENDED',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Color(0xFF475569),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          lastCompletedQueueNumber != null
              ? 'Concluded after Token #${lastCompletedQueueNumber?.toString().padLeft(2, '0')}. Reception desk notified that consultations are closed.'
              : 'Consultation shift is ended. Reception desk notified.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
      ],
    );

    final buttonWidget = onReopenShift != null
        ? OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F766E),
              side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F766E),
                    ),
                  )
                : const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text(
              'RE-OPEN SHIFT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: isBusy ? null : onReopenShift,
          )
        : null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(child: textWidget),
                  ],
                ),
                if (buttonWidget != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: buttonWidget),
                ],
              ],
            )
          : Row(
              children: [
                iconWidget,
                const SizedBox(width: 16),
                Expanded(child: textWidget),
                if (buttonWidget != null) ...[
                  const SizedBox(width: 16),
                  buttonWidget,
                ],
              ],
            ),
    );
  }
}
