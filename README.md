# 🏥 GuwahatiOne Clinic OS

> **Open-source, web-first clinic & chamber management platform featuring an append-only longitudinal prescription architecture, audit-proof token ledgers, and real-time doctor chamber catalog boards.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)

A web-first clinic and chamber management system built for standalone polyclinics, pharmacy-attached consultation rooms, and multi-doctor outpatient practices. Engineered for [GuwahatiOne](https://guwahatiOne.com).

---

## ⚡ ClinicOS in 60 Seconds: The Story of Token #12

> ### 📅 Visit 1 — The First Encounter
> **8:00 PM · Token #12**  
> You call the clinic and receive Token #12. You walk in. The doctor’s screen already has your name, age, and vitals. He prescribes 3 medicines and orders 4 tests. You leave with a crisp, printed prescription.
> 
> ### 🔄 Visit 2 — 1 Week Later (Day 7)
> **Free Review · Zero Paperwork**  
> Reception notes your visit is within 14 days—your review is free. You walk into the chamber. The doctor greets you by name. He doesn't ask for your crumpled old prescription; it's already on his screen. He reviews your lab reports, marks one drug as **STOPPED**, adjusts another, and prints your updated treatment plan.
> 
> ---
> **No lost papers. No memory tests. No clunky hospital ERPs. Just continuous outpatient care.**

---

## 💡 The Core Philosophy

ClinicOS is built around two core clinical and operational principles:

1. **Longitudinal Clinical Records Over Transient Paper Artifacts:**  
   ClinicOS handles the patient's continuous clinical history—it does **not** try to run a pharmacy ERP, retail inventory, or billing ledger. The printed prescription is merely a transient paper artifact; the continuous, append-only longitudinal clinical record across visits is the true product.
2. **Audit-Proof Operational Ledger (Zero Deletions):**  
   Visiting medical consultants often suspect clinic receptionists of cheating (*"I saw 10 patients today, but the receptionist paid me for 8 and claimed 2 were free reviews"*). In ClinicOS, token numbers ($1 \dots N$) are strictly consecutive and immutable. If a patient leaves, they are marked **`[ABSENT] ₹0`**—slots are never deleted, ensuring complete transparency between reception desk and consulting physicians.

---

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
  ↳ 1-tap CONTINUE or STOP (with reason) for past regimens + START new acute/chronic therapies
        ↓
[ Step 5: Diagnostic Orders & Follow-Up ]
  ↳ Order future labs + lifestyle/diet advice + review date chips (3d, 7d, 14d, 1m, 3m)
```

---

## ✨ Features

### 📋 Longitudinal Clinical Records & Chamber Prescribing
- **🤝 Doctor-Reception 2-Way Chamber Handshake** — Real-time state-machine synchronization (`counters/chamber_{doctorId}_{date}`) between reception desk and doctor chamber. Doctors control pacing via "CONSULTATION END" and "NEXT PATIENT", preventing patient misidentification and counter confusion while providing a built-in 10-second breather. Includes Reception Speed Bump protection and Doctor Emergency Safety Valve override.
- **🇮🇳 Indian Date & Demographics Format (`DD-MM-YYYY`)** — Complete UI and print formatting adherence to Indian clinical standards (`dd-MM-yyyy` / `dd-MM-yy`) across token accordions, appointment pickers, audit cards, and prescription headers.
- **💊 Clinical Dosage & Duration Presets (`MedicineEngine`)** — Automatically fills standard outpatient dosage, frequency, timing, and duration presets for common medication categories (PPIs, antihypertensives, antidiabetics, statins, antibiotics, liquids, topicals) upon selection.
- **📑 Collapsible Encounter Sections** — Collapsible Step 2 (Vitals & Clinical Examination) and Step 4 (Medication Prescribing & Reconciliation) with summary chips to minimize page scrolling.
- **🏷️ Doctor Prescribing Search Preferences** — Configurable `searchPreference` (`brandFirst` vs `compositionFirst`) with dual-mode ranking in `MedicineEngine` and an inline `[🏷️ Brand | 🧪 Salt]` toggle.
- **Strict 5-Step Clinical Encounter (`ConsultationEncounterScreen`)** — Guides physicians through allergies, vitals, past labs, medication reconciliation, and advice.
- **Medication Reconciliation State Machine** — Explicit lifecycle states (`START`, `CONTINUE`, `STOP`) on prescription items. 1-tap continuation for ongoing chronic regimens (`durationDays = null`) and explicit discontinuation documenting clinical `stopReason`.
- **Composition-First Medicine Engine (`MedicineEngine`)** — Prioritizes chemical molecule matches at the top with associated clinic trade brands grouped underneath.
- **Unlisted Medicine Support (`unlistedName`)** — Doctors can prescribe outside or unlisted medications not currently in the clinic catalogue.
- **Essential OPD Medicines Preloaded (`defaultEssentialMedicines`)** — Standard OPD medications (Dolo 650, Calpol 650, Augmentin 625 Duo, Moxikind-CV, Azee 500, Pan 40, Telma 40, etc.) with deterministic document IDs (`med_*`) to prevent duplicates on initial seed.
- **Admin vs. Prescriber Catalogue Separation (`MedicineCatalogueScreen`)** — Dedicated administration interface in reception shell for clinic owners to curate products and active compositions, with role guards preventing chamber prescriber edits.
- **Catalogue Deduplication** — Identifies and removes duplicate drug entries with identical names, compositions, and strengths from Firestore.
- **Clean Prescription Print Output (`PrescriptionPrintScreen`)** — High-contrast monochrome print layout supporting **A4** and **A5** paper, pre-printed letterhead mode (reserved 130px top margin), active Rx schedule filtering (`START`/`CONTINUE` only), and distinct audit warning box for discontinued drugs.

### 🏢 Clinic Operations & Ledger Integrity
- **⚡ Agile Reception Queue & Discretionary Chamber Dispatch (`AppointmentListScreen`)** — Top-level collapsible `CompletedConsultationsAccordion` archives finished consultations, keeping the lobby list focused on waiting patients. Single-expansion controlled accordion with high-visibility `[SEND IN]` button. Chamber occupancy collision guard alerts reception before replacing an in-consultation patient. Late/bypassed tokens (`[BYPASSED / LATE]`) maintain their permanent token and queue visibility without destructive "Skip" states or database mutations.
- **⌨️ Keyboard-First Walk-In Registration (`AddAppointmentDialog`)** — 100% mouse-free counter operation: Tab focus progression, physical hotkey Sex toggle (`M`/`F`/`O` and arrows) with no accidental Male default, 10-digit auto-fill search jumping straight to doctor selection, and global Enter-key booking commitment.
- **🎟️ Live Provisional Token & Estimated Wait Time Badge** — Immediately calculates and displays next queue token (`#X`) and dynamic arrival window (`~hh:mm A – hh:mm B`) upon doctor selection via pure domain `AppointmentEngine`.
- **🛑 Same-Day Duplicate Booking Guard & Family Exception** — Composite uniqueness validation `(Date + DoctorId + Normalized Patient Name + Phone)` with live amber alert banner and submit lockout preventing double bookings for the same patient, while explicitly preserving family member bookings under shared phone numbers.
- **🔒 3-Tier Role Security & Owner Master PIN** — Counter Reception PIN (`0000`), Doctor Chamber PIN (4 digits), and Master Owner PIN (6 digits in `clinic_config`) unlocking Doctor CRUD, schedule updates, consultation fee edits, and financial ledger audits.
- **Reception Dashboard (`DashboardScreen`)** — Responsive dashboard with daily KPI cards, live queue preview, quick reception actions, and layout adaptation across mobile, laptop (1366×768 vertical budgeting), and desktop (FHD up to 1800px split panels).
- **🌐 Web-First Responsive Architecture** — Responsive Flutter app for Chrome/Edge counter PCs and Android. An iOS platform project is not currently checked in.
- **🩺 Doctor Chamber Live Board** — Read-only chamber dashboard for consultants showing live token order, active calling token status, and fee share with 1-tap access to patient clinical records and consultation encounters.
- **🛡️ Audit-Proof Ledger** — Zero deletions allowed; consecutive token sequence is preserved on screen and database.
- **🚫 Explicit "Absent / No-Show" Status** — Replaced "Cancel" with "Absent" so slots are preserved on the doctor ledger with ₹0 amount.
- **💳 Granular Payment Types** — Paid Cash, Paid UPI, Post-Pay, Free Review (strictly for returning patients of same doctor within 14 days), Free Family (inviolable courtesy waiver), and Unpaid (phone reservations).
- **⏱️ Asynchronous OPD Advance Booking & 1-Tap Desk Check-In** — Phone reservations (`VisitStatus.booked`) remain segregated from the doctor chamber queue until physical counter check-in; rapid 1-tap & keyboard shortcut modal (`QuickCheckInDialog`) for counter payment reconciliation.
- **🚪 Restricted Emergency Door Self-Call Runway** — Doctor chamber fallback runway (`ChamberDoorOverrideBar`) strictly capped to the next 1–2 verified lobby-checked-in patients (`waitingInLobby`) with confirmed fee/waiver, auto-hiding during active consultations.
- **🔒 Read-Only Historical Chamber Archive** — Historical calendar dates switch Doctor Chamber to read-only archive mode (`ChamberArchiveBanner`), suppressing live calling triggers and marking unresolved appointments as `Unattended / No-Show`.
- **📊 Daily Revenue Analytics & Auditing** — Real-time earnings breakdown calculated by `RevenueEngine` grouped by doctor with chamber preview mode.
- **⚡ Offline Queue Fallback Cache (`P6`)** — Silent local caching of daily appointment ledgers to `SharedPreferences` (`OfflineQueueCacheService`) preventing counter PC freezes during broadband dropouts, accompanied by an automatic amber status badge.
- **💬 WhatsApp Digital Prescription Deep Link (`P7`)** — 1-tap `wa.me` deep link delivery (`WhatsAppEngine`) generating structured clinical prescription summaries with Indian date standard (`DD-MM-YYYY`), vitals, medication schedule, and follow-up review windows.
- **🧾 Daily Cash Handover & Note Denomination Counter (`P8`)** — End-of-day closing reconciliation modal (`DailyCashHandoverDialog`) with doctor-wise cash breakdown, interactive currency note calculator (`₹500`, `₹200`, `₹100`, `₹50`, `₹20`, `₹10`), live discrepancy analysis, and printable handover slip.
- **📋 Doctor Medical Council Registration & Printout Footer (`P5`)** — Configurable registration number (e.g. `AMC-24891`) on doctor profiles, roster cards, and official prescription signature footer block.
- **🔢 Atomic Queue Numbers** — Race-condition-safe queue numbering per doctor and day using Firestore transactions.
- **🔴 Real-time Firestore Streams** — Live updates across counter PC and doctor chambers via Firestore listeners.

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Platforms | Web (Desktop Counter / Tablet / Mobile), Android |
| UI Framework | Flutter 3.x (Material 3 Responsive) |
| Domain Engines | Pure Dart (`RevenueEngine`, `AppointmentEngine`, `MedicineEngine`, `WhatsAppEngine`) |
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
| `patients` | One document per patient (keyed by phone number, stores allergies) |
| `doctors` | One document per doctor (specialty, PIN, consultation fee) |
| `counters` | Atomic sequence counters for daily queue numbering (`queue_{doctorId}_{date}`) and real-time chamber calling sync (`chamber_{doctorId}_{date}`) |
| `consultations` | Append-only longitudinal consultation encounters per patient |
| `medicines` | Master clinical catalogue of chemical compositions, brands, and strengths |

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

### Default PINs (Out of the Box)
* **Clinic Owner / Master Admin:** `123456` (6-digit PIN: doctor CRUD, fee schedule overrides, financial analytics & audits)
* **Reception Desk:** `0000` (4-digit PIN: counter booking, queue management, physical arrival check, cash collection)
* **Doctor Chamber View:** Default `1234` (4-digit PIN: configurable per doctor in Doctor management, consultation encounter)

All tunable constants live in [`lib/utils/app_constants.dart`](lib/utils/app_constants.dart):

```dart
class AppConstants {
  // Global fallback consultation fee
  static const int defaultConsultationFee = 500;

  // Add clinic holiday dates in 'YYYY-MM-DD' format.
  static const List<String> blockedDates = [
    // '2026-10-02',
  ];
}
```

---

## 📁 Project Structure

```text
docs/
├── PRODUCT_VISION_AND_WORKFLOW.md           # Master clinical encounter blueprint & real-world OPD intent
├── PRODUCT_ROADMAP.md                       # 4-state lifecycle roadmap with anti-goals & backlog
└── SCHEMA_AND_MODELS.md                     # Master data dictionary for Firestore collections & models
lib/
├── main.dart                                # Entry point, AuthGate, theme & MultiProvider setup
├── firebase_options.dart                    # 🔒 Secret — not in git (see .gitignore)
├── core/
│   └── engines/
│       ├── engines.dart                     # Central barrel export for all domain engines
│       ├── revenue_engine.dart              # Pure realized revenue math, chamber KPIs, doctor rollups & cash handover
│       ├── appointment_engine.dart          # 14-day free review eligibility, fee resolution & queue states
│       ├── medicine_engine.dart             # Chemical search scoring, default OPD regimens & Rx segregation
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
│   ├── patient_review_eligibility.dart      # Encapsulates 14-day free review evaluation result
│   ├── prescription_item.dart               # PrescriptionItem state machine (START/CONTINUE/STOP)
│   ├── user_role.dart                       # UserRole & UserSession models
│   └── vitals.dart                          # Vitals schema (BP, pulse, SpO2, temp, weight)
├── providers/
│   ├── auth_provider.dart                   # PIN authentication & SharedPreferences session
│   └── clinic_provider.dart                 # Real-time streams, chamber sync, consultations & offline queue fallback
├── services/
│   ├── booking_service.dart                 # Atomic queue bookings, counter transactions & queries
│   ├── consultation_service.dart            # Append-only clinical encounter events & timeline queries
│   ├── chamber_service.dart                 # Zero-touch doctor chamber calling sync & session lifecycle
│   ├── catalogue_service.dart               # Formulary curation, deterministic seeds & deduplication
│   ├── doctor_service.dart                  # Doctor roster & chamber credential management
│   ├── patient_service.dart                 # Patient demographics & allergy directory queries
│   ├── offline_queue_cache_service.dart     # Silent local queue caching & dropout resilience
│   └── firestore_paths.dart                 # Centralized type-safe collection & counter path builders
├── screens/
│   ├── login_screen.dart                    # Role selector shell (Doctor Chamber vs Reception Desk)
│   ├── owner_shell.dart                     # Responsive shell (Desktop rail vs mobile bar)
│   ├── dashboard_screen.dart                # Reception KPI overview cards & 1-tap "Call In"
│   ├── appointment_list_screen.dart         # Live queue, absent marking, payment updates & "Call In"
│   ├── doctor_chamber_screen.dart           # Real-time zero-touch chamber sync board & active token badge
│   ├── consultation_encounter_screen.dart   # Self-contained 5-step encounter coordinator scaffold with dock & alert
│   ├── prescription_print_screen.dart       # High-contrast A4/A5 print preview with letterhead toggle & WhatsApp share
│   ├── medicine_catalogue_screen.dart       # Admin medicine catalogue management & seeding
│   ├── doctor_list_screen.dart              # Doctor roster, PIN display & chamber preview card
│   ├── add_doctor_screen.dart               # Self-contained doctor registration, fee & chamber PIN form
│   ├── doctor_daily_details_screen.dart     # Daily patient and fee breakdown details table
│   ├── login_screen.dart                    # Self-contained doctor chamber & reception desk PIN authentication
│   └── statistics_screen.dart               # Financial audit & doctor payout summary with KPI cards
├── widgets/
│   ├── widgets.dart                         # Central barrel export across all widget domains
│   ├── common/                              # Reusable atomic UI primitives & tokens
│   │   ├── appointment_status_chip.dart     # Standardized appointment status chips
│   │   ├── clinic_date_nav_bar.dart         # Standardized date navigation header
│   │   ├── metric_kpi_card.dart             # Unified vertical & horizontal KPI metrics tile
│   │   ├── payment_badge.dart               # Visual payment type badges
│   │   ├── section_card.dart                # Collapsible animated section cards with badges & actions
│   │   └── token_badge.dart                 # Uniform token sequence badges
│   ├── booking/                             # Reception appointment booking dialog components
│   │   ├── add_appointment_dialog.dart      # Rapid booking modal with patient history search
│   │   ├── booking_eligibility_banner.dart  # 14-day policy warning banner & static confirmation dialog
│   │   ├── booking_patient_fields.dart      # Phone search, patient name, age, and gender fields
│   │   ├── booking_payment_section.dart     # Paid, Free Review, and Family courtesy payment radio section
│   │   └── quick_check_in_dialog.dart       # 1-tap & keyboard shortcut counter check-in & reconciliation
│   ├── queue/                               # Reception queue management
│   │   ├── accordion_dispatch_section.dart  # Doctor ChamberSession stream, status banners & dispatch trigger
│   │   ├── accordion_status_actions.dart    # Mark complete, audit-proof mark absent modal & WhatsApp digital Rx
│   │   ├── appointment_accordion.dart       # Live token card coordinator with payment chips & check-in alert
│   │   └── completed_consultations_accordion.dart # Collapsible archive for completed patient consultations
│   ├── chamber/                             # Doctor chamber catalog screen components
│   │   ├── chamber_app_bar.dart             # Header with live time, sync indicator, and PIN logout
│   │   ├── chamber_archive_banner.dart      # Read-only shift closed archive banner for historical dates
│   │   ├── chamber_control_banner.dart      # 2-way handshake control banner (Call Next, In-Consultation badge)
│   │   ├── chamber_door_override_bar.dart   # Restricted emergency door self-call runway (top 1-2 lobby tokens)
│   │   ├── chamber_metrics_grid.dart        # Real-time KPI summary cards (Total, In Queue, Revenue)
│   │   ├── chamber_queue_header.dart        # Queue header, empty state, and sequential token list
│   │   └── chamber_token_card.dart          # Token tile with status badge & consultation launcher
│   ├── dashboard/                           # Command center reception dashboard components
│   │   ├── daily_cash_handover_dialog.dart  # End-of-day closing reconciliation & note denomination counter
│   │   ├── dashboard_header_bar.dart        # Reception header bar with quick action chips & cash handover
│   │   ├── dashboard_kpi_strip.dart         # Responsive daily KPI cards with automatic breakpoints
│   │   ├── dashboard_queue_card.dart        # Live queue preview with offline cache status badge
│   │   └── dashboard_doctor_roster_card.dart# Doctor roster with live chamber calling status
│   ├── encounter/                           # Step-by-step clinical encounter widgets
│   │   ├── advice_and_orders_section.dart   # Step 5: Advice, lab test orders, and quick follow-up chips
│   │   ├── diagnostic_review_section.dart   # Step 3: Diagnostic investigation review tracker
│   │   ├── encounter_dialogs.dart           # Modal dialogs & bottom sheets (allergies, labs, stop reasons, history)
│   │   ├── encounter_form_state.dart        # Encapsulated encounter controllers, state, and builders
│   │   ├── patient_header_section.dart      # Step 1: Patient header & demographics summary
│   │   ├── rx_reconciliation_section.dart   # Step 4: Coordinator for Rx reconciliation, search, and staging
│   │   ├── vitals_and_exam_section.dart     # Step 2: Vitals entry grid, collapsible findings pills & exam notes
│   │   └── rx/                              # Specialized prescribing sub-components
│   │       ├── staged_medicine_form.dart    # Prefilled OPD defaults, dosage chips & chronic toggle
│   │       ├── rx_search_results_view.dart  # Chemical salt + trade brand search pills & pickers
│   │       └── reconciliation_item_row.dart # Active regimen row with 1-tap CONTINUE/STOP actions
│   ├── print/                               # High-contrast monochrome A4/A5 prescription print components
│   │   ├── print_header_and_demographics.dart # Header with clinic details, patient demographics & clinical vitals snapshot
│   │   ├── print_medications_table.dart     # Active Rx table and discontinued medications audit box
│   │   └── print_orders_and_footer.dart     # Diagnostic orders, lifestyle advice & doctor signature
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

- **122 Automated Unit & Widget Tests:** Sub-4s execution covering realized revenue math, cash drawer handover & note denomination calculations, offline queue caching, WhatsApp clinical formatting & deep linking, 14-day free review eligibility boundaries, prescription reconciliation (`START`/`CONTINUE`/`STOP`), chemical search scoring, asynchronous booking/check-in, emergency door runways, historical shift archiving, modular queue dispatch & status workflows, and print schedule segregation with 100% pass rate.
- **Continuous Integration:** Automated test execution and `flutter analyze` run on every push and pull request via GitHub Actions ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

---

## 🤝 Contributing

We welcome contributions of all sizes. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgements

Built for [GuwahatiOne](https://guwahatiOne.com) · Powered by [Flutter](https://flutter.dev) & [Firebase](https://firebase.google.com)
