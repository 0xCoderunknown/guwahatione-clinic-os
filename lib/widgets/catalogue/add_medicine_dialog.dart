import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_role.dart';
import '../../providers/clinic_provider.dart';

/// Modal dialog for adding a new commercial brand & chemical composition medicine entry.
class AddMedicineDialog extends StatefulWidget {
  final UserRole? currentRole;

  const AddMedicineDialog({
    super.key,
    required this.currentRole,
  });

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _compCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController(text: '500 mg');
  final _mfgCtrl = TextEditingController();
  String _form = 'Tablet';

  @override
  void dispose() {
    _brandCtrl.dispose();
    _compCtrl.dispose();
    _strengthCtrl.dispose();
    _mfgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Master Medicine Entry'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _brandCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Product Name (Commercial Brand)',
                    hintText: 'e.g., Dolo 650, Augmentin 625 Duo, Azithral 500',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Product name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _compCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Chemical Composition (Active Molecule)',
                    hintText: 'e.g., Paracetamol, Amoxicillin + Clavulanic Acid',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Composition is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _strengthCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Strength',
                          hintText: 'e.g., 650 mg, 500 mg / 5 ml',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Strength is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _form,
                        decoration: const InputDecoration(
                          labelText: 'Form',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          'Tablet',
                          'Capsule',
                          'Syrup',
                          'Injection',
                          'Drops',
                          'Ointment',
                          'Inhaler',
                          'Suspension',
                        ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _form = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mfgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer / Brand Pharma (Optional)',
                    hintText: 'e.g., Micro Labs, GSK, Cipla, Sun Pharma',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saveMedicine,
          child: const Text('Save to Catalogue'),
        ),
      ],
    );
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await Provider.of<ClinicProvider>(context, listen: false).addMedicine(
        productName: _brandCtrl.text.trim(),
        composition: _compCtrl.text.trim(),
        strength: _strengthCtrl.text.trim(),
        form: _form,
        manufacturer: _mfgCtrl.text.trim().isNotEmpty ? _mfgCtrl.text.trim() : null,
        requestingRole: widget.currentRole,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
