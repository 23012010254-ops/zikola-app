import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class LogicGateLevel {
  final String leftRuleText;
  final String rightRuleText;
  final List<String> leftEmojis;
  final List<String> rightEmojis;

  LogicGateLevel({
    required this.leftRuleText,
    required this.rightRuleText,
    required this.leftEmojis,
    required this.rightEmojis,
  });
}

class DesertRoadLogicGame extends StatefulWidget {
  const DesertRoadLogicGame({super.key});

  @override
  State<DesertRoadLogicGame> createState() => _DesertRoadLogicGameState();
}

class _DesertRoadLogicGameState extends State<DesertRoadLogicGame> {
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, completed
  int _score = 0;
  int _lives = 3;
  int _currentLevel = 1;
  int _correctAnswers = 0;
  int _errors = 0;
  
  final List<int> _responseTimesMs = [];
  DateTime? _gameStartTime;
  int _spawnTimeMs = 0;
  
  LogicGateLevel? _currentLogic;
  String _currentEntity = '';
  String _correctTarget = ''; // 'left' or 'right'

  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  final Random _random = Random();

  // ---------------------------------------------------------------------------
  // LOGIC DATA (8 Levels)
  // ---------------------------------------------------------------------------
  final List<LogicGateLevel> _levelsData = [
    // Level 1: Kategori Dasar
    LogicGateLevel(
      leftRuleText: "HEWAN",
      rightRuleText: "KENDARAAN",
      leftEmojis: ['🐶', '🐱', '🐘', '🦒', '🐢', '🐄', '🐒'],
      rightEmojis: ['🚗', '🚙', '🚓', '🚑', '🚒', '🚜', '🚁'],
    ),
    // Level 2: Warna Kategorikal
    LogicGateLevel(
      leftRuleText: "WARNA MERAH",
      rightRuleText: "WARNA KUNING",
      leftEmojis: ['🍎', '🍓', '🚗', '🍅', '🔴', '🎒'],
      rightEmojis: ['🍌', '🍋', '🚕', '🧀', '🟡', '🌻'],
    ),
    // Level 3: Negasi (BUKAN)
    LogicGateLevel(
      leftRuleText: "BISA TERBANG",
      rightRuleText: "TIDAK BISA TERBANG",
      leftEmojis: ['🦅', '✈️', '🚁', '🦋', '🦇', '🕊️'],
      rightEmojis: ['🚗', '🐢', '🐘', '🏠', '🐕', '🚲'],
    ),
    // Level 4: Aturan Spesifik
    LogicGateLevel(
      leftRuleText: "HEWAN BERKAKI 4",
      rightRuleText: "LAINNYA",
      leftEmojis: ['🐕', '🐈', '🐄', '🐎', '🐫', '🐅'],
      rightEmojis: ['🦆', '🦅', '🐍', '🚗', '🍎', '🐟', '🧍'],
    ),
    // Level 5: Kombinasi Lengkap (Bukan Buah)
    LogicGateLevel(
      leftRuleText: "MAKANAN (BUKAN BUAH)",
      rightRuleText: "LAINNYA",
      leftEmojis: ['🍔', '🍕', '🧀', '🍞', '🌭', '🍟'],
      rightEmojis: ['🍎', '🍌', '🚗', '🐶', '⚽', '📱', '🍓'],
    ),
    // Level 6: Buah-buahan vs Sayur-sayuran
    LogicGateLevel(
      leftRuleText: "BUAH-BUAHAN",
      rightRuleText: "SAYUR-SAYURAN",
      leftEmojis: ['🍎', '🍌', '🍉', '🍇', '🍓', '🍒', '🍍', '🍊'],
      rightEmojis: ['🥕', '🌽', '🥦', '🍆', '🥬', '🥔', '🧅', '🍄'],
    ),
    // Level 7: Makhluk Hidup vs Benda Mati
    LogicGateLevel(
      leftRuleText: "MAKHLUK HIDUP",
      rightRuleText: "BENDA MATI",
      leftEmojis: ['🐶', '🐈', '🦁', '🐸', '🦋', '🌳', '🌻', '🧍'],
      rightEmojis: ['🚗', '🏠', '🧸', '📱', '⚽', '✏️', '🔑', '🛋️'],
    ),
    // Level 8: Peralatan Sekolah vs Peralatan Olahraga
    LogicGateLevel(
      leftRuleText: "ALAT SEKOLAH",
      rightRuleText: "ALAT OLAHRAGA",
      leftEmojis: ['🎒', '📚', '✏️', '📐', '✂️', '🎨', '🖊️', '📒'],
      rightEmojis: ['⚽', '🏀', '🎾', '🏈', '⚾', '🏸', '🏓', '🛹'],
    ),
  ];

