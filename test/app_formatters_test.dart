import 'package:appointment_app/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFormatters Clinical Invariant & Indian Date Tests', () {
    final sampleDateTime = DateTime(
      2026,
      10,
      12,
      16,
      45,
    ); // Monday, 12-10-2026 4:45 PM

    test('date formats strictly to Indian DD-MM-YYYY format', () {
      expect(AppFormatters.date(sampleDateTime), '12-10-2026');
      expect(AppFormatters.date(null), '—');
      expect(AppFormatters.date(null, fallback: 'N/A'), 'N/A');
    });

    test('time formats to 12-hour hh:mm a format', () {
      expect(AppFormatters.time(sampleDateTime), '04:45 PM');
      expect(AppFormatters.time(null), '—');
    });

    test('dateTime combines Indian date and 12-hour time', () {
      expect(AppFormatters.dateTime(sampleDateTime), '12-10-2026, 04:45 PM');
      expect(AppFormatters.dateTime(null), '—');
    });

    test('dateWithDay prefixes full day of week to Indian date', () {
      expect(AppFormatters.dateWithDay(sampleDateTime), 'Monday, 12-10-2026');
      expect(AppFormatters.dateWithDay(null), '—');
    });

    test('compactDate formats to compact Indian DD-MM-YY', () {
      expect(AppFormatters.compactDate(sampleDateTime), '12-10-26');
      expect(AppFormatters.compactDate(null), '—');
    });

    test(
      'isoDate generates internal Firestore counter key string (yyyy-MM-dd)',
      () {
        expect(AppFormatters.isoDate(sampleDateTime), '2026-10-12');
        expect(AppFormatters.isoDate(null), '');
      },
    );

    test(
      'currency formats Indian Rupee amounts with integer and decimal handling',
      () {
        expect(AppFormatters.currency(500), '₹500');
        expect(AppFormatters.currency(750.0), '₹750');
        expect(AppFormatters.currency(650.50), '₹650.50');
        expect(AppFormatters.currency(0), '₹0');
        expect(AppFormatters.currency(null), '₹0');
      },
    );

    test('doctorTitle prevents duplicate Dr prefixes and normalizes title', () {
      expect(AppFormatters.doctorTitle('Bhaskar Baruah'), 'Dr. Bhaskar Baruah');
      expect(
        AppFormatters.doctorTitle('Dr. Bhaskar Baruah'),
        'Dr. Bhaskar Baruah',
      );
      expect(
        AppFormatters.doctorTitle('dr. Bhaskar Baruah'),
        'Dr. Bhaskar Baruah',
      );
      expect(
        AppFormatters.doctorTitle('Dr Bhaskar Baruah'),
        'Dr. Bhaskar Baruah',
      );
      expect(
        AppFormatters.doctorTitle('Dr. Dr. Bhaskar Baruah'),
        'Dr. Bhaskar Baruah',
      );
      expect(AppFormatters.doctorTitle(''), 'Doctor');
      expect(AppFormatters.doctorTitle(null), 'Doctor');
    });

    test('cleanDoctorName extracts stripped name without title', () {
      expect(
        AppFormatters.cleanDoctorName('Bhaskar Baruah'),
        'Bhaskar Baruah',
      );
      expect(
        AppFormatters.cleanDoctorName('Dr. Bhaskar Baruah'),
        'Bhaskar Baruah',
      );
      expect(
        AppFormatters.cleanDoctorName('dr. Bhaskar Baruah'),
        'Bhaskar Baruah',
      );
      expect(
        AppFormatters.cleanDoctorName('Dr Bhaskar Baruah'),
        'Bhaskar Baruah',
      );
      expect(
        AppFormatters.cleanDoctorName('Dr. Dr. Bhaskar Baruah'),
        'Bhaskar Baruah',
      );
      expect(AppFormatters.cleanDoctorName(''), '');
      expect(AppFormatters.cleanDoctorName(null), '');
    });

    test('specialty sanitizes common typos and empty fallbacks', () {
      expect(AppFormatters.specialty('Paedetrician'), 'Paediatrician');
      expect(
        AppFormatters.specialty('paedetric Medicine'),
        'Paediatric Medicine',
      );
      expect(AppFormatters.specialty('Cardiology'), 'Cardiology');
      expect(AppFormatters.specialty(''), 'General');
      expect(AppFormatters.specialty(null), 'General');
    });

    test('doctorInitials generates clean 2-letter uppercase initials', () {
      expect(AppFormatters.doctorInitials('Dr. Bhaskar Thakuria'), 'BT');
      expect(AppFormatters.doctorInitials('Bhaskar Thakuria'), 'BT');
      expect(AppFormatters.doctorInitials('Dr. Sharma'), 'SH');
      expect(AppFormatters.doctorInitials('Dr.'), 'DR');
      expect(AppFormatters.doctorInitials(''), '');
      expect(AppFormatters.doctorInitials(null), '');
    });
  });
}
