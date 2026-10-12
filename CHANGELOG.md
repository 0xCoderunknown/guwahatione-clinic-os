# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
  - **Automated Verification:**
    - `flutter analyze` completed with 0 errors and 0 warnings.
    - All 144 automated unit tests pass seamlessly.

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
  - **Automated Verification:**
    - Test suite expanded from 122 to **144 automated tests** with 100% pass rate in sub-6 seconds.
    - `flutter analyze` completed with 0 errors and 0 warnings.

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
  - **Automated Verification:**
    - `flutter analyze` completed with 0 errors and 0 warnings.
    - All 122 automated unit and widget tests pass seamlessly.

---

## [1.16.4] — 12-10-2026

### Refactored & Modularized
- **Queue Tile Architecture Decomposition (`AppointmentAccordion`):**
  - **Single Responsibility Principle:** Deconstructed the monolithic 786-line `AppointmentAccordion` into lightweight, atomic sub-widgets, reducing the coordinator file by ~50% (down to 398 lines).
  - **Extracted `AccordionDispatchSection`:** Encapsulates the `ChamberSession` realtime stream listener, dynamic doctor readiness badges (`Ready`, `Breather`, `Occupied`), and guarded `SEND IN` dispatch buttons with occupied chamber collision and breather confirmation modals.
  - **Extracted `AccordionStatusActions`:** Encapsulates `Mark Complete`, `Mark Absent` (with audit-proof slot preservation confirmation modal), and `Send WhatsApp Digital Prescription` generation.
  - **Export Centralization:** Added exports to `lib/widgets/widgets.dart` barrel file.
  - **Automated Test Fortification:** Added `test/accordion_modular_queue_test.dart`, expanding the test suite to **122 passing tests** with 100% success rate.

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
- **Automated Test Fortification:**
  - Expanded `test/chamber_read_only_archive_test.dart` with audit reconciliation and dynamic header tests, bringing test suite to **118 passing tests** with 100% success rate.

---

## [1.16.2] — 12-10-2026

### Added & Hardened
- **Read-Only Archive State for Historical Dates in Doctor Chamber:**
  - **Temporal Guarding (`_isToday` vs `_isPastDate`):** Live chamber actions (chamber initialization, ready signals, and emergency door admissions) are strictly restricted to the current active calendar day (`today`).
  - **Chamber Archive Indicator (`ChamberArchiveBanner`):** Historical dates completely hide live control banners and render `🔒 Chamber Shift Closed • Read-Only Archive` with formatted Indian date (`DD-MM-YYYY`).
  - **EOD Unresolved Token Protection:** Past appointments left unresolved render as `UNATTENDED / NO-SHOW` with an `Unattended` static pill, eliminating active queue indicators or live admission options.
  - **Historical Record Review:** Completed visits on past dates display `[ View Summary ]` to inspect longitudinal records in read-only mode with zero status mutation capability.
  - **Automated Test Fortification:** Added `test/chamber_read_only_archive_test.dart`, expanding automated test suite to **114 passing tests** with 100% success rate.

---

## [1.16.1] — 12-10-2026

### Security & Queue Integrity
- **Restricted Emergency Door Override Runway (`ChamberDoorOverrideBar`):**
  - **Eliminated Arbitrary Overrides:** Removed unconstrained manual override buttons and long-press triggers across queue cards, preventing arbitrary queue-jumping or admitting unverified/unpaid patients.
  - **Strict "Next at Door" Quick-Selector:** Added an emergency self-call runway strictly capped to the next 1–2 patients in `VisitStatus.waitingInLobby` with confirmed payment/waiver (`PaymentType != unpaid`).
  - **Zero Distraction / Auto-Hiding:** The emergency runway automatically hides during active physician consultations (`in_consultation`) or when no verified lobby-checked-in patients are waiting.
  - **Atomic State Transition:** 1-tap door admission immediately updates appointment status to `VisitStatus.inConsultation`, syncs the live chamber session channel, and hydrates the consultation encounter workspace.
  - **Automated Test Fortification:** Added `test/doctor_door_override_test.dart`, expanding automated test suite to **110 passing tests** with 100% success rate.

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
  - **Automated Test Fortification:** Added `test/opd_checkin_payment_workflow_test.dart`.

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
- **Automated Test Suite Expansion:**
  - Added responsive widget tests verifying mobile (390px) and desktop (1200px) layout stability with zero overflows. Test suite expanded to **99 automated tests** passing at 100%.

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
- **Automated Test Suite Expansion:**
  - Added unit test suites `test/offline_queue_cache_test.dart`, `test/whatsapp_engine_test.dart`, and `test/cash_handover_engine_test.dart`.
  - Expanded test suite from 81 to **95 automated tests** executing in sub-3 seconds with 100% pass rate.

