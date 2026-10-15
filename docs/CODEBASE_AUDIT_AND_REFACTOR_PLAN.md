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
| **Special Focus: Prescribing IntelliSense** | 5 | - | - | 4 Core Gaps | 🔴 Urgent Clinical UX |
| **Special Focus: Household / Paediatric Identity** | 4 | - | - | 3 Critical Gaps | 🔴 Make-or-Break Integrity |
| **Batch 1: Engines (`core/engines/`)** | 5 | 3 | 0 | 3 Gaps | 🔴 High |
| **Batch 1: Data Models (`models/`)** | 12 | 8 | 3 | 2 Gaps | 🟡 Medium |
| **Batch 2: Services (`services/`)** | 9 | 6 | 2 | 2 Gaps | 🟡 Medium |
| **Batch 2: Providers (`providers/`)** | 2 | 1 | 0 | 2 Gaps | 🔴 High |
| **Batch 3: Screens (`screens/`)** | 13 | 8 | 0 | 4 Gaps | 🔴 High |
| **Batch 4: Reusable Widgets (`widgets/`)** | 44 | 38 | 1 | 4 Gaps | 🔴 High |

> **📌 IMPORTANT NOTE ON PLAN STATUS & EVALUATION TAXONOMY:**  
> This master document is an **active working blueprint**, not a finalized commitment.  
> 1. **Broken System / System Bug Fixes (Definite Actions):** Issues that represent broken mechanisms or orphaned code (e.g. cash drawer UPI revenue collision, un-rendered `Doctor.blockedDates`, missing dirty-state guarding, responsive `maxWidth` monitor bottlenecks, micro-file sprawl) are definite engineering fixes.  
> 2. **Clinical Feature Solutions (Proposals for PM Evaluation):** Feature workflows and domain expansions (such as the specific UI mechanics of *Prescribing IntelliSense* or the exact schema migration for *Household / Paediatric Multi-Patient Identity*) are documented as **architectural possibilities and solution options** for the Product Manager to evaluate, modify, or approve before execution.

---

## ⚡ CLINICAL INTELLIGENCE SPOTLIGHT: OPD Prescribing IntelliSense & Master Formulary Architecture

> **Product Invariant & Context:** In an active Indian OPD shift (30–60 patients in 3–4 hours), doctors spend 30–60 seconds per prescription. Over 80% of routine prescriptions follow textbook pharmacological regimens (e.g. Telma 40 -> OD morning after breakfast for 30 days chronic; Pan 40 -> OD morning empty stomach for 14 days; Augmentin 625 -> BD after food for 5 days).  
> **The Problem:** The app currently ships with only ~30 medicines. Adding a medicine via `AddMedicineDialog` completely omits default dosage, frequency, timing, and duration fields (even though the `Medicine` model has them!). Furthermore, `MedicineEngine` uses brittle hardcoded string matching. When a doctor searches and stages a medicine, they have to manually configure or verify multiple fields through repetitive clicks rather than an "IntelliJ IntelliSense" flow (Type -> Search -> Instant Auto-fill -> 1-Key Verify -> Next Drug).

### Architectural Breakdown of Current Deficiencies:
1. **Model Fields Abandoned in UI & Provider:**
   - `Medicine` model (`lib/models/medicine.dart`) defines `defaultDosage`, `defaultFrequency`, `defaultTiming`, `defaultDurationDays`.
   - `AddMedicineDialog` (`lib/widgets/catalogue/add_medicine_dialog.dart`) only has inputs for Brand Name, Composition, Strength, Form, and Manufacturer. It provides **zero inputs** for default regimen.
   - `ClinicProvider.addMedicine()` drops default dosage parameters entirely.
2. **Tiny Initial Seed Catalogue Without Defaults:**
   - `defaultEssentialMedicines` in `lib/utils/default_medicines.dart` contains only ~30 medicines, and **zero** of them have `defaultDosage`, `defaultFrequency`, `defaultTiming`, or `defaultDurationDays` populated!
   - Result: All default medicines fall back to string matching in `MedicineEngine`, and any non-matching drug defaults to generic "1 Tablet, 1-0-1, 5 days".
