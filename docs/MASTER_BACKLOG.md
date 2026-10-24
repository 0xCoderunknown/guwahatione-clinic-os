# 🎯 GuwahatiOne Clinic OS — Master Backlog & Roadmap

> **Single Source of Truth** for what remains to be built, active milestone runway, and non-negotiable architectural boundaries.  
> Detailed release notes and implementation history are preserved in [`CHANGELOG.md`](../CHANGELOG.md).  
> System capabilities, clinical workflows, and architecture are documented in [`README.md`](../README.md).  
> Canonical AI operating rules and invariants are defined in [`AGENTS.md`](../AGENTS.md).  
> **Date Standard:** All human-facing dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## 🚀 Active Roadmap Runway (What Is Left to Build)

### 📌 Milestone 1.6.0 — Master Formulary Editor & Clinical Automation (Next Up)

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

#### 2. IDEA-2 — Prescribe-to-Formulary Auto-Ingest
- **Domain:** Doctor Chamber / Prescribing
- **Status:** Pending PM Prioritization (TODO)
- **Target Files:** `lib/widgets/encounter/rx/rx_search_results_view.dart`, `lib/screens/consultation_encounter_screen.dart`
- **Specification:**
  - When a doctor prescribes an unlisted or outside drug, provide a subtle toggle `[☑ Add to Clinic Formulary]`.
  - On consultation sign-off, automatically ingests the product into `/medicines` with minimum metadata (brand name + formulation form) for future auto-complete.
  - **Ingest Guard:** Require valid trade name and formulation form to prevent typo pollution in the clinic catalogue.

