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
   - Operating across **3 distinct physical hardware stations**:
     1. **Doctor Chamber Devices:** 1–3 consulting physicians running simultaneously on tablets, laptops, or desktops. Multiple doctors consult concurrently in their respective chambers.
     2. **Reception Counter PC:** Typically a single dedicated PC handling walk-in booking, atomic token allocation, arrival verification, upfront fee reconciliation, and thermal receipt slip printing.
     3. **Clinic Owner / Admin Device:** A single mobile or desktop session used occasionally for fee configuration, doctor roster management, security PIN rotation, and financial tax audits.

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
   - **Zero Security Through Obscurity:** Because the full repository is public, anyone can inspect the codebase, API models, and Firestore rules. Hardcoded test credentials (such as default PINs in UI/providers) represent security risks. For the private on-premise clinic pilot, trusted stations operate behind domain-salted SHA-256 PINs; strict Firebase Auth rules are scheduled for multi-tenant SaaS deployment before public hosting.

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

### AUDIT-01 🟢 [RESOLVED] Hardcoded Test Credentials Displayed in Login UI

**Files:** `lib/screens/login_screen.dart`, `lib/providers/auth_provider.dart`

Default admin and reception PINs (`849201` and `0000`) were previously visibly on-screen in hints, helper texts, and error messages.

**Status:** Resolved in v1.40.6. Removed all default PIN helper/hint/error strings from `LoginScreen`. Replaced with neutral failure messages (`'Incorrect PIN. Please try again.'` and `'Incorrect PIN for Dr. [Name]. Please try again.'`). Zero credentials are leaked in the UI.

---

### AUDIT-02 🟡 [DEFERRED TO SAAS PHASE] Firestore Security Rules Hardening

**File:** `firestore.rules`

Every collection currently allows open read/write access. Under production SaaS multi-tenancy, collections must require authenticated client sessions (`request.auth != null`).

**PM Decision (22-10-2026):** Formally deferred for the current on-premise clinic pilot. The clinic runs exclusively on 3 trusted internal hardware stations (receptionist PC, simultaneous doctor devices, owner device) protected by domain-salted SHA-256 PIN authentication. Enforcing Firebase Anonymous Authentication requires pre-configuring Firebase Console settings (failing with `operation-not-allowed` if omitted) and introduces offline cold-boot hydration failures during Tier 2 broadband dropouts. Strict Firebase Auth rules will be implemented for the multi-tenant SaaS cloud rollout.

---

### AUDIT-03 🔴 [CANCELLED / SCRAPPED BY DESIGN] Doctor PIN Hashing at Rest

**Files:** `lib/models/doctor.dart`, `lib/providers/auth_provider.dart`

**Decision (22-10-2026):** Formally scrapped by design per PM directive. In a real-world OPD clinic, visiting physicians rotate across 2–4 clinics per week and regularly forget their 4-digit chamber PINs. Cryptographic one-way hashing forces time-consuming manual resets. Storing readable 4-digit PINs in the `doctors` collection allows the Clinic Owner to instantly look up and remind the physician (`Chamber PIN: 1234` in `DoctorListScreen`) in 5 seconds. In an internal clinic with no public web access, plaintext doctor PINs are an intentional operational convenience.

---

### AUDIT-04 🔴 [CANCELLED / SCRAPPED BY DESIGN] Brute-Force Rate Limiting & Screen Lockout

**Files:** `lib/screens/login_screen.dart`, `lib/providers/auth_provider.dart`

**Decision (22-10-2026):** Formally purged from codebase in v1.40.9 per PM directive. In a busy clinic during peak morning OPD rush, an accidental mistyped PIN locking the counter terminal for 30–60 seconds halts walk-in registration, delays token issuing, and creates furious queues in the physical lobby. For an on-premise clinic tool used by 3 trusted staff roles, screen lockout is an operational hazard rather than a security benefit. The terminal now immediately displays an inline error without freezing the desk.

---

### AUDIT-05 🟢 [RESOLVED] Batch Size Limit Not Enforced in `closeDoctorSessionForDate`

**File:** `lib/services/booking_service.dart` lines 328–356

Firestore batch writes have a hard 500-operation limit. `closeDoctorSessionForDate` previously added all appointments for a doctor-date into a single batch without a size guard. In a polyclinic with accumulated advance bookings, this would throw a Firestore exception mid-operation, leaving the session partially-closed.

**Status:** Resolved in `lib/services/booking_service.dart`. Document updates are now chunked into safe batches of 450 items and committed sequentially.

---

### AUDIT-06 🟢 [RESOLVED] `saveConsultation` Writes a Ghost Field `formattedAge` to Patient Documents

**File:** `lib/services/consultation_service.dart` line 55

The canonical `patients` schema uses `patientAgeDisplay`, not `formattedAge`. Previously, `'formattedAge'` was written to patient documents on consultation completion.

**Status:** Resolved in `lib/services/consultation_service.dart`. Key renamed to canonical `'patientAgeDisplay'`.

---

### AUDIT-07 ⚪ [CANCELLED / INAPPLICABLE FOR MULTI-DOCTOR CLINICS] TOCTOU Race in `notifyReadyForNext` Single-Doctor Mode

**File:** `lib/services/chamber_service.dart` lines 151–169

