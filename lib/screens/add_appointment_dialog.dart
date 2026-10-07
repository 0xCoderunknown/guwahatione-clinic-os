import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/engines/engines.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/patient_review_eligibility.dart';
import '../providers/clinic_provider.dart';
import '../widgets/widgets.dart';

/// Modal dialog for receptionist to register patient walk-ins and book appointments.
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
                // 1. Date Selector
                ListTile(
                  title: Text("Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}"),
                  trailing: const Icon(Icons.calendar_today),
                  tileColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),

                // 2. Patient Demographics & Phone Search
                BookingPatientFields(
                  phoneController: _phoneController,
                  nameController: _nameController,
                  ageController: _ageController,
                  selectedGender: _selectedGender,
                  isLoading: _isLoading,
                  onGenderChanged: (val) => setState(() => _selectedGender = val),
                  onPhoneChanged: _onPhoneChanged,
                ),
                if (_historyInfo != null) ...[
                  const SizedBox(height: 8),
                  BookingEligibilityBanner(
                    historyInfo: _historyInfo,
                    historyColor: _historyColor,
                    isNewPatient: _isNewPatient,
                  ),
                ],
                const SizedBox(height: 16),

                // 3. Doctor Selection, Payment Policy & Fee
                BookingPaymentSection(
                  doctors: doctors,
                  selectedDoctor: _selectedDoctor,
                  onDoctorChanged: (val) {
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
                  selectedPayment: _selectedPayment,
                  onPaymentChanged: _onPaymentChanged,
                  reviewEligibility: _reviewEligibility,
                  amountController: _amountController,
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

  void _onPhoneChanged(String val) {
    if (val.length == 10) {
      _searchPatient(val);
    } else if (val.length < 10) {
      if (_historyInfo != null || _patientAppointments.isNotEmpty) {
        setState(() {
          _historyInfo = null;
          _patientAppointments = [];
          _reviewEligibility = const PatientReviewEligibility(
            hasVisitedDoctorEarlier: false,
            isWithin14Days: false,
            message: '',
          );
        });
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
        _patientAppointments = await provider.getAppointmentsForPatient(phone);
      } else {
        _isNewPatient = true;
        _patientAppointments = [];
        _amountController.text =
            "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: PaymentType.paid)}";
      }

      _updateEligibilityAndPayment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error fetching patient: $e"), backgroundColor: Colors.red),
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
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: PaymentType.paid)}";
        }
      });
      return;
    }

    final eligibility = AppointmentEngine.evaluateReviewEligibility(
      patientHistory: _patientAppointments,
      doctorId: _selectedDoctor?.id,
      targetDate: _selectedDate,
      doctorName: _selectedDoctor?.name,
    );

    setState(() {
      _reviewEligibility = eligibility;

      if (!eligibility.hasVisitedDoctorEarlier) {
        _historyColor = Colors.blue.shade100;
        _historyInfo =
            "Existing Patient • No earlier visit with ${_selectedDoctor?.name ?? 'selected doctor'}\n(Free Review requires prior visit with same doctor)";
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = PaymentType.paid;
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: PaymentType.paid)}";
        }
      } else if (eligibility.isWithin14Days) {
        final dateStr = DateFormat('dd MMM yyyy').format(eligibility.lastVisitDate!);
        _historyColor = Colors.teal.shade100;
        _historyInfo =
            "Existing Patient • Last visit with ${_selectedDoctor?.name}: $dateStr\n✅ Eligible for 14-day Free Review (${eligibility.daysSinceLastVisit} days ago)";
        _selectedPayment = PaymentType.freeReview;
        _amountController.text = "0";
      } else {
        final dateStr = DateFormat('dd MMM yyyy').format(eligibility.lastVisitDate!);
        _historyColor = Colors.amber.shade100;
        _historyInfo =
            "Existing Patient • Last visit with ${_selectedDoctor?.name}: $dateStr\n⚠️ 14 days have passed (${eligibility.daysSinceLastVisit} days ago)";
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = PaymentType.paid;
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: PaymentType.paid)}";
        }
      }
    });
  }

  Future<void> _onPaymentChanged(PaymentType? val) async {
    if (val == null) return;

    if (val == PaymentType.freeReview) {
      if (!_reviewEligibility.hasVisitedDoctorEarlier) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Free Review is only available for returning patients of this doctor.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_reviewEligibility.isWithin14Days) {
        final dateStr = _reviewEligibility.lastVisitDate != null
            ? DateFormat('dd MMM yyyy').format(_reviewEligibility.lastVisitDate!)
            : 'N/A';
        final days = _reviewEligibility.daysSinceLastVisit ?? 15;

        final proceed = await BookingEligibilityBanner.showFourteenDaysWarningDialog(
          context,
          doctorName: _selectedDoctor?.name ?? 'the doctor',
          dateStr: dateStr,
          days: days,
        );
        if (!proceed) {
          setState(() {
            _selectedPayment = PaymentType.paid;
            _amountController.text =
                "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: PaymentType.paid)}";
          });
          return;
        }
      }
    }

    setState(() {
      _selectedPayment = val;
      _amountController.text =
          "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment)}";
    });
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a doctor")),
      );
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
