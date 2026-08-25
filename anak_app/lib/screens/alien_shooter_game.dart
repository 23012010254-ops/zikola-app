import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../services/app_state.dart';
import '../services/assessment_engine.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class AlienTarget {
  final int id;
  double x;
  double y;
  final String problem;
  final dynamic answer;
  final List<dynamic> options;
  final dynamic correctAnswer;
  bool destroyed;
  final double speed;
  final int spawnTime;

  AlienTarget({
    required this.id,
    required this.x,
    required this.y,
    required this.problem,
    required this.answer,
    required this.options,
    required this.correctAnswer,
    this.destroyed = false,
    required this.speed,
    required this.spawnTime,
  });
}

class MathProblem {
  final String problem;
  final dynamic answer;
  final List<dynamic> options;

  MathProblem({required this.problem, required this.answer, required this.options});
}

class AlienShooterGame extends StatefulWidget {
  const AlienShooterGame({super.key});

  @override
  State<AlienShooterGame> createState() => _AlienShooterGameState();
}

class _AlienShooterGameState extends State<AlienShooterGame> with TickerProviderStateMixin {
  String _gameState = 'menu'; // 'menu', 'level_select', 'playing', 'level_complete', 'completed'
  int _currentLevel = 1;
  int _score = 0;
  int _lives = 3;
  int _timeLeft = 60;
  List<AlienTarget> _aliens = [];
  int _hits = 0;
  int _misses = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  DateTime? _startTime;
  int? _selectedAlienId;
  bool _isPaused = false;
  bool _showHurtFlash = false;
  
  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _loopTimer;
  
