import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class MotorTestGameScreen extends StatefulWidget {
  const MotorTestGameScreen({super.key});

  @override
  State<MotorTestGameScreen> createState() => _MotorTestGameScreenState();
}

class _MotorTestGameScreenState extends State<MotorTestGameScreen> with TickerProviderStateMixin {
  int _score = 0; // Cumulative score
  int _misses = 0; // Cumulative misses
  int _totalTargets = 0; // Cumulative targets
  
  // Leveling State
  int _currentLevel = 1;
  final int _maxLevels = 8;
  int _levelScore = 0;
  int _levelMisses = 0;
  int _levelTargetsAppeared = 0;
  
  int _activeHoleIndex = -1;
  int _whackedHoleIndex = -1;
  String _gamePhase = 'intro'; // intro, level_select, playing, level_complete, results
  
  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;
  
  Timer? _gameTimer;
  Timer? _moleTimer;
  DateTime? _moleAppearTime;
  List<int> _reactionTimes = [];
  
  // Animation controllers for Intro and Results
  late AnimationController _introAnimCtrl;
  late AnimationController _resultsAnimCtrl;

  @override
  void initState() {
    super.initState();
    _introAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _resultsAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _introAnimCtrl.dispose();
    _resultsAnimCtrl.dispose();
    _gameTimer?.cancel();
    _moleTimer?.cancel();
    AudioService().stopBGM();
    super.dispose();
  }

  int _getLevelTotalTargets(int level) {
    switch (level) {
      case 1: return 6;
      case 2: return 8;
      case 3: return 8;
      case 4: return 10;
      case 5: return 10;
      case 6: return 12;
      case 7: return 12;
      case 8: return 15;
      default: return 10;
    }
  }

  int _getLevelInitialSpeed(int level) {
    switch (level) {
      case 1: return 1500;
      case 2: return 1400;
      case 3: return 1300;
      case 4: return 1200;
      case 5: return 1100;
      case 6: return 1000;
      case 7: return 900;
      case 8: return 800;
      default: return 1000;
    }
  }

  int _getLevelSpeedDecrease(int level) {
    switch (level) {
      case 1: return 50;
      case 2: return 45;
      case 3: return 40;
      case 4: return 35;
      case 5: return 30;
      case 6: return 25;
      case 7: return 20;
      case 8: return 15;
      default: return 30;
    }
  }

  int _getLevelMinSpeed(int level) {
    switch (level) {
      case 1: return 1000;
      case 2: return 900;
      case 3: return 800;
      case 4: return 700;
      case 5: return 600;
      case 6: return 500;
      case 7: return 450;
      case 8: return 400;
      default: return 500;
    }
  }

  void _startLevel(int level) {
    setState(() {
      _gamePhase = 'playing';
      _currentLevel = level;
      _levelScore = 0;
      _levelMisses = 0;
      _levelTargetsAppeared = 0;
      _reactionTimes = [];
      _activeHoleIndex = -1;
      _whackedHoleIndex = -1;
    });
    AudioService().playGameBGM();
    _spawnMole();
  }

