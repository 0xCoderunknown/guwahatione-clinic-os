# 🔍 GuwahatiOne Clinic OS — Complete File-by-File Codebase Audit & Architectural Review

> **Date:** 20-10-2026  
> **Status:** Temporary Audit Document for PM Review & Strategic Refactoring  
> **Target:** 115 Dart source files in `lib/`, 39 test suites in `test/`, Firestore configuration, and operational models  
> **Standard:** Zero Tolerance for Data Loss, Financial Inaccuracies, Clinical Collisions, or Hidden Tech Debt  

---

## 📊 1. Quantitative Inventory & Architecture Overview

### Codebase Breakdown by Layer

| Layer | Directory | File Count | Total Lines | Primary Responsibilities | Health Rating |
|---|---|---|---|---|---|
| **Engines** | `lib/core/engines/` | 7 | 1,972 | Pure Dart domain logic: queue partitioning, pharmacology, revenue math, cashier reconciliation, patient search | 🟢 Excellent (Pure, 100% testable) |
| **Models** | `lib/models/` | 13 | 1,475 | Domain data structures, Firestore serialization, immutability, date formatting | 🟢 Clean & Robust |
| **Providers** | `lib/providers/` | 2 | 1,172 | App state management (`AuthProvider`, `ClinicProvider` **[GOD OBJECT]**) | 🔴 Critical Hotspot (`ClinicProvider`) |
| **Services** | `lib/services/` | 10 | 1,143 | Firestore transactions, atomic counters, streaming channels, sound, offline caching | 🟢 Solid & Transactional |
| **Screens** | `lib/screens/` | 14 | 4,944 | Full-page views: shells, chamber, encounter, doctor management, login, directory | 🟡 Good (Some large files >600 lines) |
| **Widgets** | `lib/widgets/` | 55 | 11,811 | Reusable UI components across 9 domains (booking, chamber, encounter, print, queue, etc.) | 🟡 Mixed (Several monolithic widgets >700 lines) |
| **Utils & Config** | `lib/utils/`, `lib/config/` | 14 | 487 | Tenant configuration, formatters, platform print/sound/URL stubs | 🟢 Clean & Minimal |
| **Root** | `lib/` | 2 | 152 | Entrypoint (`main.dart`), Firebase configuration options | 🟢 Standard |
| **Test Suite** | `test/` | 39 | 8,978 | 306 automated unit & widget tests covering engines, workflows, concurrency, and print layouts | 🟢 Outstanding (Sub-second execution) |
| **TOTAL** | `lib/` + `test/` | **154** | **32,134** | Full Production Codebase | **Overall: Production Grade with Architectural Bloat in Provider & Top 4 Widgets** |

---

## ⚡ 2. Deep-Tissue Dissection of the "God Object" (`ClinicProvider.dart` — 879 Lines)

### 2.1 What Is It and Why Did It Become a God Object?
`ClinicProvider` (`lib/providers/clinic_provider.dart`) was initially created as a simple, centralized state container for the clinic. As features were added during Phases 1–4 (live queues, doctor roster, formulary catalogue, chamber zero-touch handshake, audio chimes, midnight auto-rollover, offline caching, and medication reconciliation), **almost every cross-cutting concern was attached directly to `ClinicProvider`**.

### 2.2 Conflated Responsibilities in `ClinicProvider`
A single class is currently managing **8 completely separate domain responsibilities**:

1. **Doctor Management & Master Roster:**
   - Active streams (`_doctorSub`), doctor caching (`_doctors`), active vs. retired filters, doctor creation, updates, leave blocking, and search preferences.
2. **Live Queue & Appointment Lifecycle:**
   - Active appointment stream (`_appointmentSub`), queue lists (`_todayAppointments`), search filtering (`_dashboardSearchQuery`), booking delegation, check-in, admission, absence, and status transitions.
3. **Midnight Date Rollover Management:**
   - Background periodic timer (`_midnightObserverTimer`, 30s interval), checking calendar date boundaries, canceling and re-subscribing live streams for unattended counter PCs.
