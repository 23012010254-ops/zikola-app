import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import '../services/assessment_engine.dart';

class Crystal {
  final IconData shape;
  final Color color;
  
  Crystal({required this.shape, required this.color});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Crystal && runtimeType == other.runtimeType && shape == other.shape && color == other.color;

  @override
  int get hashCode => shape.hashCode ^ color.hashCode;
}

class MatrixVaultLevel {
  final List<List<Crystal?>> grid;
  final int missingRow;
  final int missingCol;
  final Crystal correctCrystal;
  final List<Crystal> options;
  
  MatrixVaultLevel({
    required this.grid,
    required this.missingRow,
    required this.missingCol,
    required this.correctCrystal,
    required this.options,
  });
}

class PatternRecognitionGameScreen extends StatefulWidget {
  const PatternRecognitionGameScreen({super.key});

  @override
  State<PatternRecognitionGameScreen> createState() => _PatternRecognitionGameScreenState();
}

class _PatternRecognitionGameScreenState extends State<PatternRecognitionGameScreen> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, completed (fail)
  int _currentLevel = 1;
  int _score = 0;
  int _correctAnswers = 0;
  int _errors = 0;
  int _lives = 3;
  int _roundIndex = 0; // 3 rounds per level
  
  MatrixVaultLevel? _currentLevelData;
  DateTime? _gameStartTime;
  int _spawnTimeMs = 0;
  final List<int> _responseTimesMs = [];
  
  bool _isVaultUnlocking = false;

  final Random _random = Random();

  final List<IconData> _shapes = [Icons.diamond, Icons.circle, Icons.square, Icons.star, Icons.hexagon];
  final List<Color> _colors = [
    const Color(0xFFEF4444), // Red
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF8B5CF6), // Purple
  ];

  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  late AnimationController _bgAnimCtrl;

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

  int getMatrixSize(int level) {
    if (level <= 3) return 2;
    return 3;
  }

  int getLogicType(int level) {
    switch (level) {
      case 1: return 0;
      case 2: return 1;
      case 3: return 2;
      case 4: return 0;
      case 5: return 1;
      case 6: return 2;
      case 7: return 3;
      case 8:
      default:
        return _random.nextInt(4);
    }
  }

  MatrixVaultLevel _generateMatrix(int level) {
    int size = getMatrixSize(level);
    int logicType = getLogicType(level);
    List<List<Crystal?>> grid = List.generate(size, (_) => List.generate(size, (_) => null));

    List<IconData> selectedShapes = List.from(_shapes)..shuffle(_random);
    List<Color> selectedColors = List.from(_colors)..shuffle(_random);

    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        IconData shape;
        Color color;
        
        switch (logicType) {
          case 0: // Color shifts per column, shape same per row
            shape = selectedShapes[r % selectedShapes.length];
            color = selectedColors[c % selectedColors.length];
            break;
          case 1: // Shape shifts per column, color same per row
            shape = selectedShapes[c % selectedShapes.length];
            color = selectedColors[r % selectedColors.length];
            break;
          case 2: // Diagonal mirroring / offset
            shape = selectedShapes[(r + c) % selectedShapes.length];
            color = selectedColors[(r + c) % selectedColors.length];
            break;
          default: // Sequence shift
            shape = selectedShapes[(r * size + c) % selectedShapes.length];
            color = selectedColors[(r * size + c) % selectedColors.length];
        }
        grid[r][c] = Crystal(shape: shape, color: color);
      }
    }

    int mRow = _random.nextInt(size);
    int mCol = _random.nextInt(size);
    Crystal correct = grid[mRow][mCol]!;
    grid[mRow][mCol] = null; // empty slot

    Set<Crystal> optionSet = {correct};
    while(optionSet.length < 4) {
      optionSet.add(Crystal(
        shape: selectedShapes[_random.nextInt(selectedShapes.length)],
        color: selectedColors[_random.nextInt(selectedColors.length)]
      ));
    }
    List<Crystal> options = optionSet.toList()..shuffle(_random);

    return MatrixVaultLevel(
      grid: grid,
      missingRow: mRow,
      missingCol: mCol,
      correctCrystal: correct,
      options: options
    );
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
      _responseTimesMs.clear();
      _gameStartTime = DateTime.now();
    });
    AudioService().playBGM('puzzle_music.mp3');
    _generateNextVault();
  }

  void _generateNextVault() {
    setState(() {
      _currentLevelData = _generateMatrix(_currentLevel);
      _spawnTimeMs = DateTime.now().millisecondsSinceEpoch;
      _isVaultUnlocking = false;
    });
  }

  void _handleCrystalDrop(Crystal droppedCrystal) {
    if (_isVaultUnlocking || _currentLevelData == null) return;
    
    int responseTime = DateTime.now().millisecondsSinceEpoch - _spawnTimeMs;
    bool isCorrect = droppedCrystal == _currentLevelData!.correctCrystal;

    setState(() {
      if (isCorrect) {
        _isVaultUnlocking = true;
        _score += 20 * _currentLevel;
        _correctAnswers++;
        _responseTimesMs.add(responseTime);
        AudioService().playSFX('success.mp3');
        
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() {
            _roundIndex++;
            if (_roundIndex >= 3) {
              _completeLevel();
            } else {
              _generateNextVault();
            }
          });
        });

      } else {
        _errors++;
        _lives--;
        AudioService().playSFX('wrong.mp3');
        if (_lives <= 0) {
          AudioService().stopBGM();
          AudioService().playSFX('completion.mp3');
          setState(() {
            _gameState = 'completed'; // fail
          });
        }
      }
    });
  }

  void _completeLevel() {
    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');

    int starsCount = _lives;
    _starRatings[_currentLevel - 1] = max(_starRatings[_currentLevel - 1], starsCount);

    if (_currentLevel == _highestUnlocked && _currentLevel < 8) {
      _highestUnlocked = _currentLevel + 1;
    }

    int totalTimeSecs = DateTime.now().difference(_gameStartTime!).inSeconds;
    int totalPushed = _correctAnswers + _errors;
    if (totalPushed == 0) totalPushed = 1;
    int accuracy = ((_correctAnswers / totalPushed) * 100).round();
    
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

    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: 3,
      correct: _correctAnswers,
      avgResponseMs: avgMs,
      idealTimeMs: 8000,
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _errors,
    );

    context.read<AppState>().updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': totalPushed,
      'percentage': accuracy,
      'timeSpent': totalTimeSecs,
      'gameMode': 'Crystal Vault',
      'level': _currentLevel,
      'patternRecognitionScore': assessScore,
    });

    context.read<AppState>().updateGameAssessment('patternRecognition', GameSession(
      score: _score, 
      timeSpent: totalTimeSecs, 
      errors: _errors,
      correctAnswers: _correctAnswers,
      totalItems: 3,
      avgResponseTimeMs: avgMs,
      fastestResponseTimeMs: fastestMs,
      slowestResponseTimeMs: slowestMs,
      medianResponseTimeMs: medianMs,
      itemsPerMinute: itemsPerMin,
      maxLevelReached: _currentLevel,
      assessmentScore: assessScore,
      subdomainScores: {
        'visualLogic': assessScore,
        'spatialAbstraction': (accuracy / 100.0) * 80.0,
      },
    ));
    
    context.read<AppState>().addPointsFromScore(_score);

    if (_highestUnlocked >= 8 && starsCount == 3) {
      context.read<AppState>().addSticker('pattern-master');
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
      backgroundColor: const Color(0xFF1E1B4B), // indigo-950
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _bgAnimCtrl,
              builder: (context, child) {
                double offset1 = sin(_bgAnimCtrl.value * pi) * 10;
                double offset2 = cos(_bgAnimCtrl.value * pi) * 15;
                return Stack(
                  children: [
                    Positioned(top: 80 - offset1, left: 40, child: const Text('🔮', style: TextStyle(fontSize: 48))),
                    Positioned(top: 120 + offset2, right: 60, child: const Text('💎', style: TextStyle(fontSize: 56))),
                    Positioned(bottom: 150 - offset2, left: 70, child: const Text('✨', style: TextStyle(fontSize: 48))),
                    Positioned(bottom: 90 + offset1, right: 50, child: const Text('⭐', style: TextStyle(fontSize: 56))),
                  ],
                );
              },
            ),
            SingleChildScrollView(
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
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      Text('Crystal Matrix Vault 🔮', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 20)),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)]
                    ),
                    child: const Icon(Icons.apps, size: 100, color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 32),
                  Text('Crystal Matrix Vault', style: AppTheme.heading1.copyWith(color: Colors.white, fontSize: 32), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text('Pecahkan kode brankas kuno dengan menyeret kristal yang tepat ke dalam matriks!', style: TextStyle(color: Colors.indigo.shade200, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _gameState = 'level_select';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent.shade700,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 8,
                        shadowColor: Colors.cyanAccent,
                      ),
                      child: const Text('🔮 PILIH LEVEL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSelect() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B), // indigo-950
      body: SafeArea(
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
                        'Pilih Level Vault 🔮',
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
                            child: ClipPath(
                              clipper: OctagonClipper(),
                              child: Container(
                                color: isUnlocked ? const Color(0xFF06B6D4) : const Color(0xFF475569), // Outer neon border
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: ClipPath(
                                    clipper: OctagonClipper(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: isUnlocked
                                            ? const LinearGradient(
                                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Dark tech theme
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [Color(0xFF334155), Color(0xFF1E293B)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Cyber lines
                                          if (isUnlocked)
                                            Positioned(
                                              top: 4,
                                              left: 4,
                                              child: Icon(
                                                Icons.qr_code_scanner_rounded,
                                                size: 14,
                                                color: const Color(0xFF06B6D4).withOpacity(0.3),
                                              ),
                                            ),
                                          Center(
                                            child: isUnlocked
                                                ? Text(
                                                    '$levelNum',
                                                    style: const TextStyle(
                                                      fontSize: 26,
                                                      fontWeight: FontWeight.w900,
                                                      color: Color(0xFF22D3EE), // Glowing bright cyan text
                                                      shadows: [
                                                        Shadow(color: Color(0xFF06B6D4), blurRadius: 10, offset: Offset(0, 0))
                                                      ],
                                                      fontFamily: 'monospace',
                                                    ),
                                                  )
                                                : const Icon(Icons.lock_rounded, color: Colors.white38, size: 24),
                                          ),
                                        ],
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
                                color: isStarred ? Colors.cyanAccent : Colors.white12,
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
    );
  }

  Widget _buildPlaying() {
    int size = getMatrixSize(_currentLevel);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // slate-900
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () {
                      AudioService().stopBGM();
                      setState(() {
                        _gameState = 'level_select';
                      });
                    },
                  ),
                  Column(
                    children: [
                      Text('Level $_currentLevel', style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Pola ${_roundIndex + 1} dari 3', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: List.generate(3, (index) => Icon(Icons.favorite, color: index < _lives ? Colors.pinkAccent : Colors.grey.shade800, size: 28)),
                  ),
                ],
              ),
            ),

            // Vault Matrix Area
            Expanded(
              flex: 5,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.blueGrey.shade700, width: 4),
                    boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(_isVaultUnlocking ? 0.3 : 0.05), blurRadius: _isVaultUnlocking ? 50 : 20, spreadRadius: 5)]
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: size,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: size * size,
                    itemBuilder: (context, index) {
                      int r = index ~/ size;
                      int c = index % size;
                      
                      if (_currentLevelData == null) return const SizedBox();
                      
                      Crystal? crystal = _currentLevelData!.grid[r][c];
                      
                      if (crystal != null) {
                        return _buildCrystalNode(crystal);
                      } else {
                        return DragTarget<Crystal>(
                          builder: (context, candidateData, rejectedData) {
                            bool isHovered = candidateData.isNotEmpty;
                            
                            if (_isVaultUnlocking) {
                              return _buildCrystalNode(_currentLevelData!.correctCrystal, glowing: true);
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: isHovered ? Colors.cyanAccent.withOpacity(0.3) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isHovered ? Colors.cyanAccent : Colors.blueGrey.shade600, width: 2, style: BorderStyle.solid)
                              ),
                              child: isHovered ? const Icon(Icons.add_circle_outline, color: Colors.cyanAccent, size: 40) : null,
                            );
                          },
                          onAccept: (droppedCrystal) => _handleCrystalDrop(droppedCrystal),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            // Source Crystals Dock
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                   color: const Color(0xFF1E293B).withOpacity(0.8),
                   borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                   border: Border(top: BorderSide(color: Colors.cyanAccent.withOpacity(0.3), width: 2))
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text('Tarik Kristal ke Brankas', style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),
                    if (_currentLevelData != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _currentLevelData!.options.map((opt) {
                          return Draggable<Crystal>(
                            data: opt,
                            feedback: Opacity(opacity: 0.8, child: _buildCrystalNode(opt, size: 80)),
                            childWhenDragging: Opacity(opacity: 0.3, child: _buildCrystalNode(opt)),
                            child: _buildCrystalNode(opt),
                          );
                        }).toList(),
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

  Widget _buildCrystalNode(Crystal crystal, {double size = 70, bool glowing = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowing ? Colors.white : crystal.color.withOpacity(0.5), width: 2),
        boxShadow: [
          if (glowing) BoxShadow(color: crystal.color, blurRadius: 20, spreadRadius: 5),
          if (!glowing) BoxShadow(color: crystal.color.withOpacity(0.2), blurRadius: 10)
        ]
      ),
      child: Center(
        child: Icon(crystal.shape, color: glowing ? Colors.white : crystal.color, size: size * 0.6),
      ),
    );
  }

  Widget _buildLevelComplete() {
    int starsCount = _lives;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // slate-900
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.diamond, size: 100, color: Colors.cyanAccent),
                const SizedBox(height: 16),
                const Text(
                  'LEVEL SELESAI!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final isStarred = i < starsCount;
                    return Icon(
                      Icons.star_rounded,
                      color: isStarred ? Colors.cyanAccent : Colors.white12,
                      size: 64,
                    );
                  }),
                ),
                
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blueGrey.shade700)),
                  child: Column(
                    children: [
                      _buildStatRow('Jawaban Benar', '$_correctAnswers / 3'),
                      const Divider(color: Colors.white12),
                      _buildStatRow('Kesalahan', '$_errors'),
                      const Divider(color: Colors.white12),
                      _buildStatRow('Skor', '$_score'),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                
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
                      backgroundColor: Colors.cyanAccent.shade700,
                      foregroundColor: Colors.black,
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
                  child: const Text('Main Lagi 🔄', style: TextStyle(fontSize: 16, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _gameState = 'level_select';
                    });
                  },
                  child: const Text('Kembali ke Peta Level 🗺️', style: TextStyle(fontSize: 16, color: Colors.white54, fontWeight: FontWeight.bold)),
                ),
              ],
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
                  'KODE GAGAL DIPECAHKAN!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jangan berkecil hati! Coba analisis polanya kembali.',
                  style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _buildStatRow('Jawaban Benar', '$_correctAnswers / 3', labelColor: Colors.black54, valueColor: const Color(0xFFEF4444)),
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

  Widget _buildStatRow(String label, String value, {Color labelColor = Colors.white70, Color valueColor = Colors.cyanAccent}) {
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

class OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.28, 0);
    path.lineTo(w * 0.72, 0);
    path.lineTo(w, h * 0.28);
    path.lineTo(w, h * 0.72);
    path.lineTo(w * 0.72, h);
    path.lineTo(w * 0.28, h);
    path.lineTo(0, h * 0.72);
    path.lineTo(0, h * 0.28);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
