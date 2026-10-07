# 🗺️ GuwahatiOne Clinic OS — Master Product Roadmap & Lifecycle Matrix

> **Maintained by:** Senior Clinical Systems Architect & Product Manager  
> **Audience:** All AI Agents, Coding Assistants, and Engineering Staff  
> **Companion Blueprint:** [PRODUCT_VISION_AND_WORKFLOW.md](file:///k:/Android/appointment_app/docs/PRODUCT_VISION_AND_WORKFLOW.md)

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
| **Master Medicine Catalogue** | Chemical composition search scorer, OPD essential formulary, owner-only deduplication engine. | 🟢 Verified & Live |
| **Prescription Printing** | Monochrome clean layout, A4 & A5 support, pre-printed clinic letterhead margin toggle, browser print via `dart:js_interop`. | 🟢 Verified & Live |
| **Role-Based Security** | Reception PIN (`0000`) vs Doctor Chamber 4-digit PIN authentication. | 🟢 Verified & Live |
| **Doctor Chamber Queue** | Real-time consultant token stream, doctor fee summary, patient history review. | 🟢 Verified & Live |

---

## 🎯 3. Active Priority Backlog (Chamber Speed & Friction-Free OPD)

These items address direct clinical friction in the doctor's 3-minute consultation workflow:

| Priority | Feature / Module | Problem Solved | Acceptance Criteria |
|---|---|---|---|
| **P1** | **Zero-Touch Chamber Auto-Sync** | Doctor currently has to manually find and click "Consult". In high-volume OPD, the doctor's screen must follow reception automatically. | When reception clicks "Call / Start" on a token, the doctor's chamber screen automatically transitions to the active encounter and preloads the patient's record without touching the mouse. |
| **P2** | **Smart Medicine Dosage & Duration Defaults** | Typing dosage (1-0-0) and duration (30 days) for routine drugs adds 10+ unnecessary keystrokes per prescription. | Selecting a catalogue medicine (e.g., *Telma 40*) auto-populates standard clinical defaults (e.g., 1 tablet OD morning after food, 30 days/continue). Doctor only edits if deviating. |
| **P3** | **Collapsible Sectional Encounter Ergonomics** | Current encounter screen is a long scrolling page that overwhelms rapid entry. | Structure encounter into 3 distinct collapsible blocks: "Add Findings" $\rightarrow$ "Close Findings" (summary badge), "Add Medicine" $\rightarrow$ "Close Medicine", and "Diagnostic Tests". |
| **P4** | **Doctor Search Preference Toggle (Brand vs Salt)** | Different physicians prefer searching by commercial trade brands vs pharmacological chemical compositions. | Stored doctor setting (`brandFirst` vs `compositionFirst`). Search bar ranks results according to doctor's preference while keeping results comprehensive. |

---

## 📦 4. Secondary Backlog (Operational Utilities)

| Priority | Feature | Description | Acceptance Criteria |
|---|---|---|---|
| **P5** | **Doctor Signature & Reg Stamp on Printout** | Configurable digital signature and medical council registration number. | Clean toggle in doctor profile; renders optionally on prescription footer. |
| **P6** | **Offline Queue Fallback Cache** | Counter resilience against transient internet drops. | Reads from local storage cache if Firestore connection drops momentarily. |
| **P7** | **WhatsApp Prescription Deep Link** | Send prescription link/summary to patient's WhatsApp without heavy SMS gateways. | 1-tap `wa.me` launcher button at reception counter. |
| **P8** | **Daily End-of-Day Financial Summary** | Daily counter reconciliation sheet for receptionist handover. | Grouped summary of collected fees by doctor and payment type (Paid, Free Review, Family). |

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
