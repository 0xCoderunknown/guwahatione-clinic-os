import '../../models/appointment.dart';
import '../../models/consultation.dart';
import '../../models/medicine.dart';
import '../../models/patient.dart';

/// Pure Dart RFC-4180 compliant CSV serialization engine for clinic data export.
/// Zero Flutter UI dependencies. Strictly enforces Indian date formatting (DD-MM-YYYY).
class DataExportEngine {
  DataExportEngine._();

  /// Formats a DateTime object as DD-MM-YYYY.
  static String formatIndianDate(DateTime? dt) {
    if (dt == null) return '';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day-$month-$year';
  }

  /// Formats a DateTime object as HH:mm (24-hour Indian Standard Time).
  static String formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Escapes a CSV cell value according to RFC-4180:
  /// - Null is treated as empty string.
  /// - If the string contains comma, double-quote, or newline, it is wrapped in double quotes.
  /// - Any double quotes inside the string are escaped by doubling them ("").
  static String escapeCsvCell(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  /// Converts a row of cells into an RFC-4180 CSV line.
  static String toCsvRow(List<dynamic> cells) {
    return cells.map(escapeCsvCell).join(',');
  }

  /// Serializes appointments to an audit-ready CSV.
  static String exportAppointmentsCsv(List<Appointment> appointments) {
    final buffer = StringBuffer();
    final headers = [
      'Date (DD-MM-YYYY)',
      'Token #',
      'Check-in Time',
      'Patient Name',
      'Phone Number',
      'Age',
      'Doctor Name',
      'Visit Status',
      'Payment Status',
      'Amount Collected (INR)',
      'Appointment ID',
    ];
    buffer.writeln(toCsvRow(headers));

    for (final appt in appointments) {
      final row = [
        formatIndianDate(appt.scheduledDate),
        appt.queueNumber,
        formatTime(appt.checkedInAt),
        appt.patientName,
        appt.patientPhone,
        appt.patientAgeDisplay ?? '',
        appt.doctorName,
        appt.visitStatus.displayName,
        appt.paymentType.displayName,
        appt.amountCollected,
        appt.id,
      ];
      buffer.writeln(toCsvRow(row));
    }
    return buffer.toString();
  }

  /// Serializes financial revenue ledger for tax and accountant audits.
  static String exportRevenueLedgerCsv(List<Appointment> appointments) {
    final buffer = StringBuffer();
    final headers = [
      'Date (DD-MM-YYYY)',
      'Token #',
      'Patient Name',
      'Phone Number',
      'Doctor Name',
      'Payment Category',
      'Payment Method',
      'Fee Amount (INR)',
      'Appointment ID',
    ];
    buffer.writeln(toCsvRow(headers));

    int totalRevenue = 0;
    int totalCash = 0;
    int totalUpi = 0;
    int totalWaived = 0;

    for (final appt in appointments) {
      final isCash = appt.paymentType == PaymentType.paidCash;
      final isUpi = appt.paymentType == PaymentType.paidUpi;
      final isWaived = appt.paymentType.isFree;

      if (isCash) totalCash += appt.amountCollected;
      if (isUpi) totalUpi += appt.amountCollected;
      if (isWaived) totalWaived++;
      totalRevenue += appt.amountCollected;

      final row = [
        formatIndianDate(appt.scheduledDate),
        appt.queueNumber,
        appt.patientName,
        appt.patientPhone,
        appt.doctorName,
        appt.paymentType.displayName,
        isCash
            ? 'Cash'
            : (isUpi
                ? 'UPI'
                : (isWaived ? 'Waived / Free' : appt.paymentType.name)),
        appt.amountCollected,
        appt.id,
      ];
      buffer.writeln(toCsvRow(row));
    }

    // Append summary footer rows
    buffer.writeln();
    buffer.writeln(
      toCsvRow(['--- SUMMARY ---', '', '', '', '', '', '', '', '']),
    );
    buffer.writeln(toCsvRow(['Total Cash (INR)', totalCash]));
    buffer.writeln(toCsvRow(['Total UPI (INR)', totalUpi]));
    buffer.writeln(toCsvRow(['Total Waived / Free Visits', totalWaived]));
    buffer.writeln(toCsvRow(['Net Total Collected (INR)', totalRevenue]));

    return buffer.toString();
  }

  /// Serializes patient directory to CSV.
  static String exportPatientsCsv(List<Patient> patients) {
    final buffer = StringBuffer();
    final headers = [
      'Patient ID',
      'Name',
      'Phone Number',
      'Age',
      'Gender',
      'Guardian Name',
      'Guardian Relation',
      'Allergies',
      'Last Visit Date (DD-MM-YYYY)',
    ];
    buffer.writeln(toCsvRow(headers));

    for (final pat in patients) {
      final row = [
        pat.id,
        pat.name,
        pat.phoneNumber,
        pat.formattedAge,
        pat.gender,
        pat.guardianName ?? '',
        pat.guardianRelation ?? '',
        pat.allergies.join('; '),
        formatIndianDate(pat.lastVisitDate),
      ];
      buffer.writeln(toCsvRow(row));
    }
    return buffer.toString();
  }

  /// Serializes master medicine catalogue to CSV.
  static String exportMedicinesCsv(List<Medicine> medicines) {
    final buffer = StringBuffer();
    final headers = [
      'Medicine ID',
      'Product Name / Brand',
      'Composition (Generic)',
      'Manufacturer',
      'Default Dosage',
      'Default Frequency',
      'Default Timing',
      'Default Duration',
    ];
    buffer.writeln(toCsvRow(headers));

    for (final med in medicines) {
      final row = [
        med.id,
        med.productName,
        med.composition,
        med.manufacturer ?? '',
        med.defaultDosage ?? '',
        med.defaultFrequency ?? '',
        med.defaultTiming ?? '',
        med.durationLabel,
      ];
      buffer.writeln(toCsvRow(row));
    }
    return buffer.toString();
  }

  /// Serializes clinical consultation encounter records to CSV.
  static String exportConsultationsCsv(List<Consultation> consultations) {
    final buffer = StringBuffer();
    final headers = [
      'Consultation Date (DD-MM-YYYY)',
      'Patient Name',
      'Phone Number',
      'Age',
      'Gender',
      'Doctor Name',
      'Doctor Reg No',
      'Chief Complaints',
      'Provisional Diagnosis',
      'Prescribed Medicines (Count)',
      'Prescriptions Detail',
      'Ordered Investigations',
      'Follow-Up Date (DD-MM-YYYY)',
      'Consultation ID',
    ];
    buffer.writeln(toCsvRow(headers));

    for (final c in consultations) {
      final rxDetails = c.prescriptionItems.map((item) {
        return '${item.medicineName} (${item.dosage} • ${item.frequency} • ${item.timing} • ${item.durationText})';
      }).join('; ');

      final tests = c.orderedTests.map((t) => t.testName).join('; ');

      final row = [
        formatIndianDate(c.createdAt),
        c.patientName,
        c.patientPhone,
        c.patientAgeDisplay ?? c.patientAge.toString(),
        c.patientGender,
        c.doctorName,
        c.doctorRegNumber ?? '',
        c.chiefComplaints.join('; '),
        c.provisionalDiagnosis.join('; '),
        c.prescriptionItems.length,
        rxDetails,
        tests,
        formatIndianDate(c.nextFollowUpDate),
        c.id,
      ];
      buffer.writeln(toCsvRow(row));
    }
    return buffer.toString();
  }
}
