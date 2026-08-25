import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/assessment_engine.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

enum BubbleType { normal, golden, skull, bomb }

class Bubble {
  double x; // Normalized 0.0 - 1.0
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  BubbleType type;
  bool isPopped;
  double shrinkFactor; // For shrinking bubbles (Level 5)
  int id;

  Bubble({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.type = BubbleType.normal,
    this.isPopped = false,
    this.shrinkFactor = 1.0,
    required this.id,
  });
}

class ScorePopup {
  double x;
  double y;
  String text;
  Color color;
  double opacity;
  double offsetY;
  
  ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.opacity = 1.0,
    this.offsetY = 0.0,
  });
}

class PopParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;

  PopParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.life = 1.0,
  });
}

class LevelConfig {
  final int level;
  final int bubbleCount;
  final double baseSpeed;
  final int targetPops;
  final int timeLimit;
  final double minSize;
  final double maxSize;
  final bool hasShrinking;
  final double shrinkTarget;
  final bool hasSkull;
  final bool hasBomb;
  final bool hasGolden;
  final bool hasRandomDirectionChange;
  final double directionChangeInterval;
  final String description;

  const LevelConfig({
    required this.level,
    required this.bubbleCount,
    required this.baseSpeed,
    required this.targetPops,
    required this.timeLimit,
    this.minSize = 80,
    this.maxSize = 80,
    this.hasShrinking = false,
    this.shrinkTarget = 50,
    this.hasSkull = false,
    this.hasBomb = false,
    this.hasGolden = false,
    this.hasRandomDirectionChange = false,
    this.directionChangeInterval = 2.0,
    required this.description,
  });
}

// ─── Level Configurations ─────────────────────────────────────────────────────

const List<LevelConfig> _levelConfigs = [
  LevelConfig(level: 1, bubbleCount: 1, baseSpeed: 0.0, targetPops: 8, timeLimit: 30, description: 'Gelembung Diam'),
  LevelConfig(level: 2, bubbleCount: 1, baseSpeed: 0.004, targetPops: 10, timeLimit: 30, description: 'Melayang Lambat'),
  LevelConfig(level: 3, bubbleCount: 2, baseSpeed: 0.006, targetPops: 12, timeLimit: 30, description: 'Dua Gelembung'),
  LevelConfig(level: 4, bubbleCount: 2, baseSpeed: 0.008, targetPops: 15, timeLimit: 45, minSize: 60, maxSize: 90, description: 'Cepat & Beragam'),
  LevelConfig(level: 5, bubbleCount: 3, baseSpeed: 0.010, targetPops: 18, timeLimit: 45, hasShrinking: true, shrinkTarget: 50, hasGolden: true, description: 'Menyusut & Emas'),
  LevelConfig(level: 6, bubbleCount: 3, baseSpeed: 0.012, targetPops: 20, timeLimit: 45, hasSkull: true, hasGolden: true, description: 'Hati-hati Tengkorak!'),
  LevelConfig(level: 7, bubbleCount: 4, baseSpeed: 0.010, targetPops: 22, timeLimit: 60, hasRandomDirectionChange: true, directionChangeInterval: 2.0, hasBomb: true, hasGolden: true, description: 'Bom & Kacau'),
  LevelConfig(level: 8, bubbleCount: 5, baseSpeed: 0.015, targetPops: 25, timeLimit: 60, hasGolden: true, hasSkull: true, hasBomb: true, minSize: 50, maxSize: 90, description: 'Level Terakhir!'),
];

// ─── Main Widget ──────────────────────────────────────────────────────────────

class BubblePopperGameScreen extends StatefulWidget {
  const BubblePopperGameScreen({super.key});

  @override
  State<BubblePopperGameScreen> createState() => _BubblePopperGameScreenState();
}

class _BubblePopperGameScreenState extends State<BubblePopperGameScreen> with TickerProviderStateMixin {
  // Core game state
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, game_over, victory
  int _currentLevel = 0; // Index into _levelConfigs
  int _popsCount = 0;
  int _totalScore = 0;
  int _highestUnlocked = 1;
  final List<int> _starRatings = List.filled(8, 0);