**PM Decision (22-10-2026):** Formally cancelled/closed as inapplicable for multi-doctor clinics per PM directive. The clinic operates with multiple doctors consulting simultaneously (`enforceSingleActiveDoctor: false`, the system default). The single-doctor TOCTOU condition only applied to the artificial solo-doctor OPD booth flag. Multi-chamber clinics allow each doctor to independently manage their own chamber session without cross-doctor locks.

---

### AUDIT-08 🟢 [RESOLVED] Patient Name & Surname Search Scalability Beyond 50 Records

**Files:** `lib/services/patient_service.dart`, `lib/core/engines/patient_search_engine.dart`, `docs/SCHEMA_AND_MODELS.md`

Previously, the name search fallback in `searchPatients` loaded an arbitrary 50 documents from the `patients` collection into memory. When clinics exceeded 50 registered patients, searching by surname (*"Borah"*, *"Das"*) or middle name silently missed records, causing duplicate patient registrations and fractured clinical histories.

**Status:** Resolved in v1.40.10 (22-10-2026).
- Added `PatientSearchEngine.generateSearchTokens()` generating 2+ char n-grams and whole words for each term in the patient's name.
- Upgraded `PatientService.savePatient()` to automatically index `nameLower` (full lowercase string) and `searchTokens` (`List<String>`) on patient records in Firestore.
- Replaced the in-memory 50-limit scan with direct `array-contains` lookup on `searchTokens` and prefix range queries on `nameLower`.
- Eliminated all arbitrary document query ceilings while retaining legacy prefix query fallbacks.

---

### AUDIT-09 🟢 [RESOLVED] Free Review Booking Skips Window and Consumption Checks

**File:** `lib/providers/delegates/live_queue_delegate.dart` lines 258–285

When booking `PaymentType.freeReview`, `bookAppointment` previously only validated `hasVisitedDoctorEarlier`. It now enforces that the review has not been already consumed (`!isReviewAlreadyConsumed`) and that the visit is within the doctor-configured review period (`isWithinReviewPeriod`) using `selectedDoctor.freeReviewDays`.

**Status:** Resolved in `live_queue_delegate.dart`, `add_appointment_dialog.dart`, and `booking_payment_section.dart`. Added comprehensive unit and delegate test coverage.

---

### AUDIT-10 🟢 [RESOLVED] Dual Default Fee Constants Can Silently Drift

**Files:** `lib/utils/app_constants.dart`, `lib/core/engines/appointment_engine.dart` line 255, `lib/config/clinic_config.dart` line 43

`AppConstants.defaultConsultationFee = 500` previously acted as a separate engine fallback when `doctor` was null, bypassing `ClinicConfig.current.defaultConsultationFee`.

**Status:** Resolved. Removed `AppConstants.defaultConsultationFee` and updated `AppointmentEngine.resolveConsultationFee` and `BookingPaymentSection` to reference `ClinicConfig.current.defaultConsultationFee` directly.

---

### AUDIT-11 🟢 [RESOLVED] `blockedDates` Comment Shows YYYY-MM-DD but Humans Write DD-MM-YYYY

**File:** `lib/utils/app_constants.dart` lines 8–12

```dart
/// Globally blocked dates (clinic holidays).
///
/// NOTE: Internal comparison format is ISO 'YYYY-MM-DD' for programmatic checks only.
/// This is distinct from the mandatory 'DD-MM-YYYY' display format used everywhere else in the product.
static const List<String> blockedDates = [
  // Add clinic holiday dates in ISO format here, e.g.:
  // '2026-10-02',  // Gandhi Jayanti (02-10-2026)
];
```

**Status:** Resolved in `lib/utils/app_constants.dart` with explicit developer guidance distinguishing internal ISO format from the mandatory product-wide `DD-MM-YYYY` standard.

---

### AUDIT-12 🟡 Doctor PIN Double-Hashing Will Break When QOL-12 Is Implemented

**File:** `lib/providers/auth_provider.dart` line 301

```dart
if (hashPin(doctor.pin) == hashPin(pin)) {  // both sides hashed
```

This works today because `doctor.pin` is plaintext. Once doctor PINs are stored pre-hashed (QOL-12), `hashPin(hash_value)` will never equal `hashPin(entered_pin)`, permanently locking all doctors out. The correct post-QOL-12 form is `doctor.pin == hashPin(pin)`.

**Fix:** Resolve together with QOL-12. Flag this line explicitly so it is not missed.

---

### AUDIT-13 🟢 [RESOLVED] Discard Consultation Leaves Appointment Stuck as `inConsultation`

**File:** `lib/screens/consultation_encounter_screen.dart` lines 255–263

`_discardAndExitConsultation` previously cleared the local draft and signaled `ready_for_next` but failed to reset the appointment's `visitStatus` back to `waitingInLobby`. The appointment remained `inConsultation` in Firestore, making the patient appear "In Chamber" on the reception dashboard indefinitely.

**Status:** Resolved in `lib/screens/consultation_encounter_screen.dart`, `ClinicProvider`, `LiveQueueDelegate`, and `BookingService`. Added `returnAppointmentToLobby` and `discardConsultation`, properly resetting `visitStatus: waitingInLobby` and `isPaused: false`.

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

### AUDIT-22 🟢 [RESOLVED] Doctor Sitting Days (`availableDays`) Enforced in Advance Booking

**Files:** `lib/core/engines/appointment_engine.dart`, `lib/providers/delegates/live_queue_delegate.dart`, `lib/widgets/booking/add_appointment_dialog.dart`, `lib/widgets/booking/booking_duplicate_warning_banner.dart`