#### 3. IDEA-6 — Doctor Retrospective Leave Conflict Detection & WhatsApp Cancellation Notices
- **Domain:** Clinical Operations / Reception & Patient Communication
- **Status:** Pending PM Prioritization (TODO)
- **Problem:** When an appointment is booked in advance and the doctor subsequently declares leave or blocks that date via `DoctorLeaveCalendarSection`, the system currently preserves the appointment (Rule #1 Zero Deletions) but does not alert the owner during leave save or provide an immediate resolution path to notify the patient.
- **Specification:**
  - **Pre-Save Leave Conflict Warning:** When clinic owner or doctor blocks date(s) in `DoctorLeaveCalendarSection`, query for existing active appointments on those dates. If found, display a high-priority confirmation modal:  
    *"⚠️ Dr. Sharma already has N booked appointment(s) on [Date(s)]. Blocking this date requires contacting and rescheduling or refunding these patients. Proceed to block?"*
  - **Visual Conflict Alert Badge:** On `AppointmentListScreen` and `DashboardQueueCard`, any appointment scheduled on a date where the assigned doctor is marked on leave displays a prominent red badge: `[⚠️ DOCTOR ON LEAVE — RESCHEDULE / CANCEL]`.
  - **1-Tap WhatsApp Cancellation Notice:** Inside `AppointmentAccordion` for conflicted appointments, provide a 1-tap WhatsApp button using `WhatsAppEngine.buildDeepLink`:  
    > *"Dear [Patient Name], your appointment (Token #T) with Dr. [Doctor] at GuwahatiOne Clinic on [DD-MM-YYYY] cannot be held as the doctor will be unavailable/on leave. Please contact clinic reception at [Phone] to reschedule your visit or receive a refund if paid. We sincerely regret the inconvenience."*
  - **Cancellation Resolution:** Reception can mark `AppointmentStatus.absent` (audit-proof with ₹0 fee collected) or carry over payment to a rescheduled date.

#### 4. IDEA-7 — Emergency Off-Day Booking Override with Prominent Reception Warning
- **Domain:** Booking & Queue Management / Front-Desk Flexibility
- **Status:** Pending PM Prioritization (TODO)
- **Problem:** Currently, selecting a doctor on a day they do not sit (e.g., Thursday when doctor only sits Mon/Wed/Fri) completely disables the "Book Appointment" button (`BookingOffDayWarningBanner`). In real-world clinics, patients occasionally arrive for urgent/emergency reviews, or a doctor comes in for a special unscheduled procedure.
- **Specification:**
  - In `AddAppointmentDialog`, keep the high-visibility warning banner:  
    `"⚠️ Note: Dr. [Doctor] does not regularly sit on [Weekday]. Regular OPD days: [Mon, Wed, Fri]."`
  - Instead of strictly disabling the submission button, provide an explicit **[Emergency / Off-Day Booking Override]** confirmation checkbox.
  - If checked, reception can proceed with booking. The created appointment document records `isEmergencyOffDayOverride: true` and displays an `[OFF-DAY SPECIAL ADMISSION]` amber badge in the queue to alert chamber and accounting.

---

### ⏳ Milestone 1.7.0 — Platform Operations & Commercial Controls (Backlog)

#### 5. AUDIT-26 — Subscription Expiry Runtime Enforcement
- **Domain:** Business / Commercial Operations
- **Status:** Pending PM Prioritization (TODO)
- **Target Files:** `lib/config/clinic_config.dart`, `lib/providers/clinic_provider.dart`, `lib/screens/owner_shell.dart`
- **Specification:**
  - Operating model: 1-year prepaid subscription with an extended 1-month grace period.
  - Track `subscriptionExpiry` (`Timestamp`) on the clinic configuration document.
  - Display an in-app renewal reminder banner in `OwnerShell` starting 30 days prior to expiry.
  - Post-grace-period: switch app to read-only archival mode, locking fresh walk-in bookings while keeping patient lookup, past prescriptions, and 1-click CSV data export (`DataExportEngine`) 100% accessible to guarantee zero vendor lock-in.

#### 6. AUDIT-19 — Counter Document Retention & Archival Strategy
- **Domain:** DevOps / Firestore Maintenance
- **Status:** Low-Priority Maintenance (TODO)
- **Specification:**
  - `counters/chamber_{doctorId}_{date}` documents accumulate daily (~730 docs/year for a 2-doctor clinic).
  - Define an automated or owner-triggered archival job to prune chamber sync documents older than 90–180 days while permanently preserving atomic queue counter records (`counters/queue_*`).

#### 7. IDEA-5 — Break-Glass Developer / Maintenance Mode (Remote Support & Data Purge)
- **Domain:** DevOps / Platform Maintenance / Support
- **Status:** Under Architecture Evaluation (Future Goal)
- **Concept:** A restricted developer/superadmin maintenance tier designed for remote technical support, test/dummy data cleanup (e.g., removing erroneous demo doctors, test patients, or corrupted counter docs), and recovery without exposing destructive operations to standard clinic roles (Owner, Doctor, Reception).
- **Key Safety & Isolation Guardrails:**
  - **Dead-Code Elimination / Build Stripping:** Gated behind compile-time flags (`--dart-define=ENABLE_DEV_MODE=true` or `kDebugMode`) so that standard production client binaries have destructive paths completely eliminated by the Dart tree shaker.
  - **Off-Band Break-Glass Auth:** Independent from the clinic owner PIN. Activated only via an off-band developer master key or a secure remote flag in Firestore (`/clinic_settings/system.maintenanceMode = true`).
  - **Visual Hazard Branding:** High-contrast red/purple hazard banner (`⚠️ DEVELOPER MAINTENANCE MODE — DESTRUCTIVE CAPABILITIES ACTIVE`) across the app shell to prevent accidental usage during live clinic operations.
  - **Explicit Confirmation Gates:** Irreversible actions (e.g., deleting a dummy doctor, clearing corrupted test tokens, or purging test patients) require typing exact confirmation phrases (e.g., typing `"PURGE DOCTOR"`).
  - **Immutable Maintenance Audit Trail:** All maintenance actions write append-only event logs to `_maintenance_audit_logs` before executing document mutations.

---

### ☁️ Milestone 2.0 — Cloud SaaS & Multi-Tenant Migration (Future Phase)

#### 8. AUDIT-29 — Historical Data Backfill & Legacy Fallback Query Purge
- **Domain:** Data Architecture / Schema Modernization (Zero Backward-Compatibility Debt)
- **Status:** Scheduled for Milestone 2.0
- **Specification:**
  - **Prerequisite:** Run an automated Cloud Firestore migration/backfill script to populate canonical `patientId` on any early MVP appointment/consultation records and ensure `visitStatus` exists on all historical documents.
  - **Code Cleanup:** Once backfilled, purge secondary `patientPhone` fallback queries in `BookingService.getAppointmentsForPatient` and `ConsultationService.getConsultationsForPatient`, and retire the `status` constructor adapter and `fromJson` schema shims in `Appointment` and `Patient`.
  - **Preservation Notice:** Until the cloud backfill is executed, defensive fallbacks remain active to guarantee early prototype records and historical consultations never appear blank.

#### 9. AUDIT-02 — Firestore Security Rules Hardening (`request.auth != null`)
- **Domain:** Cloud Security
- **Status:** Formally Deferred to SaaS Cloud Rollout
- **Specification:**
  - Transition from on-premise trusted hardware network with salted PIN authentication to strict Firebase Authentication tokens (`request.auth.uid != null`).
  - Multi-tenant tenant ID claims embedded in custom auth tokens.

#### 10. AUDIT-18 — Dynamic Cloud-Hosted `ClinicConfig`
- **Domain:** Cloud Architecture
- **Status:** Formally Deferred to SaaS Cloud Rollout
- **Specification:**
  - Migrate tenant branding, addresses, tax IDs, and consultation fee configurations from static Dart config files to cloud Firestore collections (`/tenants/{tenantId}/config`).

---

## 🛑 Canonical Anti-Goals (Do NOT Build)

The following architectural constraints are strictly enforced per [`AGENTS.md`](../AGENTS.md):

1. ❌ **No Pharmacy Inventory ERP:** Never build batch numbers, expiry tracking, distributor invoicing, or stock deduction ledgers.
2. ❌ **No Retail Point-of-Sale (POS) Billing:** Never build retail counter billing for OTC goods or non-consultation retail items.
3. ❌ **No Queue Token Deletions:** Never delete an appointment or token document from Firestore; always mark as `AppointmentStatus.absent` with ₹0 amount.
4. ❌ **No "Stepped Out" Intermediate Queue Status:** Receptionists have 100% full authority to dispatch any waiting lobby patient in any order.
5. ❌ **No Destructive Clinical Overwrites:** Consultations and prescriptions are append-only longitudinal records forever.
6. ❌ **No Physical Thermal Roll Receipt Printing:** Physical thermal slips are scrapped per PM directive; tokens and wait times are tracked digitally and via WhatsApp.