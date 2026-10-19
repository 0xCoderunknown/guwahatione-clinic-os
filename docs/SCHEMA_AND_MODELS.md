# 📊 GuwahatiOne Clinic OS — Data Schema & Model Contracts

> **Single Source of Truth for Firestore Collections, Document IDs, and Serialization Models.**  
> **RULE:** No AI agent may add, rename, or delete any Firestore fields without updating this document and getting approval from the PM.

---

## 🗄️ Firestore Collections Overview

| Collection Name | Document ID Pattern | Description |
|---|---|---|
| `patients` | Unique patient ID (`pat_{timestamp}_{suffix}` or legacy `{phoneNumber}`) | Master patient directory keyed by unique `id`, with `phoneNumber` as household contact index. |
| `doctors` | Auto-generated UID or slug | Consulting doctors, specialty, schedule, fees, and PINs. |
| `appointments` | Auto-generated UID (UUID / Firestore ID) | Daily appointment & token ledger records. **Zero deletions.** |
| `counters` | `queue_{doctorId}_{yyyy-MM-dd}` | Atomic sequence counter for daily queue token numbering. |
| `consultations` | Auto-generated UID | Append-only clinical encounter records. |
| `medicines` | Deterministic `med_*` or auto UID | Master clinic medicine formulary catalogue. |

---

## 📑 1. `patients` Collection

- **Document ID:** Unique patient ID string (`id`, e.g. `pat_1729000000_1234` or legacy 10-digit phone number).
- **Invariance:** Phone number acts as a household index (multiple family members can share one contact phone). Consultations and clinical charts key directly to `id`.

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique patient identity key. |
| `phoneNumber` | `String` | Yes | 10-digit primary household contact phone number. |
| `name` | `String` | Yes | Full name of the patient. |
| `age` | `int` | Yes | Patient age in completed years (or `0` for infants). |
| `ageMonths` | `int?` | No | Age in months for infants (< 1 year). |
| `ageDays` | `int?` | No | Age in days for newborns (< 1 month). |
| `dateOfBirth` | `String?` | No | ISO 8601 date of birth if known. |
| `guardianName` | `String?` | No | Name of parent / caregiver / legal guardian (e.g. `"Sunita Sharma"`). |
| `guardianRelation` | `String?` | No | Relationship of guardian to patient (e.g. `"Mother"`, `"Father"`). |
| `gender` | `String` | Yes | `'Male'`, `'Female'`, or `'Other'`. |
| `allergies` | `List<String>` | No | Critical clinical allergy alerts (e.g. `["Penicillin", "Sulfa"]`). Default: `[]`. |
| `lastVisitDate` | `String` (ISO 8601) | No | Most recent completed consultation time; absent until the patient has a consultation. |

---

## 👨‍⚕️ 2. `doctors` Collection

- **Document ID:** Unique doctor ID (`doctorId`).

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Unique identifier. |
| `name` | `String` | Yes | Doctor full title & name (e.g. `"Dr. A. Sharma"`). |
| `specialty` | `String` | Yes | Specialty (e.g. `"General Medicine"`, `"Cardiology"`). |
| `phone` | `String` | Yes | Contact phone number. |
| `availableDays` | `List<String>` | Yes | Days on duty (e.g. `["Mon", "Tue", "Wed"]`). |
| `blockedDates` | `List<String>` (ISO 8601) | No | Dates doctor is on leave. |
| `pin` | `String` | Yes | 4-digit numeric PIN for chamber access (default: `'1234'`). |
| `consultationFee` | `int` | Yes | Consultation fee in INR (e.g. `500`). |
| `freeReviewDays` | `int` | Yes | Free review policy window in days (`0` to `30`; `0` = no free review; default: `14`). |
| `searchPreference` | `String` | No | Drug search mode: `'brandFirst'` or `'compositionFirst'` (default: `'brandFirst'`). |
| `medicalRegNumber` | `String?` | No | State Medical Council / NMC registration number (e.g. `'AMC-24891'`). |
| `shiftTiming` | `String` | No | Active OPD sitting hours (e.g. `'6:00 PM – 8:30 PM'`; default: `'6:00 PM – 8:30 PM'`). |
| `dailyTokenLimit` | `int` | No | Maximum token allocation cap per calendar day (default: `18`). |
| `isActive` | `bool` | No | Operational status (`true` = active, `false` = retired/inactive). Preserves longitudinal consultations & audit records. Default: `true`. |

