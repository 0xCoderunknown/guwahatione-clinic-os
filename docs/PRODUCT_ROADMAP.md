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

## 🟢 2. Active Domain Capability Matrix

The following capabilities are fully implemented, verified, and operational in production:

| Domain Module | Core Capabilities | Operational & Invariant Guarantee |
|---|---|---|
| **Audit-Proof Queue & Registration Desk** | • Atomic consecutive daily tokens ($1 \dots N$ via `counters/queue_{doctorId}_{date}`).<br>• Keyboard-first walk-in booking (`F2` shortcut, Tab-order chaining, dedicated `M`/`F`/`O` sex toggles).<br>• Same-day duplicate booking guard `(Date + DoctorId + Name + Phone)` with family exception.<br>• 2-stage asynchronous OPD flow (`booked` $\to$ `QuickCheckInDialog` desk check-in $\to$ `waitingInLobby`).<br>• Offline queue fallback cache (`SharedPreferences`) during broadband hiccups. | **Zero Deletions Invariant:** Canceled or no-show tokens are permanently preserved as `AppointmentStatus.absent` with `₹0`. Zero token pre-emption or silent sequence deletion. |
| **Doctor Chamber & Queue Handshake** | • 5-state synchronized handshake (`idle` $\to$ `ready_for_next` $\to$ `calling` $\to$ `in_consultation` $\to$ `consultation_ended`).<br>• Atomic single-occupancy chamber lock preventing concurrent admissions or token pre-emption.<br>• Discretionary reception dispatch with late/bypassed tagging (`[BYPASSED / LATE]`) and completed visits accordion.<br>• Restricted emergency door override strictly limited to top 1–2 physically present, paid lobby patients.<br>• Historical date read-only archive mode (`ChamberArchiveBanner`) with consolidated no-show state. | **Doctor-Paced Pacing:** Reception cannot force patient admission during consultations or doctor breathers without explicit `ready_for_next` signal. Historical dates are immutable. |
| **Clinical Encounter & Prescribing** | • Append-only consultations collection preserving medical-legal longitudinal integrity.<br>• 3-state medication reconciliation (`START`, `CONTINUE`, `STOP` with stop reason).<br>• Master medicine catalogue with dual-mode brand/salt search scorer (`[🏷️ Brand \| 🧪 Salt]`) honoring doctor preferences.<br>• Pharmacological clinical defaults pre-filling dosage, frequency, and duration across OPD regimens.<br>• Prescription template presets with salt and brand deduplication (🧪 Experiment). | **Longitudinal Integrity:** Previous visits are never modified. Follow-ups record explicit reconciliation states. |
| **3-Tier Security & Financial Ledger** | • Role-guarded access: Owner (6-digit Master PIN), Doctor (4-digit PIN), Receptionist (`0000`).<br>• Owner-exclusive settings: Doctor CRUD, fee scheduling, free review window configuration, and ledger audits.<br>• Doctor-configurable free review window (0–30 days) with strict 1:1 paid-to-review cycle enforcement.<br>• Daily cash handover reconciliation modal with Indian note denomination counter. | **Role Isolation:** Reception and chamber sessions cannot modify fee schedules or doctor profiles. Zero unearned review chaining. |
| **Communications, Print & Sound** | • High-contrast monochrome A4 & A5 prescription printing with adjustable letterhead margins and medical registration number footer.<br>• Formatted WhatsApp clinical summary deep-links (`wa.me`) with Indian date standard (`DD-MM-YYYY`).<br>• Web Audio API dual-tone chime and SpeechSynthesis multi-chamber token announcer with AppBar mute toggle (🧪 Experiment). | **Monochrome & Privacy:** Zero ink/paper waste on pre-printed stationery. No patient data logged to public endpoints. |
| **Pure Domain Engines & Test Suite** | • Pure Dart domain engines decoupled from UI ([RevenueEngine](../lib/core/engines/revenue_engine.dart), [AppointmentEngine](../lib/core/engines/appointment_engine.dart), [MedicineEngine](../lib/core/engines/medicine_engine.dart), [WhatsAppEngine](../lib/core/engines/whatsapp_engine.dart), [CashHandoverEngine](../lib/core/engines/cash_handover_engine.dart)).<br>• Comprehensive automated unit and widget test suite (209 passing tests). | **Zero Business Logic in UI:** Financial math, review eligibility, and pharmacological rules reside strictly in pure engines. |

