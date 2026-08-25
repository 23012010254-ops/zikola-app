import 'dart:math';

enum ChallengeType {
  playGame,
  completeTest,
  earnSticker,
  viewProgress,
  playMinutes,
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeType type;
  final int target;
  int progress;
  final int xpReward;
  bool isCompleted;
  final DateTime date;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
    required this.target,
    this.progress = 0,
    required this.xpReward,
    this.isCompleted = false,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'emoji': emoji,
      'type': type.name,
      'target': target,
      'progress': progress,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String,
      type: ChallengeType.values.byName(json['type'] as String),
      target: json['target'] as int,
      progress: json['progress'] as int? ?? 0,
      xpReward: json['xpReward'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      date: DateTime.parse(json['date'] as String),
    );
  }

  static List<DailyChallenge> generateDailyChallenges(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    // Use a seed derived from the date so the same day always generates the same challenges
    final seed = normalizedDate.year * 10000 + normalizedDate.month * 100 + normalizedDate.day;
    final random = Random(seed);

    final List<DailyChallenge> pool = [
      DailyChallenge(
        id: 'play_2_games',
        title: 'Bermain 2 Game',
        description: 'Mainkan game apa saja sebanyak 2 kali',
        emoji: '🎮',
        type: ChallengeType.playGame,
        target: 2,
        xpReward: 50,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'complete_1_test',
        title: 'Selesaikan 1 Tes',
        description: 'Selesaikan 1 tes perkembangan anak',
        emoji: '📊',
        type: ChallengeType.completeTest,
        target: 1,
        xpReward: 100,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'earn_1_sticker',
        title: 'Kumpulkan 1 Stiker',
        description: 'Dapatkan stiker baru hari ini',
        emoji: '✨',
        type: ChallengeType.earnSticker,
        target: 1,
        xpReward: 70,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'view_progress',
        title: 'Pantau Perkembangan',
        description: 'Buka menu Progres untuk melihat grafik',
        emoji: '📈',
        type: ChallengeType.viewProgress,
        target: 1,
        xpReward: 30,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'play_15_minutes',
        title: 'Bermain 15 Menit',
        description: 'Habiskan 15 menit bermain game edukatif',
        emoji: '⏱️',
        type: ChallengeType.playMinutes,
        target: 15,
        xpReward: 60,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'play_3_games',
        title: 'Super Gamer',
        description: 'Mainkan game apa saja sebanyak 3 kali',
        emoji: '⚡',
        type: ChallengeType.playGame,
        target: 3,
        xpReward: 80,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'complete_cognitive',
        title: 'Latih Kognitif',
        description: 'Selesaikan tes perkembangan kognitif',
        emoji: '🧠',
        type: ChallengeType.completeTest,
        target: 1,
        xpReward: 100,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'complete_linguistic',
        title: 'Asah Bahasa',
        description: 'Selesaikan tes perkembangan linguistik',
        emoji: '🗣️',
        type: ChallengeType.completeTest,
        target: 1,
        xpReward: 100,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'complete_motoric',
        title: 'Latih Motorik',
        description: 'Selesaikan tes perkembangan motorik',
        emoji: '✋',
        type: ChallengeType.completeTest,
        target: 1,
        xpReward: 100,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'play_memory_game',
        title: 'Main Memory Game',
        description: 'Bermain game memori gambar atau angka',
        emoji: '🧩',
        type: ChallengeType.playGame,
        target: 1,
        xpReward: 40,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'play_coloring_game',
        title: 'Mari Mewarnai',
        description: 'Bermain coloring game bersama anak',
        emoji: '🎨',
        type: ChallengeType.playGame,
        target: 1,
        xpReward: 40,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'visit_community',
        title: 'Sapa Komunitas',
        description: 'Buka menu Komunitas untuk melihat forum',
        emoji: '💬',
        type: ChallengeType.viewProgress,
        target: 1,
        xpReward: 25,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'play_20_minutes',
        title: 'Bermain 20 Menit',
        description: 'Habiskan 20 menit bermain game edukatif',
        emoji: '⏳',
        type: ChallengeType.playMinutes,
        target: 20,
        xpReward: 80,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'earn_2_stickers',
        title: 'Kolektor Stiker',
        description: 'Dapatkan 2 stiker baru hari ini',
        emoji: '🦄',
        type: ChallengeType.earnSticker,
        target: 2,
        xpReward: 120,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'complete_personality',
        title: 'Kenali Kepribadian',
        description: 'Selesaikan tes perkembangan kepribadian',
        emoji: '🎭',
        type: ChallengeType.completeTest,
        target: 1,
        xpReward: 120,
        date: normalizedDate,
      ),
      DailyChallenge(
        id: 'play_1_game',
        title: 'Bermain Sejenak',
        description: 'Mainkan 1 game edukasi apa saja',
        emoji: '🧸',
        type: ChallengeType.playGame,
        target: 1,
        xpReward: 30,
        date: normalizedDate,
      ),
    ];

    // Select 3 random challenges from the pool using the seeded Random instance
    final List<DailyChallenge> selected = [];
    final Set<int> chosenIndices = {};

    while (selected.length < 3 && selected.length < pool.length) {
      final index = random.nextInt(pool.length);
      if (!chosenIndices.contains(index)) {
        chosenIndices.add(index);
        selected.add(pool[index]);
      }
    }

    return selected;
  }
}
