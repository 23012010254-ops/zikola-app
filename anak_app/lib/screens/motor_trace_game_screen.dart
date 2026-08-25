import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class MotorTraceGameScreen extends StatefulWidget {
  const MotorTraceGameScreen({super.key});

  @override
  State<MotorTraceGameScreen> createState() => _MotorTraceGameScreenState();
}

class _MotorTraceGameScreenState extends State<MotorTraceGameScreen> with TickerProviderStateMixin {
  int _currentLevel = 0;
  int _driftErrors = 0;
  String _gamePhase = 'intro'; // intro, level_select, playing, level_complete, results
  DateTime? _levelStartTime;
  
  int _totalTimeMs = 0;
  int _levelElapsedTimeMs = 0;
  
  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  // Tracing State
  Offset? _currentPos;
  bool _isDragging = false;
  List<Offset> _drawnPath = [];

  // Constellation Names per level
  final List<String> _constellationNames = [
    'Rasi Bimasakti',
    'Sabuk Komet',
    'Lintasan Nebula',
    'Sabuk Asteroid',
    'Tangga Antariksa',
    'Bintang Kejora',
    'Inti Supernova',
    'Pusaran Kosmik',
  ];

  // Path configs per level (will be normalized to screen size during build)
  final List<List<Offset>> _pathBlueprints = [
    [const Offset(0.1, 0.5), const Offset(0.9, 0.5)], // Level 1: Garis Lurus (Mudah)
    [const Offset(0.1, 0.2), const Offset(0.5, 0.8), const Offset(0.9, 0.2)], // Level 2: Bentuk V
    [const Offset(0.1, 0.5), const Offset(0.3, 0.2), const Offset(0.7, 0.8), const Offset(0.9, 0.5)], // Level 3: ZigZag
    [const Offset(0.1, 0.8), const Offset(0.2, 0.2), const Offset(0.5, 0.5), const Offset(0.8, 0.2), const Offset(0.9, 0.8)], // Level 4: Huruf M
    [const Offset(0.1, 0.2), const Offset(0.5, 0.2), const Offset(0.5, 0.8), const Offset(0.9, 0.8)], // Level 5: Tangga Sudut
    [const Offset(0.5, 0.1), const Offset(0.8, 0.9), const Offset(0.1, 0.4), const Offset(0.9, 0.4), const Offset(0.2, 0.9), const Offset(0.5, 0.1)], // Level 6: Bintang Pentagon
    [const Offset(0.5, 0.2), const Offset(0.8, 0.5), const Offset(0.5, 0.8), const Offset(0.2, 0.5), const Offset(0.5, 0.2)], // Level 7: Berlian
    [const Offset(0.1, 0.9), const Offset(0.2, 0.1), const Offset(0.4, 0.9), const Offset(0.6, 0.1), const Offset(0.8, 0.9), const Offset(0.9, 0.1)], // Level 8: Zigzag Super Rapat
  ];

  late AnimationController _pulseAnimCtrl;

