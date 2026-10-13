# 🏥 GuwahatiOne Clinic OS — Product Vision & Clinical Encounter Blueprint

> **Source:** Direct product intent shared by the Product Manager (PM)  
> **Formulated by:** Senior Clinical Systems Architect & Engineer (Antigravity AI)  
> **Target Audience:** Clinicians, Product Managers, Engineers, and Clinical Operations Staff

---

## 🧭 1. Executive Summary & Core Philosophy

### The Real-World Problem in Indian Healthcare
In India, the vast majority of outpatient (OPD) prescriptions are handwritten on paper pads:
- **Illegible Handwriting:** Prescriptions are frequently decipherable only by the clinic's attached chemist, creating medical errors, patient anxiety, and pharmacy lock-in.
- **Missing Chemical Compositions:** Prescriptions often mention only commercial trade brands (e.g., *Telma 40*, *Augmentin 625*) without indicating the generic salt composition or strength.
- **The Software Trap for Small Clinics:** When independent physicians or small single-doctor clinics look for digital solutions, they face bloated enterprise "hospital packages" that cost thousands of rupees and force them into inventory lot tracking, wholesale purchase orders, retail billing, and insurance claims.

### The Clinic OS Mandate: "1 Simple Thing"
GuwahatiOne Clinic OS is built to focus on one primary role:
> **A doctor's clinical consultation record, longitudinal patient encounter history, and clean monochrome printed prescription generator. No inventory tracking. No retail invoicing.**

---

## 👥 2. User Roles & Daily Operational Setup

| Role | Environment | Authentication | Key Responsibilities |
|---|---|---|---|
| **Clinic Owner / Admin** | Counter PC / Management Display | 6-Digit Master PIN (`849201`) | Full administrative authority: Doctor CRUD, schedule and consultation fee adjustments, catalogue curation, and financial revenue audits. |
| **Receptionist / Assistant** | Counter PC / Tablet | 4-Digit Counter PIN (`0000`) | Rapid walk-in registration (keyboard-first), atomic daily token allocation, physical arrival verification, chamber calling, and ledger recording. |
| **Consulting Physician** | Chamber Laptop / Monitor | 4-Digit Doctor PIN (Chamber) | Focused patient consultation, rapid vitals/findings recording, medication reconciliation & prescribing, diagnostic orders, and review pacing. |
| **Patient** | Chamber & Waiting Room | None | Receives an atomic token, receives an approximate consultation window, walks away with a clear, legible A4/A5 printed prescription. |

---

## ⚡ 3. Scenario 1: New Patient OPD Encounter Walkthrough

```
[ Reception Desk — Booking & Check-In ]
   1. Patient books appointment (Phone/Advance Booking or Walk-in at counter).
   2. Reception opens New Appointment modal (100% keyboard-navigable via Tab, M/F/O hotkeys, Enter).
   3. Types phone number (10 digits). On new patient, advances to Name; on existing patient, auto-fills and jumps to Doctor.
   4. Selects Doctor: System immediately computes and displays provisional live token & consultation time window:
      "🎟️ Next Token: #04 • Est. Time: ~08:00 PM – 08:20 PM"
   5. Duplicate booking guard: Prevents same-day accidental double bookings while permitting family members under shared phone.
   6. Advance / Phone bookings are saved with `VisitStatus.booked` (holding token slot without cluttering the active lobby queue).
   7. When patient physically arrives at the clinic desk:
      - Reception performs 1-tap Check-In (`QuickCheckInDialog`) with payment reconciliation (`paidCash`, `paidUpi`, `postPay`, `freeReview`, `freeFamily`).
      - Patient status updates to `VisitStatus.waitingInLobby`.
   8. When doctor is ready (`ready_for_next`), Reception clicks "SEND IN" in the Live Queue.
          │
          ▼ (Real-time sync to Chamber; fallback: Doctor Restricted Emergency Runway "Next at Door")
[ Doctor Chamber Screen ]
   9. Doctor's screen displays clean Header with Patient Demographics & Allergy Alert.
   10. Body is blank and organized into 3 fast, sequential sections:
```

### Canonical 5-Step Clinical Encounter Pipeline:

> ⚠️ **Note (Updated):** The original 3-section prototype description ("Section A: Findings", "Section B: Medications", "Section C: Tests") was superseded when the encounter was promoted to the formal 5-step pipeline in `v1.6.0`. The canonical encounter structure is defined in **AGENTS.md Invariant #3** and implemented in `lib/screens/consultation_encounter_screen.dart`.

- **Step 1 — Patient Header & Allergies Alert Banner:** Displays patient demographics, longitudinal history button, and critical allergy alert chips.
- **Step 2 — Vitals & Clinical Examination:** Rapid inline entry of BP, RBS, Pulse, Weight, Temperature, SpO₂, Chief Complaints, and Provisional Diagnosis. Collapsible into a compact summary badge strip after entry.
- **Step 3 — Diagnostic Investigations Review:** Review of past lab reports brought by the patient with recorded values and dates.
- **Step 4 — Medication Reconciliation & Prescribing:** Inline search-and-add with `START` / `CONTINUE` / `STOP` reconciliation states and pre-filled clinical defaults. Collapsible into a compact prescription summary strip.
- **Step 5 — Diagnostic Orders & Follow-Up Advice:** New test orders, lifestyle/diet advice, and recommended follow-up interval.

### Completion & Output:
- 1-click **"Complete & Print"** outputs a standardized, high-contrast monochrome prescription (A4 or A5) designed to fit clinic letterheads without wasting ink or paper.


---

## 🔁 4. Scenario 2: Return Patient & 14-Day Free Review