---

## 🎟️ 3. `appointments` Collection (Audit-Proof Ledger)

- **Document ID:** Unique appointment ID.
- **Rule:** **NEVER DELETE.** If patient cancels, mark `status = 'absent'` and `amountCollected = 0`.

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Appointment ID. |
| `patientId` | `String` | Yes | Unique patient identity ID (defaults to `patientPhone` in legacy records). |
| `patientPhone` | `String` | Yes | Patient's primary household contact phone number. |
| `patientName` | `String` | Yes | Patient's name at time of booking. |
| `patientAgeDisplay` | `String?` | No | Formatted age string (e.g. `"4 Months"`, `"18 Days"`, `"34 Years"`). |
| `guardianName` | `String?` | No | Optional parent or caregiver name. |
| `guardianRelation` | `String?` | No | Relationship of guardian to patient. |
| `status` | `String` (Enum) | Yes | `'pending'`, `'completed'`, or `'absent'` (retained for operational ledger). |
| `visitStatus` | `String` (Enum) | Yes | `'booked'`, `'waitingInLobby'`, `'inConsultation'`, `'completed'`, or `'cancelled'`. |
| `paymentType` | `String` (Enum) | Yes | `'paidCash'`, `'paidUpi'`, `'freeReview'`, `'freeFamily'`, `'postPay'`, or `'unpaid'`. |
| `amountCollected`| `int` | Yes | Cash/UPI amount collected in INR. |
| `queueNumber` | `int` | Yes | Strictly consecutive token number ($1, 2, 3 \dots N$). |
| `scheduledDate` | `Timestamp` | Yes | Calendar date and time of appointment. |
| `doctorId` | `String` | Yes | Assigned doctor ID. |
| `doctorName` | `String` | Yes | Assigned doctor display name. |
| `checkedInAt` | `Timestamp?` | No | Timestamp recorded when patient arrives at desk and checks in to lobby. |
| `isPaused` | `bool` | No | Whether an active consultation encounter was paused (draft saved) and returned to lobby queue. Default: `false`. |
| `notes` | `String?` | No | Operational ledger audit note (e.g. cancellation or doctor absent session close reason). |

---

## 🔢 4. `counters` Collection (Atomic Queue & Chamber State)

### A. Daily Queue Counter
- **Document ID:** `queue_{doctorId}_{yyyy-MM-dd}`
- **Purpose:** Transactional atomic counter to prevent race conditions on daily token numbers.

| Field | Type | Description |
|---|---|---|
| `currentNumber` | `int` | Current highest issued queue number for the day. |

### B. Chamber Calling Session
- **Document ID:** `chamber_{doctorId}_{yyyy-MM-dd}` (stored inside `counters` collection via `FirestorePaths.chamberSyncDoc`)
- **Purpose:** Real-time sync document listened to by Doctor Chamber Screen for automatic encounter loading when reception calls a token.
- **Model:** `ChamberSession` (`lib/models/chamber_session.dart`). Zero SDK leaks to UI presentation layer.

| Field | Type | Required | Description |
|---|---|---|---|
| `doctorId` | `String` | Yes | Doctor identifier. Deserialized by `ChamberSession.fromMap`. |
| `date` | `String` | Yes | Calendar date key (`yyyy-MM-dd`) for multi-doctor daily queue indexing. |
| `status` | `String` | Yes | `'idle'`, `'ready_for_next'`, `'calling'`, `'in_consultation'`, `'consultation_ended'`, `'shift_ended'`. |
| `activeAppointmentId` | `String?` | No | Appointment ID currently called into the chamber. |
| `activeQueueNumber` | `int?` | No | Token number currently called into the chamber. |
| `patientName` | `String?` | No | Name of the patient called or consulting. |
| `patientPhone` | `String?` | No | Contact number of the patient called or consulting. |
| `lastCompletedQueueNumber` | `int?` | No | Token number of consultation that just concluded. |
| `lastCompletedPatientName` | `String?` | No | Name of patient whose consultation just concluded. |
| `calledAt` | `Timestamp?` | No | Server timestamp recorded when patient is called into chamber. |
| `readyAt` | `Timestamp?` | No | Server timestamp recorded when doctor signals readiness for next token. |
| `endedAt` | `Timestamp?` | No | Server timestamp recorded when doctor completes encounter (breather). |
| `shiftEndedAt` | `Timestamp?` | No | Server timestamp recorded when doctor concludes consultations for the day. |
| `clearedAt` | `Timestamp?` | No | Server timestamp recorded when chamber session resets to idle. |