4. **Offline Queue Caching & Network Fallback:**
   - Local cache loading (`OfflineQueueCacheService`), fallback flag (`_isOfflineFallback`), cache timestamps, error interception during network drops.
5. **Doctor Chamber Handshake & Audio Notification:**
   - Chamber calling transactions, audio trigger dispatch (`SoundService.instance.announceToken`), consultation start/end/pause signals.
6. **Master Medicine Formulary & Catalogue:**
   - Active stream (`_medicineSub`), medicine list (`_medicines`), deduplication, deletion, default formulary seeding.
7. **Patient Directory Pass-Through:**
   - Passthrough methods to `PatientService` (`searchPatient`, `getPatientsForPhone`, `savePatient`, `searchPatients`).
8. **Pure Domain Math Pass-Through:**
   - Wrapping pure engine calculations (`checkReviewEligibility`, `calculatePaymentType`, `getProvisionalNextToken`, `dailyRevenue`).

### 2.3 The Architectural Cost of the God Object
- **Rebuild Cascades:** Every call to `notifyListeners()` (e.g. typing a single character into the dashboard search query, an appointment status update, or an incoming doctor stream event) triggers rebuilds across *all* widgets watching `ClinicProvider`, unless wrapped in granular `context.select`.
- **Testing Rigidity:** To test any widget that depends on one tiny aspect of the clinic (e.g. doctor names in a dropdown), tests must mock or construct an entire `ClinicProvider` with 7 underlying mock services.
- **Cognitive Overhead:** At ~880 lines and 65 methods/getters, navigating and extending `ClinicProvider` creates a high risk of unintended side-effects.

### 2.4 Recommended Decomposition Blueprint (Zero-Breaking Facade Pattern)
We can decompose `ClinicProvider` cleanly **without breaking existing UI code or switching state management libraries**:

```
                       ┌───────────────────────────────┐
                       │   ClinicProvider (Facade)     │  <-- Existing screens continue to work 100%
                       └───────┬───────┬───────┬───────┘
                               │       │       │
             ┌─────────────────┘       │       └─────────────────┐
             ▼                         ▼                         ▼
  ┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
  │ DoctorStateDelegate │   │  LiveQueueDelegate  │   │  CatalogueDelegate  │
  │ • Doctor streams    │   │ • Appointment queue │   │ • Formulary streams │
  │ • Doctor leave/CRUD │   │ • Midnight rollover │   │ • Medicine search   │
  │ • Doctor share %    │   │ • Offline cache     │   │ • Default seeding   │
  └─────────────────────┘   └─────────────────────┘   └─────────────────────┘
```

- **Step 1:** Extract `DoctorStateDelegate`, `LiveQueueDelegate`, and `CatalogueDelegate` as lightweight controller classes.
- **Step 2:** `ClinicProvider` holds instances of these delegates and forwards calls, maintaining 100% backward compatibility for all widget calls like `context.read<ClinicProvider>().todayAppointments`.
- **Step 3 (Optional):** Expose the sub-providers via `MultiProvider` so screens can watch *only* what they need (e.g. `DoctorListScreen` watches only `DoctorProvider`).

---

## 📂 3. Comprehensive File-by-File Codebase Audit

### 3.1 Domain Engines (`lib/core/engines/`) — 7 Files (1,972 Lines)
*All engines are pure Dart, completely decoupled from Flutter UI, and 100% covered by automated unit tests.*

1. **`appointment_engine.dart` (635 lines):**
   - **Role:** Pure queue partitioning (`partitionQueueForReception`), review eligibility calculation, provisional token calculation, estimated time window algorithms, and leave summary formatting.
   - **Findings:** Impeccably pure. Cleanly implements Invariant #1 (zero deletions) and Invariant #8 (queue partitioning). Contains no Flutter dependencies.
   - **Recommendation:** Keep as-is. High test coverage in `appointment_engine_estimated_time_test.dart` and `patient_review_and_models_test.dart`.

