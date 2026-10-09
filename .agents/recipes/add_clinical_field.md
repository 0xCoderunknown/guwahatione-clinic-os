# 📋 Recipe: Adding a Clinical Field to Encounter & Consultation

Follow this checklist whenever adding a new clinical field (e.g., examination observation, vitals parameter, diagnostic metric) to ensure zero data regressions and zero missing schema touchpoints.

---

### Step 1: Update Domain Model (`lib/models/`)
1. Add the field with proper nullability to the appropriate model (e.g., `Consultation`, `Vitals`, `Patient`).
2. Update `toJson()`:
   - For `DateTime`: Store as `Timestamp.fromDate(...)` (if event timestamp) or ISO-8601 string (if patient profile date).
   - For enums: Store as `enum.name` string.
3. Update `fromJson()`:
   - Add defensive parsing (accept both native type, Timestamp, or fallback).
4. Update unit test in `test/consultation_test.dart` to verify serialization round-trip.

---

### Step 2: Document Schema Contract (`docs/SCHEMA_AND_MODELS.md`)
1. Add the new field to the schema table for the collection.
2. Specify: Field name (camelCase), Type, Required/Optional, and Clinical Description.

---

### Step 3: Wire Form State & Clinical UI (`lib/widgets/encounter/`)
1. If the field is editable in encounter:
   - Add controller/state to `EncounterFormState` (`lib/widgets/encounter/encounter_form_state.dart`).
   - Add controller disposal in `EncounterFormState.dispose()`.
   - Add mapped field in `buildConsultation()` or `buildVitals()`.
2. Add input widget to the appropriate encounter section:
   - Step 1: `PatientHeaderSection`
   - Step 2: `VitalsAndExamSection`
   - Step 3: `DiagnosticReviewSection`
   - Step 4: `RxReconciliationSection`
   - Step 5: `AdviceAndOrdersSection`

---

### Step 4: Update Print Output (`lib/widgets/print/`)
1. If the clinical field belongs on the printed prescription:
   - Add the rendering block in `PrintClinicalSnapshot` or `PrintOrdersAndFooter`.
   - Ensure null-safe fallback (does not render blank space if field is null or empty).

---

### Step 5: Verification Gate
Run:
```bash
flutter analyze
flutter test test/consultation_test.dart
```
Both must pass with zero errors.