---

## [1.14.0] — 11-10-2026

### Added
- **Doctor Medical Council Registration Number & Printout Signature Block (`P5`):**
  - **Schema & Model Expansion:** Added optional `medicalRegNumber` to `Doctor` and immutable `doctorRegNumber` snapshot to `Consultation` models compliant with Indian medical-legal standards.
  - **Doctor Registration & Edit Form:** Added Medical Council Registration Number input field (`lib/widgets/common/doctor_form.dart`) allowing clinic owners to configure credentials (e.g., `AMC-24891`, `NMC-10293`).
  - **Roster Card Badge:** Added verified registration badge (`📋 Reg: {medicalRegNumber}`) on `DoctorRosterCard`.
  - **Official Prescription Footer (`PrintOrdersAndFooter`):** Renders official doctor registration number directly under doctor name on both A4 and A5 printable sheets with automatic fallback to historical consultation record.
  - **Seamless Encounter Passing:** Enriched `buildConsultation` and `_navigateToPrint` in `ConsultationEncounterScreen` to pass and snapshot the physician's registration number atomically.
- **Pure Domain Engine Test Fortification (100% Engine Coverage):**
  - **`RevenueEngine` Unit Test Suite (`test/revenue_engine_test.dart`):** Dedicated tests covering realized revenue calculation (strict exclusion of pending and absent appointments), doctor total fees, daily reception metrics, chamber KPIs, and multi-doctor analytics summaries.
  - **`AppointmentEngine` Test Expansion (`test/appointment_engine_estimated_time_test.dart`):** Comprehensive unit tests for duplicate booking detection (`findDuplicateBooking` composite key matching targetDate + doctorId + normalized name + phone, family member exception preservation, absent slot rebooking), fee resolution across all payment policies, and provisional queue token calculations.
  - **`MedicineEngine` Defaults Test Suite (`test/medicine_engine_defaults_test.dart`):** Unit tests covering pharmacological OPD defaults (fasting PPIs, morning antihypertensives, bedtime statins, course-length antibiotics, SOS antipyretics, non-tablet forms), prescription reconciliation segregation, and master catalogue filtering and unique molecule tallying.
- **Automated Test Suite Expansion:**
  - Expanded test suite from 54 to **81 automated tests** executing in sub-3 seconds with zero failures and zero warnings in `flutter analyze`.

---

## [1.13.0] — 11-10-2026

### Changed
- **Purified Firebase Layer & Gateway Abstraction:**
  - Completely eliminated `DocumentSnapshot` and `cloud_firestore` imports from all screens (`appointment_list_screen.dart`, `doctor_chamber_screen.dart`, `consultation_encounter_screen.dart`) and widgets.
  - Updated `ChamberService` and `FirebaseService` facade to map raw Firestore snapshots into typed `Stream<ChamberSession>` before dispatching to state providers and UI.
  - Purged `cloud_firestore` import from `ClinicProvider` and added convenience helper `getDoctorById(doctorId)`.
- **UI & Widget Purification (Engine Delegation):**
  - Replaced raw `.where((a) => a.doctorId == doc.id).length` loops in `DashboardDoctorRosterCard` and `DashboardTodayQueueCard` with `AppointmentEngine.countDoctorAppointments`.
  - Replaced raw `.where` filtering in `RxReconciliationSection` with pure domain method `MedicineEngine.segregatePrescriptions`.
  - Typed all chamber stream builders across presentation widgets (`StreamBuilder<ChamberSession>`) with boolean getters replacing ad-hoc string comparisons.

