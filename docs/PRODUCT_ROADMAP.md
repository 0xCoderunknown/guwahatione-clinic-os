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
| **Patient Registration** | 10-digit phone lookup, age/gender, allergy alerts, doctor-configured free review eligibility auto-calculation (`freeReviewDays` 0–30). | 🟢 Verified & Live |
| **Longitudinal Prescribing** | 5-step encounter pipeline, medication reconciliation (`START`, `CONTINUE`, `STOP`), unlisted outside medicine fallback. | 🟢 Verified & Live |
| **Chamber Auto-Sync (`P1`)** | Real-time sync at `counters/chamber_{doctorId}_{date}`. Reception clicks "Call In" ➔ Doctor screen automatically loads patient encounter. Includes consultation collision alert banner. | 🟢 Shipped & Verified (`v1.5.0`) |
| **Clinical Defaults (`P2`)** | `ClinicalDefaultsHelper` auto-populates standard OPD regimens (PPIs, Antihypertensives, Diabetes, Statins, Antibiotics, Liquids, Topicals) with prefilled dosage, frequency, and duration defaults. | 🟢 Shipped & Verified (`v1.5.0`) |
| **Collapsible Encounter Sections (`P3`)** | Step 2 Findings and Step 4 Prescribing collapsible into compact summary badge strips to reduce scrolling on counter displays. | 🟢 Shipped & Verified (`v1.5.0`) |
| **Doctor Prescribing Search Preferences (`P4`)** | Per-doctor `searchPreference` (`brandFirst` vs `compositionFirst`) with dual-mode `MedicineSearchScorer` and quick-toggle `[🏷️ Brand | 🧪 Salt]` pill on search bar. | 🟢 Shipped & Verified (`v1.5.0`) |
| **Modular Encounter Architecture & State Encapsulation** | Deconstructed ~2,600-line monolithic encounter into reusable atomic step widgets (`lib/widgets/encounter/`), centralized `EncounterFormState`, and lightweight (<300 line) coordinator scaffold. | 🟢 Shipped & Verified (`v1.6.0`) |
| **Comprehensive Frontend Modularization** | Modularized Dashboard, Chamber, Prescribing/Encounter, Prescription Print, Add Appointment, and Reception Queue into clean sub-packages under `lib/widgets/` with centralized barrel export. | 🟢 Shipped & Verified (`v1.7.0`) |
| **Core Domain Engines & UI Math Decoupling** | Centralized pure Dart engines (`lib/core/engines/`) for revenue calculations, 14-day review eligibility, fee resolution, and pharmacological defaults. All `.fold()` and inline math stripped from UI widgets. Consolidated `MetricKpiCard` and unified `ClinicDateNavBar`. | 🟢 Shipped & Verified (`v1.8.0`) |
| **Doctor-Reception 2-Way Handshake Protocol** | Synchronized 5-stage handshake: End of visit transitions to `consultation_ended` (Breather); Doctor single-tap `NEXT PATIENT` trigger (`ready_for_next`); Reception counter presence verification & admission guardrail (`calling` / `in_consultation`); Breather confirmation speed bump; Doctor emergency safety valve manual override for offline/unresponsive counters. | 🟢 Shipped & Verified (`v1.9.0`) |
| **Indian Date Format Standardization (DD-MM-YYYY)** | Unified all UI, print previews, review eligibility warnings, and date navigation headers to Indian standard numerical date formats (`dd-MM-yyyy`, `dd-MM-yy`, and `EEEE, dd-MM-yyyy`) via centralized `AppFormatters`. | 🟢 Shipped & Verified (`v1.9.0`) |
| **Agile Reception Queue & Discretionary Chamber Dispatch** | Top-level collapsible `CompletedConsultationsAccordion` archives finished visits; single-expansion accordion controller; high-visibility `[SEND IN]` button with chamber occupancy collision safety guard; pure domain `partitionQueueForReception` non-destructively tags bypassed/late tokens (`[BYPASSED / LATE]`) without artificial "Skip" states or database mutations, preserving receptionist operational autonomy for emergencies and VIPs. | 🟢 Shipped & Verified (`v1.10.0`) |
| **Keyboard-First Walk-In Modal & Live Token Preview** | 100% mouse-free walk-in booking: Tab-order chaining across Phone, Name, Age, Sex, Doctor, and Payment; dedicated physical hotkeys (`M`/`F`/`O` and arrows) for Sex selection with zero accidental defaults; dynamic provisional token & estimated consultation arrival window badge calculated directly on doctor selection. | 🟢 Shipped & Verified (`v1.11.0`) |
| **Same-Day Duplicate Booking Guard & Family Exception** | Composite key detection `(Date + DoctorId + Normalized Patient Name + Phone)` with live amber alert banner and submit lockout preventing double bookings for the same patient, while explicitly preserving family member bookings under shared phone numbers. Includes 1-tap live queue locator. | 🟢 Shipped & Verified (`v1.11.0`) |
| **3-Tier Role Security & Master 6-Digit Owner PIN** | Receptionist (PIN `0000`), Doctor (4-digit PIN), and Clinic Owner (6-digit Master PIN in `clinic_config`) with dedicated permissions unlocking Doctor CRUD, schedule updates, consultation fee edits, and financial ledger audits. | 🟢 Shipped & Verified (`v1.11.0`) |
| **Master Medicine Catalogue** | Chemical composition search scorer, OPD essential formulary, owner-only deduplication engine. | 🟢 Verified & Live |
| **Prescription Printing** | Monochrome clean layout, A4 & A5 support, pre-printed clinic letterhead margin toggle, browser print via `dart:js_interop`. | 🟢 Verified & Live |
| **Doctor Chamber Queue** | Real-time consultant token stream, doctor fee summary, patient history review. | 🟢 Verified & Live |
| **Doctor Medical Reg & Print Footer (`P5`)** | Medical council registration number (`medicalRegNumber` / `doctorRegNumber`) in doctor profile, roster card badge, and official prescription signature footer block. | 🟢 Shipped & Verified (`v1.14.0`) |
| **Domain Engine Test Fortification** | 100% unit test coverage across pure domain engines (`RevenueEngine`, `AppointmentEngine`, `MedicineEngine`) with 81 automated tests. | 🟢 Shipped & Verified (`v1.14.0`) |
| **Offline Queue Fallback Cache (`P6`)** | Silent caching of daily appointments to local browser storage (`SharedPreferences`) with graceful zero-dropout fallback and amber status badge during broadband hiccups. | 🟢 Shipped & Verified (`v1.15.0`) |
| **WhatsApp Prescription Deep Link (`P7`)** | Formatted clinical summaries via pure `WhatsAppEngine` with Indian date standard (`DD-MM-YYYY`), vitals, medication schedule, and 1-tap `wa.me` deep link delivery. | 🟢 Shipped & Verified (`v1.15.0`) |
| **Daily Cash Handover & Note Counter (`P8`)** | End-of-day cash reconciliation modal (`DailyCashHandoverDialog`) with doctor-wise cash breakdown, interactive Indian note denomination counter, and discrepancy auditing. | 🟢 Shipped & Verified (`v1.15.0`) |
| **Asynchronous OPD Booking & 1-Tap Desk Check-In** | Advance and phone bookings register as `VisitStatus.booked` with zero lobby clutter; physical arrival triggers 1-tap `QuickCheckInDialog` with granular payment reconciliation (`paidCash`, `paidUpi`, `postPay`, `freeReview`, `freeFamily`, `unpaid`). | 🟢 Shipped & Verified (`v1.16.0`) |
| **Restricted Emergency Door Self-Call Runway** | `ChamberDoorOverrideBar` strictly displays only the top 1–2 physically checked-in patients (`waitingInLobby`) with amber warning modals to prevent queue chaos during receptionist breaks. | 🟢 Shipped & Verified (`v1.16.1`) |
| **Read-Only Archive State for Historical Chamber Dates** | Selecting any date prior to today switches doctor chamber to immutable archive mode (`ChamberArchiveBanner`), suppressing all live controls, self-call bars, and admissions while allowing review of past consultation notes. | 🟢 Shipped & Verified (`v1.16.2`) |
| **Architectural Consolidation & Layer Modernization** | Consolidated widgets from 56 to 44 (-21%), decoupled screens and providers from monolithic `FirebaseService` (now retired), hardened polymorphic model deserialization, and added models barrel export. | 🟢 Shipped & Verified (`v1.16.5`) |
| **Pure Dart Domain Engines & Math Audit** | Architectural review and extraction of all 5 pure Dart domain engines ([RevenueEngine](../lib/core/engines/revenue_engine.dart), [AppointmentEngine](../lib/core/engines/appointment_engine.dart), [MedicineEngine](../lib/core/engines/medicine_engine.dart), [WhatsAppEngine](../lib/core/engines/whatsapp_engine.dart), [CashHandoverEngine](../lib/core/engines/cash_handover_engine.dart)), verified zero UI/Firebase leaks, synchronized canonical barrels, and fortified test suite to 145 passing tests. | 🟢 Shipped & Verified (`v1.16.8`) |
| **Backend Security Rules & State Model Parity** | Authoritative `firestore.rules` enforcing Zero Deletions and append-only consultations at database level, unified single source of truth for appointment status, and expanded test suite to 148 automated tests. | 🟢 Shipped & Verified (`v1.17.0`) |
| **Phase 2: Atomic Locks & Forensic Audit Trail** | Atomic booking reservation locks (`counters/lock_*`) in Firestore transaction eliminating multi-desk race conditions, immutable append-only `appointment_events` collection logging every lifecycle shift, and expanded test suite to 153 automated tests. | 🟢 Shipped & Verified (`v1.18.0`) |
| **Cryptographic Credential Hashing & Compliance Matrix** | Domain-salted SHA-256 PIN hashing in `AuthProvider` purging plaintext credentials from storage, DPDP Act & ABDM healthcare compliance matrix, and expanded test suite to 155 automated tests. | 🟢 Shipped & Verified (`v1.19.0`) |
| **Doctor-Configurable Free Review Policy (0–30 Days)** | Added configurable `freeReviewDays` on `Doctor` model (`0` to `30` days, default: `14`), owner configuration UI with preset choice chips, roster visibility badges, dynamic review eligibility engine evaluation, warning dialogs, and expanded test suite to 157 automated tests. | 🟢 Shipped & Verified (`v1.20.0`) |
| **Mobile Responsive Doctor Chamber & Roster Tokens** | Responsive `LayoutBuilder` for `ChamberControlBanner`, adaptive 2-row `ChamberTokenCard` layout, and wrapping `ChamberQueueHeader` preventing horizontal `RenderFlex` overflows on mobile viewports (<650px); expanded test suite to 160 automated tests. | 🟢 Shipped & Verified (`v1.21.0`) |
| **Strict 1:1 Paid-to-Review Cycle Enforcement** | Enforced strictly 1 free review per paid consultation within the doctor's configured `freeReviewDays` window; subsequent visits require paid consultation; prevents infinite review chaining; expanded test suite to 163 automated tests. | 🟢 Shipped & Verified (`v1.22.0`) |
| **Prescription Template Presets (`P9`)** | Pre-configured clinical OPD bundles (URI/Pharyngitis, Acute Gastritis, Gastroenteritis, Viral Fever, HTN Starter) with 1-tap horizontal chip loader (`RxTemplatePresetsBar`), duplicate suppression by brand and salt composition (`evaluateTemplateApplication`), and non-destructive `START` staging; expanded test suite to 179 automated tests. | 🟢 Shipped & Verified (`v1.28.0`) |
| **Multi-Chamber Queue Sound Announcer (`P10`)** | In-browser Web Audio API dual-tone chime (587.33 Hz $\to$ 880 Hz) and SpeechSynthesis token callout ("Token N, please proceed to Dr. X") on patient dispatch, persistent Mute/Unmute toggle in AppBars, deduplication guard, and zero external asset dependencies; expanded test suite to 184 automated tests. | 🟢 Shipped & Verified (`v1.29.0`) |

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
1. **Vitals** — BP, Pulse, SpO2, Temperature, Weight. Standard compact grid.
2. **Findings / Remarks** — Freeform text. Doctor notes clinical findings, symptoms, working diagnosis. For returning patients, the **last visit's findings are shown read-only** above the new entry field for quick reference.

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

