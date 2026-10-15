# 🤖 GuwahatiOne Clinic OS — AI Operating Constitution & Guardrails

> **MANDATORY CONTEXT FOR ALL AI AGENTS & CODING ASSISTANTS**  
> Read this file **first** before planning, analyzing, or modifying any code in this repository.  
> The human user is the **Strict Product Manager (PM)**. You are the **Senior Clinical Systems Architect & Engineer**.

---

## 🏛️ 1. The Core Philosophy & Non-Negotiable Invariants

Any code or proposal that violates these tenets is strictly **REJECTED**:

1. **Audit-Proof Operational Ledger (Zero Deletions):**
   - **Never delete an appointment or token document from Firestore.**
   - Queue / Token numbers ($1 \dots N$) must be strictly consecutive and immutable per doctor per calendar date.
   - If a patient leaves, cancels, or does not show up, their status is set to `AppointmentStatus.absent` with `amountCollected: 0`. The token slot is preserved permanently on screen and in database to ensure zero cheating between reception and consulting physicians.
   - Queue numbers must always be allocated atomically via Firestore transaction (`counters/queue_{doctorId}_{yyyy-MM-dd}`).

2. **Longitudinal Clinical Records Over Paper Artifacts:**
   - Prescriptions and consultations are **append-only** clinical events (`consultations` collection).
   - Past consultations are never overwritten or edited on a follow-up visit.
   - Subsequent encounters record medication reconciliation states: `START` (new therapy), `CONTINUE` (reconciled chronic regimen), or `STOP` (explicit discontinuation with `stopReason`).
   - The printed prescription is a transient output; the append-only clinical history across visits is the core product.

3. **Longitudinal Clinical Encounter Architecture:**
   - Prescriptions and consultations are **append-only** clinical events (`consultations` collection). Past encounters are never overwritten or mutated.
   - Encounters are structured around familiar Indian MBBS/MD clinical workflows:
     - **Header & Passive Allergy Alert:** Patient demographics with passive free-text allergy chip.
     - **Clinical Observations:** Compact vitals grid + MBBS standard notes (`C/O` Chief Complaints, `O/E` On Examination, `Dx`/`P/D` Provisional Diagnosis).
     - **Past History & 1-Click Carry Forward:** Prior visits viewable read-only; single `[CARRY FORWARD]` button copies prior regimen into active prescription as `CONTINUE` items.
     - **Medication Reconciliation & Prescribing:** Unified brand/composition search, pre-filled clinical defaults, rapid frequency chips (`1-0-1`, `1-0-0`, `0-0-1`, `1-1-1`, `SOS`), and timing chips (`After Food / PC`, `Before Food / Khali Pet / AC`).
     - **Diagnostic Orders & Follow-Up Advice:** Ordered lab tests, free-form remarks/diet instructions, and structured next review dropdown (`3 days`, `7 days`, `14 days`, `1 month`, `3 months`, `Not Needed`).
   - Clinical encounter sections are modular and collapsible (HK-1). Doctors can record observations in any order without forced linear roadblocks.

4. **Product Boundaries (What Clinic OS Is NOT):**
   - **NOT** a Pharmacy ERP or retail billing software.
   - **NOT** an inventory stock management ledger.
   - **NOT** an insurance claims billing platform.
   - Do **NOT** propose or build inventory management or retail point-of-sale features unless explicitly requested by the PM.

5. **Real-World Responsive Layout Specifications Across Clinic Tiers:**
   Every dashboard, encounter, and shell screen must strictly adhere to operational form factor standards:
   - **Counter PC Monitors (FHD 21.5"-24" / 1920×1080):** Never bottleneck dashboard containers with small arbitrary caps like `maxWidth: 1400` that leave 150px+ dead margins on the sides. Container constraints must allow up to `1800px` with side-by-side split panels (`flex: 6` Queue, `flex: 4` Doctor Roster) when `width >= 1050`.
   - **Counter Laptops (14"/15.6" / 1366×768 & 1536×864):** Usable vertical height is tightly budgeted (~640px). Never waste screen height with duplicate revenue badges or booking buttons when `OwnerShell`'s top AppBar already renders them. Inter-section gaps must stay compact (12–16px, never 24px+). "Today's Live Queue" must be visible above the fold without forced scrolling.
   - **Suppression of Double AppBars on Embedded Desktop Screens:** When secondary screens (`AppointmentListScreen`, `DoctorListScreen`, `StatisticsScreen`, `MedicineCatalogueScreen`) are embedded in `OwnerShell` on desktop, their inner `AppBar` must be suppressed (`!isDesktop || Navigator.canPop(context)`), preventing stacked duplicate headers.
   - **Mobile (Pixel / iPhone 390–430px):** Must remain seamless edge-to-edge with bottom navigation bar, single top AppBar, and 2×2 metric KPI grid.

