import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../utils/formatters.dart';
import '../common/token_badge.dart';
import '../encounter/encounter_dialogs.dart';

/// Interactive token card displaying queue status, active calling indicators, fee status, and "Consult" action.
class ChamberTokenCard extends StatelessWidget {
  final Appointment appointment;
  final bool isCallingNow;
  final bool isPastDate;
  final VoidCallback onConsult;
  final VoidCallback? onViewHistory;

  const ChamberTokenCard({
    super.key,
    required this.appointment,
    required this.isCallingNow,
    this.isPastDate = false,
    required this.onConsult,
    this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeFg;
    String statusTitle;
    String paymentSubtitle;

    if (isCallingNow && !isPastDate) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeFg = const Color(0xFF15803D);
      statusTitle = "CALLING / IN CHAMBER";
      paymentSubtitle = "Active Token • In Chamber";
    } else if (appointment.status == AppointmentStatus.absent) {
      badgeBg = const Color(0xFFF1F5F9);
      badgeFg = const Color(0xFF64748B);
      statusTitle = isPastDate ? "No-Show" : "ABSENT";
      paymentSubtitle = isPastDate ? "" : "Slot Preserved • ₹0";
    } else if (appointment.status == AppointmentStatus.completed) {
      if (appointment.paymentType.isPaid ||
          (appointment.paymentType == PaymentType.postPay &&
              appointment.amountCollected > 0)) {
        badgeBg = const Color(0xFFDCFCE7);
        badgeFg = const Color(0xFF15803D);
        statusTitle = "COMPLETED";
        paymentSubtitle =
            "Paid: ${AppFormatters.currency(appointment.amountCollected)} (${appointment.paymentType.displayName})";
      } else if (appointment.paymentType == PaymentType.freeReview) {
        badgeBg = const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFFB45309);
        statusTitle = "FREE REVIEW";
        paymentSubtitle = "Follow-up / Report Check • ₹0";
      } else if (appointment.paymentType == PaymentType.freeFamily) {
        badgeBg = const Color(0xFFEDE9FE);
        badgeFg = const Color(0xFF6D28D9);
        statusTitle = "FAMILY / COURTESY";
        paymentSubtitle = "Clinic Courtesy • ₹0";
      } else {
        badgeBg = const Color(0xFFFFFBEB);
        badgeFg = const Color(0xFFB45309);
        statusTitle = "COMPLETED";
        paymentSubtitle = appointment.paymentType.displayName;
      }
    } else if (isPastDate) {
      // EOD Unresolved Token: Pending visit left over from a past date
      badgeBg = const Color(0xFFF1F5F9);
      badgeFg = const Color(0xFF64748B);
      statusTitle = "No-Show";
      paymentSubtitle = "";
    } else {
      // Pending / In Queue (Today)
      badgeBg = const Color(0xFFE0F2FE);
      badgeFg = const Color(0xFF0369A1);
      statusTitle = "WAITING";
      paymentSubtitle = "In Waiting Room";
    }

    final maskedPhone = _maskPhone(appointment.patientPhone);

    final canEnterConsultation =
        isPastDate ||
        appointment.status == AppointmentStatus.completed ||
        isCallingNow;

    Widget? actionWidget;
    if (appointment.status != AppointmentStatus.absent) {
      if (appointment.status == AppointmentStatus.pending) {
        if (!isPastDate && isCallingNow) {
          actionWidget = FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text(
              'Enter Consultation',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: onConsult,
          );
        } else if (!isPastDate) {
          actionWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 13,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Waiting Reception Call',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        actionWidget = OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.description_outlined, size: 14),
          label: Text(
            isPastDate ? 'View Summary' : 'Record',
            style: const TextStyle(fontSize: 11),
          ),
          onPressed: onConsult,
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        final displayName = isPastDate
            ? '#${appointment.queueNumber} • ${appointment.patientName}'
            : appointment.patientName;

        final tokenBadgeWidget = TokenBadge(
          queueNumber: appointment.queueNumber,
          size: isCompact ? 38 : 44,
          isCalling: isCallingNow,
          isCompleted: appointment.status == AppointmentStatus.completed,
          isAbsent: appointment.status == AppointmentStatus.absent,
        );

        final patientDetailsWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: appointment.status == AppointmentStatus.absent
                    ? Colors.grey.shade500
                    : const Color(0xFF0F172A),
                decoration: appointment.status == AppointmentStatus.absent
                    ? TextDecoration.lineThrough
                    : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              maskedPhone,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        );

        final historyButtonWidget = IconButton(
          icon: const Icon(
            Icons.history_rounded,
            size: 20,
            color: Color(0xFF64748B),
          ),
          tooltip: 'View Longitudinal History',
          visualDensity: VisualDensity.compact,
          onPressed:
              onViewHistory ??
              () => EncounterDialogs.showLongitudinalHistory(
                context,
                patientPhone: appointment.patientPhone,
              ),
        );

        final statusBadgeWidget = Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusTitle,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: badgeFg,
              letterSpacing: 0.3,
            ),
          ),
        );

        final paymentSubtitleWidget = Text(
          paymentSubtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: appointment.amountCollected > 0
                ? const Color(0xFF15803D)
                : Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        return InkWell(
          onTap: canEnterConsultation ? onConsult : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 14 : 16,
              vertical: isCompact ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: isCallingNow ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCallingNow
                    ? Colors.teal.shade600
                    : (appointment.status == AppointmentStatus.pending
                          ? Colors.blue.shade200
                          : const Color(0xFFE2E8F0)),
                width: isCallingNow
                    ? 2.5
                    : (appointment.status == AppointmentStatus.pending
                          ? 1.5
                          : 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: isCallingNow
                      ? Colors.teal.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.015),
                  blurRadius: isCallingNow ? 8 : 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (!isPastDate) ...[
                            tokenBadgeWidget,
                            const SizedBox(width: 10),
                          ],
                          Expanded(child: patientDetailsWidget),
                          historyButtonWidget,
                          const SizedBox(width: 4),
                          statusBadgeWidget,
                        ],
                      ),
                      if (paymentSubtitle.isNotEmpty || actionWidget != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (paymentSubtitle.isNotEmpty)
                              Expanded(child: paymentSubtitleWidget)
                            else
                              const Spacer(),
                            if (actionWidget != null) ...[
                              const SizedBox(width: 8),
                              actionWidget,
                            ],
                          ],
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      if (!isPastDate) ...[
                        tokenBadgeWidget,
                        const SizedBox(width: 14),
                      ],
                      Expanded(child: patientDetailsWidget),
                      historyButtonWidget,
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          statusBadgeWidget,
                          if (paymentSubtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            paymentSubtitleWidget,
                          ],
                        ],
                      ),
                      if (actionWidget != null) ...[
                        const SizedBox(width: 14),
                        actionWidget,
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }

  static String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    final last4 = phone.substring(phone.length - 4);
    final prefix = phone.substring(0, (phone.length - 4).clamp(0, 3));
    return '$prefix*****$last4';
  }
}
