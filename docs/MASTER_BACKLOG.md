# 📚 GuwahatiOne Clinic OS — Master Backlog & Reference

> **Single Source of Truth** for all issues, audit findings, feature backlog, roadmap, experiments, scrapped items, compliance notes, and engineering operational guidelines.
>
> **Companion Files (not merged here):**
> - [`AGENTS.md`](../AGENTS.md) — AI operating constitution, invariants, and red lines (canonical law)
> - [`CHANGELOG.md`](../CHANGELOG.md) — Version history
> - [`docs/SCHEMA_AND_MODELS.md`](SCHEMA_AND_MODELS.md) — Firestore schema & model contracts
> - [`.agents/recipes/`](../.agents/recipes/) — AI workflow checklists
>
> **Date Standard:** All dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## 🎯 Target Deployment Context & Operating Constraints

1. **Target Physical Architecture (Tier 2 City OPD Clinics):**
   - Designed specifically for OPD polyclinics and consulting chambers in Tier 2 Indian cities with **1–3 consulting doctors** and an **attached pharmacy in front**.
   - Counter PCs / Laptops handle walk-in reception, token allocation, fee reconciliation, and physical arrival verification.
   - Doctor chambers run desktop/tablet web sessions strictly synchronized via Firestore counters.

2. **100% AI Developed & Maintained:**
   - The codebase is 100% written and maintained by AI assistants. The human user acts strictly as the **Product Manager (PM) & Physical Tester**.
   - Architectural scope and runtime operational flags are centrally governed by [`lib/config/clinic_config.dart`](../lib/config/clinic_config.dart).

3. **Master Formulary & Medicine Catalogue Roadmap:**
   - Default medicines in `lib/utils/default_medicines.dart` are for **development & test verification only**.
   - Production clinics will populate their formulary via **bulk CSV import** and direct in-app catalogue addition (tracked in **IDEA-3** & **AUDIT-27**).

4. **Commercial Model & Data Sovereignty:**
   - Deployed on an **annual prepaid subscription model (1 year)** with an **extended 1-month grace period** for non-renewing clinics to transition out before system shutdown.
   - Requires comprehensive **client-side data export** (appointments, patients, consultations, financial ledger, and medicines in CSV format) to guarantee zero lock-in during the grace period (tracked in **IDEA-1** & **AUDIT-26**).

5. **Public Open-Source Repository (MIT License on GitHub):**
   - The entire project is published publicly on GitHub under the **MIT License** (`LICENSE`).
   - **Zero Security Through Obscurity:** Because the full repository is public, anyone can inspect the codebase, API models, and Firestore rules. Hardcoded test credentials (such as default PINs `849201`/`0000` in UI/providers) or open `allow read, write: if true` security rules represent immediate, publicly exploitable attack vectors rather than theoretical risks. Production deployments must strictly decouple secrets, enforce Firebase Authentication, and secure database rules before onboarding real clinical data.

---

## 🔴 Section 1: Open Bugs & Audit Findings

> Issues identified by code audit on 21-10-2026. Items are undocumented elsewhere and require PM prioritization before or during production deployment.

### Priority Guide

| Symbol | Meaning |
|---|---|
| 🔴 | Critical — fix before any real patient data enters the system |
| 🟠 | High — fix before wider clinic deployment |
| 🟡 | Medium — fix before multi-clinic SaaS rollout |
| 🔵 | Low — address when convenient, does not block deployment |

---

### AUDIT-01 🔴 Hardcoded Test Credentials Displayed in Login UI

**File:** `lib/screens/login_screen.dart` lines 277, 430–432

Default admin and reception PINs are **visibly on-screen** in three places:
1. Error message (line 277): `'Incorrect PIN (Testing: Reception: 0000 | Admin: 849201).'`
2. Helper text (line 431): `'Testing PINs — Reception: 0000 | Admin: 849201'`
3. Hint text (line 430): `'PIN (Reception: 0000 | Admin: 849201)'`

Any patient or visitor at the reception desk can read the owner master PIN (`849201`) off the screen and gain full administrative access. The UI-visible leak is not documented in QOL-11 which only covers the code fallback logic.

**Fix:** Remove all three helper/hint/error credential strings. The login form must never display default PINs. Also remove the hardcoded fallback in `auth_provider.dart` that compares against the literal default strings.

---

### AUDIT-02 🔴 Firestore Security Rules Are Open to the Public Internet

**File:** `firestore.rules`

