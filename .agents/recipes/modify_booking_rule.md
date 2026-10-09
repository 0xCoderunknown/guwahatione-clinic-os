# 📋 Recipe: Modifying Appointment & Booking Rules

Follow this checklist whenever modifying queue logic, 14-day free review policies, fee calculations, or booking constraints.

---

### Invariant Checks (Red Lines)
- ❌ **NEVER delete an appointment document from Firestore.** (Always set `AppointmentStatus.absent` with `amountCollected: 0`).
- ❌ **NEVER allocate queue numbers in client state.** (Always use atomic transaction via `BookingService.bookAppointment`).
- ❌ **NEVER place financial math or fee eligibility directly in Flutter `build()` methods.**

---

### Step 1: Update Domain Engine (`lib/core/engines/`)
1. Implement logic inside `AppointmentEngine` (`lib/core/engines/appointment_engine.dart`) or `RevenueEngine` (`lib/core/engines/revenue_engine.dart`).
2. Keep engines 100% pure Dart — zero Flutter widget dependencies.

---

### Step 2: Add or Update Unit Tests (`test/widget_test.dart`)
1. Add boundary tests (e.g. Day 0, Day 14, Day 15, different doctor, absent visits).
2. Run test to verify:
   ```bash
   flutter test test/widget_test.dart
   ```

---

### Step 3: Wire Service & State (`lib/services/` & `lib/providers/`)
1. If modifying database transaction: Update `BookingService.bookAppointment` (`lib/services/booking_service.dart`).
2. If updating provider state: Update `ClinicProvider` (`lib/providers/clinic_provider.dart`).

---

### Step 4: Verification Gate
Run:
```bash
flutter analyze
flutter test
```
All tests must pass cleanly.
