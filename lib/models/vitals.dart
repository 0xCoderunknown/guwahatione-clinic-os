class Vitals {
  final int? systolicBp; // mmHg (e.g. 120)
  final int? diastolicBp; // mmHg (e.g. 80)
  final int? pulseRate; // bpm (e.g. 72)
  final double? temperature; // °F (e.g. 98.6)
  final double? weightKg; // kg (e.g. 68.5)
  final int? spO2; // % (e.g. 98)
  final int? respiratoryRate; // breaths/min
  final double? bloodSugar; // mg/dL

  const Vitals({
    this.systolicBp,
    this.diastolicBp,
    this.pulseRate,
    this.temperature,
    this.weightKg,
    this.spO2,
    this.respiratoryRate,
    this.bloodSugar,
  });

  bool get hasAny =>
      systolicBp != null ||
      diastolicBp != null ||
      pulseRate != null ||
      temperature != null ||
      weightKg != null ||
      spO2 != null ||
      respiratoryRate != null ||
      bloodSugar != null;

  String? get bpFormatted {
    if (systolicBp != null && diastolicBp != null) {
      return '$systolicBp/$diastolicBp mmHg';
    } else if (systolicBp != null) {
      return '$systolicBp mmHg (Sys)';
    } else if (diastolicBp != null) {
      return '$diastolicBp mmHg (Dia)';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'systolicBp': systolicBp,
      'diastolicBp': diastolicBp,
      'pulseRate': pulseRate,
      'temperature': temperature,
      'weightKg': weightKg,
      'spO2': spO2,
      'respiratoryRate': respiratoryRate,
      'bloodSugar': bloodSugar,
    };
  }

  factory Vitals.fromJson(Map<String, dynamic> json) {
    return Vitals(
      systolicBp: (json['systolicBp'] as num?)?.toInt(),
      diastolicBp: (json['diastolicBp'] as num?)?.toInt(),
      pulseRate: (json['pulseRate'] as num?)?.toInt(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      spO2: (json['spO2'] as num?)?.toInt(),
      respiratoryRate: (json['respiratoryRate'] as num?)?.toInt(),
      bloodSugar: (json['bloodSugar'] as num?)?.toDouble(),
    );
  }

  Vitals copyWith({
    int? systolicBp,
    int? diastolicBp,
    int? pulseRate,
    double? temperature,
    double? weightKg,
    int? spO2,
    int? respiratoryRate,
    double? bloodSugar,
  }) {
    return Vitals(
      systolicBp: systolicBp ?? this.systolicBp,
      diastolicBp: diastolicBp ?? this.diastolicBp,
      pulseRate: pulseRate ?? this.pulseRate,
      temperature: temperature ?? this.temperature,
      weightKg: weightKg ?? this.weightKg,
      spO2: spO2 ?? this.spO2,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      bloodSugar: bloodSugar ?? this.bloodSugar,
    );
  }
}
