import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/engines/engines.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/patient.dart';
import '../../models/patient_review_eligibility.dart';
import '../../providers/clinic_provider.dart';
import '../../utils/formatters.dart';
import 'booking_carry_over_banner.dart';
import 'booking_date_and_mode_section.dart';
import 'booking_dialog_actions.dart';
import 'booking_duplicate_warning_banner.dart';
import 'booking_eligibility_banner.dart';
import 'booking_offline_banner.dart';
import 'booking_patient_fields.dart';
import 'booking_payment_section.dart';
import 'booking_success_snackbar.dart';

/// Modal dialog for receptionist to register patient walk-ins and book appointments.
/// Features 100% keyboard-first navigation, provisional token preview, and same-day duplicate booking prevention.
class AddAppointmentDialog extends StatefulWidget {
  final Patient? initialPatient;
  final Doctor? initialDoctor;

  const AddAppointmentDialog({
    super.key,
    this.initialPatient,
    this.initialDoctor,
  });

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _amountController = TextEditingController();

  final _guardianNameController = TextEditingController();
  final _guardianRelationController = TextEditingController();
  final _guardianFocusNode = FocusNode();
  final _guardianRelationFocusNode = FocusNode();

  List<Patient> _familyMembers = [];
  String? _selectedPatientId;
  String _ageUnit = 'Yrs';

  final _phoneFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _genderFocusNode = FocusNode();
  final _doctorFocusNode = FocusNode();
  final _paymentFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _submitFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  VisitStatus _selectedVisitStatus = VisitStatus.waitingInLobby;
  PaymentType _selectedPayment = PaymentType.paidCash;
  bool _hasUserManuallyChangedPayment = false;
  String? _selectedGender;
  bool _genderHasError = false;

  Doctor? _selectedDoctor;
  bool _isNewPatient = false;
  bool _isLoading = false;
  bool _isBooking = false;

  List<Appointment> _patientAppointments = [];
  Appointment? _duplicateAppointment;
  Appointment? _eligibleCarryOver;
  bool _isCarryOverApplied = false;

  PatientReviewEligibility _reviewEligibility = const PatientReviewEligibility(
    hasVisitedDoctorEarlier: false,
    isWithinReviewPeriod: false,
    message: '',
  );