  // Bubbles
  List<Bubble> _bubbles = [];
  int _nextBubbleId = 0;

  // Timer
  int _timeRemaining = 30;
  Timer? _countdownTimer;

  // Combo system
  int _comboMultiplier = 1;
  int _maxCombo = 1;
  DateTime? _lastPopTime;
  Timer? _comboResetTimer;

  // Visual effects
  List<ScorePopup> _scorePopups = [];
  List<PopParticle> _particles = [];

  // Drift & physics ticker
  Timer? _physicsTicker;
  Timer? _directionChangeTimer;
  Timer? _shrinkTimer;

  int _totalPops = 0;
  int _totalTimeSpent = 0;
  int _skullPopsCount = 0;

  // Colors for normal bubbles
  final List<Color> _bubbleColors = [
    Colors.lightBlue.shade300,
    Colors.pink.shade300,
    Colors.purple.shade300,
    Colors.teal.shade300,
    Colors.orange.shade300,
    Colors.green.shade300,
    Colors.red.shade300,
  ];

  final math.Random _random = math.Random();

  LevelConfig get _config => _levelConfigs[_currentLevel];

  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _gameState = 'menu';
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _physicsTicker?.cancel();
    _directionChangeTimer?.cancel();
    _shrinkTimer?.cancel();
    _comboResetTimer?.cancel();
    AudioService().stopBGM();
    _floatController.dispose();
    super.dispose();
  }

  // ─── Level Setup ──────────────────────────────────────────────────────────

  void _startLevel() {
    _countdownTimer?.cancel();
    _physicsTicker?.cancel();
    _directionChangeTimer?.cancel();
    _shrinkTimer?.cancel();
    _comboResetTimer?.cancel();

    setState(() {
      _popsCount = 0;
      _comboMultiplier = 1;
      _lastPopTime = null;
      _timeRemaining = _config.timeLimit;
      _scorePopups = [];
      _particles = [];
      _gameState = 'playing';
    });

    _spawnAllBubbles();

    // Start physics ticker (60fps)
    _physicsTicker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updatePhysics();
    });

    // Start countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeRemaining--;
      });
      if (_timeRemaining <= 0) {
        _onTimeUp();
      }
    });

    // Random direction changes for level 7+
    if (_config.hasRandomDirectionChange) {
      _directionChangeTimer = Timer.periodic(
        Duration(milliseconds: (_config.directionChangeInterval * 1000).toInt()),
        (_) => _randomizeDirections(),
      );
    }

    // Shrinking bubbles for level 5
    if (_config.hasShrinking) {
      _shrinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        setState(() {
          for (final b in _bubbles) {
            if (!b.isPopped && b.type == BubbleType.normal) {
              b.shrinkFactor = (b.shrinkFactor - 0.02).clamp(0.6, 1.0);
            }
          }
        });
      });
    }
  }

  void _spawnAllBubbles() {
    _bubbles = [];
    final config = _config;

    for (int i = 0; i < config.bubbleCount; i++) {
      _bubbles.add(_createBubble(_decideBubbleType(i)));
    }
  }

  BubbleType _decideBubbleType(int index) {
    final config = _config;
    // First bubble is always normal
    if (index == 0) return BubbleType.normal;
    // Last bubble can be special
    if (config.hasSkull && index == config.bubbleCount - 1) return BubbleType.skull;
    if (config.hasGolden && index == 1 && config.bubbleCount >= 3) return BubbleType.golden;
    if (config.hasBomb && index == config.bubbleCount - 2 && config.bubbleCount >= 4) return BubbleType.bomb;
    return BubbleType.normal;
  }

  Bubble _createBubble(BubbleType type) {
    final config = _config;
    final size = config.minSize + _random.nextDouble() * (config.maxSize - config.minSize);
    final speedVariation = 0.7 + _random.nextDouble() * 0.6; // 0.7x to 1.3x

    Color color;
    switch (type) {
      case BubbleType.golden:
        color = Colors.amber.shade400;
        break;
      case BubbleType.skull:
        color = Colors.red.shade400;
        break;
      case BubbleType.bomb:
        color = Colors.grey.shade700;
        break;
      default:
        color = _bubbleColors[_random.nextInt(_bubbleColors.length)];
    }

    final vx = config.baseSpeed > 0
        ? config.baseSpeed * speedVariation * (_random.nextBool() ? 1 : -1)
        : 0.0;
    final vy = config.baseSpeed > 0
        ? config.baseSpeed * 0.7 * speedVariation * (_random.nextBool() ? 1 : -1)
        : 0.0;

    return Bubble(
      id: _nextBubbleId++,
      x: 0.15 + _random.nextDouble() * 0.7,
      y: 0.15 + _random.nextDouble() * 0.7,
      vx: vx,
      vy: vy,
      size: size,
      color: color,
      type: type,
    );
  }

  // ─── Physics Update ───────────────────────────────────────────────────────

  void _updatePhysics() {
    if (!mounted || _gameState != 'playing') return;

    setState(() {
      // Update bubbles
      for (final b in _bubbles) {
        if (b.isPopped) continue;

        b.x += b.vx;
        b.y += b.vy;

        // Bounce off edges
        if (b.x <= 0.05 || b.x >= 0.95) {
          b.vx = -b.vx;
          b.x = b.x.clamp(0.05, 0.95);
        }
        if (b.y <= 0.05 || b.y >= 0.95) {
          b.vy = -b.vy;
          b.y = b.y.clamp(0.05, 0.95);
        }
      }

      // Update score popups
      for (final popup in _scorePopups) {
        popup.offsetY -= 1.2;
        popup.opacity -= 0.02;
      }
      _scorePopups.removeWhere((p) => p.opacity <= 0);

      // Update particles
      for (final p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.15; // Gravity
        p.life -= 0.03;
        p.size *= 0.97;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _randomizeDirections() {
    if (!mounted) return;
    for (final b in _bubbles) {
      if (b.isPopped) continue;
      final speed = _config.baseSpeed * (0.7 + _random.nextDouble() * 0.6);
      b.vx = speed * (_random.nextBool() ? 1 : -1);
      b.vy = speed * 0.7 * (_random.nextBool() ? 1 : -1);
    }
  }

  // ─── Pop Logic ────────────────────────────────────────────────────────────

  void _onBubbleTapped(Bubble bubble) {
    if (bubble.isPopped || _gameState != 'playing') return;

    final now = DateTime.now();

    // Handle combo
    if (_lastPopTime != null && now.difference(_lastPopTime!).inMilliseconds < 1000) {
      _comboMultiplier = (_comboMultiplier + 1).clamp(1, 5);
    } else {
      _comboMultiplier = 1;
    }
    _lastPopTime = now;
    if (_comboMultiplier > _maxCombo) _maxCombo = _comboMultiplier;

    // Reset combo after 1.5s of inactivity
    _comboResetTimer?.cancel();
    _comboResetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _comboMultiplier = 1;
        });
      }
    });

    switch (bubble.type) {
      case BubbleType.normal:
        _handleNormalPop(bubble);
        break;
      case BubbleType.golden:
        _handleGoldenPop(bubble);
        break;
      case BubbleType.skull:
        _handleSkullPop(bubble);
        break;
      case BubbleType.bomb:
        _handleBombPop(bubble);
        break;
    }
  }

  void _handleNormalPop(Bubble bubble) {
    AudioService().playSFX('pop.mp3');
    
    final levelMult = _currentLevel + 1;
    final sizeBonus = bubble.size < 65 ? 2 : 1; // Smaller = more points
    final points = 10 * _comboMultiplier * levelMult * sizeBonus;

    setState(() {
      bubble.isPopped = true;
      _popsCount++;
      _totalPops++;
      _totalScore += points;
      _spawnParticles(bubble.x, bubble.y, bubble.color);
      _addScorePopup(bubble.x, bubble.y, '+$points', Colors.white);
    });

    _respawnOrAdvance(bubble);
  }

  void _handleGoldenPop(Bubble bubble) {
    AudioService().playSFX('pop.mp3');
    
    final levelMult = _currentLevel + 1;
    final points = 30 * _comboMultiplier * levelMult;

    setState(() {
      bubble.isPopped = true;
      _popsCount += 3;
      _totalPops += 3;
      _totalScore += points;
      _spawnParticles(bubble.x, bubble.y, Colors.amber);
      _addScorePopup(bubble.x, bubble.y, '+$points ✨', Colors.amber);
    });

    _respawnOrAdvance(bubble);
  }

  void _handleSkullPop(Bubble bubble) {
    AudioService().playSFX('wrong.mp3');
    
    final penalty = 20 * (_currentLevel + 1);

    setState(() {
      _skullPopsCount++;
      bubble.isPopped = true;
      _popsCount = (_popsCount - 2).clamp(0, _config.targetPops);
      _totalScore = (_totalScore - penalty).clamp(0, _totalScore + penalty);
      _comboMultiplier = 1; // Reset combo on skull
      _spawnParticles(bubble.x, bubble.y, Colors.red);
      _addScorePopup(bubble.x, bubble.y, '-2 💀', Colors.red);
    });

    _respawnBubble(bubble, BubbleType.skull);
  }

  void _handleBombPop(Bubble bubble) {
    AudioService().playSFX('pop.mp3');
    
    setState(() {
      bubble.isPopped = true;
      _spawnParticles(bubble.x, bubble.y, Colors.orange);
      _addScorePopup(bubble.x, bubble.y, '💣 BOOM!', Colors.orange);

      // Pop all normal bubbles on screen
      for (final b in _bubbles) {
        if (!b.isPopped && b.type == BubbleType.normal) {
          b.isPopped = true;
          _popsCount++;
          _totalPops++;
          _totalScore += 10 * (_currentLevel + 1);
          _spawnParticles(b.x, b.y, b.color);
        }
      }
    });

    // Respawn all popped bubbles after delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _gameState != 'playing') return;
      if (_popsCount >= _config.targetPops) {
        _advanceLevel();
      } else {
        setState(() {
          for (int i = 0; i < _bubbles.length; i++) {
            if (_bubbles[i].isPopped) {
              _bubbles[i] = _createBubble(_decideBubbleType(i));
            }
          }
        });
      }
    });
  }

  void _respawnOrAdvance(Bubble bubble) {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || _gameState != 'playing') return;
      if (_popsCount >= _config.targetPops) {
        _advanceLevel();
      } else {
        _respawnBubble(bubble, bubble.type);
      }
    });
  }

  void _respawnBubble(Bubble bubble, BubbleType type) {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || _gameState != 'playing') return;
      setState(() {
        final idx = _bubbles.indexWhere((b) => b.id == bubble.id);
        if (idx != -1) {
          // Occasionally change special bubble type on respawn
          BubbleType newType = type;
          if (_random.nextDouble() < 0.3 && type == BubbleType.normal && _config.hasGolden) {
            newType = BubbleType.golden;
          } else if (_random.nextDouble() < 0.2 && type == BubbleType.normal && _config.hasSkull) {
            newType = BubbleType.skull;
          }
          _bubbles[idx] = _createBubble(newType);
        }
      });
    });
  }

  // ─── Visual Effects ───────────────────────────────────────────────────────

  void _spawnParticles(double x, double y, Color color) {
    for (int i = 0; i < 8; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 1.5 + _random.nextDouble() * 3;
      _particles.add(PopParticle(
        x: x * 300 + 20, // Approximate px
        y: y * 400 + 20,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 2,
        size: 3 + _random.nextDouble() * 4,
        color: color.withOpacity(0.8),
      ));
    }
  }

  void _addScorePopup(double x, double y, String text, Color color) {
    _scorePopups.add(ScorePopup(
      x: x,
      y: y,
      text: text,
      color: color,
    ));
  }

  // ─── Level Progression ────────────────────────────────────────────────────

  void _advanceLevel() {
    _countdownTimer?.cancel();
    _physicsTicker?.cancel();
    _directionChangeTimer?.cancel();
    _shrinkTimer?.cancel();

    _totalTimeSpent += (_config.timeLimit - _timeRemaining);

    // Calculate stars
    final timePercent = _timeRemaining / _config.timeLimit;
    int stars = 1; // Completed
    if (timePercent >= 0.20) stars = 2;
    if (timePercent >= 0.50) stars = 3;
    
    _starRatings[_currentLevel] = math.max(_starRatings[_currentLevel], stars);

    // Save highest unlocked level
    if (_currentLevel + 1 == _highestUnlocked && _highestUnlocked < 8) {
      _highestUnlocked = _currentLevel + 2;
    }

    // Time bonus
    final timeBonus = (_timeRemaining * 5 * (_currentLevel + 1));
    _totalScore += timeBonus;

    AudioService().playSFX('correct.mp3');

    setState(() {
      _gameState = 'level_complete';
    });
  }

  void _onTimeUp() {
    _countdownTimer?.cancel();
    _physicsTicker?.cancel();
    _directionChangeTimer?.cancel();
    _shrinkTimer?.cancel();

    _totalTimeSpent += _config.timeLimit;

    AudioService().playSFX('game_over.mp3');
    setState(() {
      _gameState = 'game_over';
    });
  }

  void _retryLevel() {
    _startLevel();
  }

  void _saveResults() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    final int totalTime = _totalTimeSpent > 0 ? _totalTimeSpent : 120;
    final int avgRespMs = _totalPops > 0 ? ((totalTime * 1000) / _totalPops).round() : 0;
    
    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: _totalPops + _skullPopsCount,
      correct: _totalPops,
      avgResponseMs: avgRespMs,
      idealTimeMs: 2000, 
      maxLevel: _currentLevel + 1,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _skullPopsCount,
    );

    appState.updateTestResults('motor', {
      'completed': true,
      'score': _totalScore,
      'timeSpent': totalTime,
      'percentage': (_totalScore / 5000 * 100).clamp(0, 100).round(),
      'categoryScores': {
        'coordination': ((_totalPops / math.max(_totalPops + _skullPopsCount, 1)) * 40).round(),
        'speed': ((1 - (avgRespMs / 5000)).clamp(0.0, 1.0) * 30).round(),
        'precision': ((_totalPops / math.max(_totalPops + _skullPopsCount, 1)) * 30).round(),
      }
    });

    appState.updateGameAssessment('motor', GameSession(
      score: _totalScore,
      timeSpent: totalTime,
      errors: _skullPopsCount,
      totalItems: _totalPops + _skullPopsCount,
      correctAnswers: _totalPops,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel + 1,
      hintsUsed: 0,
      assessmentScore: assessScore,
      subdomainScores: {
        'fineMotor': assessScore,
      },
    ));

    appState.addPointsFromScore(_totalScore);
    appState.addSticker('bubble-master');
    if (_totalPops >= 50) appState.addSticker('bubble-champion');
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_gameState) {
      case 'menu':
        return _buildMenu();
      case 'level_select':
        return _buildLevelSelect();
      case 'playing':
        return _buildGameplayScreen();
      case 'level_complete':
        return _buildLevelCompleteScreen();
      case 'game_over':
        return _buildGameOverScreen();
      case 'victory':
        return _buildFinalVictoryScreen();
      default:
        return _buildMenu();
    }
  }

  // ─── Gameplay Screen ──────────────────────────────────────────────────────

  Widget _buildGameplayScreen() {
    final config = _config;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Pecah Gelembung 🫧', style: AppTheme.heading3),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gray700),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // ── HUD ──
              _buildHUD(config),
              const SizedBox(height: 8),

              // ── Progress Bar ──
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_popsCount / config.targetPops).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _popsCount >= config.targetPops * 0.8
                        ? Colors.green
                        : Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Game Area ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final areaWidth = constraints.maxWidth;
                    final areaHeight = constraints.maxHeight;

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          children: [
                            // Background grid
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.03,
                                child: GridPaper(
                                  color: Colors.blue,
                                  interval: 40,
                                  subdivisions: 1,
                                ),
                              ),
                            ),

                            // Particles
                            ..._particles.map((p) => Positioned(
                              left: (p.x / 300) * areaWidth,
                              top: (p.y / 400) * areaHeight,
                              child: Opacity(
                                opacity: p.life.clamp(0.0, 1.0),
                                child: Container(
                                  width: p.size,
                                  height: p.size,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.color,
                                  ),
                                ),
                              ),
                            )),

                            // Bubbles
                            ..._bubbles.where((b) => !b.isPopped).map((bubble) {
                              final effectiveSize = bubble.size * bubble.shrinkFactor;
                              return Positioned(
                                left: bubble.x * (areaWidth - effectiveSize),
                                top: bubble.y * (areaHeight - effectiveSize),
                                child: GestureDetector(
                                  onTapDown: (_) => _onBubbleTapped(bubble),
                                  child: _buildBubbleWidget(bubble, effectiveSize),
                                ),
                              );
                            }),

                            // Popped bubble animations
                            ..._bubbles.where((b) => b.isPopped).map((bubble) {
                              final effectiveSize = bubble.size * bubble.shrinkFactor;
                              return Positioned(
                                left: bubble.x * (areaWidth - effectiveSize),
                                top: bubble.y * (areaHeight - effectiveSize),
                                child: SizedBox(
                                  width: effectiveSize,
                                  height: effectiveSize,
                                  child: Center(
                                    child: TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 200),
                                      tween: Tween(begin: 1.0, end: 2.0),
                                      builder: (context, scale, child) {
                                        return Transform.scale(
                                          scale: scale,
                                          child: Opacity(
                                            opacity: (2.0 - scale).clamp(0.0, 1.0),
                                            child: Container(
                                              width: effectiveSize / 2,
                                              height: effectiveSize / 2,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: bubble.color,
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Score popups
                            ..._scorePopups.map((popup) => Positioned(
                              left: popup.x * areaWidth - 30,
                              top: popup.y * areaHeight + popup.offsetY - 20,
                              child: Opacity(
                                opacity: popup.opacity.clamp(0.0, 1.0),
                                child: Text(
                                  popup.text,
                                  style: TextStyle(
                                    color: popup.color,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),

                            // Combo indicator
                            if (_comboMultiplier > 1)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 200),
                                  tween: Tween(begin: 0.8, end: 1.0),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange.shade400,
                                              Colors.red.shade400,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.withOpacity(0.4),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '🔥 ${_comboMultiplier}× COMBO',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── Bottom Info ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _config.level >= 6
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _config.level >= 6
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _config.level >= 6 ? '⚠️' : '💡',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getHintText(),
                        style: TextStyle(
                          color: _config.level >= 6
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  String _getHintText() {
    if (_config.hasSkull && _config.hasBomb) {
      return 'Hindari 💀 tengkorak! Ketuk 💣 bom untuk pecahkan semua gelembung biasa sekaligus!';
    } else if (_config.hasSkull) {
      return 'Hindari 💀 tengkorak! Ketuk gelembung emas ✨ untuk bonus 3 pops!';
    } else if (_config.hasBomb) {
      return 'Ketuk 💣 bom untuk pecahkan semua gelembung biasa. Arah berubah tiap 2 detik!';
    } else if (_config.hasGolden) {
      return 'Gelembung emas ✨ bernilai 3 pops! Cepat ketuk beruntun untuk combo!';
    } else if (_config.hasShrinking) {
      return 'Gelembung menyusut seiring waktu! Cepat ketuk sebelum terlalu kecil!';
    } else {
      return 'Ketuk gelembung secepat mungkin! Cepat beruntun untuk combo multiplier!';
    }
  }

  // ─── HUD ──────────────────────────────────────────────────────────────────

  Widget _buildHUD(LevelConfig config) {
    final timerColor = _timeRemaining <= 10
        ? Colors.red
        : _timeRemaining <= 20
            ? Colors.orange
            : Colors.green;

    return Row(
      children: [
        // Level
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'LV ${config.level}',
                style: TextStyle(
                  color: Colors.indigo.shade700,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                config.description,
                style: TextStyle(
                  color: Colors.indigo.shade400,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: timerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: timerColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: timerColor),
              const SizedBox(width: 4),
              Text(
                '${_timeRemaining}s',
                style: TextStyle(
                  color: timerColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Pops counter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$_popsCount/${config.targetPops}',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '⭐ $_totalScore',
            style: TextStyle(
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bubble Widget ────────────────────────────────────────────────────────

  Widget _buildBubbleWidget(Bubble bubble, double effectiveSize) {
    String? emoji;
    List<Color> gradientColors;

    switch (bubble.type) {
      case BubbleType.golden:
        emoji = '✨';
        gradientColors = [
          Colors.white.withOpacity(0.9),
          Colors.amber.shade200.withOpacity(0.8),
          Colors.amber.shade400,
        ];
        break;
      case BubbleType.skull:
        emoji = '💀';
        gradientColors = [
          Colors.white.withOpacity(0.9),
          Colors.red.shade200.withOpacity(0.8),
          Colors.red.shade500,
        ];
        break;
      case BubbleType.bomb:
        emoji = '💣';
        gradientColors = [
          Colors.white.withOpacity(0.7),
          Colors.grey.shade500.withOpacity(0.8),
          Colors.grey.shade800,
        ];
        break;
      default:
        emoji = null;
        gradientColors = [
          Colors.white.withOpacity(0.9),
          bubble.color.withOpacity(0.8),
          bubble.color,
        ];
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: gradientColors,
          stops: const [0.1, 0.7, 1.0],
          center: const Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: bubble.color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: emoji != null
          ? Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: effectiveSize * 0.35),
              ),
            )
          : null,
    );
  }

  // ─── Game Over Screen ─────────────────────────────────────────────────────

  Widget _buildGameOverScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⏰', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const Text(
                'WAKTU HABIS!',
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
                'Level ${_config.level}: $_popsCount/${_config.targetPops} gelembung dipecahkan',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Skor saat ini: $_totalScore',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _retryLevel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Kembali ke Hub',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Level Complete Screen ────────────────────────────────────────────────

  Widget _buildLevelCompleteScreen() {
    final stars = _starRatings[_currentLevel];

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 70)),
              const SizedBox(height: 16),
              Text(
                'LEVEL ${_currentLevel + 1} SELESAI!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.cyanAccent,
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
                'Skor: $_totalScore  •  Kombo Max: $_maxCombo×',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentLevel < 7) {
                      setState(() {
                        _currentLevel++;
                      });
                      _startLevel();
                    } else {
                      setState(() {
                        _gameState = 'victory';
                      });
                      _saveResults();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _currentLevel < 7 ? 'LEVEL BERIKUTNYA' : 'LIHAT HASIL AKHIR',
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
                  'Pilih Level Lain',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
    Widget _buildMenu() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF0284C7)],
          ),
        ),
        child: SafeArea(
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
                        child: const Icon(Icons.arrow_back, color: Color(0xFF0369A1)),
                      ),
                    ),
                    Text('Pecah Gelembung 🫧', style: AppTheme.heading2.copyWith(color: const Color(0xFF0369A1), fontSize: 20)),
                    const SizedBox(width: 44),
                  ],
                ),
                const Spacer(),
                const Text('🫧', style: TextStyle(fontSize: 100)),
                const SizedBox(height: 24),
                Text('Pecah Gelembung', style: AppTheme.heading1.copyWith(color: const Color(0xFF0C4A6E), fontSize: 36), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text(
                  'Pecahkan gelembung secepat mungkin untuk menguji kecepatan reaksi dan koordinasi motorik halusmu!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF0C4A6E), fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
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
                      foregroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 6,
                    ),
                    child: const Text('🫧 PILIH LEVEL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelect() {
    const double itemHeight = 110.0;
    const double spacing = 40.0;
    const int totalLevels = 8;
    const double totalHeight = 150.0 + (totalLevels * (itemHeight + spacing));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF0284C7)],
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
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF0369A1)),
                      onPressed: () {
                        setState(() {
                          _gameState = 'menu';
                        });
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Pilih Level 🫧',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0C4A6E),
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
                    final double width = constraints.maxWidth;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: width,
                        height: totalHeight,
                        child: Stack(
                          children: [
                            // Static Undersea Background Bubbles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _BubbleBackgroundPainter(),
                              ),
                            ),
                            // Dashed trail of tiny bubbles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _BubblePathPainter(
                                  totalLevels: totalLevels,
                                  itemHeight: itemHeight,
                                  spacing: spacing,
                                  width: width,
                                ),
                              ),
                            ),
                            // Level Nodes
                            for (int i = 0; i < totalLevels; i++) ...[
                              Positioned(
                                left: (width / 2 + math.sin(i * 1.5) * 50.0) - 45,
                                top: 30.0 + i * (itemHeight + spacing),
                                child: SizedBox(
                                  width: 90,
                                  child: _buildBubbleLevelItem(i),
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

  Widget _buildBubbleLevelItem(int index) {
    final int levelNum = index + 1;
    final bool isUnlocked = levelNum <= _highestUnlocked;
    final int rating = _starRatings[index];

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final double floatOffset = math.sin((_floatController.value * 2 * math.pi) + index) * 6.0;
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isUnlocked
                ? () {
                    AudioService().playClick();
                    _currentLevel = index;
                    _startLevel();
                  }
                : () {
                    AudioService().playWrong();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Level ini masih terkunci! Selesaikan level sebelumnya.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUnlocked
                          ? const RadialGradient(
                              colors: [Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF0284C7)],
                              center: Alignment(-0.2, -0.2),
                              radius: 0.8,
                            )
                          : RadialGradient(
                              colors: [Colors.grey.shade200, Colors.grey.shade400, Colors.grey.shade600],
                              center: const Alignment(-0.2, -0.2),
                              radius: 0.8,
                            ),
                      border: Border.all(
                        color: isUnlocked ? Colors.white.withOpacity(0.8) : Colors.white24,
                        width: 2,
                      ),
                    ),
                  ),
                  if (isUnlocked)
                    Positioned(
                      top: 8,
                      left: 10,
                      child: Container(
                        width: 12,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: const BorderRadius.all(Radius.elliptical(6, 3)),
                        ),
                      ),
                    ),
                  Center(
                    child: isUnlocked
                        ? Text(
                            '$levelNum',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF075985),
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 3,
                                )
                              ],
                            ),
                          )
                        : const Icon(
                            Icons.lock_rounded,
                            color: Colors.white60,
                            size: 24,
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (starIdx) {
                final isStarred = starIdx < rating;
                return Icon(
                  Icons.star_rounded,
                  color: isStarred ? Colors.amber : Colors.white24,
                  size: 14,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalVictoryScreen() {
    final childName = context.read<AppState>().childProfile.name;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF0284C7)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆👑', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 24),
                Text(
                  'LUAR BIASA, $childName!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF0C4A6E),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kamu telah menyelesaikan seluruh level Pecah Gelembung!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF0C4A6E), fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Skor', style: TextStyle(color: Color(0xFF0C4A6E), fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('⭐ $_totalScore', style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gelembung Pecah', style: TextStyle(color: Color(0xFF0C4A6E), fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('🫧 $_totalPops', style: const TextStyle(color: Color(0xFF0C4A6E), fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Akurasi Reaksi', style: TextStyle(color: Color(0xFF0C4A6E), fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${((_totalPops / math.max(_totalPops + _skullPopsCount, 1)) * 100).round()}%', style: const TextStyle(color: Color(0xFF0C4A6E), fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _gameState = 'menu';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'MAIN LAGI',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    child: const Text(
                      'KEMBALI KE HUB',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), 35, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.35), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.6), 45, paint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.8), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), 55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BubblePathPainter extends CustomPainter {
  final int totalLevels;
  final double itemHeight;
  final double spacing;
  final double width;

  _BubblePathPainter({
    required this.totalLevels,
    required this.itemHeight,
    required this.spacing,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 1; i < totalLevels; i++) {
      double prevY = 30.0 + (itemHeight / 2) + (i - 1) * (itemHeight + spacing);
      double nextY = 30.0 + (itemHeight / 2) + i * (itemHeight + spacing);
      
      for (int t = 1; t <= 8; t++) {
        double ratio = t / 9.0;
        double currY = prevY + (nextY - prevY) * ratio;
        double currX = width / 2 + math.sin(((i - 1) + ratio) * 1.5) * 50.0;
        
        canvas.drawCircle(
          Offset(currX, currY), 
          3.0 + math.sin(t * 1.0) * 1.2, 
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
