# 🏥 GuwahatiOne Clinic OS

> **Open-source, web-first clinic & chamber management platform featuring an append-only longitudinal prescription architecture, audit-proof token ledgers, and real-time doctor chamber catalog boards.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)

A modern, production-grade clinical operating system built for standalone polyclinics, pharmacy-attached consultation rooms, and multi-doctor outpatient practices. Originally engineered for [GuwahatiOne](https://guwahatiOne.com).

---

## 💡 The Core Philosophy

ClinicOS is built on two unshakeable clinical and operational tenets:

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
- **Strict 5-Step Clinical Encounter (`ConsultationEncounterScreen`)** — Guides physicians through allergies, vitals, past labs, medication reconciliation, and advice.
- **Medication Reconciliation State Machine** — Explicit lifecycle states (`START`, `CONTINUE`, `STOP`) on prescription items. 1-tap continuation for ongoing chronic regimens (`durationDays = null`) and explicit discontinuation documenting clinical `stopReason`.
- **Composition-First Medicine Engine (`MedicineSearchScorer`)** — Prioritizes chemical molecule matches at the top with associated clinic trade brands grouped underneath.
- **Zero-Friction Outside Medicine Fallback (`unlistedName`)** — Doctors are never blocked when prescribing outside or brand medications missing from the clinic catalogue.
- **Admin vs. Prescriber Catalogue Separation (`MedicineCatalogueScreen`)** — Dedicated administration interface in reception shell for clinic owners to curate products and active compositions, with strict role guards preventing chamber prescriber pollution.
- **Clean Prescription Print Output (`PrescriptionPrintScreen`)** — High-contrast monochrome print layout supporting **A4** and **A5** paper, pre-printed letterhead mode (reserved 130px top margin), active Rx schedule filtering (`START`/`CONTINUE` only), and distinct audit warning box for discontinued drugs.

### 🏢 Clinic Operations & Ledger Integrity
- **🌐 Web-First Responsive Architecture** — Single responsive codebase deployed to Chrome/Edge (Counter PC), Android, and iOS.
- **🩺 Doctor Chamber Live Board** — Read-only chamber dashboard for consultants showing live token order, patient status, and fee share with 1-tap access to patient clinical records and consultation encounters.
- **🔒 Zero-Friction PIN Authentication** — Quick PIN access: Reception PIN (`0000` default) & individual 4-digit Chamber PINs per doctor.
- **🛡️ Audit-Proof Ledger** — Zero deletions allowed; consecutive token sequence is preserved on screen and database.
- **🚫 Explicit "Absent / No-Show" Status** — Replaced "Cancel" with "Absent" so slots are preserved on the doctor ledger with ₹0 amount.
- **📅 Rapid Appointment Booking** — 10-digit phone search with automatic patient history and 14-day same-doctor free review detection.
- **💳 Smart Payment Types** — Paid (per doctor fee), Free Review (strictly for returning patients of same doctor within 14 days, with warning if >14 days), Free Family (courtesy).
- **📊 Daily Revenue Analytics & Auditing** — Real-time earnings breakdown grouped by doctor with chamber preview mode.
- **🔢 Atomic Queue Numbers** — Race-condition-safe queue numbering per day using Firestore transactions.
- **🔴 Real-time Firestore Streams** — Zero-refresh instant sync across counter PC and doctor chambers.

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Platforms | Web (Desktop Counter / Tablet / Mobile), Android, iOS |
| UI Framework | Flutter 3.x (Material 3 Responsive) |
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
git clone https://github.com/coder-unknown/guwahatione-clinic-os.git
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
| `counters` | One document per date for atomic queue numbering |
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
lib/
├── main.dart                                # Entry point, AuthGate, theme & MultiProvider setup
├── firebase_options.dart                    # 🔒 Secret — not in git (see .gitignore)
├── models/
│   ├── appointment.dart                     # Appointment schema, PaymentType & AppointmentStatus
│   ├── consultation.dart                    # Immutable encounter schema with active/stopped getters
│   ├── diagnostic_investigation.dart        # Lab review (performedDate) & OrderedTest schemas
│   ├── doctor.dart                          # Doctor schema with Chamber PIN & consultationFee
│   ├── medicine.dart                        # Master catalogue decoupling composition from trade brand
│   ├── patient.dart                         # Patient schema with phone-keying & allergies
│   ├── prescription_item.dart               # PrescriptionItem state machine (START/CONTINUE/STOP)
│   ├── user_role.dart                       # UserRole & UserSession models
│   └── vitals.dart                          # Vitals schema (BP, pulse, SpO2, temp, weight)
├── providers/
│   ├── auth_provider.dart                   # PIN authentication & SharedPreferences session
│   └── clinic_provider.dart                 # Real-time streams, consultations, catalogue & appointment state
├── services/
│   └── firebase_service.dart                # Atomic transactions, batch consultation writes & Firestore streams
├── screens/
│   ├── login_screen.dart                    # Role selector (Doctor Chamber vs Reception Desk)
│   ├── owner_shell.dart                     # Responsive shell (Desktop rail vs mobile bar)
│   ├── dashboard_screen.dart                # Reception KPI overview cards
│   ├── appointment_list_screen.dart         # Live queue, absent marking & payment updates
│   ├── add_appointment_dialog.dart          # Rapid booking with patient history search
│   ├── doctor_chamber_screen.dart           # Read-only live catalog board for doctors + encounter access
│   ├── consultation_encounter_screen.dart   # 5-step clinical consultation & reconciliation workspace
│   ├── prescription_print_screen.dart       # High-contrast A4/A5 print preview with letterhead toggle
│   ├── medicine_catalogue_screen.dart       # Admin medicine catalogue management & seeding
│   ├── doctor_list_screen.dart              # Doctor roster, PIN display & chamber preview
│   ├── add_doctor_screen.dart               # Register doctor with fee & chamber PIN
│   ├── doctor_daily_details_screen.dart     # Daily patient drill-down
│   └── statistics_screen.dart               # Financial audit & doctor payout summary
└── utils/
    ├── app_constants.dart                   # Default fee, blocked clinic dates
    ├── medicine_search_scorer.dart          # Composition-first search & brand grouping engine
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

The test suite covers:
- **`catalogue_scoring_test.dart`** — Composition-first ranking hierarchy, brand grouping, unlisted outside drug fallback, and admin vs. doctor role security guards.
- **`consultation_test.dart`** — Patient backward compatibility, vitals formatting, prescription item lifecycle (`START`/`CONTINUE`/`STOP`), and 2-visit longitudinal medication reconciliation.
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