> 💡 *For granular version-by-version release history, PR commits, and detailed operational impact notes, see [CHANGELOG.md](../CHANGELOG.md) and [CHANGELOG_ARCHIVE.md](archive/CHANGELOG_ARCHIVE.md).*


---

## 🔧 3. Active Housekeeping Goals (Near-Term, Non-Negotiable)

These are **active goals**, not future backlog. They correct design decisions that were AI-proposed and shipped but proved to add friction in real-world clinical use. They are not optional enhancements — they represent what the product *should have been*.

---

### 🏥 HK-1: Encounter Screen Redesign — Replace the 5-Step Pipeline

> **Status:** Approved for implementation. Supersedes `AGENTS.md §1 Rule #3`.

The current 5-step linear encounter pipeline (`ConsultationEncounterScreen`) was AI-proposed and AI-implemented. In real clinical use it creates unnecessary friction. Every visit forces the doctor through Steps 1–5 regardless of context. This is being replaced with a **free-form, section-based encounter layout**.

#### New Layout Specification

The encounter screen renders as a single scrollable document. Sections are independent and collapsible. Doctor can interact with them in **any order** — no mandatory sequence.

---

**Patient Header** *(always visible, non-interactive top bar)*
```
[ NAME: Kaushik Talukdar | Age: 37 | Sex: M | Phone: 98XXXXXXXX ]
[ ⚠️ Allergic: Penicillin ]   ← small chip, only shown if allergy exists
```
- Allergy stays in the header as a **small passive chip** — not a full banner section.
- Allergy is a **dumb free-text field**: doctor writes the composition/substance that caused the reaction (e.g. `"Penicillin"`, `"Sulfa drugs"`). No structured coding, no dropdowns.
- Future TODO: allow doctor to edit patient details (name, age, gender) from this header.

---

**Section: Clinical Observations** *(expandable modal on tap)*
Two parts, both optional:
1. **Vitals** — BP, Pulse, SpO2, Temperature, Weight, Blood Sugar. Standard compact grid.
2. **Clinical Notes (MBBS/MD Standard Headers)** — Rapid free-text entry organized by familiar Indian medical acronyms:
   - **`C/O`** (Chief Complaints — e.g., *Fever x 3 days, cough x 5 days*)
   - **`O/E`** (On Examination — e.g., *Chest B/L clear, P/A soft*)
   - **`Dx` / `P/D`** (Provisional Diagnosis — e.g., *Acute Bronchitis*)
   - For returning patients, the **last visit's clinical notes are shown read-only** above the new entry fields for instant reference.

---

**Section: Past History** *(only shown for returning patients; closed accordion by default)*

Three sub-accordions, all closed on load:
- **Past Findings** — Read-only view of last visit's clinical observations and notes.
- **Past Medicines** — Read-only list of last visit's prescribed medicines with dosage and duration. Includes a **`[CARRY FORWARD TO CURRENT PRESCRIPTION]`** button (see below).
- **Past Lab Results** — Read-only view of last visit's ordered investigations and recorded values.

**Carry Forward Rule:**
- Tapping `[CARRY FORWARD]` copies all medicines from the last visit into the current prescription area exactly as they were: same medicine (including composition), same dosage, same duration, as **`CONTINUE`** state entries.
- The prescription section auto-expands and populates immediately.
- The `[CARRY FORWARD]` button is **disabled after first tap** (greyed out, label changes to `✓ Carried Forward`) to prevent duplicate population.
- **Re-enable edge case:** If the doctor clears the entire staging area after carrying forward (e.g. removes all carried entries manually), the button **re-enables** automatically. The disable state is tied to whether any carried-forward entries exist in the staging area — not to whether the button was ever tapped. This prevents the doctor from being permanently locked out of carrying forward during the same encounter if they clicked it by mistake.
- Once carried forward, the doctor can review each entry and tap `[STOP]` on any medicine they wish to discontinue, adding a stop reason.

---