2. **`medicine_engine.dart` (668 lines):**
   - **Role:** Pharmacological intelligence, medicine search scoring, composition parsing, dosage synthesis, NMC generic uppercase formatting, formulation defaults.
   - **Findings:** Extremely robust. Properly isolates generic chemical composition from trade names. Synthesizes Column 2 natural dosages.
   - **Recommendation:** Keep as-is. Well-tested in `catalogue_scoring_test.dart` and `medicine_engine_defaults_test.dart`.

3. **`revenue_engine.dart` (226 lines):**
   - **Role:** Realized vs. projected financial calculations, doctor payout shares (`calculateDoctorPayout`), consultation fee accounting.
   - **Findings:** Clean math. Respects `refundStatus == 'refunded'`. Handles doctor percentage share calculations accurately.
   - **Recommendation:** Keep as-is. Tested in `revenue_engine_test.dart`.

4. **`cash_handover_engine.dart` (181 lines):**
   - **Role:** Counter cash drawer reconciliation, denomination counting (₹500, ₹200, ₹100, ₹50, ₹20, ₹10), upfront cash recognition.
   - **Findings:** Successfully updated to count physical cash collected upfront regardless of visit status, eliminating discrepancies.
   - **Recommendation:** Keep as-is. Tested in `cash_handover_engine_test.dart`.

5. **`patient_search_engine.dart` (95 lines):**
   - **Role:** Pure Dart patient search scoring: phone normalization (+91, leading 0s, whitespace), name tokenization, surname matching, multi-tier ranking.
   - **Findings:** Clean, efficient, no external dependencies.
   - **Recommendation:** Keep as-is. Tested in `patient_search_and_midnight_rollover_test.dart`.

6. **`whatsapp_engine.dart` (161 lines):**
   - **Role:** Generates clean, formatted WhatsApp booking confirmations, reminder messages, and directions for patients.
   - **Findings:** Pure string generation with URL encoding. Uses Indian date format (`DD-MM-YYYY`).
   - **Recommendation:** Keep as-is. Tested in `whatsapp_engine_test.dart`.

7. **`engines.dart` (6 lines):**
   - **Role:** Barrel export file.
   - **Recommendation:** Keep as-is.

---

### 3.2 Domain Models (`lib/models/`) — 13 Files (1,475 Lines)
*Data models represent the single source of truth for Firestore documents.*

1. **`appointment.dart` (332 lines):**
   - **Role:** Core appointment/token entity. Contains `VisitStatus`, `PaymentType`, `AppointmentStatus`, queue numbers, pause flags, and refund tracking (`refundStatus`).
   - **Findings:** Fully immutable. Strict adherence to Invariant #1 (never deleted). Indian date formatting in display getters.
   - **Recommendation:** Clean and mature.

2. **`consultation.dart` (243 lines):**
   - **Role:** Append-only clinical encounter record. Contains vitals, chief complaints, examination notes, provisional diagnosis, prescription items, ordered investigations, and review date.
   - **Findings:** Implements Invariant #2 (append-only ledger). Correctly captures `carriedForwardItemsCount` and doctor NMC registration.
   - **Recommendation:** Clean and mature.

3. **`prescription_item.dart` (197 lines):**
   - **Role:** Medication line item with 3-column isolation, `MedicationAction` (`start`, `continueAction`, `stop`), rapid schedule chips, and `formattedDosageTiming`.
   - **Findings:** Fully satisfies Invariant #12 (strict 3-column isolation) and NMC generic standards.
   - **Recommendation:** Clean and mature.

4. **`patient.dart` (157 lines):**
   - **Role:** Patient demographic profile, canonical ID generation (`pat_*`), guardian details, paediatric age displays (years, months, days).
   - **Findings:** Handles canonical ID formats and phone-based legacy records cleanly.
   - **Recommendation:** Clean and mature.

5. **`doctor.dart` (134 lines):**
   - **Role:** Physician profile, specialty, fees, free review days, leave schedule, token quota, and `doctorSharePercentage`.
   - **Findings:** Fully aligned with owner financial controls and multi-doctor polyclinic requirements.
   - **Recommendation:** Clean and mature.