6. **Mandatory Indian Date Format (`DD-MM-YYYY`):**
   - **All dates displayed in UI, printed prescriptions, reports, changelogs (`CHANGELOG.md`, `docs/archive/CHANGELOG_ARCHIVE.md`), and markdown documentation MUST strictly use Indian numerical date formatting (`DD-MM-YYYY` or `DD-MM-YY`).**
   - Never use `YYYY-MM-DD` or `MM/DD/YYYY` in human-facing text, changelogs, release notes, or markdown documentation.
   - Internal database storage and query tokens continue to use standard Firestore `Timestamp` or ISO-8601 strings, but any date presented to humans, doctors, patients, receptionists, or written in markdown files must strictly be formatted as `DD-MM-YYYY`.

7. **Doctor-Paced Chamber Handshake Protocol (Zero Forced Admission & Zero Data Loss):**
   - The chamber real-time sync channel (`counters/chamber_{doctorId}_{yyyy-MM-dd}`) strictly enforces a 5-state synchronized lifecycle:
     1. **Doctor Breather (`consultation_ended`):** When doctor completes an encounter ("Complete & Sign"), the consultation concludes, the encounter screen closes, and the chamber enters `consultation_ended` (Breather).
     2. **Reception Locked During Breather:** Reception desk displays `"Doctor on Break (Waiting for Doctor)"` with the dispatch button **strictly disabled** (`onDispatch = null`). Reception can verify arrival and payment for the next patient in line, but **MUST NOT and CANNOT send anyone inside**.
     3. **Doctor Signals Readiness (`ready_for_next`):** Once ready, the doctor hits the `"Next Patient"` button in `DoctorChamberScreen`. This transitions the chamber to `ready_for_next`.
     4. **Reception Dispatches Next Patient (`calling`):** The reception button unlocks to `"SEND IN TO DOCTOR"`. Reception clicking "Send In" dispatches the verified patient into the chamber (`calling`).
     5. **Auto-Load & Active Consultation (`in_consultation`):** Doctor chamber screen receives the calling event and auto-loads the consultation encounter screen, moving status to `in_consultation`. Reception dispatch immediately re-locks to `"Chamber Occupied (Token #N Inside)"` (`onDispatch = null`).
   - **Zero Pre-Emption Guarantee:** Reception cannot force or call a patient into the chamber during an active consultation or breather. A doctor typing an encounter can NEVER have another patient forced into their chamber, eliminating all possibility of unsaved data loss or consultation collisions.

8. **Temporal Guarding & Read-Only Chamber Archive (Today-Only Live Operations):**
   - Live physical actions (starting chamber shifts, signaling ready for next, emergency door admissions) are strictly restricted to the current active calendar date (`today`).
   - Historical dates (past) switch Doctor Chamber to immutable read-only mode (`ChamberArchiveBanner`), suppressing live calling triggers and rendering unresolved tokens as `UNATTENDED / NO-SHOW`.

9. **Restricted Emergency Door Self-Call Guardrail:**
   - Any direct doctor door admission fallback (`ChamberDoorOverrideBar`) must strictly show ONLY the next 1–2 patients who are physically present in clinic (`waitingInLobby`) with confirmed payment/waiver (`PaymentType != unpaid`).
   - Remote reservations (`VisitStatus.booked`) and unpaid tokens (`PaymentType.unpaid`) must NEVER appear in emergency self-call lists.

10. **Zero Backward-Compatibility Debt (No Compatibility Shims):**
    - **Backward compatibility is NOT required in this codebase.**
    - Never write fallback bridges, legacy adapters, deprecated aliases, migration shims, or polyfill glue solely to maintain backward compatibility with obsolete schemas or retired APIs.
    - Clean, modern, unified domain code is always prioritized over legacy preservation.
    - If backward compatibility happens naturally without extra code or compromises, that is fine; if not, breaking clean is explicitly encouraged.
    - **MANDATORY:** Whenever a breaking change is introduced (schema mutation, model property shift, API signature rewrite), you MUST explicitly inform the Product Manager.

