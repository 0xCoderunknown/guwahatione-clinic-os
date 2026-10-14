# 📋 Recipe: Adding a Dashboard Metric / KPI Card

Follow this checklist whenever adding or updating an operational or financial KPI (e.g., patient counts, collections, active chambers, token averages) on reception or owner dashboards.

---

### Invariant Checks (Red Lines)
- ❌ **NEVER calculate financial math or revenue aggregations inside Flutter `build()` methods.** (Always use pure domain engines).
- ❌ **NEVER include unpaid tokens or uncollected dues in actual revenue KPI totals.**
- ❌ **NEVER bypass Indian currency formatting.** (Always format through `AppFormatters.currency(amount)`).

---

### Step 1: Implement Engine Math (`lib/core/engines/revenue_engine.dart` or `appointment_engine.dart`)
1. Add a pure static computation method (zero Flutter imports).
2. Write/update unit test in `test/revenue_engine_test.dart` or `test/reception_metrics_and_token_cap_test.dart` verifying edge cases (zero appointments, absent tokens, UPI vs Cash split).

---

### Step 2: Wire State / Aggregation (`lib/providers/clinic_provider.dart`)
1. If the KPI requires live stream computation:
   - Compute the metric getter using the pure engine method over `_todayAppointments`.
   - Ensure the getter is defensive against empty lists or uninitialized states.

---

### Step 3: Render Presentation Strip / Card (`lib/widgets/dashboard/`)
1. If adding to the top KPI row: Update `DashboardKpiStrip` (`lib/widgets/dashboard/dashboard_kpi_strip.dart`).
2. Maintain responsive grid sizing:
   - Mobile: 2×2 metric grid (`crossAxisCount: 2`).
   - Desktop: Side-by-side flex strip without overflowing usable vertical height on 1366×768 laptops.
3. Use semantic icons and consistent color coding:
   - Green: Collected Cash/UPI
   - Blue/Indigo: Checked-in / Active Lobby Tokens
   - Teal: Consulted / Completed Encounters
   - Amber/Red: Absent, Unpaid, or Pending Breathers
