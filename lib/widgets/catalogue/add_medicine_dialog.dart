import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_role.dart';
import '../../providers/clinic_provider.dart';

/// Modal dialog for adding a new medicine entry with commercial brand,
/// generic chemical composition, and optional OPD regimen defaults.
class AddMedicineDialog extends StatefulWidget {
  final UserRole? currentRole;

  const AddMedicineDialog({super.key, required this.currentRole});

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _compCtrl = TextEditingController();
  final _mfgCtrl = TextEditingController();

  // OPD Regimen Defaults
  final _dosageCtrl = TextEditingController(text: '1 Tablet');
  final _customDurationCtrl = TextEditingController(text: '5');
  String _frequency = '1-0-0 (OD)';
  String _timing = 'After Food';
  String _durationPreset = 'To continue (Chronic)';
  bool _showRegimenDefaults = false;
  bool _isSaving = false;

  final List<String> _frequencyOptions = const [
    '1-0-0 (OD)',
    '1-0-1 (BD)',
    '0-0-1 (HS)',
    '1-1-1 (TDS)',
    'SOS (As Needed)',
    'Once Weekly',
  ];

  final List<String> _timingOptions = const [
    'After Food',
    'Before Food (Empty Stomach)',
    'At Bedtime',
    'With Food',
  ];

  final List<String> _durationOptions = const [
    'To continue (Chronic)',
    '30 days',
    '15 days',
    '14 days',
    '10 days',
    '7 days',
    '5 days',
    '3 days',
    'Custom',
  ];

  @override
  void dispose() {
    _brandCtrl.dispose();
    _compCtrl.dispose();
    _mfgCtrl.dispose();
    _dosageCtrl.dispose();
    _customDurationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medicine to Catalogue'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Product Name (Trade Brand with Dosage Form)
                TextFormField(
                  controller: _brandCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Product Name (Brand & Form)',
                    hintText: 'e.g., Telma 40 tablet, Dolo 650 tablet, Ascoril D Plus syrup',
                    border: OutlineInputBorder(),
                    helperText: 'Include dosage form (tablet, syrup, capsule) in product name',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Product name is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // 2. Chemical Composition with Strength
                TextFormField(
                  controller: _compCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Active Composition & Strength',
                    hintText: 'e.g., Telmisartan 40mg, Paracetamol 650mg, Cefixime 200mg',
                    border: OutlineInputBorder(),
                    helperText:
                        'Include molecule strength directly in composition',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Composition is required'
                      : null,
                ),
                const SizedBox(height: 12),

                // 3. Manufacturer
                TextFormField(
                  controller: _mfgCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer / Pharma Brand (Optional)',
                    hintText:
                        'e.g., Glenmark, Micro Labs, GSK, Cipla, Sun Pharma',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Regimen Defaults Expansion Tile
                InkWell(
                  onTap: () => setState(
                    () => _showRegimenDefaults = !_showRegimenDefaults,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showRegimenDefaults
                              ? Icons.tune
                              : Icons.tune_outlined,
                          size: 18,
                          color: Colors.teal.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'OPD Regimen Defaults (Optional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ),
                        Icon(
                          _showRegimenDefaults
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 20,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showRegimenDefaults) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _dosageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Default Dosage',
                            hintText: '1 Tablet / 5 ml',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _frequency,
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _frequencyOptions
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(
                                    f,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _frequency = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _timing,
                          decoration: const InputDecoration(
                            labelText: 'Timing',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _timingOptions
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _timing = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _durationPreset,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _durationOptions
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                    d,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _durationPreset = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_durationPreset == 'Custom') ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _customDurationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration in Days',
                        hintText: 'e.g., 21',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveMedicine,
          child: _isSaving
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...'),
                  ],
                )
              : const Text('Save to Catalogue'),
        ),
      ],
    );
  }

  Future<void> _saveMedicine() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    int? durationDays;
    if (_durationPreset == 'To continue (Chronic)') {
      durationDays = null;
    } else if (_durationPreset == 'Custom') {
      durationDays = int.tryParse(_customDurationCtrl.text.trim());
    } else {
      durationDays = int.tryParse(
        _durationPreset.replaceAll(' days', '').trim(),
      );
    }

    try {
      await Provider.of<ClinicProvider>(context, listen: false).addMedicine(
        productName: _brandCtrl.text.trim(),
        composition: _compCtrl.text.trim(),
        manufacturer: _mfgCtrl.text.trim().isNotEmpty
            ? _mfgCtrl.text.trim()
            : null,
        defaultDosage:
            _showRegimenDefaults && _dosageCtrl.text.trim().isNotEmpty
            ? _dosageCtrl.text.trim()
            : null,
        defaultFrequency: _showRegimenDefaults ? _frequency : null,
        defaultTiming: _showRegimenDefaults ? _timing : null,
        defaultDurationDays: _showRegimenDefaults ? durationDays : null,
        requestingRole: widget.currentRole,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
