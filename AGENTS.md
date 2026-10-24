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

2. **Longitudinal Append-Only Clinical Records & Encounter Architecture:**
   - Prescriptions and consultations are **append-only** clinical events (`consultations` collection).
   - Past consultations are never overwritten or edited on follow-up visits.
   - Subsequent encounters record medication reconciliation states: `START` (new therapy), `CONTINUE` (reconciled chronic regimen), or `STOP` (explicit discontinuation with `stopReason`).
   - The printed prescription is a transient output; the append-only clinical history across visits is the core product.
   - Encounters are structured around familiar Indian MBBS/MD clinical workflows:
     - **Header & Passive Allergy Alert:** Patient demographics with passive free-text allergy chip.
     - **Clinical Observations:** Compact vitals grid + MBBS standard notes (`C/O` Chief Complaints, `O/E` On Examination, `Dx`/`P/D` Provisional Diagnosis).
     - **Past History & 1-Click Carry Forward:** Prior visits viewable read-only; single `[CARRY FORWARD]` button copies prior chronic regimens into active prescription as `CONTINUE` items.
     - **Medication Reconciliation & Prescribing:** Unified brand/composition search, pre-filled clinical defaults, rapid frequency chips (`1-0-1`, `1-0-0`, `0-0-1`, `1-1-1`, `SOS`), and timing chips (`After Food / PC`, `Before Food / Khali Pet / AC`).
     - **Diagnostic Orders & Follow-Up Advice:** Ordered lab tests, free-form remarks/diet instructions, and structured next review dropdown (`3 days`, `7 days`, `14 days`, `1 month`, `3 months`, `Not Needed`).
   - Clinical encounter sections are modular and collapsible. Doctors can record observations in any order without forced linear roadblocks.

3. **Doctor-Paced Chamber Handshake & Atomic Single Occupancy:**
   - The consultation chamber is strictly single-occupant. At any given moment, exactly **zero or one** patient can be inside or actively called into a doctor's chamber.
   - **Zero Pre-emption:** An active patient ($T_N$) undergoing consultation can **never** be superseded, interrupted, or displaced by another token ($T_{N+1}$) from reception queue cards, accordion panels, or doctor door overrides.
   - The chamber real-time sync channel (`counters/chamber_{doctorId}_{yyyy-MM-dd}`) strictly enforces a 5-state synchronized lifecycle:
     1. **Doctor Breather (`consultation_ended`):** When doctor completes an encounter ("Complete & Sign"), the consultation concludes, the encounter screen closes, and the chamber enters `consultation_ended` (Breather).
     2. **Reception Locked During Breather:** Reception desk displays `"Doctor on Break (Waiting for Doctor)"` with the dispatch button **strictly disabled** (`onDispatch = null`). Reception can verify arrival and payment for the next patient in line, but **MUST NOT and CANNOT send anyone inside**.
     3. **Doctor Signals Readiness (`ready_for_next`):** Once ready, the doctor hits the `"Next Patient"` button in `DoctorChamberScreen`. This transitions the chamber to `ready_for_next`.
     4. **Reception Dispatches Next Patient (`calling`):** The reception button unlocks to `"SEND IN TO DOCTOR"`. Reception clicking "Send In" dispatches the verified patient into the chamber (`calling`).
     5. **Auto-Load & Active Consultation (`in_consultation`):** Doctor chamber screen receives the calling event and auto-loads the consultation encounter screen, moving status to `in_consultation`. Reception dispatch immediately re-locks to `"Chamber Occupied (Token #N Inside)"` (`onDispatch = null`).
   - **Emergency Door Self-Call Guardrail:** Any direct doctor door admission fallback (`ChamberDoorOverrideBar`) must strictly show ONLY the next 1–2 patients who are physically present in clinic (`waitingInLobby`) with confirmed payment/waiver (`PaymentType != unpaid`). Remote reservations (`VisitStatus.booked`) and unpaid tokens (`PaymentType.unpaid`) must NEVER appear in emergency self-call lists.

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
   - **All dates displayed in UI, printed prescriptions, reports, changelogs (`CHANGELOG.md`), and markdown documentation MUST strictly use Indian numerical date formatting (`DD-MM-YYYY` or `DD-MM-YY`).**
   - Never use `YYYY-MM-DD` or `MM/DD/YYYY` in human-facing text, changelogs, release notes, or markdown documentation.
   - Internal database storage and query tokens continue to use standard Firestore `Timestamp` or date keys, but any date presented to humans or written in markdown files must strictly be formatted as `DD-MM-YYYY`.

7. **Temporal Guarding & Read-Only Chamber Archive (Today-Only Live Operations):**
   - Live physical actions (starting chamber shifts, signaling ready for next, emergency door admissions) are strictly restricted to the current active calendar date (`today`).
   - Historical dates (past) switch Doctor Chamber to immutable read-only mode (`ChamberArchiveBanner`), suppressing live calling triggers and rendering unresolved tokens as `UNATTENDED / NO-SHOW`.

