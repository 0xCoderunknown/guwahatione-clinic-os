# Clinic OS Workspace Rules

The root [`AGENTS.md`](../../AGENTS.md) is the canonical source for product invariants, architecture, database contracts, and verification requirements. Read it before changing code; do not duplicate or override its rules here.

For repository changes, run `flutter analyze`. Do not run `flutter test` unless the PM explicitly changes the current test prohibition. Keep changes within the clinical workflow and product boundaries in `AGENTS.md`.
