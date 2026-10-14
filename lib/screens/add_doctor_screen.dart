import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../utils/formatters.dart';

/// Screen coordinator for adding or editing a doctor's credentials and schedule.
class AddDoctorScreen extends StatelessWidget {
  final Doctor? doctor;

  const AddDoctorScreen({super.key, this.doctor});

  @override
  Widget build(BuildContext context) {
    final isEditing = doctor != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Doctor' : 'Add Doctor')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DoctorForm(
          doctor: doctor,
          onSaved: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

/// Form component for registering or updating a doctor profile,
/// consultation fee, chamber PIN, and weekly schedule.
class DoctorForm extends StatefulWidget {
  final Doctor? doctor;
  final VoidCallback onSaved;

  const DoctorForm({super.key, this.doctor, required this.onSaved});

  @override
  State<DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends State<DoctorForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _customSpecialtyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _feeController;
  late final TextEditingController _reviewDaysController;
  late final TextEditingController _pinController;
  late final TextEditingController _regNumberController;
  late final TextEditingController _tokenLimitController;

  late String _selectedSpecialty;
  late String _selectedStartTime;
  late String _selectedEndTime;
  late List<String> _timeSlots;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late List<String> _selectedDays;
  bool _isSaving = false;

  static const List<String> _standardSpecialties = [
    'General Medicine / Physician',
    'Paediatrics',
    'Gynaecology & Obstetrics',
    'Orthopaedics',
    'Dermatology',
    'ENT (Otorhinolaryngology)',
    'Cardiology',
    'Neurology',
    'Gastroenterology',
    'Pulmonology / Chest Medicine',
    'Nephrology & Urology',
    'Ophthalmology',
    'Psychiatry & Behavioural Sciences',
    'Dental Surgery',
    'General Surgery',
    'Other (Custom)...',
  ];

  static const List<String> _baseTimeSlots = [
    '6:00 AM',
    '6:30 AM',
    '7:00 AM',
    '7:30 AM',
    '8:00 AM',
    '8:30 AM',
    '9:00 AM',
    '9:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '1:00 PM',
    '1:30 PM',
    '2:00 PM',
    '2:30 PM',
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
    '4:30 PM',
    '5:00 PM',
    '5:30 PM',
    '6:00 PM',
    '6:30 PM',
    '7:00 PM',
    '7:30 PM',
    '8:00 PM',
    '8:30 PM',
    '9:00 PM',
    '9:30 PM',
    '10:00 PM',
    '10:30 PM',
    '11:00 PM',
    '11:30 PM',
    '12:00 AM',
    '12:30 AM',
    '1:00 AM',
    '1:30 AM',
    '2:00 AM',
    '2:30 AM',
    '3:00 AM',
    '3:30 AM',
    '4:00 AM',
    '4:30 AM',
    '5:00 AM',
    '5:30 AM',
  ];

  static String _canonicalTime(String raw) {
    var clean = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.startsWith('0') && clean.length >= 7 && clean[2] == ':') {
      clean = clean.substring(1);
    }
    return clean;
  }

  int _timeToMinutes(String timeStr) {
    try {
      final clean = timeStr.trim().toUpperCase();
      final isPM = clean.contains('PM');
      final isAM = clean.contains('AM');
      final digits = clean.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = digits.split(':');
      var hours = int.parse(parts[0]);
      final minutes = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPM && hours != 12) hours += 12;
      if (isAM && hours == 12) hours = 0;
      return hours * 60 + minutes;
    } catch (_) {
      return 0;
    }
  }

  bool get _isTimingAwkward {
    final startMin = _timeToMinutes(_selectedStartTime);
    final endMin = _timeToMinutes(_selectedEndTime);
    if (startMin == endMin) return true;
    if (endMin < startMin) return true;
    if (startMin < 360 || endMin < 360 || startMin >= 1320) return true;
    return false;
  }

