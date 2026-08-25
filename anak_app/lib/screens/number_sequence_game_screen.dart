import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../services/assessment_engine.dart';

class SequenceChallenge {
  final List<int> sequence;
  final int missing;
  final int missingIndex;
  final String difficulty;
  final String pattern;
  final List<int> choices;

  SequenceChallenge({
    required this.sequence,
    required this.missing,
    required this.missingIndex,
    required this.difficulty,
    required this.pattern,
    required this.choices,
  });
}

class NumberSequenceGameScreen extends StatefulWidget {
  const NumberSequenceGameScreen({super.key});

  @override
  State<NumberSequenceGameScreen> createState() => _NumberSequenceGameScreenState();
}

class _NumberSequenceGameScreenState extends State<NumberSequenceGameScreen> with TickerProviderStateMixin {
  String _gameState = 'menu'; // 'menu', 'level_select', 'playing', 'level_complete', 'game_over', 'completed'
  int _currentLevel = 1;
  SequenceChallenge? _challenge;
  int _score = 0;
  int _lives = 3;
  int _timeLeft = 30;
  bool _isTimerRunning = false;
  bool _showHint = false;
  int _hintsUsed = 0;
  int _correctAnswers = 0;
  int _levelCorrectAnswers = 0;
  int? _selectedAnswer;
  String? _answerFeedback; // 'correct' or 'wrong'
  int _errors = 0;
  DateTime? _gameStartTime;

