# 001. Patient Identity & Household Model

> **Status:** Accepted  
> **Date:** 15-10-2026  
> **Author:** Senior Clinical Systems Architect & Product Manager  
> **Target Release:** GuwahatiOne Clinic OS 1.34.0  

---

## 1. Context & Problem Statement

In the current codebase, the `patients` Firestore collection uses the patient's 10-digit phone number directly as the document ID: `patients/{phoneNumber}`. Furthermore:
1. `BookingService.bookAppointment()` executes `_patientsRef.doc(patient.phoneNumber).set(..., SetOptions(merge: true))`.
2. `ConsultationService.getConsultationsForPatient()` queries clinical consultations by contact phone: `_consultationsRef.where('patientPhone', isEqualTo: phone)`.
3. `Patient.age` is stored strictly as an `int` in whole years.

### Real-World Failure Scenarios:
1. **Master Record Overwrite Collision (Data Erasure):**
   In Indian outpatient clinics, mobile numbers belong to households/families, not individual patients. Infants, young children, and elderly dependents do not have personal phone numbers. When a mother (*Sunita, 34 F*) books for her 6-month-old infant (*Aarav*), `patients/9876543210` is written with the infant's data. When the mother visits next week for herself, her registration overwrites the infant's document, permanently erasing the child's demographic record from the master directory.
2. **Longitudinal Chart Cross-Contamination (Clinical Safety Hazard):**
   Because consultations are queried solely by `patientPhone`, opening the longitudinal history for the infant displays a mingled timeline combining the infant's paediatric notes, the mother's obstetric/gynaecology consultations, and a grandparent's cardiology notes. This violates Invariant #2 (append-only patient-specific longitudinal clinical records).
3. **Paediatric Dosing Inadequacy:**
   Infants and neonates (e.g., 3 months old, 15 days old) are forced into `age: 0`, which is clinically unacceptable for paediatric prescriptions. In addition, there is no field to capture the accompanying parent or guardian's name and relationship (`guardianName`, `guardianRelation`).

---

## 2. Options Considered

### Option 1: Composite Key (`pat_{phoneNumber}_{normalizedName}`)
- **Concept:** Generate document IDs using the contact phone and slugified name (e.g. `pat_9876543210_aarav_sharma`).
- **Pros:** Human-readable document IDs in Firestore console.
- **Cons:** Extremely fragile. Any minor spelling variance, abbreviation, or typo (e.g., "Aarav" vs "Arav", "Mohd" vs "Mohammed") creates accidental duplicate identities. If reception fixes a spelling mistake later, the ID must mutate, breaking foreign-key references in historical appointments and consultations.

### Option 2: Generated Immutable Patient ID (`pat_${uuid}`) with Contact Phone Index (Chosen)
- **Concept:** Every distinct human patient is assigned an immutable unique identifier (e.g. `pat_${uuid}` or UUID). The phone number is stored on the document as an indexed, non-unique contact field. Multiple patient profiles can legitimately share the exact same contact phone number.
- **Pros:**
  - Robust identity: Name corrections or demographic tweaks never mutate the patient ID.
  - Zero collision: Every family member has their own independent record in `patients`.
  - Clean clinical isolation: Consultations and appointments link directly to `patientId`.
  - Paediatric support: Allows storing `dateOfBirth` or structured age with age units (`months`, `days`, `years`) and guardian c/o information.
- **Cons:** Requires updating `BookingService`, `PatientService`, and `ConsultationService` to link records by `patientId` while maintaining backward-compatible read paths for legacy phone-keyed records.

### Option 3: Hierarchical Subcollections (`households/{phone}/members/{memberId}`)
- **Concept:** Create a top-level household collection with member subcollections.
- **Pros:** Explicit household tree.
- **Cons:** Excessive Firestore query complexity, subcollection group query index requirements, and awkward migrations when dependents move or obtain their own phone numbers.

---

## 3. Decision & Technical Blueprint

We select **Option 2**.

