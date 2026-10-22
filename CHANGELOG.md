# 📋 GuwahatiOne Clinic OS — Changelog

All notable updates, clinical workflows, and architectural changes to **GuwahatiOne Clinic OS** are documented in this file in reverse chronological order.

> 💡 **Product & Engineering Reference:**  
> - **Operational Focus:** Each milestone highlights practical workflow impacts across Clinic Counter (Reception), Doctor Chamber, and Clinic Owner dashboards.  
> - **Zero Clutter Rule:** Patch releases within a minor series (e.g. `1.36.1`, `1.36.2`) are consolidated into grouped range entries (`[1.36.0 – 1.36.5]`) when jumping versions to keep the document concise.  
> - **No Verification Gates:** Internal CI/test execution metrics (`flutter analyze`, `flutter test`) belong strictly to terminal logs and git commits, never in this changelog.  
> - **Date Standard:** All release and display dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

## [1.40.15] — 22-10-2026

### Pre-Sign Rx Preview Gate (QOL-19) & Technical Audit Sweep (AUDIT-14, AUDIT-17, AUDIT-27, AUDIT-28)
- **Pre-Sign Encounter Print Preview Gate (QOL-19):**
  - Integrated pre-sign clinical preview gate into `ConsultationEncounterScreen` and `PrescriptionPrintScreen`.
  - When the physician clicks `"Finish Consultation & Sign"` or `"Print Preview"`, the system routes to `PrescriptionPrintScreen` in `isPreSign: true` mode before committing any Firestore writes.
  - Displays a high-contrast amber review banner (`"PRE-SIGN CLINICAL REVIEW • Verify 3-column prescription table, dosage, and allergy alerts before medical-legal sign-off."`) with an inline `"Edit Encounter"` button.
  - Doctor can inspect the strict 3-column table, dosage instructions, and allergy notes. If an adjustment is needed, tapping `"Edit Encounter"` returns directly to the active draft with zero database mutations.
  - Tapping `"Confirm & Sign Rx"` atomically saves the append-only consultation to Firestore, signals doctor chamber `consultation_ended`, clears local drafts, triggers physical prescription printing (`printDocument()`), and returns to the doctor chamber.
- **Date Navigation & Statistics Epoch Lower Bounds (AUDIT-14):**
  - Introduced `AppConstants.clinicEpochDate = DateTime(2025, 1, 1)` establishing a unified clinic launch lower bound for historical calendar navigation.
  - Extended `ClinicDateNavBar` with `firstDate` and `lastDate` bounds, disabling the left chevron on or before the clinic epoch date and right chevron on future calendar limits.
  - Unified `StatisticsScreen` desktop navigation bar and mobile AppBar date pickers to respect `AppConstants.clinicEpochDate` and today's date.
- **Consultation `lastVisitDate` Timestamp Standardization (AUDIT-17):**
  - Standardized `ConsultationService.saveConsultation` to write `patient.lastVisitDate` as a native Firestore `Timestamp` (`Timestamp.fromDate(consultation.createdAt)`).
  - Eliminates client clock drift and ISO string formatting variations across heterogeneous clinic hardware, ensuring exact consistency with the schema definition in `docs/SCHEMA_AND_MODELS.md`.
- **Default Medicine Seeding Production Flag (AUDIT-27):**
  - Added `enableSeedDefaultMedicines` flag under `ClinicFeatureFlags` (defaulting to `true` for development and automated test suites).
  - `CatalogueService.ensureDefaultMedicinesExist()` now checks this flag and skips execution when disabled, allowing production clinics to maintain clean master formularies populated via CSV import without test data pollution.
- **Unbounded Patient History Query Protection (AUDIT-28):**
  - Added bounded limit (`limit: 100`) to `BookingService.getAppointmentsForPatient`.
  - Protects Firestore read budgets and client memory allocation for chronic patients with multi-year consultation records.
- **Doctor PIN Verification & Single-Doctor Query Audits (AUDIT-12, AUDIT-20):**
  - Formally closed AUDIT-12 as resolved by design in alignment with AUDIT-03 (doctor PINs are stored in plaintext for owner recovery; in-memory comparisons hash both sides consistently with domain salting).
  - Verified AUDIT-20: single-field queries on `counters.date` are automatically indexed by Firestore.
- **Roadmap Progression (IDEA-3):**
  - Moved In-App Master Medicine Editor (GUI catalogue editing for Clinic Owners) from ideation to the approved Roadmap backlog (Milestone 1.41).

## [1.40.14] — 22-10-2026

### Operational Hardening: Cache Debounce, Print Guard & Clinical Input Limits (AUDIT-15, AUDIT-21, AUDIT-24)
- **Offline Queue Cache Debounce (AUDIT-15):**
  - Added a 3-second debounce timer (`_cacheDebounceTimer`) in `LiveQueueDelegate` for `OfflineQueueCacheService.saveQueue`.
  - Rapid consecutive Firestore snapshot bursts (patients checking in, tokens advancing, arrivals updating) now collapse into a single local disk serialization once the stream settles.
  - Eliminates main isolate UI thread stutter and frame drops on lower-spec clinic counter laptops during peak morning rush.
  - Ensured active debounce timers are safely cancelled on listening date switch and `dispose()`.
- **Prescription Print Button Double-Tap Guard (AUDIT-24):**
  - Added `_isPrinting` state guard with a 1500ms cooldown in `PrescriptionPrintScreen`.
  - While print processing is active, the button transitions to `"Printing..."` with a circular progress spinner and disables `onPressed`, ignoring repeated clicks and keyboard Enter shortcuts.
  - Prevents accidental double-print dialog triggers on clinic touchscreens or slow PCs, eliminating letterhead paper waste.
- **Clinical Input Character Limits & Paste Caps (AUDIT-21):**
  - Enforced generous MBBS/MD clinical character limits defined in `AppConstants` across consultation encounter fields:
    - Chief complaints: 150 characters per complaint chip.
    - Provisional diagnosis: 200 characters per diagnosis chip.
    - Physical & systemic examination notes: 2,000 characters with live character counter indicator.
    - Lifestyle & diet instructions: 2,000 characters with live character counter indicator.
    - Documented patient drug allergies: 100 characters per allergen chip.
    - Outside laboratory test orders and results: 150 and 200 characters.
  - Prevents accidental clipboard paste explosions, protects Firestore document size limits (< 1 MB), and guarantees printable prescription letterhead layout stability.

## [1.40.13] — 22-10-2026

### Prepaid Carry-Over & Patient No-Show Revisit (QOL-03) and Disease Presets Purge (QOL-05)
- **Prepaid Carry-Over & Patient No-Show Carry-Forward (QOL-03):**
  - Added `PaymentType.paidCarryOver` (`'Paid (Carry-Over)'`) enabling reception to issue fresh consecutive queue tokens for patients who paid their consultation fee on an earlier date but had to leave before being examined.
  - Introduced `BookingCarryOverBanner` inside `AddAppointmentDialog`, automatically detecting unredeemed paid visits within a 30-day window (`AppointmentEngine.findEligibleCarryOverAppointment()`).
  - 1-tap revalidation links `carriedOverAppointmentId`, `carriedOverAmount`, and `carriedOverDate` to today's appointment with ₹0 fresh cash collection.
  - Atomically marks the prior appointment `refundStatus: 'carried_forward'`, `carriedForwardToAppointmentId`, and `carriedForwardDate` in the booking Firestore transaction, preventing double-redemption.
  - Zero ghost cash: `CashHandoverEngine` balances physical cash in drawer to the exact rupee at the end of the day while tracking patient volume.
  - Doctor payout integrity: `RevenueEngine` credits the consulting physician's fee split (`effectiveFee`) upon consultation completion.
  - Rendered high-visibility amber `Carry-Over (₹X)` badges across reception queue accordions and doctor chamber token cards.
