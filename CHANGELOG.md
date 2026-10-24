# 📋 GuwahatiOne Clinic OS — Changelog

All notable updates, clinical workflows, and architectural changes to **GuwahatiOne Clinic OS** are documented in this file in reverse chronological order.

> 💡 **Product & Engineering Reference:**  
> - **Operational Focus:** Each milestone highlights practical workflow impacts across Clinic Counter (Reception), Doctor Chamber, and Clinic Owner dashboards.  
> - **Zero Clutter Rule:** Patch releases within a minor series (e.g. `1.36.1`, `1.36.2`) are consolidated into grouped range entries (`[1.36.0 – 1.36.5]`) when jumping versions to keep the document concise.  
> - **No Verification Gates:** Internal CI/test execution metrics (`flutter analyze`, `flutter test`) belong strictly to terminal logs and git commits, never in this changelog.  
> - **Date Standard:** All release and display dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).


## [1.5.4] — 24-10-2026

### Chamber Findings Inline History, Dosage Reconciliation UX & Chamber Roster Sync
- **Inline Prior Clinical Findings & 1-Tap Vitals Carry-Forward:**
  - Added `_PreviousVisitFindingsCard` directly above the vitals input grid in `VitalsAndExamSection`, surfacing the patient's prior encounter date (`DD-MM-YYYY`), consulting doctor, past vitals badges (BP, pulse, SpO2, temp, weight, blood sugar, RR), provisional diagnosis, chief complaints, and examination notes.
  - Implemented `copyVitalsFromConsultation` in `EncounterFormState` with a 1-tap `[Copy Vitals]` button to copy prior baseline vitals directly into active input controllers.
- **Medication Reconciliation Duration & CONTINUE Chip Alignment:**
  - Synchronized `ChoiceChip('CONTINUE')` selection in `ReconciliationItemRow` to stay active and accented whenever medication is continuing, regardless of whether duration is set to indefinite (`To Continue`) or acute courses (e.g. `3 Days`).
  - Added 1-tap reset to chronic indefinite continuation on tapping `[CONTINUE]`.
  - Harmonized duration selector button styling with accent teal (`#E6FFFA` background, `#0D9488` border) when continuing, and cancellation red when stopped.
- **Doctor Chamber Roster Card & Shift State Synchronization:**
  - Automated reception roster notification upon doctor login (`notifyDoctorArrived` updating chamber state to `in_chamber`).
  - Added distinct choices on chamber logout between "Lock / Log Out Only" and "End Shift & Log Out".
  - Cleaned up `DashboardDoctorRosterCard` to turn off active presence indicators (green dot and schedule highlighting) when shift is ended, and removed duplicate `[SHIFT ENDED]` badges.
- **Doctor Chamber 4-Card Operational KPI Grid:**
  - Overhauled chamber metric cards to high-utility operational metrics: `[CONSULTED]`, `[WAITING]` (lobby checked-in), `[PENDING]` (unpaid / remote reservations), and `[DOCTOR'S FEES]`.

---

## [1.5.3] — 24-10-2026

### Clinical UI Ergonomics, Step Hierarchy & Vector-Crisp Print/PDF Engine
- **Vector-Crisp HTML Printing & Blank PDF Resolution:**
  - Introduced pure Dart `PrescriptionPrintEngine` with zero Flutter UI dependencies, generating semantic, self-contained HTML for clinical prescriptions with strict 3-column table isolation, Indian date formatting (`DD-MM-YYYY`), and NMC generic uppercase standards.
  - Implemented `window.printHtmlDocument` iframe printing bridge in `web/index.html` and `platform_print_web.dart`, bypassing Flutter Web CanvasKit WebGL print spooling context drops and eliminating blank output in browser print and "Save as PDF".
- **Separation of Print Preview and Clinical Sign-Off:**
  - Decoupled `_previewCurrentPrescription` (`[Print Preview]`) into a pure read-only preview mode (`isPreSign: false`) that does not finalize the consultation or discharge the patient.
  - Preserved `_completeAndSignConsultation` (`[Finish Consultation & Sign]`) as the official one-way medical-legal sign-off pipeline (`isPreSign: true`).
- **Tablet Duration & CONTINUE Highlight Disambiguation:**
  - Refined `ChoiceChip('CONTINUE')` selection in `ReconciliationItemRow` to activate only when medication is explicitly set to indefinite chronic continuation (`To Continue`).
  - Selecting specific acute durations like `3 Days`, `5 Days`, or `7 Days` from the duration dropdown displays the chosen duration without conflicting active highlights on the `CONTINUE` chip.
