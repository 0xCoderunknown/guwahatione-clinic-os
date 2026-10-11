# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.12.0] — 2026-10-11

### Architecture & Refactoring
- **Screen Coordinator Scaffold Standardization Across All Screens:**
  - Migrated all screens in `lib/screens/` to strict **Thin Coordinator Scaffolds** (orchestrating only layout bounds, responsive breakpoints, lifecycles, and navigation triggers).
  - **Relocated `AddAppointmentDialog`:** Moved from `lib/screens/` to `lib/widgets/booking/add_appointment_dialog.dart` and re-exported in `lib/widgets/widgets.dart`.
  - **Catalogue Engine Delegation:** Stripped in-memory filtering and sorting calculations out of `MedicineCatalogueScreen`, delegating to pure domain methods `MedicineEngine.filterAndSortCatalogue` and `MedicineEngine.countUniqueMolecules`.
  - **Extracted `DoctorStatisticsCard`:** Extracted doctor stats cards and KPI metrics from `StatisticsScreen` into `lib/widgets/dashboard/doctor_statistics_card.dart` (reducing `StatisticsScreen` to 98 lines).
  - **Extracted `DoctorRosterCard`:** Extracted doctor profile cards, PIN badges, and action buttons from `DoctorListScreen` into `lib/widgets/common/doctor_roster_card.dart` (reducing `DoctorListScreen` to 85 lines).
  - **Extracted `DoctorDailyBreakdownTable`:** Extracted breakdown tables and fee footers from `DoctorDailyDetailsScreen` into `lib/widgets/dashboard/doctor_daily_breakdown_table.dart` (reducing `DoctorDailyDetailsScreen` to 38 lines).
  - **Extracted `DoctorForm`:** Extracted doctor registration and edit forms from `AddDoctorScreen` into `lib/widgets/common/doctor_form.dart` (reducing `AddDoctorScreen` to 28 lines).
  - **Extracted Auth Sub-Forms:** Extracted `DoctorLoginForm` and `ReceptionLoginForm` into `lib/widgets/auth/`, reducing `LoginScreen` from 418 lines down to 215 lines.
  - **Extracted `ChamberQueueList`:** Extracted token sequence list and empty state from `DoctorChamberScreen` into `lib/widgets/chamber/chamber_queue_list.dart`.

---

## [1.11.0] — 2026-10-11

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

## [1.10.0] — 2026-10-10

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

## [1.9.0] — 2026-10-10

### Added
- **Doctor-Reception 2-Way Chamber Handshake Protocol:**
  - **Synchronized Pacing & The Breather:** When a physician clicks **"CONSULTATION END (Save & Sign)"**, the chamber session atomically transitions to `consultation_ended`. Reception immediately sees the doctor is wrapping up / taking a breather.
  - **Doctor Readiness Trigger:** Prominent, single-click **"NEXT PATIENT"** banner (`ChamberControlBanner`) enabling doctors to signal `ready_for_next` at their own pace.
  - **Reception Physical Presence Verification:** Reception desk visually alerts with 🟢 `READY FOR NEXT`. Reception verifies physical presence at the counter, skips absent tokens, and admits verified patients into the chamber (`calling`).
  - **Zero-Confusion Auto-File Load:** Admitting a patient pushes their exact clinical chart to the doctor's chamber screen with zero risk of loading a skipped patient's record.
  - **Reception Breather Speed Bump:** Added confirmation dialog in `DashboardTodayQueueCard` and `AppointmentAccordion` preventing accidental patient admission while the doctor is on break.
  - **Doctor Emergency Safety Valve:** Added manual direct-admission override dialog in `ChamberTokenCard` allowing physicians to admit patients directly if the reception desk is offline or unresponsive.
- **Indian Date Format Standardization (DD-MM-YYYY / DD-MM-YY):**
  - Centralized all date representations across the app to Indian standard numerical formatting (`dd-MM-yyyy`, `dd-MM-yy`, and `EEEE, dd-MM-yyyy`) via `AppFormatters`.
  - Standardized booking dialogs, print headers, print follow-up dates, daily detail headers, and accordion cards to use `AppFormatters`.

### Changed
- Replaced direct `DateFormat` invocations across print previews, accordions, and booking dialogs with centralized `AppFormatters`.
- Bumped project version to `1.9.0+12`.

## [1.8.3] — 2026-10-09

### Fixed
- **Documentation & Repo Hygiene:** Corrected clone repository URL in `README.md` to point to `guwahatione-clinic-os`.
- **Testing Documentation:** Replaced obsolete test prohibition notices in `README.md` and `CONTRIBUTING.md` with active automated test guidance (35/35 passing domain & widget tests) and CI verification steps.
- **Project Structure Tree:** Updated `README.md` services directory breakdown to include all modular sub-services in `lib/services/`.
- **CI Build Pipeline:** Injected mock Firebase options template (`lib/firebase_options.dart.example`) prior to analyzer execution in GitHub Actions CI workflow, resolving failure caused by gitignored secret configuration in clean clones.

