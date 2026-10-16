# 🚨 HOSTILE CLINICAL SYSTEMS CODE AUDIT & BUG REPORT

**Auditor:** Senior Clinical Systems Architect & Hostile Reviewer  
**Target Codebase:** GuwahatiOne Clinic OS (`lib/`, `firestore.rules`, `docs/`)  
**Audit Standard:** Zero Tolerance for Patient Danger, Data Loss, Financial Desync, or Operational Deadlock.  
**Rule:** All claims in `README.md`, `CHANGELOG.md`, `PRODUCT_ROADMAP.md`, and code comments were treated as unverified marketing until proven by executable Dart/Firestore code.

---

## 💥 CRITICAL DEFECT FINDINGS

### 1. Fatal Firestore Security Rule Rejects All New Patient Bookings & Consultations
- **File and Function:**  
  - [firestore.rules](file:///k:/Android/guwahatione-clinic-os/firestore.rules#L59-L65) (`match /patients/{patientPhone}`)
  - [BookingService.bookAppointment](file:///k:/Android/guwahatione-clinic-os/lib/services/booking_service.dart#L25-L78)
  - [ConsultationService.saveConsultation](file:///k:/Android/guwahatione-clinic-os/lib/services/consultation_service.dart#L44-L60)
  - [ClinicProvider.bookAppointment](file:///k:/Android/guwahatione-clinic-os/lib/providers/clinic_provider.dart#L467-L485)
- **Exact Scenario:**  
  A receptionist books any new walk-in patient or family dependent. `ClinicProvider.bookAppointment` generates a unique canonical `patientId` (e.g. `'pat_1729000000_1234'`) and invokes `_bookingService.bookAppointment(patient: Patient(id: 'pat_...'))`. In `BookingService`, line 74 sets `_patientsRef.doc('pat_1729000000_1234')` with `patient.toJson()`, containing `phoneNumber: '9876543210'`.
- **What Goes Wrong:**  
  `firestore.rules` defines:
  ```firestore
  match /patients/{patientPhone} {
    allow create, update: if request.resource.data.phoneNumber == patientPhone;
  }
  ```
  In Firestore rules, `{patientPhone}` captures the document ID (`'pat_1729000000_1234'`). The security rule evaluates `'9876543210' == 'pat_1729000000_1234'`, which is `false`. Firestore throws `permission-denied`. Because this write is executed inside the atomic booking transaction, **the entire transaction rolls back**. Reception cannot book any new patient. Furthermore, when a doctor clicks "Complete & Sign", `ConsultationService.saveConsultation` attempts to update `/patients/{consultation.patientId}` with the latest visit date; this batch write is also rejected with `permission-denied`, preventing the doctor from saving or completing any consultation.
- **Severity:** **Blocks a clinic day** (Total operational shutdown).

---

### 2. Irrecoverable Chamber Deadlock on Encounter Exit / Cancel
- **File and Function:**  
  - [ConsultationEncounterScreen](file:///k:/Android/guwahatione-clinic-os/lib/screens/consultation_encounter_screen.dart#L58-L67) (`_loadInitialData`), line 307 (`onCancel`)
  - [DoctorChamberScreen](file:///k:/Android/guwahatione-clinic-os/lib/screens/doctor_chamber_screen.dart#L265-L280) (`_openConsultation`)
  - [ChamberService.callTokenIntoChamber](file:///k:/Android/guwahatione-clinic-os/lib/services/chamber_service.dart#L28-L44)
- **Exact Scenario:**  
  A patient is called into the doctor's chamber. When `ConsultationEncounterScreen` opens, `_loadInitialData()` executes `clinic.notifyConsultationStarted(...)`, setting Firestore `counters/chamber_{doctorId}_{date}` to `status: 'in_consultation'` with `activeAppointmentId: appt.id`. The patient suddenly feels nauseous, needs to use the washroom, or the doctor accidentally taps the screen and clicks "Back / Cancel" (`Navigator.pop(context)`).
- **What Goes Wrong:**  
  Neither `ConsultationEncounterScreen` nor `DoctorChamberScreen` sends any notification or reset to `ChamberService` on route pop. The Firestore chamber document remains permanently in `status: 'in_consultation'`. Reception's dispatch button is permanently disabled (`"Chamber Occupied (Token #N Inside)"`). If reception attempts to dispatch any subsequent patient, `ChamberService.callTokenIntoChamber` throws `StateError('Chamber is already occupied...')`. The doctor cannot click "Next Patient" because the banner evaluates `_chamberStatus == inConsultation`. **The doctor's queue is permanently frozen for the rest of the day.**
- **Severity:** **Blocks a clinic day**.

---

### 3. Same-Day Return Visits & Lab Review Visits Are Hard-Blocked
- **File and Function:**  
  - [BookingService.hasAppointmentForDate](file:///k:/Android/guwahatione-clinic-os/lib/services/booking_service.dart#L231-L250)
  - [ClinicProvider.bookAppointment](file:///k:/Android/guwahatione-clinic-os/lib/providers/clinic_provider.dart#L434-L445)
  - [AppointmentEngine.evaluateReviewEligibility](file:///k:/Android/guwahatione-clinic-os/lib/core/engines/appointment_engine.dart#L101-L109)
- **Exact Scenario:**  
  A patient is consulted at 10:00 AM (`AppointmentStatus.completed`). The doctor orders an emergency ultrasound or fasting blood sugar. The patient returns at 3:30 PM with the report. Reception attempts to issue a token for the evening session so the doctor can review the report.
- **What Goes Wrong:**  
  1. `BookingService.hasAppointmentForDate` checks `appt.status != AppointmentStatus.absent`. Because the morning appointment is `completed` (not absent), it returns `true`. `ClinicProvider.bookAppointment` immediately throws:
     `Exception: Patient "<name>" already has an active appointment with <Doctor> on this date.`
     Reception is hard-blocked from issuing any token.
  2. If reception attempts to mark them as a `freeReview` (since they paid that morning), `AppointmentEngine.evaluateReviewEligibility` filters for prior visits using `aDay.isBefore(targetDay)`. Since both visits are today, `isBefore` returns `false`. The engine declares `hasVisitedDoctorEarlier: false`, and `ClinicProvider.bookAppointment` throws:
     `Exception: Free Review is only allowed for patients who previously visited <Doctor>.`
     The patient is physically blocked from getting their diagnostic reports evaluated by their consulting doctor.
- **Severity:** **Blocks a clinic day / Wrong clinical output**.

---

### 4. Cash Overwrite & Ghost Cash Drawer Discrepancies on Doctor Absence
- **File and Function:**  
  - [BookingService.closeDoctorSessionForDate](file:///k:/Android/guwahatione-clinic-os/lib/services/booking_service.dart#L280-L300)
  - [CashHandoverEngine.calculateCashHandover](file:///k:/Android/guwahatione-clinic-os/lib/core/engines/cash_handover_engine.dart#L97-L109)
- **Exact Scenario:**  
  8 patients arrive at 9:00 AM, each paying ₹500 in physical cash at the front desk (₹4,000 cash in drawer). At 10:30 AM, the doctor calls in sick with an emergency. Reception triggers "Close Doctor Session".
- **What Goes Wrong:**  
  1. In `closeDoctorSessionForDate`, line 294 updates all un-consulted appointments to `'amountCollected': 0` without generating any refund log, ledger payout entry, or tracking whether cash was returned. Physical cash of ₹4,000 in the desk drawer now has ₹0 matching in the database. If patients paid via UPI directly to the clinic's bank account, setting `amountCollected: 0` silently destroys the bank reconciliation ledger.
  2. In `CashHandoverEngine.calculateCashHandover`, expected cash (`totalPhysicalCash`) is calculated strictly for `a.status == AppointmentStatus.completed`. For all lobby patients who paid cash before their consultation, their money is **excluded** from expected cash drawer calculations. At shift handover, physical cash counted is ₹4,000, while the engine reports expected cash as ₹0, generating false discrepancy alerts and rendering financial reconciliation invalid.
- **Severity:** **Clinic's money / Data loss**.

---

### 5. Zombie State Corruption on Door Admission Collision
- **File and Function:**  
  - [DoctorChamberScreen._handleDoorAdmit](file:///k:/Android/guwahatione-clinic-os/lib/screens/doctor_chamber_screen.dart#L189-L202)
  - [ChamberService.callTokenIntoChamber](file:///k:/Android/guwahatione-clinic-os/lib/services/chamber_service.dart#L28-L44)
- **Exact Scenario:**  
  Doctor clicks "Door Admit" on Patient B at the exact moment reception dispatches Patient A into the chamber.
- **What Goes Wrong:**  
  `_handleDoorAdmit` performs step 1: `await _bookingService.admitPatientToChamber(appt.id)`, which mutates Patient B's `visitStatus` to `inConsultation` in Firestore. In step 2, `_chamberService.callTokenIntoChamber` detects Patient A in the chamber and throws `StateError`. The method aborts in the catch block. Patient B is now left permanently in `visitStatus: inConsultation`, but is NOT in the chamber. Reception can never dispatch Patient B because they are no longer in `waitingInLobby`. Patient B's appointment is permanently corrupted.
- **Severity:** **Blocks a clinic day / Data loss**.

---

### 6. Non-Transactional Chamber Handshake Race Condition
- **File and Function:**  
  - [ChamberService.callTokenIntoChamber](file:///k:/Android/guwahatione-clinic-os/lib/services/chamber_service.dart#L28-L56)
- **Exact Scenario:**  
  Two reception counter browsers, or a receptionist double-clicking "Send In to Doctor" when the doctor signals `ready_for_next`.
- **What Goes Wrong:**  
  Despite `AGENTS.md` mandating an atomic occupancy check inside a Firestore transaction, `callTokenIntoChamber` executes a standard read (`await docRef.get()`) followed by a separate write (`await docRef.set()`). Concurrent dispatches both read `status: 'ready_for_next'`, both pass the occupancy check, and the second write overwrites the first. Two patients are admitted into the chamber simultaneously, violating single-occupancy guarantees.
- **Severity:** **Wrong clinical output / Patient collision**.

---

### 7. Exponential Accumulation of Blank Ghost Diagnostic Tests in Chronic Patient Records
- **File and Function:**  
  - [EncounterFormState.loadInitialData](file:///k:/Android/guwahatione-clinic-os/lib/widgets/encounter/encounter_form_state.dart#L363-L375)
- **Exact Scenario:**  
  A hypertensive or diabetic patient attends for their 8th routine visit. Over prior visits, the doctor ordered standard blood panels (CBC, HbA1c, Lipid Profile).
- **What Goes Wrong:**  
  `loadInitialData` loops through all historical consultations:
  ```dart
  for (final past in pastConsultations) {
    for (final ordered in past.orderedTests) {
      reviewedInvestigations.add(DiagnosticInvestigationReview(...));
    }
  }
  ```
  It blindly appends all lab tests ever ordered across all past visits with an empty `resultValue: ''` and no deduplication. If 3 tests were ordered across 7 prior visits, 21 duplicate blank entries are pre-populated into `reviewedInvestigations`. When the doctor finishes the consultation, all 21 blank entries are committed to Firestore. On visit 9, the number balloons further. The patient's longitudinal chart is polluted with dozens of phantom, unreviewed test rows.
- **Severity:** **Data loss / Wrong clinical output**.

---

### 8. Hardcoded Admin Master PIN Bypass & Plaintext PIN Exposure
- **File and Function:**  
  - [AuthProvider.authenticateWithPin](file:///k:/Android/guwahatione-clinic-os/lib/providers/auth_provider.dart#L173-L176, L228-L230, L269-L270)
  - [LoginScreen._handleOwnerLogin](file:///k:/Android/guwahatione-clinic-os/lib/screens/login_screen.dart#L274-L278)
  - [Doctor.toJson](file:///k:/Android/guwahatione-clinic-os/lib/models/doctor.dart#L60)
- **Exact Scenario:**  
  The clinic owner changes their Master PIN to a private 6-digit number to protect revenue records and doctor fee management.
- **What Goes Wrong:**  
  1. In `AuthProvider`, `(inputHash == _ownerMasterPinHash || inputHash == _defaultOwnerMasterPinHash)` is hardcoded across all authentication methods. The default factory PIN `849201` **never expires**. Anyone who types `849201` is instantly authenticated as Master Owner.
  2. In `login_screen.dart` line 276, when an incorrect PIN is entered, the error message literally prints to the screen:  
     `"Incorrect PIN (Testing: Reception: 0000 | Admin: 849201)."`  
     The application leaks the master admin credential directly on the client display.
  3. Custom owner PINs are stored only in local browser `SharedPreferences`; changing the PIN on one terminal never syncs to other clinic counter PCs.
  4. In `Doctor.toJson()`, `pin: pin` persists every physician's chamber login PIN in plaintext in the publicly readable `doctors` collection.
- **Severity:** **Clinic's money / Full privilege escalation**.

---

### 9. Broken Printing & WhatsApp Delivery on Native Platforms (Web Print Renders Broken UI)
- **File and Function:**  
  - [platform_print_stub.dart](file:///k:/Android/guwahatione-clinic-os/lib/utils/platform_print_stub.dart#L1-L3)
  - [platform_url_stub.dart](file:///k:/Android/guwahatione-clinic-os/lib/utils/platform_url_stub.dart#L1-L3)
  - [platform_print_web.dart](file:///k:/Android/guwahatione-clinic-os/lib/utils/platform_print_web.dart#L6-L8)
  - [PrescriptionPrintScreen](file:///k:/Android/guwahatione-clinic-os/lib/screens/prescription_print_screen.dart#L81, L104)
- **Exact Scenario:**  
  A doctor runs the clinic app on an Android tablet, Windows desktop app, or web browser.
- **What Goes Wrong:**  
  1. On Android and Desktop, `platform_print_stub.dart` and `platform_url_stub.dart` are empty no-op functions (`// No-op`). Tapping "Print Prescription" or "Send on WhatsApp" fails silently with zero response or error handling.
  2. On Web, `platform_print_web.dart` calls browser `window.print()`. Because Flutter Web renders to an HTML `<canvas>`, the browser prints an unscaled viewport snapshot including the Scaffold AppBar, action buttons, switches, and margins, while truncating whatever portion of the prescription is scrolled below the screen fold. There is no `@media print` CSS stylesheet or DOM extraction container.
- **Severity:** **Blocks a clinic day / Wrong clinical output**.

---

### 10. Catalogue Deletion and Deduplication Hard-Blocked by Firestore Rules
- **File and Function:**  
  - [firestore.rules](file:///k:/Android/guwahatione-clinic-os/firestore.rules#L73, L82)
  - [CatalogueService.deleteMedicine](file:///k:/Android/guwahatione-clinic-os/lib/services/catalogue_service.dart#L22)
  - [CatalogueService.deduplicateMedicines](file:///k:/Android/guwahatione-clinic-os/lib/services/catalogue_service.dart#L77)
  - [DoctorService.deleteDoctor](file:///k:/Android/guwahatione-clinic-os/lib/services/doctor_service.dart#L52)
- **Exact Scenario:**  
  An administrator attempts to delete an erroneous drug, run formulary deduplication, or remove a retired doctor.
- **What Goes Wrong:**  
  In `firestore.rules`, both `/medicines/{medicineId}` and `/doctors/{doctorId}` have `allow delete: if false;`. Whenever `deleteMedicine()`, `deduplicateMedicines()`, or `deleteDoctor()` is called, Firestore throws `permission-denied`.
- **Severity:** **Annoying / Functionality permanently broken**.

---

### 11. "Chamber View" in Doctor List Bypasses All PIN Authentication
- **File and Function:**  
  - [DoctorListScreen](file:///k:/Android/guwahatione-clinic-os/lib/screens/doctor_list_screen.dart#L53-L61, L280-L288)
  - [DoctorChamberScreen](file:///k:/Android/guwahatione-clinic-os/lib/screens/doctor_chamber_screen.dart#L13, L80-L104)
- **Exact Scenario:**  
  A receptionist (authenticated with `0000`) navigates to Doctor List and clicks "Chamber View" on any doctor.
- **What Goes Wrong:**  
  The button pushes `DoctorChamberScreen(doctor: doctor, isPreviewMode: true)`. `isPreviewMode` only changes a label badge in `ChamberAppBar`. In `_DoctorChamberScreenState`, all operational listeners and triggers remain 100% active. The receptionist's device subscribes to live chamber sync, auto-opens consultations when tokens are dispatched, allows direct door admissions, and permits the receptionist to prescribe medicines, discontinue drugs, and sign medical prescriptions as the doctor without entering any doctor PIN.
- **Severity:** **Wrong clinical output / Unauthorized clinical action**.

---

### 12. Total Absence of UI to Change Receptionist or Owner PINs & Zero-Recovery Lockout Trap
- **File and Function:**  
  - [AuthProvider.setOwnerMasterPin](file:///k:/Android/guwahatione-clinic-os/lib/providers/auth_provider.dart#L304-L311)
  - [AuthProvider.setReceptionistPin](file:///k:/Android/guwahatione-clinic-os/lib/providers/auth_provider.dart#L313-L320)
  - [AddDoctorScreen](file:///k:/Android/guwahatione-clinic-os/lib/screens/add_doctor_screen.dart#L51, L196)
- **Exact Scenario:**  
  Admin logs in and wants to update clinic operational security by changing the default Receptionist PIN (`0000`) or changing the Master Owner PIN.
- **What Goes Wrong:**  
  1. **Zero UI for Reception & Owner PIN Changes:** While doctor PINs can be edited inside `AddDoctorScreen`, there is **literally no UI screen, dialog, form, or settings modal anywhere in the app** to invoke `setReceptionistPin()` or `setOwnerMasterPin()`. Both methods exist in `AuthProvider` as orphaned code that is never connected to any user interaction. The receptionist PIN is permanently locked to `0000`.
  2. **Local-Only Storage Flaw:** Even if code calls `setOwnerMasterPin()`, it writes the hash strictly to local browser `SharedPreferences`. It is **never persisted to Firestore**. The changed PIN does not exist on counter computers, and clearing browser cookies immediately erases it.
  3. **Zero-Recovery "Game Over" Lockout:** If the default hardcoded PIN fallback (`849201`) is removed and an admin forgets their custom PIN, there is **zero account recovery or reset path** (no admin email link, no SMS OTP, no recovery key). The entire clinic administrative layer is permanently locked out.
- **Severity:** **Blocks a clinic day / Security trap**.

---

## 📜 UNVERIFIED CLAIMS IN DOCUMENTATION

The following claims in `README.md`, `CHANGELOG.md`, `PRODUCT_ROADMAP.md`, and `AGENTS.md` could **NOT** be verified in the source code:

| Documented Claim | Source Document Reference | Code Reality |
|---|---|---|
| **Atomic Occupancy via Firestore Transaction** | `AGENTS.md §1 Rule #11`, `§3 Step 4` | **REFUTED.** `ChamberService.callTokenIntoChamber` executes a separate `get()` followed by a `set()`. Zero transaction wrappers used. |
| **0mm to 50mm Letterhead Margin Slider** | `PRODUCT_ROADMAP.md` line 128 | **REFUTED.** `PrescriptionPrintScreen` contains only a binary boolean Switch (`_usePrePrintedLetterhead`). No slider exists. |
| **Print Preview Keyboard Shortcuts (`Enter` / `Esc`)** | `PRODUCT_ROADMAP.md` line 133 | **REFUTED.** No keyboard listener or shortcut handlers exist in `PrescriptionPrintScreen`. |
| **Single `[CARRY FORWARD]` Button** | `AGENTS.md §1 Rule #3`, `PRODUCT_ROADMAP.md` line 87 | **REFUTED.** No carry forward button, state, or method exists in `ConsultationEncounterScreen` or any widget. |
| **Formulation Prefixes (`Tab.`, `Cap.`, `Syp.`, `Inj.`)** | `PRODUCT_ROADMAP.md` line 99 | **REFUTED.** No formulation prefix formatting logic exists in `MedicineEngine`, `PrescriptionItem`, or print widgets. |
| **"Khali Pet" Timing Chips** | `AGENTS.md §1 Rule #3`, `PRODUCT_ROADMAP.md` line 98 | **REFUTED.** Staged medicine form only contains standard `'Before Food'`. |
| **Next Review Dropdown with "Not Needed"** | `AGENTS.md §1 Rule #3`, `PRODUCT_ROADMAP.md` line 118 | **REFUTED.** `AdviceAndOrdersSection` renders interval choice chips (`3d`, `5d`, `7d`, `14d`, `1m`, `3m`). No dropdown or "Not Needed" option exists. |
| **5-Step Encounter Pipeline Retired (HK-1)** | `PRODUCT_ROADMAP.md` lines 46-148 | **REFUTED.** `ConsultationEncounterScreen` still renders the full 5-step pipeline (`Step 1`, `Step 2`, `Step 3`, `Step 4`, `Step 5`). |
| **High-Contrast Monochrome A4/A5 Printing** | `AGENTS.md §2`, `README.md` | **REFUTED.** Calls browser `window.print()` which captures the entire screen canvas with appbars, buttons, and grey background, truncating off-screen content. |
| **3-Tier Cryptographic Role Guarding** | `AGENTS.md §2`, `SCHEMA_AND_MODELS.md` | **REFUTED.** Default admin PIN `849201` is hardcoded to never expire, is printed in UI error messages, and Doctor PINs are stored in plaintext in Firestore. |

---

## 🛠️ ARCHITECTURAL SOLUTIONS & CONSOLIDATED GAMEPLAN
*(Single Source of Truth: Operational Rules, Chamber Protocols & Technical Solutions)*

### 1. Doctor Shift Conclusion & Emergency Chamber Release Protocol
- **Active Consultation Invariant:**  
  A doctor **can NEVER end their day while a consultation is running**. Attempting to end the day mid-consultation is strictly prohibited by clinical workflow rules.
- **Early Patient Departure / Emergency Referral Handling:**  
  If a patient leaves early (e.g. emergency hospital transfer, sudden departure, or refusal):
  - The doctor types a note in the **Remarks / Advice field** (e.g. `"Patient referred urgently to hospital emergency / left without prescription"`).
  - The doctor clicks **"Complete & Sign"**.
  - The consultation is permanently committed to Cloud Firestore; paper prescription printing is simply cancelled/skipped.
  - The chamber cleanly transitions to `consultation_ended` (Breather).
- **`[END CONSULTATION FOR TODAY]` (Doctor Chamber Screen):**  
  - Located prominently in the top bar of `DoctorChamberScreen`.
  - Disabled during active encounters; accessible only from the idle/breather/ready state.
  - **Unresolved Token Guard:** If there are patients still waiting in lobby or booked:
    - Triggers warning modal: `"You have X patients remaining in your queue. Are you sure you want to end consultations for today?"`
    - Doctor is permitted to confirm and proceed.
  - **Action:**
    - Transitions Firestore chamber document (`counters/chamber_{doctorId}_{date}`) to `status: 'shift_ended'`.
    - Reception desk live screen immediately updates doctor badge to **`Dr. [Name] — Shift Ended for Today`**.
    - Unresolved lobby tokens remain visible for reception to officially process (reschedule or mark absent).
- **`[RELEASE CHAMBER - FORCED]` (Reception Desk Top Bar):**  
  - Located at the very top of Reception Desk.
  - **Purpose:** Emergency operational fail-safe if a doctor physically walks out, closes their laptop lid, or chamber network sync gets stuck.
  - **Action:** Receptionist taps button, enters Reception PIN (`0000`), enters reason (e.g. `"Doctor left clinic; releasing chamber"`).
  - Resets chamber document to `status: 'idle'` / `shift_ended` with `activeAppointmentId: null`. Unblocks the chamber and reception dispatch immediately for subsequent doctors.

---

### 2. Resolution for Fatal Firestore Patient Document Security Rule (Finding #1)
- **Problem:** `firestore.rules` forces `request.resource.data.phoneNumber == patientPhone` on `/patients/{patientPhone}`, rejecting all new patients with ID `'pat_...'`.
- **Solution:** Update `firestore.rules` to key by canonical patient ID:
  ```firestore
  match /patients/{patientId} {
    allow read: if true;
    allow create, update: if request.resource.data.id == patientId;
    allow delete: if false;
  }
  ```
  Permits household multi-member patient IDs (`pat_*`) and legacy phone keys while enforcing document ID matching.

---

### 3. Resolution for Same-Day Return Visits & Lab Reviews (Finding #3)
- **Problem:** `hasAppointmentForDate` treats earlier `completed` visits as duplicate bookings, and `evaluateReviewEligibility` requires `aDay.isBefore(targetDay)`.
- **Solution:**
  1. In `BookingService.hasAppointmentForDate`: Filter out `completed` and `absent` visits when checking for duplicate queue entries:
     ```dart
     if (appt.status != AppointmentStatus.absent && appt.visitStatus != VisitStatus.completed)
     ```
  2. In `AppointmentEngine.evaluateReviewEligibility`: Allow earlier visits completed on the *same calendar date* to qualify as valid originating paid visits for free review if `a.scheduledDate.isBefore(targetDate)`.

---

### 4. Resolution for Cash Overwrites on Doctor Absence & Drawer Reconciliation (Finding #4)
- **Problem:** `closeDoctorSessionForDate` resets `amountCollected: 0`, destroying cash records and bank UPI ledgers.
- **Solution:**
  1. Never mutate `amountCollected` to `0` on cancellation. Keep `amountCollected` intact, record an explicit cancellation note, and set a dedicated refund flag (e.g. `refundStatus: 'pending_refund' | 'refunded'`).
  2. Update `CashHandoverEngine` to reconcile all monies received at the desk (including pending lobby patients and issued refunds), so counted physical drawer cash matches expected system cash.

---

### 5. Resolution for Atomic Chamber Occupancy (Finding #6)
- **Problem:** `ChamberService.callTokenIntoChamber` executes a separate `get()` and `set()`, allowing dual admission race conditions.
- **Solution:** Wrap `callTokenIntoChamber` in a strict `FirebaseFirestore.instance.runTransaction()`. Atomically verify `status != 'calling' && status != 'in_consultation'` before writing new active token.

---

### 6. Resolution for Ghost Diagnostic Reviews (Finding #7)
- **Problem:** `EncounterFormState.loadInitialData` iterates through all historical lifetime consultations, creating dozens of duplicate blank lab reviews.
- **Solution:** Restrict pre-population strictly to the **most recent prior consultation**, deduplicate by `testName`, and only include tests that have not yet been completed/reviewed.

---

### 7. Resolution for PIN Management & Admin Lockout Trap (Findings #8 & #12)
- **Problem:** No UI exists to change Receptionist or Owner PINs. Default PIN `849201` is hardcoded to never expire, is printed in UI errors, and custom PINs are saved only in local browser storage.
- **Solution:**
  1. Add an **Admin Security Settings Modal** accessible by Owner:
     - Change Receptionist PIN (4 digits).
     - Change Master Owner PIN (6 digits).
  2. Persist hashed PINs in Firestore (`clinic_config/settings`), ensuring immediate synchronization across all clinic counter PCs and tablets.
  3. Remove the hardcoded fallback to `849201` once a custom owner PIN is set.
  4. Provide an emergency secondary recovery secret key or SMS/email OTP fallback to prevent permanent admin lockout.
  5. Remove all PIN hints from production login error messages.

---
*Single Source of Truth updated and maintained in GAMEPLAN.MD.*

