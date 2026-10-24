# 🎯 GuwahatiOne Clinic OS — Master Backlog & Roadmap

> **Single Source of Truth** for what remains to be built, active milestone runway, and non-negotiable architectural boundaries.  
> Detailed release notes and implementation history are preserved in [`CHANGELOG.md`](../CHANGELOG.md).  
> Canonical AI operating rules and invariants are defined in [`AGENTS.md`](../AGENTS.md).  
> **Date Standard:** All human-facing dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## 🚀 Active Roadmap Runway (What Is Left to Build)

### 📌 Milestone 1.5.1 — Master Formulary Editor & Chamber Architecture (Next Up)

#### 1. IDEA-3 — In-App Master Medicine Editor
- **Domain:** Catalogue Management / Clinic Administration
- **Status:** Approved for Implementation (TODO)
- **Target Files:** `lib/screens/medicine_catalogue_screen.dart`, `lib/widgets/catalogue/add_medicine_dialog.dart`, `lib/services/catalogue_service.dart`
- **Specification:**
  - Add an edit action button (`Icons.edit_outlined`) to `CatalogueMedicineCard`.
  - Opens `AddMedicineDialog(medicineToEdit: item)` pre-populated with trade brand name, generic chemical composition, formulation form, strength, and manufacturer.
  - Submits through `CatalogueService.updateMedicine(updatedMedicine)`.
  - **Role Guard:** Strictly locked to Clinic Owner PIN session (Receptionist & Doctor chamber cannot modify catalogue).
  - **Longitudinal Safety Invariant:** Editing a catalogue drug modifies future auto-complete queries only; historical `PrescriptionItem` snapshots on past consultation encounters are append-only and strictly immutable.

---

### ⏳ Milestone 1.5.2+ — Operational & Commercial Enhancements (Backlog)

#### 3. IDEA-2 — Prescribe-to-Formulary Auto-Ingest
- **Domain:** Doctor Chamber / Prescribing
- **Status:** Pending PM Prioritization (TODO)
- **Target Files:** `lib/widgets/encounter/rx/rx_search_results_view.dart`, `lib/screens/consultation_encounter_screen.dart`
- **Specification:**
  - When a doctor prescribes an unlisted or outside drug, provide a subtle toggle `[☑ Add to Clinic Formulary]`.
  - On consultation sign-off, automatically ingests the product into `/medicines` with minimum metadata (brand name + formulation form) for future auto-complete.
  - **Ingest Guard:** Require valid trade name and formulation form to prevent typo pollution in the clinic catalogue.

#### 4. AUDIT-26 — Subscription Expiry Runtime Enforcement
- **Domain:** Business / Commercial Operations
- **Status:** Pending PM Prioritization (TODO)
- **Target Files:** `lib/config/clinic_config.dart`, `lib/providers/clinic_provider.dart`, `lib/screens/owner_shell.dart`
- **Specification:**
  - Operating model: 1-year prepaid subscription with an extended 1-month grace period.
  - Track `subscriptionExpiry` (`Timestamp`) on the clinic configuration document.
  - Display an in-app renewal reminder banner in `OwnerShell` starting 30 days prior to expiry.
  - Post-grace-period: switch app to read-only archival mode, locking fresh walk-in bookings while keeping patient lookup, past prescriptions, and 1-click CSV data export (`DataExportEngine`) 100% accessible to guarantee zero vendor lock-in.

#### 5. AUDIT-19 — Counter Document Retention & Archival Strategy
- **Domain:** DevOps / Firestore Maintenance
- **Status:** Low-Priority Maintenance (TODO)
- **Specification:**
  - `counters/chamber_{doctorId}_{date}` documents accumulate daily (~730 docs/year for a 2-doctor clinic).
  - Define an automated or owner-triggered archival job to prune chamber sync documents older than 90–180 days while permanently preserving atomic queue counter records (`counters/queue_*`).

