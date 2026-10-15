# Architecture Decision Record 002: Prescription Snapshot & Immutable Prescribing Record

## Context & Problem Statement
In outpatient clinic operations, prescriptions and consultations are permanent medical and medico-legal records. A doctor prescribes a medicine based on its name, generic composition, strength, form, and manufacturer at that exact point in time.

If a prescription item only stores a foreign-key reference (`medicineId`) and dereferences catalogue details on load, or omits key manufacturing/form/strength metadata:
1. Editing a drug in `Catalogue / Formulary` (e.g. changing strength from 500mg to 650mg, changing manufacturer from GlaxoSmithKline to Sun Pharma, or correcting a typographical error) would retroactively and corruptively mutate past consultation records and printed artifacts.
2. Merging or purging (deleting) a discontinued drug from the clinic formulary would cause past consultations to crash, display missing information, or render blank entries upon reopening or reprinting.

## Options Considered

### Option 1: Foreign Key with Dynamic Catalogue Joins
Prescription items store only `medicineId` and pull current medicine details dynamically from `medicines/{id}` at view/print time.
- **Pros:** Saves minor JSON payload space in consultation documents.
- **Cons:** Fatal clinical flaw. Violates the append-only, immutable medical ledger invariant. Purging or editing a medicine alters or breaks historic prescriptions. Medico-legally indefensible.

### Option 2: Full Immutable Point-in-Time Snapshot on `PrescriptionItem` (Chosen)
`PrescriptionItem` stores a complete, immutable snapshot of the medicine at prescribing time:
- `medicineName` (Trade / brand name, e.g. "Dolo 650")
- `composition` (Generic molecule, e.g. "Paracetamol")
- `strength` (Molecule strength, e.g. "650 mg")
- `form` (Dosage form, e.g. "Tablet", "Syrup", "Capsule", "Injection")
- `manufacturer` (Pharmaceutical company, e.g. "Micro Labs Ltd")
- Regimen fields: `dosage`, `frequency`, `timing`, `durationDays`, `instructions`
- Optional `medicineId` reference retained for historical tracing, but never used as a runtime dependency for rendering or printing.
- **Pros:** 100% resilient against catalogue edits, merges, or purges. Zero network joins required to view or print historical encounters. Conforms strictly to Invariant #2 (Append-only longitudinal records).
- **Cons:** Slightly larger consultation document size (negligible in Firestore, well within the 1 MB document limit).

## Decision Outcome
Adopt **Option 2**. Every prescription item created in `EncounterFormState`, `applyPrescriptionTemplate`, or custom prescribing workflows takes an immutable snapshot of `name`, `composition`, `strength`, `form`, and `manufacturer`. 

The print engine and consultation viewer render exclusively from this snapshot. Any subsequent modification, renaming, or complete deletion of the medicine from the `medicines` collection has zero effect on saved consultation records or reprint fidelity.

## Migration & Rollback Plan
- Stale data is being purged per PM instruction. New records will write all snapshot fields.
- Fallback read path in `PrescriptionItem.fromJson`: If `strength`, `form`, or `manufacturer` are absent in older JSON, fallback gracefully to `composition` parsing or safe nulls without throwing errors.
