import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class PrismPainterGame extends StatefulWidget {
  const PrismPainterGame({super.key});

  @override
  State<PrismPainterGame> createState() => _PrismPainterGameState();
}

class _PrismPainterGameState extends State<PrismPainterGame> {
  final Random _random = Random();
  String _gameState = 'menu'; // menu, playing, completed
  int _currentLevel = 1;
  int _score = 0;
  int _correctAnswers = 0;
  int _errors = 0;
  
  DateTime? _gameStartTime;
  int _spawnTimeMs = 0;
  final List<int> _responseTimesMs = [];
  
  int _gridRows = 4;
  int _gridColsHalf = 2; // the actual width is 2 * _gridColsHalf
  List<Color> _activePalette = [Colors.cyanAccent];
  
  List<List<Color?>> _leftGrid = [];
  List<List<Color?>> _rightGridUser = [];

  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    AudioService().stopBGM();
    super.dispose();
  }

  void _generateLevel() {
    // Config based on level
    if (_currentLevel <= 2) {
      _gridRows = 4;
      _gridColsHalf = 2;
      _activePalette = [Colors.cyanAccent]; // 1 color, binary toggle
    } else if (_currentLevel <= 4) {
      _gridRows = 5;
      _gridColsHalf = 3;
      _activePalette = [Colors.cyanAccent, Colors.pinkAccent]; // 2 colors
    } else {
      _gridRows = 6;
      _gridColsHalf = 3;
      _activePalette = [Colors.cyanAccent, Colors.pinkAccent, Colors.yellowAccent]; // 3 colors
    }

    _leftGrid = List.generate(_gridRows, (_) => List.generate(_gridColsHalf, (_) => null));
    _rightGridUser = List.generate(_gridRows, (_) => List.generate(_gridColsHalf, (_) => null));

    // Fill left grid randomly
    for (int r = 0; r < _gridRows; r++) {
      for (int c = 0; c < _gridColsHalf; c++) {
        // ~40% chance to have a color
        if (_random.nextInt(100) < 40) {
           _leftGrid[r][c] = _activePalette[_random.nextInt(_activePalette.length)];
        }
      }
    }
  }

  void _startGame() {
    setState(() {
      _gameState = 'playing';
      _currentLevel = 1;
      _score = 0;
      _correctAnswers = 0;
      _errors = 0;
      _responseTimesMs.clear();
      _gameStartTime = DateTime.now();
    });
    AudioService().playBGM('puzzle_music.mp3');
    _startNextLevel();
  }

  void _startNextLevel() {
    setState(() {
      _isChecking = false;
      _generateLevel();
      _spawnTimeMs = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _onRightTileTap(int r, int c) {
    if (_gameState != 'playing' || _isChecking) return;

    AudioService().playSFX('flip.mp3');

    setState(() {
      Color? current = _rightGridUser[r][c];
      if (current == null) {
        _rightGridUser[r][c] = _activePalette.first;
      } else {
        int idx = _activePalette.indexOf(current);
        if (idx == _activePalette.length - 1) {
          _rightGridUser[r][c] = null; // Reset
        } else {
          _rightGridUser[r][c] = _activePalette[idx + 1]; // Next color
        }
      }
    });
  }

  void _checkMirror() {
    if (_isChecking) return;
    
    // Validate target (Right Col 0 must mirror Left Col N)
    bool isCorrect = true;
    for (int r = 0; r < _gridRows; r++) {
      for (int c = 0; c < _gridColsHalf; c++) {
        int mirrorC = (_gridColsHalf - 1) - c;
        if (_leftGrid[r][c] != _rightGridUser[r][mirrorC]) {
          isCorrect = false;
          break;
        }
      }
      if (!isCorrect) break;
    }

    setState(() {
      _isChecking = true;
      int responseTimeMs = DateTime.now().millisecondsSinceEpoch - _spawnTimeMs;

      if (isCorrect) {
        AudioService().playSFX('success.mp3');
        _score += 30 * _currentLevel;
        _correctAnswers++;
        _responseTimesMs.add(responseTimeMs);
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          if (_correctAnswers >= 5) {
             _endGame();
          } else {
             _currentLevel++;
             _startNextLevel();
          }
        });
      } else {
        AudioService().playSFX('wrong.mp3');
        _errors++;
        // Shake screen or show error briefly, then allow trying again
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() { _isChecking = false; });
        });
      }
    });
  }

  void _endGame() {
    setState(() => _gameState = 'completed');
    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');

    int totalTimeSecs = DateTime.now().difference(_gameStartTime!).inSeconds;
    int totalAttempts = _correctAnswers + _errors;
    int accuracy = totalAttempts > 0 ? ((_correctAnswers / totalAttempts) * 100).round() : 0;
    
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

    context.read<AppState>().updateTestResults('cognitive', {
      'score': _correctAnswers,
      'total': totalAttempts,
      'percentage': accuracy,
      'timeSpent': totalTimeSecs,
      'gameMode': 'Prism Painter',
    });

    context.read<AppState>().updateGameAssessment('mirrorPatternGame', GameSession(
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
    
    context.read<AppState>().addPointsFromScore(_score);

    if (accuracy >= 80) context.read<AppState>().addSticker('mirror-genius');
    if (_currentLevel >= 4) context.read<AppState>().addSticker('reflection-expert');
  }

  @override
  Widget build(BuildContext context) {
    if (_gameState == 'menu') return _buildMenu();
    if (_gameState == 'completed') return _buildCompleted();
    return _buildPlaying();
  }

  Widget _buildMenu() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flip, size: 100, color: Colors.pinkAccent),
                const SizedBox(height: 32),
                Text('Prism Painter\n(Mirror Puzzle)', style: AppTheme.heading1.copyWith(color: Colors.white, fontSize: 36), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text('Lukis pantulan cermin dengan sentuhanmu untuk menciptakan seni piksel!', style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.pinkAccent.withOpacity(0.5))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cara Melukis:', style: AppTheme.heading3.copyWith(color: Colors.pinkAccent)),
                      const SizedBox(height: 16),
                      const Text('1. Amati pola piksel di sebelah KIRI layar.', style: TextStyle(fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('2. Sentuh kotak di sebelah KANAN untuk melukis pantulan cermin dari selang kiri.', style: TextStyle(fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('3. Ketuk kotak berulang kali untuk berganti warna (jika tingkat lanjut).', style: TextStyle(fontSize: 14, color: Colors.greenAccent)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: Colors.pinkAccent
                    ),
                    child: const Text('Mulai Melukis Cermin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke Dashboard', style: TextStyle(fontSize: 16, color: Colors.white54)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaying() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.1), border: Border.all(color: Colors.pinkAccent), borderRadius: BorderRadius.circular(20)),
                    child: Text('Art Level $_currentLevel', style: AppTheme.heading3.copyWith(color: Colors.pinkAccent)),
                  ),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), border: Border.all(color: Colors.greenAccent), borderRadius: BorderRadius.circular(20)),
                     child: Text('Tantangan: ${_correctAnswers.toString().padLeft(2, '0')}/05', style: AppTheme.heading3.copyWith(color: Colors.greenAccent)),
                  ),
                ],
              ),
            ),

            // The Canvas
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // LEFT SIDE (Immutable)
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: _gridColsHalf / _gridRows,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white54, width: 2),
                                left: BorderSide(color: Colors.white54, width: 2),
                                bottom: BorderSide(color: Colors.white54, width: 2),
                                right: BorderSide(color: Colors.yellowAccent, width: 4), // Mirror Line
                              )
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _gridColsHalf,
                                childAspectRatio: 1,
                              ),
                              itemCount: _gridRows * _gridColsHalf,
                              itemBuilder: (context, index) {
                                int r = index ~/ _gridColsHalf;
                                int c = index % _gridColsHalf;
                                Color? color = _leftGrid[r][c];
                                return Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: color ?? Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: color != null ? [BoxShadow(color: color, blurRadius: 10)] : null
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      // RIGHT SIDE (Mutable/Drawable)
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: _gridColsHalf / _gridRows,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white54, width: 2),
                                right: BorderSide(color: Colors.white54, width: 2),
                                bottom: BorderSide(color: Colors.white54, width: 2),
                              )
                            ),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _gridColsHalf,
                                childAspectRatio: 1,
                              ),
                              itemCount: _gridRows * _gridColsHalf,
                              itemBuilder: (context, index) {
                                int r = index ~/ _gridColsHalf;
                                int c = index % _gridColsHalf;
                                Color? color = _rightGridUser[r][c];
                                
                                return GestureDetector(
                                  onTap: () => _onRightTileTap(r, c),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: color ?? Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white12),
                                      boxShadow: color != null ? [BoxShadow(color: color, blurRadius: 10)] : null
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkMirror,
                  icon: _isChecking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.done_all, color: Colors.indigo),
                  label: Text(_isChecking ? 'Mengevaluasi Piksel...' : 'Periksa Cermin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: Colors.yellowAccent
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return Scaffold(
      backgroundColor: const Color(0xFFF472B6), // pink-400
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.palette, size: 100, color: Colors.white),
                const SizedBox(height: 24),
                Text('Seni Cermin\nSempurna!', style: AppTheme.heading1.copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _rowStat('Karya Diselesaikan', '$_correctAnswers'),
                      const Divider(),
                      _rowStat('Revisi Lukisan', '$_errors'),
                      const Divider(),
                      _rowStat('Skor Seniman', '$_score'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Simpan di Galeri', style: TextStyle(color: Color(0xFFF472B6), fontSize: 20, fontWeight: FontWeight.bold)),
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF472B6))),
        ],
      ),
    );
  }
}
