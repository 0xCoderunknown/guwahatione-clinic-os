# 🏥 GuwahatiOne Clinic OS

> **Open-source, web-first clinic & chamber management platform featuring an append-only longitudinal prescription architecture, audit-proof token ledgers, and real-time doctor chamber catalog boards.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)

A web-first clinic and chamber management system built for standalone polyclinics, pharmacy-attached consultation rooms, and multi-doctor outpatient practices. Engineered for [GuwahatiOne](https://guwahatiOne.com).

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
- **Chamber Auto-Sync** — Real-time synchronization between reception and doctor chamber. When reception calls a patient, the doctor's chamber screen automatically displays the active encounter, with an incoming alert banner if another encounter is currently open.
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
- **Reception Dashboard (`DashboardScreen`)** — Responsive dashboard with daily KPI cards, live queue preview, quick reception actions, and layout adaptation across mobile, laptop, and desktop displays.
- **🌐 Web-First Responsive Architecture** — Single responsive codebase deployed to Chrome/Edge (Counter PC), Android, and iOS.
- **🩺 Doctor Chamber Live Board** — Read-only chamber dashboard for consultants showing live token order, active calling token status, and fee share with 1-tap access to patient clinical records and consultation encounters.
- **🔒 Role-Based PIN Authentication** — Reception PIN (`0000` default) and 4-digit Chamber PIN per doctor.
- **🛡️ Audit-Proof Ledger** — Zero deletions allowed; consecutive token sequence is preserved on screen and database.
- **🚫 Explicit "Absent / No-Show" Status** — Replaced "Cancel" with "Absent" so slots are preserved on the doctor ledger with ₹0 amount.
- **📅 Rapid Appointment Booking** — 10-digit phone search with automatic patient history, gender/sex capture, and 14-day same-doctor free review detection.
- **💳 Smart Payment Types** — Paid (per doctor fee), Free Review (strictly for returning patients of same doctor within 14 days, with warning if >14 days), Free Family (courtesy).
- **📊 Daily Revenue Analytics & Auditing** — Real-time earnings breakdown calculated by `RevenueEngine` grouped by doctor with chamber preview mode.
- **🔢 Atomic Queue Numbers** — Race-condition-safe queue numbering per day using Firestore transactions.
- **🔴 Real-time Firestore Streams** — Live updates across counter PC and doctor chambers via Firestore listeners.

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Platforms | Web (Desktop Counter / Tablet / Mobile), Android, iOS |
| UI Framework | Flutter 3.x (Material 3 Responsive) |
| Domain Engines | Pure Dart (`RevenueEngine`, `AppointmentEngine`, `MedicineEngine`) |
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
git clone https://github.com/0xCoderunknown/guwahatione-clinic-app.git
cd guwahatione-clinic-app
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
* **Reception Desk / Owner:** `0000` (can be modified directly in code or app)
* **Doctor Chamber View:** Default `1234` (configurable per doctor in the Doctors management screen)

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
│       ├── revenue_engine.dart              # Pure realized revenue math, chamber KPIs & doctor rollups
│       ├── appointment_engine.dart          # 14-day free review eligibility, fee resolution & queue states
│       └── medicine_engine.dart             # Chemical search scoring, default OPD regimens & Rx segregation
├── models/
│   ├── appointment.dart                     # Appointment schema, PaymentType & AppointmentStatus
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
│   └── clinic_provider.dart                 # Real-time streams, chamber sync, consultations & appointments
├── services/
│   └── firebase_service.dart                # Atomic transactions, daily chamber sync, batch consultation writes
├── screens/
│   ├── login_screen.dart                    # Role selector (Doctor Chamber vs Reception Desk)
│   ├── owner_shell.dart                     # Responsive shell (Desktop rail vs mobile bar)
│   ├── dashboard_screen.dart                # Reception KPI overview cards & 1-tap "Call In"
│   ├── appointment_list_screen.dart         # Live queue, absent marking, payment updates & "Call In"
│   ├── add_appointment_dialog.dart          # Rapid booking with patient history search
│   ├── doctor_chamber_screen.dart           # Real-time zero-touch chamber sync board & active token badge
│   ├── consultation_encounter_screen.dart   # Lightweight (<300 lines) 5-step encounter coordinator scaffold
│   ├── prescription_print_screen.dart       # High-contrast A4/A5 print preview with letterhead toggle
│   ├── medicine_catalogue_screen.dart       # Admin medicine catalogue management & seeding
│   ├── doctor_list_screen.dart              # Doctor roster, PIN display & chamber preview
│   ├── add_doctor_screen.dart               # Register doctor with fee & chamber PIN
│   ├── doctor_daily_details_screen.dart     # Daily patient drill-down
│   └── statistics_screen.dart               # Financial audit & doctor payout summary
├── widgets/
│   ├── widgets.dart                         # Central barrel export across all widget domains
│   ├── common/                              # Reusable atomic UI primitives
│   │   ├── allergy_alert_banner.dart        # Reusable allergy banner with interactive add/remove
│   │   ├── appointment_status_chip.dart     # Standardized appointment status chips
│   │   ├── clinic_date_nav_bar.dart         # Standardized date navigation header
│   │   ├── metric_kpi_card.dart             # Unified vertical & horizontal KPI metrics tile
│   │   ├── payment_badge.dart               # Visual payment type badges
│   │   ├── section_card.dart                # Collapsible animated section cards with badges & actions
│   │   └── token_badge.dart                 # Uniform token sequence badges
│   ├── booking/                             # Reception appointment booking dialog components
│   │   ├── booking_eligibility_banner.dart  # 14-day policy warning banner & static confirmation dialog
│   │   ├── booking_patient_fields.dart      # Phone search, patient name, age, and gender fields
│   │   └── booking_payment_section.dart     # Paid, Free Review, and Family courtesy payment radio section
│   ├── queue/                               # Reception queue management
│   │   └── appointment_accordion.dart       # Live token card with actions (absent, attended, call in)
│   ├── chamber/                             # Doctor chamber catalog screen components
│   │   ├── chamber_app_bar.dart             # Header with live time, sync indicator, and PIN logout
│   │   ├── chamber_metrics_grid.dart        # Real-time KPI summary cards (Total, In Queue, Revenue)
│   │   ├── chamber_queue_header.dart        # Section header for consultant queue
│   │   └── chamber_token_card.dart          # Token tile with status badge & consultation launcher
│   ├── dashboard/                           # Command center reception dashboard components
│   │   ├── dashboard_header_bar.dart        # Reception header bar with quick action chips
│   │   ├── dashboard_kpi_strip.dart         # Responsive daily KPI cards with automatic breakpoints
│   │   ├── dashboard_queue_card.dart        # Live queue preview with 1-tap "Call In" buttons
│   │   └── dashboard_doctor_roster_card.dart# Doctor roster with live chamber calling status
│   ├── encounter/                           # Step-by-step clinical encounter widgets
│   │   ├── advice_and_orders_section.dart   # Step 5: Advice, lab test orders, and quick follow-up chips
│   │   ├── chamber_calling_alert_bar.dart   # Live reception chamber calling alert banner
│   │   ├── consultation_bottom_dock.dart    # Sticky bottom action dock with consultation sign action
│   │   ├── diagnostic_review_section.dart   # Step 3: Diagnostic investigation review tracker
│   │   ├── encounter_dialogs.dart           # Modal dialogs & bottom sheets (allergies, labs, stop reasons, history)
│   │   ├── encounter_form_state.dart        # Encapsulated encounter controllers, state, and builders
│   │   ├── patient_header_section.dart      # Step 1: Patient header & demographics summary
│   │   ├── rx_reconciliation_section.dart   # Step 4: Coordinator for Rx reconciliation, search, and staging
│   │   ├── vitals_and_exam_section.dart     # Step 2: Vitals grid, collapsible findings pills, and exam notes
│   │   ├── vitals_input_grid.dart           # Compact numerical vitals entry grid
│   │   └── rx/                              # Specialized prescribing sub-components
│   │       ├── staged_medicine_form.dart    # Prefilled OPD defaults, dosage chips & chronic toggle
│   │       ├── rx_search_results_view.dart  # Chemical salt + trade brand search pills & pickers
│   │       └── reconciliation_item_row.dart # Active regimen row with 1-tap CONTINUE/STOP actions
│   ├── print/                               # High-contrast monochrome A4/A5 prescription print components
│   │   ├── print_clinical_snapshot.dart     # Clinical snapshot (Vitals, Complaints, Diagnosis)
│   │   ├── print_header_and_demographics.dart # Header with clinic details & patient demographics
│   │   ├── print_medications_table.dart     # Active Rx table and discontinued medications audit box
│   │   └── print_orders_and_footer.dart     # Diagnostic orders, lifestyle advice & doctor signature
│   └── catalogue/                           # Master medicine catalogue management
│       ├── add_medicine_dialog.dart         # Modal dialog to add new formulary entries
│       ├── catalogue_header_and_stats.dart  # Formulary metrics bar (total, brands, molecules)
│       ├── catalogue_medicine_card.dart     # Individual medicine brand card with actions
│       └── catalogue_search_toolbar.dart    # Real-time search and filter toolbar
└── utils/
    ├── app_constants.dart                   # Default fee, blocked clinic dates
    ├── clinical_defaults_helper.dart        # Transparent adapter forwarding to MedicineEngine
    ├── default_medicines.dart               # Canonical essential OPD medications with deterministic IDs
    ├── formatters.dart                      # Centralized date, time, and currency formatters (AppFormatters)
    ├── medicine_search_scorer.dart          # Transparent adapter forwarding to MedicineEngine
    ├── platform_print.dart                  # Unified cross-platform print interface
    ├── platform_print_web.dart              # Web print implementation using dart:js_interop
    └── platform_print_stub.dart             # Native desktop/mobile fallback print stub
```

---

## 🧪 Testing

Run all unit, model, and widget tests:

```bash
flutter test
```

The test suite contains **35 automated tests** covering:
- **`catalogue_scoring_test.dart`** — Dual-mode ranking (composition-first & brand-first), brand grouping, clinical defaults helper fallbacks, unlisted outside drug fallback, and admin vs. doctor role security guards.
- **`consultation_test.dart`** — Patient clinical attributes, vitals formatting, prescription item lifecycle (`START`/`CONTINUE`/`STOP`), and 2-visit longitudinal medication reconciliation.
- **`prescription_print_test.dart`** — Active Rx vs. discontinued regimen segregation, null-safe formatting, letterhead toggle, and widget rendering.
- **`widget_test.dart`** — Appointment ledger, PIN auth, and 14-day same-doctor free review business logic.

---

## 🤝 Contributing

We welcome contributions of all sizes. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgements

Built for [GuwahatiOne](https://guwahatiOne.com) · Powered by [Flutter](https://flutter.dev) & [Firebase](https://firebase.google.com)