8. **Prescription Table Architecture (Strict 3-Column Isolation & NMC Generic Standard):**
   - The printed and preview prescription table must strictly maintain 3 separated, unmixed columns:
     - **Column 1 (Medicine):** Dedicated purely to medicine trade brand name and generic chemical composition in uppercase brackets (`Brand [COMPOSITION]`, e.g., `Telma 40 tablet [TELMISARTAN 40MG]`, conforming to National Medical Commission uppercase prescribing standards). When the experimental flag `hidePrescriptionComposition` is enabled, only the trade brand name is rendered (`Telma 40 tablet`). Never add badges like `[NEW]` or mix dosage/timing/duration into this column.
     - **Column 2 (Dosage & Timing):** Dedicated purely to dosage instructions, frequency, timing, and optional notes (e.g., `1 tab • in morning • before food`). Never mix medicine name or course duration into this column.
     - **Column 3 (Duration / Status):** Dedicated purely to course duration or continuation/discontinuation status (`To Continue`, `X Days`, or `To STOP`).
   - **Zero Mixing:** There must be zero mixing between these 3 columns across printed prescriptions or preview tables.

9. **Pre-2.0 Active Development Phase & Zero Backward-Compatibility Debt:**
   - **Active Development Phase Until Version 2.0:** You are explicitly allowed to break schemas, data models, internal APIs, and component structures until version 2.0 is reached. Post-2.0, strict schema immutability, data migrations, and stability rules will apply.
   - **Zero Legacy Polyfills:** Never write fallback bridges, legacy adapters, deprecated aliases, migration shims, or polyfill glue solely to maintain backward compatibility with obsolete schemas or retired APIs.
   - Clean, modern, unified domain code is always prioritized over legacy preservation.
   - **MANDATORY:** Whenever a breaking change is introduced (schema mutation, model property shift, API signature rewrite), you MUST explicitly inform the Product Manager.

10. **Documentation Separation of Concerns:**
    - **`README.md`:** The user-facing and architectural guide. Documents what the product does, live clinical workflows, domain engine capabilities, system setup, and responsive layout standards.
    - **`CHANGELOG.md`:** The historical release ledger. Chronological record of shipped features and fixes. When advancing minor series, consolidate patch releases (`[1.5.0 – 1.5.5]`). Never include internal verification gates or terminal test outputs in this file.
    - **`docs/MASTER_BACKLOG.md`:** The true backlog and future roadmap. Strictly contains unbuilt, pending, or prioritized work (`TODO`, `Backlog`, `Deferred`, `Anti-Goals`). **Never** store solved tickets or resolved historical audit findings here.

---

## 🏗️ 2. Architectural & Technical Stack Rules

| Layer | Standard | Rule |
|---|---|---|
| **Framework** | Flutter 3.x (Web, Android) | Responsive codebase. Target web counter PC first. No iOS platform project is currently checked in. |
| **Domain Engines** | Pure Dart (`lib/core/engines/`) | **Zero Flutter UI dependencies.** Business logic, revenue math, eligibility rules, queue calculations, and printing HTML generation belong in dedicated pure engines (`AppointmentEngine`, `CashHandoverEngine`, `DataExportEngine`, `MedicineEngine`, `PatientSearchEngine`, `PrescriptionPrintEngine`, `RevenueEngine`, `WhatsAppEngine`). |
| **State Management** | **Provider** (`ChangeNotifierProvider`) | **Strictly Provider only.** Do NOT introduce Riverpod, Bloc, MobX, GetX, or ad-hoc global state. |
| **Backend & DB** | Cloud Firestore | Follow [SCHEMA_AND_MODELS.md](docs/SCHEMA_AND_MODELS.md). Never invent arbitrary field names. |
| **Idempotency** | Deterministic IDs (`med_*`, `counters/*`) | Default OPD medicines use canonical IDs. Queue counters use daily atomic keys. |
| **Auth & Security** | 3-Tier Role Guarding | Clinic Owner PIN (6 digits, master admin/fees), Doctor PIN (4 digits, chamber operations), Reception PIN (`0000`, counter booking/queue). Never bypass role guards. |
| **Printing Engine** | Pure Dart HTML + Iframe Bridge | `PrescriptionPrintEngine` generates semantic HTML; web iframe print bridge (`platform_print_web.dart`) avoids CanvasKit WebGL print spooling context drops for vector-crisp prints & PDFs. |

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
- **Date Storage:** Follow the storage type documented for each field in `docs/SCHEMA_AND_MODELS.md`; for example, appointment, consultation events, and `lastVisitDate` are stored as native Firestore `Timestamp` values.
- **Enums:** Store enum values using `enum.name` strings (e.g., `'pending'`, `'completed'`, `'absent'`), never integer indices.

