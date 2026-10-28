import 'package:flutter/material.dart';
import '../services/age_difficulty.dart';

/// Small pill telling parents the game is tuned to the child's age.
class AgeModeChip extends StatelessWidget {
  final Color color;

  const AgeModeChip({super.key, this.color = const Color(0xFF92400E)});

  @override
  Widget build(BuildContext context) {
    final age = AgeDifficulty.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.child_care_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${age.label} · disesuaikan umur ${age.age} th',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