  final Random _random = Random();
  double _screenWidth = 0;
  double _screenHeight = 0;

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _loopTimer?.cancel();
    AudioService().stopBGM();
    super.dispose();
  }

  MathProblem _generateMathProblem(int level) {
    if (level == 1) {
      // Penjumlahan saja (angka 1 s.d. 30)
      int a = _random.nextInt(20) + 5;
      int b = _random.nextInt(15) + 1;
      int ans = a + b;
      return MathProblem(problem: '$a + $b', answer: ans, options: _generateOptions(ans, 4));
    } else if (level == 2) {
      // Penjumlahan & Pengurangan (angka 1 s.d. 50)
      int a = _random.nextInt(35) + 10;
      int b = _random.nextInt(25) + 5;
      bool isAdd = _random.nextBool();
      if (!isAdd && a < b) {
        int temp = a;
        a = b;
        b = temp;
      }
      int ans = isAdd ? a + b : a - b;
      return MathProblem(problem: '$a ${isAdd ? '+' : '-'} $b', answer: ans, options: _generateOptions(ans, 4));
    } else if (level == 3) {
      // Perkalian dasar (perkalian 2 s.d. 10)
      int a = _random.nextInt(9) + 2; // 2..10
      int b = _random.nextInt(9) + 2; // 2..10
      int ans = a * b;
      return MathProblem(problem: '$a × $b', answer: ans, options: _generateOptions(ans, 4));
    } else if (level == 4) {
      // Pembagian dasar (pembagian dengan hasil 2 s.d. 10)
      int divisor = _random.nextInt(8) + 2; // 2..9
      int quotient = _random.nextInt(9) + 2; // 2..10
      int dividend = divisor * quotient;
      return MathProblem(problem: '$dividend ÷ $divisor', answer: quotient, options: _generateOptions(quotient, 4));
    } else if (level == 5) {
      // Pecahan sederhana ke desimal
      List<int> numerators = [1, 1, 2, 3, 1, 2, 3, 4, 1, 2, 3, 4];
      List<int> denominators = [2, 3, 4, 4, 5, 5, 5, 5, 10, 10, 10, 10];
      int idx = _random.nextInt(numerators.length);
      int num = numerators[idx];
      int den = denominators[idx];
      if (num >= den) {
        num = num % den;
        if (num == 0) num = 1;
      }
      double decimal = (num / den * 100).round() / 100;
      return MathProblem(problem: '$num/$den', answer: decimal, options: _generateDecimalOptions(decimal));
    } else if (level == 6) {
      // Campuran Penjumlahan & Pengurangan (dua digit)
      int a = _random.nextInt(40) + 15;
      int b = _random.nextInt(30) + 10;
      int c = _random.nextInt(25) + 5;
      bool startAdd = _random.nextBool();
      int ans;
      String prob;
      if (startAdd) {
        if (a + b < c) {
          c = _random.nextInt(a + b - 5) + 2;
        }
        ans = a + b - c;
        prob = '$a + $b - $c';
      } else {
        if (a < b) {
          int temp = a;
          a = b;
          b = temp;
        }
        ans = a - b + c;
        prob = '$a - $b + $c';
      }
      return MathProblem(problem: prob, answer: ans, options: _generateOptions(ans, 4));
    } else if (level == 7) {
      // Campuran Perkalian & Pembagian
      int a = _random.nextInt(8) + 3; // 3..10
      int b = _random.nextInt(6) + 2; // 2..7
      int product = a * b;
      List<int> divisors = [];
      for (int i = 2; i <= product; i++) {
        if (product % i == 0 && i != product) {
          divisors.add(i);
        }
      }
      int divisor;
      if (divisors.isNotEmpty) {
        divisor = divisors[_random.nextInt(divisors.length)];
      } else {
        divisor = a;
      }
      int ans = product ~/ divisor;
      return MathProblem(problem: '($a × $b) ÷ $divisor', answer: ans, options: _generateOptions(ans, 4));
    } else {
      // Level 8: Campuran Semua Operasi Lanjut (menantang)
      int type = _random.nextInt(3);
      if (type == 0) {
        int a = _random.nextInt(10) + 2;
        int b = _random.nextInt(8) + 2;
        int c = _random.nextInt(30) + 5;
        int ans = a * b + c;
        return MathProblem(problem: '($a × $b) + $c', answer: ans, options: _generateOptions(ans, 4));
      } else if (type == 1) {
        int a = _random.nextInt(10) + 2;
        int b = _random.nextInt(8) + 2;
        int c = _random.nextInt(15) + 2;
        if (a * b < c) c = _random.nextInt(a * b - 2) + 1;
        int ans = a * b - c;
        return MathProblem(problem: '($a × $b) - $c', answer: ans, options: _generateOptions(ans, 4));
      } else {
        int a = _random.nextInt(15) + 5;
        int b = _random.nextInt(15) + 5;
        int c = _random.nextInt(5) + 2;
        int ans = (a - b).abs() * c;
        return MathProblem(problem: '|${a} - ${b}| × $c', answer: ans, options: _generateOptions(ans, 4));
      }
    }
  }

  List<dynamic> _generateOptions(int correct, int count) {
    List<dynamic> options = [correct];
    int attempts = 0;
    while (options.length < count && attempts < 100) {
      attempts++;
      int offset = _random.nextInt(20) - 10;
      int option = correct + offset;
      if (option != correct && option >= 0 && !options.contains(option)) {
        options.add(option);
      }
    }
    while (options.length < count) {
      options.add(correct + options.length + 1);
    }
    options.shuffle();
    return options;
  }

  List<dynamic> _generateDecimalOptions(double correct) {
    List<dynamic> options = [correct];
    List<double> variations = [0.1, 0.2, 0.25, 0.33, 0.5, 0.67, 0.75];
    for (int i = 0; i < 3; i++) {
      double option = variations[_random.nextInt(variations.length)];
      if (!options.contains(option)) {
        options.add(option);
      }
    }
    int attempts = 0;
    while (options.length < 4 && attempts < 100) {
      attempts++;
      double option = (_random.nextDouble() * 100).round() / 100;
      if (!options.contains(option)) {
        options.add(option);
      }
    }
    while (options.length < 4) {
      options.add(correct + (options.length / 10));
    }
    options.shuffle();
    return options;
  }

  void _startLevel(int level) {
    setState(() {
      _gameState = 'playing';
      _currentLevel = level;
      _score = 0;
      _lives = 3;
      _timeLeft = 60;
      _hits = 0;
      _misses = 0;
      _correctAnswers = 0;
      _totalQuestions = 0;
      _startTime = DateTime.now();
      _aliens = [];
      _selectedAlienId = null;
      _isPaused = false;
    });

    AudioService().playBGM('space_adventure.mp3', volume: 0.3);

    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _loopTimer?.cancel();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState == 'playing' && !_isPaused) {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          _endGame();
        }
      }
    });

    _startSpawning();
    _startGameLoop();
  }

  void _startSpawning() {
    _spawnTimer?.cancel();
    int spawnDelay = max(1000, 3000 - (_currentLevel * 250));
    _spawnTimer = Timer.periodic(Duration(milliseconds: spawnDelay), (timer) {
      if (_gameState == 'playing' && !_isPaused && _aliens.length < 3) {
        _spawnAlien();
      }
      if (_gameState != 'playing') timer.cancel();
    });
  }

  void _startGameLoop() {
    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_gameState == 'playing' && !_isPaused) {
        setState(() {
          for (var alien in _aliens) {
            alien.y += alien.speed;
          }
          
          List<AlienTarget> escaped = _aliens.where((a) => a.y >= _screenHeight - 150 && !a.destroyed).toList();
          if (escaped.isNotEmpty) {
            _lives -= escaped.length;
            _triggerHurtFlash();
            if (_lives <= 0) {
              _lives = 0;
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_gameState == 'playing') _endGame();
              });
            } else {
              AudioService().playSFX('hurt.mp3', volume: 1.0);
            }
          }
          
          _aliens.removeWhere((a) => a.y >= _screenHeight - 150);
        });
      }
      if (_gameState != 'playing') timer.cancel();
    });
  }

  void _spawnAlien() {
    if (_screenWidth == 0) return;
    MathProblem problem = _generateMathProblem(_currentLevel);
    double alienX = _random.nextDouble() * (_screenWidth - 100);
    
    setState(() {
      _aliens.add(AlienTarget(
        id: DateTime.now().millisecondsSinceEpoch + _random.nextInt(1000),
        x: alienX,
        y: 50,
        problem: problem.problem,
        answer: problem.answer,
        options: problem.options,
        correctAnswer: problem.answer,
        speed: 1 + (_currentLevel * 0.3) + (_screenHeight * 0.001),
        spawnTime: DateTime.now().millisecondsSinceEpoch,
      ));
    });
  }

  void _shootAlien(int id, dynamic answer) {
    if (_selectedAlienId != id || _gameState != 'playing') return;
    
    setState(() {
      _selectedAlienId = null;
      _isPaused = false;
      _totalQuestions++;
    });

    AudioService().playSFX('laser_shoot.mp3', volume: 1.0);

    var alienIdx = _aliens.indexWhere((a) => a.id == id);
    if (alienIdx == -1) return;
    var alien = _aliens[alienIdx];
    if (alien.destroyed) return;

    bool isCorrect = answer == alien.correctAnswer;
    
    setState(() {
      if (isCorrect) {
        _score += 10 * _currentLevel;
        _hits++;
        _correctAnswers++;
        context.read<AppState>().addSticker('alien-hunter');
        AudioService().playSFX('correct.mp3', volume: 1.0);
        
        if (_correctAnswers >= 5) {
          _completeLevel();
          return;
        }
      } else {
        _misses++;
        _lives--;
        _triggerHurtFlash();
        AudioService().playSFX('wrong.mp3', volume: 1.0);
        if (_lives <= 0) {
          _lives = 0;
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_gameState == 'playing') _endGame();
          });
          return;
        }
      }
      _aliens.removeAt(alienIdx);
    });
  }

  void _completeLevel() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _loopTimer?.cancel();
    
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

    int totalTime = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;
    int accuracy = _totalQuestions > 0 ? ((_correctAnswers / _totalQuestions) * 100).round() : 0;
    final int avgRespMs = _totalQuestions > 0 ? ((totalTime * 1000) / _totalQuestions).round() : 0;

    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: _totalQuestions,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 4000,
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _misses,
    );

    final appState = context.read<AppState>();
    appState.updateGameAssessment('alienShooterGame', GameSession(
      score: _score,
      timeSpent: totalTime,
      errors: _misses,
      totalItems: _totalQuestions,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'hits': _hits,
        'livesRemaining': _lives,
        'accuracy': accuracy,
        'stars': starsCount,
      },
      subdomainScores: {
        'fluidReasoning': assessScore,
        'processingSpeed': (avgRespMs > 0 && avgRespMs < 8000)
            ? ((1 - (avgRespMs - 1000).clamp(0, 7000) / 7000) * 100).clamp(0, 100)
            : 0.0,
      },
    ));
    appState.addPointsFromScore(_score);

    appState.updateTestResults(
      'cognitive',
      {
        'score': _correctAnswers,
        'total': _totalQuestions,
        'percentage': accuracy.toDouble(),
        'timeSpent': totalTime,
        'fluidReasoningScore': assessScore,
      },
    );

    if (accuracy >= 90) appState.addSticker('alien-master');
    appState.addSticker('alien-hunter');

    AudioService().stopBGM();
    AudioService().playSFX('level_complete.mp3', volume: 1.0);

    setState(() {
      _aliens.clear();
      _selectedAlienId = null;
      _isPaused = false;
      _gameState = 'level_complete';
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _loopTimer?.cancel();
    
    setState(() {
      _aliens.clear();
      _selectedAlienId = null;
      _isPaused = false;
      _gameState = 'completed';
    });
    
    AudioService().stopBGM();
    AudioService().playSFX('game_over.mp3', volume: 0.5);

    int totalTime = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;
    int accuracy = _totalQuestions > 0 ? ((_correctAnswers / _totalQuestions) * 100).round() : 0;
    final int avgRespMs = _totalQuestions > 0 ? ((totalTime * 1000) / _totalQuestions).round() : 0;

    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: _totalQuestions,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 4000,
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _misses,
    );

    context.read<AppState>().updateGameAssessment('alienShooterGame', GameSession(
      score: _score,
      timeSpent: totalTime,
      errors: _misses,
      totalItems: _totalQuestions,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'hits': _hits,
        'livesRemaining': _lives,
        'accuracy': accuracy,
      },
      subdomainScores: {
        'fluidReasoning': assessScore,
        'processingSpeed': (avgRespMs > 0 && avgRespMs < 8000)
            ? ((1 - (avgRespMs - 1000).clamp(0, 7000) / 7000) * 100).clamp(0, 100)
            : 0.0,
      },
    ));
    context.read<AppState>().addPointsFromScore(_score);

    context.read<AppState>().updateTestResults(
      'cognitive',
      {
        'score': _correctAnswers,
        'total': _totalQuestions,
        'percentage': accuracy.toDouble(),
        'timeSpent': totalTime,
        'fluidReasoningScore': assessScore,
      },
    );
  }

  void _triggerHurtFlash() {
    setState(() => _showHurtFlash = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showHurtFlash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_screenWidth == 0) {
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;
    }

    if (_gameState == 'menu') return _buildMenuScreen();
    if (_gameState == 'level_select') return _buildLevelSelectScreen();
    if (_gameState == 'level_complete') return _buildLevelCompleteScreen();
    if (_gameState == 'completed') return _buildCompletedScreen();
    return _buildPlayingScreen();
  }

  Widget _buildLevelSelectScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF581C87), Color(0xFF1E3A8A), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildStarsBackground()),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _gameState = 'menu';
                            });
                          },
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Pilih Misi Luar Angkasa 🌌',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Nunito',
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
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

                          // Dynamic planet gradients
                          final Gradient planetGradient = !isUnlocked
                              ? const RadialGradient(colors: [Color(0xFF334155), Color(0xFF1E293B)])
                              : (levelNum % 4 == 1)
                                  ? const RadialGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)], center: Alignment(-0.3, -0.3), radius: 0.8) // Blue Planet
                                  : (levelNum % 4 == 2)
                                      ? const RadialGradient(colors: [Color(0xFF34D399), Color(0xFF059669)], center: Alignment(-0.3, -0.3), radius: 0.8) // Green Planet
                                      : (levelNum % 4 == 3)
                                          ? const RadialGradient(colors: [Color(0xFFFBBF24), Color(0xFFD97706)], center: Alignment(-0.3, -0.3), radius: 0.8) // Yellow/Orange Planet
                                          : const RadialGradient(colors: [Color(0xFFF472B6), Color(0xFF8B5CF6)], center: Alignment(-0.3, -0.3), radius: 0.8); // Pink/Purple Planet

                          final Color ringColor = !isUnlocked
                              ? Colors.white12
                              : (levelNum % 4 == 1)
                                  ? Colors.cyanAccent
                                  : (levelNum % 4 == 2)
                                      ? Colors.greenAccent
                                      : (levelNum % 4 == 3)
                                          ? Colors.amberAccent
                                          : Colors.purpleAccent;
                          
                          return GestureDetector(
                            onTap: isUnlocked ? () => _startLevel(levelNum) : null,
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Planet Ring (Back part)
                                      Transform.rotate(
                                        angle: -0.3,
                                        child: Container(
                                          width: 74,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: ringColor.withOpacity(0.4),
                                              width: 3.5,
                                            ),
                                            borderRadius: const BorderRadius.all(Radius.elliptical(74, 22)),
                                          ),
                                        ),
                                      ),
                                      // Planet Body
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          gradient: planetGradient,
                                          shape: BoxShape.circle,
                                          boxShadow: isUnlocked
                                              ? [
                                                  BoxShadow(
                                                    color: ringColor.withOpacity(0.4),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  )
                                                ]
                                              : [],
                                        ),
                                        child: Center(
                                          child: isUnlocked
                                              ? Text(
                                                  '$levelNum',
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1))
                                                    ],
                                                  ),
                                                )
                                              : const Icon(Icons.lock_rounded, color: Colors.white38, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (starIdx) {
                                    final isStarred = starIdx < rating;
                                    return Icon(
                                      Icons.star_rounded,
                                      color: isStarred ? Colors.yellowAccent : Colors.white10,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCompleteScreen() {
    int starsCount = 0;
    if (_lives == 3) {
      starsCount = 3;
    } else if (_lives == 2) {
      starsCount = 2;
    } else if (_lives == 1) {
      starsCount = 1;
    }

    int accuracy = _totalQuestions > 0 ? ((_correctAnswers / _totalQuestions) * 100).round() : 0;
    int totalTime = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: Stack(
        children: [
          Positioned.fill(child: _buildStarsBackground()),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B0764), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.cyanAccent, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MISI BERHASIL! 🚀',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
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
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('UFO Hancur:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('$_correctAnswers', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Akurasi Tembakan:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('$accuracy%', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Waktu Tempuh:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('$totalTime detik', style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.w900, fontSize: 18)),
                          ],
                        ),
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
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                      ),
                      child: Text(
                        _currentLevel >= 8 ? 'Peta Misi 🗺️' : 'Misi Berikutnya ${_currentLevel + 1} ➡️',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _startLevel(_currentLevel);
                    },
                    child: const Text('Ulangi Misi Ini 🔄', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _gameState = 'level_select';
                      });
                    },
                    child: const Text('Kembali ke Peta Misi 🗺️', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF581C87), Color(0xFF1E3A8A), Colors.black]), // purple-900 via blue-900 to black
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildStarsBackground()),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text('Alien Math Shooter', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 48),
                            const Text('🛸', style: TextStyle(fontSize: 80)),
                            const SizedBox(height: 24),
                            const Text('Pertahanan Bumi dari Alien Matematika!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            const Text('Selamatkan bumi dengan menembak UFO yang membawa soal matematika yang benar!', style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 16), textAlign: TextAlign.center), // purple-200
                            const SizedBox(height: 32),

                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cara Bermain:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 20),
                                  _buildInstructionRow(Icons.my_location, 'Tap UFO lalu pilih jawaban benar', const Color(0xFFA855F7)),
                                  const SizedBox(height: 12),
                                  _buildInstructionRow(Icons.access_time, 'Selesaikan misi dengan 5 jawaban benar', const Color(0xFF3B82F6)),
                                  const SizedBox(height: 12),
                                  _buildInstructionRow(Icons.favorite, 'Hati-hati! Nyawa terbatas!', const Color(0xFFEF4444)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity,
                              height: 70,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _gameState = 'level_select';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF472B6), // Pink
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 8,
                                ),
                                child: Text('Gass Main! 🚀', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFE9D5FF)))),
      ],
    );
  }

  Widget _buildPlayingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF581C87), Color(0xFF1E3A8A), Colors.black]),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildStarsBackground()),
              // Hurt Flash Overlay
              if (_showHurtFlash)
                Positioned.fill(
                  child: Container(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
              // HUD
              Positioned(
                top: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _gameTimer?.cancel();
                              _spawnTimer?.cancel();
                              _loopTimer?.cancel();
                              AudioService().stopBGM();
                              setState(() {
                                _gameState = 'level_select';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.arrow_back, color: Colors.white),
                            ),
                          ),
                          Row(
                            children: [
                              Text('HIT: $_hits', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 12),
                              Text('MISS: $_misses', style: const TextStyle(color: Color(0xFFE9D5FF), fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 12),
                              Text('❤️ $_lives', style: const TextStyle(color: Color(0xFFBFDBFE), fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text('${_timeLeft}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Level $_currentLevel • Skor: $_score', style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 14)),
                    ],
                  ),
                ),
              ),

              // Earth defender cannon
              const Positioned(
                bottom: 32,
                left: 0, right: 0,
                child: Center(child: Text('🚀', style: TextStyle(fontSize: 60))),
              ),
              
              // Instruction
              Positioned(
                bottom: 100,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.cyanAccent, width: 2)),
                    child: Text('Tap UFO untuk menembak!', style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 14)),
                  ),
                ),
              ),

              // Aliens
              ..._aliens.map((alien) => Positioned(
                left: alien.x,
                top: alien.y,
                child: GestureDetector(
                  onTap: () {
                    if (_selectedAlienId == null && _gameState == 'playing') {
                      setState(() {
                        _selectedAlienId = alien.id;
                        _isPaused = true;
                      });
                    }
                  },
                  child: Transform.scale(
                    scale: _selectedAlienId == alien.id ? 1.25 : 1.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Answer badge above UFO
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                          ),
                          child: Text(
                            alien.problem,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('🛸', style: TextStyle(fontSize: 60)),
                      ],
                    ),
                  ),
                ),
              )),

              // Question Popup
              if (_selectedAlienId != null && _aliens.any((a) => a.id == _selectedAlienId))
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 30)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🛸', style: TextStyle(fontSize: 80)),
                            const SizedBox(height: 24),
                            Text(
                              _aliens.firstWhere((a) => a.id == _selectedAlienId).problem,
                              style: TextStyle(color: const Color(0xFF1E293B), fontSize: 48, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 32),
                            
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 2.0,
                              children: _aliens.firstWhere((a) => a.id == _selectedAlienId).options.map((opt) {
                                return ElevatedButton(
                                  onPressed: () => _shootAlien(_selectedAlienId!, opt),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF38BDF8),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 6,
                                    shadowColor: const Color(0xFF38BDF8).withOpacity(0.4),
                                  ),
                                  child: Text('$opt', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),

                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedAlienId = null;
                                  _isPaused = false;
                                });
                              },
                              child: Text('Batal', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w700)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen() {
    int accuracy = _totalQuestions > 0 ? ((_correctAnswers / _totalQuestions) * 100).round() : 0;
    int totalTime = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;
    String childName = context.read<AppState>().childProfile.name;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF581C87), Color(0xFF1E3A8A), Colors.black]),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildStarsBackground()),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      Text(_lives > 0 ? '🏆' : '💫', style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 24),
                  Text(_lives > 0 ? 'Bumi Selamat, $childName!' : 'Pertahanan Berakhir, $childName!', style: AppTheme.heading2.copyWith(color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatBox('$_correctAnswers', 'UFO Dihancurkan')),
                            Expanded(child: _buildStatBox('$accuracy%', 'Akurasi')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildStatBox('$_currentLevel', 'Level Tertinggi')),
                            Expanded(child: _buildStatBox('$_lives', 'Nyawa Tersisa')),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Analisis Kemampuan:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildAnalysisRow('Logika & Matematika:', '${(accuracy / 100 * 25).round()}/25'),
                              _buildAnalysisRow('Perhatian & Fokus:', '${_hits > 0 ? (_hits / max(_hits + _misses, 1) * 25).round() : 0}/25'),
                              _buildAnalysisRow('Kemampuan Adaptasi:', '${(_currentLevel / 4 * 25).round()}/25'),
                              _buildAnalysisRow('Waktu Bertahan:', '$totalTime detik'),
                            ],
                          ),
                        ),

                        if (accuracy >= 90) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), border: Border.all(color: Colors.green.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                            child: const Text('🌟 Excellent! Kamu pahlawan matematika sejati!', style: TextStyle(color: Color(0xFFDCFCE7), fontWeight: FontWeight.bold)),
                          ),
                        ] else if (accuracy >= 70) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), border: Border.all(color: Colors.blue.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                            child: const Text('👍 Good! Terus latih kemampuan matematikamu!', style: TextStyle(color: Color(0xFFDBEAFE), fontWeight: FontWeight.bold)),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), border: Border.all(color: Colors.purple.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                            child: const Text('💪 Keep practicing! Matematika akan semakin mudah!', style: TextStyle(color: Color(0xFFF3E8FF), fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _startLevel(_currentLevel);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF1D4ED8)]), borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(minHeight: 56),
                          child: Text('🔄 Coba Lagi Level $_currentLevel', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _gameState = 'level_select';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Kembali ke Peta Misi 🗺️', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 12), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('• $label $val', style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 14)),
    );
  }

  Widget _buildStarsBackground() {
    return Stack(
      children: const [
        Positioned(top: 80, left: 40, child: TwinklingStar(text: '⭐', size: 14, color: Colors.yellowAccent)),
        Positioned(top: 120, right: 30, child: TwinklingStar(text: '✨', size: 12, color: Colors.yellowAccent, delay: 500)),
        Positioned(top: 200, left: 24, child: TwinklingStar(text: '⭐', size: 12, color: Colors.white, delay: 1000)),
        Positioned(top: 160, right: 80, child: TwinklingStar(text: '✨', size: 14, color: Colors.yellow, delay: 200)),
        Positioned(bottom: 160, left: 48, child: TwinklingStar(text: '⭐', size: 12, color: Colors.yellowAccent, delay: 800)),
        Positioned(bottom: 240, right: 24, child: TwinklingStar(text: '✨', size: 14, color: Colors.white, delay: 1200)),
        Positioned(top: 240, left: 120, child: TwinklingStar(text: '⭐', size: 12, color: Colors.yellow, delay: 400)),
      ],
    );
  }
}

class TwinklingStar extends StatefulWidget {
  final String text;
  final double size;
  final Color color;
  final int delay;

  const TwinklingStar({
    super.key,
    required this.text,
    required this.size,
    required this.color,
    this.delay = 0,
  });

  @override
  State<TwinklingStar> createState() => _TwinklingStarState();
}

class _TwinklingStarState extends State<TwinklingStar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: widget.size,
          color: widget.color,
        ),
      ),
    );
  }
}

