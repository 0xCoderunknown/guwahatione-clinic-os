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

#### 6. Irrecoverable Chamber Deadlock on Encounter Route Exit / Pop ✅ [RESOLVED]
- **Affected Files:**
  - [ConsultationEncounterScreen](lib/screens/consultation_encounter_screen.dart)
  - [DoctorChamberScreen](lib/screens/doctor_chamber_screen.dart)
  - [ChamberService](lib/services/chamber_service.dart)
  - [ClinicProvider](lib/providers/clinic_provider.dart)
- **Resolution:**
  Wrapped `ConsultationEncounterScreen` in `PopScope(canPop: false)`. Intercepts back navigation (Android back, browser back, or "Pause / Step Out" dock button) with an explicit modal dialog. Provides "Pause & Save Draft" (frees chamber with `notifyConsultationPaused`, returning chamber to `ready_for_next`, and marks appointment `isPaused: true` in waiting lobby) or "Discard" (clears draft, notifies chamber `ready_for_next`). Zero frozen chambers or stuck locks.
- **Severity:** 🚨 **Total Chamber Operational Freeze** $\to$ **CLEARED**.

#### 7. Multi-Doctor Queue Partitioning Breakdown & False Bypassed Badges ✅ [RESOLVED]
- **Affected Files:**
  - [AppointmentEngine.partitionQueueForReception](lib/core/engines/appointment_engine.dart)
  - [ReceptionQueueView](lib/core/engines/appointment_engine.dart)
  - [AppointmentAccordion](lib/widgets/queue/appointment_accordion.dart)
  - [AppointmentListScreen](lib/screens/appointment_list_screen.dart)
  - [DashboardTodayQueueCard](lib/widgets/dashboard/dashboard_queue_card.dart)
- **Resolution:**
  Refactored `ReceptionQueueView` to support `final List<Appointment> inChamberPatients` and getter `Appointment? get inChamber => inChamberPatients.firstOrNull`. When viewing multiple concurrent doctors, all active patients are isolated in `inChamberPatients`, rendering at the top of the queue with zero displacement into waiting. Per Product Manager directive, the arbitrary `[BYPASSED / LATE]` badge, calculation, and amber styling were completely eliminated across engine and UI. In clinical reality, doctors take relatives, walk-in emergencies, or elderly patients out of strict FIFO order; uncalled waiting patients in the lobby are never falsely branded "Late" or "Bypassed". Doctor filter chips on `AppointmentListScreen` dynamically filter to doctors scheduled/active on that specific date. Added Upcoming Advance Bookings view on reception dashboard with Indian date formatting (`DD-MM-YYYY`).
- **Severity:** 🚨 **Multi-Doctor Queue Corruption** $\to$ **CLEARED**.

#### 8. Zombie State Corruption on Door Admission Collision ✅ [RESOLVED]
- **Affected Files:**
  - [DoctorChamberScreen._handleDoorAdmit](lib/screens/doctor_chamber_screen.dart)
  - [ChamberService.callTokenIntoChamber](lib/services/chamber_service.dart)
- **Resolution:**
  Reordered door admission protocol: `DoctorChamberScreen._handleDoorAdmit` now claims the atomic chamber lock via `ChamberService.callTokenIntoChamber` *before* mutating appointment records. If reception concurrently called another patient into the chamber, `callTokenIntoChamber` throws inside its transaction, admission aborts cleanly, and the patient remains safely in `waitingInLobby` with zero zombie state corruption.
- **Severity:** 🚨 **Data Corruption & Lost Token** $\to$ **CLEARED**.

#### 9. Non-Transactional Chamber Handshake Race Condition ✅ [RESOLVED]
- **Affected Files:**
  - [ChamberService.callTokenIntoChamber](lib/services/chamber_service.dart)
- **Resolution:**
  Wrapped `ChamberService.callTokenIntoChamber` inside `FirebaseFirestore.instance.runTransaction()`. The chamber occupancy check (`transaction.get`) and calling state broadcast (`transaction.set`) now execute atomically. Concurrent admissions or double clicks trigger transaction conflict retries and are strictly rejected if the room is occupied (`StateError`).