**Section: Prescribe Medicines** *(expandable; auto-expands when Carry Forward is triggered)*
- Current medicine search and staging flow (composition/brand search, dosage, frequency, duration).
- **Indian OPD Frequency Quick-Chips:** 1-tap toggle chips for `[1-0-1]`, `[1-0-0]`, `[0-0-1]`, `[1-1-1]`, `[SOS]`, and timing chips `[After Food (PC)]` / `[Before Food / Khali Pet (AC)]` eliminating manual typing.
- **Formulation Prefixes:** Automatic rendering of standard dosage forms (`Tab.`, `Cap.`, `Syp.`, `Inj.`, `Drops`, `Oint.`) in staging and print to prevent dispensing errors by chemists.
- Shows all `START` (new) and `CONTINUE` (carried forward / ongoing) entries.
- `STOP` entries are shown with strikethrough + reason (for print audit trail).

---

**Section: Tests & Investigations** *(expandable modal on tap)*
- Doctor orders lab investigations (blood work, imaging, etc.).
- Optional. If nothing ordered, section prints nothing.

---

**Section: Remarks** *(expandable; simple freeform text box)*
- Anything the doctor wants to note that doesn't fit other sections: lifestyle advice, dietary instructions, referral notes, etc.
- Printed as "Doctor's Notes" at the bottom of the prescription.

---

**Section: Next Review** *(dropdown, optional)*
- Dropdown with fixed values: `3 days`, `7 days`, `14 days`, `1 month`, `3 months`, `Not Needed`.
- Selecting **Not Needed** (or leaving it unset) omits the follow-up line from the printed prescription entirely. Minor acute conditions (simple fever, mild infection) typically have no follow-up.
- An `[×]` reset control clears the selection if the doctor accidentally sets a date.

---

#### Pre-Print Preview (In-App Review Before Printing)

Before sending to the browser print dialog, the doctor is shown a **lightweight in-app preview modal** of the formatted prescription — essentially the `PrescriptionPrintScreen` layout rendered inside a scrollable modal overlay.

- **Purpose:** Quick sanity check. Doctor spots wrong follow-up date, a medicine that wasn't stopped, a missing test order, etc. — and taps `[Back to Edit]` to fix it.
- **Stationery Alignment Control:** Retains pre-printed clinic letterhead margin slider (`0mm` to `50mm`) and header visibility toggle directly inside the modal overlay for testing alignment with pre-printed letterhead pads.
- **Actions:** `[Back to Edit]` (dismiss modal, return to encounter) or `[Print & Complete]` (trigger browser print dialog and mark encounter as complete).
- This is not a separate navigation route — it is a modal overlay on the encounter screen itself.
- Distinct from the current `PrescriptionPrintScreen` which is a full navigation push and treated as a terminal step.
- **Keyboard shortcuts (mandatory from day one):** `Enter` → Print & Complete. `Esc` → Back to Edit. A doctor moving fast must never have to aim a mouse cursor to dismiss a sanity-check modal. These bindings are non-negotiable and must be wired at the time the modal is first implemented.

---

#### What This Replaces

| Retired | Replacement |
|---|---|
| Mandatory Step 1 (Allergies full section) | Passive allergy chip in patient header |
| Mandatory Step 2 (Vitals + Exam, always open) | `Clinical Observations` section (closed by default, expand on demand) |
| Mandatory Step 3 (Investigations Review) | `Past Lab Results` inside Past History accordion |
| Mandatory Step 4 (Medication Reconciliation, always open) | `Prescribe Medicines` section + Carry Forward from Past History |
| Mandatory Step 5 (Orders + Follow-up, always open) | `Tests & Investigations` section + `Next Review` dropdown |
| Manual CONTINUE tap per drug for returning patients | Single `[CARRY FORWARD]` button bulk-copying last visit's regimen |

> **AGENTS.md Impact:** `§1 Rule #3` (Strict 5-Step Pipeline as non-negotiable invariant) is **superseded** by this specification. The 5-step pipeline is retired. The clinical data model (START/CONTINUE/STOP, append-only consultations, longitudinal records) remains fully intact — only the UI layout and interaction pattern changes.

---

### ⚖️ HK-2: Over-Engineering Review — Resolved PM Verdicts

The following shipped features were flagged by the architect as disproportionate in complexity relative to the real-world threat model and operational scale of a small Indian OPD clinic. The PM-approved architectural verdicts are recorded below:

