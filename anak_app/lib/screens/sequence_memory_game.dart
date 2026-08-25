import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/assessment_engine.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class SequenceLevelConfig {
  final int level;
  final int sequenceLength;
  final int flashDelayMs;

  SequenceLevelConfig({
    required this.level,
    required this.sequenceLength,
    required this.flashDelayMs,
  });
}

class SequenceMemoryGame extends StatefulWidget {
  const SequenceMemoryGame({super.key});

  @override
  State<SequenceMemoryGame> createState() => _SequenceMemoryGameState();
}

class _SequenceMemoryGameState extends State<SequenceMemoryGame> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, showing, input, level_complete, completed
  int _currentLevel = 1;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  List<int> _sequence = [];
  List<int> _userSequence = [];
  int _showingIndex = -1;
  DateTime? _startTime;
  String? _feedback; // 'correct', 'wrong', null
  int _lives = 3;
  bool _isProcessing = false;
  bool _inputEnabled = false;

  final List<Map<String, dynamic>> _buttons = [
    {'id': 0, 'color': const Color(0xFFEF4444), 'emoji': '🔴'}, // red-500
    {'id': 1, 'color': const Color(0xFF3B82F6), 'emoji': '🔵'}, // blue-500
    {'id': 2, 'color': const Color(0xFFEAB308), 'emoji': '🟡'}, // yellow-500
    {'id': 3, 'color': const Color(0xFF22C55E), 'emoji': '🟢'}, // green-500
  ];

  late AnimationController _bgAnimCtrl;

  final List<SequenceLevelConfig> _levelsConfig = [
    SequenceLevelConfig(level: 1, sequenceLength: 3, flashDelayMs: 800),
    SequenceLevelConfig(level: 2, sequenceLength: 4, flashDelayMs: 800),
    SequenceLevelConfig(level: 3, sequenceLength: 5, flashDelayMs: 600),
    SequenceLevelConfig(level: 4, sequenceLength: 6, flashDelayMs: 600),
    SequenceLevelConfig(level: 5, sequenceLength: 7, flashDelayMs: 600),
    SequenceLevelConfig(level: 6, sequenceLength: 8, flashDelayMs: 450),
    SequenceLevelConfig(level: 7, sequenceLength: 9, flashDelayMs: 450),
    SequenceLevelConfig(level: 8, sequenceLength: 10, flashDelayMs: 450),
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
      _isProcessing = false;
    });
    AudioService().playBGM('puzzle_music.mp3');
    
    final config = _levelsConfig[level - 1];
    _generateSequence(config.sequenceLength);
  }

  void _generateSequence(int length) {
    List<int> newSequence = [];
    Random random = Random();
    for (int i = 0; i < length; i++) {
      newSequence.add(random.nextInt(4));
    }
    
    setState(() {
      _sequence = newSequence;
      _userSequence = [];
      _showingIndex = -1;
      _inputEnabled = false;
      _gameState = 'showing';
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _gameState == 'showing') {
        _showSequence(newSequence);
      }
    });
  }

  Future<void> _showSequence(List<int> seq) async {
    final config = _levelsConfig[_currentLevel - 1];
    for (int i = 0; i < seq.length; i++) {
      if (!mounted || _gameState != 'showing') return;
      setState(() => _showingIndex = i);
      AudioService().playSFX('bubble.mp3');
      await Future.delayed(Duration(milliseconds: config.flashDelayMs));
      
      if (!mounted || _gameState != 'showing') return;
      setState(() => _showingIndex = -1);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted || _gameState != 'showing') return;
    setState(() => _gameState = 'input');
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _gameState == 'input') {
        setState(() => _inputEnabled = true);
      }
    });
  }

  void _handleButtonClick(int buttonId) {
    if (_gameState != 'input' || !_inputEnabled || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _userSequence = List.from(_userSequence)..add(buttonId);
    });
    AudioService().playSFX('flip.mp3');

    if (_sequence[_userSequence.length - 1] != buttonId) {
      setState(() => _inputEnabled = false);
      _handleWrongAnswer();
      return;
    }

    if (_userSequence.length == _sequence.length) {
      setState(() => _inputEnabled = false);
      _handleCorrectAnswer();
    } else {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  void _handleCorrectAnswer() {
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
    int totalQuestions = _correctAnswers + _wrongAnswers + 1; // including this correct one
    _correctAnswers++;
    int accuracy = (totalQuestions > 0) ? ((_correctAnswers / totalQuestions) * 100).round() : 0;
    int avgRespMs = totalQuestions > 0 ? ((totalTime * 1000) / totalQuestions).round() : 0;

    _score += _levelsConfig[levelIdx].sequenceLength * 15;

    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: totalQuestions,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 5000,
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
      'gameMode': 'Sequence Memory',
      'level': _currentLevel,
      'workingMemoryScore': assessScore,
    });

    context.read<AppState>().updateGameAssessment('sequenceMemoryGame', GameSession(
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
        'maxSequenceLength': _sequence.length,
        'livesRemaining': _lives,
      },
      subdomainScores: {
        'workingMemory': assessScore,
        'shortTermMemory': (accuracy / 100.0) * 100.0,
      },
    ));

    context.read<AppState>().addPointsFromScore(_score);

    if (_highestUnlocked >= 8 && starsCount == 3) {
      context.read<AppState>().addSticker('sequence-genius');
    }

    setState(() {
      _gameState = 'level_complete';
    });
  }

  void _handleWrongAnswer() {
    AudioService().playSFX('wrong.mp3');
    setState(() {
      _wrongAnswers++;
      _lives--;
      _feedback = 'wrong';
    });

    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          AudioService().stopBGM();
          AudioService().playSFX('completion.mp3');
          setState(() {
            _gameState = 'completed'; // failed
          });
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _feedback = null;
          _isProcessing = false;
        });
        _generateSequence(_sequence.length);
      });
    }
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
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFFEC4899)])
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
                    Positioned(top: 80 - offset1, left: 40, child: const Text('🧠', style: TextStyle(fontSize: 48))),
                    Positioned(top: 128 + offset2, right: 64, child: const Text('⭐', style: TextStyle(fontSize: 56))),
                    Positioned(bottom: 128 - offset2, left: 80, child: const Text('🎯', style: TextStyle(fontSize: 48))),
                    Positioned(bottom: 80 + offset1, right: 48, child: const Text('✨', style: TextStyle(fontSize: 56))),
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
                        Text('Sequence Memory', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 20)),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 48),
                    const Text('🧠', style: TextStyle(fontSize: 96)),
                    const SizedBox(height: 24),
                    Text('Latih Daya Ingat!', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 28), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const Text('Perhatikan urutan warna yang muncul, lalu ulangi dengan benar!', style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cara Bermain:', style: AppTheme.heading3.copyWith(color: Colors.white)),
                          const SizedBox(height: 16),
                          _buildRuleRow('1', 'Perhatikan urutan warna yang menyala'),
                          const SizedBox(height: 12),
                          _buildRuleRow('2', 'Ingat baik-baik urutannya'),
                          const SizedBox(height: 12),
                          _buildRuleRow('3', 'Ketuk warna dengan urutan yang sama'),
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
                        child: const Text('🧠 Mulai Bermain!', style: TextStyle(color: Color(0xFF9333EA), fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildRuleRow(String num, String text) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: Color(0xFFA855F7), shape: BoxShape.circle),
          child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFF3E8FF)))),
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
            colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFFEC4899)]
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
                          'Pilih Level Sekuens 🧠',
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
                                  color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF475569), // Dark synth frame
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isUnlocked ? const Color(0xFFA855F7) : const Color(0xFF64748B), // Retro purple neon trim
                                    width: 4,
                                  ),
                                  boxShadow: isUnlocked
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFA855F7).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: isUnlocked
                                      ? Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // 4 colorful glowing indicator quadrants around the number
                                            Positioned(top: 6, left: 6, child: CircleAvatar(radius: 4, backgroundColor: Colors.redAccent.shade200)),
                                            Positioned(top: 6, right: 6, child: CircleAvatar(radius: 4, backgroundColor: Colors.blueAccent.shade200)),
                                            Positioned(bottom: 6, left: 6, child: CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent.shade200)),
                                            Positioned(bottom: 6, right: 6, child: CircleAvatar(radius: 4, backgroundColor: Colors.amberAccent.shade200)),
                                            Text(
                                              '$levelNum',
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(color: Color(0xFFA855F7), blurRadius: 8, offset: Offset(0, 0))
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Icon(Icons.lock_rounded, color: Colors.white38, size: 24),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA5B4FC), Color(0xFFD8B4FE), Color(0xFFF472B6)])
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
                        const Text('Sequence Memory', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.psychology, color: Color(0xFFE9D5FF), size: 20),
                          const SizedBox(width: 8),
                          Text('Nyawa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Row(
                        children: List.generate(3, (index) => Text(index < _lives ? '❤️' : '🖤', style: const TextStyle(fontSize: 24))),
                      ),
                    ],
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
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                        child: Column(
                          children: [
                            if (_gameState == 'showing')
                              const Text('Perhatikan Urutan...', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 20)),
                            if (_gameState == 'input') ...[
                              const Text('Ulangi Urutannya!', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 20)),
                              const SizedBox(height: 8),
                              Text('${_userSequence.length} / ${_sequence.length}', style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14)),
                            ],
                            if (_feedback != null) ...[
                              Text(_feedback == 'correct' ? '🎉' : '💔', style: const TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              Text(_feedback == 'correct' ? 'Benar Sekali!' : 'Oops! Salah', style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 20)),
                            ]
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: Center(
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            children: _buttons.map((button) {
                              bool isShowing = _sequence.isNotEmpty && _showingIndex != -1 && _showingIndex < _sequence.length && _sequence[_showingIndex] == button['id'] && _gameState == 'showing';
                              bool isDisabled = _gameState != 'input' || !_inputEnabled || _isProcessing;

                              return GestureDetector(
                                onTap: isDisabled ? null : () => _handleButtonClick(button['id']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  transform: isShowing ? Matrix4.diagonal3Values(1.15, 1.15, 1) : Matrix4.identity(),
                                  transformAlignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: button['color'],
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 10)],
                                  ),
                                  child: Center(
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 300),
                                      opacity: (isDisabled && !isShowing) ? 0.5 : 1.0,
                                      child: Text(button['emoji'], style: const TextStyle(fontSize: 64)),
                                    ),
                                  ),
                                ),
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
      backgroundColor: const Color(0xFFF3E8FF),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.25),
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
                    _rowStat('Panjang Sekuens:', '${_levelsConfig[_currentLevel - 1].sequenceLength}'),
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
                    foregroundColor: const Color(0xFF6B21A8),
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
                Text('Ulangi Sekuens Gagal!', style: AppTheme.heading1.copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _rowStat('Panjang Sekuens', '${_levelsConfig[_currentLevel - 1].sequenceLength}'),
                      const Divider(),
                      _rowStat('Urutan Benar', '${_userSequence.length}'),
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8))),
        ],
      ),
    );
  }
}