### ⚖️ HK-2: Over-Engineering Review — Pending PM Verdict

The following shipped features were flagged by the architect as disproportionate in complexity relative to the real-world threat model and operational scale of a small Indian OPD clinic. They are **not being removed immediately** — each is listed here for PM review. The verdict options are:
- **Remove** — strip it out cleanly, no shim left behind (consistent with Zero Backward-Compat Debt invariant).
- **Promote to 🧪** — move to the Experiment Flag Registry (Section 8) and treat as revocable, low-priority maintenance surface.
- **Keep** — PM decides the complexity is justified and the flag is cleared.

| Feature | Why It Was Shipped | Why It May Be Overkill | Verdict |
|---|---|---|---|
| **SHA-256 PIN Hashing** (`AuthProvider.hashPin`, `v1.19.0`) | Compliance posture, DPDP Act framing, zero plaintext in browser storage. | The threat model doesn't justify it. Reception PIN is `0000` — publicly known by design. Doctor PINs are 4-digit numbers shared verbally. Nobody is extracting `SharedPreferences` in a clinic. The primary fraud risk is cash at the counter, not credential theft. | ⏳ Pending |
| **Atomic Multi-Desk Booking Locks** (`counters/lock_*`, `v1.18.0`) | Eliminate race conditions when multiple reception desks book simultaneously. | Almost all Indian OPD clinics have exactly **one** reception desk. The existing Firestore transaction on the queue counter already prevents duplicate token allocation. The distributed lock layer solves a problem that doesn't exist for 95% of the user base. | ⏳ Pending |
| **Hardcoded Prescription Template Bundles (`P9`, `v1.28.0`)** | 1-tap OPD clinical presets for common conditions (URI, Gastritis, Viral Fever, HTN Starter). | Templates are hardcoded for a generic GP. A specialist (cardiologist, ENT, dermatologist) finds them irrelevant or potentially dangerous if applied without review. A doctor whose prescribing habit deviates from the bundle even once will stop using it. The right design is **per-doctor saved templates built from actual encounters** — not hardcoded bundles. | ⏳ Pending |
| **Forensic Audit Events Collection** (`appointment_events`, `v1.18.0`) | Immutable, append-only log of every appointment lifecycle state shift for compliance auditing. | The `appointments` collection already stores status transitions immutably. The `appointment_events` sub-collection is a second audit trail that adds a Firestore write on every state shift (created → booked → checked-in → in-consultation → completed / absent). For a small OPD clinic with no compliance team querying event logs, this is an operational overhead with no visible benefit. | ⏳ Pending |

