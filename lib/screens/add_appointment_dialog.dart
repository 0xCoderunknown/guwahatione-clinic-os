import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/patient_review_eligibility.dart';
import '../providers/clinic_provider.dart';
import '../utils/app_constants.dart';

class AddAppointmentDialog extends StatefulWidget {
  const AddAppointmentDialog({super.key});

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  PaymentType _selectedPayment = PaymentType.paid;
  String _selectedGender = 'Male';

  Doctor? _selectedDoctor;
  bool _isNewPatient = false;
  bool _isLoading = false;

  List<Appointment> _patientAppointments = [];
  PatientReviewEligibility _reviewEligibility = const PatientReviewEligibility(
    hasVisitedDoctorEarlier: false,
    isWithin14Days: false,
    message: '',
  );

  String? _historyInfo;
  Color _historyColor = Colors.blue.shade50;

  @override
  void initState() {
    super.initState();
    // Auto-select doctor if only one exists
    final doctors = Provider.of<ClinicProvider>(context, listen: false).doctors;
    if (doctors.length == 1) {
      _selectedDoctor = doctors.first;
      _amountController.text = "${_selectedDoctor!.consultationFee}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctors = Provider.of<ClinicProvider>(context).doctors;

    return AlertDialog(
      title: const Text('New Appointment'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. DATE PICKER
                ListTile(
                  title: Text(
                    "Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),

                // 2. DOCTOR DROPDOWN
                DropdownButtonFormField<Doctor>(
                  initialValue: _selectedDoctor,
                  decoration: const InputDecoration(
                    labelText: 'Select Doctor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_add),
                  ),
                  items: doctors.map((doc) {
                    return DropdownMenuItem(value: doc, child: Text(doc.name));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDoctor = val;
                      if (_selectedPayment == PaymentType.paid && val != null) {
                        _amountController.text = "${val.consultationFee}";
                      }
                    });
                    if (_phoneController.text.length == 10) {
                      _updateEligibilityAndPayment();
                    }
                  },
                  validator: (val) =>
                      val == null ? 'Please select a doctor' : null,
                ),
                const SizedBox(height: 16),

                // 3. PHONE SEARCH
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (val) => (val == null || val.length < 10)
                            ? 'Invalid Phone'
                            : null,
                        onChanged: (val) {
                          if (val.length == 10) {
                            _searchPatient(val);
                          } else if (val.length < 10) {
                            if (_historyInfo != null ||
                                _patientAppointments.isNotEmpty) {
                              setState(() {
                                _historyInfo = null;
                                _patientAppointments = [];
                                _reviewEligibility =
                                    const PatientReviewEligibility(
                                  hasVisitedDoctorEarlier: false,
                                  isWithin14Days: false,
                                  message: '',
                                );
                              });
                            }
                          }
                        },
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),

                if (_historyInfo != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _historyColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _historyColor.withValues(alpha: 1.0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            _isNewPatient ? Icons.person_add : Icons.history,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _historyInfo!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 4. PATIENT NAME, AGE & GENDER
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Patient Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (val) =>
                            (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Sex',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedGender = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. PAYMENT TYPE
                DropdownButtonFormField<PaymentType>(
                  key: ValueKey(_selectedPayment),
                  initialValue: _selectedPayment,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentType.values.map((type) {
                    String label;
                    bool enabled = true;
                    if (type == PaymentType.paid) {
                      final fee = _selectedDoctor?.consultationFee ??
                          AppConstants.defaultConsultationFee;
                      label = 'Paid (₹$fee)';
                    } else if (type == PaymentType.freeFamily) {
                      label = 'FREE (Family)';
                    } else {
                      // PaymentType.freeReview
                      if (!_reviewEligibility.hasVisitedDoctorEarlier) {
                        // Not eligible: patient never visited this doctor earlier
                        enabled = false;
                        label = 'FREE (Review) — Returning patients only';
                      } else if (_reviewEligibility.isWithin14Days) {
                        label = 'FREE (Review) — Within 14 days';
                      } else {
                        // Visited earlier, but >14 days has passed.
                        // NOT disabled per requirements, but clearly tagged!
                        label = 'FREE (Review) — ⚠️ >14 days passed';
                      }
                    }

                    return DropdownMenuItem<PaymentType>(
                      value: type,
                      enabled: enabled,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: enabled ? null : Colors.grey.shade500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) async {
                    if (val == null) return;

                    if (val == PaymentType.freeReview) {
                      // Rule: Only a patient who visited earlier can get a free review with same doctor
                      if (!_reviewEligibility.hasVisitedDoctorEarlier) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Free Review is only available for returning patients of this doctor.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Rule: If 14 days has passed, choosing free review should immediately warn
                      if (!_reviewEligibility.isWithin14Days) {
                        final proceed =
                            await _showFourteenDaysWarningDialog();
                        if (!proceed) {
                          setState(() {
                            _selectedPayment = PaymentType.paid;
                            _amountController.text =
                                "${_selectedDoctor?.consultationFee ?? AppConstants.defaultConsultationFee}";
                          });
                          return;
                        }
                      }
                    }

                    setState(() {
                      _selectedPayment = val;
                      if (_selectedPayment == PaymentType.paid) {
                        _amountController.text =
                            "${_selectedDoctor?.consultationFee ?? AppConstants.defaultConsultationFee}";
                      } else {
                        _amountController.text = "0";
                      }
                    });
                  },
                ),

                // Warning banner if Free Review is selected when >14 days has passed
                if (_selectedPayment == PaymentType.freeReview &&
                    _reviewEligibility.hasVisitedDoctorEarlier &&
                    !_reviewEligibility.isWithin14Days) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade900,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: 14 days have passed (${_reviewEligibility.daysSinceLastVisit} days since last visit). Free review manually approved.',
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
                const SizedBox(height: 16),

                // 6. AMOUNT
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Book Appointment'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (_phoneController.text.length == 10) {
        _updateEligibilityAndPayment();
      }
    }
  }

  Future<void> _searchPatient(String phone) async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<ClinicProvider>(context, listen: false);
      final patient = await provider.searchPatient(phone);

      if (patient != null) {
        _nameController.text = patient.name;
        _ageController.text = patient.age.toString();
        _selectedGender = patient.gender;
        _isNewPatient = false;

        // Fetch patient's appointments across all doctors
        _patientAppointments = await provider.getAppointmentsForPatient(phone);
      } else {
        _isNewPatient = true;
        _patientAppointments = [];
        _amountController.text =
            "${_selectedDoctor?.consultationFee ?? AppConstants.defaultConsultationFee}";
      }

      _updateEligibilityAndPayment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network error fetching patient: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateEligibilityAndPayment() {
    if (_isNewPatient || _phoneController.text.length < 10) {
      setState(() {
        _reviewEligibility = const PatientReviewEligibility(
          hasVisitedDoctorEarlier: false,
          isWithin14Days: false,
          message: 'New patient record',
        );
        _historyInfo = "New Patient Record";
        _historyColor = Colors.green.shade100;
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = PaymentType.paid;
          _amountController.text =
              "${_selectedDoctor?.consultationFee ?? AppConstants.defaultConsultationFee}";
        }
      });
      return;
    }

    final eligibility = PatientReviewEligibility.calculate(
      appointments: _patientAppointments,
      doctorId: _selectedDoctor?.id,
      targetDate: _selectedDate,
      doctorName: _selectedDoctor?.name,
    );

    setState(() {
      _reviewEligibility = eligibility;

      if (!eligibility.hasVisitedDoctorEarlier) {
        // Patient never visited this doctor earlier
        _historyColor = Colors.blue.shade100;
        _historyInfo =
            "Existing Patient • No earlier visit with ${_selectedDoctor?.name ?? 'selected doctor'}\n(Free Review requires prior visit with same doctor)";
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = PaymentType.paid;
          _amountController.text =
              "${_selectedDoctor?.consultationFee ?? AppConstants.defaultConsultationFee}";
        }
      } else if (eligibility.isWithin14Days) {
        // Within 14 days
        final dateStr =
            DateFormat('dd MMM yyyy').format(eligibility.lastVisitDate!);
        _historyColor = Colors.teal.shade100;
        _historyInfo =
            "Existing Patient • Last visit with ${_selectedDoctor?.name}: $dateStr\n✅ Eligible for 14-day Free Review (${eligibility.daysSinceLastVisit} days ago)";
        _selectedPayment = PaymentType.freeReview;
        _amountController.text = "0";
      } else {
        // >14 days have passed
        final dateStr =
            DateFormat('dd MMM yyyy').format(eligibility.lastVisitDate!);
        _historyColor = Colors.amber.shade100;
        _historyInfo =
            "Existing Patient • Last visit with ${_selectedDoctor?.name}: $dateStr\n⚠️ 14 days have passed (${eligibility.daysSinceLastVisit} days ago)";
        // If not already set, default to Paid
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = PaymentType.paid;
          _amountController.text =
              "${_selectedDoctor?.consultationFee ?? AppConstants.defaultConsultationFee}";
        }
      }
    });
  }

  Future<bool> _showFourteenDaysWarningDialog() async {
    final docName = _selectedDoctor?.name ?? 'the doctor';
    final dateStr = _reviewEligibility.lastVisitDate != null
        ? DateFormat('dd MMM yyyy').format(_reviewEligibility.lastVisitDate!)
        : 'N/A';
    final days = _reviewEligibility.daysSinceLastVisit ?? 15;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.amber,
          size: 48,
        ),
        title: const Text(
          '14 Days Passed Warning',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ 14 days have passed since the patient\'s last visit with Dr. $docName.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Last Visit: $dateStr'),
                  Text('• Days Elapsed: $days days (Policy limit: 14 days)'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Only visits within 14 days qualify for free review. Do you want to proceed with a Free Review anyway?',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel (Keep Paid)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow Free Review'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a doctor")));
      return;
    }

    if (_selectedPayment == PaymentType.freeReview &&
        !_reviewEligibility.hasVisitedDoctorEarlier) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Free review is only allowed for patients who previously visited Dr. ${_selectedDoctor!.name}.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await Provider.of<ClinicProvider>(context, listen: false).bookAppointment(
        phoneNumber: _phoneController.text,
        name: _nameController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        paymentType: _selectedPayment,
        amountCollected: int.parse(_amountController.text),
        scheduledDate: _selectedDate,
        selectedDoctor: _selectedDoctor!,
        isNewPatient: _isNewPatient,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