- **Visual Step Hierarchy & Elevated Section Cards:**
  - Upgraded `SectionCard` and `PatientHeaderSection` with crisp slate borders (`#CBD5E1`), soft drop shadows (`alpha: 0.05`), and distinct cool grey step headers (`#F1F5F9`) with tinted teal icon containers, providing clear visual separation between Step 1 through Step 5.
- **Muted Placeholder Hint Styling:**
  - Added global `inputDecorationTheme` with soft muted italic hints (`#94A3B8`) across `main.dart` and `vitals_and_exam_section.dart`, preventing numeric hints (`120`, `80`, `98.6`) from being mistaken for entered data.

---

## [1.5.2] — 23-10-2026

### Doctor Chamber Shift Ergonomics, Gender Tab Traversal & Dummy Phone Collision Guard
- **Doctor Chamber Unified Shift End & Exit:**
  - Consolidated redundant shift buttons into a single clear `[ 🌙 End Shift & Exit ]` action in `ChamberAppBar`, concluding the shift on the reception roster and securely returning the doctor to the login screen in one atomic tap.
  - Eliminated redundant "Close Shift" and "Re-Signal Reception" cards from `ChamberControlBanner`.
- **Gender Selector Keyboard Tab Traversal Hardening:**
  - Prevented child `InkWell` options in `KeyboardGenderSelector` from intercepting Tab navigation (`canRequestFocus: false`, `descendantsAreFocusable: false`).
  - Hitting `Tab` after selecting Male/Female/Other via `M`/`F`/`O` keys now directly advances to the next form field (`Guardian / c/o`) without cycling between option buttons.
- **Emergency Dummy Mobile Range Isolation (`00` Prefix):**
  - Updated dummy emergency patient phone generator in `AppointmentEngine` from `99` to `00` prefix (`0000000001` - `0000999999`), mathematically isolating emergency/unconscious walk-in records from genuine Indian 10-digit mobile numbers.

---

## [1.5.1] — 23-10-2026

### Non-IT Real-World Robustness Audit, Input Hardening & 7-Day Booking Horizon
- **Smart Indian Phone Normalization Formatter:**
  - Introduced `IndianPhoneInputFormatter` to sanitize phone inputs on keystroke and paste without silent digit loss.
  - Automatically strips country code prefixes (`+91` or `91` when total digits > 10) and trunk/STD prefixes (`0` when total digits > 10) while preserving 10-digit mobile numbers natively starting with `91`.
  - Automatically strips spaces, dashes, parentheses, and non-numeric characters across patient booking and doctor management.
- **Financial & Registration Field Input Hardening:**
  - Enforced `FilteringTextInputFormatter.digitsOnly` and 6-digit caps with strict numeric validators on the booking amount field in `BookingPaymentSection`, preventing accidental `₹0` saves from inputs like `"500.00"` or letter typos (`"5OO"`).
  - Hardened Chamber PIN (4 digits) and Staff/Owner PIN (6 digits) on `LoginScreen` with digits-only formatters to prevent keyboard typos on web and counter PC setups.
  - Hardened `AddDoctorScreen` with digits-only formatters and range validation across consultation fees (`₹0` to `₹50,000`), Chamber PINs (strictly 4 numeric digits), daily token caps (`1` to `200`), and free review windows (`0` to `30` days).
  - Added length caps on doctor name (60), custom specialty (60), and medical council registration number (40).
- **Clinical Bounds & Vitals Sanitization:**
  - Added input formatters (`0-9.` with 6-char caps) to all vitals fields in `VitalsAndExamSection`.
  - Added clinical sanity bounding in `EncounterFormState.buildVitals()` (Systolic BP: 40–300, Diastolic BP: 20–200, Pulse: 30–250, Temp: 70–115°F, Weight: 0.5–500kg, SpO2: 40–100%), discarding physically impossible or negative inputs as `null` rather than printing invalid vitals on prescriptions.
  - Bounded custom prescription regimen duration to 1–365 days in `CustomDurationDialog`.
  - Enforced character length bounds in `AddMedicineDialog` for trade brand (100), chemical composition (150), manufacturer (80), and default dosage (40) to prevent prescription table overflow.
- **Blank Advisory Encounter Confirmation Dialog:**
  - Added soft confirmation modal in `ConsultationEncounterScreen` when a doctor clicks "Complete & Sign" with zero medicines, complaints, or diagnoses, preventing accidental one-click empty record submission while permitting valid advisory consultations.
- **Configurable 7-Day Pre-Booking Horizon:**
  - Added `maxAdvanceBookingDays: 7` to `ClinicConfig` and dynamically bounded `showDatePicker` in `AddAppointmentDialog`, tightening advance booking from 30 days to 7 days to eliminate high OPD no-show rates.
- **Roadmap Backlog Expansion:**
  - Catalogued `IDEA-6` (Doctor Retrospective Leave Conflict Detection & WhatsApp Cancellation Notices) and `IDEA-7` (Emergency Off-Day Booking Override) in `docs/MASTER_BACKLOG.md`.

