# 🎨 GuwahatiOne Clinic OS — UI Polish & Remediation Audit (POLISH.md)
*Date: 24-10-2026*  
*Scope: Code-level visual, responsive, affordance, and layout audit across all screens, dialogs, and components.*

---

## 📊 Executive Summary Matrix

| # | File / Component | Defect Type | Severity | Status |
|---|---|---|---|---|
| 1 | [`lib/widgets/patient/patient_lookup_card.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/patient/patient_lookup_card.dart) | Unbounded 85-char Text inside unconstrained `Row` | 🔴 Critical Overflow | Pending |
| 2 | [`lib/widgets/doctor/doctor_leave_calendar_section.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/doctor/doctor_leave_calendar_section.dart) | Rigid 520px header `Row` overflows on mobile (<500px) | 🔴 Critical Overflow | Pending |
| 3 | [`lib/widgets/common/daily_cash_handover_dialog.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/common/daily_cash_handover_dialog.dart) | 4 `Expanded` metric cards crushed horizontally on 360px mobile | 🔴 Layout Squish / Wrap | Pending |
| 4 | [`lib/screens/login_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/login_screen.dart) | Hardcoded `height: 310` TabBarView box trap with `Spacer` | 🔴 Height Trap Overflow | Pending |
| 5 | [`lib/widgets/dashboard/dashboard_doctor_roster_card.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_doctor_roster_card.dart) | `"▶ CALL NEXT"` rendered as button badge with no `onTap` | 🟠 Misleading Affordance | Pending |
| 6 | [`lib/widgets/dashboard/dashboard_queue_card.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_queue_card.dart) | `list.take(10)` silently truncates patients 11+ without indicator | 🟠 Operational Trap | Pending |
| 7 | [`lib/widgets/print/token_receipt_dialog.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/print/token_receipt_dialog.dart) | `printDocument()` called with null HTML (prints whole viewport) | 🟠 Broken Print Function | Pending |
| 8 | [`lib/widgets/common/owner_shell_app_bar.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/common/owner_shell_app_bar.dart) | Rigid horizontal actions (>950px) on laptop/split screens | 🟡 Responsive Collision | Pending |
| 9 | [`lib/widgets/dashboard/dashboard_doctor_roster_card.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_doctor_roster_card.dart) | Doctor Name + Chamber Status ellipsis crushed in `flex: 4` | 🟡 Responsive Collision | Pending |
| 10 | [`lib/widgets/encounter/staged_medicine_form.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/encounter/staged_medicine_form.dart) | 3 rigid dropdowns in single horizontal `Row` on mobile | 🟡 Form Usability | Pending |
| 11 | [`lib/widgets/dashboard/dashboard_queue_item_row.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_queue_item_row.dart) | Duplicate `AppointmentStatusChip` rendered in title and trailing | ⚪ Visual Duplication | Pending |
| 12 | [`lib/screens/doctor_list_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/doctor_list_screen.dart) | 1848px card stretch + unstyled raw days text in badge wrap | ⚪ Polish & Layout | Pending |
| 13 | [`lib/screens/statistics_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/statistics_screen.dart) | Duplicate Export CSV & stacked date selectors on mobile | ⚪ UI Redundancy | Pending |
| 14 | [`lib/screens/doctor_daily_details_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/doctor_daily_details_screen.dart) | Raw enum strings & unstyled colors bypassing chip system | ⚪ Design System Drift | Pending |
| 15 | [`lib/screens/medicine_catalogue_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/medicine_catalogue_screen.dart) | Missing mobile header + `shrinkWrap: true` performance trap | ⚪ Performance & Shell | Pending |

---

## 🚨 Category 1: Critical RenderFlex Overflows & Breakdowns

### 1. Guaranteed RenderFlex Overflow in Encounter History
- **File:** [`lib/widgets/patient/patient_lookup_card.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/patient/patient_lookup_card.dart) (Lines 242–259)
- **Code:**
  ```dart
  Row(
    children: [
      Icon(Icons.history_edu, size: 20, color: Colors.grey.shade400),
      const SizedBox(width: 8),
      Text(
        'No past clinical encounters recorded yet. Patient registered via counter check-in.',
        style: TextStyle(...),
      ),
    ],
  )
  ```
