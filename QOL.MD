# 📋 GuwahatiOne Clinic OS — Quality of Life (QOL) & Feature Backlog

> **Purpose:** Single source of truth for all pending Quality-of-Life (QOL) features, future roadmap items, and deferred architectural enhancements shifted from `docs/PRODUCT_ROADMAP.md` and `GAMEPLAN.MD`.  
> **Status:** Active Working Backlog (Zero newly invented items; strictly consolidated from existing codebase documents).  
> **Date Standard:** All dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## 🧭 Invariants & Guardrails Reminder

All items in this backlog must strictly adhere to the codebase invariants defined in `AGENTS.md`:
1. **Audit-Proof Zero Deletions:** Tokens are never deleted; cancellations/no-shows remain `absent` at ₹0.
2. **Doctor-Paced Single-Occupancy Chamber:** Reception can never force or pre-empt an active consultation.
3. **Strict 3-Column Prescription Isolation:** Column 1: Medicine & Composition (`Brand [COMPOSITION]`), Column 2: Dosage & Timing (`1-0-1 • After Food`), Column 3: Duration / Status (`14 Days` / `To Continue`).
4. **Zero Pharmacy ERP / POS Clutter:** No batch tracking, retail inventory, or OTC retail sales.
5. **Indian Date Standard:** Human-facing dates must always render as `DD-MM-YYYY`.

---

## 🏥 1. Reception & Counter Desk QOL

### 1.1 Emergency / Illiterate Walk-In Dummy Key (`P13`)
- **Original Source:** `docs/PRODUCT_ROADMAP.md` §4 (`P13`), `CONTRIBUTING.md`
- **Problem:** Emergency casualty or elderly village patient arrives without a mobile phone or cannot recall it. Registration strictly mandates a 10-digit primary phone key, blocking immediate token issuance.
- **Specification:**
  - 1-tap `[No Mobile / Emergency Dummy]` toggle at walk-in registration.
  - Allocates sequential clinic dummy phone keys (`9900000001`+) tied to the clinic tenant.
  - Generates immediate atomic queue tokens via `counters/queue_{doctorId}_{date}` without breaking database integrity.

### 1.2 Thermal POS Token Slip Printing (`Finding #23`)
- **Original Source:** `GAMEPLAN.MD` Finding #23 & Pillar 4 Item 4
- **Affected Files:**
  - `lib/widgets/print/token_receipt_dialog.dart`
  - `lib/utils/platform_print_web.dart`
- **Problem:** Standard web printing triggers the browser's full-page preview. Token receipt slips need an isolated layout for thermal paper rolls.
- **Specification:**
  - Implement dedicated CSS print stylesheet and hidden DOM iframe for 58mm / 80mm thermal receipt slips.
  - Completely isolates token slips from the main dashboard UI.
  - Sub-second monochrome print execution at counter desk.

### 1.3 Prepaid Carry-Over & Doctor No-Show / Refund Protocol (`P11` / `RFC-2`)
- **Original Source:** `docs/PRODUCT_ROADMAP.md` §4 (`P11`) & §5 (`RFC-2`), `GAMEPLAN.MD` Finding #19
- **Problem:** Patient paid online or cash but did not attend (Patient No-Show), OR consulting physician canceled/absent due to an emergency (Doctor Absence).
- **Specification:**
  - **Doctor Absence / Session Cancellation (✅ Implemented in v1.39.0):**
    - Preserves appointment ledger records immutably (Zero Deletions invariant).
    - Status transitions to `AppointmentStatus.absent` (`VisitStatus.cancelled`) with `refundStatus: 'pending_refund' | 'refunded'`.
    - `CashHandoverEngine` preserves upfront physical cash collected until explicitly marked `'refunded'`, preventing ghost discrepancies between cash drawer and daily ledger.
  - **Patient No-Show Carry-Forward (📋 Pending):**
    - Option for reception to "Revalidate Yesterday's Paid Token", generating today's atomic token linked to yesterday's payment reference with ₹0 fresh collection.

---

## 🩺 2. Doctor Chamber & Clinical Encounter QOL

### 2.1 Patient Demographics Edit Directly from Encounter Header
- **Original Source:** `docs/PRODUCT_ROADMAP.md` line 87 ("Future TODO: allow doctor to edit patient details from this header")
- **Affected Files:**
  - `lib/widgets/encounter/patient_header_section.dart`
  - `lib/screens/consultation_encounter_screen.dart`
  - `lib/services/patient_service.dart`
