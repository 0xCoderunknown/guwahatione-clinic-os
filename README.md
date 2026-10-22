# 🏥 GuwahatiOne Clinic OS

> **A human-first, web-native outpatient clinic operating system engineered for real-world OPD practices in Tier 2 Indian cities. Built around 1–3 consulting doctors, an attached front pharmacy, append-only longitudinal medical records, and zero-bullshit clinical workflows.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)

A web-first clinic and chamber management system built for standalone polyclinics, pharmacy-attached consultation rooms, and multi-doctor outpatient practices. Engineered for [GuwahatiOne](https://guwahatiOne.com).

---

## 🌆 The Evening OPD: A Tale of Two Chambers, Two Patients & Zero Chaos

*It's 6:30 PM in a bustling Tier 2 city clinic. There is an attached medicine counter in front, a waiting lobby with ceiling fans humming in the middle, and two consulting chambers in the back:*
- **Chamber 1:** Dr. Bhaskar (Consultant Physician — General Medicine)
- **Chamber 2:** Dr. Pritisha (Consultant Pediatrician)

Here is how ClinicOS actually runs the floor:

### 1. The Reception Desk & Phone-First Lookup
**Hira** walks in through the glass door. She is a returning patient with hypertension.
The receptionist doesn't ask for a patient ID card or a folder. She taps `F2` and types Hira's 10-digit mobile number:
- The system recognizes her instantly: *"Returning Patient: Hira (42 F)"*. All demographics auto-fill.
- The receptionist selects **Dr. Bhaskar**.
- The engine checks his records: Hira had a paid visit 7 days ago. Dr. Bhaskar's configured review window is **14 days** $\to$ **Fee: ₹0 (Free Follow-Up Review)**.
- Before committing, the modal calculates her slot: **Token #8 · Estimated Consultation: ~6:50 PM**.

Right behind Hira is **Kamal**, holding his 4-year-old feverish son by the hand.
A 4-year-old child doesn't have a phone number. Under rigid corporate hospital software, registration grinds to a halt. In ClinicOS, the receptionist enters Kamal's number:
- Kamal's family chips pop up: `[👤 Kamal]` and `[➕ Add Member]`.
- She taps `+ Add Member`, types the child's name and age (`4 Yrs`), and assigns **Dr. Pritisha**.
- Dr. Pritisha has a **0-day review policy** (every pediatric acute consultation is fresh) $\to$ standard fee is collected.
- Kamal's child receives an independent clinical identity (`patientId`) linked to the father's phone—**zero chart cross-contamination between father and child**.

### 2. The Doctor-Paced Handshake & The 2-Minute Breather
Dr. Bhaskar arrives, enters Chamber 1, logs in with his 4-digit PIN, and clicks **`I AM READY`**.
- Immediately, on the reception screen, the dispatch arrow next to his patients lights up green.
- Receptionist calls Token #1. But Token #1 has stepped out to the medical shop across the street.
- **The queue doesn't freeze.** Reception skips Token #1 without breaking the ledger, calls Token #2, verifies physical presence and payment, and clicks the green arrow.
- Instantly, Dr. Bhaskar's screen auto-loads the consultation workspace for Token #2.

When Dr. Bhaskar finishes, signs, and hands over the prescription, the patient walks out.
In ordinary clinics, the receptionist immediately pushes the next patient through the curtain.
**Not in ClinicOS.**
- The chamber automatically locks into **Breather Mode** (`consultation_ended`).
- The dispatch arrow on reception is disabled: *"Doctor on Break (Holding Queue)"*.
- Dr. Bhaskar has complete, undisturbed privacy to wash his hands, take a sip of water, or answer a private phone call.
- Only when Dr. Bhaskar feels ready and clicks **`NEXT PATIENT`** does reception unlock to send in Token #3.

### 3. Inside the Chamber: Saving the "5-Minute Rewrite"
Hira sits in Dr. Bhaskar's chair.
Dr. Bhaskar doesn't ask her for a crumpled plastic bag of old paper prescriptions. Her full medical history across previous visits is right on his screen.
Hira is on chronic hypertension therapy. In traditional clinics, Dr. Bhaskar would spend 5 valuable minutes manually handwriting the same old medications:
$$\text{Telma 40 tablet [TELMISARTAN 40MG]} \quad\Big|\quad \text{1 tab daily morning before food} \quad\Big|\quad \text{To Continue}$$
Instead, Dr. Bhaskar clicks **`[CARRY FORWARD]`** $\to$ **BOOM.** Her entire chronic regimen is instantly staged into today's active prescription with status `To continue`.
- Want to stop one of her older medications? **1 tap on `STOP`**—a brief optional reason prompt appears, nothing more.
- Want to add Clopidogrel? He types `"clopi"`. The catalogue auto-completes `Clopitab 75 [CLOPIDOGREL 75MG]` with default dosage and `"After Food"` timing pre-filled.
- He adds his examination findings (BP `138/86`, Pulse `74`), orders a Serum Creatinine test, and clicks **`Finish Consultation & Sign`**.
- The system immediately opens the **Pre-Sign Clinical Preview Gate** (`QOL-19`), highlighting the strict 3-column table and passive allergy alerts with an amber verification banner.
- Satisfied with zero dosage errors, he clicks **`Confirm & Sign Rx`**. The append-only consultation is committed to Firestore, the chamber enters breather mode, and the monochrome prescription prints out immediately. He signs with his physical pen.

### 4. Real-World Clinic Resilience
- **What if the reception PC broadband disconnects?** Dr. Bhaskar's chamber screen has an **Emergency Door Override** (`ChamberDoorOverrideBar`) allowing him to directly call verified lobby patients into his room.
- **What if the doctor's printer jams or runs out of paper?** Past consultations are permanently preserved and append-only. Either the doctor or reception can reprint the exact prescription with one click.
- **What if the patient wants a digital copy?** A formatted clinical summary with Indian dates (`DD-MM-YYYY`), vitals, and medication schedules can be dispatched directly to the patient's phone via a **1-tap WhatsApp deep link** (`wa.me`).

---

## 💡 The Core Philosophy

ClinicOS was designed from the physical clinic floor up, not from a corporate boardroom:

1. **Longitudinal Clinical Records Over Transient Paper Artifacts:**  
   ClinicOS handles the patient's continuous clinical history—it does **not** try to run a bloated pharmacy ERP, retail stock ledger, or insurance claim engine. The printed prescription is merely a transient paper artifact; the continuous, append-only longitudinal medical record across visits is the true product.
2. **Audit-Proof Operational Ledger (Zero Deletions):**  
   Visiting consulting physicians often suspect clinic receptionists of cheating (*"I saw 10 patients today, but the receptionist paid me for 8 and claimed 2 were free reviews"*). In ClinicOS, token numbers ($1 \dots N$) are strictly consecutive, immutable, and atomic. Cancelled or no-show patients are marked **`[ABSENT] ₹0`**—slots are never deleted, ensuring complete, mutual financial trust between reception and doctors.
3. **Chamber Sovereignty & Physician Dignity:**  
   A consultation chamber is sacred. Reception can never force or barge patients into a room during an active consultation or doctor breather. The doctor dictates their own clinical pace.

## 🩺 The 5-Step Longitudinal Clinical Sequence

Every consultation encounter follows a strict, physician-aligned clinical sequence:

```
[ Step 1: Patient Header & Allergies ]
  ↳ Prominent Drug Allergies alert banner + baseline "Prior Meds" entry for fresh patients
        ↓
[ Step 2: Vitals & Clinical Examination ]
  ↳ Compact vitals (BP, Pulse, SpO2, Temp, Weight) + Complaints & Provisional Diagnosis
        ↓
[ Step 3: Diagnostic Investigations Review ]
  ↳ Past lab orders with performedDate & report values (collapsible when none exist)
        ↓
[ Step 4: Medication Reconciliation & Prescribing ]
  ↳ 1-tap CONTINUE or STOP for past regimens + 1-click [CARRY FORWARD] + START new acute/chronic therapies
        ↓
[ Step 5: Diagnostic Orders & Follow-Up ]
  ↳ Order future labs + lifestyle/diet advice + review date chips (3d, 7d, 14d, 1m, 3m)
```

---

## ✨ Features

### 📋 Longitudinal Clinical Records & Chamber Prescribing
- **🤝 Doctor-Reception 2-Way Chamber Handshake** — Real-time state-machine synchronization (`counters/chamber_{doctorId}_{date}`) between reception desk and doctor chamber. Doctors control pacing via "CONSULTATION END" and "NEXT PATIENT", preventing patient misidentification and counter confusion while providing a built-in 10-second breather. Includes Reception Speed Bump protection and Doctor Emergency Safety Valve override.
- **🔄 Longitudinal 1-Click `[CARRY FORWARD]` & Cross-Doctor Continuity** — Clinicians reviewing past visits (including historical encounters by other doctors) can instantly import past regimens as `CONTINUE` items with a single tap, skipping duplicates and binding today's unified prescription to the active consulting doctor's NMC registration while preserving previous consultation records as immutable audit-proof events.
- **🇮🇳 Indian Date & Demographics Format (`DD-MM-YYYY`)** — Complete UI and print formatting adherence to Indian clinical standards (`dd-MM-yyyy` / `dd-MM-yy`) across token accordions, appointment pickers, audit cards, and prescription headers.
- **💊 Clinical Dosage & Duration Presets (`MedicineEngine`)** — Automatically fills standard outpatient dosage, frequency, timing, and duration presets for common medication categories (PPIs, antihypertensives, antidiabetics, statins, antibiotics, liquids, topicals) upon selection.
- **🗣️ Natural Dosage & Timing Synthesis (`formattedDosageTiming`)** — Intelligently synthesizes Column 2 on prescription prints and on-screen cards without repetitive or awkward wording (e.g. `1 tablet daily morning before food` or `1 Tablet • 1-0-1 • After Food (PC)`). Includes 1-tap rapid schedule chips (`1-0-0 Khali Pet`, `1-0-1 After Food`, `1-1-1 TDS`, `0-0-1 Bedtime`, `SOS`) and Indian MBBS/MD timings (`AC`, `PC`, `HS`).
- **📑 Collapsible Encounter Sections** — Collapsible Step 2 (Vitals & Clinical Examination) and Step 4 (Medication Prescribing & Reconciliation) with summary chips to minimize page scrolling.
- **🏷️ Doctor Prescribing Search Preferences** — Configurable `searchPreference` (`brandFirst` vs `compositionFirst`) with dual-mode ranking in `MedicineEngine` and an inline `[🏷️ Brand | 🧪 Salt]` toggle.
- **Strict 5-Step Clinical Encounter (`ConsultationEncounterScreen`)** — Guides physicians through allergies, vitals, past labs, medication reconciliation, and advice.
- **Medication Reconciliation State Machine** — Explicit lifecycle states (`START`, `CONTINUE`, `STOP`) on prescription items. Frictionless 1-tap continuation for ongoing chronic regimens (`durationDays = null`) and 1-tap discontinuation without intrusive modal popups, plus 1-tap "Not Needed / SOS" follow-up chip.
- **In-Chamber Patient Demographics Correction (`QOL-04`)** — Allows physicians to correct misheard patient names, ages, and genders directly from the consultation encounter header without closing the encounter, synchronizing changes across active consultation state, appointment records, and master patient directory.
- **Reconciled Regimen In-Place Duration Dropdown & Inline Dosage Editing (`QOL-14`)** — Direct clinical duration dropdown menu on reconciled medication cards (`To Continue`, `3 Days`, `5 Days`, `7 Days`, `14 Days`, `1 Month`, `SOS`, `STOP`, and `Custom...`) plus 1-tap inline dosage/timing modal to adjust quantities, frequencies, and instructions without removing and re-searching drugs.
- **🛑 Staged Medicine Discard Guard** — Intercepts "Complete & Sign" when a configured medicine is staged but not added, offering doctors an interactive dialog with `[Add to Prescription & Sign]`, `[Discard & Sign]`, and `[Review / Cancel]`.
- **🧪 Flexible Multi-Modal Duration Engine** — `MedicineEngine.parseDuration` accepts acute numeric days (`1 to 300` days), as-needed (`SOS`), and ongoing chronic therapy (`To continue`), strictly blocking out-of-bounds day values with clear feedback.
- **Composition-First Medicine Engine (`MedicineEngine`)** — Prioritizes chemical molecule matches at the top with associated clinic trade brands grouped underneath.
- **Unlisted Medicine Support (`unlistedName`)** — Doctors can prescribe outside or unlisted medications not currently in the clinic catalogue.
- **Essential OPD Medicines Preloaded (`defaultEssentialMedicines`)** — Standard OPD medications (Dolo 650, Calpol 650, Augmentin 625 Duo, Moxikind-CV, Azee 500, Pan 40, Telma 40, etc.) with deterministic document IDs (`med_*`) to prevent duplicates on initial seed.
- **Admin vs. Prescriber Catalogue Separation (`MedicineCatalogueScreen`)** — Dedicated administration interface in reception shell for clinic owners to curate products and active compositions, with role guards preventing chamber prescriber edits.
- **Catalogue Deduplication** — Identifies and removes duplicate drug entries with identical names, compositions, and strengths from Firestore.
- **Clean Prescription Print Output & Pre-Sign Preview Gate (`QOL-19`)** — High-contrast monochrome print layout supporting **A4** and **A5** paper, pre-sign amber review banner (`"PRE-SIGN CLINICAL REVIEW"`), strict 3-column table isolation (Medicine, Dosage & Timing, Duration/Status), pre-printed letterhead mode (`defaultLetterheadTopMarginMm`), active Rx schedule filtering (`START`/`CONTINUE` only), distinct audit warning box for discontinued drugs, and counter keyboard shortcuts (`Enter` to sign/print, `Esc` to return to draft).
- **💊 Rapid Dosage & Timing Clinical Defaults (`QOL-05`)** — Instant 1-tap medicine addition pre-filling clinical defaults, rapid frequency chips (`1-0-1`, `1-0-0`, `0-0-1`, `1-1-1`, `SOS`), and timing chips without rigid, hardcoded whole-course disease presets.
- **🔔 Multi-Chamber Queue Sound Announcer (`P10`)** — In-browser dual-tone chime (587.33 Hz → 880 Hz) and SpeechSynthesis vocal token callout ("Token N, please proceed to Dr. X") on patient dispatch, with persistent mute/unmute toggle and deduplication guard (`SoundService`).

### 🏢 Clinic Operations & Ledger Integrity
- **🔄 Prepaid Carry-Over & Patient No-Show Revisit (`QOL-03`)** — Dedicated payment type (`PaymentType.paidCarryOver`) and smart revalidation banner (`BookingCarryOverBanner`) for patients returning after missing an earlier paid visit within 30 days. Issues today's consecutive queue token with ₹0 fresh cash collection, balances physical drawer cash to the exact rupee (`CashHandoverEngine`), credits the consulting doctor their full fee slice upon completion (`RevenueEngine`), and atomically prevents double redemption.
- **⚡ Agile Reception Queue & Discretionary Chamber Dispatch (`AppointmentListScreen`)** — Top-level collapsible `CompletedConsultationsAccordion` archives finished consultations, keeping the lobby list focused on waiting patients. Clean FIFO lobby queue visibility with single-expansion controlled accordion, high-visibility `[SEND IN]` button, and reception full discretionary dispatch. Chamber occupancy collision guard alerts reception before replacing an in-consultation patient.
- **🔍 Pure Dart `PatientSearchEngine` & Scalable N-Gram Lookup (`AUDIT-08`)** — Blazing fast pure Dart search with phone normalization (strips +91, 0, whitespace), multi-word name tokenization, and 2+ character prefix n-grams (`searchTokens`) indexed in Firestore, eliminating document ceilings and supporting scale beyond 50+ records with surname and middle-name discovery.
- **⚡ 1-Tap Emergency / No-Mobile Walk-In Registration (`QOL-01`)** — Collision-resistant `99`-prefixed placeholder key generation (`AppointmentEngine.generateEmergencyDummyPhone()`) and 1-tap `[⚡ No Phone]` button in booking modal for trauma walk-ins and elderly patients without active phones.
- **📊 1-Click Client-Side Full Data Export (`IDEA-1`)** — Pure Dart RFC-4180 CSV generation engine (`DataExportEngine`) exporting 5 full datasets (Revenue & Tax Ledger, Appointments & Queue, Patient Directory, Medicine Formulary, Clinical Encounters) with Indian date format (`DD-MM-YYYY`) and local browser download (`dart:js_interop`) ensuring zero PHI leaves the clinic.
- **🔐 Cloud-Synced Security PIN Store & Multi-Terminal Rotation UI (`QOL-13`)** — Persists salted SHA-256 PIN hashes in `clinic_config/security`, synchronizing credential updates across all clinic terminals in real time with 2-step verification (`SecuritySettingsDialog`).
- **⌨️ Keyboard-First Walk-In Registration (`AddAppointmentDialog`)** — 100% mouse-free counter operation: Tab focus progression, physical hotkey Sex toggle (`M`/`F`/`O` and arrows) with no accidental Male default, 10-digit auto-fill search jumping straight to doctor selection, and global Enter-key booking commitment.
- **🎟️ Live Provisional Token & Estimated Wait Time Badge** — Immediately calculates and displays next queue token (`#X`) and dynamic arrival window (`~hh:mm A – hh:mm B`) upon doctor selection via pure domain `AppointmentEngine`.
- **🛑 Same-Day Duplicate Booking Guard & Family Exception** — Composite uniqueness validation `(Date + DoctorId + Normalized Patient Name + Phone)` with live amber alert banner and submit lockout preventing double bookings for the same patient, while explicitly preserving family member bookings under shared phone numbers.
- **🔄 Same-Day Return Visits & Lab Review Tokens via Reception** — Patients returning on the same day with lab reports are routed through reception desk for queue transparency and slot numbering, correctly unlocking doctor-configured free review waivers (`PaymentType.freeReview` with `daysSincePaid == 0`).
- **🔒 3-Tier Role Security & Owner Master PIN** — Counter Reception PIN (`0000`), Doctor Chamber PIN (4 digits), and Master Owner PIN (6 digits in `clinic_config`) unlocking Doctor CRUD, schedule updates, consultation fee edits, and financial ledger audits.
- **Reception Dashboard (`DashboardScreen`)** — Responsive dashboard with daily KPI cards, live queue preview, quick reception actions, and layout adaptation across mobile, laptop (1366×768 vertical budgeting), and desktop (FHD up to 1800px split panels).
- **🌐 Web-First Responsive Architecture** — Responsive Flutter app for Chrome/Edge counter PCs and Android. An iOS platform project is not currently checked in.
- **🩺 Doctor Chamber Live Board** — Read-only chamber dashboard for consultants showing live token order, active calling token status, and fee share with 1-tap access to patient clinical records and consultation encounters.
- **🛡️ Audit-Proof Ledger** — Zero deletions allowed; consecutive token sequence is preserved on screen and database.
- **🚫 Explicit "Absent / No-Show" Status** — Replaced "Cancel" with "Absent" so slots are preserved on the doctor ledger with ₹0 amount.
- **💳 Granular Payment Types** — Paid Cash, Paid UPI, Post-Pay, Free Review (strictly for returning patients of the same doctor within the doctor's configured free review window, 1:1 per paid visit), Free Family (inviolable courtesy waiver), and Unpaid (phone reservations).
- **⏱️ Asynchronous OPD Advance Booking & 1-Tap Desk Check-In** — Phone reservations (`VisitStatus.booked`) remain segregated from the doctor chamber queue until physical counter check-in; rapid 1-tap & keyboard shortcut modal (`QuickCheckInDialog`) for counter payment reconciliation.
- **🚪 Restricted Emergency Door Self-Call Runway** — Doctor chamber fallback runway (`ChamberDoorOverrideBar`) strictly capped to the next 1–2 verified lobby-checked-in patients (`waitingInLobby`) with confirmed fee/waiver, auto-hiding during active consultations.
- **🔒 Read-Only Historical Chamber Archive** — Historical calendar dates switch Doctor Chamber to read-only archive mode (`ChamberArchiveBanner`), suppressing live calling triggers and marking unresolved appointments as `Unattended / No-Show`.
- **📊 Daily Revenue Analytics & Auditing** — Real-time earnings breakdown calculated by `RevenueEngine` grouped by doctor with chamber preview mode.
- **🤝 Doctor Revenue Share Split & Fee Payout** — Configurable `doctorSharePercentage` (0–100%) on doctor profiles with owner-only access and automated fee split calculation via `RevenueEngine.calculateDoctorPayout`.
- **🧾 Upfront Cash Handover & Note Denomination Counter (`P8`)** — End-of-day closing reconciliation modal (`DailyCashHandoverDialog`) counting physical cash collected upfront at reception, with interactive currency note calculator (`₹500`, `₹200`, `₹100`, `₹50`, `₹20`, `₹10`), live discrepancy analysis, printable handover slip, and `refundStatus` tracking (`'none'`, `'pending_refund'`, `'refunded'`) to avoid ghost discrepancies on doctor absence session close.
- **⚡ Offline Queue Fallback & Broadband Dropout Resilience (`P6`)** — Silent local caching of daily appointment ledgers to `SharedPreferences` (`OfflineQueueCacheService`) preventing counter PC freezes during broadband dropouts, accompanied by persistent high-visibility amber status banners on `OwnerShell` and `AddAppointmentDialog`.
- **🕛 Automatic Midnight Date Rollover Observer** — Periodic 30-second observer in `ClinicProvider` detects overnight calendar day changes on always-on counter PCs, automatically resetting and re-subscribing live queue streams to the new date.
- **💬 WhatsApp Digital Prescription Deep Link (`P7`)** — 1-tap `wa.me` deep link delivery (`WhatsAppEngine`) generating structured clinical prescription summaries with Indian date standard (`DD-MM-YYYY`), vitals, medication schedule, and follow-up review windows.
- **📋 Doctor Medical Council Registration & Printout Footer (`P5`)** — Configurable registration number (e.g. `AMC-24891`) on doctor profiles, roster cards, and official prescription signature footer block.
- **🔢 Atomic Queue Numbers** — Race-condition-safe queue numbering per doctor and day using Firestore transactions.
- **🔴 Real-time Firestore Streams** — Live updates across counter PC and doctor chambers via Firestore listeners.

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Platforms | Web (Desktop Counter / Tablet / Mobile), Android |
| UI Framework | Flutter 3.x (Material 3 Responsive) |
| Domain Engines | Pure Dart (`RevenueEngine`, `AppointmentEngine`, `CashHandoverEngine`, `DataExportEngine`, `MedicineEngine`, `WhatsAppEngine`, `PatientSearchEngine`) |
| State Management | Provider |
| Backend / DB | Cloud Firestore (Firebase) |
| Hosting | Firebase Hosting (SPA Web App) |
| Auth & Sessions | Role-based PIN Auth + `SharedPreferences` session persistence |
| Printing | Cross-platform web print (`dart:js_interop`) & desktop/mobile stubs |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.10
- A [Firebase project](https://console.firebase.google.com/) with **Cloud Firestore** enabled
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) for configuration

### 1. Clone the repository

```bash
git clone https://github.com/0xCoderunknown/guwahatione-clinic-os.git
cd guwahatione-clinic-os
```

### 2. Configure Firebase

This repository does **not** include `lib/firebase_options.dart` — it contains secret API keys and must not be committed to version control.

Generate it for your own Firebase project:

```bash
# Install FlutterFire CLI if you haven't already
dart pub global activate flutterfire_cli

# Log in and configure
firebase login
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

This will create `lib/firebase_options.dart` and `android/app/google-services.json` automatically. See [`lib/firebase_options.dart.example`](lib/firebase_options.dart.example) and [`android/app/google-services.json.example`](android/app/google-services.json.example) for expected templates.

### 3. Set up Firestore

In your Firebase Console, the following collections are utilized:

| Collection | Purpose |
|---|---|
| `appointments` | One document per appointment (immutable, zero deletions) |
| `patients` | One document per patient (keyed by unique ID `pat_*` or legacy phone; phone serves as household contact index, stores allergies) |
| `doctors` | One document per doctor (specialty, PIN, consultation fee) |
| `counters` | Atomic sequence counters for daily queue numbering (`queue_{doctorId}_{date}`) and real-time chamber calling sync (`chamber_{doctorId}_{date}`) |
| `consultations` | Append-only longitudinal consultation encounters per patient |
| `medicines` | Master clinical catalogue of chemical compositions, brands, and strengths |
| `clinic_config` | Clinic-wide configurations, runtime flags, and cloud-synced SHA-256 PIN credentials (`security` document) |

**Firestore Indexes Configuration**:
Index definitions are tracked in [`firestore.indexes.json`](firestore.indexes.json) and linked via `firebase.json`:
- `appointments`: `doctorId` ASC + `scheduledDate` ASC
- `appointments`: `patientPhone` ASC + `scheduledDate` ASC
- `consultations`: `patientPhone` ASC + `createdAt` DESC

> **Note**: Runtime queries use single-field date/phone streaming and in-memory ordering, allowing the app to run immediately with zero composite index requirements out-of-the-box.

### 4. Install dependencies and run

```bash
flutter pub get

# Run on Desktop Browser (Chrome) — Recommended for Reception Desk & Doctor Chamber
flutter run -d chrome

# Or run on connected Android Device
flutter run
```

### 5. Deploy to Firebase Hosting (Web Platform)

```bash
# Build production web bundle
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## ⚙️ Configuration & Access PINs

### Access PINs & Cryptographic Storage
* All access PINs are cryptographically evaluated and persisted using domain-salted **SHA-256 hashes** (`AuthProvider.hashPin`), ensuring zero plaintext exposure in browser storage or device memory.
* **Clinic Owner / Master Admin:** `849201` (6-digit PIN: doctor CRUD, fee schedule overrides, financial analytics & audits)
* **Reception Desk:** `0000` (4-digit PIN: counter booking, queue management, physical arrival check, cash collection)
* **Doctor Chamber View:** Default `1234` (4-digit PIN: configurable per doctor in Doctor management, consultation encounter)

All tunable constants live in [`lib/utils/app_constants.dart`](lib/utils/app_constants.dart) and runtime clinic settings in [`lib/config/clinic_config.dart`](lib/config/clinic_config.dart):

```dart
class AppConstants {
  // Clinic holiday dates stored as ISO strings (presented as DD-MM-YYYY in UI).
  static const List<String> blockedDates = [
    // '2026-10-02',
  ];
}
```

---

## 📁 Project Structure

```text
docs/
├── MASTER_BACKLOG.md                       # Master backlog, roadmap & technical reference
└── SCHEMA_AND_MODELS.md                     # Master data dictionary for Firestore collections & models
lib/
├── main.dart                                # Entry point, AuthGate, theme & MultiProvider setup
├── firebase_options.dart                    # 🔒 Secret — not in git (see .gitignore)
├── config/
│   └── clinic_config.dart                   # Feature flags & runtime clinic operational configurations
├── core/
│   └── engines/
│       ├── engines.dart                     # Central barrel export for all domain engines
│       ├── revenue_engine.dart              # Pure realized revenue math, chamber KPIs & doctor rollups
│       ├── appointment_engine.dart          # Doctor-configured free review eligibility, fee resolution & queue states
│       ├── cash_handover_engine.dart        # End-of-day closing reconciliation & denomination counter
│       ├── data_export_engine.dart          # Pure Dart RFC-4180 CSV serializer for revenue, queue, patient & Rx ledgers
│       ├── medicine_engine.dart             # Chemical search scoring, default OPD regimens & Rx segregation
│       ├── patient_search_engine.dart       # Pure Dart patient lookup, phone normalization & relevance ranking
│       └── whatsapp_engine.dart             # Structured clinical summary formatting & wa.me deep links
├── models/
│   ├── models.dart                          # Central barrel file exporting all domain models
│   ├── appointment.dart                     # Appointment schema, PaymentType & AppointmentStatus
│   ├── chamber_session.dart                 # Pure domain model for 2-way doctor-reception chamber handshake
│   ├── consultation.dart                    # Immutable encounter schema with active/stopped getters
│   ├── diagnostic_investigation.dart        # Lab review (performedDate) & OrderedTest schemas
│   ├── doctor.dart                          # Doctor schema with Chamber PIN, fee, and searchPreference
│   ├── medicine.dart                        # Master catalogue decoupling composition from trade brand + clinical defaults
│   ├── patient.dart                         # Patient schema with phone-keying & allergies
│   ├── patient_review_eligibility.dart      # Encapsulates per-doctor free review eligibility evaluation result
│   ├── prescription_item.dart               # PrescriptionItem state machine (START/CONTINUE/STOP)
│   ├── prescription_template.dart           # OPD regimen bundles & template application result
│   ├── user_role.dart                       # UserRole & UserSession models
│   └── vitals.dart                          # Vitals schema (BP, pulse, SpO2, temp, weight)
├── providers/
│   ├── auth_provider.dart                   # PIN authentication & SharedPreferences session
│   ├── clinic_provider.dart                 # Unified facade over live streams, consultations & delegates
│   └── delegates/                           # Decomposed domain controllers
│       ├── catalogue_delegate.dart          # Master formulary curation, search & deduplication
│       ├── doctor_state_delegate.dart       # Doctor roster, PIN verification & leave schedules
│       └── live_queue_delegate.dart         # Live queue streaming, offline caching & midnight rollover
├── services/
│   ├── services.dart                        # Central barrel export across all services
│   ├── booking_service.dart                 # Atomic queue bookings, counter transactions & queries
│   ├── consultation_service.dart            # Append-only clinical encounter events & timeline queries
│   ├── chamber_service.dart                 # Zero-touch doctor chamber calling sync & session lifecycle
│   ├── catalogue_service.dart               # Formulary curation, deterministic seeds & deduplication
│   ├── doctor_service.dart                  # Doctor roster & chamber credential management
│   ├── patient_service.dart                 # Patient demographics & allergy directory queries
│   ├── security_service.dart                # Cloud-synchronized SHA-256 PIN credentials store
│   ├── offline_queue_cache_service.dart     # Silent local queue caching & dropout resilience
│   ├── sound_service.dart                   # In-clinic queue chime & vocal token callout (mute-persistent, deduplication-guarded)
│   └── firestore_paths.dart                 # Centralized type-safe collection & counter path builders
├── screens/
│   ├── screens.dart                         # Central barrel export across all screens
│   ├── login_screen.dart                    # Role selector shell (Doctor Chamber vs Reception Desk)
│   ├── owner_shell.dart                     # Responsive shell (Desktop rail vs mobile bar)
│   ├── dashboard_screen.dart                # Reception KPI overview cards & 1-tap "Call In"
│   ├── appointment_list_screen.dart         # Live queue, absent marking, payment updates & "Call In"
│   ├── patient_directory_screen.dart        # Multi-doctor patient lookup with zero-egress search & walk-in shortcut
│   ├── doctor_chamber_screen.dart           # Real-time zero-touch chamber sync board & active token badge
│   ├── consultation_encounter_screen.dart   # Self-contained 5-step encounter coordinator scaffold with dock & alert
│   ├── prescription_print_screen.dart       # High-contrast A4/A5 print preview with letterhead toggle & WhatsApp share
│   ├── medicine_catalogue_screen.dart       # Admin medicine catalogue management & seeding
│   ├── doctor_list_screen.dart              # Doctor roster, PIN display & chamber preview card
│   ├── add_doctor_screen.dart               # Self-contained doctor registration, fee & chamber PIN form
│   ├── doctor_daily_details_screen.dart     # Daily patient and fee breakdown details table
│   └── statistics_screen.dart               # Financial audit & doctor payout summary with KPI cards
├── widgets/
│   ├── widgets.dart                         # Central barrel export across all widget domains
│   ├── common/                              # Reusable atomic UI primitives & tokens
│   │   ├── appointment_status_chip.dart     # Standardized appointment status chips
│   │   ├── clinic_date_nav_bar.dart         # Standardized date navigation header
│   │   ├── metric_kpi_card.dart             # Unified vertical & horizontal KPI metrics tile
│   │   ├── owner_shell_app_bar.dart         # Responsive top navigation bar with live stats & sound toggle
│   │   ├── payment_badge.dart               # Visual payment type badges
│   │   ├── section_card.dart                # Collapsible animated section cards with badges & actions
│   │   └── token_badge.dart                 # Uniform token sequence badges
│   ├── patient/                             # Patient lookup & directory card components
│   │   ├── doctor_consultation_accordion.dart # Expandable consultation history card per doctor
│   │   └── patient_lookup_card.dart         # Master patient card with doctor consultation accordions & walk-in shortcut
│   ├── booking/                             # Reception appointment booking dialog components
│   │   ├── add_appointment_dialog.dart      # Rapid booking modal with patient history search
│   │   ├── booking_date_and_mode_section.dart # Date picker and walk-in vs advance booking toggle
│   │   ├── booking_dialog_actions.dart      # Booking modal action buttons & submission triggers
│   │   ├── booking_duplicate_warning_banner.dart # Same-day duplicate booking guard banner
│   │   ├── booking_eligibility_banner.dart  # 14-day policy warning banner & static confirmation dialog
│   │   ├── booking_offline_banner.dart      # Broadband dropout warning banner for walk-in bookings
│   │   ├── booking_patient_fields.dart      # Phone search, patient name, age, and gender fields
│   │   ├── booking_payment_section.dart     # Paid, Free Review, and Family courtesy payment radio section
│   │   ├── booking_success_snackbar.dart    # Post-booking confirmation snackbar with token badge
│   │   └── quick_check_in_dialog.dart       # 1-tap & keyboard shortcut counter check-in & reconciliation
│   ├── queue/                               # Reception queue management
│   │   ├── accordion_dispatch_section.dart  # Doctor ChamberSession stream, status banners & dispatch trigger
│   │   ├── accordion_status_actions.dart    # Mark complete, audit-proof mark absent modal & WhatsApp digital Rx
│   │   ├── appointment_accordion.dart       # Live token card coordinator with payment chips & check-in alert
│   │   ├── completed_consultations_accordion.dart # Collapsible archive for completed patient consultations
│   │   └── queue_chamber_dispatch_action.dart # Action button to dispatch patient to doctor chamber
│   ├── chamber/                             # Doctor chamber catalog screen components
│   │   ├── chamber_app_bar.dart             # Header with live time, sync indicator, and PIN logout
│   │   ├── chamber_archive_banner.dart      # Read-only shift closed archive banner for historical dates
│   │   ├── chamber_control_banner.dart      # 2-way handshake control banner (Call Next, In-Consultation badge)
│   │   ├── chamber_door_override_bar.dart   # Restricted emergency door self-call runway (top 1-2 lobby tokens)
│   │   ├── chamber_metrics_grid.dart        # Real-time KPI summary cards (Total, In Queue, Revenue)
│   │   ├── chamber_queue_header.dart        # Queue header, empty state, and sequential token list
│   │   └── chamber_token_card.dart          # Token tile with status badge & consultation launcher
│   ├── dashboard/                           # Command center reception dashboard components
│   │   ├── cash_denomination_counter_section.dart # Indian currency denomination input grid
│   │   ├── daily_cash_handover_dialog.dart  # End-of-day closing reconciliation & note denomination counter
│   │   ├── dashboard_header_bar.dart        # Reception header bar with quick action chips & cash handover
│   │   ├── dashboard_kpi_strip.dart         # Responsive daily KPI cards with automatic breakpoints
│   │   ├── dashboard_queue_card.dart        # Live queue preview with offline cache status badge
│   │   ├── dashboard_queue_item_row.dart    # Individual live queue patient item row
│   │   ├── queue_doctor_filter_bar.dart     # Doctor filter chip bar for live queue partitioning
│   │   ├── upcoming_bookings_section.dart   # Advance phone reservations runway
│   │   └── dashboard_doctor_roster_card.dart# Doctor roster with live chamber calling status
│   ├── doctor/                              # Doctor roster & configuration components
│   │   └── doctor_leave_calendar_section.dart # Doctor leave date picker & blocked dates management
│   ├── encounter/                           # Step-by-step clinical encounter widgets
│   │   ├── advice_and_orders_section.dart   # Step 5: Advice, lab test orders, and quick follow-up chips
│   │   ├── diagnostic_review_section.dart   # Step 3: Diagnostic investigation review tracker
│   │   ├── encounter_dialogs.dart           # Modal dialogs & bottom sheets (allergies, labs, stop reasons, history)
│   │   ├── encounter_form_state.dart        # Encapsulated encounter controllers, state, and builders
│   │   ├── patient_header_section.dart      # Step 1: Patient header & demographics summary
│   │   ├── rx_reconciliation_section.dart   # Step 4: Coordinator for Rx reconciliation, search, and staging
│   │   ├── vitals_and_exam_section.dart     # Step 2: Vitals entry grid, collapsible findings pills & exam notes
│   │   └── rx/                              # Specialized prescribing sub-components
│   │       ├── rx_template_presets_bar.dart # 1-tap OPD clinical bundle presets chip bar (P9)
│   │       ├── staged_medicine_form.dart    # Prefilled OPD defaults, dosage chips & chronic toggle
│   │       ├── rx_search_results_view.dart  # Chemical salt + trade brand search pills & pickers
│   │       └── reconciliation_item_row.dart # Active regimen row with 1-tap CONTINUE/STOP actions
│   ├── print/                               # High-contrast monochrome A4/A5 prescription print components
│   │   ├── print_header_and_demographics.dart # Header with clinic details, patient demographics & clinical vitals snapshot
│   │   ├── print_medications_table.dart     # Active Rx table and discontinued medications audit box
│   │   ├── print_orders_and_footer.dart     # Diagnostic orders, lifestyle advice & doctor signature
│   │   └── token_receipt_dialog.dart        # Thermal receipt preview dialog for counter check-in
│   └── catalogue/                           # Master medicine catalogue management
│       ├── add_medicine_dialog.dart         # Modal dialog to add new formulary entries
│       ├── catalogue_header_and_stats.dart  # Formulary metrics bar (total, brands, molecules)
│       ├── catalogue_medicine_card.dart     # Individual medicine brand card with actions
│       └── catalogue_search_toolbar.dart    # Real-time search and filter toolbar
└── utils/
    ├── app_constants.dart                   # Default fee, blocked clinic dates
    ├── default_medicines.dart               # Canonical essential OPD medications with deterministic IDs
    ├── formatters.dart                      # Centralized date, time, and currency formatters (AppFormatters)
    ├── platform_print.dart                  # Unified cross-platform print interface
    ├── platform_print_web.dart              # Web print implementation using dart:js_interop
    ├── platform_print_stub.dart             # Native desktop/mobile fallback print stub
    ├── platform_sound.dart                  # Unified cross-platform sound interface
    ├── platform_sound_web.dart              # Web Audio API chime & browser SpeechSynthesis implementation
    ├── platform_sound_stub.dart             # Non-web platform sound no-op stub
    ├── platform_url.dart                    # Cross-platform URL launcher interface
    ├── platform_url_web.dart                # Web window.open via dart:js_interop
    └── platform_url_stub.dart               # Non-web platform URL stub
```

---

## 🧪 Testing

The repository maintains an active automated testing suite covering domain business rules, serialization models, print schedule filtering, offline caching, and clinical state machines:

```bash
# Run all automated tests
flutter test
```

- **375 Automated Unit & Widget Tests:** Sub-second execution covering realized revenue math, cash drawer handover & note denomination calculations with upfront collection & refund tracking, offline queue caching, WhatsApp clinical formatting & deep linking, doctor-configurable free review eligibility terms (0 to 30 days) including same-day lab reviews, prescription reconciliation (`START`/`CONTINUE`/`STOP`) with 1-click `[CARRY FORWARD]` longitudinal history, pre-sign prescription preview gate & confirmation sign-off workflows (`QOL-19`), prepaid carry-over revisit revalidation (`QOL-03`), natural dosage & timing synthesis, staged medicine discard guard, multi-modal duration bounds checks, in-clinic sound chime mute/unmute persistence, chemical search scoring, pure Dart `PatientSearchEngine` relevance ranking, asynchronous booking/check-in, emergency door runways, historical shift archiving, automatic midnight date rollover observer, doctor revenue share split & fee payout math, modular queue dispatch & status workflows, 3-tier auth role guards with SHA-256 PIN hashing, chamber collision locks & single-occupant integrity, print schedule segregation, reception token cap threshold transitions, mobile walk-in FAB & responsive queue cards, multi-doctor patient lookup with zero-egress search, doctor sitting day validations, and date picker epoch lower bounds — all with 100% pass rate.
- **Continuous Integration:** Automated test execution and `flutter analyze` run on every push and pull request via GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

---

## 🛠️ Maintenance & Governance

This project is **100% coded and maintained by AI**, directed by the human Product Manager & Tester.
- For AI operating constitution, core clinical invariants, and engineering guardrails, see [AGENTS.md](AGENTS.md).
- For product roadmap, architecture reference, and feature backlog, see [docs/MASTER_BACKLOG.md](docs/MASTER_BACKLOG.md).
- For Firestore schemas and data contracts, see [docs/SCHEMA_AND_MODELS.md](docs/SCHEMA_AND_MODELS.md).

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgements

Built for [GuwahatiOne](https://guwahatiOne.com) · Powered by [Flutter](https://flutter.dev) & [Firebase](https://firebase.google.com)
