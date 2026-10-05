# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] — 2026-10-05

### Added
- **Flutter Web Platform Support** — Single responsive codebase deployed to web and mobile with responsive navigation rail for reception desktop PCs.
- **Doctor Chamber Live View (Catalog Mode)** — Zero-friction read-only chamber board for visiting consultants showing live token sequence, patient queue, and fee share tally.
- **Chamber & Reception PIN Authentication** — Quick, accountless PIN authentication with `SharedPreferences` session persistence.
- **Audit-Proof Appointments (Zero Deletions)** — Appointments cannot be deleted once created; token numbers remain strictly consecutive.
- **Explicit "Absent / No-Show" Status** — Replaced "Cancel" with "Absent" so slots are preserved on the doctor ledger with ₹0 amount.
- **Per-Doctor Consultation Fees & PINs** — Each doctor profile now stores their customized consultation fee and chamber PIN.
- **Firebase Hosting Configuration** — Added single-page app hosting configuration in `firebase.json`.
- **Chamber Preview for Reception** — Clinic owner can preview the live chamber view for any registered doctor.

### Changed
- `AppointmentStatus`: Added `absent` status with graceful backward-compatible deserialization of legacy `cancelled` records.
- `lib/main.dart`: Integrated `AuthGate` routing between `OwnerShell`, `DoctorChamberScreen`, and `LoginScreen`.

---

## [1.1.0] — 2026-10-04

### Added
- `dispose()` in `ClinicProvider` to properly cancel Firestore stream subscriptions and prevent memory leaks
- `AppConstants.defaultConsultationFee` — single source of truth for the consultation fee (₹500)
- Atomic queue number generation using Firestore transactions — prevents duplicate queue numbers on concurrent bookings
- Backward-compatible Firestore `Timestamp` storage for `scheduledDate` — new documents store a proper Timestamp; old ISO-string documents still parse correctly
- Live "Pending Appointments" card on dashboard replacing placeholder stub
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `LICENSE` (MIT) — FOSS release preparation
- `lib/firebase_options.dart.example` — template for contributors to configure Firebase

### Fixed
- **`_isExpanded` unused field** in `AppointmentAccordion` — field removed; `ExpansionTile` manages its own expansion state
- **Unsafe casts in `Patient.fromJson`** — all fields now use null-safe fallbacks (`as String? ?? ''`, `(as num?)?.toInt() ?? 0`); corrupt Firestore documents no longer crash the patient stream
- **Unsafe casts in `Doctor.fromJson`** — same defensive pattern applied
- **Doctor ID collision risk** — switched from `millisecondsSinceEpoch.toString()` to `Uuid.v4()`
- **No-op `subtract(Duration(days: 0))`** removed from date picker in `AddAppointmentDialog`
- **`PaymentType.paid` dropdown label** now shows `"Paid (₹500)"` instead of `"PAID"`
- **Stale blocked dates** (`2024-12-25`, `2025-01-01`) removed from `AppConstants`; `isDateBlocked()` no longer uses a fragile ISO-split
- **Stub UI actions removed** — removed non-functional placeholder buttons in doctor list

### Changed
- `firebase_options.dart` added to `.gitignore` — credentials/keys excluded from version control
- Firestore date range queries now use `Timestamp` objects instead of ISO strings
- Removed stale default Flutter counter test (`test/widget_test.dart`)

---

## [1.0.0] — 2026-10-03 *(pre-FOSS internal release)*

### Added
- Dashboard screen with appointment count, daily revenue, doctor count
- Appointment booking dialog with phone-based patient lookup
- Multi-doctor support with per-doctor appointment tracking
- Daily statistics screen grouped by doctor
- Doctor daily detail drill-down screen
- Real-time Firestore streams for appointments and doctors
- Patient auto-fill from phone number with last-visit date display
- "Free Review" auto-detection (visit within 15 days)
- Appointment status management (pending / completed / cancelled)
- Appointment list with date navigation and "show completed" toggle
