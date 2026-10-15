# 🏥 GuwahatiOne Clinic OS — Master Codebase Audit & Refactor Blueprint

> **Status:** Active Working Audit & Strategic Roadmap  
> **Last Updated:** 15-10-2026  
> **Owner:** Senior Clinical Systems Architect (AI) & Strict Product Manager (Human)  
> **Reference Standards:** [`AGENTS.md`](../AGENTS.md) | [`docs/SCHEMA_AND_MODELS.md`](SCHEMA_AND_MODELS.md)

---

## 🎯 Executive Objectives & Audit Rubric

Every file in the repository is evaluated across 4 non-negotiable dimensions:

1. **Domain Invariants & Clinical Safety:**
   - Strict adherence to the 11 Invariants in `AGENTS.md` (Zero deletions, sequential daily tokens, append-only longitudinal records, single-occupant chamber integrity, Indian `DD-MM-YYYY` dates).
2. **AI Maintainability & Blast Radius:**
   - Type safety over magic strings, pure static functions in engines, predictable component boundaries, and suppression of "God Object" side effects.
3. **Micro-File Strategy (< 50 lines):**
   - **Consolidate** into domain aggregates, **Cluster** related sub-widgets, or **Preserve** only if independently reused across boundaries.
4. **Feature Completeness & Scope Opportunities:**
   - ⚠️ **Half-Baked:** Dead buttons, un-rendered schema fields, un-debounced searches, or broken real-world math.
   - 💡 **Essential Missing OPD Scope:** High-value clinical or reception workflows strictly within Clinic OS boundaries.

---

## 📊 Summary Scorecard by Architectural Layer

| Layer | Files Audited | Clean / Strong | Micro-File Candidates | Half-Baked / Gaps Found | Refactor Priority |
|---|:---:|:---:|:---:|:---:|:---:|
| **Special Focus: Prescribing IntelliSense** | 5 | - | - | 2 Remaining Gaps (Search Shipped `v1.35.0`) | 🔴 Urgent Clinical UX |
| **Special Focus: Household / Paediatric Identity** | 4 | 4 | 0 | ✅ **Shipped `v1.34.0`** (Moved to Roadmap) | 🟢 Resolved |
| **Special Focus: Prescription Snapshot & Immunity** | 3 | 3 | 0 | ✅ **Shipped `v1.34.1`** (Moved to Roadmap) | 🟢 Resolved |
| **Batch 1: Engines (`core/engines/`)** | 5 | 5 | 0 | 1 Gap | 🟡 Medium |
| **Batch 1: Data Models (`models/`)** | 12 | 8 | 3 | 2 Gaps | 🟡 Medium |
| **Batch 2: Services (`services/`)** | 9 | 6 | 2 | 2 Gaps | 🟡 Medium |
| **Batch 2: Providers (`providers/`)** | 2 | 1 | 0 | 2 Gaps | 🔴 High |
| **Batch 3: Screens (`screens/`)** | 13 | 11 | 0 | 2 Gaps | 🔴 High |
| **Batch 4: Reusable Widgets (`widgets/`)** | 44 | 39 | 1 | 3 Gaps | 🔴 High |

> **📌 IMPORTANT NOTE ON PLAN STATUS & EVALUATION TAXONOMY:**  
> This master document is an **active working blueprint**, not a finalized commitment.  
> 1. **Broken System / System Bug Fixes (Definite Actions):** Issues that represent broken mechanisms or orphaned code (e.g. cash drawer UPI revenue collision, un-rendered `Doctor.blockedDates`, missing dirty-state guarding, responsive `maxWidth` monitor bottlenecks, micro-file sprawl) are definite engineering fixes.  
> 2. **Clinical Feature Solutions (Proposals for PM Evaluation):** Feature workflows and domain expansions (such as remaining *Prescribing IntelliSense* formulary defaults or doctor leave calendars) are documented as **architectural possibilities and solution options** for the Product Manager to evaluate, modify, or approve before execution.

---

## ⚡ CLINICAL INTELLIGENCE SPOTLIGHT: OPD Prescribing Formulary & Regimen Configuration

> **Product Invariant & Context:** In an active Indian OPD shift (30–60 patients in 3–4 hours), doctors spend 30–60 seconds per prescription. Over 80% of routine prescriptions follow textbook pharmacological regimens (e.g. Telma 40 -> OD morning after breakfast for 30 days chronic; Pan 40 -> OD morning empty stomach for 14 days; Augmentin 625 -> BD after food for 5 days).  
> **Shipped in `v1.35.0`:** Unified dual-column Brand + Molecule search in `MedicineEngine.searchAndGroup`, grouped composition cards UI, 3-char trigger with 2-char pharmacology allowance (`D3`, `O2`), auto-populated defaults, and standardized duration dropdown (see [`PRODUCT_ROADMAP.md §2`](PRODUCT_ROADMAP.md)).  
> **Domain Model Simplification:** Form is integral to `productName` (e.g. `Telma 40 tablet`), and strength is integral to `composition` (e.g. `Telmisartan 40mg`). Redundant separate `strength`, `form`, and `category` fields are retired from `Medicine`, eliminating artificial data-entry barriers and double-concatenation errors.  
> **Remaining Core Gaps:** Adding a medicine via `AddMedicineDialog` completely omits default dosage, frequency, timing, and duration fields (even though the `Medicine` model has them!). Furthermore, `ClinicProvider.addMedicine()` drops default dosage parameters entirely.

### Remaining Architectural Breakdown & Action Items:
1. **Model & Dialog Simplification (Zero Strength/Form Redundancy):**
   - Streamline `Medicine` down to `productName` (with form), `composition` (with strength), and optional `manufacturer`.
   - Update `AddMedicineDialog` to drop separate Strength and Form inputs.
