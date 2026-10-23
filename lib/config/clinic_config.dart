import 'package:flutter/foundation.dart';

/// Per-client deployment configuration placeholder for GuwahatiOne Clinic OS.
///
/// When deploying for a specific clinic / doctor chamber client, adjust these
/// settings to customize branding, operational defaults, and feature toggles.
class ClinicConfig {
  /// Name of the clinic displayed across dashboards, shells, and prints.
  final String clinicName;

  /// Subtitle or branch designation (e.g. 'Reception Desk', 'Downtown Branch').
  final String branchName;

  /// Tagline or department description.
  final String tagline;

  /// Physical address displayed on printed letterheads / receipts.
  final String address;

  /// Clinic reception contact number for patient receipts and inquiries.
  final String contactPhone;

  /// Currency symbol used across ledger and fee badges (default: '₹').
  final String currencySymbol;

  /// Default consultation fee when a doctor does not specify a custom fee.
  final int defaultConsultationFee;

  /// Grace period in days for free follow-up review consultations.
  final int freeReviewValidityDays;

  /// Default top margin reserved for physical pre-printed clinic letterheads (in millimeters).
  final double defaultLetterheadTopMarginMm;

  /// Maximum advance booking horizon in days for scheduling future appointments (default: 7).
  final int maxAdvanceBookingDays;

  /// Client-specific feature toggles.
  final ClinicFeatureFlags features;

  const ClinicConfig({
    this.clinicName = 'GuwahatiOne Clinic',
    this.branchName = 'Reception Desk',
    this.tagline = 'OPD Consultation Chamber & Reception Desk',
    this.address = 'Guwahati, Assam',
    this.contactPhone = '',
    this.currencySymbol = '₹',
    this.defaultConsultationFee = 500,
    this.freeReviewValidityDays = 14,
    this.defaultLetterheadTopMarginMm = 35.0,
    this.maxAdvanceBookingDays = 7,
    this.features = const ClinicFeatureFlags(),
  });

  /// Active configuration instance for this client deployment.
  /// Replace or modify this instance for custom tenant deployments.
  static ClinicConfig current = const ClinicConfig(
    clinicName: 'GuwahatiOne ClinicOS',
    address: 'Guwahati, Assam',
    contactPhone: '12345 67890',
    maxAdvanceBookingDays: 7,
    features: ClinicFeatureFlags(
      enableTestingMode: true,
    ),
  );
}

/// Feature flags that can be toggled on or off per client installation.
class ClinicFeatureFlags {
  // ─── Stable Operational Feature Flags ───────────────────────────────────────

  /// Whether to show the pre-printed letterhead margin toggle on the print preview.
  final bool enableLetterheadToggle;

  /// Whether to allow the doctor emergency override button on the chamber banner.
  final bool enableDoctorChamberOverride;

  /// Whether 1-tap WhatsApp prescription sharing deep-links are enabled.
  final bool enableWhatsAppPrescriptionShare;

  /// Whether doctors must enter a 4-digit PIN to access their chamber.
  final bool requireDoctorChamberPin;

  // ─── 🧪 Experimental Feature Flags (Customized per client installation) ───────

  /// 🧪 EXPERIMENT FLAG (P9): Whether hardcoded prescription template preset bundles
  /// (URI, Gastritis, Viral Fever, HTN) are displayed in the consultation prescribing section.
  /// When disabled, doctors use brand/composition search exclusively.
  final bool enablePrescriptionTemplatePresets;

  /// 🧪 EXPERIMENT FLAG: Whether counter token receipt / paid slip printing is enabled
  /// after walk-in booking and inside the reception queue accordion.
  /// When false (default), printed token slips are disabled as manual slips are used.
  /// When true, enables thermal token receipt and paid slip printing.
  final bool enableTokenReceiptPrint;

  /// 🧪 EXPERIMENT FLAG: Whether bulk "Close Session (Doctor Absent)" action is enabled
  /// for clinic owners to mark all remaining un-consulted tokens as absent.
  final bool enableBulkSessionClose;

  /// 🧪 EXPERIMENT FLAG: Whether medicine search displays grouped composition cards
  /// [COMPOSITION] {Brand 1} {Brand 2}.
  /// When disabled, renders a streamlined flat brand-first direct selection list.
  final bool enableGroupedCompositionCards;

  /// 🧪 EXPERIMENT FLAG: Whether the generic chemical composition is hidden from the prescription.
  /// When false (default), compositions are displayed alongside the brand name in uppercase brackets:
  /// e.g. "Telma 40 tablet [TELMISARTAN 40MG]".
  /// When true, composition is turned off, displaying only the trade brand name:
  /// e.g. "Telma 40 tablet".
  final bool hidePrescriptionComposition;

  /// 🧪 EXPERIMENT FLAG: Whether the clinic enforces single-active-doctor mode.
  /// When false (default), multi-chamber concurrent consulting is allowed.
  /// When true, a second doctor cannot signal ready or admit patients if another doctor is active.
  final bool enforceSingleActiveDoctor;

  // ─── 🧪 Testing & Developer Feature Flags ──────────────────────────────────

  /// 🧪 TESTING FLAG: When enabled, simplifies authentication across all roles
  /// (Doctor, Reception, Admin/Owner) by accepting '0000' for all PIN challenges.
  ///
  /// For production safety and FOSS compliance on Firebase Hosting:
  /// This bypass requires [isTestingModeActive], which is automatically suppressed
  /// and dead-code eliminated in `--release` builds unless explicitly overridden
  /// with `--dart-define=TEST_MODE=true`.
  final bool enableTestingMode;

  /// Compile-time guarded check for testing mode.
  /// Returns `true` only if [enableTestingMode] is set AND the app is in debug/test
  /// mode or explicitly built with `--dart-define=TEST_MODE=true`.
  bool get isTestingModeActive =>
      enableTestingMode &&
      (kDebugMode || const bool.fromEnvironment('TEST_MODE', defaultValue: false));

  /// 🧪 EXPERIMENT FLAG: Whether the default demo OPD medicine list is seeded automatically (AUDIT-27).
  /// When false, suppresses ensureDefaultMedicinesExist to prevent polluting live clinics that import custom CSV formularies.
  final bool enableSeedDefaultMedicines;

  const ClinicFeatureFlags({
    this.enableLetterheadToggle = true,
    this.enableDoctorChamberOverride = true,
    this.enableWhatsAppPrescriptionShare = true,
    this.requireDoctorChamberPin = true,
    this.enablePrescriptionTemplatePresets = false,
    this.enableTokenReceiptPrint = false,
    this.enableBulkSessionClose = true,
    this.enableGroupedCompositionCards = true,
    this.hidePrescriptionComposition = false,
    this.enforceSingleActiveDoctor = false,
    this.enableSeedDefaultMedicines = true,
    this.enableTestingMode = true,
  });
}
