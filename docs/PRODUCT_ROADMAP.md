# 🗺️ GuwahatiOne Clinic OS — Master Product Roadmap & Lifecycle Matrix

> **Maintained by:** Senior Clinical Systems Architect & Product Manager  
> **Audience:** All AI Agents, Coding Assistants, and Engineering Staff  
> **Companion Blueprint:** [PRODUCT_VISION_AND_WORKFLOW.md](PRODUCT_VISION_AND_WORKFLOW.md)

---

## 🚫 1. Anti-Goals (Strict Architectural Guardrails)

Any code, dependency, or feature proposal that introduces these is **instantly rejected**:

1. ❌ **No Pharmacy Inventory ERP:** Never track batch numbers, expiration dates, distributor invoices, purchase orders, or stock shelf counts.
2. ❌ **No Retail Point of Sale (POS):** Never add retail billing for bandages, OTC toiletries, or non-consultation goods.
3. ❌ **No Complex Accounting / Tally Ledger:** The ledger exists strictly for daily counter token audits and doctor fee reconciliation.
4. ❌ **No Inpatient (IPD) / Bed Management:** Designed strictly for outpatient (OPD) clinics and consulting chambers.
5. ❌ **No Destructive Clinical Edits:** Past consultations are append-only. Never overwrite prior medical records.

---

## 🟢 2. Active & Verified Capabilities

| Module | Core Features | Verification Status |
|---|---|---|
| **Audit-Proof Queue Ledger** | Atomic consecutive daily tokens ($1 \dots N$). No deletions from Firestore; cancellations/no-shows preserved as `AppointmentStatus.absent` with `₹0`. | 🟢 Verified & Live |
| **Patient Registration** | 10-digit phone lookup, age/gender, allergy alerts, 14-day free review eligibility auto-calculation. | 🟢 Verified & Live |
| **Longitudinal Prescribing** | 5-step encounter pipeline, medication reconciliation (`START`, `CONTINUE`, `STOP`), unlisted outside medicine fallback. | 🟢 Verified & Live |
| **Zero-Touch Chamber Auto-Sync (`P1`)** | Real-time sync at `counters/chamber_{doctorId}_{date}`. Reception clicks "Call In" ➔ Doctor screen automatically opens encounter with zero mouse clicks. Includes consultation collision safety banner. | 🟢 Shipped & Verified (`v1.5.0`) |
| **Smart Clinical Defaults (`P2`)** | `ClinicalDefaultsHelper` auto-populates standard OPD regimens (PPIs, Antihypertensives, Diabetes, Statins, Antibiotics, Liquids, Topicals). Zero typing for 90% of prescriptions. | 🟢 Shipped & Verified (`v1.5.0`) |
| **Collapsible Encounter Ergonomics (`P3`)** | Step 2 Findings and Step 4 Prescribing collapsible into compact summary badge strips. Eliminates vertical scroll fatigue on counter PCs. | 🟢 Shipped & Verified (`v1.5.0`) |
| **Doctor Prescribing Search Preferences (`P4`)** | Per-doctor `searchPreference` (`brandFirst` vs `compositionFirst`) with dual-mode `MedicineSearchScorer` and quick-toggle `[🏷️ Brand | 🧪 Salt]` pill on search bar. | 🟢 Shipped & Verified (`v1.5.0`) |
| **Modular Encounter Architecture & State Encapsulation** | Deconstructed ~2,600-line monolithic encounter into reusable atomic step widgets (`lib/widgets/encounter/`), centralized `EncounterFormState`, and lightweight (<300 line) coordinator scaffold. | 🟢 Shipped & Verified (`v1.6.0`) |
| **Comprehensive Frontend Modularization** | Modularized Dashboard, Chamber, Prescribing/Encounter, Prescription Print, Add Appointment, and Reception Queue into clean sub-packages under `lib/widgets/` with centralized barrel export. | 🟢 Shipped & Verified (`v1.7.0`) |
| **Master Medicine Catalogue** | Chemical composition search scorer, OPD essential formulary, owner-only deduplication engine. | 🟢 Verified & Live |
| **Prescription Printing** | Monochrome clean layout, A4 & A5 support, pre-printed clinic letterhead margin toggle, browser print via `dart:js_interop`. | 🟢 Verified & Live |
| **Role-Based Security** | Reception PIN (`0000`) vs Doctor Chamber 4-digit PIN authentication. | 🟢 Verified & Live |
| **Doctor Chamber Queue** | Real-time consultant token stream, doctor fee summary, patient history review. | 🟢 Verified & Live |

---

## 🎯 3. Active Priority Backlog (Next Horizon)

The primary clinical friction points (P1–P4) have been shipped in **v1.5.0**. The active roadmap now advances to secondary operational utilities:

| Priority | Feature / Module | Problem Solved | Acceptance Criteria |
|---|---|---|---|
| **P5** | **Doctor Signature & Reg Stamp on Printout** | Currently printed prescriptions require manual pen signing and stamping. | Configurable digital signature and medical council registration number in doctor profile; renders cleanly on prescription print footer with toggle. |
| **P6** | **Offline Queue Fallback Cache** | Counter PCs may experience momentary internet hiccups. | Local cache of daily appointments using browser storage / SQLite fallback to prevent counter freezes during transient dropouts. |
| **P7** | **WhatsApp Prescription Deep Link** | Patients frequently request a digital copy on WhatsApp without clinic needing expensive SMS gateways. | 1-tap `wa.me/91...?text=...` deep link at reception counter allowing direct send via Web WhatsApp. |
| **P8** | **Daily End-of-Day Financial Handover** | Reception shift handover requires manual cash counting. | Single-click end-of-day reconciliation view aggregating collected fees by doctor and payment type (Paid, Free Review, Family Courtesy). |

---

## 🗑️ 5. Scrapped & Superseded Items (Strict "Do Not Re-Implement" Log)

To prevent AI assistants from regressing or re-introducing discarded patterns:

| Discarded Feature / Pattern | Initial State / Idea | Why It Was Scrapped | Prevention Guardrail for AI |
|---|---|---|---|
| **Pharmacy Inventory & Batch Tracking** | Prototype had fields for batch numbers, expiry dates, supplier invoices, and stock counts. | Creates administrative overload. Transforms a fast clinical OPD tool into an expensive retail ERP. | **Never re-add** batch, expiry, or stock ledger collections to Firestore or models. |
| **Retail Counter POS Billing** | Selling cotton, band-aids, OTC products at reception. | Distracts counter assistant from token flow and queue management. | Keep billing restricted strictly to doctor consultation tokens. |
| **Modal Prescribing Dialogs** | Prescribing was opened in fullscreen popups. | Interrupted clinical view and added 4+ clicks per drug. | Keep medication search and prefilled defaults **inline** within the encounter body. |
| **Destructive Prescription Overwrite** | Modifying previous visit's consultation document on return visit. | Destroys medical-legal audit history. Violates longitudinal record integrity. | Consultations must remain strictly **append-only**. Follow-ups use `MedicationAction.continueAction` or `stopAction`. |
| **Queue Item Deletion** | Deleting canceled or duplicate appointments from Firestore. | Enables financial leakage and cheating between counter and doctors. | Deletions are forbidden. Mark as `AppointmentStatus.absent` with `amountCollected: 0`. |

---

## 📋 6. Operational Governance for AI Agents
1. Before implementing any feature, check this matrix to ensure the task aligns with Section 3 or Section 4.
2. If an AI receives a prompt that matches an item in Section 1 or Section 5, it must **flag the conflict immediately** and adhere to the architectural guardrails.
3. Only the **Product Manager** can promote items from Proposed to Active Backlog.
