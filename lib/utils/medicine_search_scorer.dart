import '../models/medicine.dart';

class CompositionGroupResult {
  final String compositionLabel; // e.g., 'Paracetamol 650 mg'
  final String composition; // e.g., 'Paracetamol'
  final String strength; // e.g., '650 mg'
  final String form; // e.g., 'Tablet'
  final List<Medicine> associatedBrands; // e.g., [Dolo 650, Calpol 650]
  final int score;
  final bool isCompositionMatch;

  const CompositionGroupResult({
    required this.compositionLabel,
    required this.composition,
    required this.strength,
    required this.form,
    required this.associatedBrands,
    required this.score,
    required this.isCompositionMatch,
  });
}

class MedicineSearchScorer {
  /// Scores and groups catalogue medicines prioritizing chemical composition first,
  /// followed by commercial trade brands.
  static List<CompositionGroupResult> searchAndGroup({
    required List<Medicine> catalog,
    required String query,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      // Group all by composition
      return _groupByComposition(catalog, defaultScore: 0);
    }

    // Map each medicine to its match score
    final Map<String, List<Medicine>> groupedByComp = {};
    final Map<String, int> groupScores = {};
    final Map<String, bool> groupIsCompMatch = {};

    for (final med in catalog) {
      final compLower = med.composition.toLowerCase();
      final strengthLower = med.strength.toLowerCase();
      final fullCompLower = '${med.composition} ${med.strength}'.toLowerCase();
      final brandLower = med.productName.toLowerCase();

      int score = 0;
      bool isCompMatch = false;

      // Composition matches have highest priority (80 - 100)
      if (fullCompLower.startsWith(cleanQuery) || compLower.startsWith(cleanQuery)) {
        score = 100;
        isCompMatch = true;
      } else if (fullCompLower.contains(cleanQuery) ||
          compLower.contains(cleanQuery) ||
          strengthLower.contains(cleanQuery)) {
        score = 80;
        isCompMatch = true;
      } else if (brandLower.startsWith(cleanQuery)) {
        // Trade brand prefix match (60)
        score = 60;
      } else if (brandLower.contains(cleanQuery)) {
        // Trade brand substring match (40)
        score = 40;
      }

      if (score > 0) {
        final groupKey = '${med.composition.trim()}__${med.strength.trim()}__${med.form.trim()}';
        groupedByComp.putIfAbsent(groupKey, () => []).add(med);

        final currentMax = groupScores[groupKey] ?? 0;
        if (score > currentMax) {
          groupScores[groupKey] = score;
        }
        if (isCompMatch) {
          groupIsCompMatch[groupKey] = true;
        }
      }
    }

    final List<CompositionGroupResult> results = [];
    for (final entry in groupedByComp.entries) {
      final meds = entry.value;
      final first = meds.first;
      final key = entry.key;

      results.add(
        CompositionGroupResult(
          compositionLabel: first.fullCompositionLabel,
          composition: first.composition,
          strength: first.strength,
          form: first.form,
          associatedBrands: meds,
          score: groupScores[key] ?? 0,
          isCompositionMatch: groupIsCompMatch[key] ?? false,
        ),
      );
    }

    // Sort: highest score first; if tied, composition matches first, then alphabetically
    results.sort((a, b) {
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }
      if (b.isCompositionMatch != a.isCompositionMatch) {
        return b.isCompositionMatch ? 1 : -1;
      }
      return a.compositionLabel.compareTo(b.compositionLabel);
    });

    return results;
  }

  static List<CompositionGroupResult> _groupByComposition(
    List<Medicine> catalog, {
    required int defaultScore,
  }) {
    final Map<String, List<Medicine>> grouped = {};
    for (final med in catalog) {
      final key = '${med.composition.trim()}__${med.strength.trim()}__${med.form.trim()}';
      grouped.putIfAbsent(key, () => []).add(med);
    }

    return grouped.entries.map((e) {
      final first = e.value.first;
      return CompositionGroupResult(
        compositionLabel: first.fullCompositionLabel,
        composition: first.composition,
        strength: first.strength,
        form: first.form,
        associatedBrands: e.value,
        score: defaultScore,
        isCompositionMatch: false,
      );
    }).toList();
  }
}
