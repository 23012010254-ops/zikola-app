/// Merepresentasikan satu sesi bermain game dengan metrik asesmen granular.
/// Field tambahan ([correctAnswers], [avgResponseTimeMs], dll.) digunakan oleh
/// [AssessmentEngine] untuk menghitung skor CHC per konstruk.
class GameSession {
  final int score;
  final int timeSpent;
  final int errors;
  final int totalItems;
  final String date;

  // ── Metrik Asesmen Granular ──────────────────────────────────────────────
  /// Jumlah jawaban benar dalam sesi ini.
  final int correctAnswers;

  /// Rata-rata waktu respons per soal dalam milidetik.
  final int avgResponseTimeMs;

  /// Nilai median waktu respons per soal dalam milidetik.
  final int medianResponseTimeMs;

  /// Waktu respons tercepat per soal dalam milidetik.
  final int fastestResponseTimeMs;

  /// Waktu respons terlama per soal dalam milidetik.
  final int slowestResponseTimeMs;

  /// Kecepatan ideal mengerjakan soal (Items per minute).
  final double itemsPerMinute;

  /// Level tertinggi yang dicapai anak dalam sesi (jika game berjenjang).
  final int maxLevelReached;

  /// Jumlah hint/bantuan yang digunakan anak selama sesi.
  final int hintsUsed;

  /// Skor komposit asesmen (0-100) dihitung oleh AssessmentEngine.
  final double assessmentScore;

  /// Metrik detail spesifik per game (error by type, accuracy by category, dll.)
  /// Format bebas sesuai kebutuhan masing-masing game.
  final Map<String, dynamic>? detailedMetrics;

  /// Skor per sub-domain CHC dari game ini (mis. {'fluidReasoning': 75.0}).
  final Map<String, double>? subdomainScores;

