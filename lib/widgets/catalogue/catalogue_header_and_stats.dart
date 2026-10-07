import 'package:flutter/material.dart';

/// Top header banner with catalogue description, live product/molecule counts, and action buttons.
class CatalogueHeaderAndStats extends StatelessWidget {
  final int totalProducts;
  final int totalMolecules;
  final VoidCallback onCleanDuplicates;
  final VoidCallback onAddProduct;

  const CatalogueHeaderAndStats({
    super.key,
    required this.totalProducts,
    required this.totalMolecules,
    required this.onCleanDuplicates,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Products Count Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  "$totalProducts",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                Text("Products", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Unique Molecules Count Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  "$totalMolecules",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800),
                ),
                Text("Molecules", style: TextStyle(fontSize: 11, color: Colors.teal.shade700)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal.shade800,
              side: BorderSide(color: Colors.teal.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            icon: const Icon(Icons.cleaning_services_outlined, size: 18),
            label: const Text('Clean Duplicates', style: TextStyle(fontWeight: FontWeight.w600)),
            onPressed: onCleanDuplicates,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: onAddProduct,
          ),
        ],
      ),
    );
  }
}