2. **Regimen Configuration in `AddMedicineDialog`:**
   - Add inputs for Default Dosage, Frequency (`1-0-0`, `1-0-1`, etc.), Timing (`After Food`, `Empty Stomach`), Duration, and Chronic flag in `AddMedicineDialog` (`lib/widgets/catalogue/add_medicine_dialog.dart`).
3. **Plumb Defaults Through `ClinicProvider.addMedicine`:**
   - Update `ClinicProvider.addMedicine` (`lib/providers/clinic_provider.dart`) to persist default regimen parameters to Firestore.
4. **Fast Prescribing "Verify & Next" UX:**
   - Support Enter keypress in `StagedMedicineForm` to immediately confirm the staged medicine into the prescription table and refocus the search input for the next drug.
5. **Master Formulary Expansion (~80–100 Standard OPD Medicines):**
   - Expand `defaultEssentialMedicines` in `lib/utils/default_medicines.dart` with streamlined `productName`, `composition`, and `manufacturer`.

---

## 👶 SHIPPED: Paediatric, Geriatric & Household Multi-Patient Identity Architecture

> **Status:** ✅ **COMPLETED & MOVED TO PRODUCT ROADMAP (`v1.34.0`)**  
> **Implemented in:** `v1.34.0` (Commit `bc8c2de`)  
> **Permanent Blueprint:** [`docs/PRODUCT_ROADMAP.md §2`](PRODUCT_ROADMAP.md) | **Decision Record:** [`docs/decisions/001-patient-identity-household-model.md`](decisions/001-patient-identity-household-model.md)  
> **Core Changes Shipped:**
> - Decoupled `patientId` from contact phone number; phone numbers now serve as non-unique household contact indices.
> - Isolated longitudinal clinical records strictly by `patientId` (preventing maternal/paediatric chart cross-contamination).
> - Added structured paediatric demographics (`ageMonths`, `ageDays`, `formattedAge`) eliminating `"0 Years"` artefacts.
> - Added guardian and caregiver attribution (`guardianName`, `guardianRelation`, e.g. `"c/o Sunita Sharma (Mother)"`) across appointments, letterhead prints, and WhatsApp summaries.
> - Added reception household member selector chips (`[👤 Sunita]`, `[👶 Aarav]`, `[➕ Add Member]`) in `AddAppointmentDialog`.
> - Updated `AppointmentEngine.hasDuplicateAppointment` with family exception logic.  
> **Automated Verification:** 5 dedicated unit and integration tests in `test/patient_identity_household_test.dart`.

---

## 🔬 BATCH 1: Domain Engines (`lib/core/engines/`)

### 1. `appointment_engine.dart` (528 lines)
* **Layer:** Pure Domain Engine (Static methods, zero UI dependencies).
* **Code Health & Invariant Adherence:** 🟢 **Exemplary.**
  - Single source of truth for sequential token allocation, 14-day free review consumption, reception queue partitioning, and arrival estimation.
  - Standardized on `AppFormatters.date()` and `AppFormatters.time()`.
* **Micro-File Decision:** N/A (Core domain engine).
* **Feature Completeness Check:**
  - ⚠️ **Half-Baked (Leave Guarding):** `AppointmentEngine.isDateBlocked(date)` only inspects clinic-wide holidays (`AppConstants.isDateBlocked`). It does not inspect `Doctor.blockedDates`!
  - 💡 **Scope Opportunity:** Add `AppointmentEngine.isDoctorOnLeave(doctor, targetDate)` so booking modals prevent advance bookings on a physician's individual leave days.
* **Refactor Recommendation:**
  - Add doctor-specific leave validation to duplicate and booking checks.
* **Severity:** `🟡 Medium`

---

### 2. `cash_handover_engine.dart` (185 lines)
* **Layer:** Pure Financial Handover Engine.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary (Resolved in `v1.35.1`).**
  - Pure calculation loops, denomination counters, and discrepancy math.
  - Distinctly segregates `totalPhysicalCash` (drawer currency notes) from `totalUpiRevenue` (bank account transfers).
  - Drawer discrepancy evaluation strictly compares physical denomination counts against physical cash revenue, preventing artificial cash shortages caused by digital payments.
* **Micro-File Decision:** Keep standalone (Clean, cohesive).
* **Severity:** `🟢 Resolved`

---

### 3. `revenue_engine.dart` (217 lines)
* **Layer:** Pure Financial Analytics & KPI Engine.
* **Code Health & Invariant Adherence:** 🟢 **Solid.**
  - Single-pass loops for realized revenue, doctor fee summaries, and chamber KPIs.
  - Strictly follows Invariant #1: only completed visits contribute to realized revenue; absent visits contribute ₹0.
* **Micro-File Decision:** Keep standalone.
* **Feature Completeness Check:**
  - ✅ **Complete:** Robust coverage across reception metrics, doctor analytics, and chamber statistics.
* **Severity:** `🟢 Low`

---

### 4. `whatsapp_engine.dart` (180 lines)
* **Layer:** Pure Communication Deep-Link Engine.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary (Resolved in `v1.35.2`).**
  - Generates zero-cost `wa.me` links with structured markdown prescriptions and strictly Indian numerical dates (`DD-MM-YYYY`).
  - Dynamically respects doctor's configured `freeReviewDays` policy (omitting the review note completely if `freeReviewDays == 0`).
* **Micro-File Decision:** Keep standalone.
* **Severity:** `🟢 Resolved`

---