  GameSession({
    required this.score,
    required this.timeSpent,
    required this.errors,
    this.totalItems = 0,
    this.correctAnswers = 0,
    this.avgResponseTimeMs = 0,
    this.medianResponseTimeMs = 0,
    this.fastestResponseTimeMs = 0,
    this.slowestResponseTimeMs = 0,
    this.itemsPerMinute = 0.0,
    this.maxLevelReached = 0,
    this.hintsUsed = 0,
    this.assessmentScore = 0.0,
    this.detailedMetrics,
    this.subdomainScores,
    String? date,
  }) : date = date ?? DateTime.now().toIso8601String();

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      score: json['score'] as int? ?? 0,
      timeSpent: json['timeSpent'] as int? ?? 0,
      errors: json['errors'] as int? ?? 0,
      totalItems: json['totalItems'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      avgResponseTimeMs: json['avgResponseTimeMs'] as int? ?? 0,
      medianResponseTimeMs: json['medianResponseTimeMs'] as int? ?? 0,
      fastestResponseTimeMs: json['fastestResponseTimeMs'] as int? ?? 0,
      slowestResponseTimeMs: json['slowestResponseTimeMs'] as int? ?? 0,
      itemsPerMinute: (json['itemsPerMinute'] as num?)?.toDouble() ?? 0.0,
      maxLevelReached: json['maxLevelReached'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      assessmentScore: (json['assessmentScore'] as num?)?.toDouble() ?? 0.0,
      detailedMetrics: json['detailedMetrics'] as Map<String, dynamic>?,
      subdomainScores: (json['subdomainScores'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      date: json['date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'timeSpent': timeSpent,
      'errors': errors,
      'totalItems': totalItems,
      'correctAnswers': correctAnswers,
      'avgResponseTimeMs': avgResponseTimeMs,
      'medianResponseTimeMs': medianResponseTimeMs,
      'fastestResponseTimeMs': fastestResponseTimeMs,
      'slowestResponseTimeMs': slowestResponseTimeMs,
      'itemsPerMinute': itemsPerMinute,
      'maxLevelReached': maxLevelReached,
      'hintsUsed': hintsUsed,
      'assessmentScore': assessmentScore,
      if (detailedMetrics != null) 'detailedMetrics': detailedMetrics,
      if (subdomainScores != null) 'subdomainScores': subdomainScores,
      'date': date,
    };
  }
}

class GameAssessment {
  int totalPlayed;
  int averageTime;
  double averageErrors;
  int averageScore;
  int bestScore;
  String difficulty;
  List<String> domains;
  String? lastPlayed;
  List<GameSession> sessions;

  GameAssessment({
    this.totalPlayed = 0,
    this.averageTime = 0,
    this.averageErrors = 0,
    this.averageScore = 0,
    this.bestScore = 0,
    this.difficulty = 'medium',
    this.domains = const [],
    this.lastPlayed,
    this.sessions = const [],
  });

  GameAssessment addSession(GameSession session) {
    final newSessions = [...sessions, session];
    final newTotalPlayed = totalPlayed + 1;

    final totalTime = newSessions.fold<int>(0, (sum, s) => sum + s.timeSpent);
    final totalErrors = newSessions.fold<int>(0, (sum, s) => sum + s.errors);
    final totalScore = newSessions.fold<int>(0, (sum, s) => sum + s.score);

    return GameAssessment(
      totalPlayed: newTotalPlayed,
      averageTime: (totalTime / newTotalPlayed).round(),
      averageErrors: double.parse(((totalErrors / newTotalPlayed) * 10).roundToDouble().toString()) / 10,
      averageScore: (totalScore / newTotalPlayed).round(),
      bestScore: session.score > bestScore ? session.score : bestScore,
      difficulty: difficulty,
      domains: domains,
      lastPlayed: DateTime.now().toIso8601String(),
      sessions: newSessions.length > 10 ? newSessions.sublist(newSessions.length - 10) : newSessions,
    );
  }

  factory GameAssessment.fromJson(Map<String, dynamic> json) {
    return GameAssessment(
      totalPlayed: json['totalPlayed'] as int? ?? 0,
      averageTime: json['averageTime'] as int? ?? 0,
      averageErrors: (json['averageErrors'] as num?)?.toDouble() ?? 0.0,
      averageScore: json['averageScore'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      difficulty: json['difficulty'] as String? ?? 'medium',
      domains: (json['domains'] as List?)?.map((e) => e as String).toList() ?? const [],
      lastPlayed: json['lastPlayed'] as String?,
      sessions: (json['sessions'] as List?)
              ?.map((e) => GameSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPlayed': totalPlayed,
      'averageTime': averageTime,
      'averageErrors': averageErrors,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'difficulty': difficulty,
      'domains': domains,
      'lastPlayed': lastPlayed,
      'sessions': sessions.map((e) => e.toJson()).toList(),
    };
  }
}

class AllGameAssessments {
  GameAssessment memory;
  GameAssessment wordPuzzle;
  GameAssessment numberSequence;
  GameAssessment patternRecognition;
  GameAssessment motor;
  GameAssessment cognitiveGame;
  GameAssessment linguisticGame;
  GameAssessment alienShooterGame;
  GameAssessment desertTankGame;
  GameAssessment desertRoadGame;
  GameAssessment storyBuilderGame;
  GameAssessment sequenceMemoryGame;
  GameAssessment numberMemoryGame;
  // ── Game tambahan (tracking asesmen) ────────────────────────────────────
  GameAssessment shapeSortingGame;
  GameAssessment mirrorPatternGame;
  GameAssessment puzzleGame;
  GameAssessment spellBeeGame;
  GameAssessment coloringGame;

  AllGameAssessments({
    GameAssessment? memory,
    GameAssessment? wordPuzzle,
    GameAssessment? numberSequence,
    GameAssessment? patternRecognition,
    GameAssessment? motor,
    GameAssessment? cognitiveGame,
    GameAssessment? linguisticGame,
    GameAssessment? alienShooterGame,
    GameAssessment? desertTankGame,
    GameAssessment? desertRoadGame,
    GameAssessment? storyBuilderGame,
    GameAssessment? sequenceMemoryGame,
    GameAssessment? numberMemoryGame,
    GameAssessment? shapeSortingGame,
    GameAssessment? mirrorPatternGame,
    GameAssessment? puzzleGame,
    GameAssessment? spellBeeGame,
    GameAssessment? coloringGame,
  })  : memory = memory ?? GameAssessment(domains: ['Konsentrasi', 'Memori Jangka Pendek']),
        wordPuzzle = wordPuzzle ?? GameAssessment(domains: ['Bahasa', 'Kosakata', 'Problem Solving']),
        numberSequence = numberSequence ?? GameAssessment(domains: ['Logika', 'Matematika', 'Pattern Recognition']),
        patternRecognition = patternRecognition ?? GameAssessment(domains: ['Logika Visual', 'Abstraksi', 'Spatial Intelligence']),
        motor = motor ?? GameAssessment(domains: ['Koordinasi Motorik', 'Refleks', 'Keseimbangan']),
        cognitiveGame = cognitiveGame ?? GameAssessment(domains: ['Matematika', 'Logika', 'Konsentrasi']),
        linguisticGame = linguisticGame ?? GameAssessment(domains: ['Bahasa', 'Tata Bahasa', 'Kosakata']),
        alienShooterGame = alienShooterGame ?? GameAssessment(difficulty: 'hard', domains: ['Matematika Lanjutan', 'Logika', 'Pecahan']),
        desertTankGame = desertTankGame ?? GameAssessment(difficulty: 'hard', domains: ['Logika Abstrak', 'Penalaran', 'Pattern Recognition']),
        desertRoadGame = desertRoadGame ?? GameAssessment(difficulty: 'hard', domains: ['Logika', 'Abstraksi', 'Penalaran']),
        storyBuilderGame = storyBuilderGame ?? GameAssessment(domains: ['Linguistik', 'Tata Bahasa', 'Struktur Kalimat']),
        sequenceMemoryGame = sequenceMemoryGame ?? GameAssessment(domains: ['Kognitif', 'Memori Urutan', 'Konsentrasi']),
        numberMemoryGame = numberMemoryGame ?? GameAssessment(domains: ['Kognitif', 'Memori Angka', 'Konsentrasi']),
        shapeSortingGame = shapeSortingGame ?? GameAssessment(domains: ['Kecepatan Proses', 'Klasifikasi', 'Visual']),
        mirrorPatternGame = mirrorPatternGame ?? GameAssessment(domains: ['Visual-Spasial', 'Rotasi Mental', 'Abstraksi']),
        puzzleGame = puzzleGame ?? GameAssessment(domains: ['Visual-Spasial', 'Konstruksi', 'Problem Solving']),
        spellBeeGame = spellBeeGame ?? GameAssessment(domains: ['Linguistik', 'Fonemik', 'Ejaan']),
        coloringGame = coloringGame ?? GameAssessment(domains: ['Motorik Halus', 'Koordinasi Tangan-Mata', 'Kreativitas']);

  factory AllGameAssessments.fromJson(Map<String, dynamic> json) {
    return AllGameAssessments(
      memory: json['memory'] != null ? GameAssessment.fromJson(json['memory']) : null,
      wordPuzzle: json['wordPuzzle'] != null ? GameAssessment.fromJson(json['wordPuzzle']) : null,
      numberSequence: json['numberSequence'] != null ? GameAssessment.fromJson(json['numberSequence']) : null,
      patternRecognition: json['patternRecognition'] != null ? GameAssessment.fromJson(json['patternRecognition']) : null,
      motor: json['motor'] != null ? GameAssessment.fromJson(json['motor']) : null,
      cognitiveGame: json['cognitiveGame'] != null ? GameAssessment.fromJson(json['cognitiveGame']) : null,
      linguisticGame: json['linguisticGame'] != null ? GameAssessment.fromJson(json['linguisticGame']) : null,
      alienShooterGame: json['alienShooterGame'] != null ? GameAssessment.fromJson(json['alienShooterGame']) : null,
      desertTankGame: json['desertTankGame'] != null ? GameAssessment.fromJson(json['desertTankGame']) : null,
      desertRoadGame: json['desertRoadGame'] != null ? GameAssessment.fromJson(json['desertRoadGame']) : null,
      storyBuilderGame: json['storyBuilderGame'] != null ? GameAssessment.fromJson(json['storyBuilderGame']) : null,
      sequenceMemoryGame: json['sequenceMemoryGame'] != null ? GameAssessment.fromJson(json['sequenceMemoryGame']) : null,
      numberMemoryGame: json['numberMemoryGame'] != null ? GameAssessment.fromJson(json['numberMemoryGame']) : null,
      shapeSortingGame: json['shapeSortingGame'] != null ? GameAssessment.fromJson(json['shapeSortingGame']) : null,
      mirrorPatternGame: json['mirrorPatternGame'] != null ? GameAssessment.fromJson(json['mirrorPatternGame']) : null,
      puzzleGame: json['puzzleGame'] != null ? GameAssessment.fromJson(json['puzzleGame']) : null,
      spellBeeGame: json['spellBeeGame'] != null ? GameAssessment.fromJson(json['spellBeeGame']) : null,
      coloringGame: json['coloringGame'] != null ? GameAssessment.fromJson(json['coloringGame']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memory': memory.toJson(),
      'wordPuzzle': wordPuzzle.toJson(),
      'numberSequence': numberSequence.toJson(),
      'patternRecognition': patternRecognition.toJson(),
      'motor': motor.toJson(),
      'cognitiveGame': cognitiveGame.toJson(),
      'linguisticGame': linguisticGame.toJson(),
      'alienShooterGame': alienShooterGame.toJson(),
      'desertTankGame': desertTankGame.toJson(),
      'desertRoadGame': desertRoadGame.toJson(),
      'storyBuilderGame': storyBuilderGame.toJson(),
      'sequenceMemoryGame': sequenceMemoryGame.toJson(),
      'numberMemoryGame': numberMemoryGame.toJson(),
      'shapeSortingGame': shapeSortingGame.toJson(),
      'mirrorPatternGame': mirrorPatternGame.toJson(),
      'puzzleGame': puzzleGame.toJson(),
      'spellBeeGame': spellBeeGame.toJson(),
      'coloringGame': coloringGame.toJson(),
    };
  }
}