- **Problem:** Reception frequently makes minor spelling errors in patient names, approximate age, or gender during walk-in rush. The doctor notices this during consultation but currently cannot fix it from inside the encounter without leaving the room.
- **Specification:**
  - Allow doctor to edit patient details (name, age, gender) directly from the encounter patient header.
  - Updates the `patients` Firestore record and active appointment without closing the encounter or losing staged medications/vitals.

### 2.2 Per-Doctor Saved Prescription Templates (Transition from Hardcoded GP Presets)
- **Original Source:** `docs/PRODUCT_ROADMAP.md` §283 (Experiment Flag Registry P9) & HK-2 Over-Engineering Review line 182
- **Affected Files:**
  - `lib/models/prescription_template.dart`
  - `lib/screens/consultation_encounter_screen.dart`
  - `lib/config/clinic_config.dart` (`enablePrescriptionTemplatePresets`)
- **Problem:** Hardcoded prescription template presets (`P9`, URI, Gastritis, Viral Fever) are generic and rigid. A specialist finds them irrelevant.
- **Specification:**
  - Build customizable per-doctor saved templates constructed directly from active clinical encounters.
  - Doctors save their own regimens to personal profiles (`doctor_templates` collection) without hardcoded static bundles.
  - Replaces hardcoded GP presets cleanly without backward-compatibility bloat.

---

## 📢 3. Waiting Hall & Display QOL

### 3.1 Fullscreen Waiting Hall Queue Display Board (`/display`) (`P15 · 🧪`)
- **Original Source:** `docs/PRODUCT_ROADMAP.md` §4 (`P15`) & §8 (Experiment Registry)
- **Problem:** Counter assistants must repeatedly shout patient names across noisy waiting rooms; patients crowd reception asking when their turn will come.
- **Specification:**
  - Fullscreen responsive route (`/display`) designed for counter-facing tablets or waiting hall Android TVs.
  - Subscribes in real-time to active doctor chamber sessions (`counters/chamber_{doctorId}_{date}`).
  - Displays currently calling tokens, room numbers, and upcoming tokens.
  - Triggers in-browser dispatch audio chimes.
  - High-contrast display visible across waiting hall distance.

---

## 📊 4. Administration, Scheduling & Financial QOL

### 4.1 Multi-Shift / Split Daily OPD Timings (`P16`)
- **Original Source:** `docs/PRODUCT_ROADMAP.md` §4 (`P16`)
- **Problem:** Some consulting physicians sit for two distinct shifts daily (e.g., Morning `10:00 AM – 1:00 PM` and Evening `6:00 PM – 8:30 PM`). Current single shift timing cannot segment daily quotas per shift.
- **Specification:**
  - Data model and counter expansion supporting multi-session shift schedules per duty day.
  - Distinct morning and evening token quotas and separate chamber calling runs without breaking atomic sequential queue invariants.

### 4.2 Doctor Extended Credentials, Accolades & Bio (`P17`)
- **Original Source:** `docs/PRODUCT_ROADMAP.md` §4 (`P17`)
- **Problem:** Some physicians have long-form qualification strings, awards, and biographical summaries (e.g., `"Gold Medalist, MD, Fellow of..."`) that need professional display without bloating counter roster labels.
- **Specification:**
  - Structured `qualifications` and `biography` fields in `Doctor` model.
  - Rendered cleanly on digital letterheads, prescription printouts, and doctor detail modals, keeping counter chips and queue cards compact.

### 4.3 Multi-Specialty Department Tagging (`P18`)
- **Original Source:** `docs/PRODUCT_ROADMAP.md` §4 (`P18`)
- **Problem:** Physicians who practice across combined or multiple sub-specialties (e.g., `"General Medicine + Diabetology"` or `"Cardiology + Electrophysiology"`).
- **Specification:**
  - Array-based or composite department tagging allowing doctors to be discovered under multiple clinical specialty filters at reception walk-in registration.

### 4.4 Shift Handover Time-Window Partitioning (`Finding #20.1`)
- **Original Source:** `GAMEPLAN.MD` Finding #20.1 & Pillar 4 Item 2
- **Affected Files:**
  - `lib/core/engines/cash_handover_engine.dart`
  - `lib/widgets/dashboard/daily_cash_handover_dialog.dart`
- **Problem:** Cash handover currently aggregates all tokens across the entire date. Multi-shift clinics with morning and evening receptionists need shift-specific drawer reconciliation.
- **Specification:**
  - Upgrade `CashHandoverEngine` to support time-window filtering (Morning shift vs. Evening shift) for end-of-day drawer handover.

---

## 🔐 5. Deferred Security & PIN Hardening (from `GAMEPLAN.MD`)