### 3.1 Data Model Changes
- **`Patient` (`lib/models/patient.dart`):**
  - `id`: Unique patient ID (e.g. `pat_${uuid}` or UUID; legacy records may retain phone string).
  - `phoneNumber`: Contact phone number (indexed, non-unique across documents).
  - `dateOfBirth`: Optional `DateTime?`.
  - `ageMonths`: Optional `int?` (for infants < 2 years, e.g. 4 months).
  - `ageDays`: Optional `int?` (for neonates < 1 month, e.g. 18 days).
  - `guardianName`: Optional `String?` (e.g. `"Sunita Sharma"`).
  - `guardianRelation`: Optional `String?` (e.g. `"Mother"`, `"Father"`, `"Spouse"`, `"Son"`, `"Daughter"`, `"Guardian"`).
  - `isLegacy`: Optional `bool` indicating an un-disambiguated pre-migration record.
  - Helper getter `formattedAge`: Returns `"4 Months"`, `"18 Days"`, or `"34 Years"`.
- **`Appointment` (`lib/models/appointment.dart`):**
  - `patientId`: Unique patient identifier (falling back to `patientPhone` if absent).
  - `guardianName`: Optional `String?`.
  - `guardianRelation`: Optional `String?`.
  - `patientAgeDisplay`: Optional `String?` (preserves exact age snapshot at appointment time).
- **`Consultation` (`lib/models/consultation.dart`):**
  - `patientId`: Unique patient identifier (falling back to `patientPhone` if absent).
  - `guardianName`: Optional `String?`.
  - `guardianRelation`: Optional `String?`.
  - `patientAgeDisplay`: Optional `String?`.

### 3.2 Service Layer Updates
1. **`PatientService` (`lib/services/patient_service.dart`):**
   - `getPatient(String patientId)`: Fetches `patients/{patientId}`. If not found and ID is 10 digits, checks `patients/{phone}` as legacy fallback.
   - `getPatientsForPhone(String phone)`: Queries `_patientsRef.where('phoneNumber', isEqualTo: phone)`. If empty, checks `_patientsRef.doc(phone).get()` (legacy fallback). Returns `List<Patient>`.
   - `savePatient(Patient patient)`: Writes `_patientsRef.doc(patient.id).set(patient.toJson(), SetOptions(merge: true))`.
2. **`BookingService` (`lib/services/booking_service.dart`):**
   - `bookAppointment`: Saves `appointment.patientId = patient.id`, writes patient under `patients/{patient.id}`.
   - `hasAppointmentForDate`: Checks duplicate booking for the specific `patientId` (or matching name on the same phone), ensuring family members on the same phone can independently consult the same doctor on the same date without false duplicate blocks.
3. **`ConsultationService` (`lib/services/consultation_service.dart`):**
   - `saveConsultation`: Persists `consultation.patientId`.
   - `getConsultationsForPatient(String patientId, {String? legacyPhone})`: Primary query by `patientId`. If empty and `legacyPhone != null`, falls back to legacy `patientPhone` query so historical consultations remain accessible.

### 3.3 Reception & Prescribing UX
1. **Reception (`AddAppointmentDialog`):**
   - Entering a 10-digit phone triggers `getPatientsForPhone()`.
   - If multiple family members are registered, displays quick selector chips:
     `[ 👤 Sunita (34 Yrs) ]  [ 👶 Aarav (6 Mos) ]  [ ➕ New Family Member ]`
   - Selecting a chip fills that specific patient's profile, prior history, and review eligibility.
   - Clicking *"New Family Member"* generates a new `patientId`, retains the contact phone, and displays clean fields for child name, age (with Months/Years toggle), and Guardian details.
2. **Prescription Print & WhatsApp:**
   - Displays patient name, formatted age, and guardian c/o:  
     `Patient: Aarav Sharma (6 Months / Male) | c/o Sunita Sharma (Mother) | Ph: 9876543210`.

---

## 4. Migration & Rollback Plan

### Forward Migration (Non-Destructive & Lazy)
- **Legacy Records:** Existing Firestore records live at `patients/{phone}`.
- **Backward-Compatible Read Path:** All query methods (`getPatient`, `getPatientsForPhone`, `getConsultationsForPatient`) inspect the new fields first. If absent, they fall back to legacy document ID or `patientPhone` queries.
- **Lazy Promotion:** When a legacy patient visits the clinic or a family member is added, the record is saved with a canonical `patientId`, leaving the legacy record intact or tagged with `isLegacy: true`.
- **One-Off Batch Migration Script (Optional):** Can be run via administrative CLI to backfill `patientId = doc.id` and `isLegacy = true` on existing documents without altering any data.

### Rollback Plan
- All models continue to serialize and read `phoneNumber` and `patientPhone`.
- If the system is rolled back to an earlier version, the `patientPhone` field remains populated on all appointments and consultations.
