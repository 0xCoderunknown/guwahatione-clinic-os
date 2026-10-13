# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.23.0] — 13-10-2026

### Unified Desk Authentication & Explicit Action Button Latches
- **Unified Desk Authentication (`lib/screens/login_screen.dart` & `lib/providers/auth_provider.dart`):**
  - Updated `LoginScreen._handleOwnerLogin` to authenticate both Reception PIN (`0000`) and Owner PIN (`849201`) seamlessly via `loginAsReceptionistOrOwner`.
  - Added default fallback parity in `loginAsOwner` and `authenticateWithPin` (`inputHash == _defaultOwnerMasterPinHash`), ensuring default master credentials operate reliably even if local storage is desynced.
  - Added legacy hash sanitization in `AuthProvider.initSession` to prevent legacy 0000 hashes from locking out owner sessions.
- **Mandatory Explicit Button Latches & Re-entrancy Locks:**
  - **Appointment Booking (`lib/widgets/booking/add_appointment_dialog.dart`):** Added `_isBooking` transaction state, locked re-entrancy on click, disabled Cancel during writes, and added distinct progress feedback (`Booking Token...` / `Searching Patient...`).
  - **Medicine Formulary (`lib/widgets/catalogue/add_medicine_dialog.dart`):** Added `_isSaving` state, locked re-entrancy, and added progress spinner feedback (`Saving...`).
  - **Doctor Registration (`lib/screens/add_doctor_screen.dart`):** Added re-entrancy guard `if (_isSaving) return;`.
  - **Consultation Encounter (`lib/screens/consultation_encounter_screen.dart`):** Added re-entrancy guard `if (_isSaving) return;`.
  - **Desk & Chamber Login (`lib/screens/login_screen.dart`):** Added in-flight locks `if (_isLoading) return;` on doctor and receptionist/owner login handlers.
- **Automated Test Coverage:**
  - Added 3 unit tests in `test/auth_provider_test.dart` for unified desk login, master fallback resilience, and cache sanitization, passing all 166 automated unit and widget tests.

---

## [1.22.0] — 13-10-2026

### Strict 1:1 Paid-to-Review Cycle Enforcement & Roadmap RFC Expansion
- **Single Free Review Enforcement (`lib/models/patient_review_eligibility.dart`):**
  - Updated `PatientReviewEligibility.calculate` to anchor to the most recent paid visit (`latestPaidVisit`), scanning all interim visits for previous free review consumption.
  - Prevents infinite free review chaining by setting `isReviewAlreadyConsumed: true` and `isWithinReviewPeriod: false` once a free review has been completed within the cycle.
  - Formats date string in user alert with strict Indian format (`DD-MM-YYYY`).
- **Booking Modal Guardrail (`lib/widgets/booking/add_appointment_dialog.dart`):**
  - Displays amber warning banner when free review entitlement is consumed, and automatically resets payment selection to `paidCash` / doctor consultation fee.
- **Cycle Reset on Fresh Consultation:**
  - Verified that a subsequent paid visit restarts a brand-new single free review cycle.
- **Product Roadmap & Architectural RFCs (`docs/PRODUCT_ROADMAP.md`):**
  - Shipped and verified 1:1 Free Review enforcement in roadmap registry.
  - Documented active PM debate for Prepaid Carry-Over & Doctor Absence Refund protocol (RFC-2) for zero-deletion financial reconciliation.
- **Automated Test Coverage:**
  - Added 3 comprehensive unit test suites in `test/patient_review_and_models_test.dart`, expanding passing suite to 163 automated tests.

---

## [1.21.0] — 13-10-2026

### Mobile Responsive Doctor Chamber Layout & Roster Hardening
- **Chamber Control Banner Responsiveness (`lib/widgets/chamber/chamber_control_banner.dart`):**
  - Integrated responsive `LayoutBuilder` (< 600px breakpoint) across all chamber states (`idle`, `consultation_ended`, `ready_for_next`, `calling`).
  - Mobile layout stacks status text and icon on top and provides full-width primary action button on bottom, eliminating 2-column squishing and horizontal cramping.