### 5. `medicine_engine.dart` (628 lines)
* **Layer:** Pure Pharmacology Intelligence & Scoring Engine.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary (Resolved in `v1.36.0`).**
  - Outstanding dual-column search scoring algorithms (`searchAndGroup`) prioritizing chemical composition vs trade brand.
  - Streamlined data model: eliminated redundant separate `form`, `strength`, and `category` fields across `Medicine` and `PrescriptionItem`.
  - Brand and dosage form unified in `productName` (e.g. `Telma 40 tablet`, `Dolo 650 tablet`), chemical molecule and strength unified in `composition` (e.g. `Telmisartan 40mg`, `Paracetamol 650mg`), and pharma company in `manufacturer`.
  - Rapid 1-key (Enter) "Verify & Next" prescribing loop wired with autofocus on medicine search input.
* **Micro-File Decision:** Keep standalone.
* **Feature Completeness Check:**
  - ✅ **Complete:** Robust scoring, OPD defaults, and grouped composition cards.
  - 🚫 **Rejected Scope (PM Decision):** Automated allergy collision detection is explicitly rejected and out of scope. Allergies remain passive clinical display chips in the header per `PRODUCT_ROADMAP.md` (dumb free-text) to prevent false-positive clinical alerts and algorithmic friction.
* **Severity:** `🟢 Resolved`

---

## 📦 BATCH 1: Data Models (`lib/models/`)

### 1. `appointment.dart` (259 lines)
* **Layer:** Domain Aggregate Model.
* **Code Health:** 🟢 **Exemplary Domain Cohesion.**
  - Contains `AppointmentStatus`, `VisitStatus`, `PaymentType`, and `Appointment`.
  - Clean mapping between `VisitStatus` (5-state real-world physical pipeline) and `AppointmentStatus` (ledger status).
* **Micro-File Decision:** Model aggregate pattern—keep as is.
* **Severity:** `🟢 Low`

---

### 2. `chamber_session.dart` (111 lines)
* **Layer:** Chamber Real-Time Handshake Model.
* **Code Health:** 🟢 **Clean & Strongly Typed.**
  - Recently upgraded with `ChamberStatus` enum, eliminating magic strings.
* **Micro-File Decision:** Cohesive model.
* **Severity:** `🟢 Low`

---

### 3. `consultation.dart` (215 lines)
* **Layer:** Central Longitudinal Clinical Event Record.
* **Code Health:** 🟢 **Strict Invariant Adherence.**
  - Append-only structure preserving Step 1 to Step 5 encounter pipeline.
* **Micro-File Decision:** Core model.
* **Severity:** `🟢 Low`

---

### 4. `diagnostic_investigation.dart` (73 lines)
* **Layer:** Clinical Investigation Models.
* **Code Health:** 🟢 **Functional.**
  - Defines `DiagnosticInvestigationReview` (past lab reports reviewed in Step 3) and `OrderedTest` (tests ordered in Step 5).
* **Micro-File Decision:** 🟡 **Consolidation Candidate.**
  - Both classes are exclusively utilized by `Consultation`.
  - **Proposed Action:** Merge directly into `consultation.dart` to reduce file fragmentation and imports.
* **Severity:** `🟢 Low`

---

### 5. `doctor.dart` (119 lines)
* **Layer:** Practitioner Profile Model.
* **Code Health:** 🟡 **Clean Model / Orphaned Field.**
  - Strong schedule formatters, PIN security, and fee configuration.
* **Feature Completeness Check:**
  - ⚠️ **Orphaned Schema Field:** `blockedDates: List<DateTime>` is serialized to Firestore, but has no UI in `AddDoctorScreen` and no validation in `AppointmentEngine`.
* **Refactor Recommendation:**
  - Connect `blockedDates` to `AppointmentEngine` and `AddDoctorScreen`, or formally document/retire the field.
* **Severity:** `🟡 Medium`

---

### 6. `medicine.dart` (86 lines)
* **Layer:** Master Medicine Catalogue Model.
* **Code Health:** 🟢 **Solid.**
  - Full chemical composition, brand name, dosage form, and clinical defaults.
* **Severity:** `🟢 Low`

---

### 7. `patient.dart` (140 lines)
* **Layer:** Patient Master Demographic Model.
* **Code Health:** 🟢 **Exemplary (Upgraded in `v1.34.0`).**
  - Encapsulates decoupled canonical identity (`patientId`), non-unique household phone indexing, structured paediatric age (`ageMonths`, `ageDays`, `formattedAge`), and guardian attribution (`guardianName`, `guardianRelation`).
* **Severity:** `🟢 Low`

---

### 8. `patient_review_eligibility.dart` (55 lines)
* **Layer:** Value Object.
* **Code Health:** 🟡 **Micro-File.**
  - 55 lines containing eligibility properties and delegating `.calculate()` to `AppointmentEngine`.
* **Micro-File Decision:** 🔴 **Consolidate.**
  - **Proposed Action:** Move directly into `lib/core/engines/appointment_engine.dart` where the calculation and queue models (`QueuePartition`, `ReceptionQueueView`) already live. Eliminates an isolated satellite file.
* **Severity:** `🟡 Medium`

---

### 9. `prescription_item.dart` (145 lines)
* **Layer:** Medication Reconciliation Item Model.
* **Code Health:** 🟢 **Strong Invariant Adherence (Upgraded in `v1.34.1`).**
  - Implements `MedicationAction` (`START`, `CONTINUE`, `STOP`) with `stopReason` and chronic flags.
  - Implements immutable point-in-time clinical snapshot (`name`, `composition`, `strength`, `form`, `manufacturer`) shielding historical consultation records from catalogue mutations or purges.
* **Severity:** `🟢 Low`

---