### 5.1 Hardcoded Admin Master PIN Bypass & Credential Leak (`Finding #2`)
- **Original Source:** `GAMEPLAN.MD` Deferred Roadmap Finding #2
- **Affected Files:**
  - `lib/providers/auth_provider.dart` (`lines 173-176, 228-230, 269-270`)
  - `lib/screens/login_screen.dart` (`lines 274-278`)
- **Specification:**
  - Remove hardcoded default admin PIN `849201` fallback once the owner PIN is initialized.
  - Purge credential leak helper strings (`"Testing: Reception: 0000 | Admin: 849201"`) from error UI in `login_screen.dart`.

### 5.2 Plaintext Doctor PINs & Chamber View Impersonation Bypass (`Finding #3`)
- **Original Source:** `GAMEPLAN.MD` Deferred Roadmap Finding #3
- **Affected Files:**
  - `lib/models/doctor.dart` (`line 60`)
  - `lib/screens/doctor_list_screen.dart` (`lines 53-61, 280-288`)
  - `lib/screens/doctor_chamber_screen.dart` (`lines 13, 80-104`)
- **Specification:**
  - Hash Doctor PINs before writing to the public `doctors` collection.
  - Enforce strict chamber preview lock: preview mode displays view-only telemetry and suppresses all consultation triggers and door admissions without entering the doctor's PIN.

### 5.3 Cloud-Synced PIN Store & Session Recovery UI (`Finding #4`)
- **Original Source:** `GAMEPLAN.MD` Deferred Roadmap Finding #4
- **Affected Files:**
  - `lib/providers/auth_provider.dart` (`lines 304-320`)
- **Specification:**
  - Store hashed Owner and Reception PINs in Firestore (`clinic_config/security`) rather than local browser storage only, enabling synchronized PIN changes across all clinic terminals.
  - Provide an administrative Security Settings dialog for PIN rotation with recovery passkey.

---

## 📌 6. Consolidated Backlog Inventory & Source Map

| Code | Feature Title | Original Source | Domain |
|---|---|---|---|
| **QOL-01** | Emergency / Illiterate Walk-In Dummy Key (`P13`) | `PRODUCT_ROADMAP.md` §4 | Reception Desk |
| **QOL-02** | Thermal POS Token Slip Printing (`Finding #23`) | `GAMEPLAN.MD` Finding #23 | Reception Desk |
| **QOL-03** | Prepaid Carry-Over & Refund Protocol (`P11` / `RFC-2`) | `PRODUCT_ROADMAP.md` §4 & §5 | Reception / Ledger |
| **QOL-04** | Patient Demographics Edit from Header | `PRODUCT_ROADMAP.md` line 87 | Doctor Chamber |
| **QOL-05** | Per-Doctor Saved Prescription Templates | `PRODUCT_ROADMAP.md` §8 (`P9`) | Doctor Chamber |
| **QOL-06** | Waiting Hall Display Board (`/display`) (`P15 · 🧪`) | `PRODUCT_ROADMAP.md` §4 & §8 | Waiting Hall |
| **QOL-07** | Multi-Shift / Split Daily OPD Timings (`P16`) | `PRODUCT_ROADMAP.md` §4 | Scheduling |
| **QOL-08** | Doctor Extended Credentials & Bio (`P17`) | `PRODUCT_ROADMAP.md` §4 | Roster / Print |
| **QOL-09** | Multi-Specialty Department Tagging (`P18`) | `PRODUCT_ROADMAP.md` §4 | Registration |
| **QOL-10** | Shift Handover Time-Window Partitioning (`Finding #20.1`)| `GAMEPLAN.MD` Finding #20.1 | Financial Ledger |
| **QOL-11** | Hardcoded Admin PIN Bypass Purge (`Finding #2`) | `GAMEPLAN.MD` Finding #2 | Security / Auth |
| **QOL-12** | Doctor PIN Hashing & Chamber Preview Lock (`Finding #3`)| `GAMEPLAN.MD` Finding #3 | Security / Chamber |
| **QOL-13** | Cloud-Synced PIN Store & Security UI (`Finding #4`) | `GAMEPLAN.MD` Finding #4 | Security / Auth |

---

## 💡 7. User-Proposed QOL Ideas (Under Evaluation & Architectural Review)

> ⚠️ **Note:** Kept strictly separate from the core roadmap & backlog above. These items represent upcoming product directions for review.

