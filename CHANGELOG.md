# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