  Timer? _timer;
  late AnimationController _confettiController;
  late AnimationController _bgFloatCtrl;
  int _highestUnlocked = 1;
  final List<int> _starRatings = List.filled(8, 0);

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _bgFloatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _bgFloatCtrl.dispose();
    _timer?.cancel();
    AudioService().stopBGM();
    super.dispose();
  }

  SequenceChallenge _generateChallenge(int level) {
    String patternType = '';
    String description = '';
    String difficulty = '';

    if (level <= 2) {
      difficulty = 'easy';
      patternType = Random().nextBool() ? 'addition' : 'subtraction';
    } else if (level <= 5) {
      difficulty = 'medium';
      patternType = Random().nextBool() ? 'multiplication' : 'fibonacci';
    } else {
      difficulty = 'hard';
      patternType = Random().nextBool() ? 'square' : 'complex';
    }

    List<int> sequence = [];
    int missing = 0;
    int missingIndex = 0;

    switch (patternType) {
      case 'addition':
        int start = Random().nextInt(10) + 1;
        int step = Random().nextInt(5) + 1;
        sequence = List.generate(6, (i) => start + i * step);
        description = '+';
        break;
      case 'subtraction':
        int start2 = Random().nextInt(10) + 30;
        int step2 = Random().nextInt(5) + 1;
        sequence = List.generate(6, (i) => start2 - i * step2);
        description = '-';
        break;
      case 'multiplication':
        int start3 = Random().nextInt(3) + 2;
        int step3 = Random().nextInt(2) + 2;
        sequence = List.generate(5, (i) => start3 * pow(step3, i).toInt());
        description = '×';
        break;
      case 'fibonacci':
        sequence = [1, 1];
        for (int i = 2; i < 6; i++) {
          sequence.add(sequence[i - 1] + sequence[i - 2]);
        }
        description = 'Fibonacci';
        break;
      case 'square':
        int start4 = Random().nextInt(3) + 1;
        sequence = List.generate(5, (i) => pow(start4 + i, 2).toInt());
        description = 'n²';
        break;
      case 'complex':
        int start5 = Random().nextInt(10) + 1;
        int step5 = Random().nextInt(5) + 1;
        sequence = List.generate(6, (i) => start5 + i * step5 + i);
        description = 'n + step + i';
        break;
      default:
        sequence = [1, 2, 3, 4, 5, 6];
        description = '+';
    }

    missingIndex = Random().nextInt(sequence.length);
    missing = sequence[missingIndex];

    List<int> choices = [missing];
    while (choices.length < 4) {
      int wrongChoice = missing + Random().nextInt(20) - 10;
      if (!choices.contains(wrongChoice) && wrongChoice > 0) {
        choices.add(wrongChoice);
      }
    }
    choices.shuffle();

    return SequenceChallenge(
      sequence: sequence,
      missing: missing,
      missingIndex: missingIndex,
      difficulty: difficulty,
      pattern: description,
      choices: choices,
    );
  }

  void _startGame() {
    setState(() {
      _gameState = 'level_select';
    });
  }

  void _startLevel(int level) {
    setState(() {
      _gameState = 'playing';
      _currentLevel = level;
      _score = 0;
      _lives = 3;
      _levelCorrectAnswers = 0;
      _correctAnswers = 0;
      _errors = 0;
      _hintsUsed = 0;
      _gameStartTime = DateTime.now();
    });
    AudioService().playBGM('puzzle_music.mp3');
    _initLevel();
  }

  void _initLevel() {
    _timer?.cancel();
    setState(() {
      _challenge = _generateChallenge(_currentLevel);
      _timeLeft = 30;
      _isTimerRunning = true;
      _showHint = false;
      _selectedAnswer = null;
      _answerFeedback = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerRunning && _timeLeft > 0) {
        setState(() => _timeLeft--);
      } else if (_isTimerRunning && _timeLeft == 0) {
        _handleWrongAnswer();
      }
    });
  }

  void _handleAnswer(int answer) {
    if (_challenge == null || _answerFeedback != null) return;

    setState(() {
      _selectedAnswer = answer;
      _isTimerRunning = false;
    });
    AudioService().playSFX('flip.mp3');

    if (answer == _challenge!.missing) {
      setState(() {
        _answerFeedback = 'correct';
        _score += _challenge!.difficulty == 'easy' ? 10 : _challenge!.difficulty == 'medium' ? 15 : 20;
        _correctAnswers++;
        _levelCorrectAnswers++;
      });
      AudioService().playSFX('correct.mp3');

      if (_levelCorrectAnswers >= 3) {
        _timer?.cancel();
        int stars = 1;
        if (_lives == 3) stars = 3;
        else if (_lives == 2) stars = 2;

        _starRatings[_currentLevel - 1] = max(_starRatings[_currentLevel - 1], stars);

        if (_currentLevel == _highestUnlocked && _highestUnlocked < 8) {
          _highestUnlocked = _currentLevel + 1;
        }

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          setState(() {
            _gameState = 'level_complete';
          });
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _initLevel();
        });
      }
    } else {
      _handleWrongAnswer();
    }
  }

  void _handleWrongAnswer() {
    setState(() {
      _answerFeedback = 'wrong';
      _errors++;
      _lives--;
      _isTimerRunning = false;
      _timeLeft = 30;
    });
    AudioService().playSFX('wrong.mp3');

    if (_lives <= 0) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _gameState = 'game_over';
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _initLevel();
      });
    }
  }

  void _endGame() {
    _timer?.cancel();
    
    int totalTime = _gameStartTime != null ? DateTime.now().difference(_gameStartTime!).inSeconds : 0;
    int accuracy = _correctAnswers > 0 ? ((_correctAnswers / max(1, _correctAnswers + _errors)) * 100).round() : 0;
    
    context.read<AppState>().updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': _correctAnswers + _errors,
      'percentage': accuracy,
      'timeSpent': totalTime,
      'gameMode': 'Number Sequence Premium',
      'level': _currentLevel,
      'categoryScores': {
        'accuracy': accuracy,
        'livesRemaining': _lives
      }
    });

    final int avgRespMs = (_correctAnswers + _errors) > 0 ? ((totalTime * 1000) / (_correctAnswers + _errors)).round() : 0;
    
    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: _correctAnswers + _errors,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 12000, 
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: _hintsUsed,
      errors: _errors,
    );

    context.read<AppState>().updateGameAssessment('numberSequence', GameSession(
      score: _score,
      timeSpent: totalTime,
      errors: _errors,
      totalItems: _correctAnswers + _errors,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: _hintsUsed,
      assessmentScore: assessScore,
      detailedMetrics: {
        'livesRemaining': _lives,
      },
      subdomainScores: {
        'fluidReasoning': assessScore,
      },
    ));

    context.read<AppState>().addPointsFromScore(_score);
    context.read<AppState>().addSticker(_lives > 0 ? 'number-master' : 'number-explorer');

    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');
    setState(() => _gameState = 'completed');
  }

  void _useHint() {
    if (!_showHint && _challenge != null) {
      setState(() {
        _showHint = true;
        _hintsUsed++;
      });
    }
  }

  String _getHintText() {
    if (_challenge == null) return '';
    switch (_challenge!.pattern) {
      case '+': return 'Setiap angka bertambah dengan jumlah yang sama';
      case '-': return 'Setiap angka berkurang dengan jumlah yang sama';
      case '×': return 'Setiap angka dikali dengan angka yang sama';
      case 'Fibonacci': return 'Setiap angka adalah hasil penjumlahan 2 angka sebelumnya';
      case 'n²': return 'Setiap angka adalah kuadrat dari bilangan berurutan';
      case 'n + step + i': return 'Pola lebih kompleks: perhatikan selisih antar angka';
      default: return 'Perhatikan pola dalam urutan angka';
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_gameState) {
      case 'menu':
        return _buildMenu();
      case 'level_select':
        return _buildLevelSelect();
      case 'playing':
        if (_challenge == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return _buildGameScreen();
      case 'level_complete':
        return _buildLevelCompleteScreen();
      case 'game_over':
        return _buildGameOverScreen();
      case 'completed':
        return _buildCompleted();
      default:
        return _buildMenu();
    }
  }

  Widget _buildMenu() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF311042), Color(0xFF4C1D95)]
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -50, right: -50, child: Opacity(opacity: 0.15, child: Icon(Icons.rocket_launch, size: 300, color: Colors.purple.shade300))),
            Positioned(bottom: 20, left: 10, child: Opacity(opacity: 0.2, child: const Text('🪐', style: TextStyle(fontSize: 100)))),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        _buildGlassButton(Icons.arrow_back, () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text('🪐', style: TextStyle(fontSize: 100)),
                        const SizedBox(height: 16),
                        Text(
                          'URUTAN\nANGKA',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4, fontFamily: 'Nunito'),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Asah logika angka di luar angkasa!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFC084FC), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: _buildPremiumButton('MULAI BERMAIN 🚀', _startGame),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildPremiumButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelect() {
    const double mapHeight = 700.0;
    const int totalLevels = 8;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1B4B), Color(0xFF311042), Color(0xFF4C1D95)],
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
                          'Pilih Misi 🪐',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double w = constraints.maxWidth;
                    
                    final List<Offset> points = [
                      Offset(w * 0.25, mapHeight * 0.88),
                      Offset(w * 0.72, mapHeight * 0.78),
                      Offset(w * 0.38, mapHeight * 0.65),
                      Offset(w * 0.76, mapHeight * 0.52),
                      Offset(w * 0.24, mapHeight * 0.40),
                      Offset(w * 0.68, mapHeight * 0.28),
                      Offset(w * 0.30, mapHeight * 0.16),
                      Offset(w * 0.52, mapHeight * 0.05),
                    ];

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: w,
                        height: mapHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ConstellationPainter(points, _highestUnlocked),
                              ),
                            ),
                            for (int i = 0; i < totalLevels; i++) ...[
                              Positioned(
                                left: points[i].dx - 40,
                                top: points[i].dy - 40,
                                child: SizedBox(
                                  width: 80,
                                  height: 90,
                                  child: _buildConstellationStarItem(i + 1),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConstellationStarItem(int levelNum) {
    final bool isUnlocked = levelNum <= _highestUnlocked;
    final int rating = _starRatings[levelNum - 1];

    return AnimatedBuilder(
      animation: _bgFloatCtrl,
      builder: (context, child) {
        final double pulse = _bgFloatCtrl.value;
        final double scale = 1.0 + (pulse * 0.08);

        return Transform.scale(
          scale: isUnlocked ? scale : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: isUnlocked
                    ? () {
                        AudioService().playClick();
                        _startLevel(levelNum);
                      }
                    : () {
                        AudioService().playWrong();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Misi ini masih terkunci! Selesaikan misi sebelumnya.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: const Color(0xFFA78BFA).withOpacity(0.3 + pulse * 0.3),
                              blurRadius: 10 + pulse * 6,
                              spreadRadius: pulse * 1.5,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 50,
                        color: isUnlocked
                            ? (levelNum == _highestUnlocked
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFA78BFA))
                            : const Color(0xFF374151),
                      ),
                      if (isUnlocked)
                        Icon(
                          Icons.star_rounded,
                          size: 22,
                          color: levelNum == _highestUnlocked ? const Color(0xFFFEF08A) : Colors.white,
                        ),
                      Center(
                        child: Text(
                          '$levelNum',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isUnlocked
                                ? (levelNum == _highestUnlocked
                                    ? const Color(0xFF78350F)
                                    : const Color(0xFF4C1D95))
                                : Colors.white38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (starIdx) {
                  final isStarred = starIdx < rating;
                  return Icon(
                    Icons.star_rounded,
                    color: isStarred ? Colors.amber : Colors.white10,
                    size: 10,
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1B4B), Color(0xFF311042), Color(0xFF4C1D95)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _gameState = 'level_select'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                        Text(
                          'Misi $_currentLevel  •  $_levelCorrectAnswers/3',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _startLevel(_currentLevel),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBadge('Skor', '$_score', Colors.amber),
                        _buildStatBadge('Nyawa', '❤️ $_lives', Colors.redAccent),
                        _buildStatBadge('Waktu', '⏱️ $_timeLeft', Colors.white.withOpacity(0.2), isMain: false),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Lengkapi urutan ini:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final double spacing = 12.0;
                                final int count = _challenge!.sequence.length;
                                final double availableWidth = constraints.maxWidth;
                                final double cardSize = (availableWidth - (spacing * (count - 1))) / count;
                                final double finalSize = cardSize.clamp(48.0, 68.0);
                                
                                return Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: List.generate(count, (idx) {
                                    bool isMissing = idx == _challenge!.missingIndex;
                                    return Container(
                                      width: finalSize,
                                      height: finalSize,
                                      decoration: BoxDecoration(
                                        color: isMissing ? Colors.transparent : const Color(0xFF8B5CF6),
                                        borderRadius: BorderRadius.circular(finalSize * 0.3),
                                        border: Border.all(
                                          color: isMissing ? const Color(0xFFC084FC) : Colors.transparent,
                                          width: 3,
                                        ),
                                        boxShadow: isMissing ? [] : [
                                          BoxShadow(
                                            color: const Color(0xFF6D28D9).withOpacity(0.5),
                                            offset: const Offset(0, 4),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          isMissing ? '?' : '${_challenge!.sequence[idx]}',
                                          style: TextStyle(
                                            fontSize: finalSize * 0.45,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                        children: List.generate(_challenge!.choices.length, (index) {
                          int choice = _challenge!.choices[index];
                          bool isSelected = _selectedAnswer == choice;
                          
                          Color btnColor = const Color(0xFFC084FC);
                          if (index == 1) btnColor = const Color(0xFF818CF8);
                          if (index == 2) btnColor = const Color(0xFFF472B6);
                          if (index == 3) btnColor = const Color(0xFF60A5FA);

                          if (isSelected && _answerFeedback != null) {
                            btnColor = _answerFeedback == 'correct' ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
                          }

                          return GestureDetector(
                            onTap: _answerFeedback != null ? null : () => _handleAnswer(choice),
                            child: Container(
                              decoration: BoxDecoration(
                                color: btnColor,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: btnColor.withOpacity(0.4),
                                    offset: const Offset(0, 6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$choice',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (isSelected && _answerFeedback != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        _answerFeedback == 'correct' ? Icons.check_circle : Icons.cancel,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      if (!_showHint)
                        GestureDetector(
                          onTap: _useHint,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF08A).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.lightbulb, color: Color(0xFFCA8A04)),
                                SizedBox(width: 12),
                                Text(
                                  'Butuh Bantuan?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF854D0E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      if (_showHint)
                        Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEFCE8),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFFEF08A), width: 2),
                          ),
                          child: Text(
                            '💡 ${_getHintText()}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF854D0E),
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

  Widget _buildStatBadge(String label, String value, Color color, {bool isMain = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isMain ? color : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildLevelCompleteScreen() {
    final stars = _starRatings[_currentLevel - 1];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 70)),
              const SizedBox(height: 16),
              Text(
                'MISI $_currentLevel SELESAI!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC084FC),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 44,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Skor: $_score  •  Nyawa Tersisa: $_lives',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentLevel < 8) {
                      _startLevel(_currentLevel + 1);
                    } else {
                      _endGame();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _currentLevel < 8 ? 'MISI BERIKUTNYA' : 'LIHAT HASIL AKHIR',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _gameState = 'level_select';
                  });
                },
                child: const Text(
                  'Pilih Misi Lain',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🚀💥', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const Text(
                'MISI GAGAL!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kamu kehabisan nyawa di Misi $_currentLevel',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _startLevel(_currentLevel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'COBA LAGI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _gameState = 'level_select';
                  });
                },
                child: const Text(
                  'Pilih Misi Lain',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    int totalQuestions = _correctAnswers + _errors;
    int accuracy = totalQuestions > 0 ? ((_correctAnswers / totalQuestions) * 100).round() : 0;
    String childName = context.read<AppState>().childProfile.name;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1B4B), Color(0xFF311042), Color(0xFF4C1D95)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 96)),
                  const SizedBox(height: 16),
                  Text('Hebat Sekali!', style: TextStyle(fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('$childName, kamu penjelajah angka luar angkasa yang hebat!', style: const TextStyle(color: Color(0xFFC084FC), fontSize: 18), textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  _buildResultStatRow('Skor Total', '$_score'),
                  const SizedBox(height: 16),
                  _buildResultStatRow('Akurasi', '$accuracy%'),
                  const SizedBox(height: 16),
                  _buildResultStatRow('Misi Terakhir', '$_currentLevel'),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFEFCE8).withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.withOpacity(0.3))),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Hadiah Diperoleh!', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Stiker "${_lives > 0 ? 'Number Master' : 'Number Explorer'}" ditambahkan!', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _gameState = 'menu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Main Lagi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white, width: 2)),
                      ),
                      child: const Text('Pilih Game Lain', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildResultStatRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<Offset> points;
  final int highestUnlocked;

  _ConstellationPainter(this.points, this.highestUnlocked);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glowPaint = Paint()
      ..color = const Color(0xFFA78BFA).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      bool pathUnlocked = (i + 2) <= highestUnlocked;

      if (pathUnlocked) {
        canvas.drawLine(p1, p2, glowPaint);
        canvas.drawLine(
          p1, 
          p2, 
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      } else {
        _drawDashedLine(canvas, p1, p2, linePaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 5.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    final double segments = distance / (dashWidth + dashSpace);

    for (int i = 0; i < segments; i++) {
      final double ratio = i / segments;
      final double nextRatio = (i + 0.5) / segments;
      canvas.drawLine(
        Offset(p1.dx + dx * ratio, p1.dy + dy * ratio),
        Offset(p1.dx + dx * nextRatio, p1.dy + dy * nextRatio),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.highestUnlocked != highestUnlocked;
  }
}