3. **Fragile Keyword Fallbacks:**
   - `MedicineEngine.getDefaultsForMedicine()` uses 200+ lines of `if-else` string matching on `composition` and `productName`. If a doctor adds a drug like `Thyronorm 50`, `Rifaximin 400`, or `Bilashine 20` that isn't hardcoded, it defaults to wrong regimens (e.g. BD after food instead of OD empty stomach).
4. **Prescribing UX Friction (Missing 1-Key Verify Loop):**
   - In `StagedMedicineForm`, after staging a medicine, the doctor must grab the mouse, review, and click "Add to Prescription".
   - There is no keyboard shortcut (e.g. Enter / Tab) to verify and immediately refocus the search bar for the next medication.

### Prescribing IntelliSense Solution Possibility (Subject to PM Evaluation):
1. **Master Formulary Expansion:** Expand default seeded catalogue to ~80-100 standard Indian OPD drugs across primary therapeutic classes (Cardio/HTN, Diabetes, GI/PPIs, Antibiotics, Antihistamines/Respiratory, Analgesics/NSAIDs, Thyroid, Statins, Neuro/Psych) with **explicit, soft-coded defaults** on each `Medicine` record.
2. **Full Regimen Configuration in `AddMedicineDialog`:** Allow clinic owners/doctors to configure default dosage, frequency, timing, duration, and chronic flag when adding any new medicine to the catalogue.
3. **Plumb Defaults Through `ClinicProvider.addMedicine`:** Ensure all default fields persist to Firestore.
4. **Fast Prescribing "Verify & Next" UX:**
   - Doctor types medicine name in encounter -> selects item.
   - Defaults are instantly pre-populated.
   - 1-click or Enter key confirms/verifies the staged medicine, adds it to the prescription table, and immediately resets & refocuses the search bar for the next medicine.
   - Overrides remain 100% accessible via quick-tap frequency/timing chips before confirming.

---

## 👶 CRITICAL CLINICAL SAFETY SPOTLIGHT: Paediatric, Geriatric & Household Multi-Patient Identity Architecture

> **Product Invariant & Context:** In Indian OPD healthcare, a single mobile phone number belongs to a **Family / Household Unit**, not a single individual. Infants, children, and dependent elderly relatives do not own personal mobile phones; their appointments and medical care are managed through a primary family contact (mother, father, son, or daughter).  
> **The Make-or-Break Problem:** The entire repository currently assumes a strict 1:1 mapping between phone numbers and individual human patients. This causes 3 dangerous clinical and operational breakdowns:

### Breakdown of Current Deficiencies:
1. **Master Directory Overwrite Collision (Data Erasure):**
   - `docs/SCHEMA_AND_MODELS.md` and `BookingService.bookAppointment()` hardcode the Firestore document ID as the raw phone number: `patients/{phoneNumber}`.
   - When a mother (*Sunita Sharma, 32 F*) books an appointment for her 6-month-old infant (*Baby Aarav Sharma*), reception enters `9876543210`. The database writes: `patients/9876543210` -> `name: "Baby Aarav", age: 0`.
   - When the mother herself visits next week for an adult consultation, reception enters `9876543210`. The database executes `set(..., SetOptions(merge: true))`, overwriting the child's demographic record with `name: "Sunita Sharma", age: 32`. **The child's identity is permanently erased from the master directory.**
   - The same erasure occurs when an elderly grandparent (*Ramesh Sharma, 72 M*) visits using the family phone.
2. **Longitudinal Clinical Chart Cross-Contamination (Medical Danger):**
   - `ConsultationService.getConsultationsForPatient()` and `ConsultationEncounterScreen` query consultations solely by contact phone: `_consultationsRef.where('patientPhone', isEqualTo: phone)`.
   - When a paediatrician opens *"Longitudinal History"* for the infant, the timeline displays a dangerously mingled record containing the mother's gynaecology/obstetric notes and the grandfather's cardiology prescriptions alongside the infant's paediatric encounters.