---

## [1.5.0] — 23-10-2026

### Pre-Demo Production Baseline, Codebase Polish & Architecture Hardening
- **Memory Leak Elimination & Controller Lifecycle Management (P1):**
  - Converted helper-rendered modal dialogs in `DoctorListScreen` (`_showAddDoctorDialog`), `AccordionDispatchSection` (`_showEditAmountDialog`), and `EncounterDialogs` (`_showNewMedDialog`, `_showEditMedDialog`, `_showNewLabDialog`, `_showNewAdviceDialog`) into dedicated private `StatefulWidget` classes (`_AddDoctorDialog`, `_EditAmountDialog`, `_NewMedDialog`, `_EditMedDialog`, `_NewLabDialog`, `_NewAdviceDialog`).
  - Implemented explicit `dispose()` callbacks for all `TextEditingController` instances, eliminating memory leak risks across always-on counter PC displays.
- **Fast-Access Demo Credentials Alignment (P2):**
  - Synchronized owner passkey dialog hint text (`"Owner PIN (6-digit default: 000000)"`) with the active demo credential configuration in `AuthProvider` for smooth hardware-independent evaluation.
- **Booking Payment Fallback Consolidation (P3):**
  - Consolidated 5x duplicate fee fallback calculations into a single reusable helper `_fallbackToStandardPayment()` in `AddAppointmentDialog`, eliminating logic drift between doctor selection, date switching, and review resets.
- **Chamber Control Banner Decomposition (P4):**
  - Decomposed monolithic `ChamberControlBanner` into discrete, maintainable card widgets (`_ConsultationEndedCard`, `_ReadyForNextCard`, `_CallingCard`, `_InConsultationCard`) adhering to single-responsibility rendering across all 5 chamber handshake lifecycle states.
- **Error Observability & Documentation Hygiene (P5):**
  - Enriched silent catch blocks in `LiveQueueDelegate`, `DoctorStateDelegate`, `PatientService`, `SecurityService`, and `ChamberService` with structured `debugPrint` observability.
  - Cleaned duplicated documentation comments in `ClinicConfig`.
- **Milestone 1.5.0 Baseline:**
  - Transitioned active platform from 1.40 development patch line to stable minor milestone `1.5.0`.
  - Consolidated all 1.40.x architectural milestones, audit closures, and pre-demo enhancements into a unified release line.
  - Aligned all documentation (`README.md`, `AGENTS.md`, `SCHEMA_AND_MODELS.md`) and package manifests to version `1.5.0`.

---

## [1.40.0 – 1.40.17] — 20-10-2026 to 22-10-2026

### Pre-Demo Hardening, Rx Modularization, CSV Export, Scalable Search & Chamber Architecture
- **Pre-Demo Web Presentation & Fast-Access PIN Authentication (v1.40.17):**
  - Rebranded `web/index.html` application title to `"GuwahatiOne Clinic OS"` alongside matching Apple web app title and meta description.
  - Aligned `web/manifest.json` PWA configuration with unified title (`"GuwahatiOne Clinic OS"`), short title (`"Clinic OS"`), primary theme color (`#0F766E`), and responsive orientation (`"any"`).
  - Synchronized default tenant configuration in `ClinicConfig.current` (`clinicName: 'GuwahatiOne ClinicOS'`, `address: 'Guwahati, Assam'`, `contactPhone: '12345 67890'`).
  - Configured evaluation-mode authentication credentials in `AuthProvider` for temporary live trials on third-party hardware (Owner: `000000`, Reception/Doctor: `0000`) with salted SHA-256 cryptographic evaluation.
- **Rx Module Decomposition & Clean Component Extraction (v1.40.17):**
  - Decomposed the 1,135-line `reconciliation_item_row.dart` monolithic file into 4 focused single-responsibility components under `lib/widgets/encounter/rx/`: `inline_dosage_edit_dialog.dart`, `custom_duration_dialog.dart`, `new_prescription_row.dart`, and `reconciliation_item_row.dart`.
- **Chamber Service Dependency Injection & Input Bounds (v1.40.16):**
  - Updated `DoctorChamberScreen` to accept constructor-injected `BookingService` and `ChamberService` (AUDIT-16).
  - Standardized `amountCollected` resolution in `AddAppointmentDialog` using `int.tryParse` guard and bound calendar navigation to `AppConstants.clinicEpochDate` (`01-01-2025`).
