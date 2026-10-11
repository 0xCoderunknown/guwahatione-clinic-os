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

3. **Strict 5-Step Clinical Encounter Pipeline:**
   Every consultation flow must strictly adhere to the 5 clinical stages in `ConsultationEncounterScreen`:
   - **Step 1:** Patient Header & Allergies Alert Banner
   - **Step 2:** Vitals & Clinical Examination (Chief complaints & provisional diagnosis)
   - **Step 3:** Diagnostic Investigations Review (Past lab reports & values)
   - **Step 4:** Medication Reconciliation & Prescribing (`START` / `CONTINUE` / `STOP`)
   - **Step 5:** Diagnostic Orders & Follow-Up Advice

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

7. **Doctor-Paced Chamber Handshake Protocol (Zero Forced Admission):**
   - The chamber real-time sync channel (`counters/chamber_{doctorId}_{yyyy-MM-dd}`) follows a strict 5-state lifecycle: `idle` ➔ `ready_for_next` ➔ `calling` ➔ `in_consultation` ➔ `consultation_ended`.
   - When a physician completes an encounter, the session enters `consultation_ended` (Breather).
   - Reception cannot force a patient into the chamber during a consultation or breather without explicit doctor readiness (`ready_for_next`), preventing physician burn-out and consultation collisions.

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

---

## 📂 4. Project Directory Map

```
.agents/
├── rules/        -> AI workspace rules (clinic_os_rules.md)
└── recipes/      -> Change checklists (add_clinical_field.md, modify_booking_rule.md)
lib/
├── core/         -> Pure domain engines (revenue_engine, appointment_engine, medicine_engine)
├── models/       -> Pure data models (Appointment, Consultation, Patient, Doctor, Medicine, Vitals, ChamberSession, UserRole)
├── providers/    -> App state (AuthProvider for PIN sessions, ClinicProvider for live streams)
├── services/     -> Modular Firestore service layer (FirestorePaths, booking, consultation, chamber, catalogue, doctor, patient)
├── screens/      -> UI Screens (Dashboard, ConsultationEncounter, DoctorChamber, PrescriptionPrint, etc.)
├── widgets/      -> Reusable UI sub-packages (auth, booking, catalogue, chamber, common, dashboard, encounter, print, queue)
└── utils/        -> Helpers (Default medicines, app constants, platform print, formatters)
test/             -> Automated test suite (80+ unit and widget tests covering engines, flows, and models)
docs/
├── SCHEMA_AND_MODELS.md  -> Master data dictionary for Firestore collections & models
├── PRODUCT_VISION_AND_WORKFLOW.md -> Clinical encounter blueprint & real-world OPD intent
└── PRODUCT_ROADMAP.md    -> Current feature state, backlog, and scope boundaries
```

---

## 🛑 5. Codebase Red Lines (Instant Failure Conditions)

- ❌ **Deleting an appointment document from Firestore.** (Must use `AppointmentStatus.absent`).
- ❌ **Changing state management library.** (Always use `Provider`).
- ❌ **Adding unapproved Firestore fields without updating `docs/SCHEMA_AND_MODELS.md`.**
- ❌ **Hardcoding doctor fees or bypassing 14-day free review logic.**
- ❌ **Putting financial math, review eligibility calculations, or pharmacological defaults directly inside UI widget `build()` methods.**
- ❌ **Breaking responsive layout or introducing max-width bottlenecks** (e.g. hard-capping desktop screens at 1400px leaving large side margins, wasting vertical space with duplicate headers on 1366x768 laptops, or introducing stacked duplicate AppBars inside `OwnerShell`).
- ❌ **Using non-Indian date formats (e.g. `YYYY-MM-DD` or `MM/DD/YYYY`) in UI, printed prescriptions, changelogs, release notes, or any markdown documentation.** (Must strictly use `DD-MM-YYYY` or `DD-MM-YY`).
- ❌ **Bypassing 3-tier role authorization or exposing owner settings (doctor CRUD, fee configuration) to reception or chamber PIN sessions.**
- ❌ **Forcing patient chamber admission during an active consultation or doctor breather (`consultation_ended`) without explicit `ready_for_next` handshake.**