- **Roster Patient Token Cards (`lib/widgets/chamber/chamber_token_card.dart`):**
  - Refactored token cards from a single rigid row to a responsive 2-row card layout on mobile viewports (< 650px).
  - Row 1 displays token badge, patient name with ellipsis, masked phone, longitudinal history button, and status badge.
  - Row 2 pairs payment subtitle with one-click action buttons (`Enter Consultation`, `Waiting Reception Call`, `Unattended`, `Record`, `View Summary`), resolving horizontal `RenderFlex` overflow errors on mobile phones.
- **Queue & Chamber Header Wrapping (`lib/widgets/chamber/chamber_queue_header.dart` & `lib/widgets/chamber/chamber_door_override_bar.dart`):**
  - Added responsive `LayoutBuilder` and `Wrap` in `ChamberQueueHeader` for "Past Session Roster" and "Today's Patient Queue", ensuring title, count badge, and live sync/archive indicators wrap cleanly on narrow screens.
  - Enhanced emergency door override bar header with wrapping to prevent horizontal overflow.
- **Automated Verification:**
  - Expanded test suites in `test/chamber_handshake_test.dart` and `test/chamber_read_only_archive_test.dart` with dedicated mobile 390px viewport tests, passing all 160 unit and widget tests.

---

## [1.20.0] — 13-10-2026

### Doctor-Configurable Free Review Policy (0 to 30 Days)
- **Configurable Review Terms on Doctor Model (`lib/models/doctor.dart`):**
  - Added `freeReviewDays` (`0` to `30` days, default: `14`) to the `Doctor` model, constructor, JSON serialization, and `copyWith`.
  - Setting `freeReviewDays: 0` designates visiting super-specialists or physicians who do not offer free reviews (all visits billed at full fee).
  - Configurable between `0` and `30` days to accommodate varied clinical specialties (e.g. 7 days for lab report review, 14 days for general OPD, 30 days for post-op surgical checks).
- **Owner Doctor Onboarding & Policy Editing (`lib/screens/add_doctor_screen.dart`):**
  - Added **Free Review Window (0 to 30 Days)** input with quick-select choice chips (`None (0d)`, `7 Days`, `14 Days`, `21 Days`, `30 Days`) and direct numeric entry validation.
  - Policy changes saved by clinic owners immediately take effect across all future bookings and eligibility calculations.
- **Roster Visibility (`lib/screens/doctor_list_screen.dart`):**
  - Added review policy badges on `DoctorRosterCard` displaying active policy (`Review: 14d`, `Review: 30d`, or `No Free Review`).
- **Domain Engine Refactor (`lib/core/engines/appointment_engine.dart` & `lib/models/patient_review_eligibility.dart`):**
  - Upgraded `PatientReviewEligibility.calculate` and `AppointmentEngine.evaluateReviewEligibility` to evaluate against doctor's configured `freeReviewDays`.
  - Upgraded `suggestPaymentType` to return `PaymentType.paidCash` if doctor has a `0`-day policy.
- **Booking & Live Queue Dynamic Feedback (`lib/widgets/booking/`, `lib/widgets/queue/`):**
  - Upgraded warning modal `BookingEligibilityBanner.showReviewWarningDialog` to display doctor-specific policies and elapsed day metrics.
  - Upgraded `AppointmentAccordion` to evaluate live queue payment adjustments against assigned doctor's review terms.
- **Automated Verification (`test/patient_review_and_models_test.dart`):**
  - Added unit test coverage for `0`-day policy rejection, `30`-day policy qualification, and boundary handling, bringing the test suite to 157 passing tests.

---

## [1.19.0] — 13-10-2026

### Security Hardening & Regulatory Compliance
- **Cryptographic Credential Hashing (`lib/providers/auth_provider.dart`):**
  - Integrated `crypto: ^3.0.7` and implemented domain-salted SHA-256 PIN hashing (`AuthProvider.hashPin`).
  - Purged plaintext access credentials from persistent storage (`SharedPreferences`): only cryptographic hashes (`auth_owner_master_pin_hash`, `auth_receptionist_pin_hash`) are persisted on disk.
  - Implemented automatic legacy migration on `initSession`: existing plaintext credentials from earlier versions are automatically hashed and permanently purged from device storage.
  - Enhanced direct login helpers (`loginAsOwner`, `loginAsReceptionist`, `loginAsDoctor`) and chamber verification to evaluate strictly via SHA-256 hash matching.
