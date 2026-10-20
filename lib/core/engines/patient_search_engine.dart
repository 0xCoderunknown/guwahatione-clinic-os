import '../../models/patient.dart';

/// Pure Dart search, tokenization, and ranking intelligence for Patient Directory.
///
/// Zero Flutter UI dependencies.
abstract class PatientSearchEngine {
  /// Normalizes a query or phone string by stripping spaces and non-digit characters
  /// if inspecting phone numbers, or trimming and lowercasing for text search.
  static String normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length > 10) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length > 10) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Splits a name into individual lowercase searchable tokens (first name, surname, initials).
  static List<String> tokenizeName(String name) {
    return name
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Returns true if [query] matches the patient by phone, canonical ID, full name, or surname.
  static bool matches(Patient patient, String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return false;

    // 1. Phone match (exact, prefix, or normalized substring)
    final queryDigits = normalizePhone(clean);
    if (queryDigits.isNotEmpty) {
      final patientPhone = normalizePhone(patient.phoneNumber);
      if (patientPhone.contains(queryDigits)) {
        return true;
      }
    }

    // 2. Exact or prefix match on Canonical Patient ID (e.g. pat_*)
    if (patient.id.toLowerCase().contains(clean)) {
      return true;
    }

    // 3. Name or Surname substring / prefix match
    final patientNameLower = patient.name.trim().toLowerCase();
    if (patientNameLower.contains(clean)) {
      return true;
    }

    // 4. Token-level matching (e.g. searching 'Sharma' matches 'Ratul Sharma')
    final tokens = tokenizeName(patient.name);
    for (final token in tokens) {
      if (token.startsWith(clean) || token.contains(clean)) {
        return true;
      }
    }

    return false;
  }

  /// Filters and ranks a list of patients against a search query.
  /// Exact phone matches rank highest, followed by exact name matches, surname matches, and partials.
  static List<Patient> filterAndRank(List<Patient> patients, String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return const [];

    final cleanDigits = normalizePhone(clean);

    final scored = <MapEntry<Patient, int>>[];

    for (final patient in patients) {
      if (!matches(patient, clean)) continue;

      int score = 0;
      final phoneNorm = normalizePhone(patient.phoneNumber);
      final nameLower = patient.name.trim().toLowerCase();
      final tokens = tokenizeName(patient.name);

      if (cleanDigits.isNotEmpty && phoneNorm == cleanDigits) {
        score = 100; // Exact phone match
      } else if (cleanDigits.isNotEmpty && phoneNorm.startsWith(cleanDigits)) {
        score = 80; // Phone prefix match
      } else if (nameLower == clean) {
        score = 90; // Exact name match
      } else if (nameLower.startsWith(clean)) {
        score = 75; // First name prefix match
      } else if (tokens.any((t) => t.startsWith(clean))) {
        score = 70; // Surname prefix match (e.g. "Sharma")
      } else if (nameLower.contains(clean)) {
        score = 50; // Name substring match
      } else {
        score = 30; // General partial match
      }

      scored.add(MapEntry(patient, score));
    }

    scored.sort((a, b) {
      if (b.value != a.value) {
        return b.value.compareTo(a.value);
      }
      return a.key.name.compareTo(b.key.name);
    });

    return scored.map((e) => e.key).toList();
  }
}