---

## 🩺 5. `consultations` Collection (Append-Only Clinical History)

- **Document ID:** Unique consultation ID.
- **Tenet:** Append-only clinical events. Never mutate previous visit documents.

### Fields
| Field | Type | Description |
|---|---|---|
| `id` | `String` | Consultation ID. |
| `appointmentId` | `String` | Reference to corresponding appointment. |
| `patientId` | `String` | Unique patient ID (primary clinical chart link; defaults to `patientPhone` in legacy records). |
| `patientPhone` | `String` | Patient contact phone number (household index). |
| `patientName` | `String` | Patient full name. |
| `patientAge` | `int` | Patient age at consultation time (or 0 for infants). |
| `patientAgeDisplay` | `String?` | Formatted clinical age (e.g. `"4 Months"`, `"18 Days"`, `"34 Years"`). |
| `guardianName` | `String?` | Parent or caregiver name (e.g. `"Sunita Sharma"`). |
| `guardianRelation` | `String?` | Relationship of guardian to patient (e.g. `"Mother"`). |
| `patientGender` | `String` | Patient gender. |
| `doctorId` | `String` | Prescribing doctor ID. |
| `doctorName` | `String` | Prescribing doctor name. |
| `doctorRegNumber` | `String?` | Medical Council registration number at time of consultation. |
| `createdAt` | `Timestamp` | Time consultation took place. |
| `vitals` | `Map` (Vitals) | Nested vitals map (see Vitals structure below). |
| `chiefComplaints` | `List<String>` | List of presenting symptoms/complaints. |
| `clinicalExamination`| `String?` | Free-text clinical examination findings. |
| `provisionalDiagnosis`| `List<String>` | Clinical diagnoses (e.g. `["Type 2 Diabetes Mellitus", "Essential HTN"]`). |
| `reviewedInvestigations`| `List<Map>` | Past lab results reviewed during encounter. |
| `prescriptionItems`| `List<Map>` | Prescribed medications (reconciled START, CONTINUE, STOP). |
| `orderedTests` | `List<Map>` | Tests ordered for next review. |
| `adviceNotes` | `String?` | Lifestyle, diet, or special precautions. |
| `nextFollowUpDate` | `Timestamp?` | Recommended follow-up date (3d, 7d, 14d, 1m, 3m). |

### Nested: `Vitals`
```json
{
  "systolicBp": 120,
  "diastolicBp": 80,
  "pulseRate": 72,
  "temperature": 98.6,
  "weightKg": 68.5,
  "spO2": 98,
  "respiratoryRate": 16,
  "bloodSugar": 110.0
}
```

### Nested: `PrescriptionItem`
```json
{
  "id": "uuid",
  "action": "START | CONTINUE | STOP",
  "medicineId": "med_dolo_650",
  "medicineName": "Dolo 650 tablet",
  "composition": "Paracetamol 650mg",
  "manufacturer": "Micro Labs Ltd",
  "strength": "650 mg",        // legacy / snapshot optional
  "form": "Tablet",           // legacy / snapshot optional
  "dosage": "1 Tablet",
  "frequency": "1-0-1",
  "timing": "After Food",
  "durationDays": 5,          // null = chronic ongoing medication
  "stopReason": null,         // required if action == STOP
  "unlistedName": null,       // outside brand not in formulary
  "instructions": "SOS for fever"
}
```

### Nested: `DiagnosticInvestigationReview`
```json
{
  "id": "uuid",
  "testName": "HbA1c",
  "resultValue": "6.8%",
  "performedDate": Timestamp,
  "notes": "Controlled"
}
```

### Nested: `OrderedTest`
```json
{
  "testName": "Fasting Blood Sugar",
  "instructions": "Overnight 10-12 hrs fasting"
}
```