- **Healthcare Data Privacy & Regulatory Compliance (`docs/COMPLIANCE_AND_PRIVACY.md`):**
  - Authored authoritative compliance blueprint aligned with the Indian Digital Personal Data Protection (DPDP) Act 2023, ABDM Health Data Management Policy, and NMC regulations.
  - Formulated 3-tier Role-Based Access Control (RBAC) matrix separating clinical findings (physicians) from queue dispatch (reception) and financial ledgers (owner).
  - Codified statutory 3-year minimum clinical record retention and verbal consent walk-in protocols.
- **Automated Test Fortification (`test/auth_provider_test.dart`):**
  - Added unit tests for deterministic SHA-256 hashing and automatic legacy plaintext PIN migration and disk purging, bringing test suite to 155 tests.

---

## [1.18.0] — 13-10-2026

### Phase 2: Atomic Concurrency Locks & Forensic Audit Trail
- **Atomic Booking Concurrency Lock (0% DB Race Conditions):**
  - Implemented transactional reservation locks at `counters/lock_{doctorId}_{yyyy-MM-dd}_{phone}_{normalizedName}` inside `BookingService.bookAppointment`.
  - Guarantees race-proof duplicate prevention at the database boundary: simultaneous multi-desk submissions for the same patient/doctor/day trigger typed `DuplicateBookingException` on conflicting clients via Firestore OCC, while family members sharing a phone number remain explicitly preserved.
- **Append-Only Forensic Operational Audit Ledger (`appointment_events`):**
  - Created immutable `AppointmentEvent` model and `appointment_events` collection tracking every operational state shift (`created`, `checkedIn`, `admitted`, `completed`, `markedAbsent`, `statusUpdated`).
  - Integrated audit event generation across all `BookingService` state mutations and `ConsultationService.saveConsultation`.
  - Added strict database rule in `firestore.rules` locking `appointment_events` with `allow update, delete: if false;` to guarantee forensic immutability.
- **Test Suite Fortification (`test/booking_concurrency_and_audit_test.dart`):**
  - Added 5 new unit tests covering deterministic lock path generation, family exception preservation, `DuplicateBookingException` semantics, and `AppointmentEvent` serialization across all 6 lifecycle events, expanding the automated test suite to 153 tests.

---

## [1.17.0] — 13-10-2026

### Security & Data Model Hardening
- **Authoritative Backend Security Rules (`firestore.rules` & `firebase.json`):**
  - Authored comprehensive production Firestore security rules enforcing **Invariant #1 (Zero Deletions)** with `allow delete: if false;` across `appointments`, `consultations`, `patients`, and `counters`.
  - Enforced **Invariant #2 (Append-Only Consultations)** with `allow update, delete: if false;` on the `consultations` collection, locking historical encounters from post-facto tampering.
  - Hardened document creation schema checks and locked immutable appointment attributes (`queueNumber`, `doctorId`, `scheduledDate`).
  - Wired `firestore.rules` directly into `firebase.json`.
- **Single Source of Truth & State Reconciliation (`lib/models/appointment.dart`):**
  - Reconciled dual-source-of-truth drift between `status` (`AppointmentStatus`) and `visitStatus` (`VisitStatus`).
  - Hardened `Appointment.fromJson` to automatically reconcile terminal states (`completed`, `cancelled/absent`), eliminating in-memory state drift from un-synchronized legacy writes.
  - Fixed `ConsultationService.saveConsultation` (`lib/services/consultation_service.dart`) to atomically update both `'status'` and `'visitStatus'` to `completed` in Firestore completion batches.
- **Automated Test Suite Expansion (`test/patient_review_and_models_test.dart`):**
  - Added unit tests for model state auto-reconciliation and synchronized JSON serialization, bringing the test suite to 148 passing tests.

---

## [1.16.9] — 12-10-2026

