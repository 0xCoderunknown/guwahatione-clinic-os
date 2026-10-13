# 🏛️ GuwahatiOne Clinic OS — Healthcare Compliance, Data Privacy & Governance Matrix

> **Authoritative Specification for Clinical Data Protection, Consent Architecture, and Regulatory Alignment.**  
> **Jurisdictional Standard:** Digital Personal Data Protection (DPDP) Act, 2023 & Ayushman Bharat Digital Mission (ABDM) Guidelines.  
> **Date Standard:** All audit dates and human-facing records strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## 🎯 1. Regulatory Framework & Standards

GuwahatiOne Clinic OS is designed for Indian outpatient (OPD) clinics, multi-doctor polyclinics, and consultant chambers. Its data handling protocols adhere to:

1. **Digital Personal Data Protection Act (DPDP Act, 2023):**
   - Explicit purpose specification for demographic and clinical processing.
   - Purpose limitation: Patient data is processed strictly for clinical diagnosis, prescribing, and audit-proof token allocation.
   - Data minimization: Non-clinical staff (receptionists) are strictly restricted from seeing physician clinical examination notes and provisional diagnoses.
2. **National Medical Commission (NMC) Registered Medical Practitioner Regulations:**
   - Preservation of outpatient prescription and consultation records for a minimum statutory period of **3 years**.
   - Mandatory inclusion of State Medical Council / NMC registration numbers on all official printed outputs (`medicalRegNumber`).
3. **Ayushman Bharat Digital Mission (ABDM) Health Data Management Policy:**
   - Longitudinal clinical encounters represented as immutable append-only events.
   - Distinct patient directory keyed by primary 10-digit mobile contact number.

---

## 🔐 2. Three-Tier Role-Based Access Control (RBAC) Matrix

To prevent unauthorized data exposure, clinic operations are compartmentalized into three strict trust domains:

| Data Category | Clinic Owner (Master PIN) | Consulting Physician (Chamber PIN) | Front Desk Receptionist (Counter PIN) |
|---|:---:|:---:|:---:|
| **Patient Demographics** (Name, Phone, Age, Gender) | Full Access | Full Access | Full Access |
| **Allergy Alerts Banner** | Read Only | Full Access (Alert Trigger) | Read Only |
| **Clinical Examination & Vitals** | No Access | Full Read/Write | No Access |
| **Past Diagnostic Reports & Lab Orders** | No Access | Full Read/Write | No Access |
| **Prescription History (`START`/`CONTINUE`/`STOP`)** | No Access | Full Read/Write | No Access (Print only on direct dispense) |
| **Daily Queue Token Roster** | Read Only | Read Only (Assigned Chamber) | Full Dispatch Control |
| **Financial Ledger & Cash Handover** | Full Audit Access | Individual Fee Summary Only | Daily Counter Drawer Tally Only |
| **Doctor Fee Configuration & Profiles** | Full Admin CRUD | View Only | View Only |

---

## 🛡️ 3. Credential & Cryptographic Storage Security

1. **SHA-256 PIN Hashing:**
   - All access PINs (Owner 6-digit Master PIN, Reception 4-digit PIN, Doctor Chamber PINs) are cryptographically hashed using **SHA-256** with a clinic domain salt before storage and verification (`AuthProvider.hashPin`).
   - Plaintext credentials are **NEVER** stored in browser storage, `SharedPreferences`, or client databases.
   - Legacy plaintext keys are automatically migrated to hashes and purged from storage upon session boot.
2. **Database Engine Immutability (`firestore.rules`):**
   - **Zero Deletions:** `allow delete: if false;` is enforced at the database storage engine layer across `appointments`, `consultations`, `patients`, and `counters`.
   - **Append-Only Encounters:** Past consultations and `appointment_events` cannot be edited or updated (`allow update: if false;`).

---

## 📜 4. Forensic Operational Audit Trail (`appointment_events`)

Every state mutation in the clinic is recorded in an immutable append-only audit ledger (`appointment_events`):

| Lifecycle Event | Actor Role | Logged Payload |
|---|---|---|
| `created` | Receptionist | Token issued, doctor assigned, fee collected, timestamp. |
| `checkedIn` | Receptionist | Physical lobby arrival verified, payment method reconciled. |
| `admitted` | Receptionist / Doctor | Chamber entry handshake confirmed, occupancy collision guard verified. |
| `completed` | Doctor | Clinical prescription issued, session concluded, last visit date updated. |
| `markedAbsent` | Receptionist / Admin | No-show recorded, token slot preserved, ₹0 fee locked. |
| `statusUpdated` | Receptionist / Admin | Discretionary desk override with timestamped operational note. |

---

## 🏥 5. Patient Consent & Data Subject Rights

1. **Explicit Notice at Walk-In Registration:**
   - The counter receptionist must verbally inform the patient that their phone number and clinical details are registered for generating the digital prescription and managing queue tokens.
2. **Family Member Disambiguation:**
   - GuwahatiOne Clinic OS permits multiple family members (e.g. parent, children, spouse) under a single shared phone number via composite key normalization (`phone + normalized patientName`), ensuring each family member maintains an independent medical record without identity collision.
3. **Emergency Care Overrides:**
   - In urgent clinical presentations, physical check-in and queue admission can be dispatched immediately via the Doctor Chamber Emergency Self-Call Runway (`ChamberDoorOverrideBar`) without bureaucratic lockouts.
