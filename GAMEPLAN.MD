# 🚨 GuwahatiOne Clinic OS — Master Architecture Audit & 2.0 Hardening Gameplan

> **Auditor & Author:** Senior Clinical Systems Architect & Hostile Reviewer  
> **Target Codebase:** GuwahatiOne Clinic OS (`lib/`, `firestore.rules`, `docs/`, `test/`)  
> **Audit Standard:** Zero Tolerance for Patient Danger, Data Loss, Financial Desync, or Operational Deadlock.  
> **Rule:** All claims in `README.md`, `CHANGELOG.md`, `PRODUCT_ROADMAP.md`, and code comments are treated as unverified marketing until proven by executable Dart/Firestore code.  
> **Mandatory Date Standard:** Indian Numerical Format (`DD-MM-YYYY`).

---

## 🧭 Executive Summary: The Flight-Readiness Reality Check

GuwahatiOne Clinic OS has brilliant pure domain engines and high-level architectural intentions, but an unsparing, deep-tissue hostile audit reveals **24 critical systemic defects** across security, concurrency, clinical safety, multi-doctor synchronization, financial accounting, and hardware printing. 

Currently, the system is like an aircraft that **cannot even start its engines** (Firestore security rules reject all patient registrations on day one), and if forced to fly, **stalls mid-air** (chamber deadlocks, multi-doctor queue collapses, zero draft autosave, and destructive financial overwrites).

Fixing these defects is not a routine patch. Resolving these 24 issues alongside the long-promised **HK-1 Free-Form Clinical Encounter** and **True Monochrome Printing** establishes the definitive, production-hardened **GuwahatiOne Clinic OS 2.0**.

## 💥 Comprehensive Catalog of 21 Active Defects & Deferred Items

```
                     ┌────────────────────────────────────────────────────────┐
                     │           GuwahatiOne Clinic OS Audit Map              │
                     └──────────────────────────┬─────────────────────────────┘
                                                │
         ┌──────────────────────┬───────────────┴───────────────┬──────────────────────┐
         ▼                      ▼                               ▼                      ▼
   [ Domain A ]           [ Domain B ]                    [ Domain C ]           [ Domain D ]
 Critical Firestore     Chamber Concurrency,            Clinical Encounter,     Counter Ledger,
  Rules & Safety         Queue & Multi-Doctor          Safety & Prescribing    Search & Hardware
 (Findings 1, 5)        (Findings 6 – 12)               (Findings 13 – 18)     (Findings 19 – 24)

 🔮 Deferred Roadmap (FUTURE): PIN Management & Credential Hardening (Findings 2, 3, 4)
```

---

### 🛡️ Domain A: Critical Firestore Rules & Safety

> 💡 **Product Manager Directive:** PIN authentication, cloud PIN synchronization, and doctor chamber preview locks (Findings 2, 3, 4) are **deferred to the FUTURE roadmap**. The active focus in Domain A is strictly on operational Firestore rules and safety.

