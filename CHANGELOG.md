# 📋 GuwahatiOne Clinic OS — Changelog

All notable updates, clinical workflows, and architectural changes to **GuwahatiOne Clinic OS** are documented in this file in reverse chronological order.

> 💡 **Product & Engineering Reference:**  
> - **Operational Focus:** Each milestone highlights practical workflow impacts across Clinic Counter (Reception), Doctor Chamber, and Clinic Owner dashboards.  
> - **Zero Clutter Rule:** Patch releases within a minor series (e.g. `1.36.1`, `1.36.2`) are consolidated into grouped range entries (`[1.36.0 – 1.36.5]`) when jumping versions to keep the document concise.  
> - **No Verification Gates:** Internal CI/test execution metrics (`flutter analyze`, `flutter test`) belong strictly to terminal logs and git commits, never in this changelog.  
> - **Date Standard:** All release and display dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

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
- **Architectural Refactoring & God Object Decomposition (Phases 1 & 2):**
  - **Decomposed Monolithic UI Widgets (Phase 1):**
    - Reduced `DashboardTodayQueueCard` from 913 lines down to 295 lines by extracting `UpcomingBookingsSection`, `QueueDoctorFilterBar`, and `DashboardQueueItemRow`.
    - Modularized `AddAppointmentDialog` by extracting `BookingOfflineBanner`, `BookingDialogActions`, and `BookingSuccessSnackbar`.
    - Modularized `AddDoctorScreen` by extracting `DoctorLeaveCalendarSection`.
  - **Decomposed `ClinicProvider` God Object (Phase 2):**
    - Refactored `ClinicProvider` into a lightweight, backward-compatible Facade over 3 dedicated domain controllers: `DoctorStateDelegate` (doctor roster & leave), `LiveQueueDelegate` (live queue, offline caching, and midnight rollover), and `CatalogueDelegate` (master formulary & curation).
    - Preserved 100% backward compatibility across all screen callers with zero breaking changes.
- **External Appointment Distraction Banner Excluded (Item 18):**
  - Permanently dropped per PM directive to guarantee distraction-free clinical focus inside the chamber during active consultations.

---

## [1.39.0] — 20-10-2026

