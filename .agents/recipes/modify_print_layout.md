# 📋 Recipe: Modifying Printable Layouts & Letterheads

Follow this checklist whenever modifying printable prescription documents, token receipt slips, or letterhead margins.

---

### Invariant Checks (Red Lines)
- ❌ **NEVER introduce color backgrounds or heavy ink blocks in print layouts.** (Prescriptions are high-contrast monochrome A4/A5 for thermal and laser clinic printers).
- ❌ **NEVER format dates in non-Indian formats.** (Strictly use `AppFormatters.date(dateTime)` -> `DD-MM-YYYY`).
- ❌ **NEVER hardcode doctor titles.** (Always use `AppFormatters.doctorTitle(name)`).

---

### Step 1: Identify Print Artifact Target
- **Full Clinical Prescription:** `lib/widgets/print/print_header_and_demographics.dart` (Top header + demographics) and `lib/widgets/print/print_orders_and_footer.dart` (Footer, follow-ups, signature).
- **Rx Medication Table:** `lib/widgets/print/print_rx_table.dart` (Active medications vs discontinued therapy).
- **Thermal Counter Token Slip:** `lib/widgets/print/token_receipt_dialog.dart` (A6 / POS slip).

---

### Step 2: Letterhead Margin & Spacing Toggle
1. Support both pre-printed clinic letterhead pads and digital white-paper letterheads:
   - Check `usePrePrintedLetterhead` flag.
   - When enabled, render empty top spacer (`SizedBox(height: letterheadMargin)`) so pre-printed clinic clinic logos align perfectly.

---

### Step 3: Platform Print Binding (`lib/utils/platform_print.dart`)
1. Web printing is triggered via browser print window:
   - `triggerPlatformPrint()` binds to `dart:js_interop` in `platform_print_web.dart` and desktop stub in `platform_print_stub.dart`.
2. Ensure printable container uses media print CSS styling:
   - Avoid page-break cuts across medication rows (`page-break-inside: avoid`).