3. **Paediatric Age & Guardian Inadequacy:**
   - `Patient.age` is strictly typed as an integer (`int age` in whole years).
   - A 3-month-old infant or 10-day-old newborn is recorded as `age: 0`. In clinical paediatrics, drug dosages are calculated strictly by weight and age in months/days; whole-year integer representation is clinically unacceptable.
   - There are zero fields for `guardianName` or `guardianRelation` (*"c/o Sunita Sharma (Mother)"*).

### Multi-Patient Solution Possibilities (Subject to PM Evaluation):

#### Architecture Option 1: Decoupled Patient Identity with Household Contact Indexing (Recommended)
- **Unique Patient Identity:** Decouple `Patient.id` from raw `phoneNumber`. Use a deterministic composite key (e.g. `pat_${phone}_${normalizedName}`) or UUID for each distinct human patient.
- **Indexed Contact Phone:** Keep `phoneNumber` on `Patient` and `Appointment` as the primary lookup and SMS/WhatsApp notification channel.
- **Child / Dependent Demographics:**
  - Add `ageDisplay` or `ageMonths` (e.g. `"4 Months"`, `"18 Days"`, or `"72 Years"`).
  - Add optional `guardianName` and `guardianRelation` (e.g. `"Sunita Sharma (Mother)"`).
- **Longitudinal Record Segregation:** Key consultations to `patientId` (or composite `patientPhone + patientName`), ensuring each family member has an isolated, append-only clinical chart.

#### Reception UX Proposal (Family Member Picker in `AddAppointmentDialog`):
- When Reception types `9876543210`:
  - The dialog queries all patient profiles sharing this contact phone.
  - If multiple members exist, it presents quick family selector chips:  
    `[ 👤 Sunita (34 F) ]  [ 👶 Aarav (6m M) ]  [ 👴 Ramesh (72 M) ]  [ ➕ Add Child / Family Member ]`
  - Selecting an existing chip instantly auto-fills that specific person's profile, prior visit date, and review eligibility.
  - Clicking *"Add Child / Family Member"* keeps the same contact phone but opens clean fields to enter the child's name, age in months, and guardian name—without touching or overwriting existing family profiles.

#### Prescription & Letterhead Proposal:
- The printed prescription and WhatsApp message display:
  `Patient: Aarav Sharma (6 Months / Male) | c/o Sunita Sharma (Mother) | Contact: 9876543210`

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

### 2. `cash_handover_engine.dart` (144 lines)
* **Layer:** Pure Financial Handover Engine.
* **Code Health & Invariant Adherence:** 🟡 **High Logic Clarity / Real-World Financial Flaw.**
  - Pure calculation loops, denomination counters, and discrepancy math.
* **Micro-File Decision:** Keep standalone (Clean, cohesive).
* **Feature Completeness Check:**
  - ⚠️ **Real-World Math Bug (Cash vs. UPI Drawer Collision):** Lines 89–97 lump `PaymentType.paidCash` and `PaymentType.paidUpi` together into `totalCash` and `docCash`. In an Indian counter setup, UPI payments land directly in the clinic's bank account; only physical notes sit in the cash drawer. If a receptionist counts physical notes against `totalCash`, an artificial cash shortage is reported equal to all UPI transactions!
  - 💡 **Scope Opportunity:** Segregate `totalPhysicalCash` vs `totalUpiRevenue` in `CashHandoverSummary`.
* **Refactor Recommendation:**
  - Update `CashHandoverSummary` and `CashHandoverDoctorRow` to separately track physical cash and UPI. Drawer denomination balancing must strictly match physical cash.
* **Severity:** `🔴 High`

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

### 4. `whatsapp_engine.dart` (149 lines)
* **Layer:** Pure Communication Deep-Link Engine.
* **Code Health & Invariant Adherence:** 🟡 **Good Formatting / Hardcoded Policy Invariant Flaw.**
  - Generates zero-cost `wa.me` links with structured markdown prescriptions.
* **Micro-File Decision:** Keep standalone.
* **Feature Completeness Check:**
  - ⚠️ **Invariant Red Line Flaw (Hardcoded Review Policy):** Line 146 hardcodes `_(Within 14 days qualifies for Free Follow-Up Review)_` unconditionally! If a doctor has configured a 0-day, 7-day, 21-day, or 30-day review policy, the WhatsApp text directly contradicts the doctor's policy.
  - 💡 **Scope Opportunity:** Add a 1-tap WhatsApp reminder generator for Reception to send token confirmation or follow-up booking alerts.
