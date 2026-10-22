# 🎯 GuwahatiOne Clinic OS — Master Backlog & Roadmap

> **Single Source of Truth** for what remains to be built, active milestone runway, and non-negotiable architectural boundaries.  
> Detailed release notes and implementation history are preserved in [`CHANGELOG.md`](../CHANGELOG.md).  
> Canonical AI operating rules and invariants are defined in [`AGENTS.md`](../AGENTS.md).  
> **Date Standard:** All human-facing dates strictly follow Indian numerical formatting (`DD-MM-YYYY`).

---

## 🚀 Active Roadmap Runway (What Is Left to Build)

### 📌 Milestone 1.41 — Master Formulary Editor & Chamber Architecture (Next Up)

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

#### 2. AUDIT-16 — `DoctorChamberScreen` Service Dependency Injection
- **Domain:** Architecture / State Management
- **Status:** Approved for Implementation (TODO)
- **Target Files:** `lib/screens/doctor_chamber_screen.dart` lines 27–28
- **Specification:**
  - Remove direct instantiations: `final BookingService _bookingService = BookingService();` and `final ChamberService _chamberService = ChamberService();`.
  - Inject services via constructor arguments or consume them through `ClinicProvider` delegates (`LiveQueueDelegate` and `ChamberService`).
  - Eliminates parallel uncoordinated Firestore streams and ensures 100% testability with mock service injection.

---

### ⏳ Milestone 1.42+ — Operational & Commercial Enhancements (Backlog)

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
| **AUDIT-16** | 🟡 Open | Architecture | `DoctorChamberScreen` service DI cleanup (tracked above in Milestone 1.41) | Milestone 1.41 |
| **AUDIT-17** | 🟢 Resolved | Schema | Standardized `lastVisitDate` write to native Firestore `Timestamp` | v1.40.15 |
| **AUDIT-18** | 🟡 Deferred | Architecture | Dynamic runtime tenant config migration deferred to SaaS phase | SaaS Phase |
| **AUDIT-19** | 🔵 Open | Maintenance | Chamber counter document retention strategy (tracked above in Milestone 1.42) | Milestone 1.42 |
| **AUDIT-20** | 🟢 Resolved | Firestore Ops | Verified single-field automatic indexing on `counters.date` queries | v1.40.15 |
| **AUDIT-21** | 🟢 Resolved | Clinical UX | Enforced MBBS/MD character caps and live counters on free-text inputs | v1.40.14 |
| **AUDIT-22** | 🟢 Resolved | Business Logic | Doctor sitting days (`availableDays`) enforced in advance booking modal | v1.40.12 |
| **AUDIT-23** | 🟢 Resolved | Security | Purged plaintext PIN getters from `AuthProvider`; strictly hashed in memory | v1.40.6 |
| **AUDIT-24** | 🟢 Resolved | Hardware Print | Debounced print button with 1500ms cooldown and progress indicator | v1.40.14 |
| **AUDIT-25** | 🟢 Resolved | Analytics | Fixed `free` metric in revenue engine to exclude `unpaid` bookings | v1.40.10 |
| **AUDIT-26** | 🔵 Open | Commercial | Subscription expiry runtime enforcement (tracked above in Milestone 1.42) | Milestone 1.42 |
| **AUDIT-27** | 🟢 Resolved | Formulary Ops | Added `enableSeedDefaultMedicines` flag to suppress test seeds in production | v1.40.15 |
| **AUDIT-28** | 🟢 Resolved | Performance | Added `limit: 100` query bound to `getAppointmentsForPatient` | v1.40.15 |

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
| **IDEA-2** | 🟡 Backlog | Prescribe-to-formulary auto-ingest checkbox for outside medicines | Backlog Milestone 1.42 |
| **IDEA-3** | 🟢 Approved | In-app master medicine editor for clinic owners (`MedicineCatalogueScreen`) | Approved for Milestone 1.41 |
| **IDEA-4** | ⚪ Deferred | Anonymized prescription volume telemetry for regional disease intelligence | Under evaluation |

---

## 🛑 Canonical Anti-Goals (Do NOT Build)

The following architectural constraints are strictly enforced per [`AGENTS.md`](../AGENTS.md):

1. ❌ **No Pharmacy Inventory ERP:** Never build batch numbers, expiry tracking, distributor invoicing, or stock deduction ledgers.
2. ❌ **No Retail Point-of-Sale (POS) Billing:** Never build retail counter billing for OTC goods or non-consultation retail items.
3. ❌ **No Queue Token Deletions:** Never delete an appointment or token document from Firestore; always mark as `AppointmentStatus.absent` with ₹0 amount.
4. ❌ **No "Stepped Out" Intermediate Queue Status:** Receptionists have 100% full authority to dispatch any waiting lobby patient in any order.
5. ❌ **No Destructive Clinical Overwrites:** Consultations and prescriptions are append-only longitudinal records forever.
6. ❌ **No Physical Thermal Roll Receipt Printing:** Physical thermal slips are scrapped per PM directive; tokens and wait times are tracked digitally and via WhatsApp.