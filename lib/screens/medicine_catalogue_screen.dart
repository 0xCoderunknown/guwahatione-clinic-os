import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';

class MedicineCatalogueScreen extends StatefulWidget {
  const MedicineCatalogueScreen({super.key});

  @override
  State<MedicineCatalogueScreen> createState() => _MedicineCatalogueScreenState();
}

class _MedicineCatalogueScreenState extends State<MedicineCatalogueScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFormFilter = 'All';

  final List<String> _formOptions = [
    'All',
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Drops',
    'Ointment',
    'Inhaler',
    'Suspension',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinic = Provider.of<ClinicProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    final query = _searchController.text.trim().toLowerCase();
    final allMeds = clinic.medicines;

    final filtered = allMeds.where((m) {
      final matchesQuery = query.isEmpty ||
          m.productName.toLowerCase().contains(query) ||
          m.composition.toLowerCase().contains(query) ||
          m.strength.toLowerCase().contains(query);

      final matchesForm = _selectedFormFilter == 'All' || m.form == _selectedFormFilter;

      return matchesQuery && matchesForm;
    }).toList();

    // Sort alphabetically by composition, then product name
    filtered.sort((a, b) {
      final compCmp = a.composition.compareTo(b.composition);
      if (compCmp != 0) return compCmp;
      return a.productName.compareTo(b.productName);
    });

    final uniqueCompositions = allMeds.map((m) => m.composition.trim().toLowerCase()).toSet().length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header with Stats and Add Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.medication_rounded, size: 28, color: Colors.teal.shade700),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Master Medicine Catalogue',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Curate commercial trade brands and decoupled chemical compositions. Doctors consume this read-only.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Stats Pills
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${allMeds.length}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            Text("Products", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "$uniqueCompositions",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800),
                            ),
                            Text("Molecules", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _openAddMedicineDialog(context, auth.currentRole),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Search & Filter Toolbar
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by chemical molecule (e.g. Paracetamol) or trade brand (e.g. Dolo 650)...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedFormFilter,
                        decoration: InputDecoration(
                          labelText: 'Dosage Form',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: _formOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFormFilter = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Medicine Catalogue List
                if (filtered.isEmpty)
                  _buildEmptyState(context, auth.currentRole)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return _buildMedicineCard(context, item, auth.currentRole);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(BuildContext context, Medicine item, UserRole? currentRole) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dosage Form Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Text(
              item.form,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Trade Name & Decoupled Composition
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.manufacturer != null && item.manufacturer!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.manufacturer!,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Composition: ${item.composition} • Strength: ${item.strength}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Delete Action
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            tooltip: 'Remove from Catalogue',
            onPressed: () => _confirmDeleteMedicine(context, item, currentRole),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, UserRole? currentRole) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 54, color: Colors.teal.shade200),
          const SizedBox(height: 16),
          const Text(
            'No medicines match the selected filter',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Text(
            'Add commercial products and composition mappings to curate your clinic catalog.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => _seedSampleCatalogue(context, currentRole),
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Seed Essential OPD Medications'),
          ),
        ],
      ),
    );
  }

  void _openAddMedicineDialog(BuildContext context, UserRole? currentRole) {
    final formKey = GlobalKey<FormState>();
    final brandCtrl = TextEditingController();
    final compCtrl = TextEditingController();
    final strengthCtrl = TextEditingController(text: '500 mg');
    final mfgCtrl = TextEditingController();
    String form = 'Tablet';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Text('Add Master Medicine Entry'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: brandCtrl,
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
                      controller: compCtrl,
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
                            controller: strengthCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Strength',
                              hintText: 'e.g., 650 mg, 500 mg / 5 ml',
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Strength is required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: form,
                            decoration: const InputDecoration(
                              labelText: 'Form',
                              border: OutlineInputBorder(),
                            ),
                            items: _formOptions
                                .where((f) => f != 'All')
                                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => form = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: mfgCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer / Brand Maker (Optional)',
                        hintText: 'e.g., Micro Labs, Cipla, Sun Pharma, GSK',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await Provider.of<ClinicProvider>(context, listen: false).addMedicine(
                    productName: brandCtrl.text.trim(),
                    composition: compCtrl.text.trim(),
                    strength: strengthCtrl.text.trim(),
                    form: form,
                    manufacturer: mfgCtrl.text.trim().isNotEmpty ? mfgCtrl.text.trim() : null,
                    requestingRole: currentRole,
                  );
                  if (dialogCtx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save to Catalogue'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMedicine(BuildContext context, Medicine item, UserRole? currentRole) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${item.productName}?'),
        content: Text(
          'Are you sure you want to remove "${item.displayName}" from the master catalogue?\n(Past consultations referencing this drug will remain unaffected).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Provider.of<ClinicProvider>(context, listen: false).deleteMedicine(
                  item.id,
                  requestingRole: currentRole,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _seedSampleCatalogue(BuildContext context, UserRole? currentRole) async {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);

    final samples = [
      {'name': 'Dolo 650', 'comp': 'Paracetamol', 'strength': '650 mg', 'form': 'Tablet', 'mfg': 'Micro Labs'},
      {'name': 'Calpol 650', 'comp': 'Paracetamol', 'strength': '650 mg', 'form': 'Tablet', 'mfg': 'GSK'},
      {'name': 'Crocin 500', 'comp': 'Paracetamol', 'strength': '500 mg', 'form': 'Tablet', 'mfg': 'GSK'},
      {'name': 'Augmentin 625 Duo', 'comp': 'Amoxicillin + Clavulanic Acid', 'strength': '625 mg', 'form': 'Tablet', 'mfg': 'GSK'},
      {'name': 'Moxikind-CV 625', 'comp': 'Amoxicillin + Clavulanic Acid', 'strength': '625 mg', 'form': 'Tablet', 'mfg': 'Mankind'},
      {'name': 'Azee 500', 'comp': 'Azithromycin', 'strength': '500 mg', 'form': 'Tablet', 'mfg': 'Cipla'},
      {'name': 'Azithral 500', 'comp': 'Azithromycin', 'strength': '500 mg', 'form': 'Tablet', 'mfg': 'Alembic'},
      {'name': 'Glycomet 500', 'comp': 'Metformin', 'strength': '500 mg', 'form': 'Tablet', 'mfg': 'USV'},
      {'name': 'Pan 40', 'comp': 'Pantoprazole', 'strength': '40 mg', 'form': 'Tablet', 'mfg': 'Alkem'},
      {'name': 'Telma 40', 'comp': 'Telmisartan', 'strength': '40 mg', 'form': 'Tablet', 'mfg': 'Glenmark'},
    ];

    for (final s in samples) {
      await clinic.addMedicine(
        productName: s['name']!,
        composition: s['comp']!,
        strength: s['strength']!,
        form: s['form']!,
        manufacturer: s['mfg']!,
        requestingRole: currentRole,
      );
    }
  }
}