- **Issue:** Inside an unscrollable `Row`, an 85-character `Text` widget is placed without `Expanded` or `Flexible`. On mobile screens (390px–430px) or side split-panels, this causes an instant **~200px yellow/black hazard `RenderFlex overflow`**.
- **Fix:** Wrap `Text` with `Expanded`.

---

### 2. Leave Calendar Header Mobile Overflow
- **File:** [`lib/widgets/doctor/doctor_leave_calendar_section.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/doctor/doctor_leave_calendar_section.dart) (Lines 28–78)
- **Issue:** A rigid horizontal `Row` contains an Icon, a long title (`'Planned Leave & Blocked Dates'`), a `Spacer()`, and two `OutlinedButton.icon` buttons (`'Add Day'` and `'Add Week / Range'`).
- **Impact:** Requires a minimum width of ~520px. On mobile viewport (<500px), it causes an unhandled **~150px RenderFlex overflow**.
- **Fix:** Use `Wrap(spacing: 8, runSpacing: 8, ...)` or switch to a responsive layout checking `MediaQuery.sizeOf(context).width < 500`.

---

### 3. Cash Handover Summary Cards Squished to Oblivion on Mobile
- **File:** [`lib/widgets/common/daily_cash_handover_dialog.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/common/daily_cash_handover_dialog.dart) (Lines 138–176)
- **Code:**
  ```dart
  Row(
    children: [
      Expanded(child: _buildSummaryCard('Expected', ...)),
      const SizedBox(width: 8),
      Expanded(child: _buildSummaryCard('Collected', ...)),
      const SizedBox(width: 8),
      Expanded(child: _buildSummaryCard('Difference', ...)),
      const SizedBox(width: 8),
      Expanded(child: _buildSummaryCard('Patients', ...)),
    ],
  )
  ```
- **Issue:** On a mobile dialog (~360px usable width), packing 4 `Expanded` cards horizontally leaves ~80px per card. Each card contains an icon (18px) and horizontal padding (16px total) — leaving just **~46px** for label, currency symbols, and multi-digit rupee amounts (`₹12,450`), triggering vertical text clipping and overflows.
- **Fix:** Render as a 2×2 grid (`Wrap` or 2 rows of 2 cards each) when dialog width is below 550px.

---

### 4. Fixed Height `310px` TabBarView Box Trap in Login Screen
- **File:** [`lib/screens/login_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/login_screen.dart) (Lines 155–185)
- **Code:**
  ```dart
  SizedBox(
    height: 310,
    child: TabBarView(
      children: [
        _buildRoleTab('reception', ...),
        _buildRoleTab('doctor', ...),
        _buildRoleTab('owner', ...),
      ],
    ),
  )
  ```
- **Issue:** Each tab contains instruction text, a PIN form, an error slot, action buttons, and internal `const Spacer()` widgets. On devices with Android font-scaling enabled (1.15x+) or when test mode displays the role selector, 310px is exceeded, resulting in a bottom overflow error.
- **Fix:** Remove hardcoded height and `Spacer()`, allowing content to size naturally with a scrollable wrapper or flexible constraints.

---

## 🪤 Category 2: Broken Affordances & Operational Traps

### 5. `"▶ CALL NEXT"` Fake Clickable Button in Doctor Roster
- **File:** [`lib/widgets/dashboard/dashboard_doctor_roster_card.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_doctor_roster_card.dart) (Lines 280–326)
- **Code:**
  ```dart
  if (isDoctorReady)
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        border: Border.all(color: const Color(0xFF10B981)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('▶ CALL NEXT', style: TextStyle(...)),
    )
  ```
- **Issue:** Styled like an interactive pill button with a green action triangle, but it is a static `Container` with **zero `onTap`, no `InkWell`, and no button handler**. Receptionists click it expecting to send in the patient, but nothing happens.
- **Fix:** Either attach an `onTap` handler linking directly to dispatch/calling workflow, or style it purely as an informational status pill (e.g. `'DOCTOR WAITING'`).

---