### 💡 IDEA-1: Full Clinic Data Export (Excel / CSV)
- **Concept:** Provide a 1-click mechanism for clinic owners/doctors to export all operational clinic data (appointments, patient registry, financial ledger, consultations, master medicine list) as `.csv` or `.xlsx` files.
- **Architectural Feasibility:**
  - **Firebase Support:** Firestore does not have a native "export to CSV" button in the client SDK, but exporting client-side in Flutter is straightforward:
    - We can fetch collection snapshots (`appointments`, `patients`, `medicines`) and serialize records into standard RFC 4180 CSV format using pure Dart.
    - Web downloads trigger via standard browser blob (`dart:js_interop` / HTML anchor download) with zero server latency and zero external tools.
  - **Data Privacy & Compliance:** Running exports purely client-side ensures zero patient health information (PHI) passes through third-party servers, conforming strictly with `COMPLIANCE_AND_PRIVACY.md`.
  - **Use Cases:** End-of-month accountant audits, external tax filing, local backup peace of mind.

### 💡 IDEA-2: Prescribe-to-Formulary Auto-Ingest (Auto-Save Unlisted Medicines)
- **Concept:** When a doctor searches for a drug not currently in the database, types in custom details, and prescribes it, the system automatically (or via a 1-tap toggle) adds this new medicine to the clinic's official master catalogue (`medicines` collection).
- **Architectural Feasibility:**
  - **Current State:** `RxSearchResultsView` currently offers `"Prescribe unlisted outside brand: [Query]"`, but it only stages the item for that single consultation. Next time the doctor searches for it, it remains unlisted.
  - **Proposed Workflow:** When staging or completing an unlisted medicine, present a subtle checkbox: `[☑ Add to Clinic Formulary for future auto-complete]`.
  - **Ingest Hygiene Guard:** Require minimum metadata (Product Name + Formulation form, e.g. `Tab.` or `Syp.`) before saving to `/medicines` to prevent catalogue pollution from accidental typos or incomplete drug records.
  - **Longitudinal Safety:** 100% safe. Existing encounters use immutable snapshots (`PrescriptionItem`), so catalogue additions never mutate historical records.

### 💡 IDEA-3: In-Built Master Medicine Editor
- **Concept:** An in-app GUI editor for catalogue medicines directly within the app (e.g. inside `MedicineCatalogueScreen`), eliminating the need to open the Firebase Console or delete and recreate entries to fix typos, dosage forms, or chemical compositions.
- **Architectural Feasibility:**
  - **Effort vs Horizon:** While considered a "3.0 feature", the underlying infrastructure already exists:
    - `AddMedicineDialog` already has the full validation UI, text controllers, form pickers, and dosage timing chips.
    - Adding an `onEdit` callback in `CatalogueMedicineCard` that opens `AddMedicineDialog(medicineToEdit: item)` and calls `CatalogueService.updateMedicine(item.id, data)` is a lightweight and clean enhancement.
  - **Role Guarding:** Restricted strictly to clinic administrators / owner PIN session to prevent accidental formulary overwrites.
  - **Longitudinal Integrity:** Fully compliant with Invariant #2 & Invariant #10. Modifying a brand name or composition in `/medicines` only impacts future auto-completes; historical consultations retain frozen snapshots and are never mutated.

### 💡 IDEA-4: Anonymized Prescription Volume & Trend Telemetry (Regional Healthcare Intelligence)
- **Concept:** A separate, decoupled external analytics sink that collects pure aggregate counts of how many times a medicine (brand/composition) is prescribed across dates and pin codes/regions, completely stripped of doctor, clinic, and patient identity.
- **Market & Business Value:**
  - Highly valuable for pharmaceutical market research, supply-chain forecasting, and regional drug distributors/stockists (similar to IQVIA / AWACS models in India).
  - Can track real-time seasonal disease spikes (e.g., Dengue fluid/paracetamol surges in monsoon, Azithromycin/cough syrup spikes in winter) weeks before retail pharmacy purchase orders register them.
- **Regulatory, DPDP & Ethical Guardrails:**
  - **Zero Patient Health Information (PHI):** Must contain 0 patient identifiers (no names, phones, ages, sexes).
  - **Zero Doctor Attribution:** National Medical Commission (NMC) regulations strictly prohibit tracking or selling individual physician prescribing patterns to pharma companies. Telemetry must strictly strip `doctorId`, `doctorName`, `clinicId`, and `registrationNumber`.
  - **Differential Privacy / Non-Personal Data (NPD):** Payload must be an anonymous, fire-and-forget event: `{ region: "Guwahati_East", date: "DD-MM-YYYY", composition: "TELMISARTAN 40MG", brand: "Telma 40", form: "Tablet" }`.
- **Architectural Separation:**
  - Kept completely off the clinic's transactional Firestore database.
  - Asynchronous background HTTP webhook ping to an independent analytics ingestion pipeline.
  - Doctor chamber experience must have 0ms latency impact (fire-and-forget).