### Audited & Synchronized
- **Documentation Architecture & Credential Synchronization (`docs/`, `.agents/`, `README.md`, `AGENTS.md`):**
  - **Owner Master PIN Alignment:** Rectified legacy credential documentation across `README.md`, `docs/SCHEMA_AND_MODELS.md`, and `docs/PRODUCT_VISION_AND_WORKFLOW.md` from `123456` to canonical Master PIN `849201` matching app constants and test suites.
  - **Domain Engine Topology Synchronization:** Updated `README.md` and `AGENTS.md` project maps to explicitly include the 5th domain engine (`CashHandoverEngine`), synchronized automated test counters to 145 passing tests, and pruned redundant tree entries.
  - **Developer Agent Recipes Fortification (`.agents/recipes/`):**
    - Updated `add_clinical_field.md` to reference canonical `PrintHeaderAndDemographics` instead of deprecated `PrintClinicalSnapshot`.
    - Updated `modify_booking_rule.md` unit test guidelines and commands to reference canonical `test/patient_review_and_models_test.dart` instead of legacy `test/widget_test.dart`.
  - **Standards & Invariant Compliance:** Verified 100% adherence to Indian numerical date formatting (`DD-MM-YYYY`), pure Dart engine separation, and zero Firestore ledger deletions across the entire documentation catalog.

---

## [1.16.8] — 12-10-2026

### Extracted & Modularized
- **Domain Engine Decomposition & Dedicated `CashHandoverEngine`:**
  - **Extracted Standalone Engine (`lib/core/engines/cash_handover_engine.dart`):**
    - Decoupled daily end-of-day cash drawer balancing, denomination note math, and audit discrepancy calculation from `RevenueEngine` into its own dedicated 5th pure Dart engine file, 100% fulfilling the architectural roadmap blueprint.
    - Exported `CashHandoverEngine` in `lib/core/engines/engines.dart` canonical barrel.
    - Preserved seamless backward-compatibility delegates in `RevenueEngine` (`calculateCashHandover`, `calculateDenominationTotal`, `calculateDiscrepancy`) and re-exported handover models (`CashHandoverDoctorRow`, `CashHandoverSummary`).
  - **Consumer Alignment:**
    - Refactored `DailyCashHandoverDialog` (`widgets/dashboard/daily_cash_handover_dialog.dart`) and `test/cash_handover_engine_test.dart` to directly consume atomic `CashHandoverEngine`.
  - **Roadmap Verification:** Marked Domain Engines & Math Audit as `🟢 Shipped & Verified` in `docs/PRODUCT_ROADMAP.md` with 145 passing automated tests.

---

## [1.16.7] — 12-10-2026

### Audited & Synchronized
- **Pure Dart Domain Engines Architecture Audit (`lib/core/engines/`):**
  - **Zero Flutter UI Dependencies Verified:** Confirmed that all 4 domain engines (`AppointmentEngine`, `MedicineEngine`, `RevenueEngine`, `WhatsAppEngine`) remain 100% pure Dart, preserving clear separation of presentation and business domain logic.
  - **Canonical Barrel Synchronization:** Consolidated fragmented individual model imports across `appointment_engine.dart`, `medicine_engine.dart`, `revenue_engine.dart`, and `whatsapp_engine.dart` to uniformly consume `lib/models/models.dart`.
  - **Operational & Clinical Invariants Verified:**
    - `AppointmentEngine`: 14-day free review calculations, fee determination, multi-parameter duplicate booking prevention, and dynamic consultation arrival estimation.
    - `RevenueEngine`: Realized collection segregation, chamber KPIs, and cash drawer handover denomination reconciliation.
    - `MedicineEngine`: Composition-first vs brand-first scoring, clinical dosage fallbacks, and medication reconciliation partitions.
    - `WhatsAppEngine`: Standardized phone number normalization, append-only digital prescription summaries, and deep link generation.

---

## [1.16.6] — 12-10-2026