### 6. The "Silent 10-Item Truncation Trap" in Live Queue
- **File:** [`lib/widgets/dashboard/dashboard_queue_card.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_queue_card.dart) (Lines 229–232)
- **Code:**
  ```dart
  itemCount: list.take(10).length,
  ```
- **Issue:** If a busy clinic has 25 patients registered today, the tab badge displays `'Today\'s Queue (25)'`, but the list view silently caps at `list.take(10)` with **no footer, no "View all 15 more in Queue Tab" link, and no scroll indicator**. A receptionist relying on the Dashboard is blind to patients 11 through 25.
- **Fix:** If `list.length > 10`, append an interactive footer card: `"+ ${list.length - 10} more patients in queue — Tap to view full list"`.

---

### 7. Token Receipt "Print Slip" Prints the Browser Screen Instead of Receipt
- **File:** [`lib/widgets/print/token_receipt_dialog.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/print/token_receipt_dialog.dart) (Line 226)
- **Code:**
  ```dart
  onPressed: () {
    printDocument(documentTitle: 'Token_${appointment.queueNumber}');
    Navigator.of(context).pop();
  }
  ```
- **Issue:** `printDocument()` is called without an `html` parameter. On web, calling `printDocument(html: null)` invokes `window.print()`, causing the browser to print the entire desktop web viewport and background cards instead of the thermal/A5 slip.
- **Fix:** Generate thermal HTML string and pass `printDocument(html: tokenHtml, documentTitle: ...)`.

---

## 🖥️ Category 3: Responsive Breakdowns & Header Clutter

### 8. Owner Shell Top Bar Overflow on 850px–1100px Laptops
- **File:** [`lib/widgets/common/owner_shell_app_bar.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/common/owner_shell_app_bar.dart) (Lines 69–295)
- **Issue:** In desktop mode (`isDesktop = width >= 800`), `AppBar.actions` pack:
  1. `'Security & PINs'` button (~130px)
  2. `'Export Data'` button (~115px)
  3. `'Lock to Reception'` button (~150px)
  4. `'Daily Cash Handover'` action card (~160px)
  5. Audio toggle icon (~48px)
  6. Date indicator (~100px)
  7. Doctor Quick-Filter pills (~220px)
- **Impact:** Total minimum width needed is ~950px+ just for actions. On standard 1366×768 laptops with browser bookmarks/sidebars open or windows snapped to half-screen (800–1000px), actions collide and trigger horizontal `RenderFlex overflow`.
- **Fix:** Consolidate secondary owner actions (`Security & PINs`, `Export Data`, `Lock to Reception`) into a `PopupMenuButton` when `width < 1150`.

---

### 9. Severe Ellipsis Crushing in Doctor Roster Split View (1050px–1250px)
- **File:** [`lib/widgets/dashboard/dashboard_doctor_roster_card.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_doctor_roster_card.dart) (Lines 222–260)
- **Issue:** On desktop, the Roster Card is assigned `flex: 4` (~330px width). Inside each doctor row's `title`:
  ```dart
  Row(
    children: [
      Flexible(child: Text(doctor.name, ...)),
      const SizedBox(width: 8),
      Flexible(child: _buildChamberStatusBadge(session)),
    ],
  )
  ```
  After deducting the 40px CircleAvatar, card padding (32px), ListTile internal padding, and trailing widget (80px), only ~140px remains. Both `doctor.name` and the status badge (`CONSULTING: Patient Name` or `READY FOR PATIENT`) are wrapped in `Flexible`, causing both to be truncated into unreadable 3-letter strings: `Dr. A...` `CONSU...`.
- **Fix:** Move the chamber status badge to the `subtitle` row below the doctor's name when panel width is under 400px.

---

