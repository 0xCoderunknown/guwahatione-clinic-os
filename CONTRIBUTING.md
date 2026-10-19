# 🛠️ GuwahatiOne Clinic OS — AI Engineering & Maintenance Guide

> **Operational Standard for AI Coding Assistants & Human Product Management.**  
> This project is **100% coded and maintained by AI**.  
> The human user acts exclusively as the **Strict Product Manager (PM) & Tester**.

---

## 👥 Division of Responsibilities

| Role | Entity | Scope |
|---|---|---|
| **Product Manager (PM) & Tester** | Human User | Product vision, feature acceptance, operational edge-case testing, clinical intent clarification, and config value editing. |
| **Senior Clinical Systems Architect & Engineer** | AI Assistant | Architecture design, pure Dart domain engines, UI screen coordinators, Firestore schema contracts, automated tests, and verification. |

---

## ⚙️ What Humans Configure

These are the only files and parameters the human Product Manager is expected to edit directly:

### 1. `lib/utils/app_constants.dart`
```dart
static const int defaultConsultationFee = 500; // Global fallback consultation fee in INR

static const List<String> blockedDates = [
  // '2026-10-02', // Add/remove clinic holiday dates (stored as ISO keys, presented as DD-MM-YYYY in UI)
];
```

### 2. `lib/config/clinic_config.dart`
- `ClinicFeatureFlags` — Toggle runtime clinic operational flags and experiments (`enableTokenReceiptPrint`, `hidePrescriptionComposition`, `enableGroupedCompositionCards`).

### 3. `pubspec.yaml`
- `version` — Bump when releasing a new clinic build.
- `name` / `description` — Rebranding metadata.

### 4. `lib/firebase_options.dart`
- Generated automatically by `flutterfire configure`. Re-run when switching Firebase projects.
- **Never commit secret Firebase credentials to version control.**

### 5. `assets/`
- Replace `icon.png` to update launcher / favicon icons.

---

## 🤖 Instructions for AI Coding Assistants

When implementing features, fixing bugs, or refactoring code:

1. **Verify Before & After:**
   - Run `flutter analyze` — zero issues allowed.
   - Run `flutter test` — all automated tests must pass with sub-second VM speed.
2. **Respect Clean Separation of Concerns:**
   - **Domain Engines (`lib/core/engines/`):** 100% pure Dart. Financial math, review eligibility, drug search scoring, and queue partitioning belong here, never in widget `build()` methods.
   - **Models (`lib/models/`):** Pure data schemas with robust JSON serialization. Keep models UI-free.
   - **Services (`lib/services/`):** Modular Firestore operations (`BookingService`, `ConsultationService`, `ChamberService`, etc.).
   - **Providers (`lib/providers/`):** `ChangeNotifierProvider` exclusively. Coordinates streams and engine delegation.
   - **Screens (`lib/screens/`):** Thin Coordinator Scaffolds managing layout bounds, navigation triggers, and lifecycles.
   - **Widgets (`lib/widgets/`):** Reusable presentation components.
3. **Mandatory Invariants:**
   - **Zero Deletions (Invariant #1):** Never delete an appointment or consultation document from Firestore. Use `AppointmentStatus.absent` with `₹0`.
   - **Doctor-Paced Chamber Handshake (Invariant #7):** Never admit patients during active consultations or doctor breathers without explicit `ready_for_next`.
   - **Zero Backward-Compatibility Debt (Invariant #10):** Never introduce legacy bridges, fallback shims, or deprecated aliases. Keep code modern and clean.
   - **Single-Occupant Chamber Integrity (Invariant #11):** Zero token pre-emption. A chamber holds exactly zero or one active patient.
   - **Mandatory Indian Date Format (Invariant #6):** All UI dates, printed prescriptions, reports, changelogs, and markdown documentation must strictly use `DD-MM-YYYY` or `DD-MM-YY`.
4. **Changelog Maintenance:**
   - Record user-visible and architectural changes in `CHANGELOG.md` using Indian date format (`## [x.y.z] — DD-MM-YYYY`).

---

## 🎯 Priority Backlog & Delivery Status

Authoritative product tracking lives in [`docs/PRODUCT_ROADMAP.md`](docs/PRODUCT_ROADMAP.md):

- [x] **P1:** Chamber Real-time Auto-Sync (`v1.5.0`)
- [x] **P2:** Clinical Dosage & Duration OPD Defaults (`v1.5.0`)
- [x] **P3:** Collapsible Encounter Sections (`v1.5.0`)
- [x] **P4:** Doctor Brand vs. Composition Prescribing Preferences (`v1.5.0`)
- [x] **P5:** Doctor Medical Registration & Official Printout Signature Block (`v1.14.0`)
- [x] **P6:** Offline Queue Fallback Cache for Counter Broadband Dropouts (`v1.15.0`)
- [x] **P7:** WhatsApp Digital Prescription Deep Link (`v1.15.0`)
- [x] **P8:** Daily End-of-Day Financial Handover & Denomination Note Counter (`v1.15.0`)
- [x] **P9:** Prescription Template Presets & OPD Regimen Bundles (`v1.28.0`)
- [x] **P10:** Multi-Chamber Queue Sound Announcer & Vocal Token Calling (`v1.29.0`)
- [ ] **P11:** Prepaid Carry-Over & Doctor No-Show Refund Protocol (RFC-2 in `docs/PRODUCT_ROADMAP.md`)
- [x] **P12:** Patient Lookup / Explore Patients — Patients tab with zero-egress search, multi-doctor consultation accordions, and walk-in shortcut (`v1.33.0`)
- [ ] **P13:** Emergency / Illiterate Walk-In Dummy Key (`9900000001`+)
- [x] ~~**P14:** Doctor Discretionary Fee Waiver~~ — Scrapped (redundant with `PaymentType.freeFamily`)
- [ ] **P15 · 🧪:** Fullscreen Waiting Hall Queue Display Board (`/display`)
