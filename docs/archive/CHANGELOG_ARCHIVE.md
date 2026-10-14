# 📦 GuwahatiOne Clinic OS — Changelog Archive (v1.0.0 — v1.14.0)

Historical release notes for GuwahatiOne Clinic OS prior to v1.15.0.  
For current and recent releases, see the root [`CHANGELOG.md`](../../CHANGELOG.md).

> 💡 **Product & Engineering Reference:**  
> - **Historical Scope:** Documents early foundation milestones prior to v1.15.0.  
> - **For AI Architects & Engineers:** Do **not** extract current code patterns or schemas from these historical notes. Always adhere to active standards in [`AGENTS.md`](../../AGENTS.md) and [`docs/SCHEMA_AND_MODELS.md`](../SCHEMA_AND_MODELS.md).  
> - **Retired Paradigms:** `FirebaseService` facade was deleted in v1.16.5 (use modular services in `lib/services/`). Hardcoded 14-day review was replaced in v1.20.0 by doctor-configurable `freeReviewDays` (0–30) and 1:1 cycle (v1.22.0). Deprecated `PaymentType.paid` was purged in v1.29.1 (use canonical `paidCash` / `paidUpi`). Merged widgets from v1.16.5 (`doctor_form.dart`, `PrintClinicalSnapshot`, `DoctorRosterCard`, etc.) must not be recreated.  
> - **Date Standard:** All release and display dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## [1.14.0] — 11-10-2026

### Doctor Medical Council Registration & Printout Signature Block (`P5`)
- **Operational Impact:** Doctor profiles support official State Medical Council / NMC registration credentials (e.g. `AMC-24891`, `NMC-10293`). Registration numbers print automatically under physician signatures on A4 and A5 prescription letterheads, compliant with Indian medical-legal requirements.
- **Architectural Touchpoints:**
  - `lib/models/doctor.dart`: Added optional `medicalRegNumber` field.
  - `lib/models/consultation.dart`: Added immutable `doctorRegNumber` consultation snapshot.
  - `lib/widgets/print/print_orders_and_footer.dart`: Renders doctor registration credential directly beneath the signature block.

---

## [1.12.0 – 1.13.0] — 11-10-2026

### Screen Coordinator Scaffolds & Typed Chamber Domain Model
- **Operational Impact:** Established lightweight presentation coordinators across all screens, preventing UI lag and ensuring snappy navigation on counter laptops and tablets.
- **Architectural Touchpoints:**
  - `lib/screens/`: Migrated screens to Thin Coordinator Scaffolds orchestrating layout bounds and navigation triggers while delegating calculations to pure domain engines.
  - `lib/models/chamber_session.dart`: Introduced strongly typed pure Dart domain model with status getters (`isReadyForNext`, `isCalling`, `isInConsultation`, `isConsultationEnded`, `isIdle`, `hasActivePatient`).
  - Purged raw `DocumentSnapshot` and `cloud_firestore` imports from presentation widgets.

---

## [1.11.0] — 11-10-2026

### Keyboard-First Walk-In Registration & 3-Tier User Roles
- **Operational Impact:**
  - **High-Speed Counter Registration:** Tab-chaining walk-in modal with hotkeys (`M`/`F`/`O` for gender) and 10-digit phone lookup auto-filling returning patient demographics.
  - **Provisional Token & Wait Estimation:** Instantly previews upcoming token number and estimated consultation time window upon doctor selection.
  - **Same-Day Duplicate Booking Protection:** Prevents duplicate bookings per doctor per day while preserving family members sharing a phone number.
  - **3-Tier Role Authentication:** Introduced Clinic Owner (master 6-digit PIN unlocking fee/doctor configurations), Doctor Chamber (4-digit PIN), and Receptionist (`0000`).
- **Architectural Touchpoints:**
  - `lib/widgets/booking/add_appointment_dialog.dart`: Keyboard-navigable booking modal.
  - `lib/core/engines/appointment_engine.dart`: `calculateProvisionalNextToken` and estimated wait window math.
  - `lib/providers/auth_provider.dart`: Unified 3-tier role management.

---

## [1.9.0 – 1.10.0] — 10-10-2026