---

## 💊 6. `medicines` Collection (Formulary Catalogue)

- **Document ID:** Canonical deterministic slug (e.g. `med_dolo_650`) or UUID.
- **Architectural Simplification (Zero Backward-Compatibility Debt):** Dosage form is integral to `productName` (e.g. `"Telma 40 tablet"`), and molecule strength is integral to `composition` (e.g. `"Telmisartan 40mg"`). Redundant separate `strength`, `form`, and `category` fields are retired.

### Fields
| Field | Type | Description |
|---|---|---|
| `id` | `String` | Deterministic or unique ID. |
| `productName` | `String` | Commercial brand name with form (e.g. `"Telma 40 tablet"`, `"Dolo 650 tablet"`, `"Ascoril D Plus syrup"`). |
| `composition` | `String` | Generic chemical active ingredient with strength (e.g. `"Telmisartan 40mg"`, `"Paracetamol 650mg"`). |
| `manufacturer` | `String?` | Pharmaceutical manufacturer (e.g. `"Glenmark"`, `"Micro Labs"`, `"GSK"`). |
| `defaultDosage` | `String?` | Clinical default dosage (e.g. `"1 Tablet"`, `"5 ml"`). |
| `defaultFrequency` | `String?` | Clinical default regimen (e.g. `"1-0-0 (OD)"`, `"1-0-1 (BD)"`). |
| `defaultTiming` | `String?` | Clinical default timing (e.g. `"Before Food"`, `"After Food"`). |
| `defaultDurationDays` | `int?` | Clinical default duration in days (e.g. `30`, `5`), or `null` for chronic. |

---

## ⚙️ 7. `clinic_config` Collection (Authentication & System Settings)

- **Document ID:** `settings` (or `auth`).
- **Purpose:** Clinic-wide operational configuration and master PIN hashes.

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `ownerPinHash` | `String` | No | SHA-256 hashed 6-digit PIN for Clinic Owner role (`owner`). Default hash resolves to master PIN `849201`. |
| `clinicName` | `String` | No | Official clinic display title. |
| `address` | `String` | No | Clinic postal address for prescription headers. |

---

## 📜 8. `appointment_events` Collection — 🗑️ Retired & Pruned (HK-2)