### 10. `prescription_template.dart` (65 lines)
* **Layer:** Rapid OPD Prescribing Template Model.
* **Code Health:** 🟡 **Micro-File / Hardcoded Dependency.**
  - Models `PrescriptionTemplateItem`, `PrescriptionTemplate`, and `TemplateApplicationResult`.
* **Micro-File Decision:** 🟡 **Consolidate or Expand.**
  - **Proposed Action:** Move into `prescription_item.dart` alongside prescription models, or expand with `toJson`/`fromJson` if templates are made user-configurable in Firestore.
* **Severity:** `🟢 Low`

---

### 11. `user_role.dart` (26 lines)
* **Layer:** Auth Role Model.
* **Code Health:** 🔴 **Micro-File (26 lines).**
  - Defines `enum UserRole { owner, receptionist, doctor }` and `UserSession`.
* **Micro-File Decision:** 🔴 **Consolidate.**
  - **Proposed Action:** Move into `lib/providers/auth_provider.dart` or co-locate with auth infrastructure.
* **Severity:** `🟢 Low`

---

### 12. `vitals.dart` (84 lines)
* **Layer:** Clinical Vitals Model.
* **Code Health:** 🟢 **Clean.**
  - Formatted BP calculations, nullable metric indicators, and clean JSON serialization.
* **Severity:** `🟢 Low`

---

## 🎯 Batch 1 Refactoring Action Plan (Prioritized)

| Priority | Component | Issue | Action Item |
|:---:|:---|:---|:---|
| 🟢 **Resolved** | `cash_handover_engine.dart` | UPI payments counted in physical cash drawer total. | ✅ **Shipped (`v1.35.1`)**: Segregated physical cash from UPI; drawer discrepancy evaluates physical notes only. |
| 🟡 **Medium** | `medicine_engine.dart` | Fragile ~200-line sequential `if-else` matching for clinical defaults. | Refactor clinical defaults into declarative `List<_ClinicalRegimenRule>`. |
| 🚫 **Rejected** | `medicine_engine.dart` | Automated allergy collision detection. | Explicitly rejected by PM; allergies remain passive header chips per roadmap to prevent false alerts. |
| 🟢 **Resolved** | `whatsapp_engine.dart` | Hardcoded "14 days" review policy string. | ✅ **Shipped (`v1.35.2`)**: Dynamically uses doctor-configured `freeReviewDays` (omits if 0 days). |
| 🟢 **Resolved** | `appointment_engine.dart` & `doctor.dart` | Orphaned `Doctor.blockedDates` field. | ✅ **Shipped (`v1.36.1`)**: Integrated `isDoctorOnLeave` and `formatDoctorLeaveSummary` handling single day, 2 days, and extended week leaves. |
| 🟡 **Medium** | `patient_review_eligibility.dart` | 55-line micro-file satellite. | Consolidate into `appointment_engine.dart`. |
| 🟢 **Low** | `diagnostic_investigation.dart` | Micro-model satellite. | Consolidate into `consultation.dart`. |
| 🟢 **Low** | `user_role.dart` | 26-line micro-file. | Consolidate into `auth_provider.dart`. |

---

## 🛠️ BATCH 2: Services (`lib/services/`)

### 1. `booking_service.dart` (275 lines)
* **Layer:** Appointment & Queue Firestore Gateway.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary.**
  - Strictly follows Invariant #1 (zero appointment deletions).
  - Uses atomic Firestore transaction for sequential token allocation, appointment creation, and patient upsert.
  - Efficiently filters in-memory on date streams to avoid composite index bottlenecks.
  - Implements atomic batch for `closeDoctorSessionForDate` setting status to `absent` and `amountCollected: 0`.
* **Micro-File Decision:** Core service—keep standalone.
* **Severity:** `🟢 Low`

---

### 2. `catalogue_service.dart` (103 lines)
* **Layer:** Master Medicine Catalogue Service.
* **Code Health & Invariant Adherence:** 🟡 **Functional / Seeding & Scale Flaws.**
  - Manages catalogue CRUD and batch deduplication.
* **Micro-File Decision:** Keep standalone.
* **Feature Completeness Check:**
  - ⚠️ **Half-Baked Seeding Logic:** `ensureDefaultMedicinesExist()` only checks if the entire collection is empty (`snapshot.docs.isEmpty`). If the collection contains even 1 medicine, standard essential medicines are never updated or synced.
  - ⚠️ **Scale Bottleneck:** `searchMedicines(query)` fetches the entire `medicines` collection with `.get()` on every search! While `ClinicProvider` maintains a real-time stream `_medicines`, direct calls to this service would be costly in large formularies.
* **Refactor Recommendation:**
  - Add idempotent upsert capability for essential default medicines.
  - Document that search should leverage provider stream cache rather than raw collection `.get()`.
* **Severity:** `🟡 Medium`

---

### 3. `chamber_service.dart` (159 lines)
* **Layer:** Chamber Real-Time Handshake Service.
* **Code Health & Invariant Adherence:** 🟡 **Strong Invariants / Magic String Code Smell.**
  - Strictly adheres to Invariant #7 (doctor-paced handshake) and Invariant #11 (single occupant lock).
  - Emits real-time sessions for multi-doctor counter monitoring.
* **Micro-File Decision:** Keep standalone.
* **Feature Completeness Check:**
  - ⚠️ **AI Maintainability Risk (Magic Strings):** Lines 55, 112, 126, 144, 154 write raw string literals (`'calling'`, `'consultation_ended'`, `'ready_for_next'`, `'in_consultation'`, `'idle'`) to Firestore, and line 38 checks raw strings. Now that `ChamberStatus` enum is strongly typed in `chamber_session.dart`, `ChamberService` should exclusively use `status.toDbString()` or `status.name`.