#### 6. IDEA-5 — Break-Glass Developer / Maintenance Mode (Remote Support & Data Purge)
- **Domain:** DevOps / Platform Maintenance / Support
- **Status:** Under Architecture Evaluation (Future Goal)
- **Concept:** A restricted developer/superadmin maintenance tier designed for remote technical support, test/dummy data cleanup (e.g., removing erroneous demo doctors, test patients, or corrupted counter docs), and recovery without exposing destructive operations to standard clinic roles (Owner, Doctor, Reception).
- **Key Safety & Isolation Guardrails:**
  - **Dead-Code Elimination / Build Stripping:** Gated behind compile-time flags (`--dart-define=ENABLE_DEV_MODE=true` or `kDebugMode`) so that standard production client binaries have destructive paths completely eliminated by the Dart tree shaker.
  - **Off-Band Break-Glass Auth:** Independent from the clinic owner PIN. Activated only via an off-band developer master key or a secure remote flag in Firestore (`/clinic_settings/system.maintenanceMode = true`).
  - **Visual Hazard Branding:** High-contrast red/purple hazard banner (`⚠️ DEVELOPER MAINTENANCE MODE — DESTRUCTIVE CAPABILITIES ACTIVE`) across the app shell to prevent accidental usage during live clinic operations.
  - **Explicit Confirmation Gates:** Irreversible actions (e.g., deleting a dummy doctor, clearing corrupted test tokens, or purging test patients) require typing exact confirmation phrases (e.g., typing `"PURGE DOCTOR"`).
  - **Immutable Maintenance Audit Trail:** All maintenance actions write append-only event logs to `_maintenance_audit_logs` before executing document mutations.

