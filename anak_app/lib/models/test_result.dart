class TestResults {
  TestScoreResult cognitive;
  TestScoreResult linguistic;
  PersonalityResult personality;
  MotorResult motor;

  TestResults({
    TestScoreResult? cognitive,
    TestScoreResult? linguistic,
    PersonalityResult? personality,
    MotorResult? motor,
  })  : cognitive = cognitive ?? TestScoreResult(),
        linguistic = linguistic ?? TestScoreResult(),
        personality = personality ?? PersonalityResult(),
        motor = motor ?? MotorResult();

  TestResults copyWith({
    TestScoreResult? cognitive,
    TestScoreResult? linguistic,
    PersonalityResult? personality,
    MotorResult? motor,
  }) {
    return TestResults(
      cognitive: cognitive ?? this.cognitive,
      linguistic: linguistic ?? this.linguistic,
      personality: personality ?? this.personality,
      motor: motor ?? this.motor,
    );
  }

  factory TestResults.fromJson(Map<String, dynamic> json) {
    return TestResults(
      cognitive: json['cognitive'] != null ? TestScoreResult.fromJson(json['cognitive']) : null,
      linguistic: json['linguistic'] != null ? TestScoreResult.fromJson(json['linguistic']) : null,
      personality: json['personality'] != null ? PersonalityResult.fromJson(json['personality']) : null,
      motor: json['motor'] != null ? MotorResult.fromJson(json['motor']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cognitive': cognitive.toJson(),
      'linguistic': linguistic.toJson(),
      'personality': personality.toJson(),
      'motor': motor.toJson(),
    };
  }
}

/// Hasil skor tes untuk domain Kognitif dan Linguistik.
/// Field CHC subdomain ([fluidReasoningScore], [workingMemoryScore], dll.)
/// diisi oleh [AssessmentEngine] setelah anak menyelesaikan beberapa game.
class TestScoreResult {
  bool completed;
  int score;
  int total;
  double percentage;
  String? completedDate;
  int timeSpent;

  // ── Skor Sub-domain CHC ──────────────────────────────────────────────────
  /// Fluid Reasoning (Gf) — penalaran logis, analitis.
  double? fluidReasoningScore;

  /// Working Memory (Gwm) — memori kerja, manipulasi informasi aktif.
  double? workingMemoryScore;

  /// Processing Speed (Gs) — kecepatan pemrosesan informasi.
  double? processingSpeedScore;

  /// Visual Processing (Gv) — kemampuan spasial dan visual.
  double? visualProcessingScore;

  /// Short-Term Memory (Gsm) — kapasitas memori jangka pendek.
  double? shortTermMemoryScore;

  /// Crystallized Knowledge (Gc) — kosakata & pengetahuan bahasa.
  double? crystallizedKnowledgeScore;

  /// Data breakdown per game yang berkontribusi ke domain ini.
  Map<String, dynamic>? gameBreakdown;

  TestScoreResult({
    this.completed = false,
    this.score = 0,
    this.total = 10,
    this.percentage = 0,
    this.completedDate,
    this.timeSpent = 0,
    this.fluidReasoningScore,
    this.workingMemoryScore,
    this.processingSpeedScore,
    this.visualProcessingScore,
    this.shortTermMemoryScore,
    this.crystallizedKnowledgeScore,
    this.gameBreakdown,
  });

  TestScoreResult copyWith({
    bool? completed,
    int? score,
    int? total,
    double? percentage,
    String? completedDate,
    int? timeSpent,
    double? fluidReasoningScore,
    double? workingMemoryScore,
    double? processingSpeedScore,
    double? visualProcessingScore,
    double? shortTermMemoryScore,
    double? crystallizedKnowledgeScore,
    Map<String, dynamic>? gameBreakdown,
  }) {
    return TestScoreResult(
      completed: completed ?? this.completed,
      score: score ?? this.score,
      total: total ?? this.total,
      percentage: percentage ?? this.percentage,
      completedDate: completedDate ?? this.completedDate,
      timeSpent: timeSpent ?? this.timeSpent,
      fluidReasoningScore: fluidReasoningScore ?? this.fluidReasoningScore,
      workingMemoryScore: workingMemoryScore ?? this.workingMemoryScore,
      processingSpeedScore: processingSpeedScore ?? this.processingSpeedScore,
      visualProcessingScore: visualProcessingScore ?? this.visualProcessingScore,
      shortTermMemoryScore: shortTermMemoryScore ?? this.shortTermMemoryScore,
      crystallizedKnowledgeScore: crystallizedKnowledgeScore ?? this.crystallizedKnowledgeScore,
      gameBreakdown: gameBreakdown ?? this.gameBreakdown,
    );
  }

  factory TestScoreResult.fromJson(Map<String, dynamic> json) {
    return TestScoreResult(
      completed: json['completed'] as bool? ?? false,
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 10,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      completedDate: json['completedDate'] as String?,
      timeSpent: json['timeSpent'] as int? ?? 0,
      fluidReasoningScore: (json['fluidReasoningScore'] as num?)?.toDouble(),
      workingMemoryScore: (json['workingMemoryScore'] as num?)?.toDouble(),
      processingSpeedScore: (json['processingSpeedScore'] as num?)?.toDouble(),
      visualProcessingScore: (json['visualProcessingScore'] as num?)?.toDouble(),
      shortTermMemoryScore: (json['shortTermMemoryScore'] as num?)?.toDouble(),
      crystallizedKnowledgeScore: (json['crystallizedKnowledgeScore'] as num?)?.toDouble(),
      gameBreakdown: json['gameBreakdown'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'score': score,
      'total': total,
      'percentage': percentage,
      'completedDate': completedDate,
      'timeSpent': timeSpent,
      if (fluidReasoningScore != null) 'fluidReasoningScore': fluidReasoningScore,
      if (workingMemoryScore != null) 'workingMemoryScore': workingMemoryScore,
      if (processingSpeedScore != null) 'processingSpeedScore': processingSpeedScore,
      if (visualProcessingScore != null) 'visualProcessingScore': visualProcessingScore,
      if (shortTermMemoryScore != null) 'shortTermMemoryScore': shortTermMemoryScore,
      if (crystallizedKnowledgeScore != null) 'crystallizedKnowledgeScore': crystallizedKnowledgeScore,
      if (gameBreakdown != null) 'gameBreakdown': gameBreakdown,
    };
  }
}

class PersonalityResult {
  bool completed;
  String? type;
  String? animal;
  String? animalEmoji;
  String? personality;
  String? description;
  String? completedDate;
  List<String> traits;
  int? socialScore;
  int? emotionalScore;
  int? characterScore;
  /// Konsistensi jawaban (0.0 - 1.0). Rendah = jawaban tidak konsisten / random.
  double? responseConsistency;

  PersonalityResult({
    this.completed = false,
    this.type,
    this.animal,
    this.animalEmoji,
    this.personality,
    this.description,
    this.completedDate,
    this.traits = const [],
    this.socialScore,
    this.emotionalScore,
    this.characterScore,
    this.responseConsistency,
  });

  factory PersonalityResult.fromJson(Map<String, dynamic> json) {
    return PersonalityResult(
      completed: json['completed'] as bool? ?? false,
      type: json['type'] as String?,
      animal: json['animal'] as String?,
      animalEmoji: json['animalEmoji'] as String?,
      personality: json['personality'] as String?,
      description: json['description'] as String?,
      completedDate: json['completedDate'] as String?,
      traits: (json['traits'] as List?)?.map((e) => e as String).toList() ?? const [],
      socialScore: json['socialScore'] as int?,
      emotionalScore: json['emotionalScore'] as int?,
      characterScore: json['characterScore'] as int?,
      responseConsistency: (json['responseConsistency'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'type': type,
      'animal': animal,
      'animalEmoji': animalEmoji,
      'personality': personality,
      'description': description,
      'completedDate': completedDate,
      'traits': traits,
      'socialScore': socialScore,
      'emotionalScore': emotionalScore,
      'characterScore': characterScore,
      if (responseConsistency != null) 'responseConsistency': responseConsistency,
    };
  }
}

class MotorResult {
  bool completed;
  int score;
  int total;
  double percentage;
  String? completedDate;
  int livesRemaining;
  int timeSpent;

  MotorResult({
    this.completed = false,
    this.score = 0,
    this.total = 10,
    this.percentage = 0,
    this.completedDate,
    this.livesRemaining = 3,
    this.timeSpent = 0,
  });

  factory MotorResult.fromJson(Map<String, dynamic> json) {
    return MotorResult(
      completed: json['completed'] as bool? ?? false,
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 10,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      completedDate: json['completedDate'] as String?,
      livesRemaining: json['livesRemaining'] as int? ?? 3,
      timeSpent: json['timeSpent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'score': score,
      'total': total,
      'percentage': percentage,
      'completedDate': completedDate,
      'livesRemaining': livesRemaining,
      'timeSpent': timeSpent,
    };
  }
}