- **Pre-Sign Rx Preview Gate & Technical Audit Sweep (v1.40.15):**
  - Integrated pre-sign clinical preview gate into `ConsultationEncounterScreen` and `PrescriptionPrintScreen` with amber review banner (`"PRE-SIGN CLINICAL REVIEW"`) and return-to-draft capability (QOL-19).
  - Standardized `lastVisitDate` writes to native Firestore `Timestamp` (AUDIT-17).
  - Added `enableSeedDefaultMedicines` flag under `ClinicFeatureFlags` (AUDIT-27) and `limit: 100` query bound to `getAppointmentsForPatient` (AUDIT-28).
- **Operational Hardening: Cache Debounce, Print Guard & Input Limits (v1.40.14):**
  - Added 3-second debounce timer on offline queue disk serialization in `LiveQueueDelegate` (AUDIT-15).
  - Added `_isPrinting` double-tap guard with 1500ms cooldown and progress spinner on prescription printing (AUDIT-24).
  - Enforced MBBS/MD character caps on clinical free-text inputs in consultation encounter (AUDIT-21).
- **Prepaid Carry-Over & Patient No-Show Revisit (v1.40.13):**
  - Added `PaymentType.paidCarryOver` and `BookingCarryOverBanner` enabling reception to issue fresh consecutive queue tokens for patients who paid on an earlier date but had to leave before consultation (QOL-03).
  - Purged hardcoded whole-course disease templates and flag-gated GP presets (QOL-05).
- **Doctor Sitting Days Guard in Advance Booking (v1.40.12):**
  - Enforced schedule validation in `LiveQueueDelegate.bookAppointment` and disabled advance booking on non-sitting weekdays with `BookingOffDayWarningBanner` (AUDIT-22).
- **Emergency Walk-Ins, Chamber Demographics Edit & CSV Data Export (v1.40.11):**
  - Added collision-resistant `99`-prefixed dummy phone generator (`AppointmentEngine.generateEmergencyDummyPhone()`) with `[⚡ No Phone]` walk-in button (QOL-01).
  - Added in-chamber patient demographics correction modal from encounter header (QOL-04).
  - Built pure Dart RFC-4180 CSV export engine (`DataExportEngine`) for 5 clinic ledgers (Revenue, Queue, Patients, Formulary, Consultations) with local browser download (IDEA-1).
- **Scalable Patient Name & Surname Search Beyond 50 Records (v1.40.10):**
  - Replaced in-memory query scans with indexed 2+ character prefix n-grams (`searchTokens`) and `nameLower` prefix queries in Firestore (AUDIT-08).
- **Counter Continuity & Security Simplification (v1.40.9):**
  - Completely removed 30-second screen lockout on failed PINs, displaying instant inline errors (AUDIT-04).
  - Retained clean plaintext doctor PIN storage for owner recovery per clinic operational review (AUDIT-03).
- **Reconciled Regimen Duration Dropdown & Inline Dosage Editing (v1.40.8):**
  - Added direct duration preset dropdown (`To Continue`, `3 Days`, `5 Days`, `7 Days`, `14 Days`, `1 Month`, `SOS`, `STOP`, `Custom...`) on reconciled medication cards (QOL-14).
  - Added in-place dosage, frequency, and timing editing dialog (`InlineDosageEditDialog`).
- **Cloud-Synced Security PIN Store & Multi-Terminal Rotation UI (v1.40.7):**
  - Introduced `SecurityService` to persist salted SHA-256 PIN hashes in `clinic_config/security` with 2-step verification dialog (`SecuritySettingsDialog`) in `OwnerShell` (QOL-13).
- **Authentication Hardening & Session Security (v1.40.6):**
  - Purged default test PIN hints from login UI (AUDIT-01) and removed plaintext PIN getters from `AuthProvider` (AUDIT-23).
- **Cash Handover Slip & Staged Medicine Guard (v1.40.5):**
  - Added printable end-of-day cash handover slip (P8) and staged medicine discard guard before completing consultation (QOL-15).
  - Added 1-tap WhatsApp prescription delivery from Patient Directory (QOL-18).
- **Doctor Chamber Archive & Prescribing Synthesis (v1.40.1 – v1.40.4):**
  - Historical date shift archive banner with read-only appointment lock (QOL-16).
  - Natural dosage & timing synthesis (`formattedDosageTiming`, QOL-08).
  - In-browser queue chime and vocal token callout announcer (`SoundService`, QOL-10).
  - Restructured clinical encounter with collapsible observation and prescribing steps (QOL-09).
- **Architectural Foundation & God Object Decomposition (v1.40.0):**
  - Decomposed `ClinicProvider` into 3 domain delegates (`DoctorStateDelegate`, `LiveQueueDelegate`, `CatalogueDelegate`).
  - Modularized `DashboardTodayQueueCard`, `AddAppointmentDialog`, and `AddDoctorScreen`.
  - Offline queue fallback with amber status banners and fine-grained `context.select` subscriptions.

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