- **Purge of Hardcoded Whole-Course Presets & Flag Gating (QOL-05):**
  - Purged all hardcoded whole-course disease templates (`tmpl_uri_flu`, `tmpl_acute_gastritis`, etc.) from `MedicineEngine.getDefaultPrescriptionTemplates()`.
  - While 1-tap medicine addition with default dosage and timing is supported, whole disease course presets have been eliminated.
  - Prescription template selector UI remains flag-gated behind `enablePrescriptionTemplatePresets: false` in `ClinicConfig`.

## [1.40.12] — 22-10-2026

### Doctor Sitting Days (`availableDays`) Guard in Advance Booking (AUDIT-22)
- **Multi-Doctor Schedule Protection in Advance Booking:**
  - Upgraded `AppointmentEngine.isDoctorAvailableOnDate` to handle 3-letter abbreviations (`'Mon'`), full weekday names (`'Monday'`), and case-insensitivity with whitespace trimming.
  - Enforced schedule validation in `LiveQueueDelegate.bookAppointment`: throws a clear domain exception (`"$docTitle does not consult on ${dayName}s (Schedule: $schedule)."`) when booking on a doctor's off-day.
  - Hardened `AddAppointmentDialog`: dynamically disables the submit button (`isDisabled == true`) and renders `BookingOffDayWarningBanner` instructing counter staff to select an active OPD day whenever a non-sitting weekday is chosen.
  - Eliminates the operational hazard where visiting physicians who only practice on specific weekdays (e.g. Mon/Wed/Fri) could previously be booked in advance for non-sitting days.

## [1.40.11] — 22-10-2026

### Emergency Walk-Ins, Chamber Demographics Edit & 1-Click CSV Data Export (QOL-01, QOL-04 & IDEA-1)
- **1-Tap Emergency / No-Mobile Walk-In Registration (QOL-01):**
  - Added `AppointmentEngine.generateEmergencyDummyPhone()` and `AppointmentEngine.isEmergencyDummyPhone()` generating collision-resistant placeholder numbers prefixed with `99` (e.g. `9922105432`).
  - Added a `[⚡ No Phone]` suffix button inside `BookingPatientFields` with an amber warning banner alerting staff that SMS/WhatsApp receipts are suppressed for dummy contact numbers.
  - Enables zero-friction booking for urgent trauma patients, unaccompanied elderly citizens, and walk-in patients without active mobile devices.
- **In-Chamber Patient Demographics Correction (QOL-04):**
  - Added an edit action button in `PatientHeaderSection` of `ConsultationEncounterScreen` launching `EncounterDialogs.showEditPatientDemographicsDialog()`.
  - Empowers physicians to correct misheard patient names, ages, and genders during the active consultation without forcing reception intervention.
  - Seamlessly updates `EncounterFormState`, the primary `patients/{id}` registry profile, and the active `appointments/{id}` document via `BookingService.updateAppointmentPatientName()`.
- **1-Click Full Clinic Data Export for Tax Audits & Backups (IDEA-1):**
  - Introduced `DataExportEngine`: pure Dart RFC-4180 compliant CSV generation engine with zero UI dependencies, strictly adhering to Indian date formatting (`DD-MM-YYYY`) and proper cell escaping.
  - Supports 5 export ledgers:
    1. **Financial Revenue Ledger:** Itemized fee collection, payment modes (Cash, UPI, Waived/Free Review), and net totals formatted for accountant audits and income tax filing.
    2. **Appointments & Queue Ledger:** Complete token sequence, check-in timestamps, patient identifiers, and visit statuses.
    3. **Patient Directory:** Complete demographic registry, contact numbers, guardian relationships, and clinical allergy alerts.
    4. **Medicine Formulary:** Master catalogue of brand names, chemical compositions, default dosages, and frequencies.
    5. **Clinical Consultations:** Longitudinal encounter history with chief complaints, provisional diagnoses, and prescribed regimens.
  - Added `ClinicDataExportDialog` accessible to authenticated Clinic Owners from `OwnerShellAppBar` and `StatisticsScreen` (Payments & Reports), featuring quick date range filters (`Today`, `Last 7 Days`, `This Month`, `All Time`).
  - Created client-side platform file downloader via `dart:js_interop` Blob URLs, guaranteeing zero patient health information (PHI) leaves the local clinic intranet.

## [1.40.10] — 22-10-2026

### Scalable Patient Name & Surname Search Beyond 50 Records (AUDIT-08)
- **Direct Indexed N-Gram & Token Search:**
  - Added `PatientSearchEngine.generateSearchTokens()` generating 2+ character prefix n-grams (e.g. `da`, `das`, `bo`, `bor`, `bora`, `borah`) alongside complete name tokens.
  - Upgraded `PatientService.savePatient()` to automatically index `nameLower` and `searchTokens` (`List<String>`) on patient records in Firestore.
- **Elimination of the 50-Record Ceiling:**
  - Completely replaced the in-memory `.limit(50).get()` query scan with Firestore `array-contains` queries on `searchTokens` and prefix range lookups on `nameLower`.
  - Solves the physical OPD clinic issue where returning patients searched by surname or middle name outside the initial 50 records were missed, eliminating duplicate patient registrations and preserving longitudinal clinical histories at scale.

## [1.40.9] — 22-10-2026

### Counter Continuity & Security Simplification (AUDIT-03, AUDIT-04 & QOL-12)
- **Purge of Terminal Lockout & Screen Freeze (AUDIT-04):**
  - Completely removed the 30-second lockout timer, lockout state, and blocked inputs from `AuthProvider` and `LoginScreen`.
  - In a real-world OPD clinic, mistyped PINs at the counter now immediately display an inline error without freezing the desk, ensuring uninterrupted patient registration and cash collection during peak morning rushes.
- **Formal Cancellation of Doctor PIN Hashing (AUDIT-03):**
  - Retained clean plaintext 4-digit PIN storage for doctors in Firestore, accessible exclusively to the authenticated Clinic Owner in `DoctorListScreen`.
  - Solves the physical clinic reality where visiting doctors rotate across multiple clinics and forget PINs, allowing the owner to look up and remind the physician in 5 seconds without password resets.
- **Friction-Free Chamber Queue Previews (QOL-12):**
  - Confirmed and preserved friction-free queue inspection for receptionists and clinic owners without requiring doctor PIN entry.
  - Rely on the core Doctor-Paced Chamber Handshake architecture (locked dispatch while consultation is active or during breather) to prevent accidental patient admission or sound announcements.

## [1.40.8] — 22-10-2026

### Reconciled Regimen In-Place Duration Dropdown & Inline Dosage Editing (QOL-14)
- **In-Place Duration Dropdown Menu:**
  - Added a clinical duration dropdown directly on reconciled medication cards (`ReconciliationItemRow`) with Indian OPD presets: `To Continue`, `3 Days`, `5 Days`, `7 Days`, `14 Days`, `1 Month`, `SOS`, `STOP`, and `Custom...`.
  - Selecting any duration preset automatically shifts the item action to `continueAction`, sets the duration label/days, and clears previous stop reasons.
  - Selecting `STOP` immediately marks the therapy discontinued with strikethrough styling and `stopReason: 'Discontinued by doctor'`.
- **Custom Duration Modal (`CustomDurationDialog`):**
  - Integrated a numeric input dialog allowing doctors to assign custom course lengths (e.g. `21 Days`) with instant validation.
