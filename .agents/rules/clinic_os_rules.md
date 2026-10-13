# Clinic OS Workspace Rules

The root [`AGENTS.md`](../../AGENTS.md) is the canonical source for product invariants, architecture, database contracts, and verification requirements. Read it before changing code; do not duplicate or override its rules here.

For repository changes, run `flutter analyze` and `flutter test`. Keep changes within the clinical workflow and product boundaries in `AGENTS.md`. Always enforce Indian date format (`DD-MM-YYYY`) across all UI text, printed prescriptions, changelogs, and markdown documentation. Enforce Single-Occupant Chamber Integrity (zero pre-emption of active tokens). Backward compatibility is NOT required (never add shims or legacy glue); always inform the PM if a breaking change is introduced.
