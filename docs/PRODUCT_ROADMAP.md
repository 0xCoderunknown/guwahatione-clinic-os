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

---

## 🎯 3. Active Priority Backlog (Next Horizon)

All primary operational priorities (P1 through P8) have been successfully implemented and verified across 118 automated tests. Future enhancements are proposed based on operational feedback from reception counters and consulting physicians.

| Priority | Proposed Feature | Problem Solved | Acceptance Criteria |
|---|---|---|---|
| **P9** | **Prescription Template Presets** | Visiting doctors prescribe repetitive sets of medicines for common OPD conditions (e.g. URI, Acute Gastritis). | 1-tap favorite prescription template loader in Step 4 prescribing pipeline. |
| **P10** | **Multi-Chamber Queue Sound Announcer** | Counter receptionist wants audible token chime (e.g. "Token 5, please proceed to Chamber 1") for waiting lobby. | Web audio chime synthesized on chamber call-in trigger. |

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
