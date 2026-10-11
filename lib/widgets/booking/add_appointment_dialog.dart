import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/patient_review_eligibility.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';
import 'booking_eligibility_banner.dart';
import 'booking_patient_fields.dart';
import 'booking_payment_section.dart';

/// Modal dialog for receptionist to register patient walk-ins and book appointments.
/// Features 100% keyboard-first navigation, provisional token preview, and same-day duplicate booking prevention.
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

  final _phoneFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _genderFocusNode = FocusNode();
  final _doctorFocusNode = FocusNode();
  final _paymentFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _submitFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  PaymentType _selectedPayment = PaymentType.paid;
  String? _selectedGender;
  bool _genderHasError = false;

  Doctor? _selectedDoctor;
  bool _isNewPatient = false;
  bool _isLoading = false;

  List<Appointment> _patientAppointments = [];
  Appointment? _duplicateAppointment;

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
    _nameController.addListener(_checkDuplicateBooking);
    final doctors = Provider.of<ClinicProvider>(context, listen: false).doctors;
    if (doctors.length == 1) {
      _selectedDoctor = doctors.first;
      _amountController.text = "${_selectedDoctor!.consultationFee}";
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkDuplicateBooking);
    _phoneController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _amountController.dispose();

    _phoneFocusNode.dispose();
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _genderFocusNode.dispose();
    _doctorFocusNode.dispose();
    _paymentFocusNode.dispose();
    _amountFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  List<Appointment> get _allRelevantAppointments {
    final provider = Provider.of<ClinicProvider>(context, listen: false);
    final map = <String, Appointment>{};
    for (final a in provider.todayAppointments) {
      map[a.id] = a;
    }
    for (final a in _patientAppointments) {
      map[a.id] = a;
    }
    return map.values.toList();
  }

  void _checkDuplicateBooking() {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final docId = _selectedDoctor?.id;

    if (phone.isEmpty || name.isEmpty || docId == null) {
      if (_duplicateAppointment != null) {
        setState(() => _duplicateAppointment = null);
      }
      return;
    }

    final duplicate = AppointmentEngine.findDuplicateBooking(
      appointments: _allRelevantAppointments,
      doctorId: docId,
      patientName: name,
      patientPhone: phone,
      targetDate: _selectedDate,
    );

    if (_duplicateAppointment?.id != duplicate?.id) {
      setState(() => _duplicateAppointment = duplicate);
    }
  }

  int? get _provisionalToken {
    if (_selectedDoctor == null) return null;
    final provider = Provider.of<ClinicProvider>(context, listen: false);
    return AppointmentEngine.calculateProvisionalNextToken(
      appointments: provider.todayAppointments,
      doctorId: _selectedDoctor!.id,
      targetDate: _selectedDate,
    );
  }

  String? get _provisionalTimeWindow {
    if (_selectedDoctor == null || _provisionalToken == null) return null;
    final provider = Provider.of<ClinicProvider>(context, listen: false);
    final window = AppointmentEngine.calculateProvisionalEstimatedWindow(
      appointments: provider.todayAppointments,
      doctorId: _selectedDoctor!.id,
      targetDate: _selectedDate,
      currentTime: DateTime.now(),
    );
    final startStr = AppFormatters.time(window.estimatedStart);
    final endStr = AppFormatters.time(window.estimatedEnd);
    return '~$startStr – $endStr';
  }

  @override
  Widget build(BuildContext context) {
    final doctors = Provider.of<ClinicProvider>(context).doctors;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_isLoading && _duplicateAppointment == null) _saveAppointment();
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (!_isLoading && _duplicateAppointment == null) _saveAppointment();
        },
      },
      child: AlertDialog(
        title: const Text('New Appointment'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Date Selector
                  ListTile(
                    title: Text("Date: ${AppFormatters.date(_selectedDate)}"),
                    trailing: const Icon(Icons.calendar_today),
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),

                  // 2. Patient Demographics & Phone Search (Keyboard-First)
                  BookingPatientFields(
                    phoneController: _phoneController,
                    nameController: _nameController,
                    ageController: _ageController,
                    selectedGender: _selectedGender,
                    isLoading: _isLoading,
                    phoneFocusNode: _phoneFocusNode,
                    nameFocusNode: _nameFocusNode,
                    ageFocusNode: _ageFocusNode,
                    genderFocusNode: _genderFocusNode,
                    genderHasError: _genderHasError,
                    onGenderChanged: (val) {
                      setState(() {
                        _selectedGender = val;
                        _genderHasError = false;
                      });
                    },
                    onPhoneChanged: _onPhoneChanged,
                    onSubmitted: () {
                      if (_duplicateAppointment == null) _saveAppointment();
                    },
                  ),
                  if (_historyInfo != null) ...[
                    const SizedBox(height: 10),
                    BookingEligibilityBanner(
                      historyInfo: _historyInfo,
                      historyColor: _historyColor,
                      isNewPatient: _isNewPatient,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 3. Doctor Selection, Provisional Token Preview, Payment Policy & Fee
                  BookingPaymentSection(
                    doctors: doctors,
                    selectedDoctor: _selectedDoctor,
                    doctorFocusNode: _doctorFocusNode,
                    paymentFocusNode: _paymentFocusNode,
                    amountFocusNode: _amountFocusNode,
                    provisionalToken: _provisionalToken,
                    provisionalTimeWindow: _provisionalTimeWindow,
                    onDoctorChanged: (val) {
                      setState(() {
                        _selectedDoctor = val;
                        if (_selectedPayment == PaymentType.paid && val != null) {
                          _amountController.text = "${val.consultationFee}";
                        }
                      });
                      _checkDuplicateBooking();
                      if (_phoneController.text.length == 10) {
                        _updateEligibilityAndPayment();
                      }
                    },
                    selectedPayment: _selectedPayment,
                    onPaymentChanged: _onPaymentChanged,
                    reviewEligibility: _reviewEligibility,
                    amountController: _amountController,
                    onSubmitted: () {
                      if (_duplicateAppointment == null) _saveAppointment();
                    },
                  ),

                  // 4. Duplicate Booking Warning Alert Banner
                  if (_duplicateAppointment != null) ...[
                    const SizedBox(height: 14),
                    _buildDuplicateWarningBanner(_duplicateAppointment!),
                  ],
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
            focusNode: _submitFocusNode,
            onPressed: (_isLoading || _duplicateAppointment != null)
                ? null
                : _saveAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateWarningBanner(Appointment duplicate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Warm amber background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB45309),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ ${duplicate.patientName} already holds Token #${duplicate.queueNumber} with Dr. ${duplicate.doctorName} for today.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Modify Name if booking for a family member.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB45309),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text('View Token #${duplicate.queueNumber}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFD97706)),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                onPressed: () {
                  final prov =
                      Provider.of<ClinicProvider>(context, listen: false);
                  prov.setDashboardSearchQuery('${duplicate.queueNumber}');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Viewing Token #${duplicate.queueNumber} • ${duplicate.patientName}',
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
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
      _checkDuplicateBooking();
      if (_phoneController.text.length == 10) {
        _updateEligibilityAndPayment();
      }
    }
  }

  void _onPhoneChanged(String val) {
    _checkDuplicateBooking();
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
        _ageController.text = patient.age > 0 ? patient.age.toString() : '';
        _selectedGender = ['Male', 'Female', 'Other'].contains(patient.gender)
            ? patient.gender
            : null;
        _genderHasError = false;
        _isNewPatient = false;
        _patientAppointments = await provider.getAppointmentsForPatient(phone);

        // Auto-advance focus to Doctor selector on existing record match
        if (mounted) {
          _doctorFocusNode.requestFocus();
        }
      } else {
        _isNewPatient = true;
        _patientAppointments = [];
        _selectedGender = null;
        _genderHasError = false;
        _amountController.text =
            "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: PaymentType.paid)}";

        // Auto-advance focus to Patient Name on new patient record
        if (mounted) {
          _nameFocusNode.requestFocus();
        }
      }

      _updateEligibilityAndPayment();
      _checkDuplicateBooking();
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
        final dateStr = AppFormatters.date(eligibility.lastVisitDate!);
        _historyColor = Colors.teal.shade100;
        _historyInfo =
            "Existing Patient • Last visit with ${_selectedDoctor?.name}: $dateStr\n✅ Eligible for 14-day Free Review (${eligibility.daysSinceLastVisit} days ago)";
        _selectedPayment = PaymentType.freeReview;
        _amountController.text = "0";
      } else {
        final dateStr = AppFormatters.date(eligibility.lastVisitDate!);
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
            content: Text(
              'Free Review is only available for returning patients of this doctor.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_reviewEligibility.isWithin14Days) {
        final dateStr = _reviewEligibility.lastVisitDate != null
            ? AppFormatters.date(_reviewEligibility.lastVisitDate!)
            : 'N/A';
        final days = _reviewEligibility.daysSinceLastVisit ?? 15;

        final proceed =
            await BookingEligibilityBanner.showFourteenDaysWarningDialog(
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

    if (_duplicateAppointment != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${_duplicateAppointment!.patientName} already holds Token #${_duplicateAppointment!.queueNumber} with Dr. ${_duplicateAppointment!.doctorName} for today.",
          ),
          backgroundColor: Colors.amber.shade900,
        ),
      );
      return;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      setState(() => _genderHasError = true);
      _genderFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select patient sex (Male, Female, or Other)."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDoctor == null) {
      _doctorFocusNode.requestFocus();
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
        phoneNumber: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        gender: _selectedGender!,
        paymentType: _selectedPayment,
        amountCollected: int.parse(_amountController.text.trim()),
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