  @override
  void initState() {
    super.initState();
    _pulseAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnimCtrl.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  void _startLevel(int levelIndex) {
    setState(() {
      _gamePhase = 'playing';
      _currentLevel = levelIndex;
      _driftErrors = 0;
      _resetLevelState();
    });
    AudioService().playGameBGM();
  }

  void _resetLevelState() {
    _isDragging = false;
    _currentPos = null;
    _drawnPath = [];
    _levelStartTime = DateTime.now();
  }

  List<Offset> _getScreenPath(Size size) {
    if (_currentLevel >= _pathBlueprints.length) return [];
    final blueprint = _pathBlueprints[_currentLevel];
    // Scale blueprint (0.0 to 1.0) into actual screen coordinates
    // We add some vertical padding
    final drawingHeight = size.height * 0.6;
    final topOffset = size.height * 0.2;
    
    return blueprint.map((p) => Offset(p.dx * size.width, (p.dy * drawingHeight) + topOffset)).toList();
  }

  // Calculate distance from point P to line segment AB
  double _distanceToSegment(Offset p, Offset a, Offset b) {
    var l2 = (a.dx - b.dx) * (a.dx - b.dx) + (a.dy - b.dy) * (a.dy - b.dy);
    if (l2 == 0) return (p - a).distance;
    var t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = max(0, min(1, t));
    return (p - Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy))).distance;
  }

  void _onPanStart(DragStartDetails details, Size size) {
    if (_gamePhase != 'playing') return;
    final path = _getScreenPath(size);
    if (path.isEmpty) return;

    // Check if start is near the first point
    final startPoint = path.first;
    if ((details.localPosition - startPoint).distance < 60) {
      setState(() {
        _isDragging = true;
        _currentPos = details.localPosition;
        _drawnPath = [_currentPos!];
      });
      AudioService().playClick();
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (!_isDragging) return;

    final path = _getScreenPath(size);
    final pos = details.localPosition;

    // Check for drift (is the finger too far from ANY line segment?)
    bool fellOff = true;
    for (int i = 0; i < path.length - 1; i++) {
      if (_distanceToSegment(pos, path[i], path[i+1]) < 50.0) { // Allowed 50px drift
        fellOff = false;
        break;
      }
    }

    if (fellOff) {
      AudioService().playWrong();
      setState(() {
        _driftErrors++;
        _resetLevelState(); // Must restart from the beginning of the level
      });
      return;
    }

    setState(() {
      _currentPos = pos;
      _drawnPath.add(pos);
    });

    // Check if reached the end target
    final endPoint = path.last;
    if ((pos - endPoint).distance < 40) {
      _onLevelComplete();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDragging) {
      // Lifted finger too early
      AudioService().playWrong();
      setState(() {
        _driftErrors++;
        _resetLevelState();
      });
    }
  }

  void _onLevelComplete() {
    AudioService().playCorrect();
    final elapsed = DateTime.now().difference(_levelStartTime!).inMilliseconds;
    _totalTimeMs += elapsed;
    _levelElapsedTimeMs = elapsed;

    int levelStars = 1;
    if (_driftErrors <= 1) {
      levelStars = 3;
    } else if (_driftErrors <= 3) {
      levelStars = 2;
    }

    if (levelStars > _starRatings[_currentLevel]) {
      _starRatings[_currentLevel] = levelStars;
    }

    if (_currentLevel + 1 == _highestUnlocked && _currentLevel + 1 < _pathBlueprints.length) {
      _highestUnlocked = _currentLevel + 2;
    }

    final percentage = (100 - (_driftErrors * 10)).clamp(0, 100);

    final appState = context.read<AppState>();
    appState.updateTestResults('motor', {
      'score': _currentLevel + 1,
      'total': _pathBlueprints.length,
      'driftErrors': _driftErrors,
      'timeSpent': elapsed ~/ 1000,
      'percentage': percentage,
    });

    appState.updateGameAssessment('motor', GameSession(
      score: (_currentLevel + 1) * 12,
      timeSpent: elapsed ~/ 1000,
      errors: _driftErrors,
      correctAnswers: _currentLevel + 1,
      totalItems: _pathBlueprints.length,
      avgResponseTimeMs: elapsed,
      fastestResponseTimeMs: 0,
      slowestResponseTimeMs: 0,
      medianResponseTimeMs: 0,
      itemsPerMinute: elapsed > 0 ? (1 / (elapsed / 60000)) : 0.0,
      maxLevelReached: _currentLevel + 1,
    ));
    
    appState.addPointsFromScore(percentage);

    if (percentage >= 80) {
      appState.addSticker('motor-master');
    } else if (percentage >= 50) {
      appState.addSticker('motor-star');
    }

    setState(() {
      _isDragging = false;
      _gamePhase = 'level_complete';
    });
  }



  @override
  Widget build(BuildContext context) {
    switch (_gamePhase) {
      case 'level_select':
        return _buildLevelSelectScreen();
      case 'playing':
        return _buildPlayingScreen();
      case 'level_complete':
        return _buildLevelCompleteScreen();
      case 'results':
        return _buildResultsScreen();
      case 'intro':
      default:
        return _buildIntroScreen();
    }
  }

  Widget _buildIntroScreen() {
     return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF), // violet-50
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 30, spreadRadius: 10)]
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 80)),
                ),
                const SizedBox(height: 48),
                Text('Galaksi Garis', style: AppTheme.heading1.copyWith(color: AppTheme.purple600, fontSize: 32)),
                const SizedBox(height: 16),
                Text(
                  'Tarik jarimu dari bintang awal hingga ke bintang akhir. Awas, jangan sampai terputus atau keluar jalur!',
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
                      const Icon(Icons.gesture, color: Color(0xFF9333EA)),
                      const SizedBox(width: 8),
                      Text('Latih Kestabilan Tanganmu', style: TextStyle(color: AppTheme.purple600, fontWeight: FontWeight.bold)),
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
                      backgroundColor: AppTheme.purple500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: AppTheme.purple500.withOpacity(0.5),
                    ),
                    child: const Text('Mulai Terbang!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
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
    final String currentConstellation = _currentLevel < _constellationNames.length 
        ? _constellationNames[_currentLevel] 
        : 'Rasi Bintang';
        
    return Scaffold(
      backgroundColor: const Color(0xFF090D1A), // deep space dark blue/black
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats Wood/Space HUD Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.purpleAccent, size: 18),
                        onPressed: () {
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
                          Text('RASI ${_currentLevel + 1}/${_pathBlueprints.length}', style: TextStyle(color: Colors.purpleAccent.shade100, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Text(currentConstellation, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pinkAccent.withOpacity(0.4), width: 1.5),
                    ),
                    child: Text(
                      'Keluar Jalur: $_driftErrors', 
                      style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  final pathPoints = _getScreenPath(size);

                  return GestureDetector(
                    onPanStart: (details) => _onPanStart(details, size),
                    onPanUpdate: (details) => _onPanUpdate(details, size),
                    onPanEnd: _onPanEnd,
                    child: Container(
                      color: Colors.transparent, // To catch gestures
                      width: double.infinity,
                      height: double.infinity,
                      child: Stack(
                        children: [
                          // Draw the glowing track blueprint & background stars
                          CustomPaint(
                            size: size,
                            painter: _TrackPainter(pathPoints, _drawnPath),
                          ),
                          
                          // Draw Start Point Rocket node
                          if (pathPoints.isNotEmpty)
                            Positioned(
                              left: pathPoints.first.dx - 27.5,
                              top: pathPoints.first.dy - 27.5,
                              child: _buildConstellationNode(color: Colors.cyanAccent, icon: '🚀'),
                            ),
                            
                          // Draw End Point Pulsing star node
                          if (pathPoints.isNotEmpty)
                            Positioned(
                              left: pathPoints.last.dx - 27.5,
                              top: pathPoints.last.dy - 27.5,
                              child: _buildConstellationNode(color: Colors.amberAccent, icon: '🌟', isPulsing: true),
                            ),

                          // Draw Player's current position glowing pointer
                          if (_isDragging && _currentPos != null)
                            Positioned(
                              left: _currentPos!.dx - 18,
                              top: _currentPos!.dy - 18,
                              child: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 4),
                                    BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 6),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConstellationNode({required Color color, required String icon, bool isPulsing = false}) {
    final nodeWidget = Container(
      width: 55, height: 55,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4), 
            blurRadius: isPulsing ? 18 : 10,
            spreadRadius: isPulsing ? 2 : 0,
          )
        ],
      ),
      alignment: Alignment.center,
      child: Text(icon, style: const TextStyle(fontSize: 26)),
    );

    if (isPulsing) {
      return AnimatedBuilder(
        animation: _pulseAnimCtrl,
        builder: (context, child) {
          final scale = 1.0 + (_pulseAnimCtrl.value * 0.12);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: nodeWidget,
      );
    }
    return nodeWidget;
  }

  Widget _buildLevelCompleteScreen() {
    final String name = _currentLevel < _constellationNames.length 
        ? _constellationNames[_currentLevel] 
        : 'Rasi Bintang';
        
    int starsCount = 1;
    if (_driftErrors <= 1) {
      starsCount = 3;
    } else if (_driftErrors <= 3) {
      starsCount = 2;
    }
    
    final elapsedSecs = _levelElapsedTimeMs ~/ 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF090514)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.purpleAccent, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RASI TERHUBUNG! 🌌',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: Colors.cyan, blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 24),
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Keluar Jalur:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$_driftErrors Kali', style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Waktu Terbang:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${elapsedSecs}s', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 18)),
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
                    if (_currentLevel + 1 >= _pathBlueprints.length) {
                      setState(() {
                        _gamePhase = 'level_select';
                      });
                    } else {
                      _startLevel(_currentLevel + 1);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                  ),
                  child: Text(
                    _currentLevel + 1 >= _pathBlueprints.length 
                        ? 'Kembali ke Pemilihan Level 🗺' 
                        : 'Rasi Berikutnya 🚀',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _startLevel(_currentLevel);
                },
                child: const Text('Main Ulang Rasi Ini 🔄', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  setState(() {
                    _gamePhase = 'level_select';
                  });
                },
                child: const Text('Kembali ke Peta Rasi 🗺️', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelectScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF090D1A), Color(0xFF1E1B4B), Color(0xFF090514)],
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
                          'Peta Rasi Bintang 🌌',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            shadows: [
                              Shadow(color: Colors.purpleAccent, blurRadius: 10),
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
                    itemCount: _pathBlueprints.length,
                    itemBuilder: (context, index) {
                      final int levelNum = index + 1;
                      final bool isUnlocked = levelNum <= _highestUnlocked;
                      final int rating = _starRatings[index];
                      
                      return GestureDetector(
                        onTap: isUnlocked ? () => _startLevel(index) : null,
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  gradient: isUnlocked
                                      ? const LinearGradient(
                                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isUnlocked ? Colors.purpleAccent : Colors.grey.shade800,
                                    width: 3,
                                  ),
                                  boxShadow: isUnlocked
                                      ? [
                                          BoxShadow(
                                            color: Colors.purpleAccent.withOpacity(0.3),
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
                                              Shadow(color: Colors.purple, blurRadius: 4, offset: Offset(1, 1))
                                            ],
                                          ),
                                        )
                                      : const Icon(Icons.lock_rounded, color: Colors.white24, size: 28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
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

  Widget _buildResultsScreen() {
    int percentage = (100 - (_driftErrors * 10)).clamp(0, 100);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF090514)],
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
                    animation: _pulseAnimCtrl,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseAnimCtrl.value * 0.05),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.purpleAccent, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.purpleAccent.withOpacity(0.3), blurRadius: 20),
                            ],
                          ),
                          child: Text(percentage >= 60 ? '🏆' : '👍', style: const TextStyle(fontSize: 80)),
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 32),
                  const Text('Rasi Bintang Selesai!', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  const Text(
                    'Luar Biasa! Kamu berhasil menghubungkan seluruh rasi bintang.', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Space HUD Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.4), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kestabilan Tangan:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 16)),
                            Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.cyanAccent, fontSize: 22)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Keluar Lintasan:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 16)),
                            Text('$_driftErrors kali', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.pinkAccent, fontSize: 22)),
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Waktu:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 16)),
                            Text('${_totalTimeMs ~/ 1000} detik', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.amberAccent, fontSize: 22)),
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
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                        shadowColor: Colors.purpleAccent.withOpacity(0.4),
                      ),
                      child: const Text('Kembali ke Peta Petualangan 🗺️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
}