### Refactored & Fortified
- **Test Suite Modernization & Quality Assurance Fortification:**
  - **Eliminated Misleading Legacy `widget_test.dart`:**
    - Renamed and refactored `test/widget_test.dart` to `test/patient_review_and_models_test.dart`, cleanly aligning test file naming with the tested domain subsystems (`PatientReviewEligibility`, `Appointment`, and `Doctor` domain models).
    - Migrated multi-line model imports to canonical barrel export `models.dart`.
  - **Added `AuthProvider` Security & PIN Guarding Suite (`test/auth_provider_test.dart`):**
    - Introduced 12 automated unit tests verifying 3-tier role guarding (Owner Master PIN 6 digits `849201`, Receptionist PIN `0000`, Doctor Chamber PINs).
    - Tested unified PIN evaluation without manual role selectors, ambiguous duplicate doctor PIN handling, elevated owner step-down to reception, custom PIN mutation, logout cleanup, and session persistence via `SharedPreferences`.
  - **Added `AppFormatters` Clinical Formatting & Invariants Suite (`test/app_formatters_test.dart`):**
    - Introduced 10 unit tests verifying mandatory Indian date formats (`DD-MM-YYYY`, `DD-MM-YY`, weekday strings, ISO Firestore counter keys), Indian Rupee currency formatting, doctor initials extraction, and specialty typo sanitization.
    - Discovered and fixed duplicate `"Dr. Dr."` prefix regression in `AppFormatters.doctorTitle` using exhaustive leading prefix stripping.
  - **Barrel Synchronization Across Test Suites:**
    - Harmonized imports across `test/consultation_test.dart`, `test/prescription_print_test.dart`, `test/chamber_read_only_archive_test.dart`, `test/chamber_handshake_test.dart`, and `test/whatsapp_engine_test.dart` to consume canonical barrels (`models.dart`, `widgets.dart`).
  - **Legacy Reference Pruning:**
    - Replaced stale reference to retired `ClinicalDefaultsHelper` in `test/catalogue_scoring_test.dart` with `MedicineEngine.getDefaultsForMedicine`.
  - **Automated Test Expansion:** Expanded test suite from 122 to 144 automated tests covering role guarding, session persistence, and formatting invariants.

---

## [1.16.5] — 12-10-2026

