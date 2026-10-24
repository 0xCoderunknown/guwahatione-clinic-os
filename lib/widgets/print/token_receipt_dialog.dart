import 'package:flutter/material.dart';

import '../../config/clinic_config.dart';
import '../../models/appointment.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_print.dart';

/// Thermal POS / Slip receipt dialog for counter registrations and token issuance.
/// Gated under `ClinicFeatureFlags.enableTokenReceiptPrint`.
class TokenReceiptDialog extends StatelessWidget {
  final Appointment appointment;

  const TokenReceiptDialog({super.key, required this.appointment});

  static Future<void> show(BuildContext context, Appointment appointment) {
    return showDialog(
      context: context,
      builder: (_) => TokenReceiptDialog(appointment: appointment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ClinicConfig.current;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFF0F766E), size: 22),
              SizedBox(width: 8),
              Text(
                'Token Receipt Slip',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Clinic Branding Header
                Text(
                  config.clinicName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (config.tagline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    config.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (config.address.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    config.address,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],

                const SizedBox(height: 12),
                _buildDashedLine(),
                const SizedBox(height: 12),

                // 2. Token Hero Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF5EEAD4)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'OPD QUEUE TOKEN',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${appointment.queueNumber}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${AppFormatters.date(appointment.scheduledDate)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                _buildDashedLine(),
                const SizedBox(height: 12),

                // 3. Consultation & Patient Key Facts
                _buildFactRow(
                  'Doctor',
                  AppFormatters.doctorTitle(appointment.doctorName),
                  isBold: true,
                ),
                const SizedBox(height: 6),
                _buildFactRow('Patient', appointment.patientName, isBold: true),
                const SizedBox(height: 6),
                _buildFactRow('Phone', appointment.patientPhone),
                const SizedBox(height: 6),
                _buildFactRow(
                  'Payment',
                  appointment.amountCollected > 0
                      ? '₹${appointment.amountCollected} • ${appointment.paymentType.methodLabel}'
                      : appointment.paymentType.displayName,
                  isBold: true,
                  valueColor: appointment.amountCollected > 0
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB45309),
                ),
                if (appointment.checkedInAt != null) ...[
                  const SizedBox(height: 6),
                  _buildFactRow(
                    'Checked-In',
                    AppFormatters.time(appointment.checkedInAt!),
                  ),
                ],

                const SizedBox(height: 14),
                _buildDashedLine(),
                const SizedBox(height: 10),

                // 4. Instructions & Footer
                Text(
                  'Please wait in the clinic waiting lobby.\nYour token number will be announced.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
                if (config.contactPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Helpline: ${config.contactPhone}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.print_rounded, size: 16),
          label: const Text('Print Slip'),
          onPressed: () {
            final html = _generateThermalHtml(config);
            printDocument(html: html);
          },
        ),
      ],
    );
  }

  String _generateThermalHtml(ClinicConfig config) {
    final paymentInfo = appointment.amountCollected > 0
        ? '₹${appointment.amountCollected} (${appointment.paymentType.methodLabel})'
        : appointment.paymentType.displayName;
    final checkedInStr = appointment.checkedInAt != null
        ? AppFormatters.time(appointment.checkedInAt!)
        : '--';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Token_${appointment.queueNumber}</title>
  <style>
    @page { size: 80mm auto; margin: 4mm; }
    body {
      font-family: 'Courier New', Courier, monospace, sans-serif;
      width: 72mm;
      margin: 0 auto;
      padding: 6px;
      color: #000;
      font-size: 12px;
      line-height: 1.3;
    }
    .center { text-align: center; }
    .bold { font-weight: bold; }
    .clinic-name { font-size: 15px; font-weight: 900; }
    .divider { border-top: 1px dashed #000; margin: 6px 0; }
    .token-box {
      border: 2px solid #000;
      padding: 6px;
      margin: 6px 0;
      text-align: center;
    }
    .token-num { font-size: 32px; font-weight: 900; line-height: 1; }
    .row { display: flex; justify-content: space-between; margin: 3px 0; }
    .label { color: #333; }
    .val { font-weight: bold; }
    .footer { font-size: 10px; text-align: center; margin-top: 8px; font-style: italic; }
  </style>
</head>
<body>
  <div class="center clinic-name">${config.clinicName.toUpperCase()}</div>
  ${config.tagline.isNotEmpty ? '<div class="center" style="font-size:10px;">${config.tagline}</div>' : ''}
  ${config.address.isNotEmpty ? '<div class="center" style="font-size:9px;">${config.address}</div>' : ''}
  <div class="divider"></div>
  <div class="token-box">
    <div style="font-size: 10px; font-weight: bold; letter-spacing: 1px;">OPD QUEUE TOKEN</div>
    <div class="token-num">#${appointment.queueNumber}</div>
    <div style="font-size: 11px;">Date: ${AppFormatters.date(appointment.scheduledDate)}</div>
  </div>
  <div class="divider"></div>
  <div class="row"><span class="label">Doctor:</span><span class="val">${AppFormatters.doctorTitle(appointment.doctorName)}</span></div>
  <div class="row"><span class="label">Patient:</span><span class="val">${appointment.patientName}</span></div>
  <div class="row"><span class="label">Phone:</span><span class="val">${appointment.patientPhone}</span></div>
  <div class="row"><span class="label">Payment:</span><span class="val">$paymentInfo</span></div>
  ${appointment.checkedInAt != null ? '<div class="row"><span class="label">Checked In:</span><span class="val">$checkedInStr</span></div>' : ''}
  <div class="divider"></div>
  <div class="footer">
    Please wait in the clinic waiting lobby.<br>
    Your token number will be announced.
    ${config.contactPhone.isNotEmpty ? '<br><b>Helpline: ${config.contactPhone}</b>' : ''}
  </div>
</body>
</html>
''';
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.constrainWidth() / 8).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: 4,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFactRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