  String? _historyInfo;
  Color _historyColor = Colors.blue.shade50;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkDuplicateBooking);
    final doctors = Provider.of<ClinicProvider>(context, listen: false).doctors;
    if (widget.initialDoctor != null) {
      _selectedDoctor = widget.initialDoctor;
      _amountController.text = "${_selectedDoctor!.consultationFee}";
    } else if (doctors.length == 1) {
      _selectedDoctor = doctors.first;
      _amountController.text = "${_selectedDoctor!.consultationFee}";
    }

    if (widget.initialPatient != null) {
      final p = widget.initialPatient!;
      _phoneController.text = p.phoneNumber;
      _nameController.text = p.name;
      _ageController.text = p.age > 0 ? p.age.toString() : '';
      _selectedGender = ['Male', 'Female', 'Other'].contains(p.gender)
          ? p.gender
          : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchPatient(p.phoneNumber);
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkDuplicateBooking);
    _phoneController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _amountController.dispose();
    _guardianNameController.dispose();
    _guardianRelationController.dispose();

    _phoneFocusNode.dispose();
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _genderFocusNode.dispose();
    _guardianFocusNode.dispose();
    _guardianRelationFocusNode.dispose();
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
      patientId: _selectedPatientId,
      targetDate: _selectedDate,
    );

    if (_duplicateAppointment?.id != duplicate?.id) {
      setState(() => _duplicateAppointment = duplicate);
    }
  }

  bool get _isSelectedDateToday =>
      DateUtils.isSameDay(_selectedDate, DateTime.now());

  int? get _provisionalToken {
    if (_selectedDoctor == null || !_isSelectedDateToday) return null;
    final provider = Provider.of<ClinicProvider>(context, listen: false);
    return AppointmentEngine.calculateProvisionalNextToken(
      appointments: provider.todayAppointments,
      doctorId: _selectedDoctor!.id,
      targetDate: _selectedDate,
    );
  }

  String? get _provisionalTimeWindow {
    if (_selectedDoctor == null ||
        _provisionalToken == null ||
        !_isSelectedDateToday) {
      return null;
    }
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

  int get _bookedTokensCount {
    if (_selectedDoctor == null || !_isSelectedDateToday) return 0;
    final provider = Provider.of<ClinicProvider>(context, listen: false);
    return AppointmentEngine.calculateBookedTokensCount(
      appointments: provider.todayAppointments,
      doctorId: _selectedDoctor!.id,
      targetDate: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctors = context.select<ClinicProvider, List<Doctor>>(
      (p) => p.doctors,
    );

    if (_selectedDoctor == null && doctors.length == 1) {
      _selectedDoctor = doctors.first;
      if (_amountController.text.isEmpty && _selectedPayment.isPaid) {
        _amountController.text = "${_selectedDoctor!.consultationFee}";
      }
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_isLoading && !_isBooking && _duplicateAppointment == null) {
            _saveAppointment();
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (!_isLoading && !_isBooking && _duplicateAppointment == null) {
            _saveAppointment();
          }
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
                  const BookingOfflineBanner(),

                  // 1. Date Selector & Booking Mode
                  BookingDateAndModeSection(
                    selectedDate: _selectedDate,
                    selectedVisitStatus: _selectedVisitStatus,
                    onPickDate: _pickDate,
                    onVisitStatusChanged: (status) {
                      setState(() {
                        _selectedVisitStatus = status;
                        if (_selectedVisitStatus == VisitStatus.booked &&
                            _selectedPayment.isPaid) {
                          _selectedPayment = PaymentType.unpaid;
                          _amountController.text = "0";
                        } else if (_selectedVisitStatus ==
                                VisitStatus.waitingInLobby &&
                            _selectedPayment == PaymentType.unpaid) {
                          _selectedPayment = PaymentType.paidCash;
                          _amountController.text =
                              "${_selectedDoctor?.consultationFee ?? 500}";
                        }
                      });
                    },
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
                    familyMembers: _familyMembers,
                    selectedPatientId: _selectedPatientId,
                    primaryContactName: _familyMembers.firstOrNull?.name,
                    onSelectPatient: _onSelectFamilyMember,
                    ageUnit: _ageUnit,
                    onAgeUnitChanged: (unit) {
                      setState(() => _ageUnit = unit);
                    },
                    guardianNameController: _guardianNameController,
                    guardianRelationController: _guardianRelationController,
                    guardianFocusNode: _guardianFocusNode,
                    guardianRelationFocusNode: _guardianRelationFocusNode,
                    onGenderChanged: (val) {
                      setState(() {
                        _selectedGender = val;
                        _genderHasError = false;
                      });
                    },
                    onPhoneChanged: _onPhoneChanged,
                    onGenerateEmergencyPhone: _generateEmergencyPhone,
                    onSubmitted: () {
                      if (!_isBooking && _duplicateAppointment == null) {
                        _saveAppointment();
                      }
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
                  if (_eligibleCarryOver != null) ...[
                    const SizedBox(height: 10),
                    BookingCarryOverBanner(
                      eligibleAppointment: _eligibleCarryOver!,
                      isApplied: _isCarryOverApplied,
                      onApply: () {
                        setState(() {
                          _isCarryOverApplied = true;
                          _hasUserManuallyChangedPayment = true;
                          _selectedPayment = PaymentType.paidCarryOver;
                          _amountController.text = "0";
                        });
                      },
                      onUndo: () {
                        setState(() {
                          _isCarryOverApplied = false;
                          _selectedPayment = PaymentType.paidCash;
                          _amountController.text =
                              "${_selectedDoctor?.consultationFee ?? 500}";
                        });
                      },
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
                    bookedTokensCount: _bookedTokensCount,
                    onDoctorChanged: (val) {
                      setState(() {
                        _selectedDoctor = val;
                        _hasUserManuallyChangedPayment = false;
                        if (_selectedPayment.isPaid && val != null) {
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
                      final isDoctorOnLeave = AppointmentEngine.isDoctorOnLeave(
                        doctor: _selectedDoctor,
                        date: _selectedDate,
                      );
                      if (!_isBooking &&
                          _duplicateAppointment == null &&
                          !isDoctorOnLeave) {
                        _saveAppointment();
                      }
                    },
                  ),
                  if (_selectedDoctor != null &&
                      AppointmentEngine.isDoctorOnLeave(
                        doctor: _selectedDoctor,
                        date: _selectedDate,
                      )) ...[
                    const SizedBox(height: 12),
                    BookingDoctorLeaveWarningBanner(
                      doctor: _selectedDoctor!,
                      date: _selectedDate,
                    ),
                  ] else if (_selectedDoctor != null &&
                      !AppointmentEngine.isDoctorAvailableOnDate(
                        doctor: _selectedDoctor,
                        date: _selectedDate,
                      )) ...[
                    const SizedBox(height: 12),
                    BookingOffDayWarningBanner(
                      doctor: _selectedDoctor!,
                      date: _selectedDate,
                    ),
                  ],

                  // 4. Duplicate Booking Warning Alert Banner
                  if (_duplicateAppointment != null) ...[
                    const SizedBox(height: 14),
                    BookingDuplicateWarningBanner(
                      duplicate: _duplicateAppointment!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          BookingDialogActions(
            isBooking: _isBooking,
            isLoading: _isLoading,
            isDisabled: _duplicateAppointment != null ||
                AppointmentEngine.isDoctorOnLeave(
                  doctor: _selectedDoctor,
                  date: _selectedDate,
                ) ||
                !AppointmentEngine.isDoctorAvailableOnDate(
                  doctor: _selectedDoctor,
                  date: _selectedDate,
                ),
            submitFocusNode: _submitFocusNode,
            onCancel: () => Navigator.pop(context),
            onSubmit: _saveAppointment,
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
    _hasUserManuallyChangedPayment = false;
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
            isWithinReviewPeriod: false,
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
      final family = await provider.getPatientsForPhone(phone);

      if (family.isNotEmpty) {
        setState(() {
          _familyMembers = family;
          _hasUserManuallyChangedPayment = false;
        });
        await _onSelectFamilyMember(family.first);
      } else {
        setState(() {
          _familyMembers = [];
          _selectedPatientId = null;
          _isNewPatient = true;
          _hasUserManuallyChangedPayment = false;
          _patientAppointments = [];
          _selectedGender = null;
          _genderHasError = false;
          _guardianNameController.clear();
          _guardianRelationController.clear();
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: PaymentType.paidCash)}";
        });

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateEmergencyPhone() {
    final dummy = AppointmentEngine.generateEmergencyDummyPhone();
    setState(() {
      _phoneController.text = dummy;
      _selectedPatientId = null;
      _familyMembers = [];
      _isNewPatient = true;
      _historyInfo = null;
      _nameController.clear();
      _ageController.clear();
      _selectedGender = null;
      _guardianNameController.clear();
      _guardianRelationController.clear();
      _amountController.text =
          "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment.isPaid ? _selectedPayment : PaymentType.paidCash)}";
    });
    _onPhoneChanged(dummy);
    if (mounted) {
      _nameFocusNode.requestFocus();
    }
  }

  Future<void> _onSelectFamilyMember(Patient? patient) async {
    _hasUserManuallyChangedPayment = false;
    if (patient != null) {
      setState(() {
        _selectedPatientId = patient.id;
        _nameController.text = patient.name;
        if (patient.ageMonths != null && patient.ageMonths! > 0) {
          _ageUnit = 'Months';
          _ageController.text = patient.ageMonths.toString();
        } else if (patient.ageDays != null && patient.ageDays! > 0) {
          _ageUnit = 'Days';
          _ageController.text = patient.ageDays.toString();
        } else {
          _ageUnit = 'Yrs';
          _ageController.text = patient.age > 0 ? patient.age.toString() : '';
        }
        _selectedGender = ['Male', 'Female', 'Other'].contains(patient.gender)
            ? patient.gender
            : null;
        _guardianNameController.text = patient.guardianName ?? '';
        _guardianRelationController.text = patient.guardianRelation ?? '';
        _genderHasError = false;
        _isNewPatient = false;
      });

      final provider = Provider.of<ClinicProvider>(context, listen: false);
      _patientAppointments = await provider.getAppointmentsForPatient(
        patient.id,
        phone: patient.phoneNumber,
      );

      if (mounted) {
        _doctorFocusNode.requestFocus();
      }
    } else {
      // "+ Add Member" on same household phone
      final primaryContact = _familyMembers.firstOrNull;
      setState(() {
        _selectedPatientId = null;
        _isNewPatient = true;
        _nameController.clear();
        _ageController.clear();
        _guardianNameController.text = primaryContact?.name ?? '';
        _guardianRelationController.text =
            primaryContact != null ? 'Parent / Guardian' : '';
        _selectedGender = null;
        _genderHasError = false;
        _patientAppointments = [];
      });
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    }

    _updateEligibilityAndPayment();
  }

  void _updateEligibilityAndPayment() {
    // INVIOLABLE CLINIC INVARIANT: Discretionary FREE (Family / VVIP) waivers
    // must NEVER be overwritten or coerced by patient history or review window calculations!
    if (_selectedPayment == PaymentType.freeFamily) {
      _amountController.text = "0";
      return;
    }

    if (_isNewPatient || _phoneController.text.length < 10) {
      setState(() {
        _eligibleCarryOver = null;
        _isCarryOverApplied = false;
        _reviewEligibility = const PatientReviewEligibility(
          hasVisitedDoctorEarlier: false,
          isWithinReviewPeriod: false,
          message: 'New patient record',
        );
        _historyInfo = "New Patient Record";
        _historyColor = Colors.green.shade100;
        if (_selectedPayment == PaymentType.freeReview ||
            _selectedPayment == PaymentType.paidCarryOver) {
          _selectedPayment = _selectedVisitStatus == VisitStatus.booked
              ? PaymentType.unpaid
              : PaymentType.paidCash;
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment)}";
        }
      });
      return;
    }

    final carryOver = AppointmentEngine.findEligibleCarryOverAppointment(
      patientHistory: _patientAppointments,
      doctorId: _selectedDoctor?.id,
      targetDate: _selectedDate,
      patientId: _selectedPatientId,
      patientName: _nameController.text.trim(),
    );

    final eligibility = AppointmentEngine.evaluateReviewEligibility(
      patientHistory: _patientAppointments,
      doctorId: _selectedDoctor?.id,
      targetDate: _selectedDate,
      doctorName: _selectedDoctor?.name,
      freeReviewDays: _selectedDoctor?.freeReviewDays ?? 14,
    );

    setState(() {
      _eligibleCarryOver = carryOver;
      if (carryOver == null && _isCarryOverApplied) {
        _isCarryOverApplied = false;
        if (_selectedPayment == PaymentType.paidCarryOver) {
          _selectedPayment = PaymentType.paidCash;
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment)}";
        }
      }

      _reviewEligibility = eligibility;

      if (!eligibility.hasVisitedDoctorEarlier) {
        _historyColor = Colors.blue.shade100;
        _historyInfo =
            "Existing Patient • No earlier visit with ${_selectedDoctor?.name ?? 'selected doctor'}\n(Free Review requires prior visit with same doctor)";
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = _selectedVisitStatus == VisitStatus.booked
              ? PaymentType.unpaid
              : PaymentType.paidCash;
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment)}";
        }
      } else if (eligibility.isReviewAlreadyConsumed) {
        final dateStr = AppFormatters.date(eligibility.lastVisitDate!);
        _historyColor = Colors.orange.shade100;
        _historyInfo =
            "Existing Patient • Paid visit on $dateStr\n⚠️ Free review already used for this consultation (1 review allowed per paid visit)";
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = _selectedVisitStatus == VisitStatus.booked
              ? PaymentType.unpaid
              : PaymentType.paidCash;
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment)}";
        }
      } else if (eligibility.allowedReviewDays == 0) {
        final dateStr = AppFormatters.date(eligibility.lastVisitDate!);
        _historyColor = Colors.orange.shade100;
        _historyInfo =
            "Existing Patient • Last visit with ${_selectedDoctor?.name}: $dateStr\n⚠️ ${_selectedDoctor?.name} does not offer free reviews (0-day free-follow-up policy)";
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = _selectedVisitStatus == VisitStatus.booked
              ? PaymentType.unpaid
              : PaymentType.paidCash;
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment)}";
        }
      } else if (eligibility.isWithinReviewPeriod) {
        final dateStr = AppFormatters.date(eligibility.lastVisitDate!);
        _historyColor = Colors.teal.shade100;
        _historyInfo =
            "Existing Patient • Last visit with ${_selectedDoctor?.name}: $dateStr\n✅ Eligible for ${eligibility.allowedReviewDays}-day Free Review (${eligibility.daysSinceLastVisit} days ago)";
        if (!_hasUserManuallyChangedPayment && !_isCarryOverApplied) {
          _selectedPayment = PaymentType.freeReview;
          _amountController.text = "0";
        }
      } else {
        final dateStr = AppFormatters.date(eligibility.lastVisitDate!);
        _historyColor = Colors.amber.shade100;
        _historyInfo =
            "Existing Patient • Last visit with ${_selectedDoctor?.name}: $dateStr\n⚠️ ${eligibility.allowedReviewDays} days have passed (${eligibility.daysSinceLastVisit} days ago)";
        if (_selectedPayment == PaymentType.freeReview) {
          _selectedPayment = _selectedVisitStatus == VisitStatus.booked
              ? PaymentType.unpaid
              : PaymentType.paidCash;
          _amountController.text =
              "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment)}";
        }
      }
    });
  }

  Future<void> _onPaymentChanged(PaymentType? val) async {
    if (val == null) return;

    if (val == PaymentType.paidCarryOver) {
      if (_eligibleCarryOver == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No eligible un-consulted prepaid visit found for this patient and doctor.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        _hasUserManuallyChangedPayment = true;
        _isCarryOverApplied = true;
        _selectedPayment = PaymentType.paidCarryOver;
        _amountController.text = "0";
      });
      return;
    }

    if (val == PaymentType.freeReview) {
      final docTitle = _selectedDoctor != null
          ? AppFormatters.doctorTitle(_selectedDoctor!.name)
          : 'this doctor';

      if (!_reviewEligibility.hasVisitedDoctorEarlier) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Free Review is only available for returning patients of $docTitle.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_reviewEligibility.isReviewAlreadyConsumed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Free review has already been consumed for the previous visit with $docTitle.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_reviewEligibility.isWithinReviewPeriod) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Free review window has expired for $docTitle (${_reviewEligibility.allowedReviewDays}-day policy).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _hasUserManuallyChangedPayment = true;
      if (val != PaymentType.paidCarryOver) {
        _isCarryOverApplied = false;
      }
      _selectedPayment = val;
      _amountController.text =
          "${AppointmentEngine.resolveConsultationFee(doctor: _selectedDoctor, paymentType: _selectedPayment)}";
    });
  }

  Future<void> _saveAppointment() async {
    if (_isBooking) return;
    if (!_formKey.currentState!.validate()) return;

    if (_duplicateAppointment != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${_duplicateAppointment!.patientName} already holds Token #${_duplicateAppointment!.queueNumber} with ${AppFormatters.doctorTitle(_duplicateAppointment!.doctorName)} for today.",
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

    if (AppointmentEngine.isDoctorOnLeave(
      doctor: _selectedDoctor,
      date: _selectedDate,
    )) {
      final summary =
          AppointmentEngine.formatDoctorLeaveSummary(
            doctor: _selectedDoctor,
            date: _selectedDate,
          ) ??
          'Doctor is on leave';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $summary on this date.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!AppointmentEngine.isDoctorAvailableOnDate(
      doctor: _selectedDoctor,
      date: _selectedDate,
    )) {
      const dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = dayNames[_selectedDate.weekday - 1];
      final docName = AppFormatters.doctorTitle(_selectedDoctor!.name);
      final schedule = _selectedDoctor!.availableDays.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ $docName does not consult on ${dayName}s (Schedule: $schedule).',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (_selectedPayment == PaymentType.freeReview) {
      final docName = _selectedDoctor != null
          ? AppFormatters.doctorTitle(_selectedDoctor!.name)
          : 'the selected doctor';
      if (!_reviewEligibility.hasVisitedDoctorEarlier) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Free review is only allowed for patients who previously visited $docName.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_reviewEligibility.isReviewAlreadyConsumed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Free review has already been consumed for the previous consultation with $docName.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (!_reviewEligibility.isWithinReviewPeriod) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Free review window has expired for $docName (${_reviewEligibility.allowedReviewDays}-day policy).",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    int parsedAge = 0;
    int? ageMonths;
    int? ageDays;
    final ageVal = int.tryParse(_ageController.text.trim()) ?? 0;
    if (_ageUnit == 'Months') {
      ageMonths = ageVal;
      parsedAge = 0;
    } else if (_ageUnit == 'Days') {
      ageDays = ageVal;
      parsedAge = 0;
    } else {
      parsedAge = ageVal;
    }

    setState(() => _isBooking = true);

    try {
      final newAppt = await Provider.of<ClinicProvider>(context, listen: false)
          .bookAppointment(
            patientId: _selectedPatientId,
            phoneNumber: _phoneController.text.trim(),
            name: _nameController.text.trim(),
            age: parsedAge,
            ageMonths: ageMonths,
            ageDays: ageDays,
            guardianName: _guardianNameController.text.trim().isNotEmpty
                ? _guardianNameController.text.trim()
                : null,
            guardianRelation: _guardianRelationController.text.trim().isNotEmpty
                ? _guardianRelationController.text.trim()
                : null,
            gender: _selectedGender!,
            visitStatus: _selectedVisitStatus,
            paymentType: _selectedPayment,
            amountCollected: int.parse(_amountController.text.trim()),
            scheduledDate: _selectedDate,
            selectedDoctor: _selectedDoctor!,
            isNewPatient: _isNewPatient,
            carriedOverAppointmentId:
                _isCarryOverApplied ? _eligibleCarryOver?.id : null,
            carriedOverAmount:
                _isCarryOverApplied ? _eligibleCarryOver?.amountCollected : null,
            carriedOverDate:
                _isCarryOverApplied ? _eligibleCarryOver?.scheduledDate : null,
          );
      if (mounted) {
        Navigator.pop(context, newAppt);
        BookingSuccessSnackbar.show(context, newAppt);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      final errorStr = e.toString().toLowerCase();
      final isOffline = errorStr.contains('offline') ||
          errorStr.contains('unavailable') ||
          errorStr.contains('network') ||
          errorStr.contains('connection');
      final message = isOffline
          ? '⚠️ Cannot allocate token offline: Cloud connection lost. Please verify clinic broadband and retry.'
          : 'Error booking appointment: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