- **Inline Dosage & Timing Editing Modal (`InlineDosageEditDialog`):**
  - Tapping on Column 2 (dosage/timing) in both reconciled and newly prescribed rows opens an in-place editor.
  - Provides 1-tap dosage chips (`1 Tablet`, `0.5 Tablet`, `2 Tablets`, `5 ml`, `10 ml`, `1 Capsule`), frequency schedule chips (`1-0-1`, `1-0-0`, `0-0-1`, `1-1-1`, `SOS`), timing chips (`After Food / PC`, `Before Food / Khali Pet / AC`, `At Bedtime / HS`), and special instruction notes without requiring doctors to remove and re-search medications.

## [1.40.7] — 22-10-2026

### Cloud-Synced Security PIN Store & Multi-Terminal Synchronization UI (QOL-13)
- **Cloud-Synced Security PIN Document (`clinic_config/security`):**
  - Introduced `SecurityService` to persist salted SHA-256 PIN hashes (`ownerMasterPinHash`, `receptionistPinHash`, `updatedAt`, `updatedBy`) in Firestore.
  - Eliminated single-terminal local storage silos; PIN changes made on any workstation automatically synchronize in real time across all reception terminals, doctor chambers, and owner devices.
- **Offline Cold-Boot & Real-Time Sync Stream:**
  - `AuthProvider` reads cached hashes from `SharedPreferences` on boot for instantaneous offline readiness, then subscribes to `SecurityService.securityStream()` from Firestore.
  - Remote rotations automatically update local memory and cache, notifying listeners immediately.
- **Two-Step Security Settings Modal (`SecuritySettingsDialog`):**
  - **Step 1 (Security Verification):** Requires entering the current 6-digit Owner Master Passkey before granting access to PIN rotation settings.
  - **Step 2 (PIN Rotation):** Provides dedicated cards to rotate the 4-digit Receptionist Access PIN and/or 6-digit Owner Master Passkey with input masking, length validation, and confirmation matching.
  - Includes status indicators displaying whether default or custom credentials are active.
- **Owner Shell Top Bar Action:**
  - Added a dedicated high-contrast `[Security & PINs]` button in `OwnerShellAppBar`, visible exclusively to authenticated Clinic Owners next to `Lock to Reception`.

## [1.40.6] — 22-10-2026

### Login Credential Leak Purge, Brute-Force Rate Limiting & Backdoor Removal (AUDIT-01, AUDIT-04, AUDIT-23, QOL-11)
- **Zero On-Screen Credential Leaks (AUDIT-01):**
  - Purged all default PINs (`849201` and `0000`) from login hints, helper texts, and error dialogs across both Doctor Chamber and Reception/Owner forms.
  - Replaced credential-revealing error messages with neutral notices (`'Incorrect PIN. Please try again.'` / `'Incorrect PIN for Dr. [Name]. Please try again.'`).
- **Brute-Force Rate Limiting & 30-Second Lockout (AUDIT-04):**
  - Introduced local brute-force defense in `AuthProvider`: 5 consecutive failed PIN attempts triggers a strict 30-second authentication freeze.
  - Login UI displays an alert banner with a real-time countdown: `'Too many failed attempts. Locked out for Xs.'`
  - Submissions and inputs are disabled during lockout; successful authentication resets the failed attempts counter.
  - Persisted lockout timestamp to `SharedPreferences` prevents bypassing the freeze via browser refresh.
- **Privatized Plaintext PIN Getters & In-Memory Purge (AUDIT-23):**
  - Removed `receptionistPin` and `ownerMasterPin` public getters from `AuthProvider`.
  - Purged plaintext PIN memory storage (`_receptionistPin` and `_ownerMasterPin`); operations now exclusively use salted SHA-256 hashes.
- **Eliminated Hardcoded Owner PIN Fallback Backdoor (QOL-11):**
  - Removed the hardcoded fallback to default PIN `849201` once a custom Owner PIN is configured, preventing unauthorized administrative entry via factory default credentials.

## [1.40.5] — 22-10-2026

### Encounter Bottom Dock Print Preview, 1-Tap WhatsApp Rx in Patient Lookup & Anti-Goal Log (QOL-15, QOL-18, QOL-20)
- **Primary Print Preview Action on Encounter Bottom Dock (QOL-15):**
  - Elevated "Print Preview" to a primary action button directly in `ConsultationBottomDock` alongside `[Finish Consultation & Sign]`.
  - On desktop viewports, renders a prominent `OutlinedButton.icon('Print Preview')` with print icon; on compact mobile screens, renders a high-contrast `IconButton.outlined` with accessible tooltip.
  - Allows doctors to review the complete 3-column isolated prescription layout in modal preview before committing the final digital sign-off and clearing the chamber.
- **1-Tap WhatsApp Rx from Patient History Lookup (QOL-18):**
  - Added a direct 1-tap green `[WhatsApp Rx]` outlined button alongside `[View Prescription]` in `DoctorConsultationAccordion`.
  - Directly formats the longitudinal encounter medication summary via `WhatsAppEngine.formatPrescriptionMessage` and opens the native browser deep-link (`WhatsAppEngine.buildDeepLink`) with floating confirmation feedback, accelerating counter assistance when patients request digital copies.
- **Queue State Simplification & Scrapped "Stepped Out" Status (QOL-20):**
  - Formally scrapped intermediate "stepped out" queue status per Product Manager directive: dispatch authority lies 100% with the receptionist, who can seamlessly call any present patient in line without artificial state overhead. Logged permanently in Section 4.4 (Scrapped Anti-Goals).

## [1.40.4] — 22-10-2026

### Family-Aware Patient Matching, Compact Confirmation Banners & Paediatric Guardian Pre-fill (QOL-17)
- **Compact Visual Confirmation Banners (QOL-17):**
  - Integrated an explicit, single-line green status confirmation banner above the patient name field when matching an existing patient: `✅ Registered: [Name] ([Age]) • Auto-filled`.
  - When switching to `+ Add Member` on a household number, displays a concise blue banner attributing the primary contact: `👨‍👩‍👧 New Member for [Primary Contact Name]`.
  - Enforced strict single-line text truncation (`TextOverflow.ellipsis`) and compact vertical padding to eliminate overflow risks within the 460px booking modal width budget.
- **Phone Row Quick Add-Member Action:**
  - Added a dedicated 1-tap `[person_add]` icon button directly in the phone number row alongside the discovery spinner, allowing receptionists to instantly switch to family member registration without having to tab to the family chips row.
- **Smart Paediatric Guardian Pre-fill:**
  - When clicking `+ Add Member` under a registered household contact, automatically pre-fills `Guardian Name` with the primary contact's name and `Guardian Relation` with `'Parent / Guardian'`, saving counter assistants redundant verbal questioning during rush paediatric walk-ins.
- **Pre-2.0 Active Development Phase Constitution Update:**
  - Updated Invariant 10 in `AGENTS.md` explicitly defining the active development phase until Version 2.0 with allowed schema and API refactorings, transitioning to strict stability post-2.0.

## [1.40.3] — 22-10-2026

### Consultation Discard Lobby Return, Strict Free Visit Metric & Single Fee Configuration Source (AUDIT-13, AUDIT-25, AUDIT-10, AUDIT-11)
- **Discard Consultation Reset to Lobby (AUDIT-13):**
  - Updated `_discardAndExitConsultation` in `ConsultationEncounterScreen` to reset the appointment's `visitStatus` back to `waitingInLobby` and clear `isPaused: false` via `ClinicProvider.discardConsultation` and `BookingService.returnAppointmentToLobby`.
  - Eliminates ghost "In Chamber" status on the reception desk when a doctor discards an accidental or abandoned encounter draft, freeing the chamber and returning the patient to the queue.
