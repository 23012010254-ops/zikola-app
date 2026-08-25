import '../models/game_assessment.dart';
import '../models/test_result.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  AssessmentEngine
//
//  Engine sentral yang mengolah data mentah dari semua game menjadi:
//    1. Skor CHC per sub-domain (Gf, Gwm, Gs, Gv, Gsm, Gc)
//    2. Skor komposit per domain (Kognitif, Linguistik, Sosem, Motorik)
//    3. Klasifikasi performa berbasis norma usia
//    4. JSON payload lengkap siap dikirim ke API AI
//
//  Referensi:
//    - Cattell-Horn-Carroll (CHC) Theory of Cognitive Abilities
//    - WISC-V Normative Data (ages 6-16)
//    - CDC Developmental Milestones
//    - Game-Based Assessment Literature (Van der Linden et al., 2020)
// ═══════════════════════════════════════════════════════════════════════════

class AssessmentEngine {
  // Singleton
  static final AssessmentEngine _instance = AssessmentEngine._internal();
  factory AssessmentEngine() => _instance;
  AssessmentEngine._internal();

  // ──────────────────────────────────────────────────────────────────────────
  //  1. FORMULA SKOR ASESMEN PER GAME
  // ──────────────────────────────────────────────────────────────────────────

  /// Menghitung skor asesmen komposit (0-100) dari satu sesi game.
  ///
  /// Formula: (Accuracy×0.35) + (Speed×0.20) + (Progression×0.25) + (Efficiency×0.20)
  ///
  /// [totalItems]   — total soal dalam sesi
  /// [correct]      — jumlah jawaban benar
  /// [avgResponseMs]— rata-rata waktu respons dalam ms
  /// [idealTimeMs]  — waktu ideal per soal dalam ms (berbeda per game)
  /// [maxLevel]     — level tertinggi yang dicapai
  /// [totalLevels]  — total level yang tersedia
  /// [hintsUsed]    — jumlah hint terpakai
  /// [errors]       — jumlah error
  static double calculateGameScore({
    required int totalItems,
    required int correct,
    required int avgResponseMs,
    required int idealTimeMs,
    required int maxLevel,
    required int totalLevels,
    required int hintsUsed,
    required int errors,
  }) {
    if (totalItems == 0) return 0.0;

    // Komponen 1: Akurasi (35%)
    final accuracy = (correct / totalItems) * 100;

    // Komponen 2: Kecepatan (20%)
    // Formula: max(0, 100 - (avgResponseTime - idealTime) / idealTime * 50)
    final double timePenalty = idealTimeMs > 0 ? ((avgResponseMs - idealTimeMs) / idealTimeMs) * 50.0 : 0.0;
    final speed = (100.0 - timePenalty).clamp(0.0, 100.0);

    // Komponen 3: Progressi Level (25%)
    final progression = totalLevels > 0 ? (maxLevel / totalLevels) * 100 : 50.0;

    // Komponen 4: Efisiensi (20%)
    final hintPenalty = hintsUsed * 5.0;
    final errorPenalty = errors * 3.0;
    final efficiency = (100 - hintPenalty - errorPenalty).clamp(0.0, 100.0);

    final composite = (accuracy * 0.35) + (speed * 0.20) + (progression * 0.25) + (efficiency * 0.20);
    return composite.clamp(0.0, 100.0);
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  2. SKOR CHC SUB-DOMAIN KOGNITIF
  // ──────────────────────────────────────────────────────────────────────────

  /// Menghitung skor Fluid Reasoning (Gf) dari game-game logika.
  /// Bobot: AlienShooter(30%) + DesertRoad(25%) + NumberSequence(25%) + DesertTank(20%)
  static double calculateFluidReasoning(AllGameAssessments games) {
    final scores = <double>[];
    final weights = <double>[];

    if (games.alienShooterGame.totalPlayed > 0) {
      scores.add(games.alienShooterGame.averageScore.toDouble());
      weights.add(0.30);
    }
    if (games.desertRoadGame.totalPlayed > 0) {
      scores.add(games.desertRoadGame.averageScore.toDouble());
      weights.add(0.25);
    }
    if (games.numberSequence.totalPlayed > 0) {
      scores.add(games.numberSequence.averageScore.toDouble());
      weights.add(0.25);
    }
    if (games.desertTankGame.totalPlayed > 0) {
      scores.add(games.desertTankGame.averageScore.toDouble());
      weights.add(0.20);
    }

    return _weightedAverage(scores, weights);
  }

  /// Menghitung skor Working Memory (Gwm) dari game memori urutan & pola.
  /// Bobot: SequenceMemory(35%) + PatternRecognition(35%) + NumberMemory(30%)
  static double calculateWorkingMemory(AllGameAssessments games) {
    final scores = <double>[];
    final weights = <double>[];

    if (games.sequenceMemoryGame.totalPlayed > 0) {
      scores.add(games.sequenceMemoryGame.averageScore.toDouble());
      weights.add(0.35);
    }
    if (games.patternRecognition.totalPlayed > 0) {
      scores.add(games.patternRecognition.averageScore.toDouble());
      weights.add(0.35);
    }
    if (games.numberMemoryGame.totalPlayed > 0) {
      scores.add(games.numberMemoryGame.averageScore.toDouble());
      weights.add(0.30);
    }

    return _weightedAverage(scores, weights);
  }

  /// Menghitung skor Processing Speed (Gs) dari game kecepatan.
  /// Bobot: ShapeSorting(50%) + AlienShooter speed component(50%)
  static double calculateProcessingSpeed(AllGameAssessments games) {
    final scores = <double>[];
    final weights = <double>[];

    if (games.shapeSortingGame.totalPlayed > 0) {
      scores.add(games.shapeSortingGame.averageScore.toDouble());
      weights.add(0.50);
    }
    if (games.alienShooterGame.totalPlayed > 0) {
      // Gunakan average time sebagai proxy processing speed
      // Makin cepat = makin tinggi skornya (normalize ke 0-100)
      final avgTime = games.alienShooterGame.averageTime;
      final speedScore = avgTime > 0 ? (1 - (avgTime.clamp(1000, 10000) - 1000) / 9000) * 100 : 50.0;
      scores.add(speedScore);
      weights.add(0.50);
    }

    return _weightedAverage(scores, weights);
  }

  /// Menghitung skor Visual Processing (Gv) dari game visual-spasial.
  /// Bobot: MirrorPattern(35%) + MemoryCard(35%) + PuzzleGame(30%)
  static double calculateVisualProcessing(AllGameAssessments games) {
    final scores = <double>[];
    final weights = <double>[];

    if (games.mirrorPatternGame.totalPlayed > 0) {
      scores.add(games.mirrorPatternGame.averageScore.toDouble());
      weights.add(0.35);
    }
    if (games.memory.totalPlayed > 0) {
      scores.add(games.memory.averageScore.toDouble());
      weights.add(0.35);
    }
    if (games.puzzleGame.totalPlayed > 0) {
      scores.add(games.puzzleGame.averageScore.toDouble());
      weights.add(0.30);
    }

    return _weightedAverage(scores, weights);
  }

  /// Menghitung skor Short-Term Memory (Gsm) dari game memori.
  /// Bobot: MemoryCard(50%) + NumberMemory(50%)
  static double calculateShortTermMemory(AllGameAssessments games) {
    final scores = <double>[];
    final weights = <double>[];

    if (games.memory.totalPlayed > 0) {
      scores.add(games.memory.averageScore.toDouble());
      weights.add(0.50);
    }
    if (games.numberMemoryGame.totalPlayed > 0) {
      scores.add(games.numberMemoryGame.averageScore.toDouble());
      weights.add(0.50);
    }

    return _weightedAverage(scores, weights);
  }

  /// Menghitung skor Crystallized Knowledge (Gc) dari game linguistik.
  /// Bobot: LinguisticTest(35%) + StoryBuilder(25%) + WordPuzzle(25%) + SpellBee(15%)
  static double calculateCrystallizedKnowledge(AllGameAssessments games) {
    final scores = <double>[];
    final weights = <double>[];

    if (games.linguisticGame.totalPlayed > 0) {
      scores.add(games.linguisticGame.averageScore.toDouble());
      weights.add(0.35);
    }
    if (games.storyBuilderGame.totalPlayed > 0) {
      scores.add(games.storyBuilderGame.averageScore.toDouble());
      weights.add(0.25);
    }
    if (games.wordPuzzle.totalPlayed > 0) {
      scores.add(games.wordPuzzle.averageScore.toDouble());
      weights.add(0.25);
    }
    if (games.spellBeeGame.totalPlayed > 0) {
      scores.add(games.spellBeeGame.averageScore.toDouble());
      weights.add(0.15);
    }

    return _weightedAverage(scores, weights);
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  3. SKOR DOMAIN KOMPOSIT
  // ──────────────────────────────────────────────────────────────────────────

  /// Menghitung skor komposit domain Kognitif dari semua game kognitif.
  /// Bobot per CHC (Game-based):
  /// AlienShooter (20%), PatternRecog (15%), MemoryCard (15%), 
  /// SequenceMemory (10%), NumberMemory (10%), NumberSequence (10%), 
  /// DesertRoad (10%), ShapeSorting (5%), MirrorPattern (5%)
  static double calculateCognitiveComposite(AllGameAssessments games) {
    final components = <double>[];
    final weights = <double>[];

    void addScore(GameAssessment game, double weight) {
      if (game.totalPlayed > 0) {
        components.add(game.averageScore.toDouble());
        weights.add(weight);
      }
    }

    addScore(games.alienShooterGame, 0.20);
    addScore(games.patternRecognition, 0.15);
    addScore(games.memory, 0.15);
    addScore(games.sequenceMemoryGame, 0.10);
    addScore(games.numberMemoryGame, 0.10);
    addScore(games.numberSequence, 0.10);
    addScore(games.desertRoadGame, 0.10);
    addScore(games.shapeSortingGame, 0.05);
    addScore(games.mirrorPatternGame, 0.05);

    return _weightedAverage(components, weights);
  }

  /// Menghitung skor komposit domain Linguistik.
  /// Bobot per game: LinguisticTest (35%), StoryBuilder (25%), 
  /// WordPuzzle (25%), SpellBee (15%)
  static double calculateLinguisticComposite(AllGameAssessments games, TestScoreResult linguisticResult) {
    final components = <double>[];
    final weights = <double>[];

    void addScore(GameAssessment game, double weight) {
      if (game.totalPlayed > 0) {
        components.add(game.averageScore.toDouble());
        weights.add(weight);
      }
    }

    addScore(games.linguisticGame, 0.35);
    addScore(games.storyBuilderGame, 0.25);
    addScore(games.wordPuzzle, 0.25);
    addScore(games.spellBeeGame, 0.15);

    double composite = _weightedAverage(components, weights);
    
    // Jika belum ada data game sama sekali, fallback ke persentase default
    if (composite == 0 && components.isEmpty) {
      return linguisticResult.percentage;
    }
    return composite;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  4. KLASIFIKASI & NORMA USIA
  // ──────────────────────────────────────────────────────────────────────────

  /// Mengembalikan label klasifikasi performa berdasarkan skor komposit.
  static String getPerformanceClassification(double score) {
    if (score >= 90) return 'Sangat Baik';
    if (score >= 75) return 'Baik';
    if (score >= 60) return 'Cukup';
    if (score >= 40) return 'Perlu Perhatian';
    return 'Perlu Evaluasi Lebih Lanjut';
  }

  /// Mengembalikan norma digit span berdasarkan usia anak (dalam tahun).
  static String getDigitSpanNorm(int ageYears) {
    if (ageYears <= 5) return '3-4 digit';
    if (ageYears <= 7) return '4-5 digit';
    if (ageYears <= 9) return '5-6 digit';
    return '6-7 digit';
  }

  /// Mengembalikan norma waktu respons berdasarkan usia anak (dalam tahun).
  static String getResponseTimeNorm(int ageYears) {
    if (ageYears <= 5) return 'Lambat (~5-8 detik)';
    if (ageYears <= 7) return 'Sedang (~3-5 detik)';
    if (ageYears <= 9) return 'Cepat (~2-3 detik)';
    return 'Sangat Cepat (~1-2 detik)';
  }

  /// Mengembalikan interpretasi singkat berdasarkan domain & skor.
  static Map<String, String> getDomainInterpretation(String domain, double score) {
    final classification = getPerformanceClassification(score);

    final interpretations = <String, Map<String, Map<String, String>>>{
      'Kognitif': {
        'Sangat Baik': {
          'conclusion': 'Kemampuan logika & pemecahan masalah sangat tajam dan menonjol.',
          'suggestion': 'Berikan tantangan teka-teki yang lebih kompleks (puzzle 100+ keping, catur, coding).',
        },
        'Baik': {
          'conclusion': 'Pemahaman konsep cukup kuat dan perkembangan berjalan dengan baik.',
          'suggestion': 'Latih fokus dengan permainan memori atau "Spot the Difference" secara rutin.',
        },
        'Cukup': {
          'conclusion': 'Pemahaman dasar sudah ada, namun perlu konsistensi dalam latihan.',
          'suggestion': 'Mulai dengan teka-teki sederhana 10-15 menit/hari dan tingkatkan bertahap.',
        },
        'Perlu Perhatian': {
          'conclusion': 'Memerlukan stimulasi lebih intensif untuk perkembangan kognitif.',
          'suggestion': 'Jadwalkan aktivitas bermain terarah setiap hari. Pertimbangkan sesi stimulasi dengan terapis.',
        },
        'Perlu Evaluasi Lebih Lanjut': {
          'conclusion': 'Disarankan berkonsultasi dengan psikolog anak untuk evaluasi lebih mendalam.',
          'suggestion': 'Hubungi psikolog anak atau konsultan tumbuh kembang untuk panduan lebih lanjut.',
        },
      },
      'Linguistik': {
        'Sangat Baik': {
          'conclusion': 'Kosa kata luas dan kemampuan bahasa sangat berkembang dengan baik.',
          'suggestion': 'Ajak anak storytelling, mulai menulis diary sederhana, atau ikut klub baca.',
        },
        'Baik': {
          'conclusion': 'Komunikasi lancar, kosa kata bisa terus diperkaya lebih luas.',
          'suggestion': 'Bacakan buku cerita baru setiap hari dan diskusikan kata-kata yang belum diketahui.',
        },
        'Cukup': {
          'conclusion': 'Kemampuan bahasa berkembang sesuai usia, perlu lebih banyak paparan bahasa.',
          'suggestion': 'Gunakan flashcard gambar-kata dan sering lakukan tanya jawab aktif.',
        },
        'Perlu Perhatian': {
          'conclusion': 'Perlu perangsangan kosa kata dan keberanian berekspresi lebih banyak.',
          'suggestion': 'Rutinkan sesi membaca bersama 20 menit/hari. Awasi juga kemampuan pendengaran.',
        },
        'Perlu Evaluasi Lebih Lanjut': {
          'conclusion': 'Disarankan evaluasi kemampuan bicara-bahasa oleh terapis wicara.',
          'suggestion': 'Konsultasikan dengan terapis wicara atau dokter anak untuk panduan spesifik.',
        },
      },
      'Kepribadian': {
        'Sangat Baik': {
          'conclusion': 'Kekuatan sosial-emosional dan kemandirian sangat menonjol.',
          'suggestion': 'Berikan tanggung jawab kecil di rumah untuk memupuk jiwa pemimpin yang positif.',
        },
        'Baik': {
          'conclusion': 'Kemampuan sosialisasi baik, terus dukung dalam pengembangan empati.',
          'suggestion': 'Bermain peran (role-play) untuk belajar memahami perasaan orang lain.',
        },
        'Cukup': {
          'conclusion': 'Masih dalam tahap adaptasi sosial-emosional yang wajar.',
          'suggestion': 'Perbanyak interaksi dengan teman sebaya melalui kegiatan kelompok.',
        },
        'Perlu Perhatian': {
          'conclusion': 'Anak mungkin membutuhkan dukungan lebih dalam regulasi emosi.',
          'suggestion': 'Pastikan bonding berkualitas lebih sering agar anak merasa aman dan diterima.',
        },
        'Perlu Evaluasi Lebih Lanjut': {
          'conclusion': 'Pertimbangkan konsultasi dengan psikolog anak untuk dukungan emosional.',
          'suggestion': 'Diskusikan dengan konselor atau psikolog anak tentang strategi dukungan yang tepat.',
        },
      },
      'Motorik': {
        'Sangat Baik': {
          'conclusion': 'Koordinasi dan ketangkasan sangat baik untuk usianya.',
          'suggestion': 'Kegiatan luar ruangan seperti bersepeda, berenang, atau seni bela diri sangat cocok.',
        },
        'Baik': {
          'conclusion': 'Gerakan motorik terkoordinasi dengan baik, terus aktif bergerak.',
          'suggestion': 'Latih motorik halus dengan meronce, menggunting pola, atau mewarnai detail.',
        },
        'Cukup': {
          'conclusion': 'Perkembangan motorik berjalan normal, perlu lebih banyak latihan.',
          'suggestion': 'Bermain dengan playdough, origami, atau melempar-tangkap bola setiap hari.',
        },
        'Perlu Perhatian': {
          'conclusion': 'Koordinasi motorik memerlukan latihan yang lebih terstruktur.',
          'suggestion': 'Latihan motorik halus 15-20 menit/hari. Pertimbangkan terapi okupasi.',
        },
        'Perlu Evaluasi Lebih Lanjut': {
          'conclusion': 'Disarankan evaluasi motorik dengan terapis okupasi profesional.',
          'suggestion': 'Konsultasikan dengan dokter anak atau terapis okupasi untuk panduan evaluasi.',
        },
      },
    };

    final domainMap = interpretations[domain];
    if (domainMap == null) {
      return {'conclusion': 'Data belum lengkap.', 'suggestion': 'Selesaikan tes untuk melihat analisis.'};
    }

    return domainMap[classification] ??
        {'conclusion': 'Data belum lengkap.', 'suggestion': 'Selesaikan lebih banyak game untuk analisis yang akurat.'};
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  5. JSON PAYLOAD UNTUK AI
  // ──────────────────────────────────────────────────────────────────────────

  /// Menghasilkan payload JSON lengkap yang siap dikirim ke API AI.
  ///
  /// Payload ini mencakup profil anak, semua skor domain & subdomain,
  /// analisis lintas-domain, dan perbandingan norma usia.
  static Map<String, dynamic> buildAIPayload({
    required String childName,
    required int childAge,
    required String childGender,
    required AllGameAssessments games,
    required TestResults testResults,
  }) {
    // Hitung semua skor CHC
    final gf = calculateFluidReasoning(games);
    final gwm = calculateWorkingMemory(games);
    final gs = calculateProcessingSpeed(games);
    final gv = calculateVisualProcessing(games);
    final gsm = calculateShortTermMemory(games);
    final gc = calculateCrystallizedKnowledge(games);

    // Hitung skor domain komposit
    final cogScore = calculateCognitiveComposite(games);
    final linScore = calculateLinguisticComposite(games, testResults.linguistic);
    final perSocial = testResults.personality.socialScore?.toDouble() ?? 0.0;
    final perEmotional = testResults.personality.emotionalScore?.toDouble() ?? 0.0;
    final perCharacter = testResults.personality.characterScore?.toDouble() ?? 0.0;
    final socemScore = testResults.personality.completed
        ? (perSocial + perEmotional + perCharacter) / 3
        : 0.0;
    final motScore = testResults.motor.percentage;

    // Tentukan domain terkuat
    final domainScores = <String, double>{
      'Kognitif': cogScore,
      'Linguistik': linScore,
      'Kepribadian': socemScore,
      'Motorik': motScore,
    };
    final strongest = domainScores.entries
        .where((e) => e.value > 0)
        .fold<MapEntry<String, double>?>(
          null,
          (prev, curr) => prev == null || curr.value > prev.value ? curr : prev,
        );

    // Hitung berapa domain yang sudah selesai
    final completedDomains = <String>[];
    if (testResults.cognitive.completed) completedDomains.add('Kognitif');
    if (testResults.linguistic.completed) completedDomains.add('Linguistik');
    if (testResults.personality.completed) completedDomains.add('Kepribadian');
    if (testResults.motor.completed) completedDomains.add('Motorik');

    return {
      'childProfile': {
        'name': childName,
        'age': childAge,
        'gender': childGender,
        'assessmentDate': DateTime.now().toIso8601String().split('T').first,
      },
      'ageNorms': {
        'digitSpan': getDigitSpanNorm(childAge),
        'responseTime': getResponseTimeNorm(childAge),
        'expectedCognitiveRange': _getCognitiveAgeRange(childAge),
      },
      'cognitiveProfile': {
        'compositeScore': _round(cogScore),
        'classification': getPerformanceClassification(cogScore),
        'completed': testResults.cognitive.completed,
        'subdomains': {
          'fluidReasoning': {
            'score': _round(gf),
            'classification': getPerformanceClassification(gf),
            'games': _extractGameData(games, ['alienShooterGame', 'desertRoadGame', 'numberSequence', 'desertTankGame']),
          },
          'workingMemory': {
            'score': _round(gwm),
            'classification': getPerformanceClassification(gwm),
            'games': _extractGameData(games, ['sequenceMemoryGame', 'patternRecognition', 'numberMemoryGame']),
          },
          'processingSpeed': {
            'score': _round(gs),
            'classification': getPerformanceClassification(gs),
            'games': _extractGameData(games, ['shapeSortingGame', 'alienShooterGame']),
          },
          'visualProcessing': {
            'score': _round(gv),
            'classification': getPerformanceClassification(gv),
            'games': _extractGameData(games, ['mirrorPatternGame', 'memory', 'puzzleGame']),
          },
          'shortTermMemory': {
            'score': _round(gsm),
            'classification': getPerformanceClassification(gsm),
            'games': _extractGameData(games, ['memory', 'numberMemoryGame']),
          },
        },
      },
      'linguisticProfile': {
        'compositeScore': _round(linScore),
        'classification': getPerformanceClassification(linScore),
        'completed': testResults.linguistic.completed,
        'subdomains': {
          'crystallizedKnowledge': {
            'score': _round(gc),
            'classification': getPerformanceClassification(gc),
          },
          'receptiveLanguage': {
            'score': testResults.linguistic.completed ? _round(testResults.linguistic.percentage) : 0,
            'gameAverage': _round(games.linguisticGame.averageScore.toDouble()),
          },
          'expressiveLanguage': {
            'gameAverage': _round(games.storyBuilderGame.averageScore.toDouble()),
          },
          'phonemicAwareness': {
            'wordPuzzleAvg': _round(games.wordPuzzle.averageScore.toDouble()),
            'spellBeeAvg': _round(games.spellBeeGame.averageScore.toDouble()),
          },
        },
      },
      'socialEmotionalProfile': {
        'compositeScore': _round(socemScore),
        'classification': getPerformanceClassification(socemScore),
        'completed': testResults.personality.completed,
        'subdomains': {
          'socialCompetence': _round(perSocial),
          'emotionalRegulation': _round(perEmotional),
          'characterValues': _round(perCharacter),
        },
        'responseConsistency': testResults.personality.responseConsistency,
      },
      'motorProfile': {
        'compositeScore': _round(motScore),
        'classification': getPerformanceClassification(motScore),
        'completed': testResults.motor.completed,
        'subdomains': {
          'motorKnowledge': _round(testResults.motor.percentage),
          'fineMotor': _round(games.coloringGame.averageScore.toDouble()),
        },
      },
      'crossDomainAnalysis': {
        'completedDomains': completedDomains,
        'completionRate': '${completedDomains.length}/4',
        'strongestDomain': strongest?.key ?? 'Belum dapat ditentukan',
        'strongestScore': _round(strongest?.value ?? 0.0),
        'overallDevelopmentStatus': _getOverallStatus(cogScore, linScore, socemScore, motScore),
        'recommendProfessionalEvaluation': _needsProfessionalEval(cogScore, linScore, socemScore, motScore),
      },
      'gameEngagementSummary': {
        'totalGamesPlayed': _countTotalSessions(games),
        'mostPlayedGame': _getMostPlayedGame(games),
        'averageSessionsPerGame': _getAvgSessionsPerGame(games),
      },
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  6. PROMPT AI
  // ──────────────────────────────────────────────────────────────────────────

  /// Menghasilkan system prompt untuk AI analysis.
  static String buildSystemPrompt() {
    return '''Kamu adalah psikolog anak profesional yang ramah, empatik, dan suportif. 
Kamu menganalisis data asesmen perkembangan anak dari platform game-based assessment "Zikola".

ATURAN PENTING:
1. Gunakan bahasa Indonesia yang hangat, mudah dipahami orangtua awam
2. JANGAN gunakan terminologi klinis yang mengkhawatirkan (gangguan, abnormal, defisit, dll.)
3. JANGAN memberikan diagnosis — hanya observasi dan rekomendasi
4. Selalu frame positif: fokus pada potensi, bukan kelemahan
5. Jika skor < 40 di area manapun, sarankan konsultasi profesional dengan cara yang menenangkan
6. Ingat: ini asesmen via game, BUKAN diagnosis klinis resmi

FORMAT LAPORAN (gunakan markdown):
1. 🌟 Sapaan hangat personalisasi
2. 📊 Ringkasan Profil (2-3 kalimat positif tentang anak secara keseluruhan)
3. 💪 Kekuatan Utama (top 2-3 area terbaik dengan penjelasan konkret)
4. 🌱 Area Pengembangan (2-3 area + cara mengembangkan yang fun & actionable)
5. 🏠 Aktivitas di Rumah (3-5 aktivitas konkret, mudah dilakukan)
6. 🎯 Target 1-2 Bulan ke Depan (milestone yang realistis dan menyemangati)
7. ❤️ Penutup yang menyemangati orangtua''';
  }

  /// Menghasilkan user message untuk AI analysis.
  static String buildUserMessage(Map<String, dynamic> payload) {
    final child = payload['childProfile'] as Map<String, dynamic>;
    final cogScore = (payload['cognitiveProfile'] as Map)['compositeScore'];
    final linScore = (payload['linguisticProfile'] as Map)['compositeScore'];
    final socScore = (payload['socialEmotionalProfile'] as Map)['compositeScore'];
    final motScore = (payload['motorProfile'] as Map)['compositeScore'];
    final strongest = (payload['crossDomainAnalysis'] as Map)['strongestDomain'];

    return '''Tolong buat laporan perkembangan untuk anak berikut berdasarkan data asesmen game:

PROFIL ANAK:
- Nama: ${child['name']}
- Usia: ${child['age']} tahun
- Gender: ${child['gender'] == 'male' ? 'Laki-laki' : 'Perempuan'}
- Tanggal Asesmen: ${child['assessmentDate']}

HASIL ASESMEN:
- Skor Kognitif: $cogScore/100 (${getPerformanceClassification(cogScore?.toDouble() ?? 0)})
- Skor Linguistik: $linScore/100 (${getPerformanceClassification(linScore?.toDouble() ?? 0)})
- Skor Sosial-Emosional: $socScore/100 (${getPerformanceClassification(socScore?.toDouble() ?? 0)})
- Skor Motorik: $motScore/100 (${getPerformanceClassification(motScore?.toDouble() ?? 0)})

DOMAIN TERKUAT: $strongest

DATA DETAIL:
${_formatPayloadForPrompt(payload)}

Buat laporan yang hangat, personal, dan menyemangati orangtua. Gunakan nama anak langsung.''';
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  static double _weightedAverage(List<double> values, List<double> weights) {
    if (values.isEmpty) return 0.0;
    if (values.length != weights.length) return values.reduce((a, b) => a + b) / values.length;

    double totalWeight = weights.reduce((a, b) => a + b);
    if (totalWeight == 0) return 0.0;

    double sum = 0.0;
    for (int i = 0; i < values.length; i++) {
      sum += values[i] * (weights[i] / totalWeight);
    }
    return sum.clamp(0.0, 100.0);
  }

  static double _round(double value) {
    return (value * 10).round() / 10;
  }

  static Map<String, dynamic> _extractGameData(AllGameAssessments games, List<String> gameKeys) {
    final result = <String, dynamic>{};
    for (final key in gameKeys) {
      final assessment = _getGameAssessmentByKey(games, key);
      if (assessment != null && assessment.totalPlayed > 0) {
        result[key] = {
          'totalPlayed': assessment.totalPlayed,
          'averageScore': assessment.averageScore,
          'averageTime': assessment.averageTime,
          'averageErrors': assessment.averageErrors,
          'bestScore': assessment.bestScore,
        };
      }
    }
    return result;
  }

  static GameAssessment? _getGameAssessmentByKey(AllGameAssessments games, String key) {
    switch (key) {
      case 'memory': return games.memory;
      case 'wordPuzzle': return games.wordPuzzle;
      case 'numberSequence': return games.numberSequence;
      case 'patternRecognition': return games.patternRecognition;
      case 'motor': return games.motor;
      case 'cognitiveGame': return games.cognitiveGame;
      case 'linguisticGame': return games.linguisticGame;
      case 'alienShooterGame': return games.alienShooterGame;
      case 'desertTankGame': return games.desertTankGame;
      case 'desertRoadGame': return games.desertRoadGame;
      case 'storyBuilderGame': return games.storyBuilderGame;
      case 'sequenceMemoryGame': return games.sequenceMemoryGame;
      case 'numberMemoryGame': return games.numberMemoryGame;
      case 'shapeSortingGame': return games.shapeSortingGame;
      case 'mirrorPatternGame': return games.mirrorPatternGame;
      case 'puzzleGame': return games.puzzleGame;
      case 'spellBeeGame': return games.spellBeeGame;
      case 'coloringGame': return games.coloringGame;
      default: return null;
    }
  }

  static String _getCognitiveAgeRange(int age) {
    if (age <= 5) return '60-90 (perkembangan pra-sekolah)';
    if (age <= 7) return '70-100 (perkembangan awal sekolah)';
    if (age <= 9) return '75-105 (perkembangan sekolah dasar)';
    return '80-110 (perkembangan sekolah dasar lanjut)';
  }

  static String _getOverallStatus(double cog, double lin, double socem, double mot) {
    final scores = [cog, lin, socem, mot].where((s) => s > 0).toList();
    if (scores.isEmpty) return 'Belum dapat dinilai';
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    return getPerformanceClassification(avg);
  }

  static bool _needsProfessionalEval(double cog, double lin, double socem, double mot) {
    final scores = [cog, lin, socem, mot].where((s) => s > 0);
    return scores.any((s) => s < 40);
  }

  static int _countTotalSessions(AllGameAssessments games) {
    return games.memory.totalPlayed +
        games.wordPuzzle.totalPlayed +
        games.numberSequence.totalPlayed +
        games.patternRecognition.totalPlayed +
        games.alienShooterGame.totalPlayed +
        games.desertRoadGame.totalPlayed +
        games.desertTankGame.totalPlayed +
        games.storyBuilderGame.totalPlayed +
        games.sequenceMemoryGame.totalPlayed +
        games.numberMemoryGame.totalPlayed +
        games.shapeSortingGame.totalPlayed +
        games.mirrorPatternGame.totalPlayed +
        games.puzzleGame.totalPlayed +
        games.spellBeeGame.totalPlayed +
        games.coloringGame.totalPlayed;
  }

  static String _getMostPlayedGame(AllGameAssessments games) {
    final gameMap = {
      'Memory Card': games.memory.totalPlayed,
      'Word Puzzle': games.wordPuzzle.totalPlayed,
      'Number Sequence': games.numberSequence.totalPlayed,
      'Pattern Recognition': games.patternRecognition.totalPlayed,
      'Alien Shooter': games.alienShooterGame.totalPlayed,
      'Desert Road': games.desertRoadGame.totalPlayed,
      'Story Builder': games.storyBuilderGame.totalPlayed,
      'Sequence Memory': games.sequenceMemoryGame.totalPlayed,
      'Number Memory': games.numberMemoryGame.totalPlayed,
      'Shape Sorting': games.shapeSortingGame.totalPlayed,
      'Mirror Pattern': games.mirrorPatternGame.totalPlayed,
      'Puzzle': games.puzzleGame.totalPlayed,
      'Spell Bee': games.spellBeeGame.totalPlayed,
      'Coloring': games.coloringGame.totalPlayed,
    };
    final max = gameMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    return max.value > 0 ? max.key : 'Belum ada';
  }

  static double _getAvgSessionsPerGame(AllGameAssessments games) {
    final total = _countTotalSessions(games);
    final gamesWithData = [
      games.memory, games.wordPuzzle, games.numberSequence, games.patternRecognition,
      games.alienShooterGame, games.desertRoadGame, games.storyBuilderGame,
      games.sequenceMemoryGame, games.numberMemoryGame, games.shapeSortingGame,
      games.mirrorPatternGame, games.puzzleGame, games.spellBeeGame, games.coloringGame,
    ].where((g) => g.totalPlayed > 0).length;

    return gamesWithData > 0 ? (total / gamesWithData * 10).round() / 10 : 0.0;
  }

  static String _formatPayloadForPrompt(Map<String, dynamic> payload) {
    final cog = payload['cognitiveProfile'] as Map<String, dynamic>;
    final sub = cog['subdomains'] as Map<String, dynamic>;
    final buffer = StringBuffer();

    buffer.writeln('Sub-domain Kognitif:');
    (sub).forEach((key, value) {
      final score = (value as Map)['score'];
      buffer.writeln('  - ${_subdomainLabel(key)}: $score/100');
    });

    final social = payload['socialEmotionalProfile'] as Map<String, dynamic>;
    final subSocial = social['subdomains'] as Map<String, dynamic>;
    buffer.writeln('Sub-domain Sosial-Emosional:');
    buffer.writeln('  - Kompetensi Sosial: ${subSocial['socialCompetence']}/100');
    buffer.writeln('  - Regulasi Emosi: ${subSocial['emotionalRegulation']}/100');
    buffer.writeln('  - Nilai Karakter: ${subSocial['characterValues']}/100');

    return buffer.toString();
  }

  static String _subdomainLabel(String key) {
    switch (key) {
      case 'fluidReasoning': return 'Penalaran Logis (Gf)';
      case 'workingMemory': return 'Memori Kerja (Gwm)';
      case 'processingSpeed': return 'Kecepatan Proses (Gs)';
      case 'visualProcessing': return 'Pemrosesan Visual (Gv)';
      case 'shortTermMemory': return 'Memori Jangka Pendek (Gsm)';
      default: return key;
    }
  }
}