### Step 3: Verification Gate
- After making changes, always ensure:
  - Code compiles cleanly with `flutter analyze` (Zero errors, zero warnings).
  - All automated unit tests pass with `flutter test` across pure domain engines, services, and models.
  - No broken imports or deprecated Flutter APIs introduced.

---

## 📂 4. Project Directory Map

```
.agents/
├── rules/        -> AI workspace rules (clinic_os_rules.md)
└── recipes/      -> Change checklists (add_clinical_field.md, modify_booking_rule.md)
lib/
├── config/       -> Tenant configuration, branding, and feature flags (clinic_config.dart)
├── core/engines/ -> Pure Dart domain engines (AppointmentEngine, CashHandoverEngine, DataExportEngine,
│                    MedicineEngine, PatientSearchEngine, PrescriptionPrintEngine, RevenueEngine, WhatsAppEngine)
├── models/       -> Pure data models (Appointment, Consultation, Patient, Doctor, Medicine, Vitals, ChamberSession, UserRole)
├── providers/    -> App state (AuthProvider, ClinicProvider facade, and delegates: DoctorState, LiveQueue, Catalogue)
├── services/     -> Modular Firestore service layer (FirestorePaths, booking, consultation, chamber, catalogue, doctor, patient, sound_service, offline_queue_cache)
├── screens/      -> UI Screens (Dashboard, ConsultationEncounter, DoctorChamber, OwnerShell, etc.)
├── widgets/      -> Reusable UI sub-packages (booking, catalogue, chamber, common, dashboard, doctor, encounter, patient, print, queue)
└── utils/        -> Helpers (Default medicines, app constants, platform print, platform sound, formatters)
test/             -> Automated test suite covering pure engines, models, providers, and integration flows
docs/
├── MASTER_BACKLOG.md     -> Active backlog and future roadmap (what remains to be built)
└── SCHEMA_AND_MODELS.md  -> Single source of truth for Firestore collections & models
```

---

## 🛑 5. Codebase Red Lines (Instant Failure Conditions)

### 🏥 Clinical Safety
- ❌ **Deleting an appointment document from Firestore.** (Must use `AppointmentStatus.absent` with ₹0 fee).
- ❌ **Overwriting or editing historical consultation records.** (Consultations and prescriptions are append-only forever).
- ❌ **Allowing chamber collisions or pre-empting an active token in chamber.** (Never allow Token $N+1$ to displace Token $N$ during active consultation or breather).
- ❌ **Stacking duplicate or secondary consultation encounter screens over an in-progress consultation.**
- ❌ **Allowing live admissions, ready signals, or chamber operations on past historical dates.** (Must switch to immutable read-only mode).
- ❌ **Exposing remote reservations (`VisitStatus.booked`) or uncollected dues (`PaymentType.unpaid`) in emergency door self-call lists.** (Strictly capped to top 1–2 verified lobby-checked-in patients).
- ❌ **Mixing medicine names, dosages, or durations across prescription table columns, or adding badges like `[NEW]`** (violating the strict 3-column isolation rule).

### 💰 Ledger & Financial Integrity
- ❌ **Hardcoding doctor fees or bypassing doctor-configured free review logic (0 to 30 days).**
- ❌ **Putting financial math, review eligibility calculations, or pharmacological defaults directly inside UI widget `build()` methods.**

### 🏛️ Architecture & State
- ❌ **Changing state management library.** (Strictly Provider only).
- ❌ **Adding unapproved Firestore fields without updating `docs/SCHEMA_AND_MODELS.md`.**
- ❌ **Adding backward-compatibility bloatware, legacy polyfills, or adapter shims instead of writing clean modern domain code.**
- ❌ **Introducing breaking changes without explicitly informing the Product Manager.**

### 🖥️ UI, Formatting & Documentation
- ❌ **Breaking responsive layout or introducing max-width bottlenecks** (e.g. hard-capping desktop screens at 1400px leaving large side margins, wasting vertical space with duplicate headers on 1366x768 laptops, or introducing stacked duplicate AppBars inside `OwnerShell`).
- ❌ **Using non-Indian date formats (e.g. `YYYY-MM-DD` or `MM/DD/YYYY`) in UI, printed prescriptions, changelogs, release notes, or any markdown documentation.** (Must strictly use `DD-MM-YYYY` or `DD-MM-YY`).
- ❌ **Bypassing 3-tier role authorization or exposing owner settings (doctor CRUD, fee configuration) to reception or chamber PIN sessions.**
- ❌ **Logging completed / solved items into `docs/MASTER_BACKLOG.md`.** (Backlog is strictly for unbuilt work).