  void _startGame() {
    setState(() {
      _gameState = 'level_select';
    });
  }

  void _startLevel(int level) {
    setState(() {
      _gameState = 'playing';
      _score = 0;
      _lives = 3;
      _currentLevel = level;
      _correctAnswers = 0;
      _errors = 0;
      _responseTimesMs.clear();
      _gameStartTime = DateTime.now();
    });
    
    AudioService().playBGM('puzzle_music.mp3');
    _generateNextEntity();
  }

  void _generateNextEntity() {
    int levelIdx = min(_currentLevel - 1, _levelsData.length - 1);
    _currentLogic = _levelsData[levelIdx];

    bool isLeft = _random.nextBool();
    if (isLeft) {
      _currentEntity = _currentLogic!.leftEmojis[_random.nextInt(_currentLogic!.leftEmojis.length)];
      _correctTarget = 'left';
    } else {
      _currentEntity = _currentLogic!.rightEmojis[_random.nextInt(_currentLogic!.rightEmojis.length)];
      _correctTarget = 'right';
    }

    _spawnTimeMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _handleSwipe(String direction) {
    if (_gameState != 'playing') return;

    int responseTime = DateTime.now().millisecondsSinceEpoch - _spawnTimeMs;
    bool isCorrect = direction == _correctTarget;

    setState(() {
      if (isCorrect) {
        AudioService().playSFX('correct.mp3');
        _score += (10 * _currentLevel);
        _correctAnswers++;
        _responseTimesMs.add(responseTime);
        
        if (_correctAnswers >= 5) {
          _completeLevel();
        } else {
          _generateNextEntity();
        }
      } else {
        AudioService().playSFX('wrong.mp3');
        _errors++;
        _lives--;

        if (_lives <= 0) {
          _endGame();
        } else {
          _generateNextEntity();
        }
      }
    });
  }

  void _completeLevel() {
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

    int totalTimeSecs = DateTime.now().difference(_gameStartTime!).inSeconds;
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
      'gameMode': 'Logic Convoy Routing',
    });

    appState.updateGameAssessment('desertRoadGame', GameSession(
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

    if (_highestUnlocked >= 8 && starsCount == 3) {
      appState.addSticker('road-master');
    }

    setState(() {
      _gameState = 'level_complete';
    });
  }

  void _endGame() {
    setState(() => _gameState = 'completed');
    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');

    int totalTimeSecs = DateTime.now().difference(_gameStartTime!).inSeconds;
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
      'gameMode': 'Logic Convoy Routing',
    });