- **Status:** **RETIRED & PRUNED** in `v1.32.0` under Invariant #10 (Zero Backward-Compatibility Debt) as part of HK-2 Housekeeping.
- **Rationale:** Write-only sub-collection with zero UI readers that unnecessarily doubled Firestore write costs.
- **Canonical Lifecycle Auditing:** Operational and legal auditing is preserved directly on the primary `appointments` collection via permanent document retention (Invariant #1: Zero Deletions), status transitions, and native timestamps (`scheduledDate`, `checkedInAt`, `updatedAt`).

## 🔒 9. Composite Invariants & Business Logic Contracts

1. **Queue Concurrency & Immutability:** Daily counter tokens ($1 \dots N$) are issued via atomic Firestore transaction at `counters/queue_{doctorId}_{yyyy-MM-dd}`. Never delete an appointment document; cancellations must use `AppointmentStatus.absent` with `amountCollected: 0`.
2. **Duplicate Patient Booking Prevention:** A patient cannot hold multiple active (non-absent) appointments with the same doctor on the same calendar day. The composite validation key is:
   $$\text{scheduledDate} + \text{doctorId} + \text{normalized patientName} + \text{patientPhone}$$
   Family members sharing a phone number are distinguished by `normalized patientName`.
3. **Doctor-Configured Free Review Policy:** Each doctor defines a `freeReviewDays` window (`0`–`30`; default `14`). Free reviews are valid only when the patient has a prior non-absent **paid** consultation with the **same** doctor within that configured window, and only if no free review has already been consumed in the current cycle (strict 1:1 per paid visit). Setting `freeReviewDays: 0` disables free reviews entirely for that doctor.
4. **Clean Presentation Boundary:** Zero raw Firebase objects (`DocumentSnapshot`, `FieldValue`, `cloud_firestore`) may cross into Flutter screens or widgets; all data flow routes via pure domain models (`ChamberSession`, `Appointment`, etc.) and dedicated engines.
5. **Mandatory Indian Date Formatting (`DD-MM-YYYY`):** While database and internal serialization continue to use standard Firestore `Timestamp` or ISO-8601 strings, all human-facing presentation and documentation must strictly use `DD-MM-YYYY` (via `AppFormatters`).

---

## 💾 10. Local Client Storage & Domain Handover Contracts

### A. Offline Queue Fallback Storage (`SharedPreferences`)
- **Key Pattern:** `offline_queue_{yyyy-MM-dd}`
- **Timestamp Key Pattern:** `offline_queue_time_{yyyy-MM-dd}`
- **Purpose:** Local browser/device cache enabling zero-dropout counter operations during broadband disruptions.
- **Serialization:** JSON array of `Appointment.toCacheMap()` entries with ISO-8601 string dates.

### B. Daily Cash Handover Domain Models
- **`CashHandoverSummary`:** Aggregates realized cash, completed consultations, paid counts, and free reviews (Review & Family).
- **`CashHandoverDoctorRow`:** Segments cash drawer receipts by doctor for closing sign-off.
- **Denomination Math:** Evaluates note counts (`₹500`, `₹200`, `₹100`, `₹50`, `₹20`, `₹10`) against expected realized revenue to audit discrepancies.

### C. Prescription Template Presets Domain Models
- **Source:** `lib/models/prescription_template.dart`, exported via `lib/models/models.dart`.
- **`PrescriptionTemplateItem`:** Clinical template entry (`medicineName`, `composition`, `dosage`, `frequency`, `timing`, `durationDays`, `instructions`). Converts via `.toPrescriptionItem()` into staged `PrescriptionItem` with action `MedicationAction.start`.
- **`PrescriptionTemplate`:** Pre-configured OPD clinical preset bundle (`id`, `name`, `description`, `emoji`, `items`).
- **`TemplateApplicationResult`:** Forensic result returned by `MedicineEngine.evaluateTemplateApplication` (`templateName`, `addedItems`, `skippedDuplicates`). Evaluates existing active medications and safely skips duplicate brands or matching generic salts.

### D. Sound Announcer Preference Storage (`SharedPreferences`)
- **Key:** `sound_announcer_muted`
- **Type:** `bool`
- **Purpose:** Persists per-device mute preference for in-clinic queue chime and SpeechSynthesis vocal token callout across browser sessions.
- **Default:** `false` (sound enabled).
- **Consumer:** `SoundService` (`lib/services/sound_service.dart`).

### E. Client Feature Flags & Deployment Configurations (`ClinicFeatureFlags`)
- **Source:** `lib/config/clinic_config.dart`.
- **Purpose:** Centralized per-tenant / client deployment configuration controlling stable operational workflows and experimental pilot features.
- **Stable Operational Flags:**
  - `enableLetterheadToggle` (`bool`, default: `true`): Enables pre-printed stationery margin toggle on prescription print previews.
  - `enableDoctorChamberOverride` (`bool`, default: `true`): Enables restricted emergency door self-call runway on doctor chamber screen.
  - `enableWhatsAppPrescriptionShare` (`bool`, default: `true`): Enables 1-tap WhatsApp deep-link prescription sharing.
  - `requireDoctorChamberPin` (`bool`, default: `true`): Enforces 4-digit numeric PIN authentication for chamber access.
- **🧪 Experimental Flags (Tenant Configurable):**
  - `enablePrescriptionTemplatePresets` (`bool`, default: `false`): Enables generic GP prescribing bundle chips in clinical encounter.
  - `enableTokenReceiptPrint` (`bool`, default: `false`): Enables counter token receipt slip dialog after walk-in registration and on queue accordion cards.
  - `enableBulkSessionClose` (`bool`, default: `true`): Enables Owner-PIN-gated bulk "Close Session (Doctor Absent)" batch action marking un-consulted tokens as absent with ₹0 collection.
  - `enableGroupedCompositionCards` (`bool`, default: `true`): Renders grouped composition cards [COMPOSITION] with associated trade brand pills in medicine search.
  - `hidePrescriptionComposition` (`bool`, default: `false`): When enabled, suppresses generic chemical composition and renders trade brand names exclusively on prescriptions.

