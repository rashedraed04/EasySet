import 'dart:math';
import '../models/exercise.dart';

/// Detects personal records. An entry is a PR when, compared with everything
/// logged before it for the same exercise, it lifts more weight OR has a higher
/// estimated one-rep max. The very first entry is the baseline, not a PR.
class PrService {
  /// [entries] must all be for the same exercise. Returns the ids of PR entries.
  static Set<String> personalRecordIds(Iterable<Exercise> entries) {
    final sorted = entries.toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    const epsilon = 1e-9;
    final ids = <String>{};
    double bestWeight = 0;
    double bestOneRepMax = 0;
    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      final beatsWeight = e.weight > bestWeight + epsilon;
      final beatsOneRepMax = e.oneRepMax > bestOneRepMax + epsilon;
      if (i > 0 && (beatsWeight || beatsOneRepMax)) ids.add(e.id);
      bestWeight = max(bestWeight, e.weight);
      bestOneRepMax = max(bestOneRepMax, e.oneRepMax);
    }
    return ids;
  }

  /// Whether [candidate] is a PR given the other [history] for that exercise.
  static bool isPersonalRecord(Exercise candidate, Iterable<Exercise> history) {
    final others = history.where((e) => e.id != candidate.id && e.name == candidate.name);
    return personalRecordIds([...others, candidate]).contains(candidate.id);
  }
}
