import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosticInvestigationReview {
  final String id;
  final String testName; // e.g., 'HbA1c', 'Thyroid Profile'
  final String resultValue; // e.g., '6.8%', 'TSH: 4.2 uIU/mL'
  final DateTime? performedDate; // Date when the lab test was conducted
  final String? notes; // Optional observations

  const DiagnosticInvestigationReview({
    required this.id,
    required this.testName,
    required this.resultValue,
    this.performedDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testName': testName,
      'resultValue': resultValue,
      'performedDate': performedDate != null
          ? Timestamp.fromDate(performedDate!)
          : null,
      'notes': notes,
    };
  }

  factory DiagnosticInvestigationReview.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['performedDate'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return DiagnosticInvestigationReview(
      id: json['id'] as String? ?? '',
      testName: json['testName'] as String? ?? '',
      resultValue: json['resultValue'] as String? ?? '',
      performedDate: parsedDate,
      notes: json['notes'] as String?,
    );
  }

  DiagnosticInvestigationReview copyWith({
    String? id,
    String? testName,
    String? resultValue,
    DateTime? performedDate,
    String? notes,
  }) {
    return DiagnosticInvestigationReview(
      id: id ?? this.id,
      testName: testName ?? this.testName,
      resultValue: resultValue ?? this.resultValue,
      performedDate: performedDate ?? this.performedDate,
      notes: notes ?? this.notes,
    );
  }
}

class OrderedTest {
  final String testName; // e.g., 'Fasting Blood Sugar', 'Serum Creatinine'
  final String? instructions; // e.g., 'Overnight 10-12 hrs fasting'

  const OrderedTest({
    required this.testName,
    this.instructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'instructions': instructions,
    };
  }

  factory OrderedTest.fromJson(Map<String, dynamic> json) {
    return OrderedTest(
      testName: json['testName'] as String? ?? '',
      instructions: json['instructions'] as String?,
    );
  }
}