11. **Single-Occupant Chamber Integrity & Collision Lock (Atomic Occupancy):**
    - A consultation chamber is strictly single-occupant. At any given moment, exactly **zero or one** patient can be inside or actively called into a doctor's chamber.
    - **Zero Pre-emption:** An active patient ($T_N$) undergoing consultation can **never** be superseded, interrupted, or displaced by another token ($T_{N+1}$) from reception queue cards, accordion panels, or doctor door overrides.
    - `ConsultationEncounterScreen` must NEVER contain incoming patient switch alerts or route replacements. When an encounter is open, the doctor is in exclusive session with that patient until completion.
    - Emergency door admission lists (`ChamberDoorOverrideBar`) and reception dispatch actions (`AccordionDispatchSection`, `DashboardQueueCard`) are strictly locked whenever a chamber is occupied.

---

## 🏗️ 2. Architectural & Technical Stack Rules

| Layer | Standard | Rule |
|---|---|---|
| **Framework** | Flutter 3.x (Web, Android) | Responsive codebase. Target web counter PC first. No iOS platform project is currently checked in. |
| **Domain Engines** | Pure Dart (`lib/core/engines/`) | **Zero Flutter UI dependencies.** Screens and widgets are Flutter presentation components; revenue math, eligibility rules, queue partitioning, and pharmacological defaults belong in dedicated engines. |
| **State Management** | **Provider** (`ChangeNotifierProvider`) | **Strictly Provider only.** Do NOT introduce Riverpod, Bloc, MobX, GetX, or ad-hoc global state. |
| **Backend & DB** | Cloud Firestore | Follow [SCHEMA_AND_MODELS.md](docs/SCHEMA_AND_MODELS.md). Never invent arbitrary field names. |
| **Idempotency** | Deterministic IDs (`med_*`, `counters/*`) | Default OPD medicines must use canonical IDs. Queue counters use daily atomic keys. |
| **Auth & Security** | 3-Tier Role Guarding | Clinic Owner PIN (6 digits, master admin/fees), Doctor PIN (4 digits, chamber operations), Reception PIN (`0000`, counter booking/queue). Never bypass role guards. |
| **Printing** | `platform_print.dart` | High-contrast monochrome A4/A5 letterhead printing via web `dart:js_interop` & desktop stubs. |

---

## 📋 3. Strict PM Interaction Protocol (How You Must Operate)

You are being managed by a strict Product Manager. Follow this exact workflow:

### Step 1: Clarify & Plan First (Never jump straight to mass edits)
- When given a feature request, provide:
  1. **User Flow & Acceptance Criteria**
  2. **Affected Files & Architecture Touchpoints**
  3. **Database Impact** (Are any Firestore schemas changing? If yes, provide the exact schema diff).
- Wait for PM approval before executing large or multi-file changes.

### Step 2: Respect Existing Conventions
- **Naming Casing:** Firestore field names use `camelCase` (e.g., `patientPhone`, `scheduledDate`, `amountCollected`).
- **Date Storage:** Follow the storage type documented for each field in `docs/SCHEMA_AND_MODELS.md`; for example, `lastVisitDate` is an optional ISO-8601 string while appointment and consultation event dates are `Timestamp` values.
- **Enums:** Store enum values using `enum.name` strings (e.g., `'pending'`, `'completed'`, `'absent'`), never integer indices.

### Step 3: Verification Gate
- After making changes, always ensure:
  - Code compiles cleanly with `flutter analyze` (Zero errors, zero warnings).
  - All automated unit tests pass with `flutter test` (sub-second execution across pure domain engines and models).
  - No broken imports or deprecated Flutter APIs introduced.

### Step 4: Code Review Guardrails for Chamber & Encounter Integrity
When reviewing or authoring any code that touches queue, chamber, or encounters, you MUST verify:
1. **Zero Pre-emption:** Can token $T_{N+1}$ displace token $T_N$? (Must be impossible in UI, service, and Firestore transaction).
2. **Atomic Occupancy:** Does `callTokenIntoChamber` verify that the chamber is empty before assigning a new token?
3. **Modal Lock:** Does the chamber screen protect against concurrent or re-entrant navigation (`_isConsultationOpen`)?
4. **Door Override Lockout:** Are direct doctor door admissions disabled when a patient is already in the chamber or being called?
5. **Multi-Doctor Queue Partitioning:** When viewing all doctors, are in-chamber patients across all practitioners segregated from lobby waiting lists?