| Feature | Why It Was Shipped | Why It May Be Overkill | Verdict |
|---|---|---|---|
| **SHA-256 PIN Hashing** (`AuthProvider.hashPin`, `v1.19.0`) | Compliance posture, DPDP Act framing, zero plaintext in browser storage. | The threat model doesn't justify it for reception (`0000`), but master owner PIN and doctor PINs reside in browser storage. Lightweight, sub-millisecond, and fully automated. | ✅ **Keep** (Zero UX friction, retains compliance hygiene) |
| **Atomic Multi-Desk Booking Locks** (`counters/lock_*`, `v1.18.0`) | Eliminate race conditions when multiple reception desks book simultaneously. | Almost all Indian OPD clinics have exactly **one** reception desk. The existing Firestore transaction on the queue counter already prevents duplicate token allocation. The distributed lock layer is redundant and adds Firestore write overhead. | 🗑️ **Removed** (Pruned under Invariant #10) |
| **Hardcoded Prescription Template Bundles (`P9`, `v1.28.0`)** | 1-tap OPD clinical presets for common conditions (URI, Gastritis, Viral Fever, HTN Starter). | Templates are hardcoded for a generic GP. A specialist finds them irrelevant. The right design is **per-doctor saved templates built from actual encounters**. | 🧪 **Promoted to Experiment** (Revocable UI in Section 8) |
| **Forensic Audit Events Collection** (`appointment_events`, `v1.18.0`) | Immutable, append-only log of every appointment lifecycle state shift for compliance auditing. | The `appointments` collection already stores status transitions immutably (Zero Deletions invariant). `appointment_events` is a write-only sink with zero UI consumers that doubles Firestore write costs per appointment. | 🗑️ **Removed** (Pruned under Invariant #10) |

---

## 🎯 4. Active Priority Backlog (Next Horizon)


All primary operational priorities (P1 through P10) and review cycle enforcement have been successfully implemented and verified across 209 automated tests. P12 (Patient Lookup) has also shipped. Future enhancements and architectural debates are prioritized below:

| Priority | Proposed Feature | Problem Solved | Acceptance Criteria |
|---|---|---|---|
| **P11** | **Prepaid Carry-Over & Doctor No-Show / Refund Protocol (RFC)** | Patient paid online/cash but didn't attend, OR consulting doctor canceled/absent. Current ledger has no formal carry-forward or refund state. | Formalized refund ledger (`PaymentType.refunded` / `refundAmount`) updating daily cash/UPI totals, or explicit carry-over token revalidation without double charging. |
| ~~**P12**~~ | ~~**Patient Lookup / Explore Patients**~~ | ✅ **Shipped in `v1.33.0`** — Dedicated `Patients` tab with zero-egress initial state, multi-doctor consultation segregation, and 1-tap walk-in booking shortcut. | — |
| **P13** | **Emergency / Illiterate Walk-In Dummy Key** | Emergency casualty or elderly village patient arrives without a mobile phone or cannot recall it. Registration strictly mandates a 10-digit primary phone key, blocking immediate token issuance. | 1-tap `[No Mobile / Emergency Dummy]` toggle at walk-in registration allocating sequential clinic dummy phone keys (`9900000001`+), generating immediate atomic queue tokens without breaking database integrity. |
| **P15 · 🧪 (TODO)** | **Fullscreen Waiting Hall Queue Display Board (`/display`)** | Counter assistants must repeatedly shout patient names across noisy waiting rooms; patients crowd reception asking when their turn will come. | Fullscreen responsive route (`/display`) designed for counter-facing tablets or waiting hall Android TVs. Subscribes in real-time to active doctor chamber sessions, displaying currently calling tokens, room numbers, and triggering in-browser dispatch chimes. |

---

## ⚖️ 5. Architectural RFCs & Active PM Debates

The following clinical, financial, and operational dilemmas are under active product deliberation before code implementation:

### 📋 RFC-1: Strict 1-Time Free Review Cycle Model — ✅ Resolved in `v1.22.0`
- **Clinical Intent:** In Indian OPD practice, a "Free Review" exists exclusively to review lab reports, radiology, or drug tolerance resulting directly from an initial paid consultation. It is **never** an open-ended pass for unlimited free consultations.
- **Canonical Implementation** (`lib/models/patient_review_eligibility.dart`):
  1. **Strict 1:1 Relationship:** Each paid encounter (`paidCash`, `paidUpi`, `postPay` with collection) unlocks exactly **one (1)** free review token within the doctor's configured `freeReviewDays` window.
  2. **Doctor-Paced Opt-In:** Free reviews only apply if the doctor has configured `freeReviewDays > 0`. If `freeReviewDays == 0`, free reviews are disabled completely.
  3. **Consumption & Reset:** Once a free review is completed (`visitStatus == completed` with `PaymentType.freeReview`), that entitlement is permanently marked **consumed**. The next visit must be a paid visit, which subsequently unlocks a brand-new review cycle.


### 💰 RFC-2: Prepaid Token Carry-Forward vs. Doctor No-Show Refund
- **Scenario A: Patient Paid in Advance but Did Not Attend (Patient No-Show)**
  - *Context:* Patient paid ₹500 via online UPI or advance counter payment, but could not make it to the clinic.
  - *Dilemma:* Yesterday's token is closed as `absent`. If they arrive the next day:
    - *Option 1 (Carry-Forward Token):* Reception selects "Revalidate Yesterday's Paid Token", generating today's token linked to yesterday's payment reference with ₹0 fresh collection.
    - *Option 2 (Refund & Re-collect):* Yesterday's token is marked `refunded`, and today's token collects fresh payment.
    - *Option 3 (Time-Bound Expiry):* Clinic policy forfeits the consultation fee if not rescheduled before the doctor's shift concludes.
- **Scenario B: Doctor Did Not Show Up (Doctor Absence / Emergency Cancellation) After Patient Paid**
  - *Context:* Patient physically checked in or paid online, but the consulting physician had an emergency or failed to conduct the OPD session.
  - *Inviolable Rule:* **The patient MUST be refunded, and this financial reversal MUST be accurately reflected in the clinic register.**
  - *Audit & Ledger Impact:*
    - In accordance with the **Zero Deletions Invariant**, the appointment document cannot be deleted from Firestore.
    - Its status must transition to a dedicated state (e.g., `AppointmentStatus.absent` or `VisitStatus.cancelled` with `refundStatus: 'refunded'`).
    - The daily revenue calculation ([RevenueEngine](../lib/core/engines/revenue_engine.dart)) and end-of-day cash handover ([CashHandoverEngine](../lib/core/engines/cash_handover_engine.dart)) must deduct the refunded amount so the counter register matches physical cash in the drawer and doctor payouts are zeroed.
    - If paid via UPI, a digital refund transaction ID must be captured for forensic audit.

---

## 🗑️ 6. Scrapped & Superseded Items (Strict "Do Not Re-Implement" Log)

To prevent AI assistants from regressing or re-introducing discarded patterns:

| Discarded Feature / Pattern | Initial State / Idea | Why It Was Scrapped | Prevention Guardrail for AI |
|---|---|---|---|
| **Pharmacy Inventory & Batch Tracking** | Prototype had fields for batch numbers, expiry dates, supplier invoices, and stock counts. | Creates administrative overload. Transforms a fast clinical OPD tool into an expensive retail ERP. | **Never re-add** batch, expiry, or stock ledger collections to Firestore or models. |
| **Retail Counter POS Billing** | Selling cotton, band-aids, OTC products at reception. | Distracts counter assistant from token flow and queue management. | Keep billing restricted strictly to doctor consultation tokens. |
| **Modal Prescribing Dialogs** | Prescribing was opened in fullscreen popups. | Interrupted clinical view and added 4+ clicks per drug. | Keep medication search and prefilled defaults **inline** within the encounter body. |
| **Destructive Prescription Overwrite** | Modifying previous visit's consultation document on return visit. | Destroys medical-legal audit history. Violates longitudinal record integrity. | Consultations must remain strictly **append-only**. Follow-ups use `MedicationAction.continueAction` or `stopAction`. |
| **Queue Item Deletion** | Deleting canceled or duplicate appointments from Firestore. | Enables financial leakage and cheating between counter and doctors. | Deletions are forbidden. Mark as `AppointmentStatus.absent` with `amountCollected: 0`. |
| **Atomic Multi-Desk Booking Locks (`counters/lock_*`)** | Transactional distributed locks per appointment reservation. | 95%+ of clinics have 1 counter. Queue counter transaction + UI check already serialize token allocation. Adds redundant writes and orphan risks. | Do not re-add distributed lock collections or keys. Counter transaction is authoritative. |
| **Forensic Audit Events Collection (`appointment_events`)** | Secondary append-only audit trail logging every status change. | Write-only collection with zero UI consumers. Doubles Firestore writes. Appointments collection is already immutable under Zero Deletions. | Store lifecycle timestamps directly on `Appointment` (`checkedInAt`, `completedAt`). Never re-introduce `appointment_events`. |
| **P14: Dedicated Discretionary Fee Waiver Type (`freeConcession`)** | Adding `PaymentType.freeConcession` for doctor-authorized fee waivers. | Completely redundant with `PaymentType.freeFamily` ("Family / Complimentary"), which already records authorized discretionary waivers with ₹0 collection and clean financial ledger reporting. | Use `PaymentType.freeFamily` for all authorized discretionary waivers. Never add redundant payment type enum variants. |

---

## 📋 7. Operational Governance for AI Agents
1. Before implementing any feature, check this matrix to ensure the task aligns with Section 3 or Section 4.
2. If an AI receives a prompt that matches an item in Section 1 or Section 6, it must **flag the conflict immediately** and adhere to the architectural guardrails.
3. Only the **Product Manager** can promote items from Proposed to Active Backlog.
4. Features marked `🧪` (see Section 8) require explicit PM sign-off before being hardened into stable, non-removable product surface. Treat them as revocable at any point.

---

## 🧪 8. Experiment Flag Registry

Some features — shipped or planned — are inherently exploratory in nature. They solve a real problem but carry uncertainty around UX fit, data model stability, or long-term clinical value. These are formally tagged with the **🧪 EXPERIMENT** flag.

### What the 🧪 Flag Means

| Property | Behaviour |
|---|---|
| **Revocable** | PM can remove or gut the feature at any time without it being treated as a regression. |
| **No Schema Lock-in** | Firestore fields or collections introduced solely for an experimental feature may be removed or restructured without a migration shim. |
| **No Test Coverage Mandate** | Experimental features are exempt from the 100% domain engine test coverage rule until promoted to stable. |
| **No Backward-Compat Debt** | Consistent with the Zero Backward-Compatibility Debt invariant — experimental features that are scrapped leave zero adapter residue. |
| **UI Opt-In Only** | Experimental features must never gate, block, or degrade the core booking / queue / encounter pipeline. They are strictly additive. |

### AI Agent Rules for 🧪 Features
- When implementing a `🧪` feature, **scope it narrowly** — one new file or widget; avoid deep tentacles into core engines.
- When refactoring or modifying core systems, **do not let changes break `🧪` features silently** — but also do not bend core architecture to preserve them.
- If a `🧪` feature's Firestore schema conflicts with a clean architectural direction, **the clean direction wins**.

### 🧪 Current Experiment Inventory

| Feature | Status | Flag Reason | Promotion Criteria |
|---|---|---|---|
| **Multi-Chamber Sound Announcer (P10)** | 🟢 Shipped (`v1.29.0`) | Browser SpeechSynthesis and Web Audio API reliability varies widely across clinic PC hardware, browsers, and OS audio routing. Real-world sound quality and intelligibility in a noisy OPD reception is unproven. | Validated across ≥ 3 real clinic deployments with stable chime delivery and zero browser crash reports. |
| **Prescription Template Presets (P9)** | 🟢 Shipped (`v1.28.0`) • 🧪 Experiment | Hardcoded GP condition bundles are rigid and specialty-dependent. Serves as interim convenience until per-doctor customizable templates saved from encounters are built. Gated via `ClinicConfig.current.features.enablePrescriptionTemplatePresets` (default: `false` in `lib/config/clinic_config.dart`). | Replaced by user-saved templates feature without backward compatibility shims. |
| **Patient Lookup / Explore Patients (P12)** | 🟢 Shipped (`v1.33.0`) | ~~📋 TODO~~ Feature shipped with zero-egress search, multi-doctor consultation segregation, and 1-tap walk-in booking shortcut. | ✅ Shipped — no further promotion criteria. |
| **Waiting Hall Queue Display Board (P15)** | 📋 TODO · 🧪 Experiment | Hardware variation on lobby TVs (Chromecast, Android TV browsers, firestick) and persistent websocket stability across 8+ hour clinic shifts is unproven. | Validated in active clinic lobby TV running continuously for 1 full shift with real-time token shifts and zero browser freezes. |
