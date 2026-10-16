import 'package:appointment_app/core/engines/engines.dart';
import 'package:appointment_app/models/models.dart';
import 'package:appointment_app/screens/add_doctor_screen.dart';
import 'package:appointment_app/widgets/booking/booking_duplicate_warning_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Doctor Leave System & Planned Absence Engine Tests', () {
    final leaveDoc = Doctor(
      id: 'doc-leave-1',
      name: 'Dr. Bhaskar Thakuria',
      specialty: 'Cardiology',
      phone: '9876543210',
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      blockedDates: [
        DateTime(2026, 10, 18), // Single isolated day
        DateTime(2026, 10, 22), // 2-day leave part 1
        DateTime(2026, 10, 23), // 2-day leave part 2
        DateTime(2026, 11, 1), // Week-long extended leave part 1
        DateTime(2026, 11, 2), // part 2
        DateTime(2026, 11, 3), // part 3
        DateTime(2026, 11, 4), // part 4
        DateTime(2026, 11, 5), // part 5
        DateTime(2026, 11, 6), // part 6
        DateTime(2026, 11, 7), // part 7
      ],
    );

    test('isDoctorOnLeave returns true for exact leave dates and false for normal days', () {
      expect(
        AppointmentEngine.isDoctorOnLeave(
          doctor: leaveDoc,
          date: DateTime(2026, 10, 18, 14, 30), // Time component ignored
        ),
        isTrue,
      );

      expect(
        AppointmentEngine.isDoctorOnLeave(
          doctor: leaveDoc,
          date: DateTime(2026, 10, 19),
        ),
        isFalse,
      );

      expect(
        AppointmentEngine.isDoctorOnLeave(
          doctor: null,
          date: DateTime(2026, 10, 18),
        ),
        isFalse,
      );
    });

    test('formatDoctorLeaveSummary formats 1 single leave day as "Doctor is on leave on DD-MM-YYYY"', () {
      final summary = AppointmentEngine.formatDoctorLeaveSummary(
        doctor: leaveDoc,
        date: DateTime(2026, 10, 18),
      );
      expect(summary, 'Doctor is on leave on 18-10-2026');
    });

    test('formatDoctorLeaveSummary formats 2 consecutive leave days as "Doctor is on leave on xyz and abc"', () {
      final summaryDay1 = AppointmentEngine.formatDoctorLeaveSummary(
        doctor: leaveDoc,
        date: DateTime(2026, 10, 22),
      );
      expect(summaryDay1, 'Doctor is on leave on 22-10-2026 and 23-10-2026');

      final summaryDay2 = AppointmentEngine.formatDoctorLeaveSummary(
        doctor: leaveDoc,
        date: DateTime(2026, 10, 23),
      );
      expect(summaryDay2, 'Doctor is on leave on 22-10-2026 and 23-10-2026');
    });

    test('formatDoctorLeaveSummary formats extended leave (week) as "Doctor is on leave from xyz to abc"', () {
      final summaryStart = AppointmentEngine.formatDoctorLeaveSummary(
        doctor: leaveDoc,
        date: DateTime(2026, 11, 1),
      );
      expect(summaryStart, 'Doctor is on leave from 01-11-2026 to 07-11-2026');

      final summaryMid = AppointmentEngine.formatDoctorLeaveSummary(
        doctor: leaveDoc,
        date: DateTime(2026, 11, 4),
      );
      expect(summaryMid, 'Doctor is on leave from 01-11-2026 to 07-11-2026');

      final summaryEnd = AppointmentEngine.formatDoctorLeaveSummary(
        doctor: leaveDoc,
        date: DateTime(2026, 11, 7),
      );
      expect(summaryEnd, 'Doctor is on leave from 01-11-2026 to 07-11-2026');
    });

    test(
      'formatDoctorLeaveSummary returns null when doctor is not on leave',
      () {
        final summary = AppointmentEngine.formatDoctorLeaveSummary(
          doctor: leaveDoc,
          date: DateTime(2026, 10, 20),
        );
        expect(summary, isNull);
      },
    );

    testWidgets(
      'BookingDoctorLeaveWarningBanner displays custom leave summary and blocked indicator',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingDoctorLeaveWarningBanner(
                doctor: leaveDoc,
                date: DateTime(2026, 11, 3),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            '🚫 Doctor is on leave from 01-11-2026 to 07-11-2026. Appointments cannot be booked on doctor leave dates.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.block), findsOneWidget);
      },
    );

    testWidgets(
      'DoctorForm displays Planned Leave & Blocked Dates section with Add buttons and chips',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final doctorWithLeaves = Doctor(
          id: 'doc-leave-ui',
          name: 'Dr. Leave Test',
          specialty: 'General Medicine / Physician',
          phone: '9876543210',
          availableDays: ['Mon', 'Tue'],
          blockedDates: [DateTime(2026, 10, 25), DateTime(2026, 10, 26)],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DoctorForm(doctor: doctorWithLeaves, onSaved: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Planned Leave & Blocked Dates'), findsOneWidget);
        expect(find.text('Add Day'), findsOneWidget);
        expect(find.text('Add Week / Range'), findsOneWidget);
        expect(find.text('25-10-2026'), findsOneWidget);
        expect(find.text('26-10-2026'), findsOneWidget);
      },
    );
  });
}
