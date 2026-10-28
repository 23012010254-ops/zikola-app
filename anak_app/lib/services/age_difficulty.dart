import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

/// Coarse developmental bands used to tune game difficulty to the child.
enum AgeBand { toddler, preschool, school }

/// Picks game parameters for the active child's age, so a 3-year-old and an
/// 8-year-old don't get the same puzzle.
class AgeDifficulty {
  final int age;
  final AgeBand band;

  AgeDifficulty(this.age)
      : band = age <= 4
            ? AgeBand.toddler
            : age <= 6
                ? AgeBand.preschool
                : AgeBand.school;

  /// Reads the active child's age without subscribing to rebuilds.
  factory AgeDifficulty.of(BuildContext context) =>
      AgeDifficulty(context.read<AppState>().childProfile.age);

  T pick<T>({required T toddler, required T preschool, required T school}) {
    switch (band) {
      case AgeBand.toddler:
        return toddler;
      case AgeBand.preschool:
        return preschool;
      case AgeBand.school:
        return school;
    }
  }

  /// Short label for a "tuned for" chip, e.g. "Mode 5–6 tahun".
  String get label => pick(
        toddler: 'Mode 2–4 tahun',
        preschool: 'Mode 5–6 tahun',
        school: 'Mode 7+ tahun',
      );
}