6. **`chamber_session.dart` (117 lines):**
   - **Role:** Real-time synchronized chamber state (`ChamberSessionStatus`: idle, ready_for_next, calling, in_consultation, consultation_ended, shift_ended).
   - **Findings:** Implements Invariant #7 (handshake protocol) and Invariant #11 (atomic single occupancy).
   - **Recommendation:** Clean and mature.

7. **`medicine.dart` (111 lines):** Master catalogue formulary model.
8. **`vitals.dart` (84 lines):** Clinical vitals entity (BP, Pulse, SpO2, Temp, Weight, Height, BMI).
9. **`prescription_template.dart` (74 lines):** 1-tap clinical template presets (e.g. URI, Fever, Dyspepsia).
10. **`diagnostic_investigation.dart` (73 lines):** Ordered lab tests / investigations model.
11. **`patient_review_eligibility.dart` (55 lines):** Result object for review fee waivers.
12. **`user_role.dart` (18 lines):** 3-tier authorization enum (owner, doctor, reception).
13. **`models.dart` (12 lines):** Barrel export file.

---

### 3.3 Providers (`lib/providers/`) — 2 Files (1,172 Lines)

1. **`auth_provider.dart` (293 lines):**
   - **Role:** Manages active user session, PIN verification (Reception `0000`, Doctor 4-digit, Owner 6-digit), active doctor session binding.
   - **Findings:** Cleanly enforces Invariant #7 and role guarding. Zero UI dependencies.
   - **Recommendation:** Healthy.

2. **`clinic_provider.dart` (879 lines) — [GOD OBJECT]:**
   - **Role:** Monolithic application state coordinator.
   - **Findings:** Analyzed in detail in Section 2.
   - **Recommendation:** High-priority candidate for modular delegation refactor.

---

### 3.4 Services Layer (`lib/services/`) — 10 Files (1,143 Lines)

1. **`booking_service.dart` (318 lines):**
   - **Role:** Atomic queue allocation via Firestore transaction, check-in, admission, appointment status mutation, session closure, upcoming reservations.
   - **Findings:** Strictly transactional. Adheres to Invariant #1 (zero deletions).
   - **Recommendation:** Healthy.