```
[ Reception Desk ]
   1. Patient returns 7 days later with fresh blood test reports.
   2. System auto-detects that the patient visited Dr. Bhaskar within the 14-day free review window.
   3. Reception issues a Token marked "FREE REVIEW (₹0)" and clicks "Call In".
          │
          ▼ (Zero-touch real-time chamber update)
[ Doctor Chamber Screen — Zero Clicks Required ]
   4. Doctor DOES NOT touch the mouse or search for the patient.
   5. Chamber screen automatically updates to the returning patient's profile.
   6. Pre-loads the PAST PRESCRIPTION as the active baseline!
```

### The Longitudinal Reconciliation Experience:
- **Prescription as an Active Baseline:**
  - Instead of forcing the doctor to re-type existing medications from scratch, all active chronic medications (e.g., *Telma 40mg*) automatically load in the **Medication Reconciliation** section.
  - Default status is **`CONTINUE`**.
- **Effortless Review:**
  - If the patient's blood pressure is well-controlled and the lab report looks good, the doctor **does not need to touch the medication at all**.
  - If a change is needed:
    - **Dose adjustment:** Edit strength/timing in place.
    - **Discontinuation:** 1-click toggle to **`STOP`** with a standard clinical reason (e.g., *Goal achieved*, *Adverse effect*, *Switched to alternative*).
- **Append-Only History:**
  - The previous consultation record remains permanent and immutable in Firestore.
  - The new encounter is saved as a distinct, linked follow-up event in the patient's longitudinal record.

---

## ⚙️ 5. Doctor Preference: Brand vs. Chemical Composition

OPD physicians in India have distinct prescribing habits based on training and specialty:

| Prescribing Style | Doctor Preference | System Behavior |
|---|---|---|
| **Trade Brand Centric** | Prescribes specific trusted commercial brand names (*Telma 40*, *Dolo 650*, *Pan 40*). | Autocomplete highlights trade brand first, displaying generic composition in a muted subtitle. |
| **Generic / Composition Centric** | Thinks pharmacologically in active chemical salts (*Telmisartan 40mg*, *Paracetamol 650mg*, *Pantoprazole 40mg*). | Autocomplete highlights salt composition and provides one-tap chips for associated brand formulations. |
| **Personal Formulary Centric** | Routinely prescribes a curated subset of 15–30 medicines. | Quick-access favorite chips appear above the search bar for zero-typing selection. |

> **Architecture Principle:** The system supports a per-doctor configuration field (`searchPreference: 'brandFirst' | 'compositionFirst'`) keeping the global catalogue normalized. A `favoritesFirst` mode is under consideration as a future backlog item (**P9**+) and must be formally specced in `docs/SCHEMA_AND_MODELS.md` before implementation.

---

## 🧠 6. AI's POV: Senior Clinical Systems Architect Commentary

*Observations, ergonomics, and architectural foundations added to bridge product intent with technical execution:*

### 1. The Ergonomics of the 3-Minute OPD Consultation
In a busy Indian clinic where a physician sees 30 to 60 patients in a single evening session, **every mouse click and modal dialog is friction**.
- If adding a medication requires opening a popup, clicking three dropdowns, typing dates, and closing a dialog, the doctor will abandon the software within two days and revert to a paper pad.
- The **Inline Sectional Flow** ("Add Findings" -> "Add Medicine" with smart prefilled defaults) keeps hands on the keyboard and reduces prescribing time to under 15 seconds per drug.

### 2. The Architectural Reality of "Zero-Touch" Chamber Sync
To fulfill the PM vision where *"the doctor didn't have to touch even the mouse"*, the app cannot rely solely on the doctor manually picking names from a list.
- **Implementation Strategy:**
  - Introduce an `activeCallingToken` field on the doctor's daily chamber record (`counters/daily_chamber_{doctorId}_{date}`).
  - When the receptionist clicks `"Call Token #X"`, Firestore pushes this change down an active snapshot listener on the doctor's chamber screen.
  - The Doctor Chamber screen detects the active patient transition and automatically navigates or renders the encounter screen for that patient.

### 3. Medication Reconciliation: Why START / CONTINUE / STOP is Essential
Handwritten prescriptions fail because when a patient brings 4 old slips, no one knows which drugs are current and which were stopped.
- By treating medications as longitudinal states (**`START`** for new therapies, **`CONTINUE`** for ongoing chronic regimens, **`STOP`** for discontinued drugs), Clinic OS creates a true clinical timeline.
- A printed follow-up prescription clearly communicates to the patient and family: *"Continue Telma 40, Stop Amlodipine"*, reducing medication reconciliation errors at home.

### 4. Zero Deletions as a Safeguard
Preserving cancelled/absent tokens (`AppointmentStatus.absent` with `₹0`) and treating consultations as append-only records ensures:
- Receptionists cannot secretly delete cash visits.
- Doctors have complete audit clarity regarding daily patient volume and fees.
- Historical consultations are never overwritten or lost during a follow-up visit.

---

## 📋 7. Product Boundaries & Anti-Scope Checklist

To keep the system focused on outpatient clinical workflows:
- ❌ **No Pharmacy Inventory Management:** No tracking batches, expirations, stock shelves, or wholesale distributors.
- ❌ **No Retail Point of Sale (POS):** No billing for OTC band-aids, cotton rolls, or retail syringes.
- ❌ **No Insurance / TPA Billing Engine:** No complex claim adjudication or hospital package codes.
- ❌ **No Inpatient Bed Management:** Dedicated strictly to consulting rooms and outpatient clinics.

---

## 🚀 8. Summary & Next Steps

This document serves as the **master product and user experience blueprint** for GuwahatiOne Clinic OS. All upcoming UI refinements, state handlers, and keyboard navigation shortcuts should be measured against this standard: **fast, focused, legible, and built for the real-world Indian OPD chamber.**