  String get _timingWarningMessage {
    final startMin = _timeToMinutes(_selectedStartTime);
    final endMin = _timeToMinutes(_selectedEndTime);
    if (startMin == endMin) {
      return '⚠️ Shift start time and end time are identical (0 duration). Please select valid start and end times.';
    }
    if (endMin < startMin) {
      return '⚠️ Overnight shift: Shift ends on the following day (crossing midnight, e.g. $_selectedStartTime to $_selectedEndTime). Please verify start and end times.';
    }
    if (startMin < 360 || endMin < 360 || startMin >= 1320) {
      return '⚠️ Late night / midnight shift: Selected OPD timing ($_selectedStartTime to $_selectedEndTime) falls during unusual night hours. Please verify if this is intended.';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _nameController = TextEditingController(text: d?.name ?? '');
    _phoneController = TextEditingController(text: d?.phone ?? '');
    _feeController = TextEditingController(
      text: (d?.consultationFee ?? 500).toString(),
    );
    _reviewDaysController = TextEditingController(
      text: (d?.freeReviewDays ?? 14).toString(),
    );
    _pinController = TextEditingController(text: d?.pin ?? '1234');
    _regNumberController = TextEditingController(
      text: d?.medicalRegNumber ?? '',
    );
    _tokenLimitController = TextEditingController(
      text: (d?.dailyTokenLimit ?? 18).toString(),
    );

    // 1. Specialty Resolution
    final docSpecialty = d?.specialty.trim() ?? '';
    if (docSpecialty.isEmpty) {
      _selectedSpecialty = 'General Medicine / Physician';
      _customSpecialtyController = TextEditingController();
    } else {
      final match = _standardSpecialties.firstWhere(
        (s) => s.toLowerCase() == docSpecialty.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        _selectedSpecialty = match;
        _customSpecialtyController = TextEditingController();
      } else {
        _selectedSpecialty = 'Other (Custom)...';
        _customSpecialtyController = TextEditingController(text: docSpecialty);
      }
    }

    // 2. Shift Timing Dropdown Resolution
    final initialTiming = d?.shiftTiming ?? '6:00 PM – 8:30 PM';
    final timingParts = initialTiming.split(RegExp(r'\s*(?:–|-|\bto\b)\s*'));
    if (timingParts.length >= 2) {
      _selectedStartTime = _canonicalTime(timingParts[0]);
      _selectedEndTime = _canonicalTime(timingParts[1]);
    } else {
      _selectedStartTime = '6:00 PM';
      _selectedEndTime = '8:30 PM';
    }

    _timeSlots = List<String>.from(_baseTimeSlots);
    if (!_timeSlots.contains(_selectedStartTime)) {
      _timeSlots.add(_selectedStartTime);
    }
    if (!_timeSlots.contains(_selectedEndTime)) {
      _timeSlots.add(_selectedEndTime);
    }

    _selectedDays = d != null
        ? List<String>.from(d.availableDays)
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customSpecialtyController.dispose();
    _phoneController.dispose();
    _feeController.dispose();
    _reviewDaysController.dispose();
    _pinController.dispose();
    _regNumberController.dispose();
    _tokenLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.doctor != null;

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          // 1. Doctor Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Doctor Name (e.g., Dr. Sharma)',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          // 2. Department / Specialty Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedSpecialty,
            decoration: const InputDecoration(
              labelText: 'Department / Specialty',
              prefixIcon: Icon(Icons.medical_services_outlined),
            ),
            items: _standardSpecialties.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedSpecialty = val);
              }
            },
          ),
          if (_selectedSpecialty == 'Other (Custom)...') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customSpecialtyController,
              decoration: const InputDecoration(
                labelText: 'Specify Custom Specialty',
                hintText: 'e.g., Diabetologist, Oncologist, etc.',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ],
          const SizedBox(height: 12),

          // 3. Contact & Medical Registration
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regNumberController,
            decoration: const InputDecoration(
              labelText: 'Medical Council Reg No. (Optional)',
              hintText: 'e.g., AMC-24891 / NMC-10293',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Consultation Fee & Chamber PIN
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _feeController,
                  decoration: const InputDecoration(
                    labelText: 'Consultation Fee (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'Chamber PIN',
                    hintText: '4 digits',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return 'Min 4 digits';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5. Shift / OPD Timing (30-Minute Dropdowns)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStartTime,
                  decoration: const InputDecoration(
                    labelText: 'Shift Start',
                    prefixIcon: Icon(Icons.access_time_rounded),
                  ),
                  items: _timeSlots.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStartTime = val);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('to', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedEndTime,
                  decoration: const InputDecoration(
                    labelText: 'Shift End',
                    prefixIcon: Icon(Icons.access_time_filled_rounded),
                  ),
                  items: _timeSlots.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedEndTime = val);
                  },
                ),
              ),
            ],
          ),
          if (_isTimingAwkward) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _timingWarningMessage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 6. Daily Token Cap
          TextFormField(
            controller: _tokenLimitController,
            decoration: const InputDecoration(
              labelText: 'Daily Token Cap',
              hintText: '18',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (v) =>
                v == null || int.tryParse(v.trim()) == null
                    ? 'Number required'
                    : null,
          ),
          const SizedBox(height: 16),

          // 7. Free Review Window (Directly above Available Days)
          TextFormField(
            controller: _reviewDaysController,
            decoration: const InputDecoration(
              labelText: 'Free Review Window (0 to 30 Days)',
              hintText: 'e.g. 14 (Enter 0 for No Free Review)',
              prefixIcon: Icon(Icons.event_repeat),
              suffixText: 'Days',
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final val = int.tryParse(v.trim());
              if (val == null || val < 0 || val > 30) {
                return 'Enter between 0 and 30 days';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6.0,
            children: [
              ChoiceChip(
                label: const Text('None (0d)'),
                selected: _reviewDaysController.text.trim() == '0',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _reviewDaysController.text = '0');
                  }
                },
              ),
              ChoiceChip(
                label: const Text('7 Days'),
                selected: _reviewDaysController.text.trim() == '7',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _reviewDaysController.text = '7');
                  }
                },
              ),
              ChoiceChip(
                label: const Text('14 Days (Default)'),
                selected: _reviewDaysController.text.trim() == '14',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _reviewDaysController.text = '14');
                  }
                },
              ),
              ChoiceChip(
                label: const Text('21 Days'),
                selected: _reviewDaysController.text.trim() == '21',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _reviewDaysController.text = '21');
                  }
                },
              ),
              ChoiceChip(
                label: const Text('30 Days'),
                selected: _reviewDaysController.text.trim() == '30',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _reviewDaysController.text = '30');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 8. Available Days
          const Text(
            'Available Days',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: _days.map((day) {
              final isSelected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // 9. Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isSaving ? null : _saveDoctor,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isEditing ? 'Save Changes' : 'Save Doctor',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDoctor() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStartTime == _selectedEndTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift start time and end time cannot be identical.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fee = int.tryParse(_feeController.text.trim()) ?? 500;
      final reviewDays = int.tryParse(_reviewDaysController.text.trim()) ?? 14;
      final pin = _pinController.text.trim();
      final regNumber = _regNumberController.text.trim();
      final shiftTiming = '$_selectedStartTime – $_selectedEndTime';
      final tokenLimit = int.tryParse(_tokenLimitController.text.trim()) ?? 18;

      final specialtyRaw = _selectedSpecialty == 'Other (Custom)...'
          ? _customSpecialtyController.text.trim()
          : _selectedSpecialty;
      final specialty = AppFormatters.specialty(specialtyRaw);

      final clinicProvider = Provider.of<ClinicProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.doctor != null) {
        final updatedDoctor = widget.doctor!.copyWith(
          name: AppFormatters.doctorTitle(_nameController.text.trim()),
          specialty: specialty,
          phone: _phoneController.text.trim(),
          availableDays: _selectedDays,
          consultationFee: fee,
          freeReviewDays: reviewDays,
          pin: pin.isNotEmpty ? pin : widget.doctor!.pin,
          medicalRegNumber: regNumber.isNotEmpty ? regNumber : null,
          shiftTiming: shiftTiming,
          dailyTokenLimit: tokenLimit,
        );
        await clinicProvider.updateDoctor(
          updatedDoctor,
          requestingRole: authProvider.currentRole,
        );
      } else {
        await clinicProvider.addDoctor(
          AppFormatters.doctorTitle(_nameController.text.trim()),
          specialty,
          _phoneController.text.trim(),
          _selectedDays,
          pin: pin.isNotEmpty ? pin : '1234',
          consultationFee: fee,
          freeReviewDays: reviewDays,
          medicalRegNumber: regNumber.isNotEmpty ? regNumber : null,
          shiftTiming: shiftTiming,
          dailyTokenLimit: tokenLimit,
          requestingRole: authProvider.currentRole,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.doctor != null
                ? 'Doctor details updated successfully'
                : 'Doctor added successfully',
          ),
          backgroundColor: Colors.teal,
        ),
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
