import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import '../services/assessment_engine.dart';

class ShapeProblem {
  final int id;
  final String shape;
  final String color;
  final String size;
  final String pattern;
  final String category;
  final String correctBucket;
  final int level;
  final String instruction;

  ShapeProblem({
    required this.id,
    required this.shape,
    required this.color,
    required this.size,
    required this.pattern,
    required this.category,
    required this.correctBucket,
    required this.level,
    required this.instruction,
  });
}

class ShapeSortingGame extends StatefulWidget {
  const ShapeSortingGame({super.key});

  @override
  State<ShapeSortingGame> createState() => _ShapeSortingGameState();
}

class _ShapeSortingGameState extends State<ShapeSortingGame> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, game_over, completed
  int _currentLevel = 1;
  int _score = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _timeLeft = 45;
  int _levelCorrectAnswers = 0;
  
  ShapeProblem? _currentShape;
  DateTime? _startTime;
  int _totalQuestions = 0;
  List<Map<String, dynamic>> _gameSessionData = [];
  String? _feedback; // 'correct', 'wrong', null
  int _streak = 0;
  
  Timer? _timer;
  final Random _random = Random();

  late AnimationController _bgAnimCtrl;
  int _highestUnlocked = 1;
  final List<int> _starRatings = List.filled(8, 0);

  @override
  void initState() {
    super.initState();
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgAnimCtrl.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  ShapeProblem _generateShapeProblem(int level) {
    List<Function> problemTypes = [
      // Level 1: Sort by shape
      () {
        int shapeIndex = _random.nextInt(4);
        List<String> shapes = ['⚫', '⬛', '🔺', '⭐'];
        List<String> shapeNames = ['Lingkaran', 'Persegi', 'Segitiga', 'Bintang'];
        return {
          'shape': shapes[shapeIndex],
          'correctBucket': shapeNames[shapeIndex],
          'category': 'shape',
          'instruction': 'Pilih bentuk yang sama!'
        };
      },
      // Level 2: Sort by color
      () {
        int colorIndex = _random.nextInt(4);
        List<String> colors = ['🔴', '🔵', '🟡', '🟢'];
        List<String> colorNames = ['Merah', 'Biru', 'Kuning', 'Hijau'];
        return {
          'shape': colors[colorIndex],
          'correctBucket': colorNames[colorIndex],
          'category': 'color',
          'instruction': 'Pilih warna yang sama!'
        };
      },
      // Level 3: Sort by size
      () {
        List<String> sizeEmojis = ['🔹', '🔶', '🔷'];
        List<String> sizeNames = ['Kecil', 'Sedang', 'Besar'];
        int sizeIndex = _random.nextInt(3);
        return {
          'shape': sizeEmojis[sizeIndex],
          'correctBucket': sizeNames[sizeIndex],
          'category': 'size',
          'instruction': 'Pilih ukuran yang sama!'
        };
      },
      // Level 4: Complex patterns
      () {
        List<Map<String, String>> patterns = [
          {'shape': '🔴🔴', 'bucket': 'Dua Sama'},
          {'shape': '🔵🟡', 'bucket': 'Beda Warna'},
          {'shape': '⭐⭐⭐', 'bucket': 'Tiga Sama'}
        ];
        var pattern = patterns[_random.nextInt(patterns.length)];
        return {
          'shape': pattern['shape']!,
          'correctBucket': pattern['bucket']!,
          'category': 'pattern',
          'instruction': 'Pilih pola yang sesuai!'
        };
      },
      // Level 5: Shape + Color combination
      () {
        List<Map<String, String>> shapeColors = [
          {'shape': '🔴⚫', 'bucket': 'Merah Lingkaran'},
          {'shape': '🔵⬛', 'bucket': 'Biru Persegi'},
          {'shape': '🟡🔺', 'bucket': 'Kuning Segitiga'}
        ];
        var sc = shapeColors[_random.nextInt(shapeColors.length)];
        return {
          'shape': sc['shape']!,
          'correctBucket': sc['bucket']!,
          'category': 'shape_color',
          'instruction': 'Pilih kombinasi bentuk & warna!'
        };
      },
      // Level 6: Counting / quantity sorting
      () {
        List<Map<String, String>> counts = [
          {'shape': '⭐', 'bucket': 'Satu'},
          {'shape': '⭐⭐', 'bucket': 'Dua'},
          {'shape': '⭐⭐⭐', 'bucket': 'Tiga'}
        ];
        var c = counts[_random.nextInt(counts.length)];
        return {
          'shape': c['shape']!,
          'correctBucket': c['bucket']!,
          'category': 'counting',
          'instruction': 'Hitung jumlah objek!'
        };
      },
      // Level 7: Directions
      () {
        List<Map<String, String>> directions = [
          {'shape': '⬆️', 'bucket': 'Atas'},
          {'shape': '⬇️', 'bucket': 'Bawah'},
          {'shape': '⬅️', 'bucket': 'Kiri'},
          {'shape': '➡️', 'bucket': 'Kanan'}
        ];
        var d = directions[_random.nextInt(directions.length)];
        return {
          'shape': d['shape']!,
          'correctBucket': d['bucket']!,
          'category': 'direction',
          'instruction': 'Pilih arah panah!'
        };
      },
      // Level 8: Mixed Advanced
      () {
        List<Map<String, String>> mixed = [
          {'shape': '⬛⬆️', 'bucket': 'Persegi Atas'},
          {'shape': '⚫➡️', 'bucket': 'Lingkaran Kanan'},
          {'shape': '🔺⬇️', 'bucket': 'Segitiga Bawah'}
        ];
        var m = mixed[_random.nextInt(mixed.length)];
        return {
          'shape': m['shape']!,
          'correctBucket': m['bucket']!,
          'category': 'mixed',
          'instruction': 'Pilih bentuk dan arah yang tepat!'
        };
      }
    ];

    int problemLevel = min(level, problemTypes.length);
    Map<String, dynamic> problemData = problemTypes[problemLevel - 1]();

    return ShapeProblem(
      id: DateTime.now().millisecondsSinceEpoch,
      shape: problemData['shape'],
      color: '',
      size: 'medium',
      pattern: 'solid',
      category: problemData['category'],
      correctBucket: problemData['correctBucket'],
      level: level,
      instruction: problemData['instruction']
    );
  }



  void _startLevel(int level) {
    setState(() {
      _gameState = 'playing';
      _currentLevel = level;
      _score = 0;
      _correctAnswers = 0;
      _levelCorrectAnswers = 0;
      _wrongAnswers = 0;
      _timeLeft = 45;
      _startTime = DateTime.now();
      _totalQuestions = 0;
      _gameSessionData = [];
      _feedback = null;
      _streak = 0;
    });
    AudioService().playBGM('puzzle_music.mp3');
    _generateNewProblem();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_gameState == 'playing') {
        if (_timeLeft > 0) {
          setState(() => _timeLeft--);
        } else {
          _timer?.cancel();
          setState(() {
            _gameState = 'game_over';
          });
        }
      }
    });
  }

  void _generateNewProblem() {
    setState(() {
      _currentShape = _generateShapeProblem(_currentLevel);
      _totalQuestions++;
      _feedback = null;
    });
  }

  void _handleBucketClick(String bucketName) {
    if (_currentShape == null || _feedback != null) return;
    AudioService().playSFX('flip.mp3');

    bool isCorrect = bucketName == _currentShape!.correctBucket;

    setState(() {
      if (isCorrect) {
        _feedback = 'correct';
        _score += (10 * _currentLevel) + (_streak * 2);
        _correctAnswers++;
        _levelCorrectAnswers++;
        _streak++;
        AudioService().playSFX('success.mp3');
        context.read<AppState>().addSticker('shape-sorter');
      } else {
        _feedback = 'wrong';
        _wrongAnswers++;
        _streak = 0;
        _timeLeft = max(0, _timeLeft - 3);
        AudioService().playSFX('wrong.mp3');
      }

      _gameSessionData.add({
        'problem': _currentShape!.shape,
        'correctAnswer': _currentShape!.correctBucket,
        'selectedAnswer': bucketName,
        'isCorrect': isCorrect,
        'category': _currentShape!.category,
        'timeSpent': DateTime.now().difference(_startTime!).inMilliseconds,
        'level': _currentLevel
      });
    });

    if (isCorrect && _levelCorrectAnswers >= 5) {
      _timer?.cancel();
      int stars = 1;
      if (_timeLeft >= 22) stars = 3;
      else if (_timeLeft >= 9) stars = 2;

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
        if (_gameState == 'playing') {
          setState(() => _feedback = null);
          _generateNewProblem();
        }
      });
    }
  }

  void _endGame() {
    _timer?.cancel();
    
    int totalTime = DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    int accuracy = _totalQuestions > 0 ? ((_correctAnswers / _totalQuestions) * 100).round() : 0;

    context.read<AppState>().updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': _totalQuestions,
      'percentage': accuracy,
      'timeSpent': totalTime,
      'gameMode': 'Shape Sorting Premium',
      'level': _currentLevel,
      'categoryScores': {
        'abstraction': ((accuracy / 100) * 35).round(),
        'pattern': ((_correctAnswers / max(_totalQuestions, 1)) * 35).round(),
        'spatial': ((_currentLevel / 8) * 30).round()
      }
    });

    final int avgRespMs = _totalQuestions > 0 ? ((totalTime * 1000) / _totalQuestions).round() : 0;
    
    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: _totalQuestions,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 12000, 
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _wrongAnswers,
    );

    context.read<AppState>().updateGameAssessment('shapeSortingGame', GameSession(
      score: _score, 
      timeSpent: totalTime, 
      errors: _wrongAnswers,
      totalItems: _totalQuestions,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      subdomainScores: {
        'processingSpeed': assessScore,
      },
    ));
    context.read<AppState>().addPointsFromScore(_score);

    if (accuracy >= 90) context.read<AppState>().addSticker('sorting-master');
    if (_correctAnswers >= 15) context.read<AppState>().addSticker('pattern-expert');
    context.read<AppState>().addSticker('shape-champion');

    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');
    setState(() => _gameState = 'completed');
  }

  List<String> _getBuckets() {
    switch (_currentLevel) {
      case 1:
        return ['Lingkaran', 'Persegi', 'Segitiga', 'Bintang'];
      case 2:
        return ['Merah', 'Biru', 'Kuning', 'Hijau'];
      case 3:
        return ['Kecil', 'Sedang', 'Besar'];
      case 4:
        return ['Dua Sama', 'Beda Warna', 'Tiga Sama'];
      case 5:
        return ['Merah Lingkaran', 'Biru Persegi', 'Kuning Segitiga'];
      case 6:
        return ['Satu', 'Dua', 'Tiga'];
      case 7:
        return ['Atas', 'Bawah', 'Kiri', 'Kanan'];
      case 8:
        return ['Persegi Atas', 'Lingkaran Kanan', 'Segitiga Bawah'];
      default:
        return ['Lingkaran', 'Persegi', 'Segitiga', 'Bintang'];
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
        return _buildPlaying();
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
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8), Color(0xFFFDA4AF)]
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -50, right: -50, child: Opacity(opacity: 0.15, child: Icon(Icons.palette_rounded, size: 300, color: Colors.purple.shade300))),
            Positioned(bottom: 20, left: 10, child: Opacity(opacity: 0.2, child: const Text('🎨', style: TextStyle(fontSize: 100)))),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildGlassButton(Icons.arrow_back, () => Navigator.pop(context)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
                      ),
                      child: Column(
                        children: [
                          const Text('🎨', style: TextStyle(fontSize: 100)),
                          const SizedBox(height: 16),
                          Text(
                            'PILAH\nBENTUK',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.purple.shade900, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4, fontFamily: 'Nunito'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sortir bentuk berdasarkan pola!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.purple.shade700, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    _buildPremiumButton('MULAI BERMAIN 🎨', () {
                      setState(() {
                        _gameState = 'level_select';
                      });
                    }),
                  ],
                ),
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
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Icon(icon, color: Colors.purple.shade900),
      ),
    );
  }

  Widget _buildPremiumButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC084FC), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC084FC).withOpacity(0.4),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8), Color(0xFFFDA4AF)],
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
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF701A75)),
                      onPressed: () {
                        setState(() {
                          _gameState = 'menu';
                        });
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Pilih Level 🎨',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF701A75),
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      return _buildShapeLevelItem(index);
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

  Widget _buildShapeLevelItem(int index) {
    final int levelNum = index + 1;
    final bool isUnlocked = levelNum <= _highestUnlocked;
    final int rating = _starRatings[index];

    final List<List<Color>> shapeGradients = [
      [const Color(0xFFF87171), const Color(0xFFEF4444)],
      [const Color(0xFFFB923C), const Color(0xFFF97316)],
      [const Color(0xFFFBBF24), const Color(0xFFD97706)],
      [const Color(0xFF34D399), const Color(0xFF059669)],
      [const Color(0xFF22D3EE), const Color(0xFF0891B2)],
      [const Color(0xFF60A5FA), const Color(0xFF2563EB)],
      [const Color(0xFFC084FC), const Color(0xFF9333EA)],
      [const Color(0xFFF472B6), const Color(0xFFDB2777)],
    ];

    return GestureDetector(
      onTap: isUnlocked
          ? () {
              AudioService().playClick();
              _startLevel(levelNum);
            }
          : () {
              AudioService().playWrong();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selesaikan level sebelumnya untuk membuka galeri seni ini!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFFFFFDF9) : const Color(0xFFF1F5F9), // Cozy cream vs slate grey
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? const Color(0xFFD97706).withOpacity(0.6) : const Color(0xFFCBD5E1), // Wood trim border
            width: 3.5,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFF78350F).withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 65,
              height: 65,
              child: Stack(
                children: [
                  if (isUnlocked)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ShapeOutlinePainter(
                          levelNum,
                          shapeGradients[index][0].withOpacity(0.4),
                          isGlow: true,
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _ShapeClipper(levelNum),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isUnlocked
                              ? LinearGradient(
                                  colors: shapeGradients[index],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
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
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      )
                                    ],
                                  ),
                                )
                              : const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white60,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF701A75).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (starIdx) {
                  final isStarred = starIdx < rating;
                  return Icon(
                    Icons.star_rounded,
                    color: isStarred ? Colors.amber : Colors.black12,
                    size: 11,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    if (_currentShape == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    List<String> buckets = _getBuckets();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9D5FF), Color(0xFFFBCFE8), Color(0xFFFDA4AF)])
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
                      onTap: () => setState(() => _gameState = 'level_select'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    Column(
                      children: [
                        Text('Pilah Bentuk', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 18)),
                        Text('Level $_currentLevel  •  $_levelCorrectAnswers/5', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                        children: [
                          const Icon(Icons.access_time, color: Color(0xFFFBCFE8), size: 20),
                          const SizedBox(width: 8),
                          Text('${_timeLeft}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFDE047), size: 20),
                          const SizedBox(width: 8),
                          Text('$_correctAnswers / $_totalQuestions', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      if (_streak > 2)
                        Row(
                          children: [
                            Text('🔥 $_streak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        )
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
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              children: [
                                Text(_currentShape!.instruction, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                                const SizedBox(height: 24),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  transform: _feedback != null ? Matrix4.rotationZ(pi * 2) : Matrix4.identity(),
                                  transformAlignment: Alignment.center,
                                  child: Text(_currentShape!.shape, style: const TextStyle(fontSize: 80)),
                                )
                              ],
                            ),
                            
                            if (_feedback != null)
                              Positioned(
                                top: -32, left: -32, right: -32,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: _feedback == 'correct' ? const Color(0xFF22C55E) : const Color(0xFFEF4444), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                                  child: Text(_feedback == 'correct' ? '✨ Benar!' : '❌ Salah!', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 20), textAlign: TextAlign.center),
                                ),
                              )
                          ],
                        ),
                      ),

                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: buckets.map((bucket) {
                            bool isCorrectBucket = _currentShape!.correctBucket == bucket;
                            bool isHighlighted = _feedback != null && isCorrectBucket;
                            
                            return ElevatedButton(
                              onPressed: _feedback == null ? () => _handleBucketClick(bucket) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isHighlighted ? const Color(0xFF22C55E) : Colors.white,
                                elevation: 8,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                disabledBackgroundColor: isHighlighted ? const Color(0xFF22C55E) : Colors.white,
                              ),
                              child: Text(bucket, style: TextStyle(color: isHighlighted ? Colors.white : const Color(0xFF9333EA), fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                            );
                          }).toList(),
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

  Widget _buildLevelCompleteScreen() {
    final stars = _starRatings[_currentLevel - 1];

    return Scaffold(
      backgroundColor: const Color(0xFF1E152A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 70)),
              const SizedBox(height: 16),
              Text(
                'LEVEL $_currentLevel SELESAI!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD8B4FE),
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
                'Skor: $_score  •  Akurasi: ${(_totalQuestions > 0 ? (_correctAnswers / _totalQuestions * 100).round() : 0)}%',
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
                    backgroundColor: const Color(0xFFDB2777),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    _currentLevel < 8 ? 'LEVEL BERIKUTNYA' : 'LIHAT HASIL AKHIR',
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

  Widget _buildGameOverScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E152A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⏰💥', style: TextStyle(fontSize: 80)),
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
                'Kamu kehabisan waktu di Level $_currentLevel',
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
                    backgroundColor: const Color(0xFF9333EA),
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

  Widget _buildCompleted() {
    int accuracy = _totalQuestions > 0 ? ((_correctAnswers / _totalQuestions) * 100).round() : 0;
    String childName = context.read<AppState>().childProfile.name;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD8B4FE), Color(0xFFF9A8D4), Color(0xFFFB7185)])
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
                  Text('$childName, kamu pandai dalam menyortir bentuk!', style: const TextStyle(color: Color(0xFFFCE7F3), fontSize: 18), textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  _buildResultStatRow('Skor Total', '$_score'),
                  const SizedBox(height: 16),
                  _buildResultStatRow('Akurasi', '$accuracy%'),
                  const SizedBox(height: 16),
                  _buildResultStatRow('Level Terakhir', '$_currentLevel'),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _gameState = 'menu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Main Lagi', style: TextStyle(color: Color(0xFFDB2777), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white, width: 2)),
                      ),
                      child: const Text('Pilih Game Lain', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ShapeOutlinePainter extends CustomPainter {
  final int levelNum;
  final Color color;
  final bool isGlow;

  _ShapeOutlinePainter(this.levelNum, this.color, {this.isGlow = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isGlow ? 4.0 : 1.5;

    if (isGlow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    }

    final path = _getPathForShape(levelNum, size);
    canvas.drawPath(path, paint);
  }

  Path _getPathForShape(int level, Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    switch (level) {
      case 1:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;
      case 2:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;
      case 3:
        path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)));
        break;
      case 4:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.38);
        path.lineTo(w * 0.82, h);
        path.lineTo(w * 0.18, h);
        path.lineTo(0, h * 0.38);
        path.close();
        break;
      case 5:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.25);
        path.lineTo(w, h * 0.75);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.75);
        path.lineTo(0, h * 0.25);
        path.close();
        break;
      case 6:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w * 0.63, h * 0.38);
        path.lineTo(w, h * 0.38);
        path.lineTo(w * 0.7, h * 0.62);
        path.lineTo(w * 0.81, h);
        path.lineTo(w * 0.5, h * 0.76);
        path.lineTo(w * 0.19, h);
        path.lineTo(w * 0.3, h * 0.62);
        path.lineTo(0, h * 0.38);
        path.lineTo(w * 0.37, h * 0.38);
        path.close();
        break;
      case 7:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.5);
        path.close();
        break;
      case 8:
      default:
        path.moveTo(w * 0.5, h * 0.25);
        path.cubicTo(w * 0.2, h * -0.1, w * -0.1, h * 0.4, w * 0.5, h * 0.95);
        path.cubicTo(w * 1.1, h * 0.4, w * 0.8, h * -0.1, w * 0.5, h * 0.25);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShapeClipper extends CustomClipper<Path> {
  final int levelNum;

  _ShapeClipper(this.levelNum);

  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    switch (levelNum) {
      case 1:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;
      case 2:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;
      case 3:
        path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)));
        break;
      case 4:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.38);
        path.lineTo(w * 0.82, h);
        path.lineTo(w * 0.18, h);
        path.lineTo(0, h * 0.38);
        path.close();
        break;
      case 5:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.25);
        path.lineTo(w, h * 0.75);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.75);
        path.lineTo(0, h * 0.25);
        path.close();
        break;
      case 6:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w * 0.63, h * 0.38);
        path.lineTo(w, h * 0.38);
        path.lineTo(w * 0.7, h * 0.62);
        path.lineTo(w * 0.81, h);
        path.lineTo(w * 0.5, h * 0.76);
        path.lineTo(w * 0.19, h);
        path.lineTo(w * 0.3, h * 0.62);
        path.lineTo(0, h * 0.38);
        path.lineTo(w * 0.37, h * 0.38);
        path.close();
        break;
      case 7:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.5);
        path.close();
        break;
      case 8:
      default:
        path.moveTo(w * 0.5, h * 0.25);
        path.cubicTo(w * 0.2, h * -0.1, w * -0.1, h * 0.4, w * 0.5, h * 0.95);
        path.cubicTo(w * 1.1, h * 0.4, w * 0.8, h * -0.1, w * 0.5, h * 0.25);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