* **Refactor Recommendation:**
  - Standardize all status writes and queries to use `ChamberStatus` enum.
* **Severity:** `🟡 Medium`

---

### 4. `consultation_service.dart` (88 lines)
* **Layer:** Clinical Encounter Firestore Gateway.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary.**
  - Strictly follows Invariant #2 (append-only longitudinal clinical events).
  - Uses atomic batch commit to save consultation, mark appointment completed, and stamp patient `lastVisitDate`.
  - In-memory date sorting on historical timelines avoids Firestore composite index errors.
* **Micro-File Decision:** Keep standalone.
* **Severity:** `🟢 Low`

---

### 5. `doctor_service.dart` (45 lines)
* **Layer:** Doctor Profile Firestore Gateway.
* **Code Health & Invariant Adherence:** 🟡 **Micro-File (45 lines) / Missing Leave Support.**
  - Clean stream and CRUD operations for doctors.
* **Micro-File Decision:** 🟡 **Micro-File Candidate (45 lines).**
  - Represents the entire doctor collection gateway. Can remain standalone or expand with leave management.
* **Feature Completeness Check:**
  - ⚠️ **Missing Doctor Leave Management:** Lacks methods to add/remove dates to `Doctor.blockedDates`.
* **Refactor Recommendation:**
  - Add `setDoctorLeave(doctorId, List<DateTime> blockedDates)` to support doctor leave workflows.
* **Severity:** `🟡 Medium`

---

### 6. `firestore_paths.dart` (42 lines)
* **Layer:** Path Architecture Utility.
* **Code Health & Invariant Adherence:** 🟢 **Micro-File (42 lines) / Clean & Crucial.**
  - Single source of truth for collection names, document keys, daily atomic counter keys (`counters/queue_{doctorId}_{yyyy-MM-dd}`), and chamber sync docs.
* **Micro-File Decision:** 🟢 **Preserve as standalone.**
  - Centralizing paths here prevents circular imports between services and tests.
* **Severity:** `🟢 Low`

---

### 7. `offline_queue_cache_service.dart` (82 lines)
* **Layer:** Local Offline Persistence Service.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary Resilience.**
  - Serializes daily appointment queue to `SharedPreferences` to survive broadband dropouts.
  - Fully testable with dependency-injected `SharedPreferences`.
* **Micro-File Decision:** Keep standalone.
* **Severity:** `🟢 Low`

---

### 8. `patient_service.dart` (105 lines)
* **Layer:** Patient Master Demographic Gateway.
* **Code Health & Invariant Adherence:** 🟢 **Clean & Efficient.**
  - Direct primary-key lookup by phone number, with prefix query for 3+ digits and capitalized name prefix searches.
  - Zero Firestore queries when query is empty.
* **Micro-File Decision:** Keep standalone.
* **Severity:** `🟢 Low`

---

### 9. `sound_service.dart` (97 lines)
* **Layer:** Reception Lobby Chime & Announcer.
* **Code Health & Invariant Adherence:** 🟢 **Clean.**
  - `ChangeNotifier` with persistent mute setting in `SharedPreferences`.
  - Token announcement deduplication (`_lastAnnouncedKey`) prevents repeated chimes on stream re-evaluations.
* **Micro-File Decision:** Keep standalone.
* **Severity:** `🟢 Low`

---

## 🔌 BATCH 2: Providers (`lib/providers/`)

### 1. `auth_provider.dart` (333 lines)
* **Layer:** Application Authentication & Role State.
* **Code Health & Invariant Adherence:** 🟢 **Strong Security / Minor Antipattern.**
  - Enforces 3-tier role guarding (Owner, Receptionist, Doctor).
  - SHA-256 password hashing with domain salt (`guwahatione_clinic_salt_v1:`).
  - Automatically migrates and purges legacy plaintext PINs from `SharedPreferences`.
* **Micro-File Decision:** Core provider. (Candidate to absorb 26-line `user_role.dart`).
* **Feature Completeness Check:**
  - ⚠️ **Minor Antipattern:** Lines 65-66 hold `_receptionistPin` and `_ownerMasterPin` variables with default plaintext strings. PIN validation exclusively checks cryptographic hashes; plaintext getters should be deprecated or removed to prevent accidental exposure.
* **Severity:** `🟢 Low`

---

### 2. `clinic_provider.dart` (786 lines)
* **Layer:** Central Application Live State ("God Provider").
* **Code Health & Invariant Adherence:** 🟡 **High Real-World Resilience / "God Object" Maintainability Risk.**
  - Subscribes to real-time streams for appointments, doctors, and medicines.
  - Implements offline cache fallback on connection dropouts.
  - Implements Reception KPI counts (`waitingInLobbyCount`, `expectedBookedCount`, `inConsultationCount`, etc.).
* **Feature Completeness Check:**
  - ⚠️ **Critical Gap (Prescribing IntelliSense):** Line 666 `addMedicine()` omits `defaultDosage`, `defaultFrequency`, `defaultTiming`, `defaultDurationDays`. Any default regimen parameters are discarded!
  - ⚠️ **God Object Bloat (786 lines):** Combines queue stream management, search filtering, doctor CRUD, medicine catalogue CRUD, and session closure.
* **Refactor Recommendation:**
  - Update `addMedicine()` to accept and forward default clinical regimen parameters to `Medicine`.
  - Consider extracting catalogue mutations into a dedicated sub-provider if `clinic_provider.dart` grows beyond 800 lines.
* **Severity:** `🔴 High`

---

## 🎯 Batch 2 Refactoring Action Plan (Prioritized)