Advance booking validates `isDateBlocked` (holidays) and `isDoctorOnLeave` (personal leave) but previously skipped `AppointmentEngine.isDoctorAvailableOnDate`. In a multi-doctor clinic where visiting specialists rotate on specific weekdays (e.g. Mon/Wed/Fri), doctors could previously be booked in advance for non-sitting days.

**Status:** Resolved in v1.40.12 (22-10-2026).
- Upgraded `AppointmentEngine.isDoctorAvailableOnDate` to normalize both 3-letter abbreviations (`'Mon'`) and full names (`'Monday'`) with case-insensitivity and whitespace trimming.
- Enforced validation in `LiveQueueDelegate.bookAppointment`: throws exception `"$docTitle does not consult on ${dayName}s (Schedule: $schedule)."` when booking on off-days.
- Hardened `AddAppointmentDialog`: disables submission (`isDisabled == true`) and renders `BookingOffDayWarningBanner` instructing reception to pick an active OPD day.
- Covered by dedicated test suite in `test/doctor_sitting_days_advance_booking_test.dart`.

---

### AUDIT-23 🟢 [RESOLVED] `AuthProvider` Exposes Plaintext Default PINs as Public Getters

**File:** `lib/providers/auth_provider.dart`

Previously exposed unhashed default PIN strings as public getters (`receptionistPin` and `ownerMasterPin`).

**Status:** Resolved in v1.40.6. Removed public getters and purged in-memory plaintext PIN fields (`_receptionistPin` and `_ownerMasterPin`). All authentication routines and assertions strictly use domain-salted SHA-256 hashes (`receptionistPinHash`, `ownerMasterPinHash`).

---

### AUDIT-24 🔵 No Debounce on Prescription Print Button

**File:** `lib/screens/prescription_print_screen.dart`

The print button has no loading lock. A double-tap on a slow clinic PC triggers two concurrent browser print dialogs, wasting paper.

**Fix:** Add `bool _isPrinting` state guard — disable the button between the click and the browser print callback.

---

### AUDIT-25 🟢 [RESOLVED] `DoctorAnalyticsSummary.free` Count Includes `unpaid` Appointments

**File:** `lib/core/engines/revenue_engine.dart` lines 217–219

```dart
if (a.paymentType.isFree) {
  free++;
}
```

This previously counted `unpaid` advance bookings (not yet paid) as free consultations, inflating the "Free/Fam" metric on the Statistics screen.

**Status:** Resolved in `lib/core/engines/revenue_engine.dart`. Changed condition to `if (a.paymentType.isFree)` which strictly targets `freeReview` and `freeFamily`.

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
| AUDIT-01 | 🟢 (Resolved) | Security / UX | Test credentials visible in login UI |
| AUDIT-02 | 🟡 (Deferred) | Security | Firestore rules hardening deferred to SaaS multi-tenancy |
| AUDIT-03 | 🔴 (Scrapped) | Security | Doctor PINs plaintext in Firestore (intentional operational lookup) |
| AUDIT-04 | 🟢 (Resolved) | Security | No brute-force protection on PIN login (purged lockout) |
| AUDIT-05 | 🟢 (Resolved) | Data Integrity | Firestore batch overflow in `closeDoctorSessionForDate` |
| AUDIT-06 | 🟢 (Resolved) | Schema | Ghost field `formattedAge` replaced with `patientAgeDisplay` |
| AUDIT-07 | ⚪ (Inapplicable) | Clinical Integrity | Single-doctor TOCTOU cancelled for concurrent multi-doctor clinics |
| AUDIT-08 | 🟢 (Resolved) | Search / UX | Patient name search silently misses >50 patients |
| AUDIT-09 | 🟢 (Resolved) | Business Logic | Free review enforces window, consumption, and doctor policy |
| AUDIT-10 | 🟢 (Resolved) | Business Logic | Dual default fee constants can silently drift |
| AUDIT-11 | 🟢 (Resolved) | Dev UX | `blockedDates` comment shows wrong format for humans |
| AUDIT-12 | 🟡 | Security | Double-hashing will break on QOL-12 implementation |
| AUDIT-13 | 🟢 (Resolved) | Clinical Integrity | Discard path leaves appointment stuck as `inConsultation` |
| AUDIT-14 | 🟡 | UX | Statistics date pickers have inconsistent bounds |
| AUDIT-15 | 🟡 | Performance | Offline cache writes on every Firestore event |
| AUDIT-16 | 🟡 | Architecture | `DoctorChamberScreen` bypasses DI — own service instances |
| AUDIT-17 | 🟡 | Clinical Integrity | `lastVisitDate` uses client clock (drift = wrong free review) |
| AUDIT-18 | 🟡 | SaaS / Ops | Static `ClinicConfig` requires recompile per tenant |
| AUDIT-19 | 🔵 | Ops | No counter document archiving strategy |
| AUDIT-20 | 🔵 | Ops | Single-doctor query missing Firestore index |
| AUDIT-21 | 🔵 | Stability | No input length limits on clinical free-text fields |
| AUDIT-22 | 🟢 (Resolved) | Business Logic | Doctor sitting days enforced in advance booking |
| AUDIT-23 | 🟢 (Resolved) | Security | Plaintext default PINs exposed as `AuthProvider` getters |
| AUDIT-24 | 🔵 | UX | No debounce on print button (double-print risk) |
| AUDIT-25 | 🟢 (Resolved) | Analytics | `free` metric includes `unpaid` appointments |
| AUDIT-26 | 🔵 | Business / Ops | Subscription expiry has no runtime enforcement |
| AUDIT-27 | 🔵 | Ops | Default test medicines unsuppressible in production |
| AUDIT-28 | 🔵 | Performance | Unbounded patient appointment history query |