### Added
- **Introduced `ChamberSession` Domain Model:** Created strongly typed, pure Dart domain model `lib/models/chamber_session.dart` with status properties and typed boolean getters (`isReadyForNext`, `isCalling`, `isInConsultation`, `isConsultationEnded`, `isIdle`, `hasActivePatient`).
- **Automated Test Suite Expansion:**
  - Added unit test suites for `ChamberSession` deserialization, default states, and typed status flags.
  - Added unit test suite for `AppointmentEngine.countDoctorAppointments`.
  - All 54 automated unit and widget tests passing cleanly with zero warnings in `flutter analyze`.

---

## [1.12.0] — 11-10-2026

### Changed
- **Screen Coordinator Scaffold Standardization Across All Screens:**
  - Migrated all screens in `lib/screens/` to strict **Thin Coordinator Scaffolds** (orchestrating only layout bounds, responsive breakpoints, lifecycles, and navigation triggers).
  - **Relocated `AddAppointmentDialog`:** Moved from `lib/screens/` to `lib/widgets/booking/add_appointment_dialog.dart` and re-exported in `lib/widgets/widgets.dart`.
  - **Catalogue Engine Delegation:** Stripped in-memory filtering and sorting calculations out of `MedicineCatalogueScreen`, delegating to pure domain methods `MedicineEngine.filterAndSortCatalogue` and `MedicineEngine.countUniqueMolecules`.

### Added
- **Sub-Component Extractions:**
  - **Extracted `DoctorStatisticsCard`:** Extracted doctor stats cards and KPI metrics from `StatisticsScreen` into `lib/widgets/dashboard/doctor_statistics_card.dart` (reducing `StatisticsScreen` to 98 lines).
  - **Extracted `DoctorRosterCard`:** Extracted doctor profile cards, PIN badges, and action buttons from `DoctorListScreen` into `lib/widgets/common/doctor_roster_card.dart` (reducing `DoctorListScreen` to 85 lines).
  - **Extracted `DoctorDailyBreakdownTable`:** Extracted breakdown tables and fee footers from `DoctorDailyDetailsScreen` into `lib/widgets/dashboard/doctor_daily_breakdown_table.dart` (reducing `DoctorDailyDetailsScreen` to 38 lines).
  - **Extracted `DoctorForm`:** Extracted doctor registration and edit forms from `AddDoctorScreen` into `lib/widgets/common/doctor_form.dart` (reducing `AddDoctorScreen` to 28 lines).
  - **Extracted Auth Sub-Forms:** Extracted `DoctorLoginForm` and `ReceptionLoginForm` into `lib/widgets/auth/`, reducing `LoginScreen` from 418 lines down to 215 lines.
  - **Extracted `ChamberQueueList`:** Extracted token sequence list and empty state from `DoctorChamberScreen` into `lib/widgets/chamber/chamber_queue_list.dart`.

---

## [1.11.0] — 11-10-2026

### Added
- **Keyboard-First Walk-In Registration Modal (`AddAppointmentDialog`):**
  - **100% Mouse-Free Ergonomics:** Full Tab-chaining across Phone (autofocus) ➔ Name ➔ Age ➔ Sex ➔ Doctor ➔ Payment ➔ Submit.
  - **Physical Sex Hotkey Selector (`KeyboardGenderSelector`):** Replaced rigid dropdown with 3-way toggle row `[ Male ]  [ Female ]  [ Other ]`. Typing `M`/`m`, `F`/`f`, `O`/`o` or using arrow keys selects options instantly with clear focus ring highlights.
  - **No Accidental Sex Defaults:** `gender` starts unselected (`null`) for new patients, enforcing explicit selection with validation error highlighting to prevent clinical mismatches.
  - **Smart Phone Auto-Advance:** 10 digits entered searches patient directory; existing records auto-fill details and jump directly to Doctor picker, while new records advance to Patient Name.
  - **Global Enter Key Submission:** Pressing Enter or NumpadEnter from any field validates and atomically commits the booking.