class _TrackPainter extends CustomPainter {
  final List<Offset> points;
  final List<Offset> drawnPath;

  _TrackPainter(this.points, this.drawnPath);

  @override
  void paint(Canvas canvas, Size size) {
    // Background Stars (Static layout via stable seeded Random)
    final starPaint = Paint()..color = Colors.white.withOpacity(0.25);
    final random = Random(42);
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 2 + 0.5;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    if (points.isEmpty) return;

    // 1. Extra thick background glow
    final glowPaint1 = Paint()
      ..color = Colors.purple.withOpacity(0.06)
      ..strokeWidth = 55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint2 = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 2. Blueprint track channel
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 3. Dashed line guide
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(path, glowPaint1);
    canvas.drawPath(path, glowPaint2);
    canvas.drawPath(path, trackPaint);
    canvas.drawPath(path, dashPaint);

    // 4. Player's neon cyan glow trail
    if (drawnPath.length > 1) {
      final playerGlowPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.3)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final playerPaint = Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final playerCorePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final pPath = Path();
      pPath.moveTo(drawnPath.first.dx, drawnPath.first.dy);
      for (int i = 1; i < drawnPath.length; i++) {
        pPath.lineTo(drawnPath[i].dx, drawnPath[i].dy);
      }
      
      canvas.drawPath(pPath, playerGlowPaint);
      canvas.drawPath(pPath, playerPaint);
      canvas.drawPath(pPath, playerCorePaint);
    }
  }

  @override
  bool shouldRepaint(_TrackPainter oldDelegate) => true;
}