- **Strict Free Visit Metric Calculation (AUDIT-25):**
  - Corrected `RevenueEngine.generateDoctorSummaries` to strictly evaluate `a.paymentType.isFree` (targeting only `freeReview` and `freeFamily`), preventing unpaid advance bookings from incorrectly inflating the "Free/Fam" KPI count on the Statistics screen.
- **Single Source of Truth for Consultation Fees (AUDIT-10):**
  - Removed duplicate `AppConstants.defaultConsultationFee = 500`. Updated `AppointmentEngine.resolveConsultationFee` and `BookingPaymentSection` to reference `ClinicConfig.current.defaultConsultationFee` directly as the canonical fallback.
- **Holiday Date Configuration Developer Guidance (AUDIT-11):**
  - Clarified comments in `AppConstants.blockedDates` distinguishing the internal ISO comparison format (`YYYY-MM-DD`) from the mandatory Indian date format (`DD-MM-YYYY`) used everywhere else in the system.

## [1.40.2] — 22-10-2026

### Family-Aware Auto-Trigger Free Review, Review Consumption Enforcement & Firestore Batch Chunking
- **Auto-Trigger Free Review & Reception Discretion Preservation:**
  - Automated follow-up review detection: when a patient is selected and doctor assigned, `AddAppointmentDialog` automatically evaluates review eligibility (`AppointmentEngine.evaluateReviewEligibility`) and selects `PaymentType.freeReview` with ₹0 fee if eligible.
  - Implemented `_hasUserManuallyChangedPayment` tracking: if the receptionist manually chooses another payment option (e.g. charging full fee for a new clinical episode or selecting a complimentary waiver), the system respects the manual override without reverting.
  - Reset manual payment overrides automatically upon phone number clearing, patient switching, or doctor reassignment.
- **Strict Free Review Window & Consumption Guardrails (AUDIT-09):**
  - Enforced full eligibility checks in `LiveQueueDelegate.bookAppointment`, `AddAppointmentDialog`, and `BookingPaymentSection`: patients who have already consumed their review or are outside the doctor's review window are prevented from booking under `freeReview`.
  - Dropdown options clearly indicate when a review is already consumed or expired, disabling invalid selections while maintaining Flutter dropdown stability.
- **Batch Chunking for Doctor Session Close (AUDIT-05):**
  - Updated `BookingService.closeDoctorSessionForDate` to chunk uncompleted appointment document updates into batches of 450 items, eliminating Firestore 500-operation overflow crashes on high-volume clinic days.
- **Patient Age Display Field Canonicalization (AUDIT-06):**
  - Corrected `ConsultationService.saveConsultation` to persist `patientAgeDisplay` directly to the `patients` collection, eliminating the redundant `'formattedAge'` ghost key.

## [1.40.1] — 21-10-2026

### Universal 0000 Testing Mode & Single Client Configuration Architecture
- **Universal Testing Mode Flag (`ClinicFeatureFlags.enableTestingMode`):**
  - Added compile-time guarded `enableTestingMode` and `isTestingModeActive` to `ClinicFeatureFlags`.
  - In testing mode, simplifies authentication across all roles by accepting PIN `0000` for Doctor, Receptionist, and Admin/Owner logins.
  - Automatically suppresses and tree-shakes testing mode bypass logic in production release builds (`--release`), preventing auth bypass on Firebase Hosting.
- **Login Screen Testing Role Selector:**
  - Added sleek role switcher (`Admin Mode` / `Reception Desk`) in `ReceptionLoginForm` when testing mode is active.
  - Cleaned all hardcoded default credentials and placeholders (`1234`, `849201`) across login, chamber release, and doctor list screens to prevent information disclosure.

## [1.40.0] — 20-10-2026