  void _spawnMole() {
    _moleTimer?.cancel();
    
    final int levelTargets = _getLevelTotalTargets(_currentLevel);
    if (_levelTargetsAppeared >= levelTargets) {
      _completeLevel();
      return;
    }

    int baseSpeed = _getLevelInitialSpeed(_currentLevel);
    int decrease = _getLevelSpeedDecrease(_currentLevel);
    int minSpeed = _getLevelMinSpeed(_currentLevel);
    int displayDurationMs = max(minSpeed, baseSpeed - (_levelTargetsAppeared * decrease));

    setState(() {
      _levelTargetsAppeared++;
      _totalTargets++;
      
      int nextHole;
      do {
        nextHole = Random().nextInt(9);
      } while (nextHole == _activeHoleIndex);
      
      _activeHoleIndex = nextHole;
      _moleAppearTime = DateTime.now();
    });

    AudioService().playClick(); 

    _moleTimer = Timer(Duration(milliseconds: displayDurationMs), () {
      if (_gamePhase == 'playing' && _activeHoleIndex != -1) {
        setState(() {
          _levelMisses++;
          _misses++;
          _activeHoleIndex = -1;
        });
        AudioService().playWrong();
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_gamePhase == 'playing') _spawnMole();
        });
      }
    });
  }

  void _whackMole(int index) {
    if (_gamePhase != 'playing' || index != _activeHoleIndex) return;

    if (_moleAppearTime != null) {
      final reaction = DateTime.now().difference(_moleAppearTime!).inMilliseconds;
      _reactionTimes.add(reaction);
    }

    _moleTimer?.cancel();
    
    setState(() {
      _levelScore++;
      _score++;
      _whackedHoleIndex = index;
      _activeHoleIndex = -1;
    });
    
    AudioService().playCorrect();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          if (_whackedHoleIndex == index) {
            _whackedHoleIndex = -1;
          }
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_gamePhase == 'playing') _spawnMole();
    });
  }

  void _completeLevel() {
    _moleTimer?.cancel();
    AudioService().stopBGM();
    AudioService().playAchievement();

    final int levelTargets = _getLevelTotalTargets(_currentLevel);
    final accuracy = levelTargets > 0 ? (_levelScore / levelTargets) : 0.0;
    
    int starsCount = 0;
    if (accuracy >= 0.85) {
      starsCount = 3;
    } else if (accuracy >= 0.60) {
      starsCount = 2;
    } else if (accuracy >= 0.35) {
      starsCount = 1;
    }

    final levelIdx = _currentLevel - 1;
    if (starsCount > _starRatings[levelIdx]) {
      _starRatings[levelIdx] = starsCount;
    }

    if (_currentLevel == _highestUnlocked && _currentLevel < _maxLevels) {
      _highestUnlocked = _currentLevel + 1;
    }

    final percentage = (accuracy * 100).round();
    int avgReactionTime = 0;
    if (_reactionTimes.isNotEmpty) {
      avgReactionTime = _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
    }

    final appState = context.read<AppState>();
    appState.updateTestResults('motor', {
      'score': _levelScore,
      'total': levelTargets,
      'percentage': percentage,
      'misses': _levelMisses,
      'averageReactionTimeMs': avgReactionTime,
    });

    appState.updateGameAssessment('motor', GameSession(
      score: _levelScore * 10, 
      timeSpent: 30,
      errors: _levelMisses,
      correctAnswers: _levelScore,
      totalItems: levelTargets,
      avgResponseTimeMs: avgReactionTime,
      fastestResponseTimeMs: _reactionTimes.isNotEmpty ? _reactionTimes.reduce(min) : 0,
      slowestResponseTimeMs: _reactionTimes.isNotEmpty ? _reactionTimes.reduce(max) : 0,
      medianResponseTimeMs: avgReactionTime,
      itemsPerMinute: 30 > 0 ? (_levelScore / (30 / 60)) : 0.0,
      maxLevelReached: _currentLevel,
    ));
    
    appState.addPointsFromScore(percentage);

    if (percentage >= 85) {
      appState.addSticker('motor-master');
    } else if (percentage >= 60) {
      appState.addSticker('motor-star');
    }

    setState(() {
      _activeHoleIndex = -1;
      _gamePhase = 'level_complete';
    });
  }



  Map<String, dynamic> _getScoreMessage() {
    final percentage = _totalTargets > 0 ? (_score / _totalTargets) : 0.0;
    if (percentage >= 0.85) return {'message': '🏆 Kilat! Refleksmu sangat tajam!', 'color': AppTheme.yellow500};
    if (percentage >= 0.60) return {'message': '⭐ Bagus Sekali! Tanganmu cepat!', 'color': AppTheme.blue500};
    if (percentage >= 0.40) return {'message': '👍 Lumayan! Terus latih jeli matamu!', 'color': AppTheme.green500};
    return {'message': '💪 Semangat! Coba kejar kelincinya lagi!', 'color': AppTheme.purple500};
  }

  @override
  Widget build(BuildContext context) {
    if (_gamePhase == 'intro') return _buildIntroScreen();
    if (_gamePhase == 'level_select') return _buildLevelSelectScreen();
    if (_gamePhase == 'level_complete') return _buildLevelCompleteScreen();
    if (_gamePhase == 'results') return _buildResultsScreen();
    return _buildPlayingScreen();
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // green-50
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _introAnimCtrl,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, sin(_introAnimCtrl.value * 2 * pi) * 10),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 30, spreadRadius: 10)
                          ]
                        ),
                        child: const Text('🐰', style: TextStyle(fontSize: 80)),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 48),
                Text('Tangkap Kelinci!', style: AppTheme.heading1.copyWith(color: AppTheme.green600, fontSize: 32)),
                const SizedBox(height: 16),
                Text(
                  'Uji seberapa cepat matamu melihat dan tanganmu menangkap kelinci nakal yang muncul dari lubang!',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText.copyWith(fontSize: 16, color: AppTheme.gray600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Text('Ketuk secepat mungkin!', style: TextStyle(color: AppTheme.green600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _gamePhase = 'level_select';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.green500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: AppTheme.green500.withOpacity(0.5),
                    ),
                    child: const Text('Mulai Bermain!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Kembali', style: TextStyle(color: AppTheme.gray500, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayingScreen() {
    final int levelTargets = _getLevelTotalTargets(_currentLevel);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF042F2E), Color(0xFF022C22)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Wood Panel Header stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF78350F), Color(0xFF451A03)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.amber.withOpacity(0.5), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Level Indicator
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.amberAccent, size: 18),
                          onPressed: () {
                            _moleTimer?.cancel();
                            AudioService().stopBGM();
                            setState(() {
                              _gamePhase = 'level_select';
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TINGKAT', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            Text('Level $_currentLevel/$_maxLevels', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                    // Captured stats
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Text('🐰', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tangkap', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('$_levelScore / $levelTargets', style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                    // Misses stats
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 4),
                          Text('Meleset: $_levelMisses', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Board Grid
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        final isActive = index == _activeHoleIndex;
                        final isWhacked = index == _whackedHoleIndex;
                        return GestureDetector(
                          onTap: () => _whackMole(index),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Burrow Hole
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  gradient: const RadialGradient(
                                    colors: [
                                      Color(0xFF041E15), // deep black hole
                                      Color(0xFF064E3B), // outer hole dirt
                                    ],
                                    center: Alignment.center,
                                    radius: 0.8,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isActive 
                                        ? Colors.amberAccent 
                                        : const Color(0xFF15803D).withOpacity(0.8),
                                    width: isActive ? 6 : 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isActive 
                                          ? Colors.amberAccent.withOpacity(0.6) 
                                          : Colors.black45,
                                      blurRadius: isActive ? 24 : 10,
                                      spreadRadius: isActive ? 4 : 1,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeOutBack,
                                    scale: isActive ? 1.0 : 0.0,
                                    child: const Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: Text('🐰', style: TextStyle(fontSize: 60)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Hit splash indicator popping up
                              if (isWhacked)
                                const Positioned(
                                  top: -16,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      '💥 +1',
                                      style: TextStyle(
                                        color: Colors.amberAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 26,
                                        shadows: [
                                          Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Progress Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: levelTargets == 0 ? 0 : (_levelTargetsAppeared / levelTargets),
                      minHeight: 14,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kemunculan Kelinci: $_levelTargetsAppeared / $levelTargets',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCompleteScreen() {
    final int levelTargets = _getLevelTotalTargets(_currentLevel);
    final accuracy = levelTargets > 0 ? (_levelScore / levelTargets) : 0.0;
    
    int starsCount = 0;
    if (accuracy >= 0.85) {
      starsCount = 3;
    } else if (accuracy >= 0.60) {
      starsCount = 2;
    } else if (accuracy >= 0.35) {
      starsCount = 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A).withOpacity(0.9), // dark overlay
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF78350F), Color(0xFF451A03)], // rich dark wooden colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF59E0B), width: 6), // golden border
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
              Text(
                'LEVEL $_currentLevel SELESAI!',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stars display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final active = index < starsCount;
                  return Icon(
                    Icons.star_rounded,
                    color: active ? Colors.amber : Colors.white24,
                    size: 55,
                    shadows: active ? [const Shadow(color: Colors.orange, blurRadius: 15)] : null,
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Level Stats Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tertangkap:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$_levelScore / $levelTargets', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Meleset:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$_levelMisses', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 18)),
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
                    if (_currentLevel >= _maxLevels) {
                      setState(() {
                        _gamePhase = 'level_select';
                      });
                    } else {
                      _startLevel(_currentLevel + 1);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                  ),
                  child: Text(
                    _currentLevel >= _maxLevels ? 'Kembali ke Pemilihan Level 🗺️' : 'Lanjut Ke Level ${_currentLevel + 1} ➡️',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _startLevel(_currentLevel);
                },
                child: const Text('Main Ulang Level Ini 🔄', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  setState(() {
                    _gamePhase = 'level_select';
                  });
                },
                child: const Text('Kembali ke Menu Utama 🗺️', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final msg = _getScoreMessage();

    int avgReaction = 0;
    if (_reactionTimes.isNotEmpty) {
      avgReaction = _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF0F2E20), Color(0xFF021C14)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _resultsAnimCtrl,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (sin(_resultsAnimCtrl.value * pi * 2) * 0.05),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: msg['color'].withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: msg['color'], width: 4),
                            boxShadow: [
                              BoxShadow(color: msg['color'].withOpacity(0.3), blurRadius: 20, spreadRadius: 4),
                            ],
                          ),
                          child: Text(
                            (_score / _totalTargets) >= 0.6 ? '🏆' : '👍', 
                            style: const TextStyle(fontSize: 80)
                          ),
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 32),
                  const Text('Permainan Selesai!', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Text(msg['message'], textAlign: TextAlign.center, style: TextStyle(color: msg['color'], fontSize: 20, fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 32),
                  
                  // Detailed Stats Wood Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF78350F), Color(0xFF451A03)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.amber.withOpacity(0.5), width: 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Akurasi Pukulan:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 15)),
                            Text('${((_score / _totalTargets) * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.greenAccent, fontSize: 20)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white24, height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kecepatan Rata-rata:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 15)),
                            Text('${avgReaction}ms', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.cyanAccent, fontSize: 20)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white24, height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Tertangkap:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 15)),
                            Text('$_score / $_totalTargets', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white24, height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Meleset:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 15)),
                            Text('$_misses', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent, fontSize: 20)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                      ),
                      child: const Text('Kembali ke Peta Petualangan 🗺️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelectScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF064E3B), Color(0xFF022C22)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Pilih Level 🧩',
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
                    itemCount: _maxLevels,
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  gradient: isUnlocked
                                      ? const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF334155), Color(0xFF1E293B)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isUnlocked ? Colors.amberAccent : Colors.grey.shade700,
                                    width: 3,
                                  ),
                                  boxShadow: isUnlocked
                                      ? [
                                          BoxShadow(
                                            color: Colors.amber.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: isUnlocked
                                      ? Text(
                                          '$levelNum',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 1))
                                            ],
                                          ),
                                        )
                                      : const Icon(Icons.lock_rounded, color: Colors.white38, size: 28),
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
                                  color: isStarred ? Colors.amber : Colors.white10,
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
      ),
    );
  }
}