## [1.8.2] — 2026-10-09

### Added
- **Modular Sub-Service Decomposition (`lib/services/`):**
  - `FirestorePaths`: Centralized type-safe path, date key, and counter key builders.
  - `BookingService`: Dedicated service for atomic bookings, queue allocations, and appointment queries.
  - `ConsultationService`: Dedicated service for append-only encounters and longitudinal timelines.
  - `ChamberService`: Zero-touch chamber calling broadcast and session lifecycle management.
  - `CatalogueService`: Master medicine catalogue curation, deterministic seeds, deduplication, and search.
  - `DoctorService` & `PatientService`: Targeted services for doctor roster and patient demographics.
- **AI Operational Recipes (`.agents/recipes/`):**
  - `add_clinical_field.md`: Standardized checklist for clinical encounter field additions.
  - `modify_booking_rule.md`: Standardized checklist for booking and queue policy modifications.
- **Fast Domain Automated Testing Re-Enabled:**
  - Removed test skip annotations; enabled sub-second suite execution (35/35 tests passing).
  - Added automated test execution step to GitHub Actions CI workflow.
  - Enabled `unawaited_futures` rule in `analysis_options.yaml`.

### Changed
- Refactored `FirebaseService` into a lightweight, backward-compatible facade delegating to modular services.
- Archived pre-1.8 release notes to `docs/archive/CHANGELOG_ARCHIVE.md` to optimize context token footprint.

## [1.8.1] — 2026-10-09

### Fixed
- Queue counters now follow the documented per-doctor, per-day key and `currentNumber` field.
- Saved doctor sessions wait for the initial doctor list before validation.
- Patient `lastVisitDate` now reflects completed consultations rather than scheduled bookings, and booking preserves existing patient fields.
- Queue allocation, appointment creation, and patient demographic upsert now commit atomically.
- Updated AI maintenance guidance and added CI dependency-resolution and analyzer checks.

## [1.8.0] — 2026-10-07

### Added
- **Core Domain Engine Architecture (`lib/core/engines/`):**
  - **`RevenueEngine` (`lib/core/engines/revenue_engine.dart`):** Pure Dart financial engine calculating realized revenue (completed visits strictly), chamber KPIs, doctor fee shares, and owner analytics summaries.
  - **`AppointmentEngine` (`lib/core/engines/appointment_engine.dart`):** Single source of truth for 14-day same-doctor free review eligibility, consultation fee resolution, and queue status partitioning (`pending`, `completed`, `absent`).
  - **`MedicineEngine` (`lib/core/engines/medicine_engine.dart`):** Unified multi-mode search scoring, clinical default OPD regimens (form dosages, fasting PPIs, bedtime statins, course durations), and prescription reconciliation segregation.
  - **`engines.dart`:** Central barrel export for domain engines.
- **Unified UI Component Consolidation (`lib/widgets/common/`):**
  - **`MetricKpiCard` (`lib/widgets/common/metric_kpi_card.dart`):** Unified metric card supporting both vertical (`MetricCardLayout.vertical`) and horizontal (`MetricCardLayout.horizontal`) responsive layouts.
  - Re-exported `MetricKpiCard` in `lib/widgets/widgets.dart`.

### Changed
- **Decoupled Math from UI Presentation:**
  - `ClinicProvider`: Rewired `dailyRevenue`, `checkReviewEligibility`, and `calculatePaymentType` to use `RevenueEngine` and `AppointmentEngine`.
  - `ChamberMetricsGrid`: Replaced 6 manual `.where()` and `.fold()` passes with a single call to `RevenueEngine.calculateChamberKpis`; delegated `ChamberMetricTile` to `MetricKpiCard`.
  - `DoctorDailyDetailsScreen`: Stripped inline `.fold()` in `build()` method; rewired to `RevenueEngine.calculateRealizedRevenue`.
  - `StatisticsScreen`: Stripped inline stats calculations in `_buildDoctorCard`; rewired to `RevenueEngine.calculateDoctorAnalytics`. Replaced custom date header with `ClinicDateNavBar`.
  - `DashboardKpiStrip`: Replaced inline `.where()` in `build()` with `RevenueEngine.calculateDailyMetrics`; delegated `DashboardMetricCard` to `MetricKpiCard`.
  - `AddAppointmentDialog`: Replaced inline fee ternary calculations with `AppointmentEngine.resolveConsultationFee` and eligibility checks with `AppointmentEngine.evaluateReviewEligibility`.
  - `AppointmentAccordion`: Dynamically resolves consultation fees using doctor configuration via `AppointmentEngine.resolveConsultationFee`.
  - `AppointmentListScreen`: Replaced custom date row with unified `ClinicDateNavBar`.

---

> **Historical Release Notes:**  
> For changes in versions v1.0.0 through v1.7.0, see [`docs/archive/CHANGELOG_ARCHIVE.md`](docs/archive/CHANGELOG_ARCHIVE.md).