### Longitudinal 1-Click Carry Forward, Natural Dosage Synthesis, Doctor Revenue Split & Letterhead Margin Ergonomics
- **Longitudinal 1-Click `[CARRY FORWARD]` & Cross-Doctor Continuity (HK-1 #1):**
  - Added 1-click `[CARRY FORWARD]` capability in `EncounterFormState`, `RxReconciliationSection`, and `EncounterDialogs.showLongitudinalHistory`.
  - When reviewing a patient's historical visit (including visits originally conducted by other doctors in the clinic), clinicians can instantly copy past active regimens into the active encounter as `To continue` (`MedicationAction.continueAction`) items, skipping duplicates and maintaining zero data loss.
  - Signing today's consultation permanently binds the unified prescription to the active consulting doctor's NMC registration while preserving previous consultation records as immutable audit-proof events.
- **Natural Dosage & Timing Synthesis (`formattedDosageTiming`) & Rapid Schedule Chips (HK-1 #2):**
  - Implemented `PrescriptionItem.formattedDosageTiming` to intelligently synthesize Column 2 on prescription prints and on-screen cards without repetitive or awkward wording (e.g. `1 tablet daily morning before food` or `1 Tablet • 1-0-1 • After Food (PC)`).
  - Added 1-tap rapid schedule chips to `StagedMedicineForm` (`1-0-0 Khali Pet`, `1-0-0 After Food`, `1-0-1 After Food`, `1-1-1 TDS`, `0-0-1 Bedtime`, `SOS`), allowing doctors to configure frequency and timing in a single touch.
  - Added Indian MBBS/MD timing options: `'Before Food / Khali Pet (AC)'`, `'After Food (PC)'`, `'At Bedtime (HS)'`, `'With Food'`, and `'As Needed (SOS)'`.
- **Frictionless 1-Tap STOP Reconciliation (Zero Popup Friction):**
  - Removed intrusive stop-reason modal dialogs per PM directive; clicking `STOP` on any chronic medication row instantly toggles its action to `MedicationAction.stop` without disrupting doctor flow.
- **Next Follow-up Review with 1-Tap "Not Needed / SOS":**
  - Added a dedicated 1-tap `Not Needed / SOS` chip in `AdviceAndOrdersSection`, allowing doctors to clear scheduled follow-up dates in one tap.
- **Doctor Revenue Share Split & Fee Payout (Item 20.2):**
  - Added `doctorSharePercentage` (0–100%, default 100%) to `Doctor` model with clean serialization.
  - Integrated an owner-only configuration input in `DoctorForm` (accessible exclusively with Owner PIN session).
  - Implemented pure Dart calculation `RevenueEngine.calculateDoctorPayout({required totalDoctorFees, required doctorSharePercentage})` for automated owner-physician fee split reconciliation.
- **Configurable Letterhead Top Margin & Print Keyboard Shortcuts (Item 24):**
  - Added `defaultLetterheadTopMarginMm` (default: 35.0 mm) to `ClinicConfig` so pre-printed letterhead reserved space is client-customizable.
  - Added `CallbackShortcuts` and autofocus to `PrescriptionPrintScreen` for counter efficiency: `Enter` instantly triggers printing, `Esc` dismisses the preview.
- **Broadband Outage Offline Fallback & Network Error Handling (Item 22):**
  - Integrated persistent amber offline indicators in `OwnerShell` (desktop header and mobile top strip) alerting front-desk staff whenever the system falls back to `OfflineQueueCacheService` local cache.
  - Added an offline warning banner to `AddAppointmentDialog` clarifying that walk-in token allocation requires active cloud synchronization to maintain consecutive atomic counter integrity (Invariant #1).
  - Enhanced booking exception handling with human-friendly guidance when broadband is interrupted rather than cryptic database error traces.
- **Architectural Refactoring & God Object Decomposition (Phases 1, 2 & 3):**
  - **Decomposed Monolithic UI Widgets (Phase 1):**
    - Reduced `DashboardTodayQueueCard` from 913 lines down to 295 lines by extracting `UpcomingBookingsSection`, `QueueDoctorFilterBar`, and `DashboardQueueItemRow`.
    - Modularized `AddAppointmentDialog` by extracting `BookingOfflineBanner`, `BookingDialogActions`, and `BookingSuccessSnackbar`.
    - Modularized `AddDoctorScreen` by extracting `DoctorLeaveCalendarSection`.
  - **Decomposed `ClinicProvider` God Object (Phase 2):**
    - Refactored `ClinicProvider` into a lightweight, backward-compatible Facade over 3 dedicated domain controllers: `DoctorStateDelegate` (doctor roster & leave), `LiveQueueDelegate` (live queue, offline caching, and midnight rollover), and `CatalogueDelegate` (master formulary & curation).
    - Preserved 100% backward compatibility across all screen callers with zero breaking changes.
  - **Fine-Grained Widget Rebuild Optimization (Phase 3):**
    - Replaced broad `ClinicProvider` rebuild triggers with targeted `context.select` and `Selector` subscriptions in high-traffic widgets (`OwnerShell`, `AuthGate`, `ConsultationEncounterScreen`, `AppointmentListScreen`, `MedicineCatalogueScreen`, `LoginScreen`, `DoctorListScreen`, and `OwnerShellAppBar`).
    - Eliminates cascading full-app re-renders on counter PCs during background appointment bookings and doctor queue mutations.
- **External Appointment Distraction Banner Excluded (Item 18):**
  - Permanently dropped per PM directive to guarantee distraction-free clinical focus inside the chamber during active consultations.

---

## [1.37.0 – 1.39.0] — 19-10-2026 to 20-10-2026

### PatientSearchEngine, Same-Day Lab Reviews, Upfront Cash Drawer & Prescribing Guardrails
- **Pure Dart `PatientSearchEngine` & Multi-Attribute Lookup (v1.39.0):**
  - Built pure Dart `PatientSearchEngine` with robust phone normalization (strips +91, 0, whitespace, formatting), multi-word name tokenization, and multi-tier relevance ranking (exact phone > exact name > surname prefix > partial matches).
  - Fixed `PatientService.searchPatients` to query the `phoneNumber` field instead of `FieldPath.documentId` (which failed on canonical `pat_*` IDs).
  - Added dedicated `pat_*` canonical ID lookup and integrated recent patient pool token matching so searching by surname (e.g. "Devi", "Baruah", "Sharma") or canonical ID immediately returns ranked matches.
- **Same-Day Return Visits & Lab Review Tokens via Reception (v1.39.0):**
  - Updated `BookingService.hasAppointmentForDate` duplicate check to permit same-day re-booking when a prior appointment on the date has reached `AppointmentStatus.completed`. A patient consulted in the morning returning in the afternoon with lab results is routed via reception desk, receiving a valid queue token so doctors have complete operational clarity without unannounced chamber barging.
  - Enhanced `AppointmentEngine.evaluateReviewEligibility` to recognize same-day return visits (`daysSincePaid == 0`) with descriptive status `'Same-day return / lab review'`, correctly unlocking doctor-configured free review waivers (`PaymentType.freeReview`).
- **Upfront Desk Cash Drawer Accounting & Session Close Preservation (v1.39.0):**
  - Updated `CashHandoverEngine` to count physical cash collected upfront at the reception counter (`PaymentType.paidCash` with `amountCollected > 0`) regardless of whether the patient is in lobby, in consultation, or completed, perfectly mirroring real physical cash in drawer.
  - Fixed `BookingService.closeDoctorSessionForDate` to NEVER destructively zero out `amountCollected` on doctor absence. Retains collected cash amounts in the audit trail and tags `refundStatus: 'pending_refund'`.
  - Added `refundStatus` (`'none'`, `'pending_refund'`, `'refunded'`) on `Appointment` model and serialized to Firestore and offline cache.
  - `CashHandoverEngine` skips visits only when `refundStatus == 'refunded'`, eliminating ghost discrepancies between counted drawer cash and system expectations.
- **Automatic Midnight Date Rollover Observer (v1.39.0):**
  - Implemented periodic 30-second midnight rollover observer (`checkAndHandleMidnightRollover`) inside `ClinicProvider`. When counter PCs remain powered on overnight, the observer detects calendar day shift (`!DateUtils.isSameDay(_activeListeningDate, now)`), automatically cancels the previous day's stream, resets today's appointment list, and re-subscribes live queue streams to the new calendar day.
  - Operates automatically for live queue sessions while preserving intentional user archive browsing when historical dates are explicitly selected.
- **Soft Daily Token Cap Retained (v1.39.0):**
  - Retained soft visual quota warning badge per Product Manager directive. In clinical practice, strict hard modal locks paralyze front-desk operations during walk-in emergencies. If limits are reached, soft warnings display prominently on desk badges while doctors retain discretion to verbally coordinate with reception.
- **Flexible Multi-Modal Duration Engine & Pharmacological Validation (v1.38.0):**
  - Implemented `MedicineEngine.parseDuration` accepting acute numeric days (`1 to 300` days, e.g. `5`, `14`, `21 days`), as-needed (`SOS`, `SoS`, `s.o.s`), and ongoing chronic therapy (`To continue`, `cont`, `chronic`).
  - Added inline pharmacological sanity checks strictly blocking negative (`<= 0`) or excessive (`> 300`) day values with clear feedback.
  - Enhanced `StagedMedicineForm` with 1-tap quick preset chips (`[Cont]`, `[SOS]`, `[3d]`, `[5d]`, `[7d]`, `[14d]`, `[30d]`) alongside direct keyboard input.
  - Integrated `effectiveDuration` getter in `PrescriptionItem` to guarantee strict 3-column isolation across print letterheads, preview tables, WhatsApp summaries, and consultation charts.
  - Ensured formulary catalogue bundled defaults (e.g. *Telma 40 tablet* with `{Telmisartan 40mg, 1-0-1, to continue}`) populate intact into staging without clinical friction.
- **Staged Medicine Discard Guard (v1.38.0):**
  - Added `hasStagedMedicine` and `stagedMedicineDisplayName` in `EncounterFormState`.
  - In `ConsultationEncounterScreen`, intercept "Complete & Sign" when a medicine is actively staged without being added, offering doctors an interactive dialog with `[Add to Prescription & Sign]`, `[Discard & Sign]`, and `[Review / Cancel]`, eliminating silent drops of configured medications.
- **Longitudinal Diagnostic Test Deduplication (v1.38.0):**
  - Updated `EncounterFormState.loadInitialData` to track `seenTestNames` across past consultations and deduplicate by normalized `testName.trim().toLowerCase()`.
  - Eliminates exponential ghost blank row accumulation in chronic follow-up charts while ensuring all unique past investigations remain accessible for review.
- **Retirement of Arbitrary `BYPASSED` Badge & Clean FIFO Lobby Queue (v1.37.0):**
  - Completely eliminated the `bypassed` badge, calculation, and amber styling from `AppointmentEngine.partitionQueueForReception` and `AppointmentAccordion` per real-world OPD operational realities.
  - When doctors admit relatives, emergency walk-ins, or elderly patients out of strict sequential order, uncalled patients in the lobby remain in clean, unpenalized FIFO queue order without being arbitrarily labeled "Late" or "Bypassed".
- **Multi-Chamber Queue Partitioning (`inChamberPatients`) (v1.37.0):**
  - Enhanced `ReceptionQueueView` to support `inChamberPatients` list (`List<Appointment> inChamberPatients` with `Appointment? get inChamber => inChamberPatients.firstOrNull`).
  - Supports concurrent multi-doctor clinics where multiple practitioners are in session simultaneously (e.g., Dr. A consulting Token #8 in Chamber 1, Dr. B consulting Token #3 in Chamber 2). Both patients render prominently in top active chamber cards, and neither leaks into the waiting list.
- **Date-Specific Doctor Filter Chips on Live Ledger (v1.37.0):**
  - Updated doctor filter chips to dynamically show strictly doctors who have an OPD schedule on the selected calendar date (and are not on planned leave) OR who have existing appointments booked for that date.
  - Clinics with 10 registered physicians displaying a 3-doctor OPD day will now only render chips for the 3 active doctors, eliminating visual clutter.
- **Upcoming Advance Bookings on Reception Dashboard (v1.37.0):**
  - Added `BookingService.getUpcomingAppointments({int daysAhead = 7})` and exposed stream method in `ClinicProvider.streamUpcomingAppointments()`.
  - Added a responsive segmented toggle in `DashboardTodayQueueCard` allowing receptionists to seamlessly switch between `"Today's Queue (N)"` and `"Upcoming Bookings"`.
  - Upcoming bookings are grouped by calendar date adhering strictly to Indian formatting (`DD-MM-YYYY`) with booking count chips, displaying patient name, age, phone number, doctor name, and advance payment status (`Paid ₹X` vs `Pay at Desk`).
  - Added horizontal scroll wrapping to the segmented tab bar to guarantee zero RenderFlex overflow across compact mobile viewports (320px–360px).

---

## [1.36.0 – 1.36.9] — 15-10-2026 to 19-10-2026

### Doctor Shift Conclusion, Reception Emergency Release, Consultation Pause & Step-Out Protocol
- **Doctor Shift Conclusion & Reception Emergency Chamber Release (v1.36.9):**
  - **Doctor-Controlled Shift Conclusion:** Added `ChamberStatus.shiftEnded` (`'shift_ended'`) to the real-time chamber operational lifecycle. Doctors can formally conclude consultations for the day on their own schedule via dedicated `[END SHIFT]` / `[Close Shift]` actions in `ChamberControlBanner` (`consultationEnded`, `readyForNext`, or `idle` states) guarded by confirmation dialogs, rather than waiting for midnight cron jobs or date rollovers.
  - **Re-Open Shift Capability:** Concluded chambers render an informative `[OPD Shift Concluded for Today]` card with a prominent `[RE-OPEN SHIFT]` button allowing the doctor to immediately resume OPD if unexpected walk-ins or urgent follow-ups arrive.
  - **Reception & Roster Sync:** `DashboardDoctorRosterCard` renders an explicit `[SHIFT ENDED]` badge across both desktop tables and mobile cards. Reception dispatch actions (`QueueChamberDispatchAction` and `AccordionDispatchSection`) immediately switch to disabled state `"Doctor Shift Ended for Today"` and door override lists are locked.
  - **Single-Active-Doctor Concurrency Guard Flag (`enforceSingleActiveDoctor`):** Added a tenant configuration toggle (`ClinicFeatureFlags.enforceSingleActiveDoctor`, default `false`). When `false`, multi-chamber polyclinic concurrency is fully enabled. When set to `true`, chamber transaction guards strictly block a second physician from signaling readiness or admitting tokens while another doctor is actively consulting.
  - **Reception Emergency Chamber Release (PIN 0000 Guarded):** Added an `[Emergency Release Chamber Lock]` trigger in `AccordionDispatchSection` when a room is locked on break or marked occupied. Staff entering Reception PIN (`0000`) or Owner Master PIN can immediately clear the chamber sync state to `idle`, safely handling offline doctors or network glitches without deleting appointment documents (Invariant #1).
- **Consultation Pause / Step-Out Protocol & Local Draft Recovery (v1.36.8):**
  - **Zero Data Loss Draft Caching:** Integrated draft serialization (`toDraftMap` / `restoreFromDraftMap`) and asynchronous local caching in `SharedPreferences` (`draft_encounter_${appointmentId}`) in `EncounterFormState`. When a doctor pauses an encounter or reloads, typed vitals, examination notes, complaints, provisional diagnoses, staged medications, and orders are automatically restored.
  - **Modal Exit & Chamber Unwind Guard:** Wrapped `ConsultationEncounterScreen` in `PopScope(canPop: false)`. Tapping Android back, browser back, or the new bottom dock **`[Pause / Step Out]`** button launches an operational modal with "Pause & Save Draft", "Keep Editing", and "Discard". Pausing broadcasts `notifyConsultationPaused`, resetting doctor chamber status to `ready_for_next` and freeing the room immediately.
  - **Reception Queue Visibility & 1-Tap Resume:**
    - Renders a purple `[PAUSED / RESUMABLE]` chip and card highlight in `AppointmentAccordion`.
    - Dynamic chamber dispatch in `QueueChamberDispatchAction` and `AccordionDispatchSection` displays a high-visibility purple **`[Resume In]`** / **`[RESUME CONSULTATION IN CHAMBER]`** button when doctor is ready.
    - Emergency door override bar in `ChamberDoorOverrideBar` displays a `[PAUSED]` chip with a `[Resume]` button.
  - **Transactional Chamber Occupancy (Invariant #11):** Wrapped `ChamberService.callTokenIntoChamber` inside `FirebaseFirestore.instance.runTransaction()`. Chamber occupancy inspection and token claim execute atomically, guaranteeing that simultaneous double-clicks or concurrent reception/doctor admissions cannot admit multiple patients into one room.
  - **Door Admission Collision Guard:** Reordered `DoctorChamberScreen._handleDoorAdmit` to secure the atomic chamber lock before mutating appointment records, eliminating zombie `inConsultation` state corruption if reception concurrently calls another patient.
  - **Firestore Audit-Proof Ledger (Invariant #1):** Pausing marks `Appointment.isPaused: true` and sets `visitStatus: waitingInLobby` without deleting any appointment document or queue counter. On encounter completion and sign, `isPaused` is reset to `false` and local draft is cleared.
- **Doctor Deactivation, Inactive Filtering & Admin Passkey Gate (v1.36.7):**
  - **Zero Deletions Guard (Invariant #1):** Replaced hard delete in `DoctorService` with non-destructive deactivation (`isActive: bool`). Inactive/retired doctors are preserved in Firestore so longitudinal consultations, patient prescription histories, and financial ledgers remain permanently intact.
  - **Reception & Dashboard Isolation:** Filtered `ClinicProvider.doctors` to return strictly active doctors (`isActive == true`). Inactive doctors are completely excluded from dashboard rosters, walk-in booking modals, live queue tabs, and chamber login dropdowns.
  - **Owner Roster Segregation:** Added segmented filter chips (`Active Doctors (N)` | `Inactive / Retired (M)`) in `DoctorListScreen` exclusively visible to Clinic Owners.
  - **Inactive Card Styling & Overflow Protection:** Inactive doctors are rendered with soft slate backgrounds (`Color(0xFFF8FAFC)`), grey avatars, and an explicit `[INACTIVE]` badge built with responsive text spans to guarantee zero RenderFlex overflow.
  - **Admin Master Passkey Authorization:** Toggling doctor active status (`Deactivate` or `Reactivate Doctor`) strictly prompts an authentication dialog requiring the Owner's 6-digit Master Passkey (`AuthProvider.verifyOwnerMasterPin`).
  - **Chamber Login Guard:** Inactive doctors are barred from PIN authentication and direct chamber login in `AuthProvider.loginAsDoctor`.
- **Universal Walk-In Booking Modal & Explicit LOGOUT Button (v1.36.6):**
  - Moved desktop walk-in booking trigger into the left `NavigationRail` with a prominent `Book Walk-In (F2)` button, freeing topbar desktop real estate.
  - Made mobile `FloatingActionButton.extended` persistently accessible across all navigation tabs (Dashboard, Queue, Patients, Schedules).
  - Replaced the unlabelled exit arrow in the sidebar with an explicit, high-visibility **`LOGOUT`** button and confirmation modal.
  - Implemented a re-entrancy latch (`_isBookingModalOpen`) preventing rapid double-clicks from launching duplicate or stacked booking modals.
  - Ensured booking always launches as an overlay modal (`AddAppointmentDialog`) rather than a route replacement, preventing state loss on the active screen.
  - **Solo Doctor Booking Auto-Select:** When only 1 doctor is registered (`doctors.length == 1`), the booking panel automatically pre-selects that doctor and renders a clean summary tile, eliminating redundant dropdown interaction.
  - **Thermal Token Slip Printing Flag:** Disabled printed token slips by default (`enableTokenReceiptPrint: false`) as an experimental flag for manual-ticket clinics while preserving printing capabilities intact.
  - Made `DoctorRosterCard` and booking payment dropdowns responsive on compact viewports to prevent RenderFlex overflow.
- **Prescription Table Strict 3-Column Isolation (v1.36.5):**
  - Refactored `PrintMedicationsTable` into 3 dedicated, unmixed columns:
    - **Column 1 (Medicine):** Brand name and uppercase bracketed composition (`Telma 40 tablet [TELMISARTAN 40MG]`, conforming to National Medical Commission standards). Removed badges like `[NEW]` and `[CONT]`.
    - **Column 2 (Dosage & Timing):** Dosage, frequency, timing, and optional patient notes (`1 tab • in morning • before food`).
    - **Column 3 (Duration):** Course duration (`X Days`), ongoing chronic therapy (`To Continue`), or explicit discontinuation (`To STOP`).
  - Discontinued medications render in the unified table with `To STOP` in the Duration column alongside the active regimen.
  - **🧪 Experimental Flag (`hidePrescriptionComposition`):** Added to `ClinicFeatureFlags` (default: `false`). When enabled, suppresses generic compositions so only trade brand names appear (`Telma 40 tablet`).
  - **AI Constitution Lock:** Codified Invariant #12 and Red Line in `AGENTS.md` and `.agents/rules/clinic_os_rules.md`.
- **Reception Mobile Header & Doctor Chamber Badges (v1.36.4):**
  - Removed duplicate booking button from mobile AppBar in `DashboardScreen`; receptionists use the single prominent `FloatingActionButton.extended`.
  - Replaced cluttered fee labels with clean payment presentation: `₹500 Paid`, `Free Review`, `Free Waiver`, `Post-Pay`, `Unpaid`.
  - Refined 5-state chamber status lifecycle: `[ABSENT]`, `[NO OPD TODAY]`, `[NOT ARRIVED]`, `[IN CHAMBER]`, `[CONSULTING]`.
- **Single Source of Truth Documentation Consolidation (v1.36.3):**
  - Purged legacy archives (`docs/archive/`) and historical decision logs (`docs/decisions/`) to establish a zero-hallucination, single source of truth (`AGENTS.md`, `docs/SCHEMA_AND_MODELS.md`, `docs/MASTER_BACKLOG.md`).
- **Enforce Doctor-Paced Handshake Integrity (v1.36.2):**
  - Purged `ChamberCallingAlertBar` and pre-emption routines from `ConsultationEncounterScreen` to strictly enforce Invariant #7 & #11.
  - Reception buttons are locked (`Chamber Occupied` or `Doctor on Break`) during active consultations and breathers. Doctor signals readiness via "Next Patient" (`ready_for_next`) before reception can dispatch.
- **Doctor Planned Leave System with Dynamic Range Messaging (v1.36.1):**
  - Wired `Doctor.blockedDates` across engines, booking desks, and provider layers with dynamic leave duration messages (`"Doctor is on leave on DD-MM-YYYY"`, `"Doctor is on leave from DD-MM-YYYY to DD-MM-YYYY"`).
  - Strictly blocks booking on leave days with a high-visibility warning banner and server-side validation.
  - Added "Planned Leave & Blocked Dates" chip editor with date and week pickers in `AddDoctorScreen`.
- **Streamlined Medicine Schema & 1-Key Prescribing Loop (v1.36.0):**
  - Unified commercial brand and dosage form in `productName` (e.g. `Telma 40 tablet`), molecule and strength in `composition` (e.g. `Telmisartan 40mg`), and manufacturer in `manufacturer`.
  - Added formulary regimen defaults (`defaultDosage`, `defaultFrequency`, `defaultTiming`, `defaultDurationDays`) for 1-click prescribing.
  - 1-Key (Enter) "Verify & Next" loop in `StagedMedicineForm` auto-commits drug and refocuses search input without mouse interaction.

---

## [1.35.0 – 1.35.2] — 15-10-2026

### WhatsApp Review Policy, Cash Drawer Reconciliation & Unified Search
- **Dynamic WhatsApp Review Policy & FHD Monitor Expansion (v1.35.2):**
  - Dynamic review window in `WhatsAppEngine.formatPrescriptionMessage` reflecting configured `freeReviewDays` (omitted when 0 days).
  - Expanded container constraints to `maxWidth: 1800` across `PatientDirectoryScreen`, `DoctorChamberScreen`, and `MedicineCatalogueScreen` to eliminate dead margins on FHD monitors.
- **Cash Drawer vs. Digital UPI Segregation (v1.35.1):**
  - Separated physical currency notes (`totalPhysicalCash`) from digital UPI collections (`totalUpiRevenue`) in `CashHandoverEngine`.
  - Eliminated false cash shortage alerts in `DailyCashHandoverDialog`. Added 4-metric KPI strip and dedicated Cash/UPI columns in doctor breakdown.
- **Unified 2-Column Medicine Search & Composition Cards (v1.35.0):**
  - Simultaneous search across brand name and chemical composition without manual mode toggling.
  - High-contrast clinical cards featuring uppercase bracketed chemical headers (`[COMPOSITION]`) with selectable trade brand buttons (`{Products}`).
  - Standardized duration dropdown and added `enableGroupedCompositionCards` experiment toggle.

---

## [1.34.0 – 1.34.1] — 15-10-2026

### Prescription Point-in-Time Snapshots & Multi-Patient Household Identity
- **Prescription Snapshot & Catalogue Immunity (v1.34.1):**
  - `PrescriptionItem` captures immutable snapshots of `name`, `composition`, `strength`, `form`, and `manufacturer` at prescribing time.
  - Formularies and medicine catalogues can be edited or purged without altering historical consultations or printed records.
- **Patient Identity & Household Model (v1.34.0):**
  - Replaced phone-keyed documents with canonical patient IDs (`pat_{timestamp}_{suffix}`). Phone numbers serve as shared household contact indices.
  - Added infant age support (`ageMonths`, `ageDays`) and guardian fields (`"c/o Sunita Sharma, Mother"`).
  - Reception family picker discovers household members with `+ Add Member` provisioning.

---

## [1.33.0 – 1.33.5] — 14-10-2026 to 15-10-2026

### Stream Optimizations, Component Decomposition & Reception Ergonomics
- **Performance & Handshake Typing (v1.33.5):**
  - Eliminated $N+1$ stream subscriptions in `DashboardDoctorRosterCard`.
  - Introduced strongly typed `ChamberStatus` enum (`idle`, `readyForNext`, `calling`, `inConsultation`, `consultationEnded`).
- **Autonomous AI Maintainability & Sub-Widget Extraction (v1.33.4):**
  - Decomposed monolithic UI screens into modular components: `BookingDateAndModeSection`, `QueueChamberDispatchAction`, `CashDenominationCounterSection`, `DoctorConsultationAccordion`, and `OwnerShellAppBar`.
  - Created maintenance recipes in `.agents/recipes/`.
- **Doctor Title Normalization & Form Ergonomics (v1.33.3):**
  - Eliminated duplicate `"Dr. Dr."` prefixes with `AppFormatters.cleanDoctorName` and `doctorTitle`.
  - Added 30-minute shift timing dropdowns with inverted timing validation and curated specialty list.
- **Indian OPD Optimizations & Token Receipts (v1.33.2):**
  - Non-blocking sitting schedule warning for off-day bookings.
  - Added `TokenReceiptDialog` for thermal slip printing (gated under `enableTokenReceiptPrint`).
  - Added bulk "Close Session (Doctor Absent)" action (gated under `enableBulkSessionClose`).
- **Mobile Reception Responsiveness (v1.33.1):**
  - Added extended `FloatingActionButton` (`+ Book Walk-In`) on reception tabs.
  - Dedicated mobile card format for "Today's Live Queue" with vertical patient hierarchy.
- **Patient Directory & Multi-Doctor Lookup (v1.33.0):**
  - Zero-egress patient search tab loading with zero initial Firestore reads.
  - Multi-doctor consultation history segregated into expandable accordions on a single master patient card.

---

## [1.32.0 – 1.32.3] — 14-10-2026

### Reception KPI Funnel, Dashboard Header Consolidation & Template Presets
- **Reception Metrics & Token Cap Indicator (v1.32.3):**
  - Compact 4-state token cap indicator in booking dialog (`[ 12/18 Booked ]`, `[ ⚠️ 16/18 Booked ]`, `[ ⚠️ 18/18 Full ]`, `[ 🔴 19/18 Extra ]`).
  - 4-stage reception funnel: `Total Booked`, `In Lobby`, `Completed`, `No-Show`.
- **Desktop Dashboard Header Consolidation (v1.32.2):**
  - Merged date greeting into top AppBar line, elevating KPI cards and live queue above the fold.
  - Sharpened action button contrast (`+ Book Walk-In (F2)` in filled teal).
- **Gated Rx Template Presets (v1.32.1):**
  - Gated GP preset bundles behind `ClinicConfig.current.features.enablePrescriptionTemplatePresets`.
- **HK-2 Architectural Clean-Up (v1.32.0):**
  - Purged write-only `appointment_events` sub-collection, halving Firestore write costs. Auditing preserved on permanent appointment ledger (Invariant #1).

---

## [1.30.0 – 1.31.0] — 14-10-2026

### Doctor Chamber Mobile, Historical Archive & Operational Lifecycle KPI Hierarchy
- **Doctor Chamber Mobile & Historical Archive (v1.31.0):**
  - Compact 1-line archive banner: `🔒 Viewing Past Records (Read-Only)`.
  - Consolidated historical status into a single muted `No-Show` pill; enabled direct card tapping for consultation summaries.
  - Tightened metric subtitles for mobile viewports (< 450px).
- **Dashboard Header Reorganization & KPI Hierarchy (v1.30.0):**
  - Bound global hotkey `F2` to trigger `[ Book Walk-In ]` instantly.
  - Restructured KPI cards to track real-world outpatient lifecycle: `Waiting in Lobby`, `Expected / Booked`, `Inside Chamber`, and `Completed`.
  - Embedded compact pace telemetry (`• Pace: ~8-10 min/pt`) directly into doctor cards.

---

## [1.29.0 – 1.29.1] — 13-10-2026 to 14-10-2026

### Multi-Chamber Queue Sound Announcer & Invariant #10 Cleanup
- **Queue Sound Announcer (v1.29.0):** Plays airport clinic chime and vocal token announcement (*"Token 12, please proceed to Dr. Baruah"*) on patient dispatch via Web Audio & Speech Synthesis API.
- **Invariant #10 Cleanup (v1.29.1):** Purged obsolete `@Deprecated` `PaymentType.paid` alias; migrated all fixtures to canonical `paidCash` / `paidUpi`.

---

## [1.25.0 – 1.28.0] — 13-10-2026

### Encounter Templates, Chamber Integrity & Doctor-Paced Handshake
- **Prescription Template Presets (v1.28.0):** Fast 1-tap prescribing for URI, Gastritis, Diarrhea, Viral Fever, and HTN starter regimens.
- **Single-Occupant Chamber Integrity (v1.26.0):** Enforced Invariant #11 guaranteeing exactly one patient in chamber with atomic occupancy lock.
- **Doctor-Paced Chamber Handshake Protocol (v1.25.0):** Replaced reception forced admissions with 5-state synchronized handshake (`idle` ➔ `ready_for_next` ➔ `calling` ➔ `in_consultation` ➔ `consultation_ended`).
- **Counter Queue Legibility & Mobile Encounter (v1.24.0):** 44px high-contrast token badges on counter monitors; responsive encounter dock on mobile.

---

## [1.20.0 – 1.23.0] — 13-10-2026

### Security Hardening, Review Cycle Enforcement & Doctor Configuration
- **Unified Desk Authentication (v1.23.0):** Counter login accepts both Reception PIN (`0000`) and Owner Master PIN from a single input with anti-duplicate submit latches.
- **Strict 1:1 Paid-to-Review Cycle (v1.22.0):** Prevents infinite free review chaining; each paid visit entitles strictly one free review within the doctor's review window.
- **Mobile Responsive Chamber Layout (v1.21.0):** Fluidly stacks chamber controls, token cards, and emergency door override bars on mobile viewports.
- **Doctor-Configurable Free Review Window (v1.20.0):** Customizable per physician (`0` to `30` days, default `14`), enabling 0-day policies for visiting specialists.

---

## [1.17.0 – 1.19.0] — 13-10-2026

### Security Hardening & Concurrency Locks
- **Security Hardening (v1.19.0):** Domain-salted SHA-256 PIN hashing (`hashPin`). Plaintext credentials purged from browser storage.
- **Atomic Concurrency Locks (v1.18.0):** Multi-desk simultaneous bookings locked atomically via transaction (`counters/lock_{doctorId}_{date}_{phone}_{name}`).
- **Backend Security Rules (v1.17.0):** Firestore rules locking appointments and consultations against client-side deletions.

---

## [1.15.0 – 1.16.9] — 12-10-2026

### Architectural Consolidation, Modular Engines & Offline Cache
- **Asynchronous Desk Check-In (v1.16.0):** Advance reservations isolated until physical counter check-in (`waitingInLobby`).
- **Emergency Door Self-Call Guard (v1.16.1):** Direct doctor door admissions capped strictly to top 1–2 verified lobby patients.
- **Read-Only Historical Chamber Archive (v1.16.2):** Past calendar dates lock into read-only mode with unresolved tokens marked as `UNATTENDED / NO-SHOW`.
- **Standalone `CashHandoverEngine` (v1.16.8):** Decoupled cash drawer denomination balancing into pure Dart domain engine.
- **Offline Queue Cache & WhatsApp Engine (v1.15.0):** Local queue caching during network drops and 1-tap `wa.me` prescription sharing.
