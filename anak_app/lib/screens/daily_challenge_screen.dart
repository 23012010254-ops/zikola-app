import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/daily_challenge.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final int streak = appState.currentStreak;
    final int currentXP = appState.totalXP % 100;
    const int levelXP = 100;
    final int currentLevel = appState.currentLevel;
    
    final String childName = appState.childProfile.name.isNotEmpty
        ? appState.childProfile.name
        : 'Anak';

    final List<_ChallengeData> challenges = appState.todayChallenges.map((c) {
      Color color = const Color(0xFF3B82F6); // Blue fallback
      if (c.type == ChallengeType.completeTest) {
        color = const Color(0xFF8B5CF6); // Purple
      } else if (c.type == ChallengeType.earnSticker) {
        color = const Color(0xFFF97316); // Orange
      } else if (c.type == ChallengeType.viewProgress) {
        color = const Color(0xFF10B981); // Green
      } else if (c.type == ChallengeType.playMinutes) {
        color = const Color(0xFFEC4899); // Pink
      }

      return _ChallengeData(
        emoji: c.emoji,
        title: c.title,
        current: c.progress,
        target: c.target,
        reward: '+${c.xpReward} XP',
        color: color,
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Misi Hari Ini 🎯'),
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Hai, $childName! 👋',
              style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Selesaikan misi harian untuk mendapatkan XP!',
              style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),

            // Streak card
            _StreakCard(streak: streak),
            const SizedBox(height: 24),

            // Section title
            Text(
              'Misi Hari Ini',
              style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            // Challenge cards
            ...challenges.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChallengeCard(challenge: c),
                )),

            const SizedBox(height: 24),

            // XP Level progress
            _XPProgressCard(
              currentXP: currentXP,
              levelXP: levelXP,
              currentLevel: currentLevel,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak Card
// ---------------------------------------------------------------------------
class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFFB923C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak Harian',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$streak hari berturut-turut!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🔥 $streak',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Challenge Card
// ---------------------------------------------------------------------------
class _ChallengeData {
  final String emoji;
  final String title;
  final int current;
  final int target;
  final String reward;
  final Color color;

  const _ChallengeData({
    required this.emoji,
    required this.title,
    required this.current,
    required this.target,
    required this.reward,
    required this.color,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0;
  bool get isComplete => current >= target;
}

class _ChallengeCard extends StatelessWidget {
  final _ChallengeData challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final bool done = challenge.isComplete;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done ? challenge.color.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? challenge.color.withOpacity(0.3) : AppTheme.gray200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Emoji / check icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: done
                  ? challenge.color.withOpacity(0.15)
                  : challenge.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: done
                ? Icon(Icons.check_circle, color: challenge.color, size: 28)
                : Text(challenge.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          color: done
                              ? challenge.color
                              : AppTheme.textPrimary,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: challenge.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        challenge.reward,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          color: challenge.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: challenge.progress,
                          minHeight: 8,
                          backgroundColor: AppTheme.gray200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(challenge.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${challenge.current}/${challenge.target}',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        color: done ? challenge.color : AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// XP Progress Card
// ---------------------------------------------------------------------------
class _XPProgressCard extends StatelessWidget {
  final int currentXP;
  final int levelXP;
  final int currentLevel;

  const _XPProgressCard({
    required this.currentXP,
    required this.levelXP,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final double progress =
        levelXP > 0 ? (currentXP / levelXP).clamp(0.0, 1.0) : 0;
    final int remaining = (levelXP - currentXP).clamp(0, levelXP);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Level $currentLevel',
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '$currentXP / $levelXP XP',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            '$remaining XP lagi menuju Level ${currentLevel + 1}',
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
