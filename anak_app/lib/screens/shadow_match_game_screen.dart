import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../services/assessment_engine.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class ShadowMatchGameScreen extends StatefulWidget {
  const ShadowMatchGameScreen({super.key});

  @override
  State<ShadowMatchGameScreen> createState() => _ShadowMatchGameScreenState();
}

class _ShadowMatchGameScreenState extends State<ShadowMatchGameScreen> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, completed (fail)
  int _currentLevel = 1;
  int _score = 0;
  int _correctAnswers = 0;
  int _errors = 0;
  int _lives = 3;
  int _roundIndex = 0; // 3 rounds per level
  DateTime? _gameStartTime;
  double _rotationAngle = 0.0;

  String? targetEmoji;
  List<String> options = [];

  final List<String> allEmojis = [
    '🐶', '🐱', '🐭', '🐰', '🦊', '🐻', '🐼', '🐨', '🐸', '🐔',
    '🚗', '🚕', '🚙', '🚌', '🚓', '🚑', '🚒', '🚜', '🛵', '🚲',
    '🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈', '🍒', '🍍',
  ];

  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  late AnimationController _pulseController;
  late AnimationController _successController;
  late AnimationController _bgAnimCtrl;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _bgAnimCtrl.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  int getOptionsCount(int level) {
    switch (level) {
      case 1: return 3;
      case 2: return 4;
      case 3: return 5;
      case 4: return 6;
      case 5: return 6;
      case 6: return 6;
      case 7: return 7;
      case 8:
      default:
        return 8;
    }
  }

  void _startLevel(int level) {
    setState(() {
      _gameState = 'playing';
      _currentLevel = level;
      _score = 0;
      _correctAnswers = 0;
      _errors = 0;
      _lives = 3;
      _roundIndex = 0;
      _gameStartTime = DateTime.now();
    });
    AudioService().playBGM('creative_bgm.mp3.wav', volume: 0.3);
    _generateLevel();
  }

  void _generateLevel() {
    final random = math.Random();
    List<String> pool = List.from(allEmojis)..shuffle();
    
    int count = getOptionsCount(_currentLevel);
    options = pool.take(count).toList();
    targetEmoji = options[random.nextInt(count)];

    // Add rotation for Level 5 and above to increase spatial rotation difficulty
    if (_currentLevel >= 5) {
      _rotationAngle = (random.nextBool() ? 1 : -1) * (15 + random.nextInt(30)) * math.pi / 180;
    } else {
      _rotationAngle = 0.0;
    }

    setState(() {});
  }

  void _handleDrop(String draggedEmoji) {
    if (_lives <= 0 || _gameState != 'playing') return;

    if (draggedEmoji == targetEmoji) {
      AudioService().playSFX('correct_match.mp3.wav');
      _successController.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          _score += 20;
          _correctAnswers++;
          _roundIndex++;
          if (_roundIndex >= 3) {
            _completeLevel();
          } else {
            _generateLevel();
          }
        });
      });
    } else {
      AudioService().playSFX('error.mp3');
      setState(() {
        _errors++;
        _lives--;
        if (_lives <= 0) {
          AudioService().stopBGM();
          AudioService().playSFX('completion.mp3');
          _gameState = 'completed'; // fail
        } else {
          // Generate a new matching pair on error to keep the game engaging
          _generateLevel();
        }
      });
    }
  }

  void _completeLevel() {
    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');

    int starsCount = _lives;
    _starRatings[_currentLevel - 1] = math.max(_starRatings[_currentLevel - 1], starsCount);

    if (_currentLevel == _highestUnlocked && _currentLevel < 8) {
      _highestUnlocked = _currentLevel + 1;
    }

    final appState = context.read<AppState>();
    int totalTime = _gameStartTime != null ? DateTime.now().difference(_gameStartTime!).inSeconds : 0;
    int totalAttempts = _correctAnswers + _errors;
    if (totalAttempts == 0) totalAttempts = 1;
    int accuracy = ((_correctAnswers / totalAttempts) * 100).round().clamp(0, 100);
    int avgRespMs = _correctAnswers > 0 ? ((totalTime * 1000) / _correctAnswers).round() : 0;

    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: 3,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 12000,
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _errors,
    );

    appState.updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': 3,
      'percentage': accuracy,
      'timeSpent': totalTime,
      'gameMode': 'Shadow Match',
      'level': _currentLevel,
      'shadowMatchScore': assessScore,
    });

    appState.updateGameAssessment('cognitiveGame', GameSession(
      score: _score,
      timeSpent: totalTime,
      errors: _errors,
      totalItems: 3,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'livesRemaining': _lives,
      },
      subdomainScores: {
        'visualPrecision': assessScore,
        'spatialRelation': (accuracy / 100.0) * 80.0,
      },
    ));

    appState.addPointsFromScore(_score);

    if (_highestUnlocked >= 8 && starsCount == 3) {
      appState.addSticker('visual-master');
    }

    setState(() {
      _gameState = 'level_complete';
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
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF4FF), Color(0xFFFCE7F3), Color(0xFFF472B6)],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _bgAnimCtrl,
              builder: (context, child) {
                double offset1 = math.sin(_bgAnimCtrl.value * math.pi) * 10;
                double offset2 = math.cos(_bgAnimCtrl.value * math.pi) * 15;
                return Stack(
                  children: [
                    Positioned(top: 80 - offset1, left: 40, child: const Text('👥', style: TextStyle(fontSize: 48))),
                    Positioned(top: 120 + offset2, right: 60, child: const Text('🕵️', style: TextStyle(fontSize: 56))),
                    Positioned(bottom: 150 - offset2, left: 70, child: const Text('✨', style: TextStyle(fontSize: 48))),
                    Positioned(bottom: 90 + offset1, right: 50, child: const Text('⭐', style: TextStyle(fontSize: 56))),
                  ],
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back, color: Color(0xFFBE185D)),
                          ),
                        ),
                        Text('Tebak Bayangan 👥', style: AppTheme.heading2.copyWith(color: const Color(0xFFBE185D), fontSize: 20)),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const Spacer(),
                    const Text('👥', style: TextStyle(fontSize: 100)),
                    const SizedBox(height: 24),
                    Text('Tebak Bayangan', style: AppTheme.heading1.copyWith(color: const Color(0xFF9D174D), fontSize: 36), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'Tarik gambar kartun lucu dan letakkan ke bayangan hitam yang cocok!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9D174D), fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _gameState = 'level_select';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFEC4899),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 6,
                        ),
                        child: const Text('👥 PILIH LEVEL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildLevelSelect() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF4FF), Color(0xFFFCE7F3), Color(0xFFF472B6)],
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
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFBE185D)),
                      onPressed: () {
                        setState(() {
                          _gameState = 'menu';
                        });
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Pilih Level Bayangan 👥',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF9D174D),
                            fontFamily: 'Nunito',
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
                                              colors: [Color(0xFF1E1B4B), Color(0xFF311042)], // Dark mysterious shadow violet/indigo
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : const LinearGradient(
                                              colors: [Color(0xFF475569), Color(0xFF334155)], // Slate grey
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                      border: Border.all(
                                        color: isUnlocked ? const Color(0xFFF43F5E) : const Color(0xFF64748B), // Glowing neon pink border
                                        width: 3.5,
                                      ),
                                      boxShadow: isUnlocked
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFF43F5E).withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Subtle silhouette icon background in the mysterious archway
                                        if (isUnlocked)
                                          Icon(
                                            Icons.portrait_rounded,
                                            size: 48,
                                            color: Colors.white.withOpacity(0.06),
                                          ),
                                        Center(
                                          child: isUnlocked
                                              ? Text(
                                                  '$levelNum',
                                                  style: const TextStyle(
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(color: Color(0xFFF43F5E), blurRadius: 8, offset: Offset(0, 0))
                                                    ],
                                                  ),
                                                )
                                              : const Icon(Icons.lock_rounded, color: Colors.white38, size: 24),
                                        ),
                                      ],
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
                                  size: 16,
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
      backgroundColor: const Color(0xFFFDF4FF), // Fuchsia tint
      body: SafeArea(
        child: Column(
          children: [
            // Header stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFC084FC), size: 30),
                    onPressed: () {
                      AudioService().stopBGM();
                      setState(() {
                        _gameState = 'level_select';
                      });
                    },
                  ),
                  Column(
                    children: [
                      Text('Level $_currentLevel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFBE185D))),
                      Text('Soal ${_roundIndex + 1} dari 3', style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: List.generate(3, (index) => Icon(
                      Icons.favorite,
                      color: index < _lives ? Colors.redAccent : Colors.black12,
                      size: 24,
                    )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Text('Tarik gambar ke bayangan yang tepat!', style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
            
            Expanded(
              flex: 3,
              child: Center(
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (data) => true,
                  onAcceptWithDetails: (details) => _handleDrop(details.data),
                  builder: (context, candidateData, rejectedData) {
                    bool highlighted = candidateData.isNotEmpty;
                    
                    return AnimatedBuilder(
                      animation: _successController,
                      builder: (context, child) {
                        double scale = 1.0 + (_successController.value * 0.5);
                        double opacity = 1.0 - _successController.value;
                        
                        return Transform.scale(
                          scale: _successController.isAnimating ? scale : (highlighted ? 1.1 : 1.0),
                          child: Opacity(
                            opacity: _successController.isAnimating ? opacity : 1.0,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: highlighted ? Colors.white : Colors.black.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: highlighted ? const Color(0xFFE879F9) : Colors.black.withOpacity(0.1),
                                  width: 4,
                                  style: highlighted ? BorderStyle.solid : BorderStyle.none,
                                ),
                              ),
                              child: Center(
                                child: targetEmoji != null
                                  ? Transform.rotate(
                                      angle: _rotationAngle,
                                      child: ColorFiltered(
                                        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                        child: Text(targetEmoji!, style: const TextStyle(fontSize: 100)),
                                      ),
                                    )
                                  : const SizedBox(),
                              ),
                            ),
                          ),
                        );
                      }
                    );
                  },
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: options.map((emoji) {
                        return Draggable<String>(
                          data: emoji,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Text(emoji, style: const TextStyle(fontSize: 80)),
                          ),
                          childWhenDragging: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                          ),
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF4FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE879F9), width: 3),
                              boxShadow: [BoxShadow(color: const Color(0xFFC084FC).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelComplete() {
    int starsCount = _lives;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF4FF), Color(0xFFFCE7F3), Color(0xFFF472B6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  const Text(
                    'LEVEL SELESAI!',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF9D174D)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stars display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final isStarred = i < starsCount;
                      return Icon(
                        Icons.star_rounded,
                        color: isStarred ? Colors.amber : Colors.black12,
                        size: 64,
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        _buildStatRow('Benar', '$_correctAnswers / 3'),
                        const Divider(),
                        _buildStatRow('Kesalahan', '$_errors'),
                        const Divider(),
                        _buildStatRow('Skor', '$_score'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentLevel < 8) {
                          _startLevel(_currentLevel + 1);
                        } else {
                          setState(() {
                            _gameState = 'level_select';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEC4899),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentLevel < 8 ? 'LEVEL BERIKUTNYA ➡️' : 'PETA LEVEL 🗺️',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _startLevel(_currentLevel),
                    child: const Text('Main Lagi 🔄', style: TextStyle(fontSize: 16, color: Color(0xFF9D174D), fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _gameState = 'level_select';
                      });
                    },
                    child: const Text('Kembali ke Peta Level 🗺️', style: TextStyle(fontSize: 16, color: Color(0xFFBE185D), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    // Fail Screen
    return Scaffold(
      backgroundColor: const Color(0xFFEF4444),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('😢', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 20),
                const Text(
                  'YAH, NYAWA HABIS!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jangan berkecil hati! Coba asah kembali ketelitian visualmu.',
                  style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _buildStatRow('Cocok Benar', '$_correctAnswers / 3', labelColor: Colors.black54, valueColor: const Color(0xFFEF4444)),
                      const Divider(),
                      _buildStatRow('Kesalahan', '$_errors', labelColor: Colors.black54, valueColor: const Color(0xFFEF4444)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _startLevel(_currentLevel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text('COBA LAGI 🔄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _gameState = 'level_select';
                    });
                  },
                  child: const Text('Kembali ke Peta Level 🗺️', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color labelColor = Colors.black54, Color valueColor = const Color(0xFF9D174D)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: labelColor)),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valueColor)),
        ],
      ),
    );
  }
}