### Chamber Handshake Protocol, Arrival Estimation & Indian Date Standards
- **Operational Impact:**
  - **Doctor-Reception Handshake:** Established the foundation of physician-paced chamber calling: consultation conclusion switches session to breather, prompting the doctor to signal readiness before reception dispatches the next patient.
  - **Air Traffic Control Arrival Estimation:** Computes estimated patient consultation times considering chamber start times, consultations ahead, and 8-minute OPD averages.
  - **Mandatory Indian Date Standardization:** Standardized all UI dates, printed prescriptions, and audit views to Indian numerical format (`DD-MM-YYYY` / `DD-MM-YY`) via centralized `AppFormatters`.
  - **Counter PC Layout Optimization:** FHD 1920×1080 expanded container constraints up to 1800px; 1366×768 laptop optimizations rendering live queues above the fold.
- **Architectural Touchpoints:**
  - `lib/utils/formatters.dart`: `AppFormatters` date, time, and currency utilities.
  - `lib/core/engines/appointment_engine.dart`: `calculateEstimatedWindow` logic.

---

## [1.8.0 – 1.8.3] — 07-10-2026 – 09-10-2026

### Pure Dart Domain Engines & Modular Firestore Services Layer
- **Operational Impact:** Completely decoupled business domain calculations (revenue sharing, fee resolution, drug search scoring) from Flutter UI widgets into pure Dart engines, making clinical logic instantly testable without UI dependencies.
- **Architectural Touchpoints:**
  - `lib/core/engines/`: Created `RevenueEngine`, `AppointmentEngine`, and `MedicineEngine` pure Dart modules.
  - `lib/services/`: Decomposed backend into single-responsibility services: `BookingService`, `ConsultationService`, `ChamberService`, `CatalogueService`, `DoctorService`, `PatientService`.
  - `lib/widgets/common/metric_kpi_card.dart`: Unified responsive metric KPI card supporting horizontal and vertical layouts.

---

## [1.5.0 – 1.7.0] — 07-10-2026

### 5-Step Clinical Encounter Pipeline & Medication Reconciliation State Machine
- **Operational Impact:**
  - **5-Step Encounter Pipeline:** Structured consultation workflow: (1) Patient Demographics & Allergies $\to$ (2) Vitals & Examination $\to$ (3) Past Investigations $\to$ (4) Prescribing & Medication Reconciliation $\to$ (5) Orders & Follow-Up Advice.
  - **Medication Reconciliation (`START` / `CONTINUE` / `STOP`):** Preserves chronic drug regimens across visits with 1-tap continuation and explicit stop-reason tracking.
  - **OPD Clinical Regimen Defaults:** Auto-populates standard dosages, timings (e.g. empty-stomach PPIs, bedtime statins), and course durations upon drug selection.
  - **Master Medicine Catalogue:** Owner formulary management supporting composition-first vs brand-first search scoring.
- **Architectural Touchpoints:**
  - `lib/screens/consultation_encounter_screen.dart`: 5-step clinical encounter coordinator.
  - `lib/widgets/encounter/encounter_form_state.dart`: Encapsulated clinical form state and controller lifecycles.
  - `lib/core/engines/medicine_engine.dart`: Clinical default OPD regimens and search scoring.

---

## [1.0.0 – 1.4.0] — 03-10-2026 – 07-10-2026

### Foundational Outpatient Clinic Core
- **Operational Impact:**
  - **Audit-Proof Operational Ledger (Invariant #1):** Zero deletion policy. Appointments cannot be deleted once created; cancelled or no-show patients are marked as `[ABSENT]` with ₹0 fee to maintain strict consecutive token sequences.
  - **Longitudinal Clinical History (Invariant #2):** Consultations stored as immutable, append-only records across visits rather than disposable paper notes.
  - **Real-Time Multi-Doctor Synchronization:** Firestore realtime streams synchronizing reception counter actions and physician chamber views.
  - **Monochrome Prescription Print Engine:** High-contrast A4 and A5 printable sheets supporting pre-printed letterhead mode (reserved 130px margin) and distinct warnings for discontinued drugs.
- **Architectural Touchpoints:**
  - `lib/models/`: Core domain models (`Appointment`, `Consultation`, `Patient`, `Doctor`, `Medicine`, `Vitals`).
  - `lib/services/firestore_paths.dart`: Type-safe Firestore path and atomic counter key builders.
  - `lib/widgets/print/`: Monochrome letterhead printing suite.
