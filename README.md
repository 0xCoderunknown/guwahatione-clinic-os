# 🏥 GuwahatiOne Clinic OS

> **Open-source, web-first clinic & chamber management platform with audit-proof token ledgers and real-time doctor catalog boards.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)

A modern, production-grade clinic operating system built for standalone polyclinics, pharmacy-attached consultation rooms, and multi-doctor chambers. Originally engineered for [GuwahatiOne](https://guwahatiOne.com) and designed to eliminate doctor-receptionist payout disputes forever.

---

## 💡 The Core Philosophy: Ending Clinic-Doctor Friction

Visiting medical consultants often suspect clinic receptionists of cheating (*"I saw 10 patients today, but receptionist paid me for 8 and claimed 2 were free reviews"*). 

**GuwahatiOne Clinic OS** solves this at the structural level:

1. **Strictly Audit-Proof (Zero Deletions):** Once an appointment is booked, it can **never** be deleted. Token numbers ($1 \dots N$) are strictly consecutive. If a patient leaves, they are marked **`[ABSENT] ₹0`**—the token number remains permanently visible so no hidden cash patients can exist.
2. **Doctor Chamber Live View ("Catalog Mode"):** Doctors don't install bulky apps. They open a web link on their chamber phone/tablet, enter a 4-digit PIN, and watch their live queue update in real-time as patients check in. They see exactly who entered, which visits were free follow-ups, and their exact daily payout.
3. **Reception Desk Ergonomics:** Designed for high-volume desktop data entry at the clinic counter with keyboard shortcuts, rapid 10-digit phone lookup, and multi-doctor scheduling.

---

## ✨ Features

- 🌐 **Web-First Responsive Architecture** — Single responsive codebase deployed to Chrome/Edge (Counter PC), Android, and iOS
- 🩺 **Doctor Chamber Live Board** — Read-only chamber dashboard for consultants showing live token order, patient status, and fee share
- 🔒 **Zero-Friction PIN Authentication** — Quick PIN access: Reception PIN (`0000` default) & individual 4-digit Chamber PINs per doctor
- 🛡️ **Audit-Proof Ledger** — Zero deletions allowed; consecutive token sequence is preserved on screen and database
- 🚫 **Explicit "Absent / No-Show" Status** — Replaced "Cancel" with "Absent" so slots are preserved on the doctor ledger with ₹0 amount
- 📅 **Rapid Appointment Booking** — 10-digit phone search with automatic patient history and 14-day same-doctor free review detection
- 💳 **Smart Payment Types** — Paid (per doctor fee), Free Review (strictly for returning patients of same doctor within 14 days, with warning if >14 days), Free Family (courtesy)
- 📊 **Daily Revenue Analytics & Auditing** — Real-time earnings breakdown grouped by doctor with chamber preview mode
- 🔢 **Atomic Queue Numbers** — Race-condition-safe queue numbering per day using Firestore transactions
- 🔴 **Real-time Firestore Streams** — Zero-refresh instant sync across counter PC and doctor chambers

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

This will create `lib/firebase_options.dart` and `android/app/google-services.json` automatically. See [`lib/firebase_options.dart.example`](lib/firebase_options.dart.example) and [`android/app/google-services.json.example`](android/app/google-services.json.example) for the expected templates.

### 3. Set up Firestore

In your Firebase Console, create the following collections (they are created automatically on first use, but you can pre-create them):

| Collection | Purpose |
|---|---|
| `appointments` | One document per appointment (immutable, zero deletions) |
| `patients` | One document per patient (keyed by phone number) |
| `doctors` | One document per doctor (stores specialty, PIN, consultation fee) |
| `counters` | One document per date for atomic queue numbering |

**Firestore Indexes Configuration**:
Index definitions are tracked in [`firestore.indexes.json`](firestore.indexes.json) and linked via `firebase.json`:
- `appointments`: `doctorId` ASC + `scheduledDate` ASC
- `appointments`: `patientPhone` ASC + `scheduledDate` ASC

> **Note**: Runtime queries use single-field date streaming and in-memory filtering, allowing the app to run immediately with zero composite index requirements out-of-the-box.

### 4. Install dependencies and run

```bash
flutter pub get

# Run on Desktop Browser (Chrome) — Recommended for Reception Desk
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
├── main.dart                         # Entry point, AuthGate, theme & MultiProvider setup
├── firebase_options.dart             # 🔒 Secret — not in git (see .gitignore)
├── models/
│   ├── appointment.dart              # Appointment schema, PaymentType & AppointmentStatus
│   ├── doctor.dart                   # Doctor schema with Chamber PIN & consultationFee
│   ├── patient.dart                  # Patient schema with phone-keying
│   └── user_role.dart                # UserRole & UserSession models
├── providers/
│   ├── auth_provider.dart            # PIN authentication & SharedPreferences session
│   └── clinic_provider.dart          # Real-time streams & appointment state
├── services/
│   └── firebase_service.dart         # Atomic queue transactions & Firestore streams
├── screens/
│   ├── login_screen.dart             # Role selector (Doctor Chamber vs Reception Desk)
│   ├── owner_shell.dart              # Responsive shell (Desktop rail vs mobile bar)
│   ├── dashboard_screen.dart         # Reception KPI overview cards
│   ├── appointment_list_screen.dart  # Live queue, absent marking & payment updates
│   ├── add_appointment_dialog.dart   # Rapid booking with patient history search
│   ├── doctor_chamber_screen.dart    # Read-only live catalog board for doctors
│   ├── doctor_list_screen.dart       # Doctor roster, PIN display & chamber preview
│   ├── add_doctor_screen.dart        # Register doctor with fee & chamber PIN
│   ├── doctor_daily_details_screen.dart # Daily patient drill-down
│   └── statistics_screen.dart        # Financial audit & doctor payout summary
└── utils/
    └── app_constants.dart            # Default fee, blocked clinic dates
```

---

## 🤝 Contributing

We welcome contributions of all sizes. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgements

Built for [GuwahatiOne](https://guwahatiOne.com) · Powered by [Flutter](https://flutter.dev) & [Firebase](https://firebase.google.com)

