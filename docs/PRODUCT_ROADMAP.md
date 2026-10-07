# 🗺️ GuwahatiOne Clinic OS — Product Roadmap & Boundaries

> **Maintained by:** The Product Manager  
> **Audience:** AI Coding Assistants & Engineering

---

## 🚫 Anti-Goals (Strictly Out of Scope)

To keep Clinic OS focused, fast, and lightweight, these features are explicitly **prohibited**:

1. ❌ **No Pharmacy Inventory ERP:** No tracking batch numbers, expiry dates, purchase orders, wholesaler invoices, or stock counts.
2. ❌ **No Retail Point of Sale (POS):** Clinic OS does not sell OTC bandages or retail goods.
3. ❌ **No Complex Accounting / Tally Ledger:** The ledger exists strictly for daily token audit between counter and doctor.
4. ❌ **No Inpatient / Bed Management:** Designed exclusively for outpatient (OPD) clinics and consulting chambers.

---

## ✅ Completed & Live Capabilities

| Module | Features Completed | Status |
|---|---|---|
| **Queue & Token Engine** | Consecutive atomic token numbering ($1 \dots N$), audit-proof zero deletion ledger, Absent/No-show preservation (`₹0`). | 🟢 Complete |
| **Patient Registration** | 10-digit phone lookup, age/gender, allergy alerts, 14-day doctor review eligibility auto-detection. | 🟢 Complete |
| **Chamber Prescription Engine** | 5-step clinical encounter sequence, medication reconciliation (`START`, `CONTINUE`, `STOP`), unlisted outside drug fallback. | 🟢 Complete |
| **Medicine Formulary** | Composition-first search scoring, default OPD essential catalogue, batch deduplication engine. | 🟢 Complete |
| **Prescription Printing** | Monochrome clean layout, A4 & A5 support, pre-printed clinic letterhead margin toggle, browser print via `dart:js_interop`. | 🟢 Complete |
| **Security & Access** | Reception PIN (`0000`) vs Doctor Chamber 4-digit PIN authentication. | 🟢 Complete |
| **Doctor Chamber Board** | Real-time consultant live queue, fee earnings summary, 1-tap patient history review. | 🟢 Complete |

---

## 🎯 Current Priority Backlog

| Priority | Feature / Improvement | Description | Acceptance Criteria |
|---|---|---|---|
| **P1** | **Print Template Doctor Signature Block** | Add configurable doctor digital signature / registration number stamp toggle on prescription printout. | Clean toggle in doctor profile; optional rendering on print. |
| **P2** | **Offline Queue Fallback Cache** | Cache today's appointments in local storage so reception can view queue if internet drops momentarily. | Read from `SharedPreferences` cache if Firestore stream disconnects. |
| **P3** | **WhatsApp Prescription Share (Deep Link)** | Allow reception or doctor to trigger a `wa.me` message with appointment slip or prescription summary link. | 1-tap button using `url_launcher` without heavy SMS gateways. |
| **P4** | **Daily End-of-Day Financial Report Export** | 1-tap CSV or PDF summary of daily doctor payouts and counter collections. | Clean printable/downloadable summary grouped by doctor. |

---

## 📌 Rules for Modifying This Roadmap
- Only the **Product Manager** may add new items or re-prioritize this list.
- An AI Agent must not self-assign backlog items without direct prompt instructions from the PM.