| Priority | Component | Issue | Action Item |
|:---:|:---|:---|:---|
| 🟢 **Resolved** | `clinic_provider.dart` | `addMedicine()` drops default dosage/frequency/timing/duration. | ✅ **Shipped (`v1.36.0`)**: Defaults accepted and forwarded to `Medicine` model & Firestore. |
| 🟡 **Medium** | `chamber_service.dart` | Uses raw magic strings (`'calling'`, `'idle'`) instead of `ChamberStatus`. | Replace raw strings with strongly typed `ChamberStatus` enum. |
| 🟡 **Medium** | `catalogue_service.dart` | `ensureDefaultMedicinesExist()` skips sync if any single medicine exists. | Implement idempotent batch upsert for new standard formulary drugs. |
| 🟢 **Resolved** | `doctor_service.dart` | Missing doctor leave/block date management. | ✅ **Shipped (`v1.36.1`)**: Added `updateDoctorLeave(doctorId, blockedDates)` to `DoctorService` and `ClinicProvider`. |
| 🟢 **Low** | `auth_provider.dart` | Retains unused plaintext PIN getters. | Purge `_receptionistPin` / `_ownerMasterPin` plaintext properties in favor of pure hash verification. |
| 🟢 **Low** | `doctor_service.dart` | 45-line micro-file. | Keep standalone as clean service boundary, but augment with leave methods. |
| 🟢 **Low** | `firestore_paths.dart` | 42-line micro-file. | Preserve standalone to prevent circular dependency tree. |

---

## 🖥️ BATCH 3: UI Screens (`lib/screens/`)

### 1. `dashboard_screen.dart` (149 lines)
* **Layer:** Master Reception Dashboard & Operational Desk.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary.**
  - Implements Invariant #5: Responsive FHD PC monitors (`maxWidth: 1800`), side-by-side 6:4 split panels (`flex: 6` Queue, `flex: 4` Roster) when `width >= 1050`.
  - Suppresses desktop AppBar (`isDesktop ? null : AppBar(...)`), preventing double AppBar when embedded in `OwnerShell`.
  - Clean separation: delegates directly to `DashboardTodayQueueCard` and `DashboardDoctorRosterCard`.
* **Micro-File Decision:** Core screen.
* **Severity:** `🟢 Low`

---

### 2. `consultation_encounter_screen.dart` (562 lines)
* **Layer:** Central Clinical Encounter Workspace.
* **Code Health & Invariant Adherence:** 🟡 **Strict 5-Step Pipeline / Clinical State Loss Risk.**
  - Strictly follows Invariant #3: 5-step clinical encounter sequence.
  - Follows Invariant #2: Append-only consultation write and atomic completion batch.
  - Manages real-time chamber alerts (`ChamberCallingAlertBar`).
* **Feature Completeness Check:**
  - ⚠️ **Clinical State Loss Risk (Unsaved Form Displacement):** In `_switchToIncomingPatient()` (lines 103–120), when reception calls the next patient, tapping "Switch Now" immediately replaces the route (`Navigator.pushReplacement`) without checking if the current form has unsaved inputs. If a doctor has typed vitals, complaints, or diagnoses, they are abruptly discarded.
* **Refactor Recommendation:**
  - Add dirty-state guarding to prompt the physician before discarding in-progress consultation work.
* **Severity:** `🔴 High`

---

