# 📋 Recipe: Adding a Clinic Setting or Feature Flag

Follow this checklist whenever adding a new feature flag (🧪 experiment) or system setting (role-guarded owner toggle, printing default, sound preference).

---

### Invariant Checks (Red Lines)
- ❌ **NEVER expose clinic configuration or fee settings to reception or doctor PIN roles.** (Owner role only).
- ❌ **NEVER hardcode experimental feature flags inside UI widgets.** (Always centralize in `ClinicFeatureFlags`).
- ❌ **NEVER add backward-compatibility adapter glue for scrapped features.** (Follow Invariant #10).

---

### Step 1: Update Feature Flag Configuration (`lib/config/clinic_config.dart`)
1. Add the boolean or configuration property to `ClinicFeatureFlags`:
   - Default experimental features to `false` until formally promoted.
   - Document the flag purpose and experiment horizon in `ClinicFeatureFlags` docstring.
2. If the feature requires persistent toggle across app sessions, wire into local cache (`SharedPreferences`).

---

### Step 2: Document in Product Governance (`docs/MASTER_BACKLOG.md`)
1. If experimental, register under **Section 5 (🧪 Experiment Flag Registry)**:
   - Feature name
   - Status (e.g. `📋 TODO · 🧪 Experiment`)
   - Flag reason
   - Promotion / Graduation criteria
2. Document architectural boundaries in `docs/SCHEMA_AND_MODELS.md` Section 10.E.

---

### Step 3: Guard in UI & Business Logic
1. Access flag cleanly via `ClinicFeatureFlags.current.[flagName]` or `ClinicConfig.current.features.[flagName]`.
2. Ensure disabling the flag completely hides or bypasses the feature with zero regressions on core appointment/queue flows.