    appState.updateGameAssessment('desertRoadGame', GameSession(
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
  }

  // ---------------------------------------------------------------------------
  // WIDGETS
  // ---------------------------------------------------------------------------
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
      backgroundColor: const Color(0xFFFDBA74),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(top: 100, left: 20, child: Text('🌞', style: TextStyle(fontSize: 80))),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🛣️', style: TextStyle(fontSize: 100)),
                    const SizedBox(height: 24),
                    Text('Logic Convoy\nRouting', style: AppTheme.heading1.copyWith(color: Colors.white, fontSize: 36), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text('Geser kendaraan ke gerbang yang sesuai dengan aturan logika!', style: TextStyle(color: Colors.orange.shade900, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cara Memainkan:', style: AppTheme.heading3),
                          const SizedBox(height: 16),
                          const Text('1. Perhatikan aturan logika di gerbang KIRI dan KANAN.', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          const Text('2. Lihat objek yang muncul di tengah bawah.', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          const Text('3. Seret/Swipe objek tersebut ke gerbang yang benar!', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Mulai Mengatur', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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

  Widget _buildLevelSelect() {
    return Scaffold(
      backgroundColor: const Color(0xFFFED7AA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF7C2D12)),
                    onPressed: () {
                      setState(() {
                        _gameState = 'menu';
                      });
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Pilih Level Konvoi 🛣️',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7C2D12),
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
                            child: Padding(
                              padding: const EdgeInsets.all(6.0), // Room for rotated diamond corners
                              child: Transform.rotate(
                                angle: 3.14159 / 4, // 45 degrees rotation
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color: isUnlocked ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1), // Caution Yellow or Slate Grey
                                    border: Border.all(
                                      color: isUnlocked ? const Color(0xFF7C2D12) : const Color(0xFF64748B),
                                      width: 4,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: isUnlocked
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.12),
                                              blurRadius: 6,
                                              offset: const Offset(2, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isUnlocked ? const Color(0xFF7C2D12) : const Color(0xFF64748B),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Transform.rotate(
                                      angle: -3.14159 / 4, // Rotate content back
                                      child: Center(
                                        child: isUnlocked
                                            ? Text(
                                                '$levelNum',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF7C2D12),
                                                  fontFamily: 'Nunito',
                                                ),
                                              )
                                            : const Icon(Icons.lock_rounded, color: Color(0xFF64748B), size: 22),
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

  Widget _buildPlaying() {
    return Scaffold(
      backgroundColor: const Color(0xFFFED7AA), // Orange-200
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF7C2D12), size: 20),
                        onPressed: () {
                          AudioService().stopBGM();
                          setState(() {
                            _gameState = 'level_select';
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                        ),
                        child: Text('Level $_currentLevel', style: AppTheme.heading3.copyWith(color: Colors.orange.shade800)),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(3, (index) => Icon(Icons.favorite, color: index < _lives ? Colors.red : Colors.grey.shade400, size: 28)),
                  ),
                ],
              ),
            ),

            // Logic Gates
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  // LEFT GATE
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DragTarget<String>(
                        onAcceptWithDetails: (details) => _handleSwipe('left'),
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              color: candidateData.isNotEmpty ? Colors.orange.shade300 : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.orange.shade400, width: 4),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_downward, size: 40, color: Colors.orange),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(_currentLogic?.leftRuleText ?? '', 
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // RIGHT GATE
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DragTarget<String>(
                        onAcceptWithDetails: (details) => _handleSwipe('right'),
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              color: candidateData.isNotEmpty ? Colors.orange.shade300 : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.orange.shade400, width: 4),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_downward, size: 40, color: Colors.orange),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(_currentLogic?.rightRuleText ?? '', 
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                  ),
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

            // Draggable Entity Pool
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDBA74), // darker road
                      borderRadius: BorderRadius.vertical(top: Radius.circular(100)),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    child: Draggable<String>(
                      data: _currentEntity,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Text(_currentEntity, style: const TextStyle(fontSize: 100)),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Text(_currentEntity, style: const TextStyle(fontSize: 100)),
                      ),
                      child: Text(_currentEntity, style: const TextStyle(fontSize: 100)),
                    ),
                  ),
                  const Positioned(
                    bottom: 20,
                    child: Text('Geser ke Kiri atau Kanan 🔼', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                  )
                ],
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

    int totalTimeSecs = DateTime.now().difference(_gameStartTime!).inSeconds;
    int totalPushed = _correctAnswers + _errors;
    int accuracy = totalPushed > 0 ? ((_correctAnswers / totalPushed) * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFED7AA),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.35),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'KONVOI AMAN! 🛣️',
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
                    _rowStat('Penyortiran Benar:', '$_correctAnswers'),
                    const Divider(color: Colors.white24),
                    _rowStat('Akurasi Logika:', '$accuracy%'),
                    const Divider(color: Colors.white24),
                    _rowStat('Waktu Bermain:', '$totalTimeSecs detik'),
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
                    foregroundColor: const Color(0xFFC2410C),
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
                const Text('💥', style: TextStyle(fontSize: 100)),
                const SizedBox(height: 24),
                Text('Konvoi Menabrak!\nLevel Gagal', style: AppTheme.heading1.copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _rowStat('Penyortiran Benar', '$_correctAnswers'),
                      const Divider(),
                      _rowStat('Kesalahan Logika', '$_errors'),
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
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
        ],
      ),
    );
  }
}
