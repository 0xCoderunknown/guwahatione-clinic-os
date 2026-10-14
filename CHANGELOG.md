# 📋 GuwahatiOne Clinic OS — Changelog

All notable updates, clinical workflows, and architectural changes to **GuwahatiOne Clinic OS** are documented in this file in reverse chronological order.

> 💡 **Product & Engineering Reference:**  
> - **For Product Management:** Each milestone highlights operational workflow impacts across Clinic Counter (Reception), Doctor Chamber, and Clinic Owner dashboards.  
> - **For AI Architecture & Coding:** Always defer to [`AGENTS.md`](AGENTS.md) and [`docs/SCHEMA_AND_MODELS.md`](docs/SCHEMA_AND_MODELS.md) for active domain invariants, database contracts, and system rules.  
> - **Zero Backward-Compatibility Debt (Invariant #10):** Historical notes document evolution. Never revive deprecated models, legacy shims, or retired facades mentioned in older milestones.  
> - **Date Standard:** All release and display dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## [1.29.1] — 14-10-2026

### Architectural Compliance & Invariant #10 Debt Remediation
- **Purged Deprecated Enum Alias `PaymentType.paid` (Invariant #10):**
  - Removed obsolete `@Deprecated('Use paidCash or paidUpi') static const PaymentType paid` alias from `lib/models/appointment.dart`.
  - Migrated appointment booking UI (`AddAppointmentDialog` in `lib/widgets/booking/add_appointment_dialog.dart`) to use canonical payment resolution (`_selectedPayment.isPaid` and `PaymentType.paidCash`).
  - Migrated test fixtures across test suites to strictly canonical `PaymentType.paidCash`.
- **Quality & Verification Gates:**
  - 100% clean static analysis (`flutter analyze` — 0 issues).
  - All 184 automated tests passing cleanly (`flutter test`).

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

---

> 📦 **Historical Foundation Release Notes:**  
> For foundational releases prior to v1.15.0 (v1.0.0 — v1.14.0), see [`docs/archive/CHANGELOG_ARCHIVE.md`](docs/archive/CHANGELOG_ARCHIVE.md).
