# 📋 GuwahatiOne Clinic OS — Changelog

All notable updates, clinical workflows, and architectural changes to **GuwahatiOne Clinic OS** are documented in this file in reverse chronological order.

> 💡 **Product & Engineering Reference:**  
> - **Operational Focus:** Each milestone highlights practical workflow impacts across Clinic Counter (Reception), Doctor Chamber, and Clinic Owner dashboards.  
> - **Zero Clutter Rule:** Patch releases within a minor series (e.g. `1.36.1`, `1.36.2`) are consolidated into grouped range entries (`[1.36.0 – 1.36.5]`) when jumping versions to keep the document concise.  
> - **No Verification Gates:** Internal CI/test execution metrics (`flutter analyze`, `flutter test`) belong strictly to terminal logs and git commits, never in this changelog.  
> - **Date Standard:** All release and display dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## [1.36.0 – 1.36.7] — 15-10-2026 to 19-10-2026

### Doctor Deactivation & Admin Passkey Gate, Walk-In Booking Modal, & Prescription Table Isolation
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