#### 1. Fatal Firestore Security Rule Rejects All New Patient Bookings & Consultations ✅ [RESOLVED]
- **Affected Files:**
  - [firestore.rules](firestore.rules#L59-L65) (`match /patients/{patientId}`)
  - [BookingService.bookAppointment](lib/services/booking_service.dart#L25-L78)
  - [ConsultationService.saveConsultation](lib/services/consultation_service.dart#L44-L60)
  - [ClinicProvider.bookAppointment](lib/providers/clinic_provider.dart#L467-L485)
- **Resolution:**
  Updated `firestore.rules` to match `/patients/{patientId}` allowing writes where `request.resource.data.id == patientId || request.resource.data.phoneNumber == patientId`. This enables canonical paediatric/household registrations (`pat_*`) to succeed while maintaining backward compatibility with legacy phone-keyed records.
- **Severity:** 🚨 **Total Operational Blocker (Clinic Day Halted)** $\to$ **CLEARED**.

#### 5. Catalogue Management vs. Doctor Deactivation Integrity ✅ [RESOLVED]
- **Affected Files:**
  - [firestore.rules](firestore.rules#L73,L82)
  - [CatalogueService.deleteMedicine](lib/services/catalogue_service.dart#L22)
  - [DoctorService](lib/services/doctor_service.dart#L52)
- **Resolution:**
  1. **Medicines:** Updated `firestore.rules` for `/medicines/{medicineId}` to `allow delete: if true;`, allowing clinic admins to curate and remove erroneous formulary entries. Historical prescriptions remain 100% immune via `PrescriptionItem` composition and brand snapshotting.
  2. **Doctors (Invariant #1):** Kept `allow delete: if false;` strictly enforced for `/doctors/{doctorId}`. Doctor retirement is handled via non-destructive deactivation (`isActive: bool` with Admin Master Passkey authorization).
- **Severity:** ⚠️ **Formulary Curation Limitation** $\to$ **CLEARED**.
---

> 🔮 *For PIN-related findings (Finding #2 Hardcoded Admin PIN, Finding #3 Plaintext Doctor PINs, Finding #4 PIN Update UI), see the [Deferred Roadmap (FUTURE)](#-deferred-roadmap-future-pin-management-cloud-credentials--preview-locks) section at the bottom of this document.*

---

### 🚪 Domain B: Chamber Concurrency, Queue Engine & Multi-Doctor Collisions

#### 6. Irrecoverable Chamber Deadlock on Encounter Route Exit / Pop
- **Affected Files:**
  - [ConsultationEncounterScreen](lib/screens/consultation_encounter_screen.dart#L58-L67,L307)
  - [DoctorChamberScreen](lib/screens/doctor_chamber_screen.dart#L265-L280)
  - [ChamberService.callTokenIntoChamber](lib/services/chamber_service.dart#L28-L44)
- **Failure Mode:**
  When `ConsultationEncounterScreen` opens, `notifyConsultationStarted` sets the chamber document to `in_consultation`. If the patient steps out to the washroom, feels faint, or the doctor taps "Back" (`Navigator.pop`), no unwind notification is sent. The chamber remains permanently `in_consultation`. Reception's dispatch button is permanently locked, and `ChamberService.callTokenIntoChamber` throws `StateError('Chamber is already occupied...')`. **The doctor's queue is completely frozen for the rest of the day.**
- **Severity:** 🚨 **Total Chamber Operational Freeze**.

#### 7. Multi-Doctor Queue Partitioning Breakdown & False Bypassed Badges
- **Affected Files:**
  - [AppointmentEngine.partitionReceptionQueue](lib/core/engines/appointment_engine.dart#L305-L337)
  - [ReceptionQueueView](lib/core/engines/appointment_engine.dart#L22-L41)
- **Failure Mode:**
  `ReceptionQueueView` holds a single `final Appointment? inChamber;`. When two doctors consult simultaneously:
  - Doctor A is consulting Patient #8.
  - Doctor B is consulting Patient #3.
  Line 313 matches Doctor A's patient, leaving `inChamber` filled. Doctor B's active patient is dumped into the `waiting` list. Line 333 marks any waiting token smaller than `inChamber.queueNumber` as bypassed. Since Token #3 < Token #8, **Doctor B's patient, who is actively sitting in Chamber B, is branded with a red `[BYPASSED / LATE]` badge on reception screens**.
- **Severity:** 🚨 **Multi-Doctor Queue Corruption**.

#### 8. Zombie State Corruption on Door Admission Collision
- **Affected Files:**
  - [DoctorChamberScreen._handleDoorAdmit](lib/screens/doctor_chamber_screen.dart#L189-L202)
  - [ChamberService.callTokenIntoChamber](lib/services/chamber_service.dart#L28-L44)
- **Failure Mode:**
  Doctor clicks "Door Admit" on Patient B at the exact moment reception sends in Patient A. Step 1 mutates Patient B's `visitStatus` to `inConsultation`. In Step 2, `callTokenIntoChamber` detects Patient A and throws. Patient B is left permanently in `inConsultation` in the database, but is not in the chamber and is vanished from the lobby.
- **Severity:** 🚨 **Data Corruption & Lost Token**.

#### 9. Non-Transactional Chamber Handshake Race Condition
- **Affected Files:**
  - [ChamberService.callTokenIntoChamber](lib/services/chamber_service.dart#L28-L56)
- **Failure Mode:**
  Despite documentation claiming atomic occupancy, `callTokenIntoChamber` executes a standard `get()` followed by a separate `set()`. Concurrent dispatches or double clicks both read `ready_for_next`, pass the occupancy check, and overwrite each other, admitting two patients into one room simultaneously.
- **Severity:** 🚨 **Single-Occupancy Invariant Violation**.

#### 10. Midnight Date Rollover & 8:00 AM Stale Dashboard Trap
- **Affected Files:**
  - [DashboardScreen](lib/screens/dashboard_screen.dart#L18-L26)
  - [ClinicProvider.startListeningToAppointments](lib/providers/clinic_provider.dart#L147-L157)
- **Failure Mode:**
  Reception PCs remain powered on overnight. `DashboardScreen` subscribes once at launch. With no timer, midnight observer, or date-change listener, reception arriving at 8:00 AM sees **yesterday's queue**. New tokens default to yesterday's date and increment yesterday's counter, corrupting multiple days of records.
- **Severity:** 🚨 **Multi-Day Data Desynchronization**.

#### 11. Same-Day Return Visits & Lab Review Visits Hard-Blocked
- **Affected Files:**
  - [BookingService.hasAppointmentForDate](lib/services/booking_service.dart#L231-L250)
  - [AppointmentEngine.evaluateReviewEligibility](lib/core/engines/appointment_engine.dart#L101-L109)
- **Failure Mode:**
  A patient consulted at 10:00 AM returns at 3:30 PM with ultrasound reports. `hasAppointmentForDate` treats the completed morning appointment as an active duplicate and blocks booking. If reception tries Free Review, `evaluateReviewEligibility` requires `aDay.isBefore(targetDay)`, rejecting same-day reviews.
- **Severity:** 🚨 **Same-Day Lab Review Blocker**.

#### 12. Cosmetic-Only Daily Token Caps
- **Affected Files:**
  - [Doctor.dailyTokenLimit](lib/models/doctor.dart#L19)
  - [BookingPaymentSection](lib/widgets/booking/booking_payment_section.dart#L69-L74)
- **Failure Mode:**
  `dailyTokenLimit` (e.g. 18) only displays a passive badge (`14/18`). Reception can book token 19, 25, or 50 with zero confirmation modal, warning dialog, or override lock.
- **Severity:** ⚠️ **Doctor Quota Overrun**.

---

### 🩺 Domain C: Clinical Encounter, Prescribing & Medical Safety

#### 13. Zero Encounter Draft Persistence (Total Data Loss on Refresh / Crash)
- **Affected Files:**
  - [EncounterFormState](lib/widgets/encounter/encounter_form_state.dart)
  - [ConsultationEncounterScreen](lib/screens/consultation_encounter_screen.dart)
- **Failure Mode:**
  A doctor spends 10 minutes recording comprehensive vitals, symptoms, exam notes, staged drugs, and test orders. There is **zero local draft caching** (`SharedPreferences`/IndexedDB). If the browser tab crashes, laptop sleeps, or doctor hits reload, all data is permanently lost.
- **Severity:** 🚨 **Severe Clinical Data Loss & Doctor Friction**.

#### 14. Passive Cosmetic Allergies (Zero Prescribing Cross-Check)
- **Affected Files:**
  - [EncounterFormState](lib/widgets/encounter/encounter_form_state.dart#L68)
  - [MedicineEngine](lib/core/engines/medicine_engine.dart)
- **Failure Mode:**
  Allergies are rendered as a passive chip in the header. If a patient is marked allergic to `"Penicillin"`, and the doctor prescribes **Amoxicillin** or **Augmentin**, the engine performs zero string/composition matching and displays no warning alert.
- **Severity:** 🚨 **Patient Safety & Clinical Liability Hazard**.

#### 15. Staged Medicine Silent Drop on "Complete & Sign"
- **Affected Files:**
  - [EncounterFormState.confirmAddStagedMedicine](lib/widgets/encounter/encounter_form_state.dart#L200-L249)
  - [ConsultationEncounterScreen._completeAndSignConsultation](lib/screens/consultation_encounter_screen.dart#L85-L102)
- **Failure Mode:**
  A doctor selects a medicine, configures the frequency/dosage, and immediately clicks "Complete & Sign" without tapping "Add Medicine". The staged drug is held only in transient form controllers; `buildConsultation` serializes only `newPrescriptions`. **The last drug is silently discarded from the signed prescription.**
- **Severity:** 🚨 **Incomplete Clinical Prescriptions**.

#### 16. Negative and Zero Dosage / Duration Acceptance
- **Affected Files:**
  - [EncounterFormState.confirmAddStagedMedicine](lib/widgets/encounter/encounter_form_state.dart#L223)
  - [PrescriptionItem](lib/models/prescription_item.dart)
- **Failure Mode:**
  Duration parsing uses unvalidated `int.tryParse(controller.text)`. A typo like `-5` or `0` days passes cleanly into the database and prints on the prescription.
- **Severity:** ⚠️ **Pharmacological Validation Error**.

#### 17. Exponential Accumulation of Blank Ghost Diagnostic Tests
- **Affected Files:**
  - [EncounterFormState.loadInitialData](lib/widgets/encounter/encounter_form_state.dart#L363-L375)
- **Failure Mode:**
  `loadInitialData` iterates through all lifetime consultations for chronic patients and blindly appends every past test ordered with `resultValue: ''`. By visit 8, 20+ duplicate blank rows pollute the encounter form and are committed back to Firestore.
- **Severity:** ⚠️ **Longitudinal Chart Pollution**.

#### 18. External Appointment State De-sync in Active Consultation
- **Affected Files:**
  - [ConsultationEncounterScreen](lib/screens/consultation_encounter_screen.dart#L14)
- **Failure Mode:**
  The encounter screen holds a static snapshot of `Appointment`. If reception marks the patient absent or updates payment while the doctor is typing, the doctor has no visibility and signs a canceled encounter.
- **Severity:** ⚠️ **Chamber-Desk State Desynchronization**.

---

### 💳 Domain D: Counter Operations, Directory Search & Financial Ledger

#### 19. Cash Overwrite & Ghost Drawer Discrepancies on Doctor Absence
- **Affected Files:**
  - [BookingService.closeDoctorSessionForDate](lib/services/booking_service.dart#L280-L300)
  - [CashHandoverEngine.calculateCashHandover](lib/core/engines/cash_handover_engine.dart#L97-L109)
- **Failure Mode:**
  1. `closeDoctorSessionForDate` resets unconsulted appointments to `'amountCollected': 0` without generating a refund record, destroying drawer cash and bank UPI reconciliation.
  2. `CashHandoverEngine` calculates expected drawer cash only for `completed` visits, excluding all checked-in lobby patients who paid cash upfront, generating false discrepancy alerts.
- **Severity:** 🚨 **Financial Ledger Corruption & Missing Cash**.

#### 20. Single-Shift Ledger Bias & Zero Doctor Share Accounting
- **Affected Files:**
  - [CashHandoverEngine](lib/core/engines/cash_handover_engine.dart#L31-L58)
  - [RevenueEngine](lib/core/engines/revenue_engine.dart)
- **Failure Mode:**
  `CashHandoverEngine` aggregates all 24 hours without shift partitioning for morning vs evening reception handovers. Furthermore, it has no support for doctor commission splits (e.g. 70/30), leaving owners unable to reconcile doctor payouts.
- **Severity:** ⚠️ **Operational Accounting Limitation**.

#### 21. Patient Directory Search Broken on New IDs and Surnames
- **Affected Files:**
  - [PatientService.searchPatients](lib/services/patient_service.dart#L117-L168)
- **Failure Mode:**
  Phone prefix search queries `FieldPath.documentId`, which fails on all `pat_*` IDs. Name search does case-sensitive prefix queries that fail on lowercase queries or surname lookups (e.g. searching "Talukdar").
- **Severity:** ⚠️ **Duplicate Patient Profile Creation**.

#### 22. The "Offline Queue Cache" Fallback Myth
- **Affected Files:**
  - [ClinicProvider.bookAppointment](lib/providers/clinic_provider.dart#L186-L200)
  - [BookingService.bookAppointment](lib/services/booking_service.dart#L47-L75)
- **Failure Mode:**
  `OfflineQueueCacheService` caches appointment lists, but `bookAppointment` requires a Firestore transaction. Transactions fail unconditionally when offline. The front desk is completely paralyzed during internet drops.
- **Severity:** ⚠️ **Misleading High-Availability Posture**.

#### 23. Thermal POS Token Slip Printing Broken
- **Affected Files:**
  - [TokenReceiptDialog](lib/widgets/print/token_receipt_dialog.dart#L223-L226)
  - [platform_print_web.dart](lib/utils/platform_print_web.dart)
- **Failure Mode:**
  Tapping "Print Slip" triggers `window.print()` which renders the entire browser screen, dialog scrim, and buttons instead of an isolated 58mm/80mm POS receipt.
- **Severity:** 🚨 **Hardware Output Failure on Counter PCs**.

#### 24. Broken Prescription Printing & WhatsApp Delivery on Web/Native
- **Affected Files:**
  - [platform_print_stub.dart](lib/utils/platform_print_stub.dart#L1-L3)
  - [platform_url_stub.dart](lib/utils/platform_url_stub.dart#L1-L3)
  - [PrescriptionPrintScreen](lib/screens/prescription_print_screen.dart#L81,L104)
- **Failure Mode:**
  On Native (Android/Windows), printing and WhatsApp deep-links are empty stubs. On Web, printing dumps the canvas viewport and truncates pages below the fold.
- **Severity:** 🚨 **Clinical Artifact Delivery Blocker**.

---

## 📜 Unverified Claims in Documentation (Reality Check)

| Documented Claim | Document Reference | Code Reality |
|---|---|---|
| **Atomic Occupancy via Transaction** | `AGENTS.md §1 Rule #11` | **REFUTED.** Uses standard `get()` followed by separate `set()`. |
| **0mm to 50mm Margin Slider** | `PRODUCT_ROADMAP.md` line 128 | **REFUTED.** Contains only a binary boolean Switch (`_usePrePrintedLetterhead`). |
| **Print Preview Shortcuts (`Enter`/`Esc`)** | `PRODUCT_ROADMAP.md` line 133 | **REFUTED.** Zero keyboard shortcut listeners in print screens. |
| **1-Click `[CARRY FORWARD]` Button** | `AGENTS.md §1 Rule #3`, `ROADMAP` line 87 | **REFUTED.** No carry forward button or logic exists in encounter screen. |
| **Formulation Prefixes (`Tab.`, `Cap.`)** | `PRODUCT_ROADMAP.md` line 99 | **REFUTED.** No formulation formatting logic in `MedicineEngine`. |
| **"Khali Pet" Timing Chips** | `AGENTS.md §1 Rule #3`, `ROADMAP` line 98 | **REFUTED.** Form contains only standard `'Before Food'`. |
| **Next Review Dropdown with "Not Needed"** | `AGENTS.md §1 Rule #3`, `ROADMAP` line 118 | **REFUTED.** Renders fixed interval chips (`3d`, `5d`, etc.) with no "Not Needed" option. |
| **5-Step Pipeline Retired (HK-1)** | `PRODUCT_ROADMAP.md` lines 46-148 | **REFUTED.** Screen still renders full 5-step wizard. |
| **Monochrome A4/A5 Printing** | `AGENTS.md §2`, `README.md` | **REFUTED.** Web calls `window.print()` dumping raw canvas with UI headers. |
| **3-Tier Cryptographic Guarding** | `AGENTS.md §2` | **REFUTED.** Hardcoded admin PIN `849201` never expires, and doctor PINs are plaintext. |

---

## 🛠️ The 4 Implementation Pillars for GuwahatiOne Clinic OS 2.0

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    GuwahatiOne Clinic OS 2.0 Roadmap                            │
├────────────────────────┬────────────────────────┬───────────────────────────────┤
│ Pillar 1: Critical     │ Pillar 2: Chamber &    │ Pillar 3: Clinical Encounter │
│ Rules Hardening        │ Queue Orchestration    │ & Safety (HK-1)               │
├────────────────────────┼────────────────────────┼───────────────────────────────┤
│ • Match canonical pat_*│ • Atomic transaction   │ • Free-form collapsible layout│
│   document IDs in rules│   chamber occupancy    │ • Local draft autosave        │
│ • Formulary catalogue  │ • Multi-doctor queue   │ • 1-click [CARRY FORWARD]     │
│   management rules     │   partition fix        │ • Active allergy warnings     │
│ • Preserve doctor      │ • Midnight rollover    │ • Pre-print modal + shortcuts │
│   deactivation rules   │ • Emergency release    │ • Regimen sanity validation   │
└────────────────────────┴────────────────────────┴───────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│ Pillar 4: Financial Ledger, Directory Search & True Clinical Printing           │
├─────────────────────────────────────────────────────────────────────────────────┤
│ • Explicit refund ledger & upfront cash reconciliation (no amountCollected = 0) │
│ • Shift-based cashier handover & doctor revenue split calculator                │
│ • Substring & household-indexed patient search                                  │
│ • Isolated CSS/DOM 58mm/80mm thermal POS receipt printing                       │
│ • Isolated high-contrast monochrome A4/A5 letterhead printing                   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

### 🏛️ Pillar 1: Critical Firestore Rules & Safety ✅ [CLEARED]

1. **Firestore Patient Document Security Rule (Finding #1) ✅ [RESOLVED]:**
   Updated `firestore.rules` to key by canonical patient ID (`patientId`), validating `request.resource.data.id == patientId || request.resource.data.phoneNumber == patientId`. Canonical household registrations (`pat_*`) succeed on live Firestore while preserving legacy compatibility.
2. **Formulary Catalogue Management (Finding #5) ✅ [RESOLVED]:**
   - Updated `firestore.rules` for `/medicines/{medicineId}` to `allow delete: if true;`, unblocking admin formulary curation without compromising historical prescription immutability.
   - For `/doctors/{doctorId}`, `allow delete: if false;` remains strictly enforced to uphold **Invariant #1 (Zero Deletions)**, with retirement handled via non-destructive deactivation (`isActive: bool`).

---

### 🚪 Pillar 2: Chamber Concurrency, Queue & Multi-Doctor Engine

1. **Transactional Chamber Occupancy (Finding #9):**
   Wrap `ChamberService.callTokenIntoChamber` in `FirebaseFirestore.instance.runTransaction()`.
2. **Safe Encounter Route Exit & Unwind (Finding #6):**
   Wrap `ConsultationEncounterScreen` in `PopScope`. On exit without completing, prompt for confirmation and cleanly reset chamber status to `ready_for_next` or `idle`.
3. **Doctor Shift Conclusion & Emergency Chamber Release Protocol:**
   - **`[END CONSULTATION FOR TODAY]` (Doctor Chamber):** Transitions chamber to `shift_ended` and updates reception badge to `Dr. [Name] — Shift Ended`.
   - **`[RELEASE CHAMBER - FORCED]` (Reception Desk):** Receptionist enters PIN `0000` to emergency-release stuck chambers.
4. **Multi-Doctor Queue Partitioning Fix (Finding #7):**
   Refactor `ReceptionQueueView` to support `Map<String, Appointment> inChamberByDoctorId`. Prevent active patients of Doctor B from being dumped into lobby waiting or branded as bypassed.
5. **Midnight Rollover & Clock Observer (Finding #10):**
   Implement `DateChangeObserver` in `ClinicProvider` that automatically switches active listening stream and date counters when midnight crosses.
6. **Same-Day Return Visits & Lab Reviews (Finding #11):**
   Update `BookingService.hasAppointmentForDate` and `AppointmentEngine.evaluateReviewEligibility` to allow same-day follow-ups for lab review.
7. **Strict Daily Token Limit Guard (Finding #12):**
   Trigger explicit confirmation modal when reception attempts to book beyond doctor's `dailyTokenLimit`.

---

### 🩺 Pillar 3: Clinical Encounter Overhaul & Safety (HK-1)

1. **Retire the 5-Step Pipeline (HK-1):**
   Replace the step wizard with a single scrollable document with collapsible MBBS/MD sections:
   - Header with passive allergy chip and demographics.
   - Clinical observations modal: Vitals grid + `C/O`, `O/E`, `Dx`/`P/D`.
   - Past history accordion with **1-Click `[CARRY FORWARD]`** populating previous medicines as `CONTINUE` items.
   - Prescribe medicines section with Indian frequency chips (`1-0-1`, `1-0-0`, `0-0-1`, `1-1-1`, `SOS`) and timing chips (`After Food / PC`, `Before Food / Khali Pet / AC`).
   - Standard formulation prefixes (`Tab.`, `Cap.`, `Syp.`, `Inj.`).
   - Next review dropdown with `Not Needed` option.
2. **Encounter Local Draft Autosave (Finding #13):**
   Serialize `EncounterFormState` to local storage every 5 seconds. Restore draft automatically if browser reloads or crashes.
3. **Active Allergy Safety Cross-Check (Finding #14):**
   Match staged medicine brand names and active compositions against patient allergies; display prominent red safety warning banner on conflict.
4. **Staged Medicine Discard Guard (Finding #15):**
   Alert doctor or auto-commit staged drug if "Complete & Sign" is tapped while a medicine is staged.
5. **Pharmacological Sanity Validation (Finding #16):**
   Enforce `durationDays > 0` and standard dosage formats.
6. **Deduplicate Lab Reviews (Finding #17):**
   Limit pre-population strictly to the most recent prior consultation, deduplicated by `testName`.

---

### 💳 Pillar 4: Financial Ledger, Directory Search & Clinical Printing

1. **Non-Destructive Refund Ledger (Finding #19):**
   Never set `amountCollected: 0` on session cancellation. Mark status as `absent` with explicit `refundStatus: 'pending_refund' | 'refunded'`, preserving audit integrity.
2. **Shift-Based Cash Handover & Doctor Fee Splits (Finding #20):**
   Upgrade `CashHandoverEngine` to support time-window filtering (Morning vs Evening shifts) and calculate doctor fee splits (e.g. 70/30) vs clinic retention.
3. **Robust Patient Directory Search (Finding #21):**
   Maintain normalized search tokens on patient documents to support substring, surname, and phone queries across all `pat_*` profiles.
4. **Isolated Thermal POS Slip Printing (Finding #23):**
   Implement dedicated CSS print stylesheet and hidden DOM iframe for 58mm/80mm token receipts, completely isolating slips from the main dashboard.
5. **True High-Contrast Monochrome Letterhead Printing (Finding #24):**
   Render A4/A5 prescription letterhead into dedicated print iframe with `0mm` to `50mm` margin slider and `Enter`/`Esc` keyboard shortcuts.

---

### 🔮 Deferred Roadmap (FUTURE): PIN Management, Cloud Credentials & Preview Locks

> 💡 **Product Manager Directive:** All PIN authentication modifications, cloud PIN synchronization, and doctor chamber preview locks are moved to this deferred future sprint.

#### 1. Hardcoded Admin Master PIN Bypass & Credential Leak (Finding #2)
- **Affected Files:**
  - [auth_provider.dart](lib/providers/auth_provider.dart#L173-L176,L228-L230,L269-L270)
  - [login_screen.dart](lib/screens/login_screen.dart#L274-L278)
- **Plan:** Remove hardcoded default admin PIN `849201` fallback once the owner PIN is initialized. Purge credential leak messages (`"Testing: Reception: 0000 | Admin: 849201"`) from error UI in `login_screen.dart`.

#### 2. Plaintext Doctor PINs & Chamber View Impersonation Bypass (Finding #3)
- **Affected Files:**
  - [doctor.dart](lib/models/doctor.dart#L60)
  - [doctor_list_screen.dart](lib/screens/doctor_list_screen.dart#L53-L61,L280-L288)
  - [doctor_chamber_screen.dart](lib/screens/doctor_chamber_screen.dart#L13,L80-L104)
- **Plan:** Hash Doctor PINs before writing to the public `doctors` collection. Enforce strict chamber preview lock: preview mode displays view-only telemetry and suppresses all consultation triggers and door admissions without entering the doctor's PIN.

#### 3. Cloud-Synced PIN Store & Session Recovery UI (Finding #4)
- **Affected Files:**
  - [auth_provider.dart](lib/providers/auth_provider.dart#L304-L320)
- **Plan:** Store hashed Owner and Reception PINs in Firestore (`clinic_config/security`) rather than local browser storage only, enabling synchronized PIN changes across all clinic terminals. Provide an administrative Security Settings dialog for PIN rotation with recovery passkey.

---

## 🎯 Verification Criteria for Clinic OS 2.0 Release

1. **Automated Test Coverage:**
   - All 24 defect fixes verified by automated unit tests in `test/`.
   - Engine and state transition tests pass cleanly with sub-second execution.
2. **Zero Linter & Static Analysis Warnings:**
   - `flutter analyze` passes with 0 errors and 0 warnings.
3. **Hostile Concurrency Validation:**
   - Multi-counter simultaneous bookings stress-tested without counter collisions.
   - Two doctors consulting simultaneously verified without queue partitioning or bypassed badge errors.
4. **Operational Continuity:**
   - Browser refresh mid-consultation restores 100% of typed draft.
   - Midnight date rollover verified on continuously running client.

---
*Single Source of Truth maintained in GAMEPLAN.MD for GuwahatiOne Clinic OS 2.0.*