2. **`chamber_service.dart` (225 lines):**
   - **Role:** Manages chamber handshake lifecycle documents (`counters/chamber_{doctorId}_{date}`). Atomic lock claiming, ready/end/pause signals.
   - **Findings:** Strictly prevents collisions (Invariant #11).
   - **Recommendation:** Healthy.

3. **`patient_service.dart` (171 lines):**
   - **Role:** Firestore queries for patient documents (`/patients`). Queries by `phoneNumber`, canonical ID, and household groups.
   - **Findings:** Integrates pure `PatientSearchEngine` for accurate multi-field search.
   - **Recommendation:** Healthy.

4. **`consultation_service.dart` (104 lines):**
   - **Role:** Append-only consultation storage (`/consultations`). Fetches chronological encounter history and latest active medications.
   - **Findings:** Adheres to Invariant #2.
   - **Recommendation:** Healthy.

5. **`catalogue_service.dart` (87 lines):** Master medicine catalogue CRUD, deduplication, default formulary seeding.
6. **`sound_service.dart` (77 lines):** Audio chime and token announcement player (`WebAudio` on web, silent stubs on mobile/desktop).
7. **`offline_queue_cache_service.dart` (68 lines):** Local storage queue cache for broadband dropouts via `shared_preferences`.
8. **`doctor_service.dart` (50 lines):** Firestore streams and updates for `/doctors`. Never deletes documents (Invariant #1).
9. **`firestore_paths.dart` (33 lines):** Centralized canonical path constants for all Firestore collections and documents.
10. **`services.dart` (10 lines):** Barrel export file.

---

### 3.5 UI Screens (`lib/screens/`) — 14 Files (4,944 Lines)

1. **`add_doctor_screen.dart` (857 lines) — [HOTSPOT #3]:**
   - **Role:** Screen for adding and editing doctor profiles, schedule days, consultation fees, review days, token caps, and doctor revenue share.
   - **Findings:** Very large file. Combines form inputs, leave calendar multi-picker, admin passkey dialogs, and timing dropdowns in one file.
   - **Recommendation:** Extract `DoctorLeaveCalendarSection` and `DoctorFinancialsSection` into reusable sub-widgets.

2. **`consultation_encounter_screen.dart` (619 lines):**
   - **Role:** The main doctor consultation workspace. Coordinates vitals, complaints, examination, medication reconciliation, investigations, advice, and sign-off.
   - **Findings:** Substantially modularized! Sub-sections were extracted into `lib/widgets/encounter/`. Wrapped in `PopScope` to prevent accidental data loss or chamber lock freezes.
   - **Recommendation:** Healthy.

3. **`doctor_list_screen.dart` (590 lines):**
   - **Role:** Owner screen listing active and inactive doctors, doctor details cards, leave management, and retirement passkey authorization.
   - **Findings:** Works well, respects responsive desktop/mobile constraints and suppresses duplicate AppBars inside `OwnerShell`.
   - **Recommendation:** Healthy.

4. **`owner_shell.dart` (525 lines):**
   - **Role:** Master responsive application shell. Left navigation rail on desktop, bottom navigation bar on mobile, unified top AppBar, broadband offline fallback banners, and global F2 shortcut for walk-in bookings.
   - **Findings:** Clean responsive design. Implements desktop container max-width up to 1800px per Invariant #5.
   - **Recommendation:** Healthy.

5. **`doctor_chamber_screen.dart` (509 lines):**
   - **Role:** Doctor's consultation room dashboard. Live token display, breather status, next patient trigger, emergency door override bar, and completed visit history.
   - **Findings:** Solid orchestration of Invariant #7 and Invariant #8.
   - **Recommendation:** Healthy.

6. **`login_screen.dart` (444 lines):** Role selection (Reception, Doctor, Owner) and PIN pad verification.
7. **`appointment_list_screen.dart` (436 lines):** Tabular reception appointment list with doctor filtering and Indian date navigation.
8. **`patient_directory_screen.dart` (349 lines):** Patient directory lookup by phone, name, or canonical ID.
9. **`medicine_catalogue_screen.dart` (276 lines):** Formulary search and curation.
10. **`prescription_print_screen.dart` (268 lines):** Isolated print preview with `Enter`/`Esc` keyboard shortcuts.
11. **`statistics_screen.dart` (215 lines):** Daily and historical clinic financial metrics, consultation counts, and cashier reconciliation.
12. **`doctor_daily_details_screen.dart` (197 lines):** Single doctor daily breakdown for owners.
13. **`dashboard_screen.dart` (111 lines):** Thin wrapper hosting reception KPI strip, queue card, and doctor roster.
14. **`screens.dart` (14 lines):** Barrel export file.

---

### 3.6 UI Widgets (`lib/widgets/`) — 55 Files (11,811 Lines Across 9 Domains)

#### A. Booking Widgets (`lib/widgets/booking/` — 7 files)
- **`add_appointment_dialog.dart` (864 lines) — [HOTSPOT #2]:**
  - **Role:** Universal walk-in booking and advance reservation modal dialog.
  - **Findings:** High cyclomatic complexity. Manages date selection, patient lookup, paediatric fields, doctor selection, leave alerts, fee waivers, receipt preview, and offline warning banners.
  - **Recommendation:** Split into smaller focused sub-widgets: `BookingDemographicStep` and `BookingReviewStep`.
- `booking_patient_fields.dart` (438 lines): Paediatric/adult demographic inputs.
- `booking_payment_section.dart` (399 lines): Payment type chips, review eligibility banner, fee display.
- `quick_check_in_dialog.dart` (391 lines): 1-tap desk check-in modal.
- `booking_duplicate_warning_banner.dart` (196 lines): Alert for existing appointments on date.
- `booking_eligibility_banner.dart` (139 lines): Review fee eligibility summary.
- `booking_date_and_mode_section.dart` (60 lines): Date picker and walk-in vs. advance chips.

#### B. Dashboard Widgets (`lib/widgets/dashboard/` — 6 files)
- **`dashboard_queue_card.dart` (883 lines) — [HOTSPOT #1]:**
  - **Role:** Primary reception live queue dashboard table.
  - **Findings:** Contains doctor filter chips, search input, multi-doctor queue table, upcoming bookings preview, and dispatch action buttons.
  - **Recommendation:** Extract `UpcomingBookingsSection` and `QueueFilterToolbar` into separate sub-widgets.
- `dashboard_doctor_roster_card.dart` (429 lines): Right-side doctor presence card with chamber status chips.
- `daily_cash_handover_dialog.dart` (383 lines): Cashier handover and denomination entry dialog.
- `cash_denomination_counter_section.dart` (212 lines): Denomination multiplier grid (₹500, ₹200, ₹100, etc.).
- `dashboard_kpi_strip.dart` (138 lines): Top metric cards (Queue total, Waiting, Completed, Revenue).
- `dashboard_header_bar.dart` (122 lines): Reception title and quick action bar.

#### C. Chamber Widgets (`lib/widgets/chamber/` — 7 files)
- **`chamber_control_banner.dart` (737 lines) — [HOTSPOT #4]:**
  - **Role:** Doctor chamber top banner managing the 5-state lifecycle (idle, ready_for_next, calling, in_consultation, consultation_ended).
  - **Findings:** Highly complex state machine UI with breather countdown, end shift, and reopen shift actions.
  - **Recommendation:** Extract `ChamberShiftActions` into a dedicated widget.
- `chamber_token_card.dart` (331 lines): Big hero token card showing patient currently inside chamber.
- `chamber_door_override_bar.dart` (264 lines): Restricted emergency direct-call bar (strictly shows top 1-2 verified lobby patients).
- `chamber_queue_header.dart` (196 lines): Chamber patient queue header.
- `chamber_metrics_grid.dart` (141 lines): Doctor chamber metric counters.
- `chamber_app_bar.dart` (130 lines): Chamber top bar with sound mute toggle.
- `chamber_archive_banner.dart` (30 lines): Immutable read-only banner for historical dates.

#### D. Clinical Encounter Widgets (`lib/widgets/encounter/` — 11 files)
- **`encounter_form_state.dart` (593 lines):** Clean state container for active consultation form. Handles draft autosave and 1-click `[CARRY FORWARD]`.
- `vitals_and_exam_section.dart` (446 lines): Vitals grid, C/O, O/E, Diagnosis inputs.
- `encounter_dialogs.dart` (427 lines): Historical consultation accordion and exit confirmation dialogs.
- `staged_medicine_form.dart` (444 lines): Prescription item composer with rapid schedule chips (`1-0-0 Khali Pet`, etc.).
- `reconciliation_item_row.dart` (375 lines): Chronic medication reconciliation row with 1-tap `STOP` toggle.
- `rx_reconciliation_section.dart` (330 lines): Active medication table with 1-click carry forward button.
- `rx_search_results_view.dart` (292 lines): Formulary auto-complete search results.
- `patient_header_section.dart` (216 lines): Patient demographics and passive allergy alert chip.
- `diagnostic_review_section.dart` (209 lines): Ordered lab investigations.
- `advice_and_orders_section.dart` (200 lines): Diet advice and next review dropdown with 1-tap `Not Needed / SOS`.
- `rx_template_presets_bar.dart` (139 lines): 1-tap OPD template chips.

#### E. Queue, Patient, Print & Common Widgets (`lib/widgets/` — 24 files)
- `appointment_accordion.dart` (468 lines): Expandable queue item card.
- `accordion_dispatch_section.dart` (450 lines): Dispatch buttons with doctor-paced chamber handshake lock.
- `doctor_consultation_accordion.dart` (340 lines): Patient visit history viewer.
- `queue_chamber_dispatch_action.dart` (313 lines): Dispatch action button.
- `patient_lookup_card.dart` (292 lines): Search result card in patient directory.
- `print_header_and_demographics.dart` (287 lines): Letterhead header with configurable top margin.
- `token_receipt_dialog.dart` (271 lines): OPD token slip preview.
- `print_medications_table.dart` (263 lines): Strict 3-column isolated prescription table (Invariant #12).
- `completed_consultations_accordion.dart` (167 lines): Completed patients accordion.
- `metric_kpi_card.dart` (164 lines): Reusable metric KPI card.
- `print_orders_and_footer.dart` (143 lines): Investigations, follow-up advice, and doctor signature block.
- `accordion_status_actions.dart` (138 lines): Quick status change buttons.
- `clinic_date_nav_bar.dart` (110 lines): Date picker bar with Indian date formatting (`DD-MM-YYYY`).
- `section_card.dart` (108 lines): Standard card styling wrapper.
- `token_badge.dart` (105 lines): Formatted token badge.
- `payment_badge.dart` (96 lines): Payment status badge.
- `appointment_status_chip.dart` (79 lines): Appointment status chip.
- `widgets.dart` (62 lines): Centralized widgets barrel file.

---

### 3.7 Utilities, Config & Root (`lib/utils/`, `lib/config/`, `lib/`) — 16 Files (639 Lines)

- `clinic_config.dart` (92 lines): Tenant config (clinic name, address, phone, `defaultLetterheadTopMarginMm`).
- `default_medicines.dart` (249 lines): 20+ default OPD medicines with compositions and dosages.
- `formatters.dart` (94 lines): Indian currency (₹), Indian dates (`DD-MM-YYYY`), phone number formatters.
- `app_constants.dart` (17 lines): App-wide layout and duration constants.
- Platform stubs (`platform_print*`, `platform_sound*`, `platform_url*`): 11 stub and web implementation files.
- `main.dart` (81 lines): App entrypoint, `MultiProvider` wiring, theme initialization.
- `firebase_options.dart` (71 lines): Firebase project configuration.

---

## 🏆 4. Adherence to Core Invariants & Red Lines

| Invariant / Operational Rule | Compliance Status | Evidence & Audit Notes |
|---|---|---|
| **#1 Zero Deletions in Firestore** | ✅ **100% Compliant** | Verified in `BookingService`, `ClinicProvider`, and `DoctorService`. Appointments are marked `absent` with amount ₹0; doctor deletion is blocked at rule and service levels. |
| **#2 Longitudinal Append-Only Records** | ✅ **100% Compliant** | Past consultations are strictly read-only; new visits append separate documents to `/consultations`. |
| **#5 Responsive Layout (No Dead Margins)** | ✅ **100% Compliant** | Container constraints allow up to 1800px on FHD monitors. Usable vertical height budgeted for 1366×768 laptops. Duplicate AppBars suppressed inside `OwnerShell`. |
| **#6 Mandatory Indian Date (`DD-MM-YYYY`)** | ✅ **100% Compliant** | All user-facing screens, receipt dialogs, print previews, and changelogs strictly format dates as `DD-MM-YYYY`. |
| **#7 Doctor-Paced Chamber Handshake** | ✅ **100% Compliant** | Strict 5-state lifecycle enforced in `ChamberService` and `ChamberControlBanner`. Zero forced admission during breather or consultation. |
| **#8 Temporal Guarding (Today-Only Actions)** | ✅ **100% Compliant** | Historical dates lock Doctor Chamber into read-only mode (`ChamberArchiveBanner`). Live actions strictly guarded to `today`. |
| **#9 Restricted Emergency Door Self-Call** | ✅ **100% Compliant** | `ChamberDoorOverrideBar` strictly filters to top 1–2 verified lobby check-ins (`waitingInLobby` with payment confirmed). Unpaid or remote reservations excluded. |
| **#10 Zero Backward-Compatibility Debt** | ✅ **100% Compliant** | No legacy adapter shims or polyfills. Clean domain models throughout. |
| **#11 Single-Occupant Chamber Integrity** | ✅ **100% Compliant** | Chamber lock claimed inside Firestore transaction before mutating appointment state; zero pre-emption guarantee. |
| **#12 Strict 3-Column Prescription Isolation** | ✅ **100% Compliant** | Col 1 (Medicine & Composition), Col 2 (Dosage & Timing), Col 3 (Duration / Status). Zero mixing between columns. |

---

## 🔥 5. The Top 5 Complexity Hotspots

These 5 files account for **4,222 lines** (~13% of the entire codebase) and present the highest risk for maintenance friction:

| Rank | File Path | Line Count | Primary Complexity Drivers |
|---|---|---|---|
| **1** | [dashboard_queue_card.dart](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_queue_card.dart) | 883 | Monolithic reception table: search filters, multi-doctor view, upcoming bookings accordion, table headers, and dispatch logic all in one file. |
| **2** | [clinic_provider.dart](file:///d:/Android/guwahatione-clinic-os/lib/providers/clinic_provider.dart) | 879 | **The God Object.** Conflates doctors, live queue, formulary, chamber handshake, offline caching, and midnight rollover. |
| **3** | [add_appointment_dialog.dart](file:///d:/Android/guwahatione-clinic-os/lib/widgets/booking/add_appointment_dialog.dart) | 864 | Monolithic modal: handles date picker, phone lookup, demographic inputs, paediatric inputs, fee calculations, receipt preview, and offline fallbacks. |
| **4** | [add_doctor_screen.dart](file:///d:/Android/guwahatione-clinic-os/lib/screens/add_doctor_screen.dart) | 857 | Large form combining scheduling chips, financial inputs, leave calendar multi-select, and passkey authorization dialogs. |
| **5** | [chamber_control_banner.dart](file:///d:/Android/guwahatione-clinic-os/lib/widgets/chamber/chamber_control_banner.dart) | 737 | Complex 5-state chamber status card combining breather countdown, shift close modal, emergency release dialog, and audio trigger integration. |

---

## 🎯 6. Strategic Refactoring Roadmap & Recommendation

### Recommendation: Is a Refactoring Run Worth It?
**YES, BUT TARGETED & NON-DESTRUCTIVE.**  
The domain logic, engines, and automated tests are rock-solid (306 passing tests, zero analyzer errors). A blind, ground-up rewrite would be reckless and unnecessary.  
Instead, a **surgical, 3-phase modularization** will dramatically enhance developer velocity, eliminate rebuild bloat, and make the codebase effortless for both AI agents and human developers to maintain.

### Phase 1: High-Impact, Zero-Risk Extractions (Immediate)
1. **Decompose `dashboard_queue_card.dart` (883 $\to$ ~350 lines):**
   - Extract `UpcomingBookingsSection` into `lib/widgets/dashboard/upcoming_bookings_section.dart`.
   - Extract `QueueFilterToolbar` into `lib/widgets/dashboard/queue_filter_toolbar.dart`.
2. **Decompose `add_appointment_dialog.dart` (864 $\to$ ~380 lines):**
   - Extract `BookingDemographicStep` and `BookingSummaryDialog` into dedicated sub-widgets.
3. **Decompose `add_doctor_screen.dart` (857 $\to$ ~400 lines):**
   - Extract `DoctorLeaveCalendarSection` and `DoctorFinancialsSection`.

### Phase 2: Decompose the `ClinicProvider` God Object (High Architectural Value)
1. Implement the **Facade Pattern**:
   - Extract `DoctorStateDelegate` (~150 lines) to manage doctor streams, leave, and updates.
   - Extract `LiveQueueDelegate` (~250 lines) to manage appointment streams, midnight rollover, and offline caching.
   - Extract `CatalogueDelegate` (~120 lines) to manage medicine streams and formulary deduplication.
2. `ClinicProvider` delegates to these sub-controllers while preserving its existing public API:
   - **Zero breaking changes** to any screen or widget.
   - Drastically reduced file size (~250 lines).
   - Unit-testable delegates in complete isolation.

### Phase 3: Fine-Grained Widget Rebuild Optimization
1. In high-traffic widgets (`DashboardTodayQueueCard`, `DoctorRosterCard`, `ChamberControlBanner`), replace broad `context.watch<ClinicProvider>()` calls with granular `context.select` queries (e.g. `context.select<ClinicProvider, bool>((p) => p.isOfflineFallback)`).
2. Prevents full-screen rebuilds on counter PCs during typing or queue stream heartbeats.
