# 📋 GuwahatiOne Clinic OS — Changelog

All notable updates, clinical workflows, and architectural changes to **GuwahatiOne Clinic OS** are documented in this file in reverse chronological order.

> 💡 **Product & Engineering Reference:**  
> - **For Product Management:** Each milestone highlights operational workflow impacts across Clinic Counter (Reception), Doctor Chamber, and Clinic Owner dashboards.  
> - **For AI Architecture & Coding:** Always defer to [`AGENTS.md`](AGENTS.md) and [`docs/SCHEMA_AND_MODELS.md`](docs/SCHEMA_AND_MODELS.md) for active domain invariants, database contracts, and system rules.  
> - **Zero Backward-Compatibility Debt (Invariant #10):** Historical notes document evolution. Never revive deprecated models, legacy shims, or retired facades mentioned in older milestones.  
> - **Date Standard:** All release and display dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

## [1.36.5] — 19-10-2026

### Prescription Table: Strict 3-Column Isolation, Uppercase NMC Generic Formatting & Experimental Flag
- **Operational & Presentation Impact:**
  - **Strict 3-Column Prescription Table Isolation (Invariant #12):** Refactored `PrintMedicationsTable` into 3 dedicated, unmixed columns:
    - **Column 1 (Medicine):** Strictly brand name and uppercase bracketed composition (`Telma 40 tablet [TELMISARTAN 40MG]`, conforming to National Medical Commission standards). Pure generics avoid redundant duplication. Removed badges like `[NEW]` and `[CONT]`.
    - **Column 2 (Dosage & Timing):** Strictly dosage, frequency, timing, and optional patient notes (`1 tab • in morning • before food`).
    - **Column 3 (Duration):** Strictly course duration (`X Days`), ongoing chronic therapy (`To Continue`), or explicit discontinuation (`To STOP`).
  - **Single Unified Table with STOP Support:** Discontinued medications render in the table with `To STOP` in the Duration column alongside the active regimen.
  - **🧪 Experimental Flag (`hidePrescriptionComposition`):** Added to `ClinicFeatureFlags` (default: `false`). When enabled, hides generic chemical compositions on prescriptions, rendering only trade brand names (`Telma 40 tablet`).
  - **AI Constitution Lock:** Added permanent invariant Rule 12 and Red Line to `AGENTS.md` and `.agents/rules/clinic_os_rules.md` to prevent column mixing or badge regressions.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 244 unit and widget tests passing green.

---

## [1.36.4] — 15-10-2026

### Reception Dashboard Cleanups: Streamlined Mobile Header, Clean Fee Presentation & Refined Doctor Status Badges
- **Operational & Presentation Impact:**
  - **Eliminated Mobile Booking Redundancy:** Removed duplicate appointment booking button from `DashboardScreen` mobile AppBar (which redundantly opened `AddAppointmentDialog`). Mobile receptionists now use the single, prominent `FloatingActionButton.extended` in `OwnerShell`. Patient queue check-in and chamber dispatch actions next to patient cards were untouched.
  - **Clean Patient Card Payment Presentation (`Appointment.paymentSummary`):** Replaced cluttered `Fee: ₹500 (Paid (Cash))` with clean, unbracketed presentation:
    - Paid visits: `₹500 Paid`
    - Statutory review: `Free Review`
    - Discretionary waiver: `Free Waiver`
    - Pending collections: `Post-Pay` or `Unpaid`
  - **Refined 5-State Doctor Chamber Roster Status Lifecycle:**
    - `[ABSENT]`: Prominently rendered in red (`#FEE2E2` / `#DC2626`) when doctor has planned leave today (`AppointmentEngine.isDoctorOnLeave`).
    - `[NO OPD TODAY]`: Warm amber badge (`#FEF3C7` / `#B45309`) when the doctor does not sit on the current weekday as per their schedule (`!AppointmentEngine.isDoctorAvailableOnDate`).
    - `[NOT ARRIVED]`: Muted slate badge (`#F1F5F9` / `#64748B`) when scheduled today, before the physician starts their chamber or arrives at clinic.
    - `[IN CHAMBER]`: Green badge (`#DCFCE7` / `#15803D`) once physician hits "Ready for Next / First Patient" and onwards for the day when not attending a patient.
    - `[CONSULTING]` / `[Consulting: Patient Name]`: Kept intact in blue (`#DBEAFE` / `#1D4ED8`) for active chamber encounters.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 239 unit and widget tests passing green.

---

## [1.36.3] — 15-10-2026

### Single Source of Truth Documentation Consolidation
- **Architecture & AI Guardrail Impact:**
  - **Pruned Redundant Documentation:** Purged legacy archives (`docs/archive/`) and historical decision logs (`docs/decisions/`) to establish a zero-hallucination, single source of truth for AI agents and developers.
  - **Single Source Architecture:** Root `AGENTS.md` is the canonical product constitution, `docs/SCHEMA_AND_MODELS.md` is the database contract, and `docs/PRODUCT_ROADMAP.md` is the active backlog.
  - **Clean Context Footprint:** Removed outdated planning hypotheses and contradictory proposals, ensuring consistent chamber handshake rules and strict single-occupancy guarantees across all agents.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 234 unit and widget tests passing green.

---

## [1.36.2] — 15-10-2026

### Enforce Doctor-Paced Handshake Integrity & Purge Illegal Encounter Pre-Emption
- **Operational & Engineering Impact:**
  - **Enforce Invariant #7 & #11 (Doctor-Paced Chamber Handshake & Single-Occupancy):** Purged `ChamberCallingAlertBar`, `_listenToChamberSessionAlert`, and `_switchToIncomingPatient` from `ConsultationEncounterScreen`. 
  - **Zero Consultation Pre-Emption:** Receptions buttons are strictly locked (`Chamber Occupied` or `Doctor on Break`) whenever a physician is conducting an encounter or in a breather. Reception cannot dispatch patients into an active consultation.
  - **Doctor Paced Admission:** Doctor completes encounter ➔ enters `consultation_ended` breather ➔ taps "Next Patient" ➔ status transitions to `ready_for_next` ➔ Reception "SEND IN" button unlocks.
  - **Documentation Alignment:** Corrected `docs/CODEBASE_AUDIT_AND_REFACTOR_PLAN.md` to remove flawed recommendation of "switching patient prompts" during consultations, reinforcing `AGENTS.md` as the single canonical source of truth for chamber invariants.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 234 unit and widget tests passing green.

---

## [1.36.1] — 15-10-2026

### Doctor Planned Leave & Extended Week Absence System with Dynamic Range Messaging
- **Operational & Engineering Impact:**
  - **End-to-End Doctor Leave Pipeline:** Wired `Doctor.blockedDates` through domain engine, services, booking desk, and owner settings.
  - **Dynamic Leave Duration Messaging (`AppointmentEngine.formatDoctorLeaveSummary`):**
    - Single day: `"Doctor is on leave on DD-MM-YYYY"`
    - 2 days: `"Doctor is on leave on DD-MM-YYYY and DD-MM-YYYY"`
    - 3+ days / Extended Week: `"Doctor is on leave from DD-MM-YYYY to DD-MM-YYYY"`
    - Omitted doctor name in message since the doctor selector already displays the physician.
  - **Zero Booking on Leave Days:** `AppointmentEngine.isDoctorOnLeave` strictly blocks booking. `AddAppointmentDialog` renders a red `BookingDoctorLeaveWarningBanner` and disables the confirmation button (`onPressed: null`).
  - **Server-Side & Provider Guard:** `ClinicProvider.addAppointment` validates `isDoctorOnLeave` and throws with the exact formatted summary if bypassed.
  - **Owner Profile Leave Management (`AddDoctorScreen`):** Added a dedicated "Planned Leave & Blocked Dates" section with `Add Day` and `Add Week / Range` pickers and removable `DD-MM-YYYY` chips.
  - **Service Gateway:** Added `DoctorService.updateDoctorLeave(doctorId, blockedDates)` and `ClinicProvider.updateDoctorLeave`.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 234 unit and widget tests passing green (7 new tests in `test/doctor_leave_system_test.dart`).

---

## [1.36.0] — 15-10-2026

### Streamlined Medicine Schema (Form in Name, Strength in Composition), Catalogue Regimen Defaults & 1-Key "Verify & Next" Prescribing Loop
- **Operational & Engineering Impact:**
  - **Streamlined Medicine Data Model:** Per PM mandate, eliminated redundant separate `form`, `strength`, and `category` fields across `Medicine`, `PrescriptionItem`, and Firestore contracts. Commercial brand name and dosage form are unified in `productName` (e.g. `Telma 40 tablet`, `Dolo 650 tablet`, `Ascoril D Plus syrup`), chemical active ingredient and molecule strength in `composition` (e.g. `Telmisartan 40mg`, `Paracetamol 650mg`), and pharma company in `manufacturer` (e.g. `Glenmark`, `Micro Labs`, `GSK`). Zero backward-compatibility debt or shims introduced (Invariant #10).
  - **Formulary Regimen Defaults:** Added `defaultDosage`, `defaultFrequency`, `defaultTiming`, and `defaultDurationDays` to `ClinicProvider.addMedicine`, `Medicine` model, and `AddMedicineDialog`. Custom clinic medicines now store readymade directions for instant 1-click chamber selection.
  - **1-Key (Enter) "Verify & Next" Prescribing Loop:** In `StagedMedicineForm`, hitting Enter on any regimen field commits the drug to the prescription. `EncounterFormState.medSearchFocusNode` immediately reclaims focus on the medicine search box and resets the query, allowing the physician to type the next medication without ever touching the mouse.
  - **Composition-First Search Scorer:** Updated `MedicineEngine.searchAndGroup` match scoring hierarchy so chemical molecule matches (100 exact, 90 prefix, 70 contains) strictly outrank trade brand matches (95 exact, 80 prefix, 60 contains).
  - **Passive Allergy Chip Retained:** Documented and confirmed PM rejection of automated allergy collision checking; allergies remain a passive, high-visibility free-text chip in Step 1 of the encounter.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 227 unit and widget tests passing green.

---

## [1.35.2] — 15-10-2026

### Dynamic Doctor Review Window in WhatsApp Prescriptions & FHD Monitor (1800px) Expansion
- **Operational & Engineering Impact:**
  - **Dynamic WhatsApp Review Policy:** Refactored `WhatsAppEngine.formatPrescriptionMessage` to dynamically accept and reflect the doctor's configured `freeReviewDays` policy. If a specialist or doctor configures `freeReviewDays == 0` (no free review), the review policy note is completely omitted, eliminating customer disputes. Custom review windows (e.g. 7, 21, or 30 days) are formatted cleanly.
  - **Auto-Pass Doctor Review Days on Dispatch:** Wired `PrescriptionPrintScreen` and `AccordionStatusActions` to lookup and pass the active doctor's `freeReviewDays` directly into `WhatsAppEngine`.
  - **FHD Counter Monitor Constraint Expansion (Invariant #5):** Expanded container constraints to `maxWidth: 1800` across `PatientDirectoryScreen`, `DoctorChamberScreen`, and `MedicineCatalogueScreen`, eliminating 260px–410px of dead blank margins on standard 1080p FHD clinic counter monitors.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 227 unit and widget tests passing green (1 new test in `test/whatsapp_engine_test.dart`).

---

## [1.35.1] — 15-10-2026

### Cash Drawer vs. Digital UPI Reconciliation Segregation
- **Operational & Engineering Impact:**
  - **Segregated Physical Notes from Bank UPI:** Updated `CashHandoverEngine` to separately calculate `totalPhysicalCash` (physical currency notes collected at the counter via `paidCash` and `postPay`) and `totalUpiRevenue` (digital UPI payments credited directly to clinic bank account).
  - **Zero False Cash Shortage Alert:** In `DailyCashHandoverDialog`, the cash drawer discrepancy calculation now compares physical denomination counts strictly against `totalPhysicalCash`. Fixed the operational flaw where reception was falsely alerted of a severe cash deficit equal to all UPI transactions.
  - **4-Metric Financial KPI Strip:** Upgraded dialog header to distinctly display *Physical Cash (Drawer)*, *UPI (Bank)*, *Total Realized Revenue*, and *Completed OPD Patients*.
  - **Doctor Breakdown Grid with UPI & Total:** Added dedicated *Cash* and *UPI* columns to the doctor breakdown table, providing instant visibility into physical cash handed over vs digital collections.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 226 unit and widget tests passing green.

---

## [1.35.0] — 15-10-2026

### Unified 2-Column Medicine Search, Composition Cards & Experiment Flag
- **Operational & Engineering Impact:**
  - **Unified Dual-Column Search Engine:** Replaced manual brand/salt toggle pill in `RxReconciliationSection` with simultaneous search across Column 1 (`productName`) and Column 2 (`composition` / `strength`) in `MedicineEngine.searchAndGroup`. Doctors can type either product name (e.g. `Telma 40`) or chemical molecule (e.g. `Telmisartan`) without mode switching.
  - **3-Letter Trigger & Short Alphanumeric Allowance:** Enforced a minimum 3-character threshold to prevent noisy partial queries, with intelligent exception for 2-character alphanumeric pharmacology terms (e.g. `O2`, `D3`, `B6`).
  - **Composition Card UI (`[COMPOSITION]` with `{Products}`):** Grouped search results into high-contrast clinical cards featuring bracketed uppercase chemical headers (e.g. `[TELMISARTAN 40MG]`) with selectable trade brand buttons (`{Telma 40} (Glenmark)`, `{Telmikind 40} (Mankind)`).
  - **Readymade Values & Auto-Population:** Selecting any product automatically pre-populates dosage (`1 Tablet`), frequency (`1-0-0`), timing (`After Food`), and duration (`To continue` / `30 days`), reducing prescribing friction to 1 click while remaining fully editable.
  - **Streamlined Duration Dropdown:** Replaced raw text input + filter chip with a standardized duration dropdown (`To continue`, `30 days`, `15 days`, `14 days`, `10 days`, `7 days`, `5 days`, `3 days`, `Custom`).
  - **🧪 Experiment Flag (`enableGroupedCompositionCards`):** Added configurable flag in `ClinicFeatureFlags` allowing client installations to toggle between grouped composition cards and a streamlined flat brand-first direct selection list.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 226 unit and widget tests passing green (6 new tests in `test/catalogue_scoring_test.dart`).

---

## [1.34.1] — 15-10-2026

### Prescription Snapshot & Catalogue Immunity
- **Operational & Engineering Impact:**
  - **Point-in-Time Clinical Snapshots:** Upgraded `PrescriptionItem` to capture an immutable snapshot of `name`, `composition`, `strength`, `form`, and `manufacturer` at prescribing time.
  - **Catalogue Mutation & Purge Immunity:** Formularies and medicine catalogues can now be edited, renamed, merged, or completely purged without modifying or corrupting historical consultation records, printed prescriptions, or WhatsApp summaries.
  - **Zero Join Dependency on View / Reprint:** Prescription viewer and `PrintMedicationsTable` render directly from the append-only consultation snapshot with zero runtime reliance on the active `medicines` collection.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 220 unit and widget tests passing green (2 new tests in `test/prescription_snapshot_test.dart`).

---

## [1.34.0] — 15-10-2026

### Patient Identity & Multi-Patient Household Model
- **Operational & Engineering Impact:**
  - **Decoupled Identity from Phone Numbers:** Replaced phone-keyed documents in `patients` with generated canonical patient IDs (`pat_{timestamp}_{suffix}` or UUID). Phone numbers now serve as non-unique household contact indices, preventing family members (e.g. mother, newborn infant, elderly grandparent) from overwriting each other's demographic profiles.
  - **Isolated Longitudinal Clinical Charts:** Consultations, prescriptions, and allergy histories now link strictly to `patientId` instead of phone numbers, preventing chart cross-contamination while preserving historical fallback resolution for legacy unmigrated records.
  - **Infant & Paediatric Demographics:** Replaced integer-only age with structured `ageMonths` and `ageDays` alongside `formattedAge` (e.g. `"4 Months"`, `"18 Days"`), completely eliminating misleading `"0 Years"` representations on clinical prescriptions and printed artifacts.
  - **Guardian & Caregiver Support:** Added optional `guardianName` and `guardianRelation` fields across patient records, appointments, consultations, printed letterheads, and WhatsApp digital prescription messages (`"c/o Sunita Sharma, Mother"`).
  - **Reception Family Picker & Household Discovery:** `AddAppointmentDialog` now displays family member selection chips when a contact phone matches multiple patients, accompanied by an `"+ Add Member"` option that auto-populates the shared contact number while provisioning a distinct patient identity.
  - **Household-Aware Duplicate Booking Guard:** `AppointmentEngine.hasDuplicateAppointment` evaluates both `patientId` and patient name, allowing multiple family members to consult with the same doctor on the same day while strictly blocking duplicate bookings for the same individual.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 218 unit and widget tests passing green (5 new tests in `test/patient_identity_household_test.dart`).

---

## [1.33.5] — 15-10-2026

### Chamber Handshake Typing & Stream Performance Optimization
- **Operational & Engineering Impact:**
  - **Eliminated $N+1$ Stream Subscriptions:** Refactored `DashboardDoctorRosterCard` to subscribe once at the card level via `provider.streamAllChamberSessions(DateTime.now())` instead of instantiating individual stream builders in `itemBuilder`.
  - **Strongly Typed `ChamberStatus` Domain Enum:** Introduced `ChamberStatus` enum (`idle`, `readyForNext`, `calling`, `inConsultation`, `consultationEnded`) in `lib/models/chamber_session.dart`. Replaced magic string comparisons across `ChamberControlBanner` and `DoctorChamberScreen`.
  - **Fine-Grained Context Selection in Booking:** Switched `AddAppointmentDialog` doctor listener to `context.select<ClinicProvider, List<Doctor>>` to avoid full focus tree rebuilds during queue streams. Added `_isSelectedDateToday` guards on provisional token estimation for future date bookings.
  - **Pure Render Cycle in Auth:** Removed mutation side effect on `_selectedDoctor` in `LoginScreen.build()`.
  - **Uniform Indian Date & Time Formats:** Swapped manual string concatenations in `AppointmentEngine` with `AppFormatters.date()` and `AppFormatters.time()`.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 213 unit and widget tests passing green.

---

## [1.33.4] — 15-10-2026

### Autonomous AI Maintainability & Low-Token Architecture Refactoring
- **Operational Impact:**
  - **100% Functional & Visual Parity:** Preserved all counter booking, reception queue, doctor chamber handshake, cash handover, and patient directory workflows with zero UX divergence or regression.
  - **Pure Domain Engine Layering:** Relocated 140 lines of clinical review eligibility calculation from data model `PatientReviewEligibility` into dedicated pure domain engine `AppointmentEngine.evaluateReviewEligibility` (`lib/core/engines/appointment_engine.dart`). `PatientReviewEligibility.calculate` delegates directly to `AppointmentEngine`, keeping full backward-compatibility across all test suites.
  - **Decomposed Large Monolithic UI Files into Modular Sub-Widgets:**
    - `AddAppointmentDialog` (`lib/widgets/booking/`): Reduced from 875 lines to 715 lines by extracting `BookingDateAndModeSection` and `BookingDuplicateWarningBanner` / `BookingOffDayWarningBanner`.
    - `DashboardTodayQueueCard` (`lib/widgets/dashboard/`): Reduced from 815 lines to 578 lines by extracting `QueueChamberDispatchAction` (`lib/widgets/queue/`), eliminating ~240 lines of duplicate chamber dispatch presentation.
    - `DailyCashHandoverDialog` (`lib/widgets/dashboard/`): Reduced from 577 lines to 395 lines by extracting `CashDenominationCounterSection`.
    - `PatientLookupCard` (`lib/widgets/patient/`): Reduced from 656 lines to 305 lines by extracting `DoctorConsultationAccordion`.
    - `OwnerShell` (`lib/screens/`): Reduced from 591 lines to 377 lines by extracting `OwnerShellAppBar` (`lib/widgets/common/`).
  - **Clean Barrel Exports:** Added all new modular components to `lib/widgets/widgets.dart` for single-point import ergonomics.
  - **AI SOP Maintenance Recipes:** Created 3 new SOP checklist recipes in `.agents/recipes/`:
    - `add_dashboard_kpi.md`: Protocol for adding new dashboard KPI metric cards.
    - `modify_print_layout.md`: Protocol for modifying prescription, letterhead, and slip print formats.
    - `add_system_setting.md`: Protocol for adding feature flags and clinic system settings.
- **Verification Gate:**
  - `flutter analyze`: 0 errors, 0 warnings.
  - `flutter test`: All 213 unit and widget tests passing green.

---

## [1.33.3] — 15-10-2026

### Idempotent Doctor Title Normalization & Doctor Form Ergonomics
- **Operational Impact:**
  - **Zero Duplicate Titles (`Dr. Dr.`):** Completely eliminated duplicate `"Dr. Dr."` prefixes that previously occurred when doctor names already stored with title (e.g. `"Dr. Bhaskar Thakuria"`) were interpolated inside UI widgets using hardcoded `'Dr. ${...}'`.
  - **Consistent Title Display Everywhere:** Ensured doctor names registered without title (e.g. `"Upasana Talukdar"`) consistently render with the professional medical title `"Dr. Upasana Talukdar"` across printed prescriptions, consultation encounter headers, chamber app bars, booking dropdowns, and counter queue cards.
  - **Resilient Avatar Initials:** Upgraded avatar initials from naive `doc.name[0]` (which erroneously yielded `'D'` for `"Dr. Bhaskar"`) to pure domain initials generator `AppFormatters.doctorInitials(doc.name)` (yielding `'BT'`).
  - **30-Minute Shift Timing Dropdowns:** Replaced manual free-text typing in `AddDoctorScreen` with two 30-minute dropdowns (`Shift Start` to `Shift End`), standardizing formats to canonical `"$startTime – $endTime"` (e.g. `11:00 AM – 2:30 PM`) while preventing typos.
  - **Intelligent Awkward / Midnight Timing Warning:** Proactively warns clinic owners with an amber banner when an inverted or awkward shift is configured (such as an overnight shift ending after midnight or shifts falling in late night hours), preventing scheduling blunders.
  - **Curated Department / Specialty Dropdown:** Upgraded specialty input from free-text to a curated dropdown of top 15 Indian OPD specialties plus an `"Other (Custom)..."` fallback text input, eliminating inconsistent spelling across doctor rosters.
  - **Logical Form Hierarchy:** Re-ordered `AddDoctorScreen` so the Free Review Window (input + quick chips `0d`, `7d`, `14d`, `21d`, `30d`) is positioned directly above the Available Days chips, removing the awkward shift timing separation.
- **Architectural Touchpoints:**
  - `lib/utils/formatters.dart`: Introduced pure helper `AppFormatters.cleanDoctorName(name)` and streamlined `AppFormatters.doctorTitle(name)` and `AppFormatters.doctorInitials(name)`.
  - `lib/models/doctor.dart`: Added computed getters `doctor.titleName` and `doctor.cleanName`.
  - `lib/screens/add_doctor_screen.dart`: Applied `AppFormatters.doctorTitle` on save, implemented start/end 30-min dropdowns with awkward timing validation, curated specialty dropdown with custom fallback, and re-ordered sections.
  - `docs/PRODUCT_ROADMAP.md`: Logged future horizons P16 (Multi-Shift Split Daily OPD Timings), P17 (Doctor Extended Credentials, Accolades & Bio), and P18 (Multi-Specialty Department Tagging).
  - `test/app_formatters_test.dart` & `test/add_doctor_form_test.dart`: Added comprehensive unit and widget tests (suite now 213 passing tests).

---

## [1.33.2] — 14-10-2026

### Indian OPD Optimizations: Doctor Schedule Warnings, Counter Token Receipts, Bulk Absence Close & PostPay De-emphasis
- **Operational Impact:**
  - **Doctor Sitting Days (`availableDays`) Non-Blocking Schedule Warning:** In `AddAppointmentDialog`, booking a doctor on an off-day (e.g. Saturday when doctor only sits Mon/Wed/Fri) now renders an amber non-blocking schedule banner (`⚠️ Dr. [Name] does not normally sit on Saturdays...`), preventing accidental bookings while preserving receptionist flexibility for special duty or emergency shifts.
  - **Counter Token Receipt / Paid Slip Printing (🧪 Pilot Experiment):** Added `TokenReceiptDialog` (gated under `ClinicFeatureFlags.enableTokenReceiptPrint`) formatted for thermal POS / A6 slip printing. Features clinic branding, prominent `#N` queue token hero, Indian formatted date (`DD-MM-YYYY`), patient/doctor details, payment status (`₹500 (Paid (Cash))` or `₹0 (FREE Review)`), and 1-tap browser print. Accessible immediately after booking via a `[PRINT SLIP]` SnackBar action and persistently via a "Print Token Slip" button on `AppointmentAccordion`.
  - **Bulk "Close Session (Doctor Absent)" Action (🧪 Pilot Experiment):** When a consulting doctor is unexpectedly absent or cancels on short notice, clinic owners can now close the doctor's entire session in 1 click from `DashboardDoctorRosterCard` options (gated under `ClinicFeatureFlags.enableBulkSessionClose`). Atomically marks all un-consulted tokens as `AppointmentStatus.absent` with `amountCollected: 0` in a single Firestore batch write. Strictly preserves Invariant #1 (Zero Deletions) by retaining all token slots on the operational ledger.
  - **De-emphasized `postPay` Counter Payment Option:** Reordered payment options in `BookingPaymentSection` to place `postPay` at the bottom with a caution label (`Post-Pay (Exit Collect — Use with Caution)`) and an amber counter warning reminding reception that fees must be collected on exit, reducing cash leakage risks in busy OPD walk-in clinics. Reordered queue choice chips in `AppointmentAccordion` accordingly.
  - **Roadmap Governance & Pruning (Scrapped P14):** Formally retired proposed `PaymentType.freeConcession` / `freeDoctorDiscretionary` from `PRODUCT_ROADMAP.md` as redundant with `PaymentType.freeFamily` ("Family / Complimentary"), preventing ledger schema bloat and duplicate concession bookkeeping.
- **Architectural Touchpoints:**
  - `lib/core/engines/appointment_engine.dart`: Added pure domain method `AppointmentEngine.isDoctorAvailableOnDate` (zero UI dependencies).
  - `lib/config/clinic_config.dart`: Added `enableTokenReceiptPrint` and `enableBulkSessionClose` experimental toggles to `ClinicFeatureFlags`.
  - `lib/services/booking_service.dart`: Added `closeDoctorSessionForDate` atomic batch write.
  - `lib/providers/clinic_provider.dart`: Added role-guarded `closeDoctorSession` and updated `bookAppointment` to return `Future<Appointment>`.
  - `lib/widgets/print/token_receipt_dialog.dart`: Created thermal-ready receipt dialog with `printDocument()` browser trigger.
  - `lib/widgets/booking/add_appointment_dialog.dart`: Added `_buildOffDayWarningBanner` and post-booking `[PRINT SLIP]` SnackBar trigger.
  - `lib/widgets/booking/booking_payment_section.dart`: Reordered payment dropdown items with Post-Pay at bottom and cautionary banner.
  - `lib/widgets/dashboard/dashboard_doctor_roster_card.dart`: Added "Close Session (Doctor Absent)" options menu with double confirmation modal.
  - `lib/widgets/queue/appointment_accordion.dart`: Added "Print Token Slip" button and reordered payment choice chips.
  - `docs/SCHEMA_AND_MODELS.md`: Documented `notes` field in `appointments` collection and `ClinicFeatureFlags` specification under Section 10.E.
  - `docs/PRODUCT_ROADMAP.md` & `CONTRIBUTING.md`: Scrapped P14 and updated delivery tracking.
  - `test/reception_metrics_and_token_cap_test.dart` & `test/token_receipt_and_session_close_test.dart`: Added 4 automated unit and widget tests (total suite 209 tests passing).

---

## [1.33.1] — 14-10-2026

### Mobile Reception Responsiveness: Walk-In Floating Button & Responsive Queue Patient Cards
- **Operational Impact:**
  - **Prominent Mobile Walk-In Entry Point:** Restored the missing walk-in registration workflow on mobile devices by introducing an extended `FloatingActionButton` (`+ Book Walk-In`) on reception operational tabs (Dashboard & Queue) and an AppBar `Walk-In` header action in `DashboardScreen`, ensuring counter receptionists on mobile phones can immediately register walk-in patients with a single tap.
  - **Responsive Reception Queue Patient Cards:** Completely overhauled the layout of patient queue cards in "Today's Live Queue" (`DashboardTodayQueueCard`) on mobile devices. Replaced tight desktop `ListTile` horizontal squeezing with a dedicated mobile card format:
    - Vertical patient information hierarchy (Name on top line with ellipsis, Phone & Doctor on line 2, Fee & Payment Type on line 3).
    - Ellipsis-protected estimated wait time strip.
    - Full-width, thumb-friendly operational action row for desk check-ins and chamber dispatch (`Send Token #N into Chamber`, `Waiting for Doctor to Signal Ready`, `Doctor Busy Consulting Token #X`, `Doctor on Break`).
  - **Overflow-Proof Dashboard Headers & Badges:** Protected card headers (`DashboardTodayQueueCard`, `DashboardDoctorRosterCard`, and `AppointmentAccordion`) against horizontal overflows on compact mobile phone viewports (360px–390px) by wrapping titles and badges in flexible layouts.
  - **Mobile-Adaptive Patient Lookup Cards:** Updated `PatientLookupCard` in `PatientDirectoryScreen` to display the `+ Book Walk-In` button full-width beneath patient demographics on screens < 600px, avoiding horizontal squeeze.
- **Architectural Touchpoints:**
  - `lib/screens/owner_shell.dart`: Added `FloatingActionButton.extended` in `_buildMobileShell`.
  - `lib/screens/dashboard_screen.dart`: Added mobile AppBar `Walk-In` action button.
  - `lib/widgets/dashboard/dashboard_queue_card.dart`: Implemented `_buildMobileQueueItem`, responsive card header, and dedicated mobile action bar.
  - `lib/widgets/dashboard/dashboard_doctor_roster_card.dart`: Made header and status badges flexible and overflow-proof.
  - `lib/widgets/patient/patient_lookup_card.dart`: Made master demographic header and booking button responsive.
  - `lib/widgets/queue/appointment_accordion.dart`: Made advance phone booking check-in banner responsive to narrow viewports.
  - `test/mobile_reception_view_test.dart`: Added 3 automated widget tests covering mobile FAB, header button, and overflow-proof patient queue cards (total suite 205 tests passing).

---

## [1.33.0] — 14-10-2026

### Patient Directory & Multi-Doctor Lookup with Zero-Egress Initial State
- **Operational Impact:**
  - **Zero-Egress Patient Search:** Added dedicated `Patients` tab to the primary desktop sidebar and mobile navigation bar. Loads with zero automatic Firestore reads until an explicit 10-digit phone number or patient name query is entered, avoiding unnecessary database egress.
  - **Multi-Doctor Clinical Segregation (Singular Master Card + Accordions):** Each unique patient is presented as 1 singular master card with demographic badges (`Age`, `Gender`, `Phone`, and `⚠️ Allergies`). Past consultations with different physicians (e.g., Cardiology vs Dermatology) are cleanly segregated into expandable doctor accordions, revealing active medications, diagnosis, advice, and a direct `View / Print Prescription` preview without duplicate patient card clutter.
  - **1-Tap Walk-In Booking from Lookup:** Embedded a `+ Book Walk-In` action on the patient card that opens `AddAppointmentDialog` with patient phone, name, age, and gender pre-populated, enabling rapid re-booking with any doctor.
- **Architectural Touchpoints:**
  - `lib/services/patient_service.dart`: Added `searchPatients(query)` with exact phone doc lookup, prefix matching, and case-normalized name queries.
  - `lib/providers/clinic_provider.dart`: Exposed `searchPatients(query)` and consultation history access.
  - `lib/screens/patient_directory_screen.dart`: Created full responsive directory screen (max-width 1400 on counter PC/laptop, double-AppBar suppression).
  - `lib/widgets/patient/patient_lookup_card.dart`: Created patient card with doctor consultation accordions, active prescription tables, and booking action.
  - `lib/widgets/booking/add_appointment_dialog.dart`: Updated to accept optional `initialPatient` and `initialDoctor` for instant pre-population.
  - `lib/screens/owner_shell.dart`: Integrated `Patients` destination into `NavigationRail` and `BottomNavigationBar`.
  - `test/patient_directory_test.dart`: Added automated widget tests covering zero-egress initial state, phone/name search, multi-doctor consultation segregation, and walk-in booking (202 tests passing).

---

## [1.32.3] — 14-10-2026

### Reception Metrics Refinement, Doctor Schedule Display & Walk-In Token Cap Indicator
- **Operational Impact:**
  - **Doctor Sitting Schedule & Preserved Live State:** In `DoctorChamberRoster`, replaced static fee text with the doctor's active sitting schedule (`Mon, Wed, Fri • 6:00 PM – 8:30 PM`), while strictly preserving operational chamber statuses: `IDLE`, `READY`, `ON BREAK`, token counters, and the live consultation indicator `Consulting: [patient_name]`.
  - **Compact Token Cap Indicator (Walk-In Booking):** In `AddAppointmentDialog`, added a minimal, high-signal badge directly beneath the doctor selector with 4 smooth color-coded threshold states: Normal `[ 12/18 Booked ]` (neutral grey), Runway Alert `[ ⚠️ 16/18 Booked • 2 Left ]` (amber), At Limit `[ ⚠️ 18/18 Full ]` (orange), and Over Cap `[ 🔴 19/18 • Extra Token ]` (red outline; allows walk-in booking without blocking).
  - **Clean 4-Stage Reception Funnel:** Updated the top dashboard metrics strip to cleanly reflect front-desk pipeline progression: `Total Booked` (total scheduled today), `In Lobby` (physically arrived & paid), `Completed` (consultations finished), and `No-Show` (absent/cancelled) maintaining balanced 2×2 mobile geometry and 4-column desktop layout.
- **Architectural Touchpoints:**
  - `lib/models/doctor.dart`: Added `shiftTiming` (default: `'6:00 PM – 8:30 PM'`), `dailyTokenLimit` (default: `18`), and `formattedSchedule` getter.
  - `docs/SCHEMA_AND_MODELS.md`: Updated `doctors` collection schema documentation.
  - `lib/core/engines/appointment_engine.dart`: Added pure domain methods `calculateBookedTokensCount` and `evaluateTokenCapStatus` with `TokenCapStatus` enum (zero UI dependencies).
  - `lib/widgets/dashboard/dashboard_doctor_roster_card.dart`: Subtitle now renders doctor specialty and active sitting schedule; status badge displays `Consulting: [patient_name]` during active consultations.
  - `lib/widgets/booking/booking_payment_section.dart`: Rendered compact token cap pill directly under doctor dropdown.
  - `lib/widgets/booking/add_appointment_dialog.dart`: Passed calculated booked tokens to `BookingPaymentSection`.
  - `lib/widgets/dashboard/dashboard_kpi_strip.dart`: Updated KPI cards to 4-stage pipeline.
  - `lib/screens/add_doctor_screen.dart` & `lib/providers/clinic_provider.dart`: Added configuration fields for shift timing and daily token cap.
  - `test/reception_metrics_and_token_cap_test.dart`: Added 12 automated unit and widget tests covering all threshold transitions and UI displays (198 tests passing).

---

## [1.32.2] — 14-10-2026

### Refactored Desktop Dashboard Header & Reception Ergonomics
- **Operational Impact:**
  - **Eliminated 60px Dead Band:** Standalone date card strip consolidated directly into the primary top AppBar line (`Overview Dashboard • Wednesday, 14-10-2026`), elevating KPI metrics and live queue above the fold for counter PC monitors and 1366×768 laptops.
  - **Sharpened Action Button Hierarchy:** High-frequency primary action `+ Book Walk-In (F2)` styled with high-contrast filled teal; end-of-day `Cash Handover` de-emphasized to a clean outline button; lobby chime toggle condensed into a compact icon button.
  - **Enhanced Reception Triage & Active Chip Contrast:** Selected doctor filter chips now display prominent primary fill with white text; doctor roster badges accurately signal triage states (`READY` soft green, `IN CONSULTATION` soft blue, `IDLE`/`ON BREAK` neutral grey); repetitive consultation duration copy replaced with clean specialty and fee details.
- **Architectural Touchpoints:**
  - `lib/screens/owner_shell.dart`: Consolidated date and subtitle into desktop AppBar header; streamlined action buttons.
  - `lib/widgets/dashboard/dashboard_header_bar.dart`: Removed standalone date strip card; rendered `Instant Queue Search` bar directly.
  - `lib/screens/dashboard_screen.dart`: Adjusted vertical spacing for streamlined header flow.
  - `lib/widgets/dashboard/dashboard_queue_card.dart`: Removed redundant queue token count badge; enhanced filter chip active contrast; refined empty state accelerator copy.
  - `lib/widgets/dashboard/dashboard_doctor_roster_card.dart`: Updated status badge triage colors and simplified microcopy.

---

## [1.32.1] — 14-10-2026

### Gated Rx Template Presets Behind ClinicConfig Experiment Flag (P9)
- **Operational Impact:**
  - **Customizable Clinical Presets:** Hardcoded prescription template preset bundles (URI, Gastritis, Diarrhea, Viral Fever, HTN) are now formally gated behind `ClinicConfig.current.features.enablePrescriptionTemplatePresets` (default: `false`).
  - **Tenant Customization:** Clinics preferring an uncluttered encounter canvas without hardcoded GP presets operate cleanly with pure brand and salt search; clinics testing the experimental preset workflow can opt in with a 1-line configuration in `lib/config/clinic_config.dart`.
- **Architectural Touchpoints:**
  - `lib/config/clinic_config.dart`: Added `enablePrescriptionTemplatePresets` (default `false`) to `ClinicFeatureFlags`; enabled tenant customization of `ClinicConfig.current`.
  - `lib/widgets/encounter/rx_reconciliation_section.dart`: Gated `RxTemplatePresetsBar` conditionally based on active feature flags.
  - `test/prescription_template_test.dart`: Added widget tests verifying preset bar suppression when flag is disabled and rendering when enabled (186 tests passing).

---

## [1.32.0] — 14-10-2026

### HK-2 Architectural Clean-Up: Lock & Audit Pruning, Template Experimentation
- **Operational Impact:**
  - **Halved Firestore Write Costs:** Eliminated the redundant, write-only `appointment_events` sub-collection across booking, check-in, admission, and completion workflows. Operational and legal auditing is preserved directly on the permanent `appointments` document ledger under Invariant #1 (Zero Deletions) with native lifecycle timestamps.
  - **Streamlined Counter Desk Booking:** Pruned distributed locking artifacts (`counters/lock_*`) in `BookingService`. Relies on the authoritative atomic serializable Firestore queue counter transaction (`counters/queue_{doctorId}_{date}`) and real-time UI duplicate detection.
  - **Preserved Credential Compliance:** Retained lightweight domain-salted SHA-256 PIN hashing (`AuthProvider.hashPin`) ensuring zero plaintext credentials in browser storage.
  - **Promoted Template Presets to 🧪 Experiment:** Tagged `RxTemplatePresetsBar` in Section 8 as a revocable interim convenience while paving the way for doctor-customizable saved templates.
- **Architectural Touchpoints:**
  - `lib/services/booking_service.dart`: Stripped lock checks, lock documents, and audit event writes from booking and state mutations.
  - `lib/services/consultation_service.dart`: Stripped audit event writing from `saveConsultation`.
  - `lib/services/firestore_paths.dart`: Removed `bookingLock`, `appointmentEvents`, and `appointmentEventDoc`.
  - `lib/models/models.dart`: Pruned `appointment_event.dart` model and barrel export.
  - `firestore.rules`: Pruned `appointment_events` security rule.
  - `docs/PRODUCT_ROADMAP.md`: Updated Section 3 (Resolved HK-2 Verdicts), Section 6 (Scrapped Items), and Section 8 (Experiment Inventory).
  - `docs/SCHEMA_AND_MODELS.md`, `docs/COMPLIANCE_AND_PRIVACY.md`, `README.md`, `AGENTS.md`: Synchronized documentation.
  - `test/booking_concurrency_and_audit_test.dart`: Updated tests; verified 184 unit and widget tests passing cleanly.

---

## [1.31.0] — 14-10-2026

### Doctor Chamber Mobile & Historical Archive De-Duplication
- **Operational Impact:**
  - **Uncluttered Chamber Header:** Removed redundant `"CHAMBER CATALOG"` badge from the chamber app bar, granting the physician's name full horizontal expansion without artificial truncation or ellipses.
  - **Compact 1-Line Archive Banner:** Replaced verbose multi-line archive box with a single, sleek 1-line status banner: `🔒 Viewing Past Records (Read-Only)`. Eliminated redundant date repetition (date is already active in the date switcher).
  - **Historical Patient Card De-duplication:** 
    - Formatted patient name cleanly as `#X • Patient Name` with full horizontal expansion.
    - Consolidated historical status into a single muted `No-Show` pill, removing redundant `"Shift Closed • Past Date"` subtitle strings and static `[ 📅 Unattended ]` trailing pills.
    - Enabled direct card-level tapping to view past consultation summaries seamlessly.
  - **Tightened Metrics Subtitles:** Shortened wordy card helper texts (e.g. `X in queue`, `Shift closed`, `Unattended`, `X paid visits`) for a snug fit on mobile viewports (< 450px).
  - **Clean Queue Empty State:** Replaced wordy placeholder text with concise, professional copy in `ChamberEmptyQueue`.
- **Architectural Touchpoints:**
  - `lib/widgets/chamber/chamber_app_bar.dart`: Doctor name wrapped with `Expanded`; removed `'CHAMBER CATALOG'` badge in standard mode.
  - `lib/widgets/chamber/chamber_archive_banner.dart`: Replaced multi-line container with a compact 1-line banner.
  - `lib/widgets/chamber/chamber_token_card.dart`: Consolidated `No-Show` badge, removed duplicate subtitles/trailing widgets on historical dates, and enabled tap-to-summary.
  - `lib/widgets/chamber/chamber_metrics_grid.dart`: Concise metric subtitles.
  - `lib/widgets/chamber/chamber_queue_header.dart`: Cleaned empty queue placeholder copy.
  - `test/chamber_read_only_archive_test.dart`: Updated and added test cases for 1-line archive banner, clean header expansion, single No-Show badge, and tap interaction (186 tests passing).

---

## [1.30.0] — 14-10-2026

### Dashboard Header Reorganization & Operational Lifecycle KPI Hierarchy
- **Operational Impact:**
  - **Eliminated Header Clutter:** Removed redundant "Lobby Waiting" pill and "Doctors Active" badges from top bars.
  - **Relocated Financial Utilities:** Moved the `[ Cash Handover ]` modal button from the date sub-bar up into the primary top-right utility area alongside `[ Chime On / Muted ]`.
  - **Keyboard-First Walk-In Booking:** Bound global hotkey `F2` to trigger `[ Book Walk-In ]` instantly without touching the mouse.
  - **Operational Lifecycle KPI Strip:** Restructured the 4 top metrics cards to track the real-world outpatient lifecycle:
    1. ⏳ **Waiting in Lobby** (`VisitStatus.waitingInLobby`) — Patients physically at the counter/lobby.
    2. 📞 **Expected / Booked** (`VisitStatus.booked`) — Phone/advance reservations not yet checked in.
    3. 🩺 **Inside Chamber** (`VisitStatus.inConsultation`) — Active patient encounters in consultation across all rooms.
    4. 🟢 **Completed** (`VisitStatus.completed`) — Finished visits today.
  - **Demoted Queue Pace:** Removed standalone `Queue Pace` card from top KPIs; embedded compact pace telemetry (`• Pace: ~8-10 min/pt`) directly into individual doctor cards in the Doctor Chamber Roster.
- **Architectural Touchpoints:**
  - `lib/providers/clinic_provider.dart`: Added typed operational lifecycle getters (`waitingInLobbyCount`, `expectedBookedCount`, `inConsultationCount`).
  - `lib/screens/owner_shell.dart`: Added `CallbackShortcuts` binding `F2` to `_openWalkInBooking`; mounted `DailyCashHandoverDialog` button in desktop AppBar utility actions; pruned redundant lobby pill.
  - `lib/widgets/dashboard/dashboard_header_bar.dart`: Streamlined date greeting row to focus strictly on calendar identity and instant phone/token search bar.
  - `lib/widgets/dashboard/dashboard_kpi_strip.dart`: Wired 4 lifecycle cards with dedicated amber, blue, purple, and green themes; pruned unused imports.
  - `lib/widgets/dashboard/dashboard_doctor_roster_card.dart`: Integrated pace subtitle into doctor chamber status rows.
  - `test/opd_checkin_payment_workflow_test.dart`: Added unit test coverage for operational lifecycle queue partitioning (185 tests passing).

---

## [1.29.1] — 14-10-2026

### Architectural Compliance & Invariant #10 Debt Remediation
- **Operational Impact:**
  - **Purged Deprecated Enum Alias `PaymentType.paid` (Invariant #10):** Enforced zero backward-compatibility debt by eliminating the obsolete `@Deprecated` `PaymentType.paid` alias. Booking workflows and test fixtures migrated directly to canonical payment types (`paidCash` / `paidUpi`) without compatibility shims or polyfills.
- **Architectural Touchpoints:**
  - `lib/models/appointment.dart`: Removed deprecated `PaymentType.paid` static const alias.
  - `lib/widgets/booking/add_appointment_dialog.dart`: Updated booking submission to use canonical payment resolution (`_selectedPayment.isPaid` and `PaymentType.paidCash`).
  - `test/`: Migrated fixtures across test suites to strictly canonical `PaymentType.paidCash`.
  - Quality Gates: Clean static analysis (0 issues) and all 184 automated tests passing cleanly.

---

## [1.29.0] — 13-10-2026

### P10: Multi-Chamber Queue Sound Announcer & Vocal Token Calling
- **Operational Impact:** When reception dispatches a patient (`[SEND IN]`), the system plays an airport clinic chime and announces the token number and doctor name over the clinic counter speakers in Indian English (*"Token 12, please proceed to Dr. Baruah"*). Includes 1-click mute toggles on Counter and Owner AppBars.
- **Architectural Touchpoints:**
  - `web/index.html` & `lib/utils/platform_sound_web.dart`: In-memory Web Audio API oscillator chime (587.33 Hz $\to$ 880 Hz) and browser Speech Synthesis API. Zero external audio asset dependencies or network latency.
  - `lib/utils/platform_sound_stub.dart`: Safe no-op stubs for desktop and test execution.
  - `lib/services/sound_service.dart`: Persistent mute state via `SharedPreferences` (`sound_announcer_muted`) with event deduplication.
  - `lib/providers/clinic_provider.dart`: Auto-triggers audio announcement upon `callTokenIntoChamber`.
  - `test/sound_service_test.dart`: 5 unit and widget tests verifying announcement triggers, deduplication, and mute state reactivity.

---

## [1.28.0] — 13-10-2026

### P9: Prescription Template Presets & Fast OPD Prescribing Pipeline
- **Operational Impact:** Doctors can prescribe standard outpatient medication regimens with a single tap from a horizontal presets bar above the medicine search field in Step 4. Collisions with ongoing chronic medications or staged prescriptions are automatically skipped by brand name or chemical molecule.
- **Architectural Touchpoints:**
  - `lib/models/prescription_template.dart`: Introduced `PrescriptionTemplate`, `PrescriptionTemplateItem`, and `TemplateApplicationResult`.
  - `lib/core/engines/medicine_engine.dart`: Added standard OPD bundles (URI / Pharyngitis, Acute Gastritis, Gastroenteritis / Diarrhea, Viral Fever / SOS, HTN Starter) and duplicate-skipping evaluation logic (`evaluateTemplateApplication`).
  - `lib/widgets/encounter/rx/rx_template_presets_bar.dart`: Horizontal ActionChip bar mounted above the medicine search input in Step 4 Prescribing & Reconciliation.
  - `test/prescription_template_test.dart`: 8 unit and widget tests covering template application, duplicate filtering, and UI chip interactions.

---

## [1.27.0] — 13-10-2026

### Architectural Compliance & Invariant #10 Remediation
- **Operational Impact:** Hardened clinic security boundaries so only verified Clinic Owner sessions can create or update doctor credentials and fee configurations.
- **Architectural Touchpoints:**
  - `lib/core/engines/revenue_engine.dart`: Purged deprecated backward-compatibility delegation methods (`calculateCashHandover`, `calculateDenominationTotal`, `calculateDiscrepancy`).
  - `lib/models/patient_review_eligibility.dart`: Purged deprecated model alias `isWithin14Days`; migrated consumers to `isWithinReviewPeriod`.
  - `lib/providers/clinic_provider.dart`: Added strict `UserRole? requestingRole` owner authorization check on `addDoctor` and `updateDoctor`.
  - `docs/SCHEMA_AND_MODELS.md` §4B: Synchronized master Chamber Calling Session schema (`date`, `calledAt`, `readyAt`, `endedAt`, `clearedAt`).

---

## [1.26.0] — 13-10-2026

### Single-Occupant Chamber Integrity & Collision Lock (Invariant #11)
- **Operational Impact:** Strict physical lock ensuring zero patient pre-emption. A doctor's chamber can hold at most one patient at any time. Reception cannot displace an active patient, and doctors cannot accidentally overwrite an ongoing consultation encounter modal.
- **Architectural Touchpoints:**
  - `lib/services/chamber_service.dart`: `callTokenIntoChamber` atomically verifies empty chamber before admission; throws `StateError` if occupied.
  - `lib/screens/appointment_list_screen.dart`: Multi-doctor queue aggregate view filters out active chamber occupants across all physicians from lobby waiting lists.
  - `lib/screens/doctor_chamber_screen.dart`: Modal lock (`_isConsultationOpen`) prevents re-entrant navigation; emergency door override bar auto-locks while chamber is occupied.
  - `AGENTS.md` & `.agents/rules/clinic_os_rules.md`: Codified Invariant #11 and Step 4 Code Review Guardrails.
  - `test/chamber_handshake_test.dart` & `test/doctor_door_override_test.dart`: Automated test suites validating occupancy locks.

---

## [1.25.0] — 13-10-2026

### Doctor-Paced Chamber Handshake Protocol (Invariant #7)
- **Operational Impact:** Eliminated forced patient admissions from reception. When a physician ends a visit, the chamber enters a "Breather" (`consultation_ended`). Reception dispatch (`[SEND IN]`) is strictly locked until the doctor explicitly taps **"NEXT PATIENT"** (`ready_for_next`), preventing physician burnout and consultation collisions.
- **Architectural Touchpoints:**
  - `lib/widgets/dashboard/dashboard_queue_card.dart`: Replaced premature "Call In" buttons with descriptive locked status badges (`Waiting for Doctor`, `On Breather`, `Doctor Busy (#N)`).
  - `lib/widgets/queue/accordion_dispatch_section.dart`: Locked dispatch and override triggers during doctor idle, breather, or active consultation.
  - `test/chamber_handshake_test.dart`: Widget test coverage for chamber lifecycle handshake states.

---

## [1.24.0] — 13-10-2026

### Counter Queue Legibility & Mobile Responsive Encounter Layout
- **Operational Impact:** Counter monitors (1920×1080) display 44px high-contrast token badges readable at standing counter distances. Mobile phones (390–430px) render fluid encounter screens with responsive bottom docks and ellipsis guards, preventing `RenderFlex` overflow errors.
- **Architectural Touchpoints:**
  - `lib/widgets/dashboard/dashboard_queue_card.dart` & `dashboard_doctor_roster_card.dart`: Enlarged typography, token badges, doctor avatars, and action button touch targets.
  - `lib/screens/consultation_encounter_screen.dart` & `lib/widgets/encounter/`: Mobile breakpoint (< 550px) adaptive bottom dock, flexible section header titles, and compressed finding strips.

---

## [1.23.0] — 13-10-2026

### Unified Desk Authentication & Action Latches
- **Operational Impact:** Counter desk login accepts both Reception PIN (`0000`) and Owner Master PIN (`849201`) from a single input field. Multi-click submit bugs on booking, doctor registration, and prescription forms are eliminated with atomic in-flight latches.
- **Architectural Touchpoints:**
  - `lib/screens/login_screen.dart` & `lib/providers/auth_provider.dart`: Unified desk login handler with fallback parity and cache sanitization.
  - `lib/widgets/booking/add_appointment_dialog.dart`, `add_medicine_dialog.dart`, `add_doctor_screen.dart`, `consultation_encounter_screen.dart`: Added `_isBooking` and `_isSaving` re-entrancy locks disabling duplicate submits.
  - `test/auth_provider_test.dart`: Added unit tests for desk authentication and session fallback.

---

## [1.22.0] — 13-10-2026

### Strict 1:1 Paid-to-Review Cycle Enforcement
- **Operational Impact:** Prevents infinite free review chaining. A paid visit entitles the patient to exactly one free review within the doctor's review window. Once used, subsequent visits automatically revert to standard consultation fees until a fresh paid visit resets the cycle.
- **Architectural Touchpoints:**
  - `lib/models/patient_review_eligibility.dart`: `PatientReviewEligibility.calculate` anchors to the most recent paid visit and scans subsequent visits for prior review consumption (`isReviewAlreadyConsumed: true`).
  - `lib/widgets/booking/add_appointment_dialog.dart`: Displays warning banner and auto-resets payment selection to `paidCash` when free review entitlement is consumed.
  - `test/patient_review_and_models_test.dart`: 3 test suites covering single-use review cycles, fresh paid visit resets, and unpaid visit handling.

---

## [1.21.0] — 13-10-2026

### Mobile Responsive Doctor Chamber Layout & Roster Hardening
- **Operational Impact:** Visiting physicians using smartphones can view chamber queues without horizontal scrolling or text clipping. Chamber banners, patient token cards, and emergency override bars fluidly stack on screens < 650px.
- **Architectural Touchpoints:**
  - `lib/widgets/chamber/chamber_control_banner.dart`: Responsive `LayoutBuilder` stacking status and actions on mobile viewports.
  - `lib/widgets/chamber/chamber_token_card.dart`: 2-row adaptive mobile card separating patient demographics from action buttons.
  - `lib/widgets/chamber/chamber_queue_header.dart` & `chamber_door_override_bar.dart`: Responsive title, badge, and live sync indicators.

---

## [1.20.0] — 13-10-2026

### Doctor-Configurable Free Review Window (0 to 30 Days)
- **Operational Impact:** Clinic owners can configure the free review window individually per doctor (`0` to `30` days, default: `14`). Visiting super-specialists can be set to `0` days (no free review; all visits billed at full fee), while surgeons or general OPD can set 7, 14, 21, or 30 days.
- **Architectural Touchpoints:**
  - `lib/models/doctor.dart`: Added `freeReviewDays` field with JSON serialization and constructor defaults.
  - `lib/screens/add_doctor_screen.dart`: Added Free Review Window input with quick-select choice chips (`0d`, `7d`, `14d`, `21d`, `30d`).
  - `lib/core/engines/appointment_engine.dart` & `lib/models/patient_review_eligibility.dart`: Replaced hardcoded 14-day checks with dynamic evaluation against `doctor.freeReviewDays`.
  - `test/patient_review_and_models_test.dart`: Unit tests for `0`-day policy rejection and `30`-day qualification.

---

## [1.19.0] — 13-10-2026

### Security Hardening & Healthcare Data Governance
- **Operational Impact:** Upgraded PIN storage from plaintext to cryptographic hashes. Documented healthcare data privacy compliance aligned with the Indian Digital Personal Data Protection (DPDP) Act 2023, ABDM policy, and NMC regulations.
- **Architectural Touchpoints:**
  - `lib/providers/auth_provider.dart`: Integrated domain-salted SHA-256 PIN hashing (`hashPin`). Plaintext credentials permanently purged from `SharedPreferences`. Automatic migration of legacy credentials on session start.
  - `docs/COMPLIANCE_AND_PRIVACY.md`: Formulated 3-tier Role-Based Access Control (RBAC), statutory 3-year record retention protocols, and consent standards.
  - `test/auth_provider_test.dart`: Tests for SHA-256 hashing and automatic legacy migration.

---

## [1.18.0] — 13-10-2026

### Atomic Concurrency Locks & Forensic Audit Trail
- **Operational Impact:** Multi-desk simultaneous bookings for the same patient, doctor, and calendar date are prevented atomically at the database boundary (0% race conditions), while family members sharing a phone number remain supported. Every operational status transition is logged to an immutable audit trail.
- **Architectural Touchpoints:**
  - `lib/services/booking_service.dart`: Transactional reservation lock at `counters/lock_{doctorId}_{yyyy-MM-dd}_{phone}_{normalizedName}` throwing `DuplicateBookingException` on collision.
  - `lib/models/appointment_event.dart`: Append-only `appointment_events` collection logging state shifts (`created`, `checkedIn`, `admitted`, `completed`, `markedAbsent`, `statusUpdated`).
  - `firestore.rules`: Locked `appointment_events` with `allow update, delete: if false;`.
  - `test/booking_concurrency_and_audit_test.dart`: 5 unit tests verifying lock generation and event serialization.

---

## [1.17.0] — 13-10-2026

### Backend Security Rules & State Reconciliation
- **Operational Impact:** Production Firestore security rules strictly lock clinical data against deletions. In-memory state synchronization ensures terminal appointment states (`completed`, `absent`) remain strictly aligned.
- **Architectural Touchpoints:**
  - `firestore.rules`: Enforced Invariant #1 (`allow delete: if false;` on appointments, consultations, patients, counters) and Invariant #2 (`allow update, delete: if false;` on consultations).
  - `lib/models/appointment.dart`: Hardened `fromJson` to reconcile `status` (`AppointmentStatus`) and `visitStatus` (`VisitStatus`).
  - `lib/services/consultation_service.dart`: Atomically updates both status fields on completion.

---

## [1.16.0 – 1.16.9] — 12-10-2026

### Architectural Consolidation, Modular Engines & Desk Workflow
- **Operational Impact:**
  - **Asynchronous Desk Check-In (v1.16.0):** Phone/advance bookings (`VisitStatus.booked`) stay isolated from active doctor queues until physical counter check-in (`waitingInLobby`). Added 1-tap quick check-in dialog with numpad shortcuts and courtesy waivers (`PaymentType.freeFamily`).
  - **Emergency Door Self-Call Guard (v1.16.1):** Doctor door self-call strictly capped to the top 1–2 verified lobby-checked-in patients (`PaymentType != unpaid`).
  - **Read-Only Historical Chamber Archive (v1.16.2 – v1.16.3):** Viewing past calendar dates switches Doctor Chamber into read-only mode (`ChamberArchiveBanner`), rendering unresolved tokens as `UNATTENDED / NO-SHOW`.
  - **Widget Architecture Consolidation (v1.16.5):** Merged 12 thin/duplicate widgets into their parent screens, reducing widget file count by 21% and deleting the legacy `FirebaseService` facade.
  - **Standalone `CashHandoverEngine` (v1.16.8):** Decoupled daily end-of-day cash drawer balancing and denomination note math into its own pure Dart domain engine file.

---

## [1.15.0 – 1.15.1] — 12-10-2026

### Offline Queue Cache, WhatsApp Engine & Daily Cash Handover
- **Operational Impact:**
  - **Offline Queue Resilience:** Daily appointments are cached locally (`SharedPreferences`). Counter PC gracefully displays cached queue data during broadband drops with visual indicator (`[ ⚡ Offline Cache ]`).
  - **WhatsApp Digital Prescription:** 1-tap `wa.me` deep link generator formats append-only prescription summaries for patient delivery in standard Indian date format (`DD-MM-YYYY`).
  - **Daily Cash Drawer Handover:** Interactive denomination counter modal (`₹500`, `₹200`, `₹100`, etc.) summarizes cash collections across completed visits and computes drawer discrepancies.
  - **Responsive Catalogue Layout (v1.15.1):** Fluidly adapts master medicine formulary across mobile, tablet, and desktop viewports.