* **Refactor Recommendation:**
  - Accept `freeReviewDays` in `formatPrescriptionMessage` (or omit follow-up review note if policy is 0 days).
* **Severity:** `🟡 Medium`

---

### 5. `medicine_engine.dart` (620 lines)
* **Layer:** Pure Pharmacology Intelligence & Scoring Engine.
* **Code Health & Invariant Adherence:** 🟡 **Powerful Heuristics / Chained String Matching Risk.**
  - Outstanding search scoring algorithms (`searchAndGroup`) prioritizing composition vs brand.
* **Micro-File Decision:** Keep standalone.
* **Feature Completeness Check:**
  - ⚠️ **High-Risk Fragility:** ~200 lines of sequential `if-else` substring comparisons (`compLower.contains('pantoprazole')`, etc.) for clinical defaults. Adding or reordering drug rules is prone to subtle regressions.
  - ⚠️ **Missing Clinical Safety Guardrail:** Zero allergy collision checks! Although patient allergies are captured in `Patient`, `MedicineEngine` does not provide an allergy cross-check method (`checkAllergyCollision(allergies, medicine)`).
  - 💡 **Scope Opportunity:** Allow doctors to persist custom OPD prescription templates in Firestore rather than strictly using the hardcoded default templates.
* **Refactor Recommendation:**
  - Add `MedicineEngine.detectAllergyCollisions(allergies, medicine)`.
  - Refactor `if-else` clinical defaults into a declarative rule list (`List<_ClinicalRegimenRule>`).
* **Severity:** `🔴 High`

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

### 7. `patient.dart` (90 lines)
* **Layer:** Patient Master Demographic Model.
* **Code Health:** 🟢 **Solid.**
  - Encapsulates phone-key identity, age, gender normalization, and allergies list.
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

### 9. `prescription_item.dart` (131 lines)
* **Layer:** Medication Reconciliation Item Model.
* **Code Health:** 🟢 **Strong Invariant Adherence.**
  - Implements `MedicationAction` (`START`, `CONTINUE`, `STOP`) with `stopReason` and chronic flags.
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
| 🔴 **High** | `cash_handover_engine.dart` | UPI payments counted in physical cash drawer total. | Segregate physical cash from UPI; drawer discrepancy must only evaluate physical notes. |
| 🔴 **High** | `medicine_engine.dart` | Zero allergy collision checking during prescribing. | Implement `detectAllergyCollisions(patientAllergies, medicine)` and flag warnings in encounter. |
| 🟡 **Medium** | `whatsapp_engine.dart` | Hardcoded "14 days" review policy string. | Use doctor-configured `freeReviewDays` in prescription message template. |
| 🟡 **Medium** | `appointment_engine.dart` & `doctor.dart` | Orphaned `Doctor.blockedDates` field. | Enforce doctor leave in `isDateBlocked` and booking duplicate checks. |
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
| 🔴 **High** | `clinic_provider.dart` | `addMedicine()` drops default dosage/frequency/timing/duration. | Accept optional default regimen parameters and pass to `Medicine`. |
| 🟡 **Medium** | `chamber_service.dart` | Uses raw magic strings (`'calling'`, `'idle'`) instead of `ChamberStatus`. | Replace raw strings with strongly typed `ChamberStatus` enum. |
| 🟡 **Medium** | `catalogue_service.dart` | `ensureDefaultMedicinesExist()` skips sync if any single medicine exists. | Implement idempotent batch upsert for new standard formulary drugs. |
| 🟡 **Medium** | `doctor_service.dart` | Missing doctor leave/block date management. | Add `updateDoctorLeave(doctorId, blockedDates)` to support leave calendar. |
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

### 3. `doctor_chamber_screen.dart` (434 lines)
* **Layer:** Doctor Chamber Patient Queue & Paced Handshake Workspace.
* **Code Health & Invariant Adherence:** 🟡 **Strong Invariants / Responsive Desktop Bottleneck.**
  - Strictly implements Invariant #7 (doctor-paced handshake: `notifyReadyForNext`), Invariant #8 (read-only archive mode on past dates), Invariant #9 (restricted door admission capped to 1–2 lobby checked-in, paid patients), and Invariant #11 (single occupant collision lock with `_isConsultationOpen`).
