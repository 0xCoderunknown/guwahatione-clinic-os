import '../../models/models.dart';
import '../../utils/formatters.dart';

/// Pure Dart domain engine for generating structured WhatsApp prescription messages
/// and direct WhatsApp deep links (wa.me) for patient delivery without SMS gateway costs.
class WhatsAppEngine {
  WhatsAppEngine._();

  /// Normalizes Indian 10-digit or prefixed mobile numbers to '91XXXXXXXXXX'.
  static String normalizeIndianPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '91$digits';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }
    if (digits.length > 10 && digits.startsWith('0')) {
      return '91${digits.substring(1)}';
    }
    return digits;
  }

  /// Formats an append-only Consultation into a human-readable, WhatsApp-formatted clinical summary.
  static String formatPrescriptionMessage({
    required Consultation consultation,
    int? queueNumber,
    String clinicName = 'GuwahatiOne Clinic',
  }) {
    final buffer = StringBuffer();

    // 1. Header
    buffer.writeln('*$clinicName — Digital Prescription*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 2. Demographics & Doctor
    final dateStr = AppFormatters.date(consultation.createdAt);
    final tokenPart = queueNumber != null ? ' | Token: #$queueNumber' : '';
    buffer.writeln('🗓️ Date: $dateStr$tokenPart');
    final ageStr = consultation.patientAgeDisplay ??
        (consultation.patientAge > 0 ? '${consultation.patientAge}y' : 'N/A');
    final guardianStr = (consultation.guardianName != null &&
            consultation.guardianName!.trim().isNotEmpty)
        ? ' (c/o ${consultation.guardianName}${consultation.guardianRelation != null && consultation.guardianRelation!.trim().isNotEmpty ? ", ${consultation.guardianRelation}" : ""})'
        : '';
    buffer.writeln(
      '👤 Patient: ${consultation.patientName}$guardianStr ($ageStr, ${consultation.patientGender})',
    );
    buffer.writeln('📞 Contact: ${consultation.patientPhone}');
    buffer.writeln('👨‍⚕️ Doctor: ${consultation.doctorName}');
    if (consultation.doctorRegNumber != null &&
        consultation.doctorRegNumber!.trim().isNotEmpty) {
      buffer.writeln('📋 Reg. No: ${consultation.doctorRegNumber!.trim()}');
    }

    // 3. Vitals (if recorded)
    final v = consultation.vitals;
    if (v != null && v.hasAny) {
      final vitalsParts = <String>[];
      if (v.bpFormatted != null) vitalsParts.add('BP: ${v.bpFormatted}');
      if (v.pulseRate != null) vitalsParts.add('Pulse: ${v.pulseRate} bpm');
      if (v.spO2 != null) vitalsParts.add('SpO2: ${v.spO2}%');
      if (v.temperature != null) vitalsParts.add('Temp: ${v.temperature}°F');
      if (v.weightKg != null) vitalsParts.add('Wt: ${v.weightKg} kg');
      if (v.bloodSugar != null) {
        vitalsParts.add('Blood Sugar: ${v.bloodSugar} mg/dL');
      }

      if (vitalsParts.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('🩺 *Vitals:* ${vitalsParts.join(' | ')}');
      }
    }

    // 4. Provisional Diagnosis
    if (consultation.provisionalDiagnosis.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        '🔬 *Diagnosis:* ${consultation.provisionalDiagnosis.join(', ')}',
      );
    }

    // 5. Prescribed Medications (START & CONTINUE)
    final activeMeds = consultation.prescriptionItems
        .where(
          (item) =>
              item.action == MedicationAction.start ||
              item.action == MedicationAction.continueAction,
        )
        .toList();

    if (activeMeds.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('💊 *Prescribed Medications:*');
      for (var i = 0; i < activeMeds.length; i++) {
        final med = activeMeds[i];
        final actionTag = med.action == MedicationAction.continueAction
            ? ' _[Ongoing]_'
            : '';
        final durationPart = med.durationDays != null
            ? ' • ${med.durationDays} Days'
            : ' • Chronic/Ongoing';

        buffer.writeln('${i + 1}. *${med.medicineName}*$actionTag');
        buffer.writeln(
          '   ${med.dosage} (${med.frequency}) • ${med.timing}$durationPart',
        );
        if (med.instructions != null && med.instructions!.trim().isNotEmpty) {
          buffer.writeln('   _Note: ${med.instructions!.trim()}_');
        }
      }
    }

    // Discontinued Medications (STOP)
    final stoppedMeds = consultation.prescriptionItems
        .where((item) => item.action == MedicationAction.stop)
        .toList();
    if (stoppedMeds.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('⚠️ *Discontinued Medications (STOP):*');
      for (final med in stoppedMeds) {
        final reason =
            med.stopReason != null && med.stopReason!.trim().isNotEmpty
            ? ' (${med.stopReason!.trim()})'
            : '';
        buffer.writeln('• ~${med.medicineName}~$reason');
      }
    }

    // 6. Ordered Diagnostic Tests
    if (consultation.orderedTests.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('🧪 *Diagnostic Orders:*');
      for (final test in consultation.orderedTests) {
        buffer.writeln('• ${test.testName}');
      }
    }

    // 7. Advice Notes
    if (consultation.adviceNotes != null &&
        consultation.adviceNotes!.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 *Doctor Advice:*');
      buffer.writeln(consultation.adviceNotes!.trim());
    }

    // 8. Follow-up / Next Review Date
    if (consultation.nextFollowUpDate != null) {
      final reviewDateStr = AppFormatters.date(consultation.nextFollowUpDate);
      buffer.writeln();
      buffer.writeln('🗓️ *Next Review Date:* $reviewDateStr');
      buffer.writeln('_(Within 14 days qualifies for Free Follow-Up Review)_');
    }

    // 9. Footer
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
      '📌 _Please follow doctor instructions carefully. For emergencies, contact the clinic._',
    );

    return buffer.toString();
  }

  /// Builds a standard WhatsApp deep link URL: `https://wa.me/<phone>?text=<encodedMessage>`
  static String buildDeepLink({
    required String phone,
    required String message,
  }) {
    final normalized = normalizeIndianPhone(phone);
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$normalized?text=$encoded';
  }
}
