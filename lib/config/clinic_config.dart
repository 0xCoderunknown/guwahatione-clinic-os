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
    this.features = const ClinicFeatureFlags(),
  });

  /// Active configuration instance for this client deployment.
  /// Replace or modify this instance for custom tenant deployments.
  static const ClinicConfig current = ClinicConfig();
}

/// Feature flags that can be toggled on or off per client installation.
class ClinicFeatureFlags {
  /// Whether to show the pre-printed letterhead margin toggle on the print preview.
  final bool enableLetterheadToggle;

  /// Whether to allow the doctor emergency override button on the chamber banner.
  final bool enableDoctorChamberOverride;

  /// Whether 1-tap WhatsApp prescription sharing deep-links are enabled.
  final bool enableWhatsAppPrescriptionShare;

  /// Whether doctors must enter a 4-digit PIN to access their chamber.
  final bool requireDoctorChamberPin;

  const ClinicFeatureFlags({
    this.enableLetterheadToggle = true,
    this.enableDoctorChamberOverride = true,
    this.enableWhatsAppPrescriptionShare = true,
    this.requireDoctorChamberPin = true,
  });
}