- **Provisional Live Token Preview & Wait Time Badge:**
  - Instantly computes next token number upon doctor selection via pure domain `AppointmentEngine.calculateProvisionalNextToken`.
  - Calculates dynamic estimated consultation time window (`AppointmentEngine.calculateProvisionalEstimatedWindow`):
    `🎟️ Next Token: #13 • Est. Time: ~07:45 PM – 08:05 PM`
  - Gracefully prompts `Select a doctor to preview token & wait time` when unselected.
- **Same-Day Duplicate Booking Protection per Doctor:**
  - Enforces composite uniqueness: `(Target Date + DoctorId + Normalized Patient Name + Phone)`.
  - Real-time warning alert banner in dialog: `⚠️ [Patient Name] already holds Token #[queueNumber] with Dr. [Doctor Name] for today.`
  - Disables submit button and Enter shortcut while duplicate is detected.
  - Provides 1-click `[ View Token #[queueNumber] ]` helper button closing the modal and filtering today's live queue to that token.
  - **Family Member Exception:** Preserved ability for family members sharing a phone number (e.g., father booking for child) to book Token #2 by updating Patient Name.
- **Owner Role & 6-Digit Master PIN Authentication:**
  - Introduced unified 3-tier user role structure (`receptionist`, `doctor`, `owner`).
  - Clinic owner authentication via 6-digit master PIN hashed in Firestore (`clinic_config/settings`), unlocking doctor CRUD, consultation fee edits, and revenue audit access.
  - Restored Doctor Editing modal (`DoctorListScreen`), allowing owners to modify name, specialty, phone, available schedule days, and consultation fees.

### Fixed
- **Defensive Patient Model Parsing:** Resolved `type Null is not a subtype of type String` during phone lookup by handling null `id`, `phoneNumber`, `gender`, and multi-type `lastVisitDate` (Firestore Timestamp, ISO String, or DateTime).
- **Service Layer Composite Uniqueness:** Updated `BookingService.hasAppointmentForDate` and `FirebaseService.hasAppointmentForDate` to accept composite patient name and doctor ID parameters.

---

## [1.10.0] — 10-10-2026

### Added
- **Agile Reception Queue & Discretionary Chamber Dispatch:**
  - **Top-Level Collapsible Accordion (`CompletedConsultationsAccordion`):** Groups finished visits into a collapsible drawer, keeping the lobby list focused on waiting patients.
  - **Discretionary Chamber Dispatch:** Added high-visibility `[SEND IN]` button with chamber occupancy collision detection, alerting counter staff if a consultation is currently active.
  - **Non-Destructive Late / Bypassed Token Tracking:** Pure domain `partitionQueueForReception` tags waiting tokens lower than active chamber token as `[BYPASSED / LATE]` without mutating database status, preserving receptionist triage autonomy for emergencies.
- **Air Traffic Control Arrival Estimation:**
  - Dynamic estimated arrival time calculations (`AppointmentEngine.calculateEstimatedWindow`) considering chamber start times, consultations ahead, and 8-minute OPD averages.
- **Responsive Layout Optimization Across Clinic Counter Tiers:**
  - **FHD 21.5"-24" Counter Monitors (1920×1080):** Container constraints expanded up to 1800px with side-by-side split panels (`flex: 6` Queue, `flex: 4` Doctor Roster) for widths $\ge 1050\text{px}$.
  - **Counter Laptops (1366×768 & 1536×864):** Vertical budget optimizations suppressing redundant headers, compacting padding, and rendering today's live queue above the fold.
  - **Double AppBar Suppression:** Suppressed secondary screen AppBars when embedded in `OwnerShell` on desktop.

---

> **Historical Release Notes:**  
> For changes in versions v1.0.0 through v1.9.0, see [`docs/archive/CHANGELOG_ARCHIVE.md`](docs/archive/CHANGELOG_ARCHIVE.md).