Every collection allows `allow read: if true` and most allow `allow create, update: if true` from any unauthenticated request globally. Anyone with the Firebase project ID (embedded in the published web app's `firebase_options.dart`) can read every patient record, consultation, prescription, and doctor PIN via the Firestore REST API — no app required. Anyone can also write arbitrary data to `patients`, `doctors`, and `medicines`.

Application-layer PIN checks do **not** protect Firestore. Rules are the only server-side enforcement boundary. Under India's DPDP Act 2023, this constitutes a notifiable breach.

**Fix:** Implement Firebase Anonymous Authentication (or email-based). Tie all Firestore rules to `request.auth != null`. This is the single most severe security issue in the system.

---

### AUDIT-03 🔴 Doctor PINs Stored Plaintext in Firestore

**Files:** `lib/models/doctor.dart`, `lib/providers/auth_provider.dart` line 207

`AuthProvider.authenticateWithPin` hashes the value of `doctor.pin` at comparison time (`hashPin(d.pin) == inputHash`), but `doctor.pin` is loaded directly from Firestore as a plaintext 4-digit string (e.g. `'1234'`). SHA-256 hashing only protects Owner and Reception PINs in `SharedPreferences`. Doctor PINs in the `doctors` collection receive zero cryptographic protection at rest.

**Fix:** Hash doctor PINs before writing to Firestore. Related: QOL-12 tracks the broader doctor PIN hardening work, but the specific Firestore plaintext storage issue must be addressed as part of AUDIT-02 resolution.

---

### AUDIT-04 🟠 No Brute-Force Protection on PIN Authentication

**Files:** `lib/screens/login_screen.dart`, `lib/providers/auth_provider.dart`

No rate limiting, lockout threshold, attempt counter, or delay between failed attempts. A 4-digit PIN has 10,000 combinations; a 6-digit PIN has 1,000,000. Both can be exhausted in seconds with automated tooling through the web UI since `loginAsReceptionistOrOwner` accepts unlimited sequential calls.

**Fix:** Add a failed-attempt counter with a lockout (e.g., 5 attempts → 30-second freeze) tracked in local state or `SharedPreferences`.

---

### AUDIT-05 🟠 Batch Size Limit Not Enforced in `closeDoctorSessionForDate`

**File:** `lib/services/booking_service.dart` lines 328–356

Firestore batch writes have a hard 500-operation limit. `closeDoctorSessionForDate` adds all appointments for a doctor-date into a single batch without a size guard. In a polyclinic with accumulated advance bookings, this will throw a Firestore exception mid-operation, leaving the session partially-closed with inconsistent `absent`/`pending` records.

**Fix:** Chunk the batch into groups of 450 and commit sequentially.

---

### AUDIT-06 🟠 `saveConsultation` Writes a Ghost Field `formattedAge` to Patient Documents

**File:** `lib/services/consultation_service.dart` line 55

```dart
if (consultation.patientAgeDisplay != null)
  'formattedAge': consultation.patientAgeDisplay,   // ← wrong key
```

The canonical `patients` schema uses `patientAgeDisplay`, not `formattedAge`. This ghost field is written to every patient document on every consultation save, is never read back by any code, and silently violates the schema contract in `SCHEMA_AND_MODELS.md`.

**Fix:** Change `'formattedAge'` to `'patientAgeDisplay'` in `consultation_service.dart`. Update `SCHEMA_AND_MODELS.md` if the field was previously undocumented.

---

### AUDIT-07 🟠 TOCTOU Race in `notifyReadyForNext` Single-Doctor Mode

**File:** `lib/services/chamber_service.dart` lines 151–169

The `enforceSingleActiveDoctor` check in `notifyReadyForNext` performs a `get()` then `set()` outside of a Firestore transaction — a classic Time-of-Check-Time-of-Use race. Two doctors could simultaneously signal ready and both pass the guard, bypassing the single-doctor constraint. The correct `callTokenIntoChamber` path uses a transaction; `notifyReadyForNext` does not.

**Fix:** Wrap the single-doctor check + `ready_for_next` write in a Firestore transaction.

---

### AUDIT-08 🟠 Patient Name Search Only Covers Last 50 Records

**File:** `lib/services/patient_service.dart` lines 188–196

The name-search fallback in `searchPatients` fetches an arbitrary 50 documents from the `patients` collection without `orderBy`, then filters in memory. In a clinic with 200+ patients, searching for a common surname ("Das", "Borah") will silently miss registered patients outside the 50-document window, causing duplicate patient registrations.

**Fix:** Replace the in-memory filter over 50 docs with a Firestore composite index on `name` to support proper prefix range queries at scale.

---

### AUDIT-09 🟠 Free Review Booking Skips Window and Consumption Checks

**File:** `lib/providers/delegates/live_queue_delegate.dart` lines 258–274

When booking `PaymentType.freeReview`, `bookAppointment` only validates `eligibility.hasVisitedDoctorEarlier` — it does **not** check `eligibility.isWithinReviewPeriod` or `eligibility.isReviewAlreadyConsumed`. A patient outside the configured `freeReviewDays` window, or one who already consumed their review this cycle, can still book for free.

`AppointmentEngine.evaluateReviewEligibility` already computes all conditions correctly. The booking path just needs to check all three.

**Fix:** Add `eligibility.isWithinReviewPeriod` and `!eligibility.isReviewAlreadyConsumed` checks alongside the existing `hasVisitedDoctorEarlier` guard in `live_queue_delegate.dart`.

---

### AUDIT-10 🟡 Dual Default Fee Constants Can Silently Drift

**Files:** `lib/utils/app_constants.dart`, `lib/core/engines/appointment_engine.dart` line 255, `lib/config/clinic_config.dart` line 43

`AppConstants.defaultConsultationFee = 500` is used as the engine fallback when `doctor` is null, completely bypassing `ClinicConfig.current.defaultConsultationFee`. If a clinic operator changes the `ClinicConfig` value, the engine fallback silently ignores it.

**Fix:** Remove `AppConstants.defaultConsultationFee`. Have `AppointmentEngine.resolveConsultationFee` read `ClinicConfig.current.defaultConsultationFee` as its fallback.

---

### AUDIT-11 🟡 `blockedDates` Comment Shows YYYY-MM-DD but Humans Write DD-MM-YYYY

**File:** `lib/utils/app_constants.dart` lines 8–12

```dart
/// Format: 'YYYY-MM-DD'. Add dates here to prevent bookings on those days.
// '2026-10-02',  // Gandhi Jayanti
```

Any human configuring clinic holidays following the product-wide `DD-MM-YYYY` convention will enter `'02-10-2026'` instead of `'2026-10-02'`, causing the blocking to silently fail.

**Fix:** Add a clear note: *"Internal format is ISO `YYYY-MM-DD` for programmatic comparison only. This is distinct from the `DD-MM-YYYY` display format used everywhere else in the product."*

---

### AUDIT-12 🟡 Doctor PIN Double-Hashing Will Break When QOL-12 Is Implemented

**File:** `lib/providers/auth_provider.dart` line 301

```dart
if (hashPin(doctor.pin) == hashPin(pin)) {  // both sides hashed
```

This works today because `doctor.pin` is plaintext. Once doctor PINs are stored pre-hashed (QOL-12), `hashPin(hash_value)` will never equal `hashPin(entered_pin)`, permanently locking all doctors out. The correct post-QOL-12 form is `doctor.pin == hashPin(pin)`.

**Fix:** Resolve together with QOL-12. Flag this line explicitly so it is not missed.

---

### AUDIT-13 🟡 Discard Consultation Leaves Appointment Stuck as `inConsultation`

**File:** `lib/screens/consultation_encounter_screen.dart` lines 255–263

`_discardAndExitConsultation` clears the local draft and signals `ready_for_next` but does **not** reset the appointment's `visitStatus` back to `waitingInLobby`. The appointment remains `inConsultation` in Firestore, making the patient appear "In Chamber" on the reception dashboard indefinitely. The `pauseConsultation` path correctly calls `pauseAppointment()`; the discard path needs the same.

**Fix:** Call `_bookingService.pauseAppointment(widget.appointment.id)` (or an equivalent `resumeToLobby` method) before popping navigation in `_discardAndExitConsultation`.

---

### AUDIT-14 🟡 Statistics Date Pickers Have Inconsistent Date Range Constraints

**File:** `lib/screens/statistics_screen.dart`

The AppBar `_pickDate()` hardcodes `firstDate: DateTime(2025)`. The `ClinicDateNavBar` has no equivalent restriction. On desktop, the AppBar is hidden (`showAppBar = false`), leaving only `ClinicDateNavBar` for navigation — which has no lower bound. The two navigation paths have different date range rules.

**Fix:** Apply a consistent `firstDate` lower bound to both navigation paths, reading from a shared constant (e.g., clinic activation date from `ClinicConfig`).

---

### AUDIT-15 🟡 Offline Cache Writes on Every Firestore Snapshot Without Debounce

**File:** `lib/providers/delegates/live_queue_delegate.dart` lines 187–190

Every Firestore snapshot triggers a full JSON serialization and `SharedPreferences` write. In a busy OPD session with multiple concurrent status changes, this produces a burst of sequential writes. On lower-end clinic hardware, repeated `SharedPreferences` writes can block the main isolate and produce UI jank.

**Fix:** Debounce cache writes to at most once every 3–5 seconds using a `Timer` that resets on each incoming snapshot.

---

### AUDIT-16 🟡 `DoctorChamberScreen` Instantiates Its Own Service Instances

**File:** `lib/screens/doctor_chamber_screen.dart` lines 27–28

```dart
final BookingService _bookingService = BookingService();
final ChamberService _chamberService = ChamberService();
```

These bypass `ClinicProvider`, creating a parallel Firestore listener that may be slightly out of sync with the authoritative provider stream, and breaking all test injection for this screen.

**Fix:** Receive service instances via constructor injection or read them from `ClinicProvider` on first use.

---

### AUDIT-17 🟡 `lastVisitDate` Uses Client-Side Clock (Free Review Drift Risk)

**File:** `lib/services/consultation_service.dart` line 51

```dart
'lastVisitDate': consultation.createdAt.toIso8601String(),
```

`createdAt` is set on the client device. On older clinic hardware with misconfigured system time or timezone (common in Tier 2 cities), `lastVisitDate` will be inaccurate. Since `AppointmentEngine.evaluateReviewEligibility` uses `lastVisitDate` to calculate the free review window, clock drift can inadvertently grant or deny free reviews.

**Fix:** Use `FieldValue.serverTimestamp()` for `lastVisitDate` and store the result back to the model, or validate against `scheduledDate` (which is already server-side).

---

### AUDIT-18 🟡 `ClinicConfig` Is a Static Dart Constant — Requires Recompile Per Tenant

**File:** `lib/config/clinic_config.dart` line 51

All clinic-specific values (clinic name, address, contact phone, default fee, feature flags) are baked into the compiled Dart binary. In the annual SaaS subscription model, changing even the letterhead phone number requires a full rebuild and redeployment.

**Fix for SaaS:** Migrate at minimum `clinicName`, `address`, `contactPhone`, and `tagline` to the `clinic_config` Firestore collection for runtime editability. Feature flags can remain code-side but should be overridable by the owner at runtime.

---

### AUDIT-19 🔵 No Counter Document Archiving Strategy

The `counters` collection grows by 2 documents per doctor per day (queue counter + chamber sync). A 2-doctor clinic generates ~1,200 documents/year, ~3,600 over a 3-year subscription — manageable by Firestore, but with no cleanup or archiving plan. Old chamber sync documents accumulate indefinitely.

**Track:** Define a retention policy (e.g., archive counter documents older than 6 months to a `counters_archive` sub-collection or delete chamber-only documents after 90 days).

---

### AUDIT-20 🔵 `enforceSingleActiveDoctor` Query Likely Missing Firestore Index

**File:** `lib/services/chamber_service.dart` lines 37–55

`where('date', isEqualTo: dateKey)` on the `counters` collection requires a Firestore composite index on the `date` field. Without it, this query fails in production with a Firestore index error. Verify `firestore.indexes.json` contains this index.

---

### AUDIT-21 🔵 No Input Length Limits on Clinical Free-Text Fields

Clinical free-text fields (`chiefComplaints`, `clinicalExamination`, `provisionalDiagnosis`, `adviceNotes`) have no length limits. Extremely long inputs approach Firestore's 1MB per-document limit, overflow print layouts, and inflate Firebase read costs for every future consultation load.

**Fix:** Add form validators capping each field (e.g., 2,000 chars for notes, 500 chars per complaint).

---

### AUDIT-22 🔵 No `availableDays` Check When Booking Advance Appointments

**File:** `lib/providers/delegates/live_queue_delegate.dart` lines 228–243

Advance booking validates `isDateBlocked` (holidays) and `isDoctorOnLeave` (personal leave) but does **not** call `AppointmentEngine.isDoctorAvailableOnDate` — whether the date falls within the doctor's configured working days. A Monday-only doctor can be booked for a Sunday without warning.

**Fix:** Add an `isDoctorAvailableOnDate` check in the booking validation path alongside existing guards.

---

### AUDIT-23 🔵 `AuthProvider` Exposes Plaintext Default PINs as Public Getters

**File:** `lib/providers/auth_provider.dart` lines 88–90

```dart
String get receptionistPin => _receptionistPin;   // '0000'
String get ownerMasterPin => _ownerMasterPin;      // '849201'
```

Exposes unhashed default PIN strings as public getters. Only hashed equivalents (`ownerMasterPinHash`, `receptionistPinHash`) are needed for any legitimate use case.

**Fix:** Remove or privatize `receptionistPin` and `ownerMasterPin` getters.

---

### AUDIT-24 🔵 No Debounce on Prescription Print Button

**File:** `lib/screens/prescription_print_screen.dart`

The print button has no loading lock. A double-tap on a slow clinic PC triggers two concurrent browser print dialogs, wasting paper.

**Fix:** Add `bool _isPrinting` state guard — disable the button between the click and the browser print callback.

---

### AUDIT-25 🔵 `DoctorAnalyticsSummary.free` Count Includes `unpaid` Appointments

**File:** `lib/core/engines/revenue_engine.dart` lines 217–219

```dart
if (!a.paymentType.isPaid && a.paymentType != PaymentType.postPay) {
  free++;
}
```

This incorrectly counts `unpaid` advance bookings (not yet paid) as free consultations, inflating the "Free/Fam" metric on the Statistics screen.

**Fix:** Change to `if (a.paymentType.isFree)` which correctly covers only `freeReview` and `freeFamily`.

---

### AUDIT-26 🔵 Subscription Expiry Has No Runtime Enforcement

Described deployment model: annual subscription + 1-month grace period. Currently no mechanism to check expiry, enter read-only/locked mode, notify the owner pre-expiry, or prevent new bookings post-grace-period. A clinic that stops paying continues indefinitely.

**Design before production:** Add `subscriptionExpiry` (Firestore `Timestamp`) to `clinic_config/settings`. Add a Firestore rule denying `create` operations post-grace-period. Add an in-app expiry warning banner 30 days before expiry. Define a read-only lockout mode.

---

### AUDIT-27 🔵 Default Test Medicine List Has No Production Suppression Flag

**File:** `lib/utils/default_medicines.dart`

`ensureDefaultMedicinesExist()` runs in all environments. When a clinic imports their real formulary via CSV (future feature), test medicines will coexist in the catalogue without a clean removal path.

**Fix:** Add a `ClinicFeatureFlag` (e.g., `seedDefaultMedicines`, default `false` in production) to suppress `ensureDefaultMedicinesExist()`. Document the one-time test-data purge procedure before go-live.

---

### AUDIT-28 🔵 Unbounded Patient Appointment History Query

**File:** `lib/services/booking_service.dart` line 233

`getAppointmentsForPatient` fetches a patient's entire appointment history unbounded. A patient with 3+ years of regular visits (200–500+ records) will load all into memory simultaneously, increasing Firestore read costs and degrading UI performance.

**Fix:** Paginate with a reasonable limit (e.g., last 100 records) or lazy-load older history on demand.

---

### Bug/Audit Summary Table

| ID | 🔴🟠🟡🔵 | Domain | Issue |
|---|---|---|---|
| AUDIT-01 | 🔴 | Security / UX | Test credentials visible in login UI |
| AUDIT-02 | 🔴 | Security | Firestore open to public internet — all PHI exposed |
| AUDIT-03 | 🔴 | Security | Doctor PINs plaintext in Firestore |
| AUDIT-04 | 🟠 | Security | No brute-force protection on PIN login |
| AUDIT-05 | 🟠 | Data Integrity | Firestore batch overflow in `closeDoctorSessionForDate` |
| AUDIT-06 | 🟠 | Schema | Ghost field `formattedAge` instead of `patientAgeDisplay` |
| AUDIT-07 | 🟠 | Clinical Integrity | TOCTOU race in single-doctor mode `notifyReadyForNext` |
| AUDIT-08 | 🟠 | Search / UX | Patient name search silently misses >50 patients |
| AUDIT-09 | 🟠 | Business Logic | Free review booking skips window & consumption checks |
| AUDIT-10 | 🟡 | Business Logic | Dual default fee constants can silently drift |
| AUDIT-11 | 🟡 | Dev UX | `blockedDates` comment shows wrong format for humans |
| AUDIT-12 | 🟡 | Security | Double-hashing will break on QOL-12 implementation |
| AUDIT-13 | 🟡 | Clinical Integrity | Discard path leaves appointment stuck as `inConsultation` |
| AUDIT-14 | 🟡 | UX | Statistics date pickers have inconsistent bounds |
| AUDIT-15 | 🟡 | Performance | Offline cache writes on every Firestore event |
| AUDIT-16 | 🟡 | Architecture | `DoctorChamberScreen` bypasses DI — own service instances |
| AUDIT-17 | 🟡 | Clinical Integrity | `lastVisitDate` uses client clock (drift = wrong free review) |
| AUDIT-18 | 🟡 | SaaS / Ops | Static `ClinicConfig` requires recompile per tenant |
| AUDIT-19 | 🔵 | Ops | No counter document archiving strategy |
| AUDIT-20 | 🔵 | Ops | Single-doctor query missing Firestore index |
| AUDIT-21 | 🔵 | Stability | No input length limits on clinical free-text fields |
| AUDIT-22 | 🔵 | Business Logic | No `availableDays` check in advance booking |
| AUDIT-23 | 🔵 | Security | Plaintext default PINs exposed as `AuthProvider` getters |
| AUDIT-24 | 🔵 | UX | No debounce on print button (double-print risk) |
| AUDIT-25 | 🔵 | Analytics | `free` metric includes `unpaid` appointments |
| AUDIT-26 | 🔵 | Business / Ops | Subscription expiry has no runtime enforcement |
| AUDIT-27 | 🔵 | Ops | Default test medicines unsuppressible in production |
| AUDIT-28 | 🔵 | Performance | Unbounded patient appointment history query |

---

## 📋 Section 2: QOL Feature Backlog

> All pending Quality-of-Life enhancements and feature requests. PM must explicitly approve items before implementation begins.

### QOL-01 — Emergency / Illiterate Walk-In Dummy Key (P13)

**Domain:** Reception Desk  
**Problem:** Emergency or elderly village patient arrives without a mobile number. Registration mandates a 10-digit phone key, blocking immediate token issuance.  
**Specification:**
- 1-tap `[No Mobile / Emergency Dummy]` toggle at walk-in registration.
- Allocates sequential clinic dummy phone keys (`9900000001`+) tied to the tenant.
- Generates immediate atomic queue tokens via `counters/queue_{doctorId}_{date}` without breaking database integrity.

---

### QOL-02 — Thermal POS Token Slip Printing

**Domain:** Reception Desk  
**Affected Files:** `lib/widgets/print/token_receipt_dialog.dart`, `lib/utils/platform_print_web.dart`  
**Problem:** Standard web printing triggers the browser's full-page preview. Token receipt slips need an isolated layout for thermal paper rolls.  
**Specification:**
- Dedicated CSS print stylesheet and hidden DOM iframe for 58mm / 80mm thermal receipt slips.
- Sub-second monochrome print execution at counter desk.

---

### QOL-03 — Prepaid Carry-Over & Doctor No-Show / Refund Protocol (P11 / RFC-2)

**Domain:** Reception / Financial Ledger  
**Status:** Doctor Absence / Session Cancellation ✅ implemented in v1.39.0. Patient No-Show Carry-Forward 📋 pending.  
**Pending Specification:**
- Reception option to "Revalidate Yesterday's Paid Token" — generates today's atomic token linked to yesterday's payment reference with ₹0 fresh collection.

---

### QOL-04 — Patient Demographics Edit from Encounter Header

**Domain:** Doctor Chamber  
**Affected Files:** `lib/widgets/encounter/patient_header_section.dart`, `lib/screens/consultation_encounter_screen.dart`, `lib/services/patient_service.dart`  
**Problem:** Reception frequently makes minor spelling or age errors during rush registration. Doctor cannot fix them from inside the encounter.  
**Specification:**
- Allow doctor to inline-edit patient name, age, and gender from the encounter patient header.
- Updates `patients` Firestore record and active appointment without closing the encounter or losing staged medications/vitals.

---

### QOL-05 — Per-Doctor Saved Prescription Templates (Replaces Hardcoded P9 Presets)

**Domain:** Doctor Chamber  
**Affected Files:** `lib/models/prescription_template.dart`, `lib/screens/consultation_encounter_screen.dart`, `lib/config/clinic_config.dart`  
**Problem:** Hardcoded GP condition presets (URI, Gastritis, Viral Fever) are generic and irrelevant to specialists.  
**Specification:**
- Doctors save their own regimens from active encounters to personal profiles (`doctor_templates` Firestore collection).
- Replaces hardcoded presets without backward-compatibility debt.

---

### QOL-06 — Fullscreen Waiting Hall Queue Display Board `/display` (P15 · 🧪 Experiment)

**Domain:** Waiting Hall  
**Problem:** Counter assistants must repeatedly shout patient names; patients crowd reception to check their turn.  
**Specification:**
- Fullscreen responsive route (`/display`) for counter-facing tablets or waiting hall Android/Smart TVs.
- Real-time subscription to `counters/chamber_{doctorId}_{date}`.
- Displays active calling tokens, room numbers, upcoming tokens, and in-browser audio chimes.
- High-contrast display readable across waiting hall distance.
- **🧪 Experiment:** Hardware variation on lobby TVs (Chromecast, Android TV, Fire Stick) and persistent WebSocket stability over 8-hour shifts is unproven.
- **Promotion criteria:** Validated in active clinic lobby TV running continuously for 1 full shift with zero freezes.

---

### QOL-07 — Multi-Shift / Split Daily OPD Timings (P16)

**Domain:** Scheduling  
**Problem:** Some physicians sit for two distinct shifts (e.g., `10:00 AM – 1:00 PM` and `6:00 PM – 8:30 PM`). Single shift timing cannot segment daily quotas per shift.  
**Specification:**
- Data model and counter expansion for multi-session schedules per duty day.
- Distinct morning and evening token quotas and separate chamber calling runs.

---

### QOL-08 — Doctor Extended Credentials, Accolades & Bio (P17)

**Domain:** Roster / Print  
**Problem:** Physicians with long qualification strings need professional display without bloating counter roster labels.  
**Specification:**
- Structured `qualifications` and `biography` fields in `Doctor` model.
- Displayed on letterheads, prescription printouts, and doctor detail modals; compact on queue cards.

---

### QOL-09 — Multi-Specialty Department Tagging (P18)

**Domain:** Registration  
**Problem:** Physicians practicing across combined sub-specialties (e.g., `"General Medicine + Diabetology"`) need to be discoverable under multiple specialty filters.  
**Specification:**
- Array-based department tagging allowing doctors to be found under multiple clinical specialty filters at walk-in registration.

---

### QOL-10 — Shift Handover Time-Window Partitioning

**Domain:** Financial Ledger  
**Affected Files:** `lib/core/engines/cash_handover_engine.dart`, `lib/widgets/dashboard/daily_cash_handover_dialog.dart`  
**Problem:** Cash handover aggregates all tokens across the entire date. Multi-shift clinics with morning and evening receptionists need shift-specific drawer reconciliation.  
**Specification:**
- Upgrade `CashHandoverEngine` to support time-window filtering (Morning vs. Evening shift) for end-of-day drawer handover.

---

### QOL-11 — Remove Hardcoded Admin PIN Fallback & Credential Leak

**Domain:** Security / Auth  
**Affected Files:** `lib/providers/auth_provider.dart` lines 173–176, 228–230, 269–270; `lib/screens/login_screen.dart`  
**Specification:**
- Remove hardcoded default admin PIN `849201` fallback once the owner PIN is initialized.
- Purge credential leak helper strings from error UI. (See also: AUDIT-01 which covers the UI-visible leak specifically.)

---

### QOL-12 — Doctor PIN Hashing & Chamber View Impersonation Lock

**Domain:** Security / Chamber  
**Affected Files:** `lib/models/doctor.dart`, `lib/screens/doctor_list_screen.dart`, `lib/screens/doctor_chamber_screen.dart`  
**Specification:**
- Hash Doctor PINs before writing to the `doctors` collection. (See also: AUDIT-03, AUDIT-12.)
- Enforce strict chamber preview lock: preview mode displays view-only telemetry and suppresses all consultation triggers and door admissions without entering the doctor's PIN.

---

### QOL-13 — Cloud-Synced PIN Store & Security Settings UI

**Domain:** Security / Auth  
**Affected Files:** `lib/providers/auth_provider.dart` lines 304–320  
**Specification:**
- Store hashed Owner and Reception PINs in Firestore (`clinic_config/security`) rather than local browser storage only, enabling synchronized PIN changes across all clinic terminals.
- Administrative Security Settings dialog for PIN rotation with recovery passkey.

---

## 💡 Section 3: Product Ideas Under Evaluation

> Not approved for implementation. PM review required before entering the backlog.

### IDEA-1 — Full Clinic Data Export (CSV / Excel)

Provide a 1-click mechanism for clinic owners to export all operational data (appointments, patient registry, financial ledger, consultations, master medicine list) as `.csv` or `.xlsx`.

- **Architecture:** Client-side Firestore collection snapshot serialization via pure Dart. Web download via `dart:js_interop` HTML anchor blob. Zero patient data leaves through third-party servers.
- **Use cases:** End-of-month accountant audits, external tax filing, local backup, and — critically — data migration out during the subscription grace period before shutdown.
- **Priority signal:** This is directly tied to the SaaS subscription model exit flow. High priority for production SaaS readiness.

---

### IDEA-2 — Prescribe-to-Formulary Auto-Ingest

When a doctor prescribes an unlisted drug, a subtle checkbox `[☑ Add to Clinic Formulary]` auto-ingests it with minimum metadata (product name + formulation form) into `/medicines` for future auto-complete.

- **Architecture:** The `RxSearchResultsView` already stages unlisted items; this adds one checkbox and a `CatalogueService.addMedicine()` call on sign-off.
- **Ingest guard:** Require minimum product name + formulation form before saving to prevent catalogue pollution from typos.

---

### IDEA-3 — In-Built Master Medicine Editor

GUI editor for catalogue medicines inside `MedicineCatalogueScreen` — opening `AddMedicineDialog(medicineToEdit: item)` and calling `CatalogueService.updateMedicine()`.

- **Role guard:** Restricted to owner PIN session.
- **Longitudinal safety:** Modifying a brand name or composition only affects future auto-completes; historical `PrescriptionItem` snapshots are immutable.
- **Effort:** Low — `AddMedicineDialog` already has full validation UI.

---

### IDEA-4 — Anonymized Prescription Volume Telemetry (Regional Intelligence)

A decoupled external analytics sink collecting pure aggregate counts of prescribed medicines by region and date, stripped of all patient and doctor identity.

- **Architecture:** Asynchronous fire-and-forget HTTP ping to independent ingestion pipeline. Zero impact on chamber experience. Zero PHI.
- **Payload:** `{ region, date, composition, brand, form }` — no `doctorId`, `clinicId`, patient fields.
- **Regulatory guards:** NMC strictly prohibits tracking individual physician prescribing patterns; must aggregate across all clinics per region only.

---

## 🗺️ Section 4: Roadmap & Hardening Runway

### 4.1 Anti-Goals (Never Build These)

1. ❌ **Pharmacy Inventory ERP** — No batch numbers, expiry dates, distributor invoices, or stock counts.
2. ❌ **Retail POS Billing** — No OTC goods, no retail counter.
3. ❌ **Complex Accounting / Tally Ledger** — Ledger exists only for daily token audits and doctor fee reconciliation.
4. ❌ **Inpatient / Bed Management (IPD)** — Strictly outpatient OPD.
5. ❌ **Destructive Clinical Edits** — Past consultations append-only forever.

---

### 4.2 Current Capability Matrix

| Domain | Core Capabilities | Guarantee |
|---|---|---|
| **Architecture & State** | Decomposed `ClinicProvider` facade with `DoctorStateDelegate`, `LiveQueueDelegate`, `CatalogueDelegate`. Fine-grained `context.select` subscriptions. | Sub-second performance, zero cascading re-renders. |
| **Paediatric & Household Identity** | Decoupled canonical `patientId` from phone. Family member picker chips. Structured paediatric demographics. Guardian attribution. | Household integrity — master directory merge never erases family dependents. |
| **Audit-Proof Queue** | Atomic consecutive daily tokens. Keyboard-first walk-in booking. Duplicate booking guard. 2-stage `booked → waitingInLobby` flow. Offline fallback cache. | Zero deletions. Zero token pre-emption. |
| **Doctor Chamber Handshake** | 5-state synchronized handshake. Atomic single-occupancy lock. Pause & step-out protocol. Reception resume. FIFO lobby queue. Emergency door override (top 1–2 paid lobby patients only). Historical read-only archive. | Doctor-paced. No forced chamber admission. Historical dates immutable. |
| **Clinical Encounter** | Append-only consultations. Free-form modular encounter (HK-1). Local draft persistence. PopScope exit guard. 3-state medication reconciliation. Prescription snapshot immunity. Unified 2-column drug search. | Longitudinal integrity. Past visits never mutated. |
| **3-Tier Security & Ledger** | Owner (6-digit), Doctor (4-digit), Reception (`0000`). Owner-exclusive doctor CRUD & fee config. Free review 0–30 day window. Daily cash handover modal. | Role isolation. Zero unearned review chaining. |
| **Print & Communication** | Monochrome A4/A5 prescription printing. WhatsApp deep-link summaries. Web Audio API dual-tone chime. SpeechSynthesis multi-chamber announcer. | High-contrast monochrome. Zero PHI to third-party endpoints. |
| **Pure Domain Engines** | `RevenueEngine`, `AppointmentEngine`, `MedicineEngine`, `WhatsAppEngine`, `CashHandoverEngine`, `PatientSearchEngine`. 306 passing automated tests. | Zero business logic in UI widget `build()` methods. |

---

### 4.3 Active Hardening Focus (Pre-2.0 Release Gate)

1. **Physical Counter Form-Factor Verification:**
   - 21.5"–24" FHD monitors — side-by-side queue and roster fill up to 1800px without dead margins.
   - 14"/15.6" laptops (1366×768 / 1536×864) — live queue visible above the fold without forced scrolling.

2. **Hardware Printing Calibration:**
   - Physical print test runs on pre-printed doctor letterhead pads.
   - Fine-tune `ClinicConfig.defaultLetterheadTopMarginMm` presets and thermal receipt roll alignment.

3. **Operational Edge-Case Hardening:**
   - Multi-doctor chamber dispatch and step-out pause workflows at peak OPD hours.
   - End-of-day cash handover reconciliation for multi-doctor clinics.

4. **Final 2.0 Certification Gate:** Zero open blocker bugs, zero test regressions, full PM operational validation.

---

### 4.4 Scrapped & "Do Not Re-Implement" Log

| Discarded Feature | Why Scrapped | AI Prevention Rule |
|---|---|---|
| **Pharmacy Inventory & Batch Tracking** | Creates administrative ERP overload. | Never add batch, expiry, or stock ledger collections. |
| **Retail Counter POS Billing** | Distracts counter from token flow. | Keep billing restricted to doctor consultation tokens. |
| **Modal Prescribing Dialogs** | 4+ clicks per drug; interrupts clinical view. | Keep medication search inline within the encounter body. |
| **Destructive Prescription Overwrite** | Destroys medical-legal audit history. | Consultations strictly append-only. Use `CONTINUE`/`STOP` actions. |
| **Queue Item Deletion** | Enables financial leakage and cheating. | Mark as `AppointmentStatus.absent` at ₹0. Never delete. |
| **Atomic Multi-Desk Booking Locks (`counters/lock_*`)** | 95%+ of clinics have 1 counter. Queue counter transaction already serializes tokens. | Do not re-add distributed lock collections. |
| **Forensic Audit Events Collection (`appointment_events`)** | Write-only sink, zero UI consumers, doubles Firestore writes. | Store lifecycle timestamps directly on `Appointment`. Never re-add `appointment_events`. |
| **`PaymentType.freeConcession`** | Fully redundant with `PaymentType.freeFamily`. | Use `freeFamily` for all authorized discretionary waivers. Never add redundant payment type variants. |

---

### 4.5 Resolved RFCs

**RFC-1: Strict 1-Time Free Review Cycle Model** ✅ Resolved in v1.22.0
- Each paid encounter unlocks exactly **one** free review within the doctor's configured `freeReviewDays` window.
- Once consumed, the entitlement is permanently marked consumed; next visit must be paid.
- Doctor-opt-in: `freeReviewDays == 0` disables free reviews entirely.

**RFC-2: Prepaid Token Carry-Forward vs. Doctor No-Show Refund** → Migrated to QOL-03 above.

---

## 🧪 Section 5: Experiment Flag Registry

Experiments are revocable, have no test coverage mandate, introduce no schema lock-in, and must never gate the core booking/queue/encounter pipeline.

| Feature | Status | Gate Condition | Promotion Criteria |
|---|---|---|---|
| **Multi-Chamber Sound Announcer** | 🟢 Shipped v1.29.0 | `ClinicConfig` (default on) | Validated across ≥3 real clinic deployments with stable chime delivery and zero browser crashes. |
| **Prescription Template Presets (P9)** | 🟢 Shipped v1.28.0 | `enablePrescriptionTemplatePresets` (default: `false`) | Replaced by QOL-05 user-saved templates without backward-compat shims. |
| **Grouped Composition Cards** | 🟢 Shipped v1.35.0 | `enableGroupedCompositionCards` | Validated by physician prescribing velocity feedback during peak OPD hours. |
| **Waiting Hall Display Board (P15)** | 📋 Planned | See QOL-06 | Validated in active clinic lobby TV running 1 full shift with real-time token shifts and zero browser freezes. |

---

## ⚖️ Section 6: Compliance & Privacy Reference

### 6.1 Regulatory Framework

GuwahatiOne Clinic OS adheres to:

1. **Digital Personal Data Protection (DPDP) Act, 2023:**
   - Explicit purpose specification: patient data processed strictly for clinical diagnosis, prescribing, and audit-proof token allocation.
   - Purpose limitation: non-clinical staff (receptionists) are restricted from seeing physician clinical examination notes and provisional diagnoses.

2. **National Medical Commission (NMC) Registered Medical Practitioner Regulations:**
   - Preservation of OPD prescription and consultation records for a minimum statutory period of **3 years**.
   - Mandatory inclusion of State Medical Council / NMC registration numbers on all printed outputs (`medicalRegNumber`).

3. **Ayushman Bharat Digital Mission (ABDM) Health Data Management Policy:**
   - Longitudinal clinical encounters as immutable append-only events.
   - Distinct patient directory keyed by primary 10-digit mobile contact.

---

### 6.2 Role-Based Access Control (RBAC) Matrix

| Data Category | Owner (Master PIN) | Doctor (Chamber PIN) | Receptionist (Counter PIN) |
|---|:---:|:---:|:---:|
| Patient Demographics (Name, Phone, Age, Gender) | ✅ Full | ✅ Full | ✅ Full |
| Allergy Alerts | Read-only | Full (Alert Trigger) | Read-only |
| Clinical Examination & Vitals | ❌ No Access | ✅ Full Read/Write | ❌ No Access |
| Past Diagnostic Reports & Lab Orders | ❌ No Access | ✅ Full Read/Write | ❌ No Access |
| Prescription History (START/CONTINUE/STOP) | ❌ No Access | ✅ Full Read/Write | ❌ (Print only on direct dispense) |
| Daily Queue Token Roster | Read-only | Read-only (Assigned Chamber) | ✅ Full Dispatch Control |
| Financial Ledger & Cash Handover | ✅ Full Audit | Individual Fee Summary Only | Daily Counter Drawer Tally Only |
| Doctor Fee Configuration & Profiles | ✅ Full Admin CRUD | View Only | View Only |

---

### 6.3 Audit Trail & Lifecycle Immutability

| Lifecycle State | Audit Mechanism | Guarantee |
|---|---|---|
| **Booked / Expected** | `appointments` document created | Atomic token ($1…N), fee recorded, `scheduledDate` timestamped. |
| **Checked-In** | Desk check-in transition | Realized payment method reconciled, `checkedInAt` stamped. |
| **In Consultation** | Chamber handshake transition | Occupancy collision lock verified, chamber session updated. |
| **Completed** | Append-only `consultations` record | Permanent prescription appended, `status: completed`, `lastVisitDate` updated. |
| **Absent / No-Show** | Status set to `absent` | Token slot preserved permanently, `amountCollected: 0` locked. |

---

### 6.4 Data Export & Subscription Exit Protocol

Under the annual SaaS subscription model with 1-month grace period:
- Clinics must be able to export all data (appointments, patients, consultations, financial ledger, medicines) as CSV before the grace period ends.
- Exports run entirely client-side (Firestore snapshot → Dart CSV serialization → browser download). Zero PHI transits third-party servers.
- See **IDEA-1** (Section 3) for the full export implementation specification.

---

## 🤖 Section 7: AI Engineering Guidelines

> Concise operational rules for AI coding assistants. See [`AGENTS.md`](../AGENTS.md) for the full canonical constitution.

### 7.1 Mandatory Before Any Change

1. Read `AGENTS.md` — non-negotiable invariants and red lines.
2. Read `docs/SCHEMA_AND_MODELS.md` — never invent Firestore field names.
3. Plan first, code second. For multi-file changes, present affected files and schema diffs to PM before executing.

### 7.2 Verification Gate (Every Change)

```sh
flutter analyze   # Zero errors, zero warnings
flutter test      # All 306+ tests pass
```

### 7.3 Clean Separation of Concerns

| Layer | Location | Rule |
|---|---|---|
| Domain Logic | `lib/core/engines/` | 100% pure Dart. Zero Flutter imports. Financial math, review eligibility, drug search scoring, queue partitioning. |
| Data Models | `lib/models/` | Pure data schemas + JSON serialization. UI-free. |
| Firestore Operations | `lib/services/` | Modular service classes. One concern per service. |
| State | `lib/providers/` | `ChangeNotifierProvider` only. No Riverpod, Bloc, GetX. |
| Screens | `lib/screens/` | Thin coordinator scaffolds — layout bounds, navigation triggers, lifecycle only. |
| Widgets | `lib/widgets/` | Reusable presentation components. Receive data, emit callbacks. |

### 7.4 What the PM Configures Directly

| File | What to Edit |
|---|---|
| `lib/config/clinic_config.dart` | `ClinicFeatureFlags` — runtime feature toggles and experiments. |
| `lib/utils/app_constants.dart` | `blockedDates` (ISO `YYYY-MM-DD` internally), default fee fallback. |
| `pubspec.yaml` | `version`, `name`, `description`. |
| `lib/firebase_options.dart` | Re-generated by `flutterfire configure` when switching Firebase projects. Never commit secrets. |
| `assets/` | Replace `icon.png` for branding. |

### 7.5 Changelog Rules

- Format: `## [x.y.z] — DD-MM-YYYY`
- Consolidate patch releases into minor series range entries: `## [1.36.0 – 1.36.5] — DD-MM-YYYY`
- Never add Verification Gate sections or test pass counts to `CHANGELOG.md`
- Always inform the PM explicitly if a breaking change is introduced
