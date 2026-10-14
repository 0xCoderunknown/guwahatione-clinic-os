import 'package:flutter/material.dart';

/// Top header banner with catalogue description, live product/molecule counts, and action buttons.
/// Responsively adapts across Mobile (<560px), Tablet (560-800px), and Desktop (>800px).
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

  Widget _buildIconBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.medication_rounded,
        size: 26,
        color: Colors.teal.shade700,
      ),
    );
  }

  Widget _buildTitleText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medicine Catalogue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Curate commercial trade brands and decoupled chemical compositions. Doctors consume this read-only.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProductPill({bool centerText = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centerText
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.center,
        children: [
          Text(
            "$totalProducts",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            "Products",
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMoleculePill({bool centerText = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centerText
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.center,
        children: [
          Text(
            "$totalMolecules",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.teal.shade800,
            ),
          ),
          Text(
            "Molecules",
            style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanDuplicatesButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.teal.shade800,
        side: BorderSide(color: Colors.teal.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
      icon: const Icon(Icons.cleaning_services_outlined, size: 18),
      label: const Text(
        'Remove Duplicate Entries',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      onPressed: onCleanDuplicates,
    );
  }

  Widget _buildAddProductButton() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.teal.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'Add Product',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      onPressed: onAddProduct,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 800;
        final isMobile = constraints.maxWidth < 560;

        if (isCompact) {
          return Container(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Icon and Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconBadge(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTitleText()),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. Metric Pills side-by-side
                Row(
                  children: [
                    Expanded(child: _buildProductPill(centerText: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMoleculePill(centerText: true)),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Actions
                if (isMobile) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCleanDuplicatesButton(),
                      const SizedBox(height: 8),
                      _buildAddProductButton(),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _buildCleanDuplicatesButton()),
                      const SizedBox(width: 10),
                      Expanded(child: _buildAddProductButton()),
                    ],
                  ),
                ],
              ],
            ),
          );
        }

        // Wide desktop layout
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
              _buildIconBadge(),
              const SizedBox(width: 16),
              Expanded(child: _buildTitleText()),
              const SizedBox(width: 16),
              _buildProductPill(),
              const SizedBox(width: 8),
              _buildMoleculePill(),
              const SizedBox(width: 16),
              _buildCleanDuplicatesButton(),
              const SizedBox(width: 8),
              _buildAddProductButton(),
            ],
          ),
        );
      },
    );
  }
}
