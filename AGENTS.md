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

---

## 🏗️ 2. Architectural & Technical Stack Rules

| Layer | Standard | Rule |
|---|---|---|
| **Framework** | Flutter 3.x (Web, Android, iOS) | Single responsive codebase. Target web counter PC first. |
| **State Management** | **Provider** (`ChangeNotifierProvider`) | **Strictly Provider only.** Do NOT introduce Riverpod, Bloc, MobX, GetX, or ad-hoc global state. |
| **Backend & DB** | Cloud Firestore | Follow [SCHEMA_AND_MODELS.md](file:///d:/Android/guwahatione-clinic-os/docs/SCHEMA_AND_MODELS.md). Never invent arbitrary field names. |
| **Idempotency** | Deterministic IDs (`med_*`, `counters/*`) | Default OPD medicines must use canonical IDs. Queue counters use daily atomic keys. |
| **Auth & Security** | Role-based PINs | Reception PIN (`0000`), Doctor PIN (4 digits). Never bypass role guards. |
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
- **Date Storage:** Dates in Firestore must be `Timestamp` objects (with fallback parse for ISO-8601 strings in Dart models).
- **Enums:** Store enum values using `enum.name` strings (e.g., `'pending'`, `'completed'`, `'absent'`), never integer indices.

### Step 3: Verification Gate
- After making changes, always ensure:
  - Code compiles cleanly with `flutter analyze` (Zero errors, zero warnings).
  - Existing models and tests in `test/` continue to pass.
  - No broken imports or deprecated Flutter APIs introduced.

---

## 📂 4. Project Directory Map

```
lib/
├── models/       -> Pure data models & serialization (Appointment, Consultation, Patient, Doctor, Medicine, Vitals)
├── providers/    -> App state (AuthProvider for PIN sessions, ClinicProvider for live streams)
├── services/     -> Firebase Firestore client service layer (FirebaseService)
├── screens/      -> UI Screens (Dashboard, ConsultationEncounter, DoctorChamber, PrescriptionPrint, etc.)
└── utils/        -> Helpers (Default medicines, search scorer, constants, platform print)
docs/
├── SCHEMA_AND_MODELS.md  -> Master data dictionary for Firestore collections & models
├── PRODUCT_ROADMAP.md    -> Current feature state, backlog, and scope boundaries
└── PM_OPERATING_PLAYBOOK.md -> Strict PM prompt templates & operational guide
```

---

## 🛑 5. Codebase Red Lines (Instant Failure Conditions)

- ❌ **Deleting an appointment document from Firestore.** (Must use `AppointmentStatus.absent`).
- ❌ **Changing state management library.** (Always use `Provider`).
- ❌ **Adding unapproved Firestore fields without updating `docs/SCHEMA_AND_MODELS.md`.**
- ❌ **Hardcoding doctor fees or bypassing 14-day free review logic.**
- ❌ **Breaking responsive layout** on standard reception counter monitors (1366x768 / 1920x1080) or doctor mobile screens.