### Pure Dart PatientSearchEngine, Same-Day Lab Reviews via Reception, Upfront Cash Drawer Accounting & Midnight Date Rollover
- **Pure Dart `PatientSearchEngine` & Multi-Attribute Lookup (Finding #21):**
  - Built pure Dart `PatientSearchEngine` with robust phone normalization (strips +91, 0, whitespace, formatting), multi-word name tokenization, and multi-tier relevance ranking (exact phone > exact name > surname prefix > partial matches).
  - Fixed `PatientService.searchPatients` to query the `phoneNumber` field instead of `FieldPath.documentId` (which failed on canonical `pat_*` IDs).
  - Added dedicated `pat_*` canonical ID lookup and integrated recent patient pool token matching so searching by surname (e.g. "Devi", "Baruah", "Sharma") or canonical ID immediately returns ranked matches.
- **Same-Day Return Visits & Lab Review Tokens via Reception (Finding #11):**
  - Updated `BookingService.hasAppointmentForDate` duplicate check to permit same-day re-booking when a prior appointment on the date has reached `AppointmentStatus.completed`. A patient consulted in the morning returning in the afternoon with lab results is routed via reception desk, receiving a valid queue token so doctors have complete operational clarity without unannounced chamber barging.
  - Enhanced `AppointmentEngine.evaluateReviewEligibility` to recognize same-day return visits (`daysSincePaid == 0`) with descriptive status `'Same-day return / lab review'`, correctly unlocking doctor-configured free review waivers (`PaymentType.freeReview`).
- **Upfront Desk Cash Drawer Accounting & Session Close Preservation (Finding #19):**
  - Updated `CashHandoverEngine` to count physical cash collected upfront at the reception counter (`PaymentType.paidCash` with `amountCollected > 0`) regardless of whether the patient is in lobby, in consultation, or completed, perfectly mirroring real physical cash in drawer.
  - Fixed `BookingService.closeDoctorSessionForDate` to NEVER destructively zero out `amountCollected` on doctor absence. Retains collected cash amounts in the audit trail and tags `refundStatus: 'pending_refund'`.
  - Added `refundStatus` (`'none'`, `'pending_refund'`, `'refunded'`) on `Appointment` model and serialized to Firestore and offline cache.
  - `CashHandoverEngine` skips visits only when `refundStatus == 'refunded'`, eliminating ghost discrepancies between counted drawer cash and system expectations.
- **Automatic Midnight Date Rollover Observer (Finding #10):**
  - Implemented periodic 30-second midnight rollover observer (`checkAndHandleMidnightRollover`) inside `ClinicProvider`. When counter PCs remain powered on overnight, the observer detects calendar day shift (`!DateUtils.isSameDay(_activeListeningDate, now)`), automatically cancels the previous day's stream, resets today's appointment list, and re-subscribes live queue streams to the new calendar day.
  - Operates automatically for live queue sessions while preserving intentional user archive browsing when historical dates are explicitly selected.
- **Soft Daily Token Cap Retained per PM Directive (Finding #12):**
  - Retained soft visual quota warning badge per Product Manager directive. In clinical practice, strict hard modal locks paralyze front-desk operations during walk-in emergencies. If limits are reached, soft warnings display prominently on desk badges while doctors retain discretion to verbally coordinate with reception.

---

## [1.38.0] — 20-10-2026

### Prescribing Safety Guardrails, Flexible Multi-Modal Duration System & Diagnostic Test Deduplication
- **Flexible Multi-Modal Duration Engine & Pharmacological Validation (Finding #16):**
  - Implemented `MedicineEngine.parseDuration` accepting acute numeric days (`1 to 300` days, e.g. `5`, `14`, `21 days`), as-needed (`SOS`, `SoS`, `s.o.s`), and ongoing chronic therapy (`To continue`, `cont`, `chronic`).
  - Added inline pharmacological sanity checks strictly blocking negative (`<= 0`) or excessive (`> 300`) day values with clear feedback.
  - Enhanced `StagedMedicineForm` with 1-tap quick preset chips (`[Cont]`, `[SOS]`, `[3d]`, `[5d]`, `[7d]`, `[14d]`, `[30d]`) alongside direct keyboard input.
  - Integrated `effectiveDuration` getter in `PrescriptionItem` to guarantee strict 3-column isolation across print letterheads, preview tables, WhatsApp summaries, and consultation charts.
  - Ensured formulary catalogue bundled defaults (e.g. *Telma 40 tablet* with `{Telmisartan 40mg, 1-0-1, to continue}`) populate intact into staging without clinical friction.
- **Staged Medicine Discard Guard (Finding #15):**
  - Added `hasStagedMedicine` and `stagedMedicineDisplayName` in `EncounterFormState`.
  - In `ConsultationEncounterScreen`, intercept "Complete & Sign" when a medicine is actively staged without being added, offering doctors an interactive dialog with `[Add to Prescription & Sign]`, `[Discard & Sign]`, and `[Review / Cancel]`, eliminating silent drops of configured medications.
- **Longitudinal Diagnostic Test Deduplication (Finding #17):**
  - Updated `EncounterFormState.loadInitialData` to track `seenTestNames` across past consultations and deduplicate by normalized `testName.trim().toLowerCase()`.
  - Eliminates exponential ghost blank row accumulation in chronic follow-up charts while ensuring all unique past investigations remain accessible for review.
- **Documented Allergy Presentation Retained (Finding #14):**
  - Retained passive allergy header chips in `PatientHeaderSection` per PM directive, avoiding administrative popup roadblocks while preserving clear clinical visibility.

---

## [1.37.0] — 19-10-2026

### Multi-Chamber Live Queue Partitioning, Upcoming Advance Bookings & Bypassed Tag Retirement
- **Retirement of Arbitrary `BYPASSED` Badge & Clean FIFO Lobby Queue:**
  - Completely eliminated the `bypassed` badge, calculation, and amber styling from `AppointmentEngine.partitionQueueForReception` and `AppointmentAccordion` per real-world OPD operational realities.
  - When doctors admit relatives, emergency walk-ins, or elderly patients out of strict sequential order, uncalled patients in the lobby remain in clean, unpenalized FIFO queue order without being arbitrarily labeled "Late" or "Bypassed".
- **Multi-Chamber Queue Partitioning (`inChamberPatients`):**
  - Enhanced `ReceptionQueueView` to support `inChamberPatients` list (`List<Appointment> inChamberPatients` with `Appointment? get inChamber => inChamberPatients.firstOrNull`).
  - Supports concurrent multi-doctor clinics where multiple practitioners are in session simultaneously (e.g., Dr. A consulting Token #8 in Chamber 1, Dr. B consulting Token #3 in Chamber 2). Both patients render prominently in top active chamber cards, and neither leaks into the waiting list.
- **Date-Specific Doctor Filter Chips on Live Ledger (`AppointmentListScreen`):**
  - Updated doctor filter chips to dynamically show strictly doctors who have an OPD schedule on the selected calendar date (and are not on planned leave) OR who have existing appointments booked for that date.
  - Clinics with 10 registered physicians displaying a 3-doctor OPD day will now only render chips for the 3 active doctors, eliminating visual clutter.
- **Upcoming Advance Bookings on Reception Dashboard (`DashboardTodayQueueCard`):**
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
  - Purged legacy archives (`docs/archive/`) and historical decision logs (`docs/decisions/`) to establish a zero-hallucination, single source of truth (`AGENTS.md`, `docs/SCHEMA_AND_MODELS.md`, `docs/PRODUCT_ROADMAP.md`).
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

## [1.31.0] — 14-10-2026

### Doctor Chamber Mobile & Historical Archive De-Duplication
- Compact 1-line archive banner: `🔒 Viewing Past Records (Read-Only)`.
- Consolidated historical status into a single muted `No-Show` pill; enabled direct card tapping for consultation summaries.
- Tightened metric subtitles for mobile viewports (< 450px).

---

## [1.30.0] — 14-10-2026

### Dashboard Header Reorganization & Operational Lifecycle KPI Hierarchy
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