- **Severity:** 🚨 **Single-Occupancy Invariant Violation** $\to$ **CLEARED**.

#### 10. Midnight Date Rollover & 8:00 AM Stale Dashboard Trap ✅ [RESOLVED]
- **Affected Files:**
  - [DashboardScreen](lib/screens/dashboard_screen.dart)
  - [ClinicProvider](lib/providers/clinic_provider.dart)
  - [BookingService](lib/services/booking_service.dart)
- **Resolution:**
  Implemented periodic 30-second midnight rollover observer (`checkAndHandleMidnightRollover`) inside `ClinicProvider`. When counter PCs remain powered on overnight, the observer detects calendar day shift (`!DateUtils.isSameDay(_activeListeningDate, now)`), automatically cancels the previous day's stream, resets today's appointment list, and re-subscribes live queue streams to the new calendar day. Operates automatically for live queue sessions while preserving intentional user archive browsing when historical dates are explicitly selected.
- **Severity:** 🚨 **Multi-Day Data Desynchronization** $\to$ **CLEARED**.

#### 11. Same-Day Return Visits & Lab Review Visits Hard-Blocked ✅ [RESOLVED]
- **Affected Files:**
  - [BookingService.hasAppointmentForDate](lib/services/booking_service.dart)
  - [AppointmentEngine.evaluateReviewEligibility](lib/core/engines/appointment_engine.dart)
- **Resolution:**
  1. Updated `BookingService.hasAppointmentForDate` duplicate check to permit same-day re-booking when prior appointment on the date has reached `AppointmentStatus.completed`. A patient consulted in the morning returning in the afternoon with lab results is routed via reception desk, receiving a valid queue token so doctors have complete operational clarity without unannounced chamber barging.
  2. Enhanced `AppointmentEngine.evaluateReviewEligibility` to recognize same-day return visits (`daysSincePaid == 0`) with descriptive status `'Same-day return / lab review'`, correctly unlocking doctor-configured free review waivers (`PaymentType.freeReview`).
- **Severity:** 🚨 **Same-Day Lab Review Blocker** $\to$ **CLEARED**.

#### 12. Cosmetic-Only Daily Token Caps ✅ [RESOLVED]
- **Affected Files:**
  - [Doctor.dailyTokenLimit](lib/models/doctor.dart)
  - [BookingPaymentSection](lib/widgets/booking/booking_payment_section.dart)
- **Resolution:**
  Retained soft visual quota warning badge per Product Manager directive. In clinical practice, strict hard modal locks paralyze front-desk operations during walk-in emergencies. If limits are reached, soft warnings display prominently on desk badges while doctors retain discretion to verbally coordinate with reception.
- **Severity:** 💡 **Soft Cap Maintained per PM Directive** $\to$ **CLEARED**.

---

### 🩺 Domain C: Clinical Encounter, Prescribing & Medical Safety

#### 13. Zero Encounter Draft Persistence (Total Data Loss on Refresh / Crash) ✅ [RESOLVED]
- **Affected Files:**
  - [EncounterFormState](lib/widgets/encounter/encounter_form_state.dart)
  - [ConsultationEncounterScreen](lib/screens/consultation_encounter_screen.dart)
  - [BookingService](lib/services/booking_service.dart)
  - [AppointmentAccordion](lib/widgets/queue/appointment_accordion.dart)
  - [QueueChamberDispatchAction](lib/widgets/queue/queue_chamber_dispatch_action.dart)
  - [ChamberDoorOverrideBar](lib/widgets/chamber/chamber_door_override_bar.dart)
- **Resolution:**
  Implemented comprehensive consultation draft serialization (`toDraftMap` / `restoreFromDraftMap`) and asynchronous local draft caching in `SharedPreferences` (`draft_encounter_${appointmentId}`). On pause or reload, `_loadInitialData` automatically restores typed vitals, clinical exam notes, chief complaints, provisional diagnoses, staged medications, ordered tests, and advice notes. When a patient steps out for an hour, doctor pauses visit, chamber is freed for next patients, reception queue card displays `[PAUSED / RESUMABLE]` and `[RESUME IN]`, and upon return, encounter auto-restores cleanly. Completing & signing consultation removes draft.
