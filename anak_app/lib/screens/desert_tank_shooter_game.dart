import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class PatternTank {
  final int id;
  double y;
  final List<String> sequence;
  final int missingIndex;
  final String correctAnswer;
  final double speed;
  final int spawnTimeMs;

  PatternTank({
    required this.id,
    required this.y,
    required this.sequence,
    required this.missingIndex,
    required this.correctAnswer,
    required this.speed,
    required this.spawnTimeMs,
  });
}

class DesertTankShooterGame extends StatefulWidget {
  const DesertTankShooterGame({super.key});

  @override
  State<DesertTankShooterGame> createState() => _DesertTankShooterGameState();
}

class _DesertTankShooterGameState extends State<DesertTankShooterGame> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, completed
  int _score = 0;
  int _lives = 3;
  int _currentLevel = 1;
  int _correctAnswers = 0;
  int _errors = 0;
  
  final List<int> _responseTimesMs = [];
  DateTime? _startTime;
  
  List<PatternTank> _tanks = [];
  final Random _random = Random();
  double _screenHeight = 0;
  
  Timer? _moveTimer;

  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  // Emoji pool
  final List<String> _emojiPool = ['🍎', '🍌', '🍉', '🍇', '🍒', '🍓', '🥕', '🌽', '🧀', '🍔'];
  List<String> _currentAmmoOptions = [];

  @override
  void dispose() {
    _moveTimer?.cancel();
    AudioService().stopBGM();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PATTERN GENERATION
  // ---------------------------------------------------------------------------
  PatternTank _generateTank(int level) {
    // Select 3 random distinct emojis
    final pool = List<String>.from(_emojiPool)..shuffle(_random);
    final A = pool[0];
    final B = pool[1];
    final C = pool[2];

    List<String> sequence = [];
    String correct = '';
    int missingIdx = 0;
    
    // speed based on level
    double speed = 0.8 + (level * 0.2);

    if (level == 1) {
      // ABAB
      sequence = [A, B, A, B];
      missingIdx = 3;
      correct = B;
    } else if (level == 2) {
      // AABB
      sequence = [A, A, B, B];
      missingIdx = 3;
      correct = B;
    } else if (level == 3) {
      // ABCABC
      sequence = [A, B, C, A, B, C];
      missingIdx = 5;
      correct = C;
    } else if (level == 4) {
      // AABAAB
      sequence = [A, A, B, A, A, B];
      missingIdx = 5;
      correct = B;
    } else if (level == 5) {
      // ABBAABBA
      sequence = [A, B, B, A, A, B, B, A];
      missingIdx = 7;
      correct = A;
    } else if (level == 6) {
      // Campuran Pola 1-5 dengan tanda tanya (?) di posisi tengah
      int t = _random.nextInt(5);
      if (t == 0) {
        sequence = [A, B, A, B];
        missingIdx = 2; // middle
        correct = A;
      } else if (t == 1) {
        sequence = [A, A, B, B];
        missingIdx = 2; // middle
        correct = B;
      } else if (t == 2) {
        sequence = [A, B, C, A, B, C];
        missingIdx = 3; // middle
        correct = A;
      } else if (t == 3) {
        sequence = [A, A, B, A, A, B];
        missingIdx = 3; // middle
        correct = A;
      } else {
        sequence = [A, B, B, A, A, B, B, A];
        missingIdx = 4; // middle
        correct = A;
      }
    } else if (level == 7) {
      // Pola Baru: ABCCBA atau ABBABB dengan posisi kosong acak
      bool isAbccba = _random.nextBool();
      if (isAbccba) {
        sequence = [A, B, C, C, B, A];
        missingIdx = _random.nextInt(4) + 1; // index 1 to 4
        correct = sequence[missingIdx];
      } else {
        sequence = [A, B, B, A, B, B];
        missingIdx = _random.nextInt(4) + 1; // index 1 to 4
        correct = sequence[missingIdx];
      }
    } else {
      // Level 8: Campuran semua pola
      int t = _random.nextInt(7);
      if (t == 0) {
        sequence = [A, B, A, B];
        missingIdx = _random.nextInt(sequence.length);
        correct = sequence[missingIdx];
      } else if (t == 1) {
        sequence = [A, A, B, B];
        missingIdx = _random.nextInt(sequence.length);
        correct = sequence[missingIdx];
      } else if (t == 2) {
        sequence = [A, B, C, A, B, C];
        missingIdx = _random.nextInt(sequence.length);
        correct = sequence[missingIdx];
      } else if (t == 3) {
        sequence = [A, A, B, A, A, B];
        missingIdx = _random.nextInt(sequence.length);
        correct = sequence[missingIdx];
      } else if (t == 4) {
        sequence = [A, B, B, A, A, B, B, A];
        missingIdx = _random.nextInt(sequence.length);
        correct = sequence[missingIdx];
      } else if (t == 5) {
        sequence = [A, B, C, C, B, A];
        missingIdx = _random.nextInt(sequence.length);
        correct = sequence[missingIdx];
      } else {
        sequence = [A, B, B, A, B, B];
        missingIdx = _random.nextInt(sequence.length);
        correct = sequence[missingIdx];
      }
    }

    // Build options based on correct + random distractors
    Set<String> options = {correct};
    while(options.length < 4) {
      options.add(_emojiPool[_random.nextInt(_emojiPool.length)]);
    }
    _currentAmmoOptions = options.toList()..shuffle(_random);

    return PatternTank(
      id: DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000),
      y: -100, // Spawn above screen
      sequence: sequence,
      missingIndex: missingIdx,
      correctAnswer: correct,
      speed: speed,
      spawnTimeMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ---------------------------------------------------------------------------
  // GAME LOOP
  // ---------------------------------------------------------------------------
  void _startLevel(int level) {
    setState(() {
      _gameState = 'playing';
      _score = 0;
      _lives = 3;
      _currentLevel = level;
      _correctAnswers = 0;
      _errors = 0;
      _responseTimesMs.clear();
      _tanks.clear();
      _startTime = DateTime.now();
    });
    
    AudioService().playBGM('adventure_music.mp3');
    _spawnTank(); // Spawn first
    _startGameLoop();
  }

  void _spawnTank() {
    if (_tanks.isEmpty) {
      setState(() {
        _tanks.add(_generateTank(_currentLevel));
      });
    }
  }

  void _startGameLoop() {
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_gameState != 'playing') return;
      
      setState(() {
        bool hitBase = false;
        for (var tank in _tanks) {
          tank.y += tank.speed;
          if (tank.y > _screenHeight - 200) { // Hit base
            hitBase = true;
          }
        }

        if (hitBase) {
          _tanks.clear();
          _lives--;
          AudioService().playSFX('hurt.mp3');
          if (_lives <= 0) {
            _endGame();
          } else {
            // Respawn new tank after taking damage
            Future.delayed(const Duration(milliseconds: 500), _spawnTank);
          }
        }
      });
    });
  }

  void _fireAmmo(String tappedAmmo) {
    if (_tanks.isEmpty || _gameState != 'playing') return;

    final target = _tanks.first;
    bool isCorrect = target.correctAnswer == tappedAmmo;
    
    int responseTime = DateTime.now().millisecondsSinceEpoch - target.spawnTimeMs;

    setState(() {
      if (isCorrect) {
        AudioService().playSFX('correct.mp3');
        _score += (10 * _currentLevel);
        _correctAnswers++;
        _responseTimesMs.add(responseTime);
        _tanks.removeAt(0); // Destroy tank
        
        if (_correctAnswers >= 5) {
          _completeLevel();
        } else {
          _spawnTank(); // Spawn next immediately
        }
      } else {
        AudioService().playSFX('wrong.mp3');
        _errors++;
        _score = max(0, _score - 5);
      }
    });
  }

  void _completeLevel() {
    _moveTimer?.cancel();
    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');
    
    int starsCount = 0;
    if (_lives == 3) {
      starsCount = 3;
    } else if (_lives == 2) {
      starsCount = 2;
    } else if (_lives == 1) {
      starsCount = 1;
    }

    final levelIdx = _currentLevel - 1;
    if (starsCount > _starRatings[levelIdx]) {
      _starRatings[levelIdx] = starsCount;
    }

    if (_currentLevel == _highestUnlocked && _currentLevel < 8) {
      _highestUnlocked = _currentLevel + 1;
    }

    int totalTimeSecs = DateTime.now().difference(_startTime!).inSeconds;
    int totalPushed = _correctAnswers + _errors;
    int accuracy = totalPushed > 0 ? ((_correctAnswers / totalPushed) * 100).round() : 0;
    
    int fastestMs = 0;
    int slowestMs = 0;
    int medianMs = 0;
    if (_responseTimesMs.isNotEmpty) {
      _responseTimesMs.sort();
      fastestMs = _responseTimesMs.first;
      slowestMs = _responseTimesMs.last;
      medianMs = _responseTimesMs[_responseTimesMs.length ~/ 2];
    }
    double itemsPerMin = totalTimeSecs > 0 ? (_correctAnswers / (totalTimeSecs / 60)) : 0.0;
    int avgMs = _responseTimesMs.isNotEmpty ? (_responseTimesMs.fold(0, (a, b) => a + b) ~/ _responseTimesMs.length) : 0;

    final appState = context.read<AppState>();
    appState.updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': totalPushed,
      'percentage': accuracy,
      'timeSpent': totalTimeSecs,
      'gameMode': 'Oasis Pattern Defender',
    });

    appState.updateGameAssessment('alienShooterGame', GameSession(
      score: _score, 
      timeSpent: totalTimeSecs, 
      errors: _errors,
      correctAnswers: _correctAnswers,
      totalItems: _correctAnswers,
      avgResponseTimeMs: avgMs,
      fastestResponseTimeMs: fastestMs,
      slowestResponseTimeMs: slowestMs,
      medianResponseTimeMs: medianMs,
      itemsPerMinute: itemsPerMin,
      maxLevelReached: _currentLevel,
    ));
    appState.addPointsFromScore(_score);

    setState(() {
      _tanks.clear();
      _gameState = 'level_complete';
    });
  }

  void _endGame() {
    _moveTimer?.cancel();
    setState(() => _gameState = 'completed');
    AudioService().stopBGM();
    AudioService().playSFX('wrong.mp3');

    int totalTimeSecs = DateTime.now().difference(_startTime!).inSeconds;
    int totalPushed = _correctAnswers + _errors;
    int accuracy = totalPushed > 0 ? ((_correctAnswers / totalPushed) * 100).round() : 0;
    
    int fastestMs = 0;
    int slowestMs = 0;
    int medianMs = 0;
    if (_responseTimesMs.isNotEmpty) {
      _responseTimesMs.sort();
      fastestMs = _responseTimesMs.first;
      slowestMs = _responseTimesMs.last;
      medianMs = _responseTimesMs[_responseTimesMs.length ~/ 2];
    }
    double itemsPerMin = totalTimeSecs > 0 ? (_correctAnswers / (totalTimeSecs / 60)) : 0.0;
    int avgMs = _responseTimesMs.isNotEmpty ? (_responseTimesMs.fold(0, (a, b) => a + b) ~/ _responseTimesMs.length) : 0;

    context.read<AppState>().updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': totalPushed,
      'percentage': accuracy,
      'timeSpent': totalTimeSecs,
      'gameMode': 'Oasis Pattern Defender',
    });

    context.read<AppState>().updateGameAssessment('alienShooterGame', GameSession(
      score: _score, 
      timeSpent: totalTimeSecs, 
      errors: _errors,
      correctAnswers: _correctAnswers,
      totalItems: _correctAnswers,
      avgResponseTimeMs: avgMs,
      fastestResponseTimeMs: fastestMs,
      slowestResponseTimeMs: slowestMs,
      medianResponseTimeMs: medianMs,
      itemsPerMinute: itemsPerMin,
      maxLevelReached: _currentLevel,
    ));
    
    context.read<AppState>().addPointsFromScore(_score);
  }

  // ---------------------------------------------------------------------------
  // BUILDS
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    _screenHeight = MediaQuery.of(context).size.height;
    
    if (_gameState == 'menu') return _buildMenu();
    if (_gameState == 'level_select') return _buildLevelSelect();
    if (_gameState == 'level_complete') return _buildLevelComplete();
    if (_gameState == 'completed') return _buildCompleted();
    return _buildPlaying();
  }

  Widget _buildLevelSelect() {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF78350F)),
                    onPressed: () {
                      setState(() {
                        _gameState = 'menu';
                      });
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Pilih Wilayah Oasis 🏜️',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF78350F),
                          fontFamily: 'Nunito',
                          shadows: [
                            Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final int levelNum = index + 1;
                    final bool isUnlocked = levelNum <= _highestUnlocked;
                    final int rating = _starRatings[index];
                    
                    return GestureDetector(
                      onTap: isUnlocked ? () => _startLevel(levelNum) : null,
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: ClipPath(
                              clipper: HexagonClipper(),
                              child: Container(
                                color: isUnlocked ? const Color(0xFFFBBF24) : const Color(0xFF64748B), // Outer border color
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0), // Outer border width
                                  child: ClipPath(
                                    clipper: HexagonClipper(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: isUnlocked
                                            ? const LinearGradient(
                                                colors: [Color(0xFFB45309), Color(0xFF78350F)], // Deep Military Gold/Amber
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [Color(0xFF334155), Color(0xFF1E293B)], // Dark Iron
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                      ),
                                      child: Center(
                                        child: isUnlocked
                                            ? Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.shield_outlined, color: Colors.white24, size: 20),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    '$levelNum',
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.white,
                                                      shadows: [
                                                        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1))
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Icon(Icons.lock_rounded, color: Colors.white38, size: 22),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (starIdx) {
                              final isStarred = starIdx < rating;
                              return Icon(
                                Icons.star_rounded,
                                color: isStarred ? Colors.amber : Colors.black12,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelComplete() {
    int starsCount = 0;
    if (_lives == 3) {
      starsCount = 3;
    } else if (_lives == 2) {
      starsCount = 2;
    } else if (_lives == 1) {
      starsCount = 1;
    }

    int totalTimeSecs = DateTime.now().difference(_startTime!).inSeconds;
    int totalPushed = _correctAnswers + _errors;
    int accuracy = totalPushed > 0 ? ((_correctAnswers / totalPushed) * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.35),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'WILAYAH AMAN! 🏜️',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final active = index < starsCount;
                  return Icon(
                    Icons.star_rounded,
                    color: active ? Colors.yellowAccent : Colors.white24,
                    size: 55,
                    shadows: active ? [const Shadow(color: Colors.orange, blurRadius: 15)] : null,
                  );
                }),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    _rowStat('Tank Dihancurkan:', '$_correctAnswers'),
                    const Divider(color: Colors.white24),
                    _rowStat('Akurasi Tembakan:', '$accuracy%'),
                    const Divider(color: Colors.white24),
                    _rowStat('Waktu Bertahan:', '$totalTimeSecs detik'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentLevel >= 8) {
                      setState(() {
                        _gameState = 'level_select';
                      });
                    } else {
                      _startLevel(_currentLevel + 1);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFD97706),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                  ),
                  child: Text(
                    _currentLevel >= 8 ? 'Peta Wilayah 🗺️' : 'Wilayah Berikutnya ${_currentLevel + 1} ➡️',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _startLevel(_currentLevel);
                },
                child: const Text('Pertahankan Oasis Ini Lagi 🔄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  setState(() {
                    _gameState = 'level_select';
                  });
                },
                child: const Text('Kembali ke Peta Wilayah 🗺️', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE68A),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(bottom: 200, left: 40, child: Text('🌵', style: TextStyle(fontSize: 80))),
            const Positioned(bottom: 120, right: 30, child: Text('🏜️', style: TextStyle(fontSize: 100))),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🚛💨', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 24),
                    Text('Oasis Pattern\nDefender', style: AppTheme.heading1.copyWith(color: AppTheme.primaryOrange, fontSize: 36), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text('Analisis pola yang dibawa musuh dan tembak dengan urutan emoji yang benar!', style: TextStyle(color: AppTheme.gray800, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Misi Intelijen Anda:', style: AppTheme.heading3),
                          const SizedBox(height: 16),
                          const Text('1. Perhatikan pola emoji pada tank musuh.', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          const Text('2. Tap emoji di bawah yang cocok untuk melengkapi pola yang kosong (?).', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          const Text('3. Latih logika abstraksi Anda dengan cepat!', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _gameState = 'level_select';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Mulai Ujian Pola', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali ke Dashboard', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7),
      body: SafeArea(
        child: Stack(
          children: [
            // BG Scenery
            const Positioned(bottom: 120, right: 30, child: Text('🌵', style: TextStyle(fontSize: 60, color: Colors.green))),
            const Positioned(bottom: 150, left: 20, child: Text('🏜️', style: TextStyle(fontSize: 80))),
            
            // Stats Header
            Positioned(
              top: 16, left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF78350F), size: 20),
                        onPressed: () {
                          _moveTimer?.cancel();
                          AudioService().stopBGM();
                          setState(() {
                            _gameState = 'level_select';
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                        child: Text('Level $_currentLevel', style: AppTheme.heading3.copyWith(color: AppTheme.primaryOrange)),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(3, (index) => Icon(Icons.favorite, color: index < _lives ? Colors.red : Colors.grey.shade300, size: 28)),
                  ),
                ],
              ),
            ),

            // Enemies (Tanks)
            ..._tanks.map((tank) {
              return Positioned(
                top: tank.y,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade600, width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8)]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: tank.sequence.asMap().entries.map((req) {
                            bool isMissing = req.key == tank.missingIndex;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isMissing ? Colors.grey.shade200 : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isMissing ? Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid) : null,
                              ),
                              child: Text(isMissing ? '❓' : req.value, style: const TextStyle(fontSize: 32)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.green, size: 32),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Base & Cannon & Ammo
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 180,
                padding: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    const Text('🟢 MERIAM OASIS 🟢', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _currentAmmoOptions.map((ammo) {
                        return GestureDetector(
                          onTap: () => _fireAmmo(ammo),
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 6)]
                            ),
                            child: Center(child: Text(ammo, style: const TextStyle(fontSize: 36))),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return Scaffold(
      backgroundColor: const Color(0xFFEF4444),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💥', style: TextStyle(fontSize: 100)),
                const SizedBox(height: 24),
                Text('Pertahanan Oasis\nTembus!', style: AppTheme.heading1.copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _rowStat('Tank Dihancurkan', '$_correctAnswers'),
                      const Divider(),
                      _rowStat('Kesalahan Pola', '$_errors'),
                      const Divider(),
                      _rowStat('Skor Akhir', '$_score'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startLevel(_currentLevel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Coba Lagi Level $_currentLevel', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _gameState = 'level_select';
                    });
                  },
                  child: const Text('Kembali ke Peta Misi 🗺️', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rowStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
        ],
      ),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.25, 0);
    path.lineTo(size.width * 0.75, 0);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width * 0.75, size.height);
    path.lineTo(size.width * 0.25, size.height);
    path.lineTo(0, size.height * 0.5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