### 10. Rigid Multi-Column Staged Medicine Form on Mobile
- **File:** [`lib/widgets/encounter/staged_medicine_form.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/encounter/staged_medicine_form.dart) (Lines 274–423)
- **Issue:**
  - Row 1 packs `Dosage` (`flex: 2`), `Frequency` (`flex: 3`), and `Timing` (`flex: 3`) into a rigid horizontal `Row`.
  - Row 2 packs `Duration` dropdown (`flex: 3`), custom duration field (`flex: 2`), and instructions (`flex: 5`) into a rigid horizontal `Row`.
- **Impact:** On a 390px mobile phone screen, dropdown options with clinical descriptions (e.g. `'Before Food / Khali Pet (AC)'` or `'SOS (As Needed)'`) are clipped, causing text to spill over dropdown arrows and arrows to disappear.
- **Fix:** Stack controls vertically or use a 2-column wrap on mobile screens (`width < 600`).

---

## 🎨 Category 4: Visual Polish, Duplicate Badges & Styling Inconsistencies

### 11. Duplicate Status Badges on the Same Queue Row
- **File:** [`lib/widgets/dashboard/dashboard_queue_item_row.dart`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/dashboard/dashboard_queue_item_row.dart) (Lines 197 & 399)
- **Issue:**
  - For completed and absent tokens, line 197 in `_buildVisitStatusBadge` renders an `AppointmentStatusChip(status: appt.status)`.
  - Concurrently, line 399 in `_buildActionRow` (the trailing widget on desktop) ALSO returns `AppointmentStatusChip(status: appt.status)`.
  - The row renders two identical status chips side-by-side (e.g., `[COMPLETED]` in title, and `[COMPLETED]` in trailing).
- **Fix:** Suppress the trailing chip if the title already renders `_buildVisitStatusBadge`.

---

### 12. Doctor Directory Cards Stretched to 1848px + Unstyled Raw Comma-Separated Text
- **File:** [`lib/screens/doctor_list_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/doctor_list_screen.dart) (Lines 419–425)
- **Issue:**
  - Unlike [`DashboardScreen`](file:///d:/Android/guwahatione-clinic-os/lib/screens/dashboard_screen.dart) and other screens, [`DoctorListScreen`](file:///d:/Android/guwahatione-clinic-os/lib/screens/doctor_list_screen.dart) has no `maxWidth: 1800` or split layout. On ultra-wide 1080p monitors, doctor cards stretch edge-to-edge (1848px wide), pushing the "Edit Doctor" and "Configure Leave" action buttons across an empty expanse.
  - Inside the card badges `Wrap`, the doctor's available days are rendered as raw text:
    ```dart
    Text(
      doctor.availableDays.join(', '),
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    )
    ```
    This raw comma string sits directly beside styled rounded pill badges (`Active`, `₹500 consultation`, `15 mins/patient`), looking misaligned.
- **Fix:** Apply container constraints and render available days in a standardized chip style.

---

### 13. Mobile Double Header & Redundant Controls in Analytics
- **File:** [`lib/screens/statistics_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/statistics_screen.dart) (Lines 52–95)
- **Issue:**
  - On mobile, `StatisticsScreen` builds an `AppBar` with an `Export CSV` icon button.
  - Right below it, the body layout renders a large `ElevatedButton.icon(label: 'Export CSV')` and a duplicate `ClinicDateNavBar`.
  - Users are presented with two export buttons and stacked date selectors within 150px of vertical viewport.
- **Fix:** Unify header actions and hide redundant body controls when mobile AppBar actions are present.

---

### 14. Doctor Daily Details Screen Bypasses App Design System
- **File:** [`lib/screens/doctor_daily_details_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/doctor_daily_details_screen.dart) (Lines 120–148)
- **Issue:**
  - Statuses are rendered with raw enum string conversions and hardcoded primary colors:
    ```dart
    Text(
      appt.status.name.toUpperCase(),
      style: TextStyle(
        color: appt.status == AppointmentStatus.completed ? Colors.green : Colors.orange,
      ),
    )
    ```
    Completely ignores the application's unified [`AppointmentStatusChip`](file:///d:/Android/guwahatione-clinic-os/lib/widgets/common/appointment_status_chip.dart).
  - Empty state is a bare `Center(child: Text('No appointments for this date.'))` lacking standard iconography, subtitle, or theme styling.
- **Fix:** Adopt `AppointmentStatusChip` and standard empty state widget.

---

### 15. Medicine Catalogue Missing Mobile Header & Inefficient Rendering
- **File:** [`lib/screens/medicine_catalogue_screen.dart`](file:///d:/Android/guwahatione-clinic-os/lib/screens/medicine_catalogue_screen.dart) (Lines 50–115)
- **Issue:**
  - Completely omits an `AppBar`. When viewed on mobile via `OwnerShell` bottom nav, the search box sits directly under the device status notch with no page title or branding.
  - Uses `ListView.separated(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` inside a `SingleChildScrollView`. In a catalogue with 150+ drugs, this forces instant instantiation of all 150 card widget subtrees on first render.
- **Fix:** Add responsive header/AppBar when embedded on mobile, and convert to standard lazy `ListView.builder`.