#### 7. IDEA-6 — Doctor Retrospective Leave Conflict Detection & WhatsApp Cancellation Notices
- **Domain:** Clinical Operations / Reception & Patient Communication
- **Status:** Pending PM Prioritization (Future Milestone)
- **Problem:** When an appointment is booked in advance (e.g., next week) and the doctor subsequently declares leave or blocks that date via `DoctorLeaveCalendarSection`, the system currently preserves the appointment (Rule #1 Zero Deletions) but does not alert the owner during leave save or provide an immediate resolution path to notify the patient.
- **Specification:**
  - **Pre-Save Leave Conflict Warning:** When clinic owner or doctor blocks date(s) in `DoctorLeaveCalendarSection`, query for existing active appointments on those dates. If found, display a high-priority confirmation modal:  
    *"⚠️ Dr. Sharma already has N booked appointment(s) on [Date(s)]. Blocking this date requires contacting and rescheduling or refunding these patients. Proceed to block?"*
  - **Visual Conflict Alert Badge:** On `AppointmentListScreen` and `DashboardQueueCard`, any appointment scheduled on a date where the assigned doctor is marked on leave displays a prominent red badge: `[⚠️ DOCTOR ON LEAVE — RESCHEDULE / CANCEL]`.
  - **1-Tap WhatsApp Cancellation Notice:** Inside `AppointmentAccordion` for conflicted appointments, provide a 1-tap WhatsApp button using `WhatsAppEngine.buildDeepLink`:  
    > *"Dear [Patient Name], your appointment (Token #T) with Dr. [Doctor] at GuwahatiOne Clinic on [DD-MM-YYYY] cannot be held as the doctor will be unavailable/on leave. Please contact clinic reception at [Phone] to reschedule your visit or receive a refund if paid. We sincerely regret the inconvenience."*
  - **Cancellation Resolution:** Reception can mark `AppointmentStatus.absent` (audit-proof with ₹0 fee collected) or carry over payment to a rescheduled date.

#### 8. IDEA-7 — Emergency Off-Day Booking Override with Prominent Reception Warning
- **Domain:** Booking & Queue Management / Front-Desk Flexibility
- **Status:** Pending PM Prioritization (Future Milestone)
- **Problem:** Currently, selecting a doctor on a day they do not sit (e.g., Thursday when doctor only sits Mon/Wed/Fri) completely disables the "Book Appointment" button (`BookingOffDayWarningBanner`). In real-world clinics, patients occasionally arrive for urgent/emergency reviews, or a doctor comes in for a special unscheduled procedure.
- **Specification:**
  - In `AddAppointmentDialog`, keep the high-visibility warning banner:  
    `"⚠️ Note: Dr. [Doctor] does not regularly sit on [Weekday]. Regular OPD days: [Mon, Wed, Fri]."`
  - Instead of strictly disabling the submission button, provide an explicit **[Emergency / Off-Day Booking Override]** confirmation checkbox.
  - If checked, reception can proceed with booking. The created appointment document records `isEmergencyOffDayOverride: true` and displays an `[OFF-DAY SPECIAL ADMISSION]` amber badge in the queue to alert chamber and accounting.

#### 9. AUDIT-29 — Historical Data Backfill & Legacy Fallback Query Purge
- **Domain:** Data Architecture / Schema Modernization (Zero Backward-Compatibility Debt)
- **Status:** Scheduled for Future Milestone (Milestone 2.0 / SaaS Migration)
- **Specification:**
  - **Prerequisite:** Run an automated Cloud Firestore migration/backfill script to populate canonical `patientId` on any early MVP appointment/consultation records and ensure `visitStatus` exists on all historical documents.
  - **Code Cleanup:** Once backfilled, purge secondary `patientPhone` fallback queries in `BookingService.getAppointmentsForPatient` and `ConsultationService.getConsultationsForPatient`, and retire the `status` constructor adapter and `fromJson` schema shims in `Appointment` and `Patient`.
  - **Preservation Notice:** Until the cloud backfill is executed, defensive fallbacks remain active to guarantee early prototype records and historical consultations never appear blank.

---

### ☁️ SaaS Multi-Tenant Cloud Phase (Formally Deferred)

| ID | Domain | Scope & Deferral Rationale |
|---|---|---|
| **AUDIT-02** | Security | **Firestore Security Rules Hardening (`request.auth != null`):** Deferred for private on-premise clinic pilot operating on 3 trusted hardware stations behind domain-salted SHA-256 PIN authentication. Strict Firebase Auth rules will be implemented for public SaaS cloud hosting. |
| **AUDIT-18** | Architecture | **Dynamic Cloud-Hosted `ClinicConfig`:** Migrating tenant branding, addresses, and fees from static Dart constants to cloud Firestore collections will be executed during multi-tenant SaaS tenant provisioning. |

---

## 📊 Historical Resolutions & Audit Log

> All items below have been implemented, verified with automated test suites, and deployed. For detailed commit notes and file diffs, see [`CHANGELOG.md`](../CHANGELOG.md).

### Audit Findings Ledger (AUDIT-01 to AUDIT-28)

| ID | Status | Domain | Resolution Summary | Milestone |
|---|---|---|---|---|
| **AUDIT-01** | 🟢 Resolved | Security / UX | Removed default test PINs and credential hints from login UI | v1.40.6 |
| **AUDIT-02** | 🟡 Deferred | Security | Firestore open rules hardening deferred to cloud SaaS rollout | SaaS Phase |
| **AUDIT-03** | 🟢 Scrapped | Security | Doctor PINs kept readable in Firestore for owner recovery (intentional) | v1.40.8 |
| **AUDIT-04** | 🟢 Resolved | Security | Screen lockout on failed PINs purged; instant inline error displayed | v1.40.9 |
| **AUDIT-05** | 🟢 Resolved | Data Integrity | Chunked bulk session closes into safe Firestore batches of $\le 450$ docs | v1.40.10 |
| **AUDIT-06** | 🟢 Resolved | Schema | Purged ghost field `formattedAge`; standardized on `patientAgeDisplay` | v1.40.10 |
| **AUDIT-07** | ⚪ Scrapped | Concurrency | Single-doctor TOCTOU cancelled; concurrent multi-doctor clinics supported | v1.40.8 |
| **AUDIT-08** | 🟢 Resolved | Search / UX | Scalable n-gram lookup via `PatientSearchEngine` replacing 50-item ceiling | v1.40.10 |
| **AUDIT-09** | 🟢 Resolved | Business Logic | Free review window (0–30 days) and 1:1 consumption strictly enforced | v1.40.10 |
| **AUDIT-10** | 🟢 Resolved | Business Logic | Unified default consultation fee constants between config and models | v1.40.10 |
| **AUDIT-11** | 🟢 Resolved | Documentation | Clarified `blockedDates` human formatting (`DD-MM-YYYY`) vs ISO storage | v1.40.10 |
| **AUDIT-12** | 🟢 Closed | Security | Doctor PIN verification aligned with plaintext invariant (`hashPin(pin)`) | v1.40.15 |
| **AUDIT-13** | 🟢 Resolved | Clinical Flow | Discard consultation properly resets appointment status to `waitingInLobby` | v1.40.10 |
| **AUDIT-14** | 🟢 Resolved | UX / Navigation | Bounded calendar navigation to `AppConstants.clinicEpochDate` (01-01-2025) | v1.40.15 |
| **AUDIT-15** | 🟢 Resolved | Performance | Debounced offline queue cache writes with 3s cooldown timer | v1.40.14 |
| **AUDIT-16** | 🟢 Resolved | Architecture | Constructor DI for `BookingService` and `ChamberService` in chamber screen | v1.40.16 |
| **AUDIT-17** | 🟢 Resolved | Schema | Standardized `lastVisitDate` write to native Firestore `Timestamp` | v1.40.15 |
| **AUDIT-18** | 🟡 Deferred | Architecture | Dynamic runtime tenant config migration deferred to SaaS phase | SaaS Phase |
| **AUDIT-19** | 🔵 Open | Maintenance | Chamber counter document retention strategy (tracked above in Milestone 1.5.2+) | Milestone 1.5.2+ |
| **AUDIT-20** | 🟢 Resolved | Firestore Ops | Verified single-field automatic indexing on `counters.date` queries | v1.40.15 |
| **AUDIT-21** | 🟢 Resolved | Clinical UX | Enforced MBBS/MD character caps and live counters on free-text inputs | v1.40.14 |
| **AUDIT-22** | 🟢 Resolved | Business Logic | Doctor sitting days (`availableDays`) enforced in advance booking modal | v1.40.12 |
| **AUDIT-23** | 🟢 Resolved | Security | Purged plaintext PIN getters from `AuthProvider`; strictly hashed in memory | v1.40.6 |
| **AUDIT-24** | 🟢 Resolved | Hardware Print | Debounced print button with 1500ms cooldown and progress indicator | v1.40.14 |
| **AUDIT-25** | 🟢 Resolved | Analytics | Fixed `free` metric in revenue engine to exclude `unpaid` bookings | v1.40.10 |
| **AUDIT-26** | 🔵 Open | Commercial | Subscription expiry runtime enforcement (tracked above in Milestone 1.5.2+) | Milestone 1.5.2+ |
| **AUDIT-27** | 🟢 Resolved | Formulary Ops | Added `enableSeedDefaultMedicines` flag to suppress test seeds in production | v1.40.15 |
| **AUDIT-28** | 🟢 Resolved | Performance | Added `limit: 100` query bound to `getAppointmentsForPatient` | v1.40.15 |
| **AUDIT-29** | 🔵 Open | Data Architecture | Cloud Firestore data backfill & legacy phone fallback purge | Milestone 2.0 |

---

### Quality-of-Life (QOL) Backlog Ledger

| ID | Status | Workflow Domain | Summary | Milestone |
|---|---|---|---|---|
| **QOL-01** | 🟢 Resolved | Reception Desk | 1-tap `[⚡ No Phone]` emergency key generator (`99`-prefixed keys) | v1.40.11 |
| **QOL-02** | ❌ Scrapped | Reception Desk | Thermal POS token slips cancelled (tokens tracked digitally & on WhatsApp) | v1.40.14 |
| **QOL-03** | 🟢 Resolved | Financial Ledger | Prepaid carry-over (`PaymentType.paidCarryOver`) with zero ghost cash | v1.40.13 |
| **QOL-04** | 🟢 Resolved | Doctor Chamber | Inline demographics correction dialog directly from encounter header | v1.40.11 |
| **QOL-05** | 🟢 Resolved | Clinical Prescribing | Purged hardcoded whole-course templates; gated behind feature flag | v1.40.13 |
| **QOL-06** | 🟢 Resolved | Financial Ledger | End-of-day upfront cash handover modal with currency note calculator | v1.40.5 |
| **QOL-07** | 🟢 Resolved | Doctor Chamber | Multi-doctor queue partitioning and cross-chamber dispatch guards | v1.40.2 |
| **QOL-08** | 🟢 Resolved | Clinical Prescribing | Natural dosage and timing text synthesis (`formattedDosageTiming`) | v1.40.4 |
| **QOL-09** | 🟢 Resolved | Doctor Chamber | Collapsible clinical encounter steps to minimize vertical scrolling | v1.40.1 |
| **QOL-10** | 🟢 Resolved | Doctor Chamber | In-clinic queue chime and vocal token callout announcer (`SoundService`) | v1.40.3 |
| **QOL-11** | 🟢 Resolved | Doctor Chamber | Emergency door override self-call bar restricted to verified lobby tokens | v1.40.2 |
| **QOL-13** | 🟢 Resolved | Security / Admin | Cloud-synced SHA-256 PIN credentials store in `clinic_config/security` | v1.40.7 |
| **QOL-14** | 🟢 Resolved | Clinical Prescribing | In-place duration dropdown and inline dosage edit on reconciled regimens | v1.40.7 |
| **QOL-15** | 🟢 Resolved | Clinical Safety | Staged medicine discard guard before completing consultation | v1.40.5 |
| **QOL-16** | 🟢 Resolved | Doctor Chamber | Historical date shift archive banner with read-only appointment lock | v1.40.4 |
| **QOL-17** | 🟢 Resolved | Reception Desk | Automatic midnight date rollover observer on always-on counter PCs | v1.40.3 |
| **QOL-18** | 🟢 Resolved | Communications | 1-tap WhatsApp prescription delivery from Patient Lookup directory | v1.40.5 |
| **QOL-19** | 🟢 Resolved | Clinical Safety | Pre-sign Rx preview gate with amber clinical review banner and confirm action | v1.40.15 |
| **QOL-20** | ❌ Scrapped | Reception Queue | "Stepped out" queue status cancelled (reception dispatches lobby freely) | v1.40.14 |

---

### Product Ideas Evaluated

| ID | Status | Summary | Outcome |
|---|---|---|---|
| **IDEA-1** | 🟢 Resolved | Pure Dart RFC-4180 CSV export for 5 clinic ledgers (`DataExportEngine`) | Shipped in v1.40.11 |
| **IDEA-2** | 🟡 Backlog | Prescribe-to-formulary auto-ingest checkbox for outside medicines | Backlog Milestone 1.5.2+ |
| **IDEA-3** | 🟢 Approved | In-app master medicine editor for clinic owners (`MedicineCatalogueScreen`) | Approved for Milestone 1.5.1 |
| **IDEA-4** | ⚪ Deferred | Anonymized prescription volume telemetry for regional disease intelligence | Under evaluation |
| **IDEA-5** | ⚪ Architecture Evaluation | Break-Glass Developer / Maintenance Mode (remote support & dummy data purge) | Future Goal |

---

## 🛑 Canonical Anti-Goals (Do NOT Build)

The following architectural constraints are strictly enforced per [`AGENTS.md`](../AGENTS.md):

1. ❌ **No Pharmacy Inventory ERP:** Never build batch numbers, expiry tracking, distributor invoicing, or stock deduction ledgers.
2. ❌ **No Retail Point-of-Sale (POS) Billing:** Never build retail counter billing for OTC goods or non-consultation retail items.
3. ❌ **No Queue Token Deletions:** Never delete an appointment or token document from Firestore; always mark as `AppointmentStatus.absent` with ₹0 amount.
4. ❌ **No "Stepped Out" Intermediate Queue Status:** Receptionists have 100% full authority to dispatch any waiting lobby patient in any order.
5. ❌ **No Destructive Clinical Overwrites:** Consultations and prescriptions are append-only longitudinal records forever.
6. ❌ **No Physical Thermal Roll Receipt Printing:** Physical thermal slips are scrapped per PM directive; tokens and wait times are tracked digitally and via WhatsApp.