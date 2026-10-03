import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
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

  Doctor? _selectedDoctor;
  bool _isNewPatient = false;
  bool _isLoading = false;

  String? _historyInfo;
  Color _historyColor = Colors.blue.shade50;

  @override
  void initState() {
    super.initState();
    // Auto-select doctor if only one exists
    final doctors = Provider.of<ClinicProvider>(context, listen: false).doctors;
    if (doctors.length == 1) {
      _selectedDoctor = doctors.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctors = Provider.of<ClinicProvider>(context).doctors;

    return AlertDialog(
      title: const Text('New Appointment'),
      content: SizedBox(
        width: 400,
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
                    });
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
                          if (val.length == 10) _searchPatient(val);
                          // Clear history if they start typing a new number
                          if (val.length < 10 && _historyInfo != null) {
                            setState(() => _historyInfo = null);
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
                      children: [
                        Icon(
                          _isNewPatient ? Icons.person_add : Icons.history,
                          size: 16,
                          color: Colors.black54,
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
                Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                      flex: 1,
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
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentType>(
                  initialValue: _selectedPayment,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentType.values.map((type) {
                    String label;
                    if (type == PaymentType.paid) {
                      label = 'Paid (₹${AppConstants.defaultConsultationFee})';
                    } else if (type == PaymentType.freeReview) {
                      label = 'FREE (Review)';
                    } else {
                      label = 'FREE (Family)';
                    }
                    return DropdownMenuItem(value: type, child: Text(label));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPayment = val!;
                      // Auto-set amount logic
                      if (_selectedPayment == PaymentType.paid) {
                        _amountController.text = "500";
                      } else {
                        _amountController.text = "0";
                      }
                    });
                  },
                ),
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

        final type = provider.calculatePaymentType(patient);

        setState(() {
          _isNewPatient = false;
          _selectedPayment = type;
          _amountController.text =
              (type == PaymentType.paid)
                  ? '${AppConstants.defaultConsultationFee}'
                  : '0';

          _historyColor = Colors.blue.shade100;
          _historyInfo =
              "Existing Patient\nLast Visit: ${DateFormat('dd MMM yyyy').format(patient.lastVisitDate)}";
        });
      } else {
        setState(() {
          _isNewPatient = true;
          _selectedPayment = PaymentType.paid;
          _amountController.text = "500";

          _historyColor = Colors.green.shade100;
          _historyInfo = "New Patient Record";
        });
      }
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

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a doctor")));
      return;
    }

    try {
      await Provider.of<ClinicProvider>(context, listen: false).bookAppointment(
        phoneNumber: _phoneController.text,
        name: _nameController.text,
        age: int.parse(_ageController.text),
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
