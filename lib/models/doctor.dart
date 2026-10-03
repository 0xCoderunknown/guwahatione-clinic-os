class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String phone;
  final List<String> availableDays; // e.g., ["Mon", "Wed", "Fri"]
  final List<DateTime> blockedDates; // Days they are on leave

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phone,
    required this.availableDays,
    required this.blockedDates,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'phone': phone,
      'availableDays': availableDays,
      'blockedDates': blockedDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Doctor',
      specialty: json['specialty'] as String? ?? 'General',
      phone: json['phone'] as String? ?? '',
      availableDays: List<String>.from(json['availableDays'] ?? []),
      blockedDates: (json['blockedDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }
}