---

## 📋 Section 2: QOL Feature Backlog

> All pending Quality-of-Life enhancements and feature requests. PM must explicitly approve items before implementation begins.

### QOL-01 🟢 [RESOLVED] — Emergency / Illiterate Walk-In Dummy Key (P13)

**Domain:** Reception Desk  
**Status:** Resolved in v1.40.11. Added `AppointmentEngine.generateEmergencyDummyPhone()` generating `99`-prefixed collision-resistant phone keys (`9922105432`), 1-tap `[⚡ No Phone]` walk-in button, and amber notification suppression alert in `BookingPatientFields`.
**Problem:** Emergency or elderly village patient arrives without a mobile number. Registration mandates a 10-digit phone key, blocking immediate token issuance.  
**Specification:**
- 1-tap `[No Mobile / Emergency Dummy]` toggle at walk-in registration.
- Allocates sequential clinic dummy phone keys (`9900000001`+) tied to the tenant.
- Generates immediate atomic queue tokens via `counters/queue_{doctorId}_{date}` without breaking database integrity.

---

### QOL-02 ❌ [CANCELLED / SCRAPPED BY DESIGN] — Thermal POS Token Slip Printing

**Domain:** Reception Desk  
**Affected Files:** `lib/widgets/print/token_receipt_dialog.dart`, `lib/utils/platform_print_web.dart`  
**Decision (22-10-2026):** Formally scrapped per PM directive. Physical thermal roll token slips are not needed at the clinic counter. Walk-in tokens and waiting times are tracked digitally on live screens, reception queue cards, and via WhatsApp digital receipts. Eliminates unnecessary thermal printer hardware coupling and roll alignment maintenance.

---

### QOL-03 — Prepaid Carry-Over & Doctor No-Show / Refund Protocol (P11 / RFC-2)

**Domain:** Reception / Financial Ledger  
**Status:** Doctor Absence / Session Cancellation ✅ implemented in v1.39.0. Patient No-Show Carry-Forward 📋 pending.  
**Pending Specification:**
- Reception option to "Revalidate Yesterday's Paid Token" — generates today's atomic token linked to yesterday's payment reference with ₹0 fresh collection.

---

### QOL-04 🟢 [RESOLVED] — Patient Demographics Edit from Encounter Header

**Domain:** Doctor Chamber  
**Status:** Resolved in v1.40.11. Added an edit action button in `PatientHeaderSection`, `EncounterDialogs.showEditPatientDemographicsDialog()`, and synchronized live state across `EncounterFormState`, `patients/{id}`, and `appointments/{id}` via `BookingService.updateAppointmentPatientName()`.
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

### QOL-11 🟢 [RESOLVED] — Remove Hardcoded Admin PIN Fallback & Credential Leak

**Domain:** Security / Auth  
**Affected Files:** `lib/providers/auth_provider.dart`, `lib/screens/login_screen.dart`  
**Status:** Resolved in v1.40.6.
- Removed hardcoded default admin PIN `849201` fallback in `AuthProvider.loginAsOwner`, `loginAsReceptionistOrOwner`, and `authenticateWithPin` once a custom Owner PIN is set.
- Purged all default PIN leak helper/hint strings from `LoginScreen` error and testing UI. Zero credentials are leaked on-screen. (See also: AUDIT-01).

---

### QOL-12 🔴 [CANCELLED / SCRAPPED BY DESIGN] — Doctor PIN Hashing & Chamber View Impersonation Lock

**Domain:** Security / Chamber  
**Affected Files:** `lib/models/doctor.dart`, `lib/screens/doctor_list_screen.dart`, `lib/screens/doctor_chamber_screen.dart`  
**Decision (22-10-2026):** Formally scrapped by design per PM directive.
- **Doctor PIN Hashing:** Cancelled (see AUDIT-03). Plaintext PIN storage in `doctors` is intentionally preserved so Clinic Owners can instantly look up forgotten PINs for visiting physicians.
- **Preview PIN Lock:** Cancelled. Front-desk receptionists and clinic owners legitimately need to preview doctor queue occupancy from their terminals without entering the doctor's private PIN.
- **Zero Pre-emption / Accidental Calling Guarantee:** Handshake architecture already enforces that reception cannot dispatch or chime patients while a doctor is examining someone or on break (`onDispatch = null` unless chamber status is `ready_for_next`). The system is structurally immune to pre-emption by design without adding artificial PIN barriers.

---

### QOL-13 🟢 [RESOLVED] — Cloud-Synced PIN Store & Security Settings UI

