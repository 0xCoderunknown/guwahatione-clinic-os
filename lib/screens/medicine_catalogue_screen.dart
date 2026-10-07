import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../providers/clinic_provider.dart';
import '../widgets/widgets.dart';

/// Master Medicine Catalogue management screen for commercial brands and decoupled molecules.
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
                // 1. Header with Stats and Add Button
                CatalogueHeaderAndStats(
                  totalProducts: allMeds.length,
                  totalMolecules: uniqueCompositions,
                  onCleanDuplicates: () => _handleDeduplicateCatalogue(context, auth.currentRole),
                  onAddProduct: () => _openAddMedicineDialog(context, auth.currentRole),
                ),
                const SizedBox(height: 20),

                // 2. Search & Filter Toolbar
                CatalogueSearchToolbar(
                  searchController: _searchController,
                  selectedFormFilter: _selectedFormFilter,
                  formOptions: _formOptions,
                  onFormFilterChanged: (val) {
                    if (val != null) setState(() => _selectedFormFilter = val);
                  },
                  onSearchChanged: (_) => setState(() {}),
                  onClearSearch: () => setState(() => _searchController.clear()),
                ),
                const SizedBox(height: 16),

                // 3. Medicine Catalogue List or Empty State
                if (filtered.isEmpty)
                  CatalogueEmptyState(
                    onClearFilter: () {
                      setState(() {
                        _searchController.clear();
                        _selectedFormFilter = 'All';
                      });
                    },
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return CatalogueMedicineCard(
                        item: item,
                        onDelete: () => _confirmDeleteMedicine(context, item, auth.currentRole),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAddMedicineDialog(BuildContext context, UserRole? currentRole) {
    showDialog(
      context: context,
      builder: (ctx) => AddMedicineDialog(currentRole: currentRole),
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

  void _handleDeduplicateCatalogue(BuildContext context, UserRole? currentRole) async {
    final clinic = Provider.of<ClinicProvider>(context, listen: false);
    try {
      final purgedCount = await clinic.deduplicateMedicines(requestingRole: currentRole);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              purgedCount > 0
                  ? 'Successfully removed $purgedCount duplicate medicine entries!'
                  : 'Catalogue is clean! No duplicate medicines found.',
            ),
            backgroundColor: Colors.teal.shade800,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deduplicating catalogue: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
