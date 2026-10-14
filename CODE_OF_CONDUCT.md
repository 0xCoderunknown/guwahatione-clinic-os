# 🛡️ GuwahatiOne Clinic OS — Clinical Engineering & AI Code of Operational Conduct

> **Mandatory Operational Ethics & Invariants for AI Coding Assistants & Human Operators.**  
> GuwahatiOne Clinic OS is outpatient clinical software directly handling patient care, medical records, and clinic finances.  
> The project is **100% AI-coded and maintained**, directed by the **Human Product Manager & Tester**.

---

## 🏛️ Core Operational Tenets

### 1. Inviolability of Clinical Records (Zero Tampering)
- **Zero Deletions:** Never delete an appointment or token document from Firestore. Cancelled or no-show patients are marked `AppointmentStatus.absent` with `amountCollected: 0`.
- **Append-Only Consultations:** Past clinical encounters are immutable legal medical records. Never overwrite, edit, or delete past consultation records on follow-up visits.
- **Medication Reconciliation Integrity:** Every changed medication must have an explicit state (`START`, `CONTINUE`, or `STOP` with a verified clinical `stopReason`).

### 2. Financial & Ledger Transparency (Zero Cheating)
- **Audit-Proof Accounting:** Every rupee collected must reconcile against the clinic counter register and daily cash drawer handover.
- **Strict Atomic Queue Tokens:** Token numbers ($1 \dots N$) must be strictly consecutive and atomically allocated via daily Firestore transaction counters (`counters/queue_{doctorId}_{yyyy-MM-dd}`).
- **Zero Arbitrary Waivers:** Courtesy waivers (`PaymentType.freeFamily`) and doctor-configured free reviews (`0`–`30` days, strict 1:1 cycle) must follow engine rules and never bypass audit logging.

### 3. Physician Chamber Sovereignty
- **Doctor-Paced Handshake:** Never force patient admission into a chamber during an active consultation or doctor breather (`consultation_ended`) without an explicit `ready_for_next` signal.
- **Single-Occupant Chamber Integrity:** A doctor's chamber holds exactly zero or one active patient at any time. An active patient ($T_N$) can never be pre-empted or superseded by another token ($T_{N+1}$).
- **Collision Locks:** Consultation encounter workspaces must lock re-entrant navigation to prevent duplicate modals from stacking.

### 4. Patient Privacy & Healthcare Compliance
- **DPDP Act & NMC Regulations:** Comply with statutory 3-year record retention and role-based access control (RBAC). Non-clinical counter staff must never access physician examination notes or clinical diagnoses.
- **Mandatory Indian Date Format:** All user-facing dates across UI, printed prescriptions, reports, changelogs, and markdown files must strictly format as `DD-MM-YYYY`.

### 5. Engineering Rigor & Verification Gates
- **Zero Warnings Gate:** Every commit and change must compile with 100% clean static analysis (`flutter analyze` — 0 issues).
- **Automated Test Fortification:** All unit and widget tests must pass cleanly (`flutter test`).
- **Zero Backward-Compatibility Debt (Invariant #10):** Clean, modern domain code is strictly required. Never introduce legacy shims, deprecated aliases, or polyfills.