### Refactored & Consolidated
- **Widget Architecture Consolidation (Cleaned 12 Redundant Files):**
  - **Eliminated Pass-Through Thin Screens:**
    - Merged `DoctorDailyBreakdownTable` directly into `DoctorDailyDetailsScreen` (`doctor_daily_details_screen.dart`), turning a 45-line shell into a self-contained detail screen and removing a misplaced widget from `widgets/dashboard/`.
    - Merged `DoctorStatisticsCard` directly into `StatisticsScreen` (`statistics_screen.dart`), making it self-contained and removing a misplaced widget from `widgets/dashboard/`.
    - Merged `DoctorForm` directly into `AddDoctorScreen` (`add_doctor_screen.dart`), turning an anemic 30-line shell into a complete, self-contained doctor credential form.
    - Merged `DoctorRosterCard` directly into `DoctorListScreen` (`doctor_list_screen.dart`), removing false categorization in `widgets/common/` and eliminating naming confusion with `DashboardDoctorRosterCard`.
  - **Micro-Widget Inlining within Subsystems:**
    - Merged `VitalsInputGrid` directly into `VitalsAndExamSection` (`vitals_and_exam_section.dart`), consolidating all Step 2 encounter inputs in one file.
    - Merged `ChamberQueueList` into `ChamberQueueHeader` (`chamber_queue_header.dart`), unifying queue list rendering and headers.
    - Merged `PrintClinicalSnapshot` into `PrintHeaderAndDemographics` (`print_header_and_demographics.dart`), combining patient demographics and vitals snapshot for letterheads.
  - **Screen Micro-Dock Co-location:**
    - Co-located `ChamberCallingAlertBar` and `ConsultationBottomDock` directly in `ConsultationEncounterScreen` (`consultation_encounter_screen.dart`).
    - Merged `DoctorLoginForm` and `ReceptionLoginForm` directly into `LoginScreen` (`login_screen.dart`), eliminating cross-file prop drilling and retiring the `widgets/auth/` directory.
  - **Dead Code Pruning:**
    - Removed unreferenced orphan `AllergyAlertBanner` (`widgets/common/allergy_alert_banner.dart`).
  - **Centralized Barrel Synchronization:**
    - Cleaned and updated `lib/widgets/widgets.dart` barrel exports, reducing total widget files from 56 to 44 (-21%).
  - **Legacy Utils Shim Retirement:**
    - Replaced all calls to deprecated `ClinicalDefaultsHelper` and `MedicineSearchScorer` across `EncounterFormState`, `RxReconciliationSection`, `RxSearchResultsView`, `StagedMedicineForm`, and `catalogue_scoring_test.dart` directly with pure `MedicineEngine`.
    - Deleted obsolete adapter shims `clinical_defaults_helper.dart` and `medicine_search_scorer.dart`.
  - **Screen Direct-Service Decoupling:**
    - Refactored `AppointmentListScreen` and `StatisticsScreen` to directly consume atomic `BookingService` instead of instantiating the full `FirebaseService` facade.
    - Refactored `DoctorChamberScreen` to directly consume atomic `BookingService` and `ChamberService`, decoupling the screen from `FirebaseService`.
  - **State Management Layer Modernization (`ClinicProvider` & `AuthProvider`):**
    - Refactored `ClinicProvider` (`clinic_provider.dart`) to directly consume atomic modular services (`BookingService`, `ChamberService`, `ConsultationService`, `CatalogueService`, `DoctorService`, `PatientService`), supporting modular dependency injection.
    - Added stream idempotency in `startListeningToAppointments()`, preventing duplicate Firestore subscriptions and offline cache lookups when already listening to the active calendar date.
    - Eliminated unnecessary UI listener rebuild churn with value equality guards in `_setLoading()`, `setDashboardSearchQuery()`, and `clearDashboardSearchQuery()`.
    - Cleaned confusing legacy `ownerPin` and `setOwnerPin` aliases in `AuthProvider` (`auth_provider.dart`), securing role semantics between owner master PIN and receptionist PIN.
  - **Retirement of Legacy Service Facade:**
    - Deleted obsolete 254-line facade `lib/services/firebase_service.dart`. All screens and providers now directly consume single-responsibility services.
  - **Data Models & Schema Hardening (`lib/models/`):**
    - Hardened `Doctor.fromJson` (`doctor.dart`) with polymorphic date parsing (`Timestamp`, `DateTime`, `String`) for `blockedDates` to prevent runtime cast errors from arbitrary Firestore date formats.
    - Enhanced `Patient.fromJson` (`patient.dart`) with whitespace trimming and Set-based deduplication for critical clinical allergy alert tags.
    - Introduced clean barrel export file `lib/models/models.dart` exporting all 11 pure data models.

---

## [1.16.4] — 12-10-2026

### Refactored & Modularized
- **Queue Tile Architecture Decomposition (`AppointmentAccordion`):**
  - **Single Responsibility Principle:** Deconstructed the monolithic 786-line `AppointmentAccordion` into lightweight, atomic sub-widgets, reducing the coordinator file by ~50% (down to 398 lines).
  - **Extracted `AccordionDispatchSection`:** Encapsulates the `ChamberSession` realtime stream listener, dynamic doctor readiness badges (`Ready`, `Breather`, `Occupied`), and guarded `SEND IN` dispatch buttons with occupied chamber collision and breather confirmation modals.
  - **Extracted `AccordionStatusActions`:** Encapsulates `Mark Complete`, `Mark Absent` (with audit-proof slot preservation confirmation modal), and `Send WhatsApp Digital Prescription` generation.
  - **Export Centralization:** Added exports to `lib/widgets/widgets.dart` barrel file.
  - **Automated Test Fortification:** Added `test/accordion_modular_queue_test.dart` covering realtime chamber stream listeners, dispatch confirmation modals, and status actions.

---

## [1.16.3] — 12-10-2026

### Audit Integrity & Historical View Hardening
- **Dynamic Queue Header & Static Archive Badge (`ChamberQueueHeader`):**
  - Section title automatically switches from `"Today's Patient Queue"` to `"Past Session Roster"` when viewing historical dates.
  - Replaced the live sync indicator (`"🟢 Live Sync"`) with a muted static badge (`"⚪ Archived Snapshot"`) on past dates.