**Domain:** Security / Auth  
**Affected Files:** [auth_provider.dart](file:///k:/Android/guwahatione-clinic-os/lib/providers/auth_provider.dart), [security_service.dart](file:///k:/Android/guwahatione-clinic-os/lib/services/security_service.dart), [security_settings_dialog.dart](file:///k:/Android/guwahatione-clinic-os/lib/widgets/dashboard/security_settings_dialog.dart), [owner_shell_app_bar.dart](file:///k:/Android/guwahatione-clinic-os/lib/widgets/common/owner_shell_app_bar.dart), [firestore_paths.dart](file:///k:/Android/guwahatione-clinic-os/lib/services/firestore_paths.dart)  
**Resolution Details:**
- **Cloud-Synchronized PIN Store (`clinic_config/security`):** Persists salted SHA-256 hashes (`ownerMasterPinHash`, `receptionistPinHash`, `updatedAt`, `updatedBy`) in Firestore.
- **Multi-Terminal Real-Time Sync:** `AuthProvider` initializes session from local `SharedPreferences` for sub-second offline boot and automatically streams updates from `SecurityService.securityStream()`, notifying listeners and updating local storage immediately upon remote PIN rotation.
- **Two-Step Security Settings Dialog:** Step 1 requires entering current 6-digit Owner Master Passkey. Step 2 allows changing 4-digit Receptionist Access PIN and/or 6-digit Owner Master Passkey with input length enforcement, confirmation matching, and 1-tap cloud synchronization.
- **Top Bar Integration:** Added high-contrast `[Security & PINs]` button in `OwnerShellAppBar` visible exclusively when logged in as Clinic Owner.
- **Comprehensive Test Suite:** Covered by 4 dedicated automated unit and widget tests in `test/security_settings_and_pin_sync_test.dart`.

---

### QOL-14 🟢 [RESOLVED] — Reconciled Regimen In-Place Duration Dropdown & Inline Dosage Editing

**Domain:** Doctor Chamber / Encounter  
**Affected Files:** [reconciliation_item_row.dart](file:///k:/Android/guwahatione-clinic-os/lib/widgets/encounter/rx/reconciliation_item_row.dart), [rx_reconciliation_section.dart](file:///k:/Android/guwahatione-clinic-os/lib/widgets/encounter/rx_reconciliation_section.dart)  
**Origin / Clinical Memory Dump:**  
> *"Telma 40 tablet [TELMISARTAN 40mg] | 1 tablet daily morning before food | to continue. Each and every part is editable. He can click on continue which is a dropdown and change to STOP, 3 days, 5 days, [custom]."*  
**Resolution Details:**
- **In-Place Duration Dropdown Menu:** Added a clinical duration dropdown directly on reconciled cards with presets (`To Continue`, `3 Days`, `5 Days`, `7 Days`, `14 Days`, `1 Month`, `SOS`, `STOP`, and `Custom...`). Selecting any continuation preset atomically switches action to `continueAction` and updates duration. Selecting `STOP` marks the item discontinued.
- **Custom Duration Dialog (`CustomDurationDialog`):** Number input dialog for arbitrary course durations in days with validation.
- **Inline Dosage & Timing Editing (`InlineDosageEditDialog`):** Tapping on the dosage/timing row (`Column 2`) opens a compact modal to adjust dosage quantity, frequency schedule, timing relation to food, and instructions without re-searching the catalogue. Also enabled for newly prescribed items.
- **Automated Test Suite:** Verified via 5 automated tests in `test/reconciliation_inline_editing_test.dart`.

---

### QOL-15 🟢 [RESOLVED] — Primary "Print Preview" Action Button on Encounter Bottom Dock

**Domain:** Doctor Chamber / Encounter  
**Affected Files:** `lib/screens/consultation_encounter_screen.dart`, `lib/widgets/encounter/consultation_bottom_dock.dart`  
**Origin / Clinical Memory Dump:**  
> *"then hits a button to do a preview. Basically you can say this 'print preview' of MS Word. 1 last step before prescription is printed. And clicks 'Sign and Complete' to print the prescription."*  
**Status:** Resolved in v1.40.5.
- Elevated "Print Preview" to a primary action button directly on `ConsultationBottomDock` alongside `[Finish Consultation & Sign]`.
- Desktop view renders a high-visibility outlined button (`OutlinedButton.icon`) with print icon; mobile view renders a dedicated `IconButton.outlined` with tooltip.
- Clicking triggers full modal preview of the strict 3-column prescription without premature encounter completion.

---

### QOL-16 🟢 [RESOLVED VIA ARCHITECTURE / SCRAPPED AS REDUNDANT] — Reception Emergency Encounter Fallback (Doctor PC Outage Failover)

**Domain:** Reception Desk / Clinical Continuity  
**Affected Files:** `docs/MASTER_BACKLOG.md`  
**Origin / Clinical Memory Dump:**  
> *"And if doctor PC goes down? then reception can take over and send in patient themselves but it's not readily accessible."*  
**Resolution & Scrapped Rationale (PM Directive 22-10-2026):**
- **Existing Native Mobile Chamber:** In the rare event of doctor PC terminal hardware failure, the doctor seamlessly logs into GuwahatiOne Clinic OS from their smartphone browser or mobile app. The mobile layout is already 100% responsive, allows signaling `Next Patient`, advancing the queue, and reviewing clinical history with zero desktop dependency.
- **Reception Paper Fallback:** If the doctor prefers to temporarily switch to physical pen-and-paper prescription pads during an outage, Reception already possesses the `[Mark Complete]` action in `AccordionStatusActions` to advance the queue and record the encounter as completed without typing clinical notes.
- **Zero Code Overhead:** Adding a heavy emergency encounter takeover UI on the reception desk was rejected as unnecessary complexity and a violation of clean role boundaries. Logged permanently in Section 4.4.

---

### QOL-17 🟢 [RESOLVED] — Explicit "Patient Already Registered" Visual Banner on Phone Match & Family Member Attribution

**Domain:** Reception Desk / Registration  
**Affected Files:** `lib/widgets/booking/booking_patient_fields.dart`, `lib/widgets/booking/add_appointment_dialog.dart`  
**Origin / Clinical Memory Dump:**  
> *"She enters Hira's phone number. It says 'patient already exist' and immediately pre-fills all details like name, age, etc."*  
**Status:** Resolved in v1.40.4.
- When an existing patient is selected, displays a compact green confirmation strip: `✅ Registered: [Name] ([Age]) • Auto-filled`.
- When switching to `+ Add Member` (child / relative under household phone), displays a concise blue banner: `👨‍👩‍👧 New Member for [PrimaryContactName]`.
- Added quick add-member icon button directly in the phone row next to discovery spinner.
- Pre-fills `Guardian Name` with primary contact's name and `Guardian Relation` with `'Parent / Guardian'` when registering a new dependent.
- Strictly budgeted within 460px modal width with single-line truncation (`TextOverflow.ellipsis`).

---

### QOL-18 🟢 [RESOLVED] — 1-Tap WhatsApp Clinical Summary from Patient Lookup History

**Domain:** Patient Lookup / Communications  
**Affected Files:** `lib/widgets/patient/doctor_consultation_accordion.dart`, `lib/screens/appointment_list_screen.dart`  
**Origin / Clinical Memory Dump:**  
> *"we also have a patient lookup (by both doc and reception) who can check past client reports. Say patient want a fresh copy or want a copy in their whatsapp, it is possible."*  
**Status:** Resolved in v1.40.5.
- Added direct 1-tap green `[WhatsApp Rx]` outlined button alongside `[View Prescription]` on each past consultation accordion card in Patient Lookup.
- Formats standard longitudinal prescription summary via `WhatsAppEngine.formatPrescriptionMessage` and launches browser deep-link (`WhatsAppEngine.buildDeepLink`) with floating confirmation feedback.

---

### QOL-19 — "Complete & Sign" Auto-Pushes to Print (Workflow Sequence Inversion)

**Domain:** Doctor Chamber / Encounter  
**Affected Files:** `lib/screens/consultation_encounter_screen.dart` (lines 179–199)  
**Origin / Clinical Memory Dump:**  
> *"then hits a button to do a preview. Basically you can say this 'print preview' of MS Word. 1 last step before prescription is printed. And clicks 'Sign and Complete' to print the prescription."*  
**Current Implementation State:**  
The implemented sequence is the **reverse** of the author's described flow:
1. Doctor clicks **`Complete & Sign`** → consultation is **saved to Firestore first**, chamber signals `consultation_ended`, draft is cleared.
2. *Then* the app auto-navigates to `PrescriptionPrintScreen` for the physical print.

In the author's mental model, preview comes *before* sign-off. In the implementation, save/sign comes *before* preview. This is not a bug per se — the print screen opens immediately after save, so the practical result is similar — but it means a doctor **cannot abort a signed consultation** from the print preview screen even if they realize a medication error at that stage.

**Specification:**
- Evaluate whether a "pre-sign preview" gate should be added: show print preview *before* committing the `saveConsultation` call, with a `[Confirm & Sign]` button on the preview screen that triggers the actual Firestore write and chamber `consultation_ended` signal.
- If the simpler approach is preferred: add a visible warning on the print screen — *"Consultation already signed and saved. To amend, contact the clinic administrator."* — so the doctor understands the record is finalized.
- Whichever route is chosen, document the decision here and update QOL-15 accordingly.

---

### QOL-20 ❌ [SCRAPPED] — Explicit "Skip Token / Stepped Out" Status Action on Reception Queue

**Domain:** Reception Desk / Queue  
**Affected Files:** `lib/widgets/queue/appointment_accordion.dart`, `lib/widgets/queue/accordion_status_actions.dart`  
**Origin / Clinical Memory Dump:**  
> *"Token #1 has stepped out to the medical shop across the street. Reception skips Token #1 without breaking the ledger, calls Token #2..."*  
**Scrapped Rationale (PM Directive):**
- Control to send in whom next lies 100% in receptionist hands.
- Reception can dispatch any present waiting patient (e.g. Token #11 or #12) without needing an artificial intermediate status for Token #10.
- If a patient steps out and returns, reception directly dispatches them when ready; adding a "stepped out" status introduces unnecessary operational and database state complexity with zero clinical benefit.
- Logged permanently in Section 4.4 (Scrapped Log).

---

## 💡 Section 3: Product Ideas Under Evaluation

> Not approved for implementation. PM review required before entering the backlog.

### IDEA-1 🟢 [RESOLVED] — Full Clinic Data Export (CSV / Excel)

**Status:** Resolved in v1.40.11. Implemented `DataExportEngine` (pure Dart RFC-4180 CSV serializer) exporting 5 complete datasets (Revenue & Tax Ledger, Appointments, Patient Directory, Medicines Formulary, Clinical Encounters) formatted with Indian dates (`DD-MM-YYYY`). Added `ClinicDataExportDialog` in `OwnerShellAppBar` and `StatisticsScreen` with client-side blob download via `dart:js_interop`.

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
| **Pure Domain Engines** | `RevenueEngine`, `AppointmentEngine`, `MedicineEngine`, `WhatsAppEngine`, `CashHandoverEngine`, `PatientSearchEngine`. 328 passing automated tests. | Zero business logic in UI widget `build()` methods. |

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
| **"Stepped Out" / "Skipped" Token Intermediate Queue Status (QOL-20)** | Dispatch authority lies 100% with receptionist who can call any lobby patient in any order; intermediate status adds state complexity with zero clinical benefit. | Never add stepped-out, skipped, or paused intermediate token statuses to the patient queue. |
| **Reception Emergency Encounter Takeover (QOL-16)** | Doctor smartphone already provides 100% responsive mobile chamber; for physical paper prescriptions, reception already has `Mark Complete`. Avoids UI bloat and role confusion. | Keep clinical encounter entry restricted to doctor chamber sessions; never add reception desk clinical takeover dialogs. |
| **Single-Doctor Chamber Mutex / Concurrency Lock (AUDIT-07)** | Real clinics operate multiple doctors consulting simultaneously across separate chambers. Artificially locking all chambers to one doctor creates counter bottlenecks. | Never introduce global single-doctor mutex locks across independent doctor chambers. |
| **Thermal POS Token Slip Printing (QOL-02)** | Unnecessary hardware coupling and roll alignment maintenance. Queue tokens and waiting times are tracked digitally on live screens and WhatsApp. | Rely on digital queue cards and screens; avoid adding dedicated thermal receipt layouts. |

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

---

## 🔍 Section 8: Author Memory Dump — Mini-Review Verdict (21-10-2026)

> This section records the outcome of a code-verified cross-check between the author's first-person narrative ("clinical memory dump") describing how ClinicOS is supposed to behave, and the actual codebase as it exists today. Items marked **✅ Verified** are correctly implemented. Items marked **⚠️ Gap Logged** are divergences that have been documented as QOL or AUDIT items above.

---

### 8.1 Registration & Phone Lookup

| Author's Description | Implementation Reality | Status |
|---|---|---|
| Receptionist types phone number and system says *"Patient already exists"*, auto-fills all fields | Renders compact green confirmation strip for registered patients and blue banner for new family members (v1.40.4) | ✅ Verified |
| New family member (`+ Add Member`) gets a new independent `patientId` linked to guardian's phone | Fully implemented via `BookingPatientFields` family picker + `PatientService.createPatient` with `guardianName`/`guardianRelation` | ✅ Verified |
| Child patient identity zero cross-contamination with father's records | `patientId` is decoupled from phone. Phone is household contact index only. Confirmed via `SCHEMA_AND_MODELS.md`. | ✅ Verified |
| Emergency / no-mobile patient registration | Not implemented — 1-tap dummy key feature pending | ⚠️ Gap → **QOL-01** |

---

### 8.2 Token & Queue Management

| Author's Description | Implementation Reality | Status |
|---|---|---|
| Atomic consecutive queue numbering | `counters/queue_{doctorId}_{date}` Firestore transaction. Fully atomic. | ✅ Verified |
| Provisional token + estimated wait time shown *before* booking is committed | `BookingPaymentSection` streams `AppointmentEngine.nextQueueNumber` + `calculateEstimatedTime`. Renders live badge on doctor selection. | ✅ Verified |
| Reception skips Token #1 and dispatches Token #2 without freezing the queue | Accordion dispatch allows any token to be dispatched regardless of queue order. The skipped token stays `waitingInLobby`. | ✅ Verified (core mechanic) |
| Skipped patient has a visible "stepped out" indicator distinct from absent | No `steppedOut` state exists. Patient just lingers as `waitingInLobby` with no visual cue. | ⚠️ Gap → **QOL-20** |
| Absent marking preserves the token slot at ₹0 (no deletion) | `AccordionStatusActions` → `AppointmentStatus.absent` + confirmation dialog. Correct. | ✅ Verified |
| Same-day duplicate guard with family exception | Composite `Date + DoctorId + Name + Phone` guard + family chip exception. Fully implemented. | ✅ Verified |

---

### 8.3 Doctor-Reception Chamber Handshake

| Author's Description | Implementation Reality | Status |
|---|---|---|
| Doctor enters chamber, logs in with 4-digit PIN, clicks **"I AM READY"** | `DoctorChamberScreen` → `notifyReadyForNext()` → chamber transitions to `ready_for_next`. Reception dispatch lights up. | ✅ Verified |
| Reception dispatch is **locked** during active consultation | `QueueChamberDispatchAction` checks `ChamberStatus.inConsultation` → `onDispatch = null`. | ✅ Verified |
| After consultation ends, chamber auto-enters **Breather Mode** — reception cannot force next patient | `notifyConsultationEnded()` → `consultation_ended`. `ChamberControlBanner` shows breather card. Reception arrow disabled. | ✅ Verified |
| Doctor's *"NEXT PATIENT"* unlocks reception dispatch | `onNextPatient` → `notifyReadyForNext()` → reception unlocks. | ✅ Verified |
| Auto-load of encounter when reception dispatches | `DoctorChamberScreen` stream listener detects `calling` → `_isConsultationOpen` guard → opens `ConsultationEncounterScreen`. | ✅ Verified |
| If reception PC goes down, doctor can directly call patients via door override | `ChamberDoorOverrideBar` shows top 1–2 lobby-checked-in paid patients. | ✅ Verified |

---

### 8.4 Consultation Encounter & Prescribing

| Author's Description | Implementation Reality | Status |
|---|---|---|
| Full patient history across all previous visits visible on-screen | `_loadInitialData` → `EncounterFormState.loadInitialData` loads past consultations. Longitudinal history dialog via `EncounterDialogs.showLongitudinalHistory`. | ✅ Verified |
| **1-Click Carry Forward** of prior chronic regimen as `CONTINUE` items | `form.carryForwardFromConsultation()` in `ConsultationEncounterScreen`. Carried items appear as `CONTINUE` in reconciliation list. | ✅ Verified |
| Each prescription row is fully inline-editable (dosage, timing, duration dropdown from `CONTINUE` → `3 days`, `STOP`, etc.) | `ReconciliationItemRow` only has binary `CONTINUE`/`STOP` chips. No duration dropdown or inline dosage editor on the reconciled card. | ⚠️ Gap → **QOL-14** |
| **`[STOP]`** medication — 1 tap, no popup interrogation | `reconciliation_item_row.dart` → `_promptStopReason` which opens a dialog for stop reason. This is a *light* popup (optional reason input), not a full interrogation. Acceptable. | ✅ Reasonable |
| New medicine search by brand or salt | Unified `MedicineEngine` search. `RxSearchResultsView`. Inline staging form with presets. | ✅ Verified |
| Rapid frequency chips (`1-0-1`, `1-0-0`, `0-0-1`, `1-1-1`, `SOS`) | `StagedMedicineForm` includes these chips. | ✅ Verified |
| Timing chips (`After Food / PC`, `Before Food / AC`) | Implemented. | ✅ Verified |
| Diagnostic orders & follow-up date chips | `AdviceAndOrdersSection` — lab orders + advice + `3 days / 7 days / 14 days / 1 month / 3 months / Not Needed` chips. | ✅ Verified |
| **Print Preview** *before* clicking **Sign & Complete** | Preview button exists but is a subtle icon in the AppBar, not a primary bottom-dock action. Sign & Complete saves *first*, then auto-pushes to print — opposite of the described mental model. | ⚠️ Gap → **QOL-15** + **QOL-19** |
| **Pause / Step Out** — saves draft, frees chamber, resumes when patient returns | `_pauseAndSaveConsultation()` + `EncounterFormState.saveDraft()` + `pauseConsultation()`. Fully implemented. Draft restored on re-open. | ✅ Verified |
| **WhatsApp digital prescription** from reception after completion | `AccordionStatusActions` → WhatsApp button when `status == completed`. Correct. | ✅ Verified |
| Patient lookup (by doctor and reception) with past consultation history + reprint | `PatientDirectoryScreen` → `PatientLookupCard` → `DoctorConsultationAccordion` → `[View Prescription]` → `PrescriptionPrintScreen`. WhatsApp available from print screen. | ✅ Verified (direct WhatsApp from history card pending QOL-18) |

---

### 8.5 Practicality & Real-World Edge Case Assessment

| Scenario | Assessment |
|---|---|
| **Peak OPD hour — 3 doctors, 30+ tokens, multiple skips** | Core queue mechanics handle this. However, with no `steppedOut` status (QOL-20), the lobby list will have ambiguous `waitingInLobby` tokens that may or may not be physically present, causing receptionist confusion during handover. |
| **Doctor types encounter, realizes medication error after clicking Complete & Sign** | Currently no amendment path. The consultation is committed to Firestore the moment Complete & Sign is pressed. The print screen opens for a signed, immutable record. QOL-19 documents a pre-sign preview gate as a potential safeguard. |
| **Child patient with no phone — registered under father's number** | Fully handled by family chips. Works correctly. |
| **Reception machine running 8+ hours — broadband dropout mid-shift** | Offline cache (`OfflineQueueCacheService`) provides resilience. High-visibility amber banner notifies staff. Emergency door override provides doctor-side fallback. Solid. |
| **Second encounter for same patient same day (lab results return visit)** | Correctly handled: same-day return generates a new queue token via reception, unlocks free review waiver. Separate, fresh consultation encounter. Append-only. |
| **Doctor forgets to click NEXT PATIENT after breather — reception stuck** | Reception is stuck indefinitely in `consultation_ended` holding mode. No auto-timeout. Manual coordination required. Low operational risk in small clinics, but should be noted for multi-doctor rollout. |
| **Advance booking for a wrong day (doctor not sitting)** | `availableDays` check missing in advance booking (AUDIT-22). A patient could book for a day the doctor doesn't sit. |

---

### 8.6 Summary Verdict

**Core flow is conceptually sound and mostly implemented correctly.** The author's mental model aligns well with the codebase for all critical paths: atomic tokens, doctor-paced handshake, 1-click carry forward, append-only clinical records, and offline resilience.

**New gaps documented in this review:**

| Item | Category | Description |
|---|---|---|
| **QOL-19** | Workflow | Sign-before-preview sequence inversion — pre-sign preview gate evaluation needed |
| **QOL-20** | Queue UX | Missing `steppedOut` intermediate status for tokens that temporarily leave the lobby |

**Pre-existing gaps confirmed by this review:** QOL-01 (no-mobile dummy), QOL-14 (inline duration dropdown), QOL-15 (preview as primary dock action), QOL-17 (existing patient banner), QOL-18 (WhatsApp from history card), AUDIT-22 (available days booking check).

**No critical implementation divergences found** that would make the described clinic floor workflow impossible to execute. The product is operationally viable for initial deployment at a real clinic.