---

## 📂 4. Project Directory Map

```
.agents/
├── rules/        -> AI workspace rules (clinic_os_rules.md)
└── recipes/      -> Change checklists (add_clinical_field.md, modify_booking_rule.md)
lib/
├── core/         -> Pure domain engines (appointment_engine, cash_handover_engine, medicine_engine, revenue_engine, whatsapp_engine)
├── models/       -> Pure data models (Appointment, Consultation, Patient, Doctor, Medicine, Vitals, ChamberSession, PrescriptionTemplate, UserRole)
├── providers/    -> App state (AuthProvider for PIN sessions, ClinicProvider for live streams)
├── services/     -> Modular Firestore service layer (FirestorePaths, booking, consultation, chamber, catalogue, doctor, patient, sound_service, offline_queue_cache)
├── screens/      -> UI Screens (Dashboard, ConsultationEncounter, DoctorChamber, PrescriptionPrint, etc.)
├── widgets/      -> Reusable UI sub-packages (booking, catalogue, chamber, common, dashboard, encounter, print, queue)
└── utils/        -> Helpers (Default medicines, app constants, platform print, platform sound, formatters)
test/             -> Automated test suite (234 automated unit and widget tests covering engines, flows, models, and platform services)
docs/
├── SCHEMA_AND_MODELS.md  -> Single source of truth for Firestore collections & models
├── PRODUCT_ROADMAP.md    -> Single source of truth for feature state, backlog, and architecture
├── COMPLIANCE_AND_PRIVACY.md -> Clinical data handling & privacy standards
└── archive/              -> Historical reference archives (never use for active invariants)
```

---

## 🛑 5. Codebase Red Lines (Instant Failure Conditions)

- ❌ **Deleting an appointment document from Firestore.** (Must use `AppointmentStatus.absent`).
- ❌ **Changing state management library.** (Always use `Provider`).
- ❌ **Adding unapproved Firestore fields without updating `docs/SCHEMA_AND_MODELS.md`.**
- ❌ **Hardcoding doctor fees or bypassing doctor-configured free review logic (0 to 30 days).**
- ❌ **Adding backward-compatibility bloatware, legacy polyfills, or adapter shims instead of writing clean modern domain code.**
- ❌ **Introducing breaking changes without explicitly informing the Product Manager.**
- ❌ **Putting financial math, review eligibility calculations, or pharmacological defaults directly inside UI widget `build()` methods.**
- ❌ **Breaking responsive layout or introducing max-width bottlenecks** (e.g. hard-capping desktop screens at 1400px leaving large side margins, wasting vertical space with duplicate headers on 1366x768 laptops, or introducing stacked duplicate AppBars inside `OwnerShell`).
- ❌ **Using non-Indian date formats (e.g. `YYYY-MM-DD` or `MM/DD/YYYY`) in UI, printed prescriptions, changelogs, release notes, or any markdown documentation.** (Must strictly use `DD-MM-YYYY` or `DD-MM-YY`).
- ❌ **Bypassing 3-tier role authorization or exposing owner settings (doctor CRUD, fee configuration) to reception or chamber PIN sessions.**
- ❌ **Forcing patient chamber admission during an active consultation or doctor breather (`consultation_ended`) without explicit `ready_for_next` handshake.**
- ❌ **Allowing chamber collisions or pre-empting an active token in chamber.** (Never allow Token $N+1$ to be called or admitted into a chamber that is actively `calling` or `in_consultation` with Token $N$).
- ❌ **Stacking duplicate or secondary consultation encounter screens over an in-progress consultation.**
- ❌ **Allowing live admissions, ready signals, or chamber operations on past historical dates.** (Must switch to immutable read-only mode).
- ❌ **Exposing remote reservations (`VisitStatus.booked`) or uncollected dues (`PaymentType.unpaid`) in emergency door self-call lists.** (Strictly capped to top 1–2 verified lobby-checked-in patients).