### 3. `doctor_chamber_screen.dart` (435 lines)
* **Layer:** Doctor Chamber Patient Queue & Paced Handshake Workspace.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary (Invariant #5 Resolved in `v1.35.2`).**
  - Strictly implements Invariant #7 (doctor-paced handshake: `notifyReadyForNext`), Invariant #8 (read-only archive mode on past dates), Invariant #9 (restricted door admission capped to 1–2 lobby checked-in, paid patients), and Invariant #11 (single occupant collision lock with `_isConsultationOpen`).
  - Container constraint expanded to `maxWidth: 1800` eliminating dead side margins on FHD 1080p counter displays.
* **Severity:** `🟢 Low`

---

### 4. `patient_directory_screen.dart` (367 lines)
* **Layer:** Patient Master Directory & Longitudinal History Viewer.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary (Invariant #5 Resolved in `v1.35.2`).**
  - Zero Firestore reads on initial load.
  - Efficient phone and name prefix search.
  - 1-tap "Book Walk-In" passing `initialPatient` into `AddAppointmentDialog`.
  - Container constraint expanded to `maxWidth: 1800` strictly adhering to Invariant #5.
* **Severity:** `🟢 Low`

---

### 5. `medicine_catalogue_screen.dart` (294 lines)
* **Layer:** Medicine Catalogue & Form Filter Screen.
* **Code Health & Invariant Adherence:** 🟡 **Functional (Invariant #5 Resolved in `v1.35.2`).**
  - Molecule count and form-based filtering (`Tablet`, `Capsule`, `Syrup`, etc.).
  - Embedded in `OwnerShell` with clean body layout and `maxWidth: 1800` container constraint.
* **Feature Completeness Check:**
  - ⚠️ **Missing Defaults in Add Modal:** "Add Medicine" button opens `AddMedicineDialog`, which lacks default dosage/frequency/timing/duration.
* **Refactor Recommendation:**
  - Add input fields for default clinical regimen in `AddMedicineDialog`.
* **Severity:** `🟡 Medium`

---

### 6. `appointment_list_screen.dart` (419 lines)
* **Layer:** Dedicated Queue & Reception Workflow Screen.
* **Code Health & Invariant Adherence:** 🟢 **Solid.**
  - Suppresses double AppBar on desktop (`!isDesktop || canPop`).
  - Implements multi-doctor queue partition tabs, real-time chamber status, and lobby audio chime toggle.
* **Micro-File Decision:** Core screen.
* **Severity:** `🟢 Low`

---

### 7. `doctor_list_screen.dart` (297 lines)
* **Layer:** Doctor Directory & PIN Administration Screen.
* **Code Health & Invariant Adherence:** 🟢 **Solid.**
  - Suppresses double AppBar on desktop.
  - Strictly role-guarded: Only Clinic Owner can view or edit doctor chamber PINs.
* **Micro-File Decision:** Core screen.
* **Severity:** `🟢 Low`

---

### 8. `statistics_screen.dart` (232 lines)
* **Layer:** Owner Analytics & Realized Revenue Screen.
* **Code Health & Invariant Adherence:** 🟢 **Solid.**
  - Suppresses double AppBar on desktop.
  - Integrates `RevenueEngine.calculateDoctorAnalytics` and routes to `DoctorDailyDetailsScreen`.
* **Micro-File Decision:** Core screen.
* **Severity:** `🟢 Low`

---

### 9. `doctor_daily_details_screen.dart` (210 lines)
* **Layer:** Patient-Level Fee Breakdown Screen.
* **Code Health & Invariant Adherence:** 🟢 **Solid.**
  - Clean modal route displaying attendance status and realized revenue breakdown per doctor.
* **Micro-File Decision:** Standalone sub-route.
* **Severity:** `🟢 Low`

---

### 10. `add_doctor_screen.dart` (679 lines)
* **Layer:** Doctor Credential & Schedule Configuration Screen.
* **Code Health & Invariant Adherence:** 🟡 **Functional / Orphaned Field Gap.**
  - Captures name, specialty, registration number, fee, free review window, and shift timings.
* **Feature Completeness Check:**
  - ⚠️ **Orphaned Feature Gap:** Never references or edits `Doctor.blockedDates`. Owners cannot configure planned doctor leaves or vacation days.
* **Refactor Recommendation:**
  - Add doctor leave calendar/picker to manage `blockedDates`.
* **Severity:** `🟡 Medium`

---

### 11. `login_screen.dart` (460 lines)
* **Layer:** PIN Authentication Screen.
* **Code Health & Invariant Adherence:** 🟢 **Clean.**
  - Recently refactored to eliminate `build()` mutation side-effect.
  - Unified PIN entry with auto-submit for 4-digit (Reception/Doctor) and 6-digit (Owner) PINs.
* **Micro-File Decision:** Core screen.
* **Severity:** `🟢 Low`

---

### 12. `owner_shell.dart` (369 lines)
* **Layer:** Top-Level App Shell Coordinator.
* **Code Health & Invariant Adherence:** 🟢 **Exemplary Architecture.**
  - Unified desktop AppBar (`OwnerShellAppBar`) with F2 hotkey for Walk-In booking.
  - Desktop navigation rail with responsive label expansion (`width >= 1100`).
  - Mobile bottom navigation bar.
  - 5-minute inactivity timer auto-stepping down Owner privileges to Reception Desk.
* **Micro-File Decision:** Top-level shell.
* **Severity:** `🟢 Low`

---

### 13. `prescription_print_screen.dart` (267 lines)
* **Layer:** Letterhead Print Preview & Patient Dispatch Screen.
* **Code Health & Invariant Adherence:** 🟢 **Solid.**
  - A4 and A5 paper size options.
  - Pre-printed clinic letterhead toggle.
  - WhatsApp transmission via `WhatsAppEngine.formatPrescriptionMessage`.
  - Monochrome high-contrast print stylesheet via `platform_print.dart`.
* **Micro-File Decision:** Standalone route.
* **Severity:** `🟢 Low`

---

## 🧩 BATCH 4: Reusable Widgets (`lib/widgets/`)

### Sub-package: Booking (`lib/widgets/booking/`) (7 files)
* **`add_appointment_dialog.dart` (725 lines):** Master booking modal. Formats dates in `DD-MM-YYYY`, calculates review eligibility, enforces daily token sequentiality.
  - ⚠️ **Gap:** Does not check `Doctor.blockedDates` when verifying doctor availability on the selected date.
* **`quick_check_in_dialog.dart` (380 lines):** 1-tap reception check-in modal for advance phone bookings arriving in lobby. 🟢 Clean.
* **`booking_patient_fields.dart`, `booking_payment_section.dart`, `booking_date_and_mode_section.dart`, `booking_eligibility_banner.dart`, `booking_duplicate_warning_banner.dart`:** High cohesion sub-components. 🟢 Clean.

---

### Sub-package: Catalogue (`lib/widgets/catalogue/`) (4 files)
* **`add_medicine_dialog.dart` (190 lines):**
  - 🔴 **Critical Prescribing IntelliSense Gap:** Missing default dosage, frequency, timing, and duration input fields.
* **`catalogue_header_and_stats.dart`, `catalogue_medicine_card.dart`, `catalogue_search_toolbar.dart`:** Cohesive catalogue display components. 🟢 Clean.

---

### Sub-package: Chamber (`lib/widgets/chamber/`) (7 files)
* **`chamber_archive_banner.dart` (34 lines):**
  - 🔴 **Micro-File Candidate (34 lines):** Only displays read-only banner.
  - **Proposed Action:** Co-locate directly inside `chamber_queue_header.dart` to eliminate unnecessary satellite file.
* **`chamber_control_banner.dart` (380 lines):** Master 5-state chamber control banner (`idle`, `ready_for_next`, `calling`, `in_consultation`, `consultation_ended`). 🟢 Strong.
* **`chamber_door_override_bar.dart` (180 lines):** Emergency door self-admission card (capped to top 1–2 lobby checked-in, paid patients). 🟢 Strong.
* **`chamber_app_bar.dart`, `chamber_metrics_grid.dart`, `chamber_queue_header.dart`, `chamber_token_card.dart`:** High quality, clean responsibilities. 🟢 Clean.

---

### Sub-package: Common (`lib/widgets/common/`) (7 files)
* **`appointment_status_chip.dart`, `payment_badge.dart`, `token_badge.dart`, `clinic_date_nav_bar.dart`, `metric_kpi_card.dart`, `owner_shell_app_bar.dart`, `section_card.dart`:**
  - Reusable presentation tokens and navigation bars. 🟢 Clean.

---

### Sub-package: Dashboard (`lib/widgets/dashboard/`) (6 files)
* **`daily_cash_handover_dialog.dart` (389 lines):**
  - ⚠️ **Math Bug Manifestation:** Calculates cash discrepancy against `summary.totalRealizedCash` (which includes UPI revenue), falsely alerting reception of a cash shortage. Must evaluate against physical cash only.
* **`cash_denomination_counter_section.dart` (180 lines):** Indian currency note counter. 🟢 Clean.
* **`dashboard_doctor_roster_card.dart` (380 lines):** Roster card on reception desk with single-stream chamber listener. 🟢 Clean.
* **`dashboard_queue_card.dart` (480 lines):** Master reception queue panel with tabbed filtering. 🟢 Clean.
* **`dashboard_header_bar.dart`, `dashboard_kpi_strip.dart`:** Header search and KPI tiles. 🟢 Clean.

---

### Sub-package: Encounter & Rx (`lib/widgets/encounter/`) (11 files)
* **`staged_medicine_form.dart` (291 lines):**
  - 🔴 **Prescribing IntelliSense Gap:** Lacks 1-key (Enter/Tab) confirmation shortcut to verify staged medicine and auto-refocus search bar for the next drug.
* **`rx_reconciliation_section.dart` (280 lines):**
  - 🟢 **Clean (Shipped `v1.35.0`):** Fast dual-column search and composition cards integrated cleanly. Passive allergy display maintained in patient header.
* **`encounter_form_state.dart` (390 lines):** State manager for clinical encounter. 🟢 Clean.
* **`advice_and_orders_section.dart`, `diagnostic_review_section.dart`, `patient_header_section.dart`, `vitals_and_exam_section.dart`:** Steps 1, 2, 3, 5 presentation. 🟢 Clean.
* **`reconciliation_item_row.dart`, `rx_search_results_view.dart`, `rx_template_presets_bar.dart`, `encounter_dialogs.dart`:** Cohesive Rx components. 🟢 Clean.

---

### Sub-package: Patient, Print & Queue (`lib/widgets/{patient,print,queue}/`) (11 files)
* **`patient_lookup_card.dart` & `doctor_consultation_accordion.dart`:** Clean patient demographic and clinical history cards. 🟢 Clean.
* **`print_header_and_demographics.dart`, `print_medications_table.dart`, `print_orders_and_footer.dart`, `token_receipt_dialog.dart`:** High-contrast monochrome A4/A5 and thermal receipt printing. 🟢 Clean.
* **`appointment_accordion.dart`, `accordion_dispatch_section.dart`, `completed_consultations_accordion.dart`, `accordion_status_actions.dart`, `queue_chamber_dispatch_action.dart`:** Cohesive queue management components. 🟢 Clean.

---

## 🎯 Batches 3 & 4 Refactoring Action Plan (Prioritized)

| Priority | Component | Issue | Action Item |
|:---:|:---|:---|:---|
| 🔴 **High** | `consultation_encounter_screen.dart` | `_switchToIncomingPatient()` discards unsaved form data. | Add dirty-form confirmation modal before switching patients. |
| 🟢 **Resolved** | `add_medicine_dialog.dart` | Missing default dosage/frequency/timing/duration inputs. | ✅ **Shipped (`v1.36.0`)**: Added input fields for default clinical regimen. |
| 🟢 **Resolved** | `staged_medicine_form.dart` | Missing 1-key (Enter) "Verify & Next" rapid prescribing loop. | ✅ **Shipped (`v1.36.0`)**: Enter keypress verifies staged drug and autofocuses search input. |
| 🟢 **Resolved** | `daily_cash_handover_dialog.dart` | False cash shortage alert due to UPI revenue inclusion. | ✅ **Shipped (`v1.35.1`)**: Physical note counter discrepancy now evaluates strictly against physical cash revenue; UPI and total revenue displayed in dedicated cards & table columns. |
| 🟢 **Resolved** | `patient_directory_screen.dart`, `doctor_chamber_screen.dart` & `medicine_catalogue_screen.dart` | Hardcoded maxWidth caps violate Invariant #5 on FHD monitors. | ✅ **Shipped (`v1.35.2`)**: Expanded container constraints to `maxWidth: 1800` across all three desktop screens. |
| 🟢 **Resolved** | `add_appointment_dialog.dart` | Does not check `Doctor.blockedDates` for doctor leave. | ✅ **Shipped (`v1.36.1`)**: Integrated `BookingDoctorLeaveWarningBanner` and disabled confirm button when doctor is on leave. |
| 🟢 **Resolved** | `add_doctor_screen.dart` | `Doctor.blockedDates` has no configuration UI. | ✅ **Shipped (`v1.36.1`)**: Added Planned Leave section with single day and week/date-range pickers and removable `DD-MM-YYYY` chips. |
| 🟢 **Low** | `chamber_archive_banner.dart` | 34-line micro-file satellite. | Consolidate into `chamber_queue_header.dart`. |


