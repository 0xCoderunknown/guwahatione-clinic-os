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
| **Strict 1:1 Paid-to-Review Cycle Enforcement** | Enforced strictly 1 free review per paid consultation within the doctor's configured `freeReviewDays` window; subsequent visits require paid consultation; prevents infinite review chaining; expanded test suite to 163 automated tests. | 🟢 Implemented & Verified |
| **Prescription Template Presets (`P9`)** | Pre-configured clinical OPD bundles (URI/Pharyngitis, Acute Gastritis, Gastroenteritis, Viral Fever, HTN Starter) with 1-tap horizontal chip loader (`RxTemplatePresetsBar`), duplicate suppression by brand and salt composition (`evaluateTemplateApplication`), and non-destructive `START` staging; expanded test suite to 179 automated tests. | 🟢 Shipped & Verified (`v1.28.0`) |

---

## 🎯 3. Active Priority Backlog (Next Horizon)

All primary operational priorities (P1 through P9) and review cycle enforcement have been successfully implemented and verified across 179 automated tests. Future enhancements and architectural debates are prioritized below:

| Priority | Proposed Feature | Problem Solved | Acceptance Criteria |
|---|---|---|---|
| **P10** | **Multi-Chamber Queue Sound Announcer** | Counter receptionist wants audible token chime (e.g. "Token 5, please proceed to Chamber 1") for waiting lobby. | Web audio chime synthesized on chamber call-in trigger. |
| **P11** | **Prepaid Carry-Over & Doctor No-Show / Refund Protocol (RFC)** | Patient paid online/cash but didn't attend, OR consulting doctor canceled/absent. Current ledger has no formal carry-forward or refund state. | Formalized refund ledger (`PaymentType.refunded` / `refundAmount`) updating daily cash/UPI totals, or explicit carry-over token revalidation without double charging. |

---

## ⚖️ 4. Architectural RFCs & Active PM Debates

The following clinical, financial, and operational dilemmas are under active product deliberation before code implementation:

### 📋 RFC-1: Strict 1-Time Free Review Cycle Model — ✅ Resolved in `v1.22.0`
> **Status:** Implemented and verified. See `CHANGELOG.md [1.22.0]` and `lib/models/patient_review_eligibility.dart`. Preserved below for historical context — do **not** treat as an open bug or active debate.
- **Clinical Intent:** In Indian OPD practice, a "Free Review" exists exclusively to review lab reports, radiology, or drug tolerance resulting directly from an initial paid consultation. It is **never** an open-ended pass for unlimited free consultations.
- **~~The Current Code Vulnerability~~ (Resolved in v1.22.0):**
  - ~~`PatientReviewEligibility.calculate` sorts past visits and inspects only the *immediate preceding visit* (`pastVisitsWithDoctor.first`).~~
  - ~~If a patient visits on Day 1 (Paid), Day 5 (Free Review #1), Day 8 (Free Review #2), and Day 12 (Free Review #3), the current engine sees each visit as $\le 14$ days from the last and marks every single one as eligible for a free review!~~
- **Implemented Solution:**
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
