import '../../config/clinic_config.dart';
import '../../models/appointment.dart';
import '../../models/consultation.dart';
import '../../models/prescription_item.dart';
import '../../utils/formatters.dart';

/// Pure Dart HTML generation engine for high-contrast monochrome A4/A5 prescription printing.
///
/// Complies strictly with AGENTS.md:
/// - Zero Flutter UI dependencies (Pure Dart engine).
/// - Mandatory Indian Date Format (DD-MM-YYYY).
/// - Strict 3-Column Isolation & NMC Generic Uppercase Standard.
/// - WebGL CanvasKit bypass: generates self-contained printable HTML injected into an iframe.
class PrescriptionPrintEngine {
  PrescriptionPrintEngine._();

  /// Generates self-contained, printable HTML for a clinical consultation.
  static String generateHtml({
    required Consultation consultation,
    Appointment? appointment,
    List<String> patientAllergies = const [],
    String? doctorSpecialty,
    String? doctorRegNumber,
    bool usePrePrintedLetterhead = false,
    bool isA5 = false,
    ClinicConfig? config,
  }) {
    final activeConfig = config ?? ClinicConfig.current;
    final hideComp = activeConfig.features.hidePrescriptionComposition;

    final clinicName = _escape(activeConfig.clinicName);
    final clinicTagline = _escape(activeConfig.tagline);
    final clinicAddress = _escape(activeConfig.address);
    final clinicPhone = _escape(activeConfig.contactPhone);

    final doctorName = _escape(AppFormatters.doctorTitle(consultation.doctorName));
    final specialty = _escape(doctorSpecialty ?? 'General Physician');
    final regNo = (doctorRegNumber != null && doctorRegNumber.trim().isNotEmpty)
        ? 'Reg. No: ${_escape(doctorRegNumber.trim())}'
        : (consultation.doctorRegNumber != null && consultation.doctorRegNumber!.trim().isNotEmpty)
            ? 'Reg. No: ${_escape(consultation.doctorRegNumber!.trim())}'
            : '';

    final patientName = _escape(consultation.patientName);
    final ageDisplay = _escape(consultation.patientAgeDisplay ?? 'N/A');
    final visitDate = AppFormatters.date(consultation.createdAt);
    final queueNo = appointment?.queueNumber.toString() ?? '1';
    final patientPhone = _escape(consultation.patientPhone);

    final allergiesHtml = patientAllergies.isNotEmpty
        ? '<div class="alert-box"><strong>⚠️ ALLERGIES / CAUTION:</strong> ${_escape(patientAllergies.join(', '))}</div>'
        : '';

    // Clinical snapshot (vitals, complaints, diagnosis, exam)
    final snapshotHtml = _buildClinicalSnapshotHtml(consultation);

    // Active & Discontinued Medications Table
    final rxTableHtml = _buildRxTableHtml(
      activeMeds: consultation.activePrescriptions,
      stoppedMeds: consultation.stoppedPrescriptions,
      hideComposition: hideComp,
    );

    // Diagnostic Orders & Advice
    final ordersAdviceHtml = _buildOrdersAndAdviceHtml(consultation);

    final topMarginMm = activeConfig.defaultLetterheadTopMarginMm;
    final headerHtml = usePrePrintedLetterhead
        ? '<div style="height: ${topMarginMm}mm;" class="reserved-letterhead"></div>'
        : '''
        <div class="clinic-header">
          <div class="clinic-info">
            <h1 class="clinic-title">$clinicName</h1>
            <div class="clinic-tagline">$clinicTagline</div>
            <div class="clinic-subtext">$clinicAddress • Tel: $clinicPhone</div>
          </div>
          <div class="doctor-badge">
            <div class="doc-title">$doctorName</div>
            <div class="doc-spec">$specialty</div>
            <div class="doc-reg">$regNo</div>
          </div>
        </div>
        ''';

    final pageCss = isA5
        ? '@page { size: A5 portrait; margin: 8mm 10mm; } body { width: 148mm; font-size: 11px; }'
        : '@page { size: A4 portrait; margin: 12mm 15mm; } body { width: 210mm; font-size: 12px; }';

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Prescription - $patientName ($visitDate)</title>
  <style>
    $pageCss
    * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      color: #0F172A;
      margin: 0;
      padding: 0;
      line-height: 1.4;
      background: #FFFFFF;
    }
    .clinic-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      border-bottom: 2px solid #0F172A;
      padding-bottom: 8px;
      margin-bottom: 10px;
    }
    .clinic-title { font-size: 18px; font-weight: 800; margin: 0 0 2px 0; color: #0F766E; text-transform: uppercase; }
    .clinic-tagline { font-size: 11px; font-weight: 600; color: #334155; margin-bottom: 2px; }
    .clinic-subtext { font-size: 10px; color: #64748B; }
    .doctor-badge { text-align: right; }
    .doc-title { font-size: 15px; font-weight: bold; color: #0F172A; }
    .doc-spec { font-size: 11px; font-weight: 600; color: #0F766E; }
    .doc-reg { font-size: 10px; color: #475569; }

    .demographics-strip {
      display: flex;
      justify-content: space-between;
      background: #F8FAFC;
      border: 1px solid #CBD5E1;
      border-radius: 4px;
      padding: 6px 10px;
      margin-bottom: 10px;
      font-size: 11px;
    }
    .demo-col { flex: 1; }
    .demo-col strong { color: #334155; }

    .alert-box {
      background: #FEF2F2;
      border: 1px solid #FCA5A5;
      color: #991B1B;
      border-radius: 4px;
      padding: 6px 10px;
      font-size: 11px;
      margin-bottom: 10px;
    }

    .section-title {
      font-size: 12px;
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #0F766E;
      border-bottom: 1px solid #CBD5E1;
      padding-bottom: 2px;
      margin: 8px 0 6px 0;
    }

    .rx-symbol {
      font-size: 18px;
      font-weight: 900;
      color: #0F172A;
      margin-top: 10px;
      margin-bottom: 4px;
    }

    /* Strict 3-Column Isolated Prescription Table */
    table.rx-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 4px;
      margin-bottom: 12px;
    }
    table.rx-table th {
      background: #F1F5F9;
      border: 1px solid #64748B;
      padding: 6px 8px;
      text-align: left;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
    }
    table.rx-table td {
      border: 1px solid #94A3B8;
      padding: 6px 8px;
      vertical-align: top;
      font-size: 11px;
    }
    .col-med { width: 50%; font-weight: bold; }
    .col-med .composition { font-weight: normal; font-size: 10px; color: #475569; display: block; margin-top: 2px; }
    .col-dosage { width: 33%; font-size: 11px; }
    .col-duration { width: 17%; text-align: right; font-weight: bold; }

    .stopped-table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 4px;
      margin-bottom: 10px;
      background: #FFF1F2;
    }
    .stopped-table th { background: #FFE4E6; border: 1px solid #FDA4AF; padding: 4px 6px; font-size: 10px; }
    .stopped-table td { border: 1px solid #FECDD3; padding: 4px 6px; font-size: 10px; color: #9F1239; }

    .clinical-grid {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-bottom: 8px;
    }
    .clinical-item {
      flex: 1 1 45%;
      font-size: 11px;
      background: #F8FAFC;
      border: 1px solid #E2E8F0;
      padding: 4px 8px;
      border-radius: 4px;
    }

    .footer-block {
      margin-top: 24px;
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      page-break-inside: avoid;
    }
    .review-box {
      font-size: 11px;
      border-left: 3px solid #0F766E;
      padding-left: 8px;
    }
    .signature-area {
      text-align: right;
      width: 200px;
    }
    .sig-line {
      border-top: 1px solid #0F172A;
      margin-top: 40px;
      padding-top: 4px;
      font-size: 11px;
      font-weight: bold;
    }
  </style>
</head>
<body>
  $headerHtml

  <!-- Patient Demographic Strip -->
  <div class="demographics-strip">
    <div class="demo-col">
      <div><strong>Patient:</strong> $patientName</div>
      <div><strong>Age / Sex:</strong> $ageDisplay</div>
    </div>
    <div class="demo-col">
      <div><strong>Token No:</strong> #$queueNo</div>
      <div><strong>Date:</strong> $visitDate</div>
    </div>
    <div class="demo-col" style="text-align: right;">
      <div><strong>Phone:</strong> $patientPhone</div>
      <div><strong>Doctor:</strong> $doctorName</div>
    </div>
  </div>

  $allergiesHtml
  $snapshotHtml

  <div class="rx-symbol">℞ Prescribed Medicines</div>
  $rxTableHtml

  $ordersAdviceHtml

  <div class="footer-block">
    <div class="review-box">
      ${consultation.nextFollowUpDate != null ? '<strong>Next Review:</strong> ${AppFormatters.date(consultation.nextFollowUpDate!)}' : '<strong>Next Review:</strong> SOS / As Needed'}
    </div>
    <div class="signature-area">
      <div class="sig-line">
        $doctorName<br>
        <span style="font-size: 10px; font-weight: normal; color: #475569;">$regNo</span>
      </div>
    </div>
  </div>
</body>
</html>''';
  }

  static String _buildClinicalSnapshotHtml(Consultation c) {
    final hasVitals = c.vitals != null && c.vitals!.hasAny;
    final hasComplaints = c.chiefComplaints.isNotEmpty;
    final hasDiagnoses = c.provisionalDiagnosis.isNotEmpty;
    final hasFindings = c.clinicalExamination != null && c.clinicalExamination!.trim().isNotEmpty;

    if (!hasVitals && !hasComplaints && !hasDiagnoses && !hasFindings) {
      return '';
    }

    final buffer = StringBuffer('<div class="clinical-grid">');

    if (hasComplaints) {
      buffer.write('<div class="clinical-item"><strong>C/O (Complaints):</strong> ${_escape(c.chiefComplaints.join(', '))}</div>');
    }
    if (hasDiagnoses) {
      buffer.write('<div class="clinical-item"><strong>Dx (Diagnosis):</strong> ${_escape(c.provisionalDiagnosis.join(', '))}</div>');
    }
    if (hasVitals) {
      final v = c.vitals!;
      final parts = <String>[];
      if (v.bpFormatted != null && v.bpFormatted!.isNotEmpty) parts.add('BP: ${v.bpFormatted}');
      if (v.pulseRate != null) parts.add('Pulse: ${v.pulseRate} bpm');
      if (v.spO2 != null) parts.add('SpO2: ${v.spO2}%');
      if (v.temperature != null) parts.add('Temp: ${v.temperature} °F');
      if (v.weightKg != null) parts.add('Weight: ${v.weightKg} kg');
      if (parts.isNotEmpty) {
        buffer.write('<div class="clinical-item"><strong>Vitals:</strong> ${_escape(parts.join(' | '))}</div>');
      }
    }
    if (hasFindings) {
      buffer.write('<div class="clinical-item"><strong>O/E (Examination):</strong> ${_escape(c.clinicalExamination!)}</div>');
    }

    buffer.write('</div>');
    return buffer.toString();
  }

  static String _buildRxTableHtml({
    required List<PrescriptionItem> activeMeds,
    required List<PrescriptionItem> stoppedMeds,
    required bool hideComposition,
  }) {
    if (activeMeds.isEmpty && stoppedMeds.isEmpty) {
      return '<div style="font-size: 11px; font-style: italic; color: #64748B; padding: 6px 0;">No active medications prescribed for this visit.</div>';
    }

    final buffer = StringBuffer();
    if (activeMeds.isNotEmpty) {
      buffer.write('''
      <table class="rx-table">
        <thead>
          <tr>
            <th class="col-med">Medicine Name & Generic Composition</th>
            <th class="col-dosage">Dosage & Timing</th>
            <th class="col-duration">Duration</th>
          </tr>
        </thead>
        <tbody>
      ''');

      for (final med in activeMeds) {
        final brand = _escape(med.effectiveName);
        final comp = _escape(med.composition.toUpperCase());
        final compDisplay = (!hideComposition && comp.isNotEmpty && brand.toUpperCase() != comp)
            ? '<span class="composition">[$comp]</span>'
            : '';

        final dosageParts = <String>[];
        if (med.dosage.trim().isNotEmpty) dosageParts.add(_escape(med.dosage.trim()));
        if (med.frequency.trim().isNotEmpty) dosageParts.add(_escape(med.frequency.trim()));
        if (med.timing.trim().isNotEmpty) dosageParts.add(_escape(med.timing.trim()));
        if (med.instructions != null && med.instructions!.trim().isNotEmpty) {
          dosageParts.add('<em>(${_escape(med.instructions!.trim())})</em>');
        }
        final dosageTiming = dosageParts.join(' • ');
        final duration = _escape(med.effectiveDuration);

        buffer.write('''
          <tr>
            <td class="col-med">$brand$compDisplay</td>
            <td class="col-dosage">$dosageTiming</td>
            <td class="col-duration">$duration</td>
          </tr>
        ''');
      }

      buffer.write('</tbody></table>');
    }

    if (stoppedMeds.isNotEmpty) {
      buffer.write('''
      <div style="font-size: 11px; font-weight: bold; color: #9F1239; margin-top: 6px;">DISCONTINUED MEDICATIONS (STOPPED THIS VISIT):</div>
      <table class="stopped-table">
        <thead>
          <tr>
            <th style="width: 50%;">Medicine</th>
            <th style="width: 30%;">Previous Regimen</th>
            <th style="width: 20%;">Reason</th>
          </tr>
        </thead>
        <tbody>
      ''');

      for (final med in stoppedMeds) {
        final brand = _escape(med.effectiveName);
        final reason = _escape(med.stopReason ?? 'Discontinued by physician');
        buffer.write('''
          <tr>
            <td style="text-decoration: line-through;">$brand</td>
            <td>${_escape(med.dosage)} • ${_escape(med.frequency)}</td>
            <td>$reason</td>
          </tr>
        ''');
      }
      buffer.write('</tbody></table>');
    }

    return buffer.toString();
  }

  static String _buildOrdersAndAdviceHtml(Consultation c) {
    final hasOrders = c.orderedTests.isNotEmpty;
    final hasAdvice = c.adviceNotes != null && c.adviceNotes!.trim().isNotEmpty;

    if (!hasOrders && !hasAdvice) return '';

    final buffer = StringBuffer();
    if (hasOrders) {
      buffer.write('<div class="section-title">Diagnostic Investigations / Lab Orders</div>');
      final ordersText = c.orderedTests.map((o) => o.instructions != null && o.instructions!.isNotEmpty ? '${o.testName} (${o.instructions})' : o.testName).join(', ');
      buffer.write('<div style="font-size: 11px; margin-bottom: 6px;">${_escape(ordersText)}</div>');
    }
    if (hasAdvice) {
      buffer.write('<div class="section-title">Advice & Dietary Instructions</div>');
      buffer.write('<div style="font-size: 11px; white-space: pre-line; margin-bottom: 6px;">${_escape(c.adviceNotes!)}</div>');
    }
    return buffer.toString();
  }

  static String _escape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }
}
