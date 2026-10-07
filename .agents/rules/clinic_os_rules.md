# Clinic OS Workspace Rules

1. **Strict Zero Deletions**: Never propose or implement `delete()` calls on the `appointments` collection. Always use `AppointmentStatus.absent` with `amountCollected: 0`.
2. **Provider State Management**: Always use `Provider` and `ClinicProvider`/`AuthProvider`. Never introduce another state management library.
3. **Database Casing**: All Firestore map keys must strictly follow camelCase as defined in `docs/SCHEMA_AND_MODELS.md`.
4. **Append-Only Consultations**: Follow-up consultations must append new documents; never overwrite past records.
5. **No Pharmacy ERP**: Respect anti-goals in `docs/PRODUCT_ROADMAP.md`.
