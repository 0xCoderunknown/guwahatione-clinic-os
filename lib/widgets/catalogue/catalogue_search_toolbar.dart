import 'package:flutter/material.dart';

/// Search input and dosage form dropdown filter toolbar.
/// Responsive across mobile (stacked column) and desktop (single row).
class CatalogueSearchToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedFormFilter;
  final List<String> formOptions;
  final ValueChanged<String?> onFormFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const CatalogueSearchToolbar({
    super.key,
    required this.searchController,
    required this.selectedFormFilter,
    required this.formOptions,
    required this.onFormFilterChanged,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  Widget _buildSearchField({bool isMobile = false}) {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: isMobile ? 'Search molecule or brand...' : 'Search by chemical molecule (e.g. Paracetamol) or trade brand (e.g. Dolo 650)...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClearSearch,
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
      onChanged: onSearchChanged,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      initialValue: selectedFormFilter,
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
      items: formOptions
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: onFormFilterChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchField(isMobile: true),
              const SizedBox(height: 10),
              _buildDropdownField(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: _buildSearchField(isMobile: false)),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: _buildDropdownField()),
          ],
        );
      },
    );
  }
}
