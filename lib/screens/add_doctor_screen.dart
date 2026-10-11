import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../providers/clinic_provider.dart';
import '../utils/formatters.dart';

class AddDoctorScreen extends StatefulWidget {
  final Doctor? doctor;

  const AddDoctorScreen({super.key, this.doctor});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _feeController;
  late final TextEditingController _pinController;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late List<String> _selectedDays;

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _nameController = TextEditingController(text: d?.name ?? '');
    _specialtyController = TextEditingController(text: d?.specialty ?? '');
    _phoneController = TextEditingController(text: d?.phone ?? '');
    _feeController = TextEditingController(
      text: (d?.consultationFee ?? 500).toString(),
    );
    _pinController = TextEditingController(text: d?.pin ?? '1234');
    _selectedDays = d != null
        ? List<String>.from(d.availableDays)
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _feeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.doctor != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Doctor' : 'Add Doctor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Doctor Name (e.g., Dr. Sharma)',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty (e.g., General Physician, Paediatrician)',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
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
                      validator: (v) => v!.isEmpty ? 'Required' : null,
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
              const SizedBox(height: 24),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _saveDoctor,
                child: Text(
                  isEditing ? 'Save Changes' : 'Save Doctor',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }

    try {
      final fee = int.tryParse(_feeController.text.trim()) ?? 500;
      final pin = _pinController.text.trim();
      final clinicProvider = Provider.of<ClinicProvider>(context, listen: false);

      if (widget.doctor != null) {
        final updatedDoctor = widget.doctor!.copyWith(
          name: _nameController.text.trim(),
          specialty: AppFormatters.specialty(_specialtyController.text.trim()),
          phone: _phoneController.text.trim(),
          availableDays: _selectedDays,
          consultationFee: fee,
          pin: pin.isNotEmpty ? pin : widget.doctor!.pin,
        );
        await clinicProvider.updateDoctor(updatedDoctor);
      } else {
        await clinicProvider.addDoctor(
          _nameController.text.trim(),
          AppFormatters.specialty(_specialtyController.text.trim()),
          _phoneController.text.trim(),
          _selectedDays,
          pin: pin.isNotEmpty ? pin : '1234',
          consultationFee: fee,
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
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
