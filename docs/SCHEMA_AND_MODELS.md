# 📊 GuwahatiOne Clinic OS — Data Schema & Model Contracts

> **Single Source of Truth for Firestore Collections, Document IDs, and Serialization Models.**  
> **RULE:** No AI agent may add, rename, or delete any Firestore fields without updating this document and getting approval from the PM.

---

## 🗄️ Firestore Collections Overview

| Collection Name | Document ID Pattern | Description |
|---|---|---|
| `patients` | `{phoneNumber}` (e.g. `9876543210`) | Master patient directory keyed by 10-digit phone number. |
| `doctors` | Auto-generated UID or slug | Consulting doctors, specialty, schedule, fees, and PINs. |
| `appointments` | Auto-generated UID (UUID / Firestore ID) | Daily appointment & token ledger records. **Zero deletions.** |
| `counters` | `queue_{doctorId}_{yyyy-MM-dd}` | Atomic sequence counter for daily queue token numbering. |
| `consultations` | Auto-generated UID | Append-only clinical encounter records across 5 steps. |
| `medicines` | Deterministic `med_*` or auto UID | Master clinic medicine formulary catalogue. |

---

## 📑 1. `patients` Collection

- **Document ID:** 10-digit phone number string (`phoneNumber`).

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Same as `phoneNumber`. |
| `phoneNumber` | `String` | Yes | 10-digit primary phone number. |
| `name` | `String` | Yes | Full name of the patient. |
| `age` | `int` | Yes | Patient age in years. |
| `gender` | `String` | Yes | `'Male'`, `'Female'`, or `'Other'`. |
| `allergies` | `List<String>` | No | Critical clinical allergy alerts (e.g. `["Penicillin", "Sulfa"]`). Default: `[]`. |
| `lastVisitDate` | `String` (ISO 8601) | Yes | ISO timestamp of the most recent clinic visit. |

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

---

## 🎟️ 3. `appointments` Collection (Audit-Proof Ledger)

- **Document ID:** Unique appointment ID.
- **Rule:** **NEVER DELETE.** If patient cancels, mark `status = 'absent'` and `amountCollected = 0`.

### Fields
| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | Yes | Appointment ID. |
| `patientPhone` | `String` | Yes | Patient's phone number. |
| `patientName` | `String` | Yes | Patient's name at time of booking. |
| `status` | `String` (Enum) | Yes | `'pending'`, `'completed'`, or `'absent'`. |
| `paymentType` | `String` (Enum) | Yes | `'paid'`, `'freeReview'`, or `'freeFamily'`. |
| `amountCollected`| `int` | Yes | Cash/UPI amount collected in INR. |
| `queueNumber` | `int` | Yes | Strictly consecutive token number ($1, 2, 3 \dots N$). |
| `scheduledDate` | `Timestamp` | Yes | Calendar date and time of appointment. |
| `doctorId` | `String` | Yes | Assigned doctor ID. |
| `doctorName` | `String` | Yes | Assigned doctor display name. |

---

## 🔢 4. `counters` Collection (Atomic Queue Counter)

- **Document ID:** `queue_{doctorId}_{yyyy-MM-dd}`
- **Purpose:** Transactional atomic counter to guarantee zero race conditions on token numbers.

### Fields
| Field | Type | Description |
|---|---|---|
| `currentNumber` | `int` | Current highest issued queue number for the day. |

---

## 🩺 5. `consultations` Collection (Append-Only Clinical History)

- **Document ID:** Unique consultation ID.
- **Tenet:** Append-only clinical events. Never mutate previous visit documents.

### Fields
| Field | Type | Description |
|---|---|---|
| `id` | `String` | Consultation ID. |
| `appointmentId` | `String` | Reference to corresponding appointment. |
| `patientPhone` | `String` | Patient phone number. |
| `patientName` | `String` | Patient full name. |
| `patientAge` | `int` | Patient age at consultation time. |
| `patientGender` | `String` | Patient gender. |
| `doctorId` | `String` | Prescribing doctor ID. |
| `doctorName` | `String` | Prescribing doctor name. |
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
  "medicineName": "Dolo 650",
  "composition": "Paracetamol 650mg",
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

### Fields
| Field | Type | Description |
|---|---|---|
| `id` | `String` | Deterministic or unique ID. |
| `productName` | `String` | Commercial brand name (e.g. `"Dolo 650"`, `"Pan 40"`). |
| `composition` | `String` | Chemical generic active ingredient (e.g. `"Paracetamol"`). |
| `strength` | `String` | Strength with units (e.g. `"650 mg"`). |
| `form` | `String` | Dosage form (`"Tablet"`, `"Syrup"`, `"Capsule"`, `"Ointment"`, etc.). |
| `manufacturer` | `String?` | Pharmaceutical manufacturer (e.g. `"Micro Labs"`). |
| `category` | `String?` | Therapeutic class (e.g. `"Analgesic / Antipyretic"`). |
