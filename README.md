# GuwahatiOne Doc — Clinic Appointment Manager

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)

A free and open-source Flutter application for managing doctor appointments at small clinics. Built for [GuwahatiOne](https://guwahatiOne.com) but designed to be self-hosted by any clinic.

---

## ✨ Features

- 📅 **Appointment Booking** — Book patients with date, doctor, and payment type
- 🩺 **Doctor Management** — Add doctors with specialty and available weekdays
- 👤 **Patient Recognition** — Auto-fills returning patient details by phone number
- 💳 **Smart Payment Types** — Paid, Free Review (within 15 days), Free Family
- 📊 **Daily Statistics** — Revenue and patient count grouped by doctor
- 🔢 **Queue Numbers** — Atomic, race-condition-safe queue numbering per day
- 🔴 **Real-time Updates** — Firestore live streams; no manual refresh needed
- 📆 **Date Navigation** — View appointments for any past or future date

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter (Material 3) |
| State Management | Provider |
| Backend / DB | Cloud Firestore (Firebase) |
| Auth | None (single-clinic, trusted network) |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.10
- A [Firebase project](https://console.firebase.google.com/) with **Cloud Firestore** enabled
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) for configuration

### 1. Clone the repository

```bash
git clone https://github.com/coder-unknown/guwahatione-clinic-app.git
cd guwahatione-clinic-app
```

### 2. Configure Firebase

This repository does **not** include `lib/firebase_options.dart` — it contains
secret API keys and must not be committed to version control.

Generate it for your own Firebase project:

```bash
# Install FlutterFire CLI if you haven't already
dart pub global activate flutterfire_cli

# Log in and configure
firebase login
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

This will create `lib/firebase_options.dart` and `android/app/google-services.json` automatically. See
[`lib/firebase_options.dart.example`](lib/firebase_options.dart.example) and
[`android/app/google-services.json.example`](android/app/google-services.json.example) for
the expected templates.

### 3. Set up Firestore

In your Firebase Console, create the following collections (they are created
automatically on first use, but you can pre-create them):

| Collection | Purpose |
|---|---|
| `appointments` | One document per appointment |
| `patients` | One document per patient (keyed by phone number) |
| `doctors` | One document per doctor |
| `counters` | One document per date for atomic queue numbering |

**Required Firestore index** (Composite):

```
Collection: appointments
Fields:
  scheduledDate  ASC
  patientPhone   ASC
```

Firebase will prompt you with a direct link to create this index the first
time you run a compound query.

### 4. Install dependencies and run

```bash
flutter pub get
flutter run
```

---

## ⚙️ Configuration

All tunable constants live in [`lib/utils/app_constants.dart`](lib/utils/app_constants.dart):

```dart
class AppConstants {
  // Change the consultation fee here — it propagates everywhere automatically.
  static const int defaultConsultationFee = 500;

  // Add clinic holiday dates in 'YYYY-MM-DD' format.
  static const List<String> blockedDates = [
    // '2026-10-02',
  ];
}
```

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry point, theme, provider setup
├── firebase_options.dart       # 🔒 Secret — not in git (see .gitignore)
├── models/
│   ├── appointment.dart        # Appointment data model
│   ├── doctor.dart             # Doctor data model
│   └── patient.dart            # Patient data model
├── providers/
│   └── clinic_provider.dart    # Global state (ChangeNotifier)
├── services/
│   └── firebase_service.dart   # All Firestore read/write logic
├── screens/
│   ├── dashboard_screen.dart
│   ├── appointment_list_screen.dart
│   ├── add_appointment_dialog.dart
│   ├── doctor_list_screen.dart
│   ├── add_doctor_screen.dart
│   ├── doctor_daily_details_screen.dart
│   └── statistics_screen.dart
└── utils/
    └── app_constants.dart      # Fee, blocked dates, shared constants
```

---

## 🤝 Contributing

We welcome contributions of all sizes. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgements

Built with [Flutter](https://flutter.dev) · Powered by [Firebase](https://firebase.google.com)
