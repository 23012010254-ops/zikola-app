import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/assessment_engine.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class NumberLevelConfig {
  final int level;
  final int digitsCount;
  final int showDurationSecs;
  final int answerDurationSecs;

  NumberLevelConfig({
    required this.level,
    required this.digitsCount,
    required this.showDurationSecs,
    required this.answerDurationSecs,
  });
}

class NumberMemoryGame extends StatefulWidget {
  const NumberMemoryGame({super.key});

  @override
  State<NumberMemoryGame> createState() => _NumberMemoryGameState();
}

class _NumberMemoryGameState extends State<NumberMemoryGame> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, showing, input, level_complete, completed
  int _currentLevel = 1;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  String _targetNumber = '';
  String _userInput = '';
  int _timeLeft = 5;
  int _answerTimeLeft = 10;
  DateTime? _startTime;
  String? _feedback; // 'correct', 'wrong', null
  int _lives = 3;

  Timer? _showTimer;
  Timer? _answerTimer;
  final Random _random = Random();

  late AnimationController _bgAnimCtrl;

  final List<NumberLevelConfig> _levelsConfig = [
    NumberLevelConfig(level: 1, digitsCount: 3, showDurationSecs: 5, answerDurationSecs: 10),
    NumberLevelConfig(level: 2, digitsCount: 4, showDurationSecs: 5, answerDurationSecs: 10),
    NumberLevelConfig(level: 3, digitsCount: 5, showDurationSecs: 4, answerDurationSecs: 12),
    NumberLevelConfig(level: 4, digitsCount: 6, showDurationSecs: 4, answerDurationSecs: 12),
    NumberLevelConfig(level: 5, digitsCount: 7, showDurationSecs: 3, answerDurationSecs: 15),
    NumberLevelConfig(level: 6, digitsCount: 8, showDurationSecs: 3, answerDurationSecs: 15),
    NumberLevelConfig(level: 7, digitsCount: 9, showDurationSecs: 3, answerDurationSecs: 15),
    NumberLevelConfig(level: 8, digitsCount: 10, showDurationSecs: 2, answerDurationSecs: 18),
  ];

  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _answerTimer?.cancel();
    _bgAnimCtrl.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameState = 'level_select';
    });
  }

  void _startLevel(int level) {
    setState(() {
      _gameState = 'playing';
      _score = 0;
      _correctAnswers = 0;
      _wrongAnswers = 0;
      _currentLevel = level;
      _lives = 3;
      _startTime = DateTime.now();
      _feedback = null;
    });
    AudioService().playBGM('puzzle_music.mp3');
    
    final config = _levelsConfig[level - 1];
    _generateNumber(config.digitsCount);
  }

  void _generateNumber(int digits) {
    String number = '';
    for (int i = 0; i < digits; i++) {
       number += _random.nextInt(10).toString();
    }
    
    final config = _levelsConfig[_currentLevel - 1];
    
    setState(() {
      _targetNumber = number;
      _userInput = '';
      _timeLeft = config.showDurationSecs;
      _answerTimeLeft = config.answerDurationSecs;
      _gameState = 'showing';
      _feedback = null;
    });

    _startShowTimer();
  }

  void _startShowTimer() {
    _showTimer?.cancel();
    _answerTimer?.cancel();
    
    _showTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_gameState == 'showing') {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          _showTimer?.cancel();
          setState(() {
            _gameState = 'input';
          });
          _startAnswerTimer();
        }
      }
    });
  }

  void _startAnswerTimer() {
    _answerTimer?.cancel();
    
    _answerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_gameState == 'input') {
        if (_answerTimeLeft > 0) {
          setState(() => _answerTimeLeft--);
        } else {
          _answerTimer?.cancel();
          _checkAnswer(_userInput);
        }
      }
    });
  }

  void _handleNumberInput(String digit) {
    if (_userInput.length < _targetNumber.length && _feedback == null) {
      setState(() {
        _userInput += digit;
      });
      AudioService().playSFX('bubble.mp3');

      if (_userInput.length == _targetNumber.length) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _checkAnswer(_userInput);
        });
      }
    }
  }

  void _handleBackspace() {
    if (_userInput.isNotEmpty && _feedback == null) {
      setState(() {
        _userInput = _userInput.substring(0, _userInput.length - 1);
      });
      AudioService().playSFX('flip.mp3');
    }
  }

  void _checkAnswer(String input) {
    if (_feedback != null) return;
    
    _answerTimer?.cancel();
    bool isCorrect = input == _targetNumber && input.length == _targetNumber.length;
    
    setState(() {
      _feedback = isCorrect ? 'correct' : 'wrong';
      
      if (isCorrect) {
        _score += _targetNumber.length * 15;
        AudioService().playSFX('correct.mp3');
      } else {
        _wrongAnswers++;
        _lives--;
        AudioService().playSFX('wrong.mp3');
      }
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      
      if (isCorrect) {
        _completeLevel();
      } else if (_lives <= 0) {
        _endGame();
      } else {
        _generateNumber(_levelsConfig[_currentLevel - 1].digitsCount);
      }
    });
  }

  void _completeLevel() {
    _showTimer?.cancel();
    _answerTimer?.cancel();
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

    int totalTime = DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    int totalQuestions = _correctAnswers + _wrongAnswers + 1; // include correct answer
    _correctAnswers++;
    int accuracy = (totalQuestions > 0) ? ((_correctAnswers / totalQuestions) * 100).round() : 0;
    int avgRespMs = totalQuestions > 0 ? ((totalTime * 1000) / totalQuestions).round() : 0;

    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: totalQuestions,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 6000,
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _wrongAnswers,
    );

    context.read<AppState>().updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': totalQuestions,
      'percentage': accuracy,
      'timeSpent': totalTime,
      'gameMode': 'Number Memory',
      'level': _currentLevel,
      'shortTermMemoryScore': assessScore,
    });

    context.read<AppState>().updateGameAssessment('numberMemoryGame', GameSession(
      score: _score,
      timeSpent: totalTime,
      errors: _wrongAnswers,
      totalItems: totalQuestions,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'maxDigitLength': _levelsConfig[levelIdx].digitsCount,
        'livesRemaining': _lives,
      },
      subdomainScores: {
        'shortTermMemory': assessScore,
        'workingMemory': (accuracy / 100.0) * 80.0,
      },
    ));
    context.read<AppState>().addPointsFromScore(_score);

    if (_highestUnlocked >= 8 && starsCount == 3) {
      context.read<AppState>().addSticker('number-genius');
    }

    setState(() {
      _gameState = 'level_complete';
    });
  }

  void _endGame() {
    _showTimer?.cancel();
    _answerTimer?.cancel();
    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');

    int totalTime = DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    int totalQuestions = _correctAnswers + _wrongAnswers;
    int accuracy = (totalQuestions > 0) ? ((_correctAnswers / totalQuestions) * 100).round() : 0;
    int avgRespMs = totalQuestions > 0 ? ((totalTime * 1000) / totalQuestions).round() : 0;

    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: totalQuestions,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 6000,
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _wrongAnswers,
    );

    context.read<AppState>().updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': totalQuestions,
      'percentage': accuracy,
      'timeSpent': totalTime,
      'gameMode': 'Number Memory',
      'level': _currentLevel,
      'shortTermMemoryScore': assessScore,
    });

    context.read<AppState>().updateGameAssessment('numberMemoryGame', GameSession(
      score: _score,
      timeSpent: totalTime,
      errors: _wrongAnswers,
      totalItems: totalQuestions,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'maxDigitLength': _levelsConfig[_currentLevel - 1].digitsCount,
        'livesRemaining': _lives,
      },
      subdomainScores: {
        'shortTermMemory': assessScore,
        'workingMemory': (accuracy / 100.0) * 80.0,
      },
    ));
    context.read<AppState>().addPointsFromScore(_score);

    setState(() {
      _gameState = 'completed';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameState == 'menu') return _buildMenu();
    if (_gameState == 'level_select') return _buildLevelSelect();
    if (_gameState == 'level_complete') return _buildLevelComplete();
    if (_gameState == 'completed') return _buildCompleted();
    return _buildPlaying();
  }

  Widget _buildMenu() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF22D3EE), Color(0xFF60A5FA), Color(0xFF6366F1)])
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _bgAnimCtrl,
              builder: (context, child) {
                double offset1 = sin(_bgAnimCtrl.value * pi) * 10;
                double offset2 = cos(_bgAnimCtrl.value * pi) * 15;
                return Stack(
                  children: [
                    Positioned(top: 80 - offset1, left: 40, child: const Text('1️⃣', style: TextStyle(fontSize: 48))),
                    Positioned(top: 128 + offset2, right: 64, child: const Text('2️⃣', style: TextStyle(fontSize: 40))),
                    Positioned(bottom: 128 - offset2, left: 80, child: const Text('3️⃣', style: TextStyle(fontSize: 48))),
                    Positioned(bottom: 80 + offset1, right: 48, child: const Text('4️⃣', style: TextStyle(fontSize: 40))),
                  ],
                );
              },
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                        Text('Number Memory', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 20)),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 48),
                    const Text('🔢', style: TextStyle(fontSize: 96)),
                    const SizedBox(height: 24),
                    Text('Ingat Angka-Angka!', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 28), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text('Lihat angka yang muncul, ingat baik-baik, lalu ketik ulang!', style: TextStyle(color: Color(0xFFCFFAFE), fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cara Bermain:', style: AppTheme.heading3.copyWith(color: Colors.white)),
                          const SizedBox(height: 16),
                          _buildRuleRow(Icons.visibility, 'Perhatikan angka yang ditampilkan'),
                          const SizedBox(height: 12),
                          _buildRuleRow(Icons.psychology, 'Ingat baik-baik sebelum hilang'),
                          const SizedBox(height: 12),
                          _buildRuleRow(Icons.visibility_off, 'Ketik angka yang kamu ingat'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        child: const Text('🔢 Mulai Bermain!', style: TextStyle(color: Color(0xFF2563EB), fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
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

  Widget _buildRuleRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFCFFAFE), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFCFFAFE)))),
      ],
    );
  }

  Widget _buildLevelSelect() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF22D3EE), Color(0xFF60A5FA), Color(0xFF6366F1)]
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
                          'Pilih Level Angka 🔢',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  gradient: isUnlocked
                                      ? const LinearGradient(
                                          colors: [Color(0xFF06B6D4), Color(0xFF1D4ED8)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isUnlocked ? Colors.yellowAccent : Colors.grey.shade400,
                                    width: 3,
                                  ),
                                  boxShadow: isUnlocked
                                      ? [
                                          BoxShadow(
                                            color: Colors.cyan.withOpacity(0.3),
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
                                      : const Icon(Icons.lock_rounded, color: Colors.white60, size: 28),
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
      ),
    );
  }

  Widget _buildPlaying() {
    final config = _levelsConfig[_currentLevel - 1];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF67E8F9), Color(0xFF93C5FD), Color(0xFF818CF8)])
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showTimer?.cancel();
                        _answerTimer?.cancel();
                        AudioService().stopBGM();
                        setState(() => _gameState = 'level_select');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    Column(
                      children: [
                        const Text('Number Memory', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Level $_currentLevel', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$_score', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 24)),
                        const Text('Skor', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(index < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 24)),
                    )),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                        child: _gameState == 'showing' ? Column(
                          children: [
                            const Text('Ingat angka ini:', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                            const SizedBox(height: 16),
                            Text(_targetNumber, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFF6B7280), size: 16),
                                const SizedBox(width: 8),
                                Text('${_timeLeft}s', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            )
                          ],
                        ) : _feedback != null ? Column(
                          children: [
                            Text(_feedback == 'correct' ? '🎉' : '💔', style: const TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(_feedback == 'correct' ? 'Benar!' : 'Salah!', style: AppTheme.heading2.copyWith(color: const Color(0xFF111827), fontSize: 24)),
                            const SizedBox(height: 8),
                            const Text('Angka yang benar:', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(_targetNumber, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
                          ],
                        ) : Column(
                          children: [
                            const Text('Ketik angka yang kamu ingat:', style: TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                            const SizedBox(height: 16),
                            Container(
                              height: 64,
                              alignment: Alignment.center,
                              child: Text(_userInput.isEmpty ? '___' : _userInput, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4)),
                            ),
                            const SizedBox(height: 8),
                            Text('${_userInput.length} / ${config.digitsCount} digit', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFFF97316), size: 16),
                                const SizedBox(width: 8),
                                Text('${_answerTimeLeft}s tersisa', style: TextStyle(color: _answerTimeLeft <= 3 ? const Color(0xFFEF4444) : const Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            )
                          ],
                        ),
                      ),
                      
                      if (_gameState == 'input' && _feedback == null)
                        Expanded(
                          child: Center(
                            child: GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.25,
                              children: [
                                '1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', '✓'
                              ].map((num) {
                                bool isBackspace = num == '⌫';
                                bool isSubmit = num == '✓';
                                bool submitDisabled = isSubmit && _userInput.length != config.digitsCount;
                                
                                return ElevatedButton(
                                  onPressed: submitDisabled ? null : () {
                                    if (isBackspace) _handleBackspace();
                                    else if (isSubmit) _checkAnswer(_userInput);
                                    else _handleNumberInput(num);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isBackspace ? const Color(0xFFF97316) : isSubmit ? (submitDisabled ? Colors.grey[300] : const Color(0xFF22C55E)) : Colors.white,
                                    foregroundColor: isBackspace || (isSubmit && !submitDisabled) ? Colors.white : const Color(0xFF111827),
                                    elevation: submitDisabled ? 0 : 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: EdgeInsets.zero
                                  ),
                                  child: Text(num, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: submitDisabled ? Colors.grey[500] : null)),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
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

  Widget _buildLevelComplete() {
    int starsCount = 0;
    if (_lives == 3) {
      starsCount = 3;
    } else if (_lives == 2) {
      starsCount = 2;
    } else if (_lives == 1) {
      starsCount = 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFCFFAFE),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF22D3EE), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'HEBAT SEKALI! 🎉',
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
                    _rowStat('Jumlah Digit:', '${_levelsConfig[_currentLevel - 1].digitsCount}'),
                    const Divider(color: Colors.white24),
                    _rowStat('Nyawa Tersisa:', '$_lives'),
                    const Divider(color: Colors.white24),
                    _rowStat('Skor Total:', '$_score'),
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
                    foregroundColor: const Color(0xFF1D4ED8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                  ),
                  child: Text(
                    _currentLevel >= 8 ? 'Peta Level 🗺️' : 'Level Berikutnya ${_currentLevel + 1} ➡️',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _startLevel(_currentLevel);
                },
                child: const Text('Main Lagi Level Ini 🔄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  setState(() {
                    _gameState = 'level_select';
                  });
                },
                child: const Text('Kembali ke Peta Level 🗺️', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
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
                const Text('💔', style: TextStyle(fontSize: 100)),
                const SizedBox(height: 24),
                Text('Ingat Angka Gagal!', style: AppTheme.heading1.copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _rowStat('Panjang Angka', '${_levelsConfig[_currentLevel - 1].digitsCount} digit'),
                      const Divider(),
                      _rowStat('Ketikkan Kamu', _userInput.isEmpty ? '-' : _userInput),
                      const Divider(),
                      _rowStat('Angka Benar', _targetNumber),
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
                  child: const Text('Kembali ke Peta Level 🗺️', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold)),
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
        ],
      ),
    );
  }
}