---

## 🎯 4. Active Priority Backlog (Next Horizon)


All primary operational priorities (P1 through P10) and review cycle enforcement have been successfully implemented and verified across 184 automated tests. Future enhancements and architectural debates are prioritized below:

| Priority | Proposed Feature | Problem Solved | Acceptance Criteria |
|---|---|---|---|
| **P11** | **Prepaid Carry-Over & Doctor No-Show / Refund Protocol (RFC)** | Patient paid online/cash but didn't attend, OR consulting doctor canceled/absent. Current ledger has no formal carry-forward or refund state. | Formalized refund ledger (`PaymentType.refunded` / `refundAmount`) updating daily cash/UPI totals, or explicit carry-over token revalidation without double charging. |
| **P12 · 🧪 (TODO)** | **Patient Lookup / Explore Patients** | No way to quickly look up a patient's history (name, phone, past visits, allergies) without going through the full booking flow. Useful for front-desk staff fielding enquiries, referrals, or repeat patient calls. | Dedicated "Explore Patients" screen (owner/reception access): free-text search by name or 10-digit phone against Firestore `patients` collection, displays patient profile card (allergy alerts, last visit date, linked doctor, visit count). Optional 1-tap shortcut to open the walk-in booking modal pre-populated with the looked-up patient's details. No appointment creation is forced — purely a read-only enquiry tool unless the user explicitly initiates booking. |

---

## ⚖️ 4. Architectural RFCs & Active PM Debates

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
4. Features marked `🧪` (see Section 7) require explicit PM sign-off before being hardened into stable, non-removable product surface. Treat them as revocable at any point.

---

## 🧪 7. Experiment Flag Registry

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
| **Patient Lookup / Explore Patients (P12)** | 📋 TODO | Feature scope and access model (owner-only vs. reception) is unclear. Firestore query patterns for name prefix search are unproven at scale. Direct booking shortcut may complicate walk-in modal state. | Defined UX wireframe approved by PM; Firestore `patients` index confirmed; booking integration tested end-to-end. |
