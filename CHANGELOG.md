# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.0] — 2026-10-07

### Added
- **Longitudinal Prescription Architecture & Append-Only Consultations** — Complete implementation of the clinical record architecture treating consultations as immutable historical encounters.
- **5-Step Clinical Sequence Encounter UI (`ConsultationEncounterScreen`)** — Strict clinical workflow: Patient Header + Allergies Alert ➔ Vitals & Clinical Examination ➔ Diagnostic Lab Review ➔ Medication Reconciliation & Prescribing ➔ Advice & Lab Orders.
- **Medication Reconciliation State Machine** — Explicit lifecycle states (`START`, `CONTINUE`, `STOP`) on prescription items. 1-click continuation for ongoing chronic regimens (`durationDays = null`) and explicit discontinuation documenting clinical `stopReason`.
- **Zero-Friction Outside / Unlisted Medicine Fallback (`unlistedName`)** — Doctors are never blocked when prescribing outside or brand medications missing from the clinic catalogue.
- **Composition-First Medicine Search & Scoring Engine (`MedicineSearchScorer`)** — Prioritizes chemical molecule matches at the top with associated clinic brands grouped underneath, offering 1-tap generic and brand prescribing chips.
- **Default Essential OPD Medicines (`lib/utils/default_medicines.dart`)** — Standard OPD medications (Dolo 650, Calpol 650, Augmentin 625 Duo, Moxikind-CV, Azee 500, Azithral 500, Pan 40, Telma 40, etc.) exist by default with deterministic document IDs (`med_*`), guaranteeing zero-duplicate idempotency.
- **Master Medicine Catalogue Management (`MedicineCatalogueScreen`)** — Dedicated administration interface in reception shell for clinic owners to curate products, active compositions, strengths, and forms with strict role guards preventing chamber prescriber pollution.
- **Automated & On-Demand Catalogue Deduplication Engine** — Scans master medicines, identifies duplicate products with identical name, composition, and strength, and batch-purges duplicates from Firestore.
- **Clean Prescription Print Output (`PrescriptionPrintScreen`)** — High-contrast monochrome print layout supporting A4 and A5 paper, with pre-printed letterhead mode (reserved 130px margin), active Rx schedule filtering (START/CONTINUE only), and distinct audit warning box for discontinued drugs.
- **Responsive Clinic Command Center Dashboard (`DashboardScreen`)** — Redesigned legacy 4-block mobile view into a modern, responsive command center with compact horizontal KPI cards, live queue preview, quick reception actions, and dynamic adaptation across mobile (iPhones), 14" laptops, and 23" FHD desktop monitors.
- **First-Class Patient Gender / Sex Intake** — Upgraded `gender` to a required clinical field across `Patient`, `Consultation`, and `AddAppointmentDialog`.

### Removed
- **Nuked Legacy Compatibility Shims & Fallbacks** — Removed stream-intercepting background hacks (`_hasCheckedDefaultsAndDuplicates`), legacy fallback defaults (`this.gender = 'Unspecified'`), defensive string parsing fallbacks, and legacy compatibility test suites in favor of strongly-typed models.

---

## [1.3.0] — 2026-10-06

### Added
- **Same-Doctor Free Review Rule & 14-Day Limit** — Only returning patients who previously visited the *same doctor* qualify for a Free Review. First-time patients and patients with no prior history under the selected doctor have the Free Review option cleanly disabled with a descriptive hint.
- **14-Day Free Review Warning Dialog** — If more than 14 days have passed since the patient's previous visit with the selected doctor, the Free Review option remains selectable (not disabled) but immediately triggers an explicit confirmation warning dialog detailing the last visit date and days elapsed.
- **Persistent Amber Policy Warning** — Prominent warning banner in appointment booking dialog when Free Review is manually approved beyond the 14-day limit.
- **Firestore Indexes Configuration (`firestore.indexes.json`)** — Added index definitions for `appointments` and `consultations` collections.

### Fixed
- **Doctor Chamber View Index Error** — Resolved Cloud Firestore composite index error on Doctor Chamber screen by querying per-day appointments and filtering by doctor in memory without requiring remote composite indexes.

---

## [1.2.0] — 2026-10-05

### Added
- **Flutter Web Platform Support** — Single responsive codebase deployed to web and mobile with responsive navigation rail for reception desktop PCs (`OwnerShell`).
- **Doctor Chamber Live View (Catalog Mode)** — Zero-friction read-only chamber board for visiting consultants showing live token sequence, patient queue, and fee share tally.
- **Chamber & Reception PIN Authentication** — Quick, accountless PIN authentication with `SharedPreferences` session persistence.
- **Audit-Proof Appointments (Zero Deletions)** — Appointments cannot be deleted once created; token numbers remain strictly consecutive.
- **Explicit "Absent / No-Show" Status** — Replaced deletion with `[ABSENT]` status so slots are preserved on the doctor ledger with ₹0 amount.
- **Per-Doctor Consultation Fees & PINs** — Each doctor profile stores their customized consultation fee and chamber PIN.
- **Firebase Hosting Configuration** — Added single-page app hosting configuration in `firebase.json`.
- **Chamber Preview for Reception** — Clinic owner can preview the live chamber view for any registered doctor.

---

## [1.1.0] — 2026-10-04

### Added
- **Atomic Queue Number Generation** — Race-condition-safe daily queue numbers using Firestore transactions.
- **Firestore Native Timestamp Storage** — Appointment scheduled dates stored natively as Firestore `Timestamp` objects.
- **Clinic Holiday Blocking** — Configurable blocked dates (`AppConstants.blockedDates`) preventing bookings on clinic closures.
- **Stream Subscription Lifecycle Management** — Added proper stream subscription cancellation in `ClinicProvider.dispose()`.
- **Centralized Consultation Fee** — Single source of truth for fallback consultation fees (`AppConstants.defaultConsultationFee`).
- **Open-Source Repository Templates** — Added `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `LICENSE` (MIT).

---

## [1.0.0] — 2026-10-03

### Initial Release
- **Outpatient Appointment Booking** — Rapid walk-in appointment registration with 10-digit phone search and patient history autofill.
- **Multi-Doctor Chamber Support** — Registration and scheduling across multiple visiting consultants with per-doctor queues.
- **Real-Time Data Sync** — Real-time Firestore streams syncing reception desk actions and doctor chamber views.
- **Daily Revenue & Payout Analytics** — Breakdown of realized clinic earnings grouped by doctor.