- **Historical Chamber Metric Reconciliation (`ChamberMetricsGrid`):**
  - Total tokens subtitle on historical dates updates to `"Shift completed"` instead of displaying phantom queue counts.
  - Waiting queue count evaluates to `0` for closed past shifts.
  - Reconciled `Absent / No-Show` count on historical dates to dynamically include unresolved tokens that never reached consultation, aligning with the visual `UNATTENDED / NO-SHOW` tags.
  - **Automated Test Fortification:** Expanded `test/chamber_read_only_archive_test.dart` with audit reconciliation and dynamic header tests.

---

## [1.16.2] — 12-10-2026

### Added & Hardened
- **Read-Only Archive State for Historical Dates in Doctor Chamber:**
  - **Temporal Guarding (`_isToday` vs `_isPastDate`):** Live chamber actions (chamber initialization, ready signals, and emergency door admissions) are strictly restricted to the current active calendar day (`today`).
  - **Chamber Archive Indicator (`ChamberArchiveBanner`):** Historical dates completely hide live control banners and render `🔒 Chamber Shift Closed • Read-Only Archive` with formatted Indian date (`DD-MM-YYYY`).
  - **EOD Unresolved Token Protection:** Past appointments left unresolved render as `UNATTENDED / NO-SHOW` with an `Unattended` static pill, eliminating active queue indicators or live admission options.
  - **Historical Record Review:** Completed visits on past dates display `[ View Summary ]` to inspect longitudinal records in read-only mode with zero status mutation capability.
  - **Automated Test Fortification:** Added `test/chamber_read_only_archive_test.dart` covering temporal guarding, read-only chamber banners, and unattended token display.

---

## [1.16.1] — 12-10-2026

### Security & Queue Integrity
- **Restricted Emergency Door Override Runway (`ChamberDoorOverrideBar`):**
  - **Eliminated Arbitrary Overrides:** Removed unconstrained manual override buttons and long-press triggers across queue cards, preventing arbitrary queue-jumping or admitting unverified/unpaid patients.
  - **Strict "Next at Door" Quick-Selector:** Added an emergency self-call runway strictly capped to the next 1–2 patients in `VisitStatus.waitingInLobby` with confirmed payment/waiver (`PaymentType != unpaid`).
  - **Zero Distraction / Auto-Hiding:** The emergency runway automatically hides during active physician consultations (`in_consultation`) or when no verified lobby-checked-in patients are waiting.
  - **Atomic State Transition:** 1-tap door admission immediately updates appointment status to `VisitStatus.inConsultation`, syncs the live chamber session channel, and hydrates the consultation encounter workspace.
  - **Automated Test Fortification:** Added `test/doctor_door_override_test.dart` covering emergency self-call runway, lobby status gating, and confirmation dialogs.

---

## [1.16.0] — 12-10-2026

### Added & Enhanced
- **Asynchronous OPD Advance/Phone Booking & Desk Check-In Workflow:**
  - **Granular Visit Lifecycle (`VisitStatus`):** Added explicit states (`booked`, `waitingInLobby`, `inConsultation`, `completed`, `cancelled`) alongside `checkedInAt` timestamp tracking.
  - **Doctor Chamber Queue Isolation:** Advance and phone reservations (`VisitStatus.booked`) are cleanly segregated from the physician's active live queue and chamber waiting KPIs until patients physically arrive and check in at the counter.
  - **1-Tap Quick Desk Check-In & Payment Reconciliation (`QuickCheckInDialog`):** Added rapid check-in modal supporting single-tap action and numpad shortcuts (`1`=Cash, `2`=UPI, `3`=Post-Pay, `4`=Free Review, `5`=Free Family) to streamline counter desk throughput.
  - **Inviolable Discretionary Fee Waivers (`PaymentType.freeFamily`):** Enforced immutable courtesy/VVIP zero-rupee fee waivers that cannot be overwritten or coerced by historical visit review calculations.
  - **Granular Payment Types:** Extended `PaymentType` to support `paidCash`, `paidUpi`, `postPay`, and `unpaid`, complete with backward compatibility aliases and helpers.
  - **Reception & Queue UI Enhancements:** Added dedicated "Advance / Phone Bookings" section to queue accordion, clear status badges ("Booked (Phone)" vs "In Lobby"), and instant 1-tap check-in buttons on dashboard queue cards.
  - **Automated Test Fortification:** Added `test/opd_checkin_payment_workflow_test.dart` covering asynchronous desk check-in and payment reconciliation.