* **Feature Completeness Check:**
  - ⚠️ **Invariant #5 Violation (Desktop Bottleneck):** Line 355 hardcodes `BoxConstraints(maxWidth: 1100)`. On a standard FHD 1920×1080 counter monitor, this creates ~410px of dead blank margins on both sides.
* **Refactor Recommendation:**
  - Expand layout constraint up to `1800px` with a responsive two-column split on wide monitors (Queue on left, Chamber Control & Door Override on right).
* **Severity:** `🟡 Medium`

---

### 4. `patient_directory_screen.dart` (367 lines)
* **Layer:** Patient Master Directory & Longitudinal History Viewer.
* **Code Health & Invariant Adherence:** 🟡 **Clean Search / Invariant #5 Violation.**
  - Zero Firestore reads on initial load.
  - Efficient phone and name prefix search.
  - 1-tap "Book Walk-In" passing `initialPatient` into `AddAppointmentDialog`.
* **Feature Completeness Check:**
  - ⚠️ **Invariant #5 Explicit Violation (1400px Cap):** Line 95 hardcodes `BoxConstraints(maxWidth: 1400)`. The `AGENTS.md` constitution explicitly states: *"Never bottleneck dashboard containers with small arbitrary caps like maxWidth: 1400 that leave 150px+ dead margins on the sides."*
* **Refactor Recommendation:**
  - Change `maxWidth` constraint from 1400 to 1800.
* **Severity:** `🟡 Medium`

---

### 5. `medicine_catalogue_screen.dart` (294 lines)
* **Layer:** Medicine Catalogue & Form Filter Screen.
* **Code Health & Invariant Adherence:** 🟡 **Functional / Responsive Bottleneck & Missing Rx Defaults.**
  - Molecule count and form-based filtering (`Tablet`, `Capsule`, `Syrup`, etc.).
  - Embedded in `OwnerShell` with clean body layout.
* **Feature Completeness Check:**
  - ⚠️ **Responsive Bottleneck:** Line 66 caps container at `maxWidth: 1100`, wasting desktop screen width.
  - ⚠️ **Missing Defaults in Add Modal:** "Add Medicine" button opens `AddMedicineDialog`, which lacks default dosage/frequency/timing/duration.
* **Refactor Recommendation:**
  - Expand container to `1800px` using a responsive 2- or 3-column card grid on counter PC monitors.
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
  - ⚠️ **Missing Safety Guardrail:** Zero patient allergy collision checking against candidate medicine composition.
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
| 🔴 **High** | `add_medicine_dialog.dart` | Missing default dosage/frequency/timing/duration inputs. | Add input fields for default clinical regimen. |
| 🔴 **High** | `staged_medicine_form.dart` | Missing 1-key (Enter) "Verify & Next" rapid prescribing loop. | Support Enter keypress to confirm staging and auto-focus next medicine search. |
| 🔴 **High** | `daily_cash_handover_dialog.dart` | False cash shortage alert due to UPI revenue inclusion. | Compare physical denomination count strictly against cash revenue. |
| 🟡 **Medium** | `patient_directory_screen.dart` | Hardcoded `maxWidth: 1400` violates Invariant #5. | Expand container constraint to `1800px`. |
| 🟡 **Medium** | `doctor_chamber_screen.dart` & `medicine_catalogue_screen.dart` | Hardcoded `maxWidth: 1100` leaves dead margins on FHD screens. | Expand container constraint to `1800px` or responsive multi-column layout. |
| 🟡 **Medium** | `add_appointment_dialog.dart` | Does not check `Doctor.blockedDates` for doctor leave. | Enforce doctor leave in booking validation and show warning banner. |
| 🟡 **Medium** | `add_doctor_screen.dart` | `Doctor.blockedDates` has no configuration UI. | Add leave date picker for doctor profile. |
| 🟢 **Low** | `chamber_archive_banner.dart` | 34-line micro-file satellite. | Consolidate into `chamber_queue_header.dart`. |