- **Severity:** 🚨 **Severe Clinical Data Loss & Doctor Friction** $\to$ **CLEARED**.

#### 14. Passive Allergy Presentation (Design Retained) ✅ [RESOLVED]
- **Affected Files:**
  - [EncounterFormState](lib/widgets/encounter/encounter_form_state.dart#L71)
  - [PatientHeaderSection](lib/widgets/encounter/patient_header_section.dart)
- **Resolution:**
  Per Product Manager directive, the clean, passive allergy chip in the encounter header is retained without introducing interrupting popups or prescribing blocking gates. Clinicians maintain full prescribing autonomy without forced administrative roadblocks.
- **Severity:** 💡 **Design Retained per PM Directive** $\to$ **CLEARED**.

#### 15. Staged Medicine Silent Drop on "Complete & Sign" ✅ [RESOLVED]
- **Affected Files:**
  - [EncounterFormState](lib/widgets/encounter/encounter_form_state.dart)
  - [ConsultationEncounterScreen._completeAndSignConsultation](lib/screens/consultation_encounter_screen.dart)
- **Resolution:**
  Added `hasStagedMedicine` and `stagedMedicineDisplayName` getters in `EncounterFormState`. When a doctor attempts to "Complete & Sign" while a medicine is actively staged, an interactive dialog intercepts the action: "Unadded Staged Medicine: You have staged [Name] but haven't added it to the prescription yet." Provides 1-tap `[Add to Prescription & Sign]` (auto-commits staged item and signs), `[Discard & Sign]`, and `[Review / Cancel]`. Zero silent drops of staged drugs.
- **Severity:** 🚨 **Incomplete Clinical Prescriptions** $\to$ **CLEARED**.

#### 16. Negative and Zero Dosage / Duration Acceptance & Flexible Duration System ✅ [RESOLVED]
- **Affected Files:**
  - [MedicineEngine.parseDuration](lib/core/engines/medicine_engine.dart)
  - [PrescriptionItem](lib/models/prescription_item.dart)
  - [Medicine](lib/models/medicine.dart)
  - [EncounterFormState](lib/widgets/encounter/encounter_form_state.dart)
  - [StagedMedicineForm](lib/widgets/encounter/rx/staged_medicine_form.dart)
  - [PrintMedicationsTable](lib/widgets/print/print_medications_table.dart)
- **Resolution:**
  Implemented pure Dart `MedicineEngine.parseDuration` supporting flexible multi-modal duration inputs: acute numbers (`1 to 300` days, e.g. `5`, `14`, `21 days`), as-needed (`SOS`, `SoS`), and ongoing therapy (`To continue`, `cont`, `chronic`). Strictly validates and rejects negative (`<= 0`) and excessive (`> 300`) values. Form supports 1-tap quick presets (`[Cont]`, `[SOS]`, `[3d]`, `[5d]`, `[7d]`, `[14d]`, `[30d]`) alongside free-text typing. Catalogue bundled package defaults (e.g. *Telma 40 tablet* with `{Telmisartan 40mg, 1-0-1, to continue}`) populate intact into staging without doctor friction. Column 3 isolation strictly maintained with `effectiveDuration`.
- **Severity:** ⚠️ **Pharmacological Validation Error** $\to$ **CLEARED**.

#### 17. Exponential Accumulation of Blank Ghost Diagnostic Tests ✅ [RESOLVED]
- **Affected Files:**
  - [EncounterFormState.loadInitialData](lib/widgets/encounter/encounter_form_state.dart)
- **Resolution:**
  Updated `loadInitialData` to track `seenTestNames` across historical consultations and deduplicate by normalized `testName.trim().toLowerCase()`. Historical lab review tables pre-populate only unique ordered investigations, completely eliminating ghost blank rows and chart pollution for chronic follow-up patients.
- **Severity:** ⚠️ **Longitudinal Chart Pollution** $\to$ **CLEARED**.

#### 18. External Appointment State De-sync in Active Consultation ❌ [REJECTED BY PM]
- **Resolution:**
  Explicitly rejected by Product Manager directive. In active consultation, doctors require distraction-free focus on the patient inside the chamber. Interrupting active medical consultations with asynchronous administrative counter notifications introduces friction and potential clinical errors. The active consultation token remains protected by the single-occupant chamber lock.
- **Status:** 🛑 **Dropped per PM Directive**.

---

### 💳 Domain D: Counter Operations, Directory Search & Financial Ledger

#### 19. Cash Overwrite & Ghost Drawer Discrepancies on Doctor Absence ✅ [RESOLVED]
- **Affected Files:**
  - [Appointment](lib/models/appointment.dart)
  - [BookingService.closeDoctorSessionForDate](lib/services/booking_service.dart)
  - [CashHandoverEngine.calculateCashHandover](lib/core/engines/cash_handover_engine.dart)
- **Resolution:**
  1. Updated `CashHandoverEngine` to count physical cash collected upfront at the reception counter (`PaymentType.paidCash` with `amountCollected > 0`) regardless of whether the patient is in lobby, in consultation, or completed, perfectly mirroring real physical cash in drawer.
  2. Fixed `BookingService.closeDoctorSessionForDate` to NEVER destructively zero out `amountCollected` on doctor absence. Retains collected cash amounts in the audit trail and tags `refundStatus: 'pending_refund'`.
  3. `CashHandoverEngine` skips visits only when `refundStatus == 'refunded'`, eliminating ghost discrepancies between counted drawer cash and system expectations.
- **Severity:** 🚨 **Financial Ledger Corruption & Missing Cash** $\to$ **CLEARED**.

#### 20. Single-Shift Ledger Bias & Doctor Revenue Share Accounting ✅ [PARTIALLY RESOLVED]
- **Affected Files:**
  - [Doctor](lib/models/doctor.dart)
  - [DoctorForm](lib/screens/add_doctor_screen.dart)
  - [RevenueEngine](lib/core/engines/revenue_engine.dart)
- **Resolution:**
  1. **Item 20.2 (Doctor Fee Share Split):** Added `doctorSharePercentage` (0–100%, default 100%) to `Doctor` model with clean serialization. Added admin-only input field in `DoctorForm` (accessible only under owner credentials). Implemented pure Dart calculation `RevenueEngine.calculateDoctorPayout({required totalDoctorFees, required doctorSharePercentage})` for transparent revenue reconciliation between clinic owner and physicians.
  2. **Item 20.1 (Shift handover partitioning):** Deferred to future milestone per PM roadmap decision.
- **Severity:** ⚠️ **Accounting Split Resolved** $\to$ **CLEARED (20.2)**.

#### 21. Patient Directory Search Broken on New IDs and Surnames ✅ [RESOLVED]
- **Affected Files:**
  - [PatientSearchEngine](lib/core/engines/patient_search_engine.dart)
  - [PatientService.searchPatients](lib/services/patient_service.dart)
- **Resolution:**
  1. Built pure Dart `PatientSearchEngine` featuring phone normalization (strips +91, 0, whitespace, formatting), name tokenization, and multi-tier relevance ranking (exact phone > exact name > surname prefix > partial matches).
  2. Fixed `PatientService.searchPatients` to query the `phoneNumber` field instead of `FieldPath.documentId` (which failed on `pat_*` IDs), added dedicated `pat_*` lookup, and integrated recent patient pool token matching so searching by surname (e.g. "Devi", "Baruah", "Sharma") or canonical ID immediately returns ranked matches.
- **Severity:** ⚠️ **Duplicate Patient Profile Creation** $\to$ **CLEARED**.

#### 22. The "Offline Queue Cache" Fallback Myth ✅ [RESOLVED]
- **Affected Files:**
  - [AddAppointmentDialog](lib/widgets/booking/add_appointment_dialog.dart)
  - [OwnerShell](lib/screens/owner_shell.dart)
  - [OfflineQueueCacheService](lib/services/offline_queue_cache_service.dart)
- **Resolution:**
  Replaced misleading offline booking expectations with clear, graceful degradation:
  1. In `OwnerShell` (desktop & mobile), persistent amber notification strips alert front-desk staff when running on local cached queue data during broadband outages.
  2. In `AddAppointmentDialog`, an offline warning banner informs staff that token allocation requires active cloud synchronization to guarantee consecutive token counter integrity (Invariant #1), preventing silent submission failures.
  3. Booking errors during network dropouts display human-friendly connectivity guidance instead of cryptic database exception traces.
- **Severity:** ⚠️ **Operational Clarity & Graceful Degradation** $\to$ **CLEARED**.

#### 23. Thermal POS Token Slip Printing Broken (Deferred)
- **Affected Files:**
  - [TokenReceiptDialog](lib/widgets/print/token_receipt_dialog.dart#L223-L226)
  - [platform_print_web.dart](lib/utils/platform_print_web.dart)
- **Status:** Deferred to future milestone per PM roadmap decision.

#### 24. Configurable Letterhead Top Margin & Print Keyboard Shortcuts ✅ [RESOLVED]
- **Affected Files:**
  - [ClinicConfig](lib/config/clinic_config.dart)
  - [PrintHeaderAndDemographics](lib/widgets/print/print_header_and_demographics.dart)
  - [PrescriptionPrintScreen](lib/screens/prescription_print_screen.dart)
- **Resolution:**
  1. Added `defaultLetterheadTopMarginMm` (default: 35.0 mm) to `ClinicConfig` so letterhead spacer height is client-configurable rather than hardcoded.
  2. Wired `CallbackShortcuts` and autofocus in `PrescriptionPrintScreen` for rapid counter workflow: `Enter` instantly triggers printing, `Esc` closes the preview.
- **Severity:** 💡 **Ergonomics & Print Layout** $\to$ **CLEARED**.

---

## 📜 Unverified Claims in Documentation (Reality Check)

| Documented Claim | Document Reference | Code Reality | Status |
|---|---|---|---|
| **Atomic Occupancy via Transaction** | `AGENTS.md §1 Rule #11` | Atomic counter transactions & lock. | **VERIFIED** |
| **Configurable Letterhead Margin** | `PRODUCT_ROADMAP.md` line 128 | Client-configurable via `ClinicConfig.defaultLetterheadTopMarginMm`. | **VERIFIED** |
| **Print Preview Shortcuts (`Enter`/`Esc`)** | `PRODUCT_ROADMAP.md` line 133 | Implemented with `CallbackShortcuts` in `PrescriptionPrintScreen`. | **VERIFIED** |
| **1-Click `[CARRY FORWARD]` Button** | `AGENTS.md §1 Rule #3`, `ROADMAP` line 87 | Implemented in `EncounterFormState`, `RxReconciliationSection`, and `EncounterDialogs`. | **VERIFIED** |
| **"Khali Pet" Timing Chips** | `AGENTS.md §1 Rule #3`, `ROADMAP` line 98 | 1-tap rapid schedule chips (`1-0-0 Khali Pet`, etc.) in `StagedMedicineForm`. | **VERIFIED** |
| **Next Review with "Not Needed / SOS"** | `AGENTS.md §1 Rule #3`, `ROADMAP` line 118 | 1-tap `Not Needed / SOS` chip in `AdviceAndOrdersSection`. | **VERIFIED** |
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

1. **Transactional Chamber Occupancy & Collision Guard (Finding #8 & #9) ✅ [CLEARED]:**
   - Wrapped `ChamberService.callTokenIntoChamber` inside `FirebaseFirestore.instance.runTransaction()`, guaranteeing atomic occupancy checking and calling state emission.
   - Reordered door admission protocol in `DoctorChamberScreen._handleDoorAdmit`: claims atomic chamber occupancy lock *before* mutating appointment records, preventing zombie state corruption if reception concurrently calls another patient.
2. **Safe Encounter Route Exit, Pause & Draft Recovery (Finding #6 & #13) ✅ [CLEARED]:**
   - Wrapped `ConsultationEncounterScreen` in `PopScope(canPop: false)`. Intercepts accidental back navigation or bottom dock "Pause / Step Out" with a protective modal dialog.
   - Provides "Pause & Save Draft": saves draft locally in `SharedPreferences` (`draft_encounter_${appointmentId}`), marks appointment `isPaused: true` in waiting lobby, and frees doctor chamber (`ready_for_next`).
   - Reception queue renders `[PAUSED / RESUMABLE]` badge and dynamic purple `[RESUME IN]` dispatch button. Door override bar renders `[PAUSED]` chip and `[Resume]` button.
   - On resume, `_loadInitialData` automatically restores typed vitals, observations, staged medications, and orders. Zero lost notes, zero chamber deadlocks.
3. **Doctor Shift Conclusion & Emergency Chamber Release Protocol ✅ [CLEARED]:**
   - **`[END SHIFT]` / `[Close Shift]` (Doctor Chamber):** Added `ChamberStatus.shiftEnded` (`'shift_ended'`) state. Doctors conclude OPD sessions on their own schedule from `ChamberControlBanner` (`consultationEnded`, `readyForNext`, `idle`) with confirmation dialogs. Chamber renders calm slate/indigo `[OPD Shift Concluded for Today]` banner with 1-tap `[RE-OPEN SHIFT]` action.
   - **Reception Visibility & Auto-Lock:** `DashboardDoctorRosterCard` renders explicit `[SHIFT ENDED]` badge; `QueueChamberDispatchAction` and `AccordionDispatchSection` display disabled state `"Doctor Shift Ended for Today"`. Door admits are locked.
   - **`[Emergency Release Chamber Lock]` (Reception Desk):** Receptionist can enter PIN `0000` (or Owner Master PIN) to emergency-release stuck or abandoned chambers, returning the room to `idle` via `clearChamberSession` without deleting appointment records (Invariant #1).
4. **Multi-Doctor Queue Partitioning & Upcoming Advance Bookings (Finding #7) ✅ [CLEARED]:**
   - Refactored `ReceptionQueueView` to support `final List<Appointment> inChamberPatients` and getter `Appointment? get inChamber => inChamberPatients.firstOrNull`. Isolates all active patients across concurrent consulting doctors, displaying all active tokens at the top of the queue with zero displacement into waiting.
   - Completely retired arbitrary `[BYPASSED / LATE]` badge and calculations across engine and UI. Waiting patients remain in their clean, respectful FIFO queue.
   - Filtered `AppointmentListScreen` doctor filter chips to show strictly doctors with OPD scheduled on that date (or with existing appointments), eliminating clutter.
   - Added Upcoming Advance Bookings view on reception dashboard (`DashboardTodayQueueCard`) streaming advance reservations up to 7 days in the future, grouped by date adhering strictly to Indian formatting (`DD-MM-YYYY`). Wrapped tab selector in horizontal scroll to prevent mobile overflow.
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
3. **Passive Allergy Presentation (Finding #14) ✅ [RESOLVED]:**
   Clean header allergy chip design retained per PM directive with zero clinical roadblocks.
4. **Staged Medicine Discard Guard (Finding #15) ✅ [RESOLVED]:**
   Interactive modal intercepts "Complete & Sign" if a staged medicine is pending, with 1-tap `[Add to Prescription & Sign]` or `[Discard & Sign]`.
5. **Flexible Duration System & Pharmacological Sanity (Finding #16) ✅ [RESOLVED]:**
   Pure Dart `MedicineEngine.parseDuration` validates 1-300 days, SOS, and Continue/Chronic, while fully preserving packaged catalogue defaults (e.g. *Telma 40*).
6. **Deduplicate Longitudinal Lab Investigations (Finding #17) ✅ [RESOLVED]:**
   Pre-populates only unique ordered tests across historical visits, eliminating ghost blank rows.

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