---

## [1.15.1] — 12-10-2026

### Fixed & Enhanced
- **Mobile Responsive Catalogue Layout:**
  - Refactored `CatalogueHeaderAndStats` using `LayoutBuilder` to fluidly adapt across mobile (<560px), tablet (560–800px), and desktop (>800px). Eliminates RenderFlex overflows on mobile viewports.
  - Made `CatalogueSearchToolbar` responsive by stacking the search query input and dosage form dropdown on narrow screens.
- **Human-Friendly Permission SnackBars:**
  - Replaced harsh red error banners on "Clean Duplicates" and "Delete Medicine" with warm amber advisory notices (`#D97706`) explaining that Clinic Administrator (Owner) credentials are required.
- **Reception & Admin Testing Login Credentials:**
  - Added clear testing credential guidance directly to `ReceptionLoginForm` (`Reception: 0000 | Admin/Owner: 849201`) with expanded viewport tolerance in `LoginScreen`.
  - **Automated Test Suite Expansion:** Added responsive widget tests verifying mobile (390px) and desktop (1200px) layout stability with zero overflows.

---

## [1.15.0] — 12-10-2026

### Added
- **Offline Queue Fallback Cache (`P6`):**
  - **Local Persistence Gateway (`OfflineQueueCacheService`):** Silently caches daily appointment queue updates to local browser storage (`SharedPreferences`) using JSON serialization via `Appointment.toCacheMap()`.
  - **Zero-Dropout Resilience:** Counter PC gracefully falls back to cached appointment ledger if broadband connectivity experiences transient hiccups or Firestore stream errors.
  - **Reception Status Indicator:** Displays high-visibility amber badge `[ ⚡ Offline Cache (HH:mm) ]` in `DashboardTodayQueueCard` during dropouts, auto-clearing once live stream restores.
- **WhatsApp Digital Prescription Deep Link (`P7`):**
  - **Pure Domain Formatter (`WhatsAppEngine`):** Formats append-only consultations into standardized, human-readable WhatsApp markdown messages with Indian date formatting (`DD-MM-YYYY`), patient demographics, vitals, diagnosis, medication schedule (dosage, frequency, duration, timing), discontinued drug audits, and follow-up review interval.
  - **1-Tap `wa.me` Deep Link Generation:** Cleanses Indian phone numbers to canonical `91XXXXXXXXXX` format and builds deep link URLs.
  - **Cross-Platform Delivery:** Added green `[ 💬 Send on WhatsApp ]` action on `PrescriptionPrintScreen` and quick dispatch on `AppointmentAccordion` for completed visits, opening Web WhatsApp via zero-dependency `platform_url.dart`.
- **Daily End-of-Day Financial Handover & Cash Reconciliation (`P8`):**
  - **Domain Calculation Engine (`RevenueEngine.calculateCashHandover`):** Accurately summarizes daily cash collections across completed visits, filtering out pending/absent slots and segmenting visits by doctor and payment type (`Paid`, `Free Review`, `Free Family`).
  - **Physical Cash Denomination Counter:** Interactive modal `DailyCashHandoverDialog` allowing receptionists to tally note counts (`₹500`, `₹200`, `₹100`, `₹50`, `₹20`, `₹10`) with live discrepancy evaluation (`🟢 ₹0 Difference • Balanced` vs `🔴 Shortage / Surplus`).
  - **Reception Dashboard Trigger:** Added 1-tap `[ 🧾 Cash Handover ]` button on `DashboardHeaderBar` and printable handover slip action.
  - **Automated Test Suite Expansion:** Added dedicated test suites `test/offline_queue_cache_test.dart`, `test/whatsapp_engine_test.dart`, and `test/cash_handover_engine_test.dart`.

---

> **Historical Release Notes:**  
> For changes in versions v1.0.0 through v1.14.0, see [`docs/archive/CHANGELOG_ARCHIVE.md`](docs/archive/CHANGELOG_ARCHIVE.md).

