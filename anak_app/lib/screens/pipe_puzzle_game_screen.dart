import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import 'dart:math' as math;
import 'dart:async';

// ============================================================
// DATA MODELS
// ============================================================

/// Directions: 0=Up, 1=Right, 2=Down, 3=Left
class PipeCell {
  /// 0=straight, 1=corner(L-bend), 2=T-junction
  final int type;

  /// 0,1,2,3 => multiples of 90°
  int rotation;

  /// Whether this cell is part of the solution path
  bool isPath;

  /// For water flow animation
  bool isFilled;
  double fillProgress;

  PipeCell({
    required this.type,
    required this.rotation,
    this.isPath = false,
    this.isFilled = false,
    this.fillProgress = 0.0,
  });

  /// Returns the set of directions this pipe connects to given its type & rotation.
  /// Directions: 0=Up, 1=Right, 2=Down, 3=Left
  Set<int> get connections {
    switch (type) {
      case 0: // Straight: connects 2 opposite sides
        switch (rotation % 2) {
          case 0:
            return {0, 2}; // Up-Down
          case 1:
            return {1, 3}; // Left-Right
        }
        break;
      case 1: // Corner/L-bend: connects 2 adjacent sides
        switch (rotation % 4) {
          case 0:
            return {0, 1}; // Up-Right
          case 1:
            return {1, 2}; // Right-Down
          case 2:
            return {2, 3}; // Down-Left
          case 3:
            return {3, 0}; // Left-Up
        }
        break;
      case 2: // T-junction: connects 3 sides
        switch (rotation % 4) {
          case 0:
            return {0, 1, 2}; // Up-Right-Down (no Left)
          case 1:
            return {1, 2, 3}; // Right-Down-Left (no Up)
          case 2:
            return {2, 3, 0}; // Down-Left-Up (no Right)
          case 3:
            return {3, 0, 1}; // Left-Up-Right (no Down)
        }
        break;
    }
    return {};
  }

  PipeCell copyWith({int? type, int? rotation, bool? isPath, bool? isFilled, double? fillProgress}) {
    return PipeCell(
      type: type ?? this.type,
      rotation: rotation ?? this.rotation,
      isPath: isPath ?? this.isPath,
      isFilled: isFilled ?? this.isFilled,
      fillProgress: fillProgress ?? this.fillProgress,
    );
  }
}

/// Level configuration
class PipeLevel {
  final int level;
  final int cols;
  final int rows;
  final int targetTime; // seconds for 3-star rating

  const PipeLevel({
    required this.level,
    required this.cols,
    required this.rows,
    required this.targetTime,
  });
}

// ============================================================
// LEVEL DEFINITIONS
// ============================================================

const List<PipeLevel> pipeLevels = [
  PipeLevel(level: 1, cols: 3, rows: 3, targetTime: 30),
  PipeLevel(level: 2, cols: 3, rows: 4, targetTime: 45),
  PipeLevel(level: 3, cols: 4, rows: 4, targetTime: 60),
  PipeLevel(level: 4, cols: 4, rows: 5, targetTime: 80),
  PipeLevel(level: 5, cols: 5, rows: 5, targetTime: 100),
  PipeLevel(level: 6, cols: 5, rows: 6, targetTime: 130),
  PipeLevel(level: 7, cols: 6, rows: 6, targetTime: 160),
  PipeLevel(level: 8, cols: 6, rows: 7, targetTime: 200),
];

// ============================================================
// MAIN SCREEN WIDGET
// ============================================================

class PipePuzzleGameScreen extends StatefulWidget {
  const PipePuzzleGameScreen({super.key});

  @override
  State<PipePuzzleGameScreen> createState() => _PipePuzzleGameScreenState();
}

class _PipePuzzleGameScreenState extends State<PipePuzzleGameScreen>
    with TickerProviderStateMixin {
  // --- State Machine ---
  _ScreenMode _mode = _ScreenMode.levelSelect;

  // --- Level Select ---
  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1; // levels unlocked (1-indexed)

  // --- Game Play ---
  late PipeLevel _currentLevel;
  late List<PipeCell> _grid;
  late List<int> _solutionPath; // indices of cells on the correct path
  late Map<int, int> _solutionRotations; // index -> correct rotation for path cells
  int _moves = 0;
  int _optimalMoves = 0;
  bool _isSolved = false;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Water flow animation
  AnimationController? _flowController;
  List<int> _flowOrder = [];
  bool _isFlowing = false;

  // Victory
  int _earnedStars = 0;
  int _earnedScore = 0;

  @override
  void initState() {
    super.initState();
    AudioService().playGameBGM();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flowController?.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  // ============================================================
  // PUZZLE GENERATION (DFS random walk)
  // ============================================================

  void _startLevel(int levelIndex) {
    _currentLevel = pipeLevels[levelIndex];
    _generatePuzzle();
    setState(() {
      _mode = _ScreenMode.playing;
      _moves = 0;
      _elapsedSeconds = 0;
      _isSolved = false;
      _isFlowing = false;
      _earnedStars = 0;
      _earnedScore = 0;
    });
    _startTimer();
  }

  void _generatePuzzle() {
    final cols = _currentLevel.cols;
    final rows = _currentLevel.rows;
    final totalCells = cols * rows;
    final rng = math.Random();

    // Initialize grid
    _grid = List.generate(totalCells, (_) => PipeCell(type: 0, rotation: 0));

    // Build path from top-left (0) to bottom-right (totalCells-1) using DFS
    final startIdx = 0;
    final endIdx = totalCells - 1;

    final path = _buildRandomPath(cols, rows, startIdx, endIdx, rng);
    _solutionPath = path;

    // Determine the correct pipe type and rotation for each path cell
    _solutionRotations = {};

    for (int i = 0; i < path.length; i++) {
      final idx = path[i];
      final r = idx ~/ cols;
      final c = idx % cols;

      // Determine which directions this path cell must connect to
      final Set<int> neededDirs = {};

      if (i > 0) {
        final prevIdx = path[i - 1];
        final pr = prevIdx ~/ cols;
        final pc = prevIdx % cols;
        neededDirs.add(_directionFrom(r, c, pr, pc));
      }
      if (i < path.length - 1) {
        final nextIdx = path[i + 1];
        final nr = nextIdx ~/ cols;
        final nc = nextIdx % cols;
        neededDirs.add(_directionFrom(r, c, nr, nc));
      }

      // Handle start/end cells needing at least one connection
      if (neededDirs.isEmpty) {
        neededDirs.addAll({1, 2}); // fallback
      }
      if (neededDirs.length == 1) {
        // Start or end cell: add one extra direction for a valid pipe
        // prefer direction that doesn't go off-grid
        final existing = neededDirs.first;
        final opposite = (existing + 2) % 4;
        neededDirs.add(opposite);
      }

      // Find matching pipe type & rotation
      final result = _findPipeForDirections(neededDirs);
      _grid[idx] = PipeCell(
        type: result.$1,
        rotation: result.$2,
        isPath: true,
      );
      _solutionRotations[idx] = result.$2;
    }

    // Fill remaining cells with random pipes
    for (int i = 0; i < totalCells; i++) {
      if (!_solutionPath.contains(i)) {
        final type = rng.nextInt(3); // 0, 1, or 2
        final rot = rng.nextInt(4);
        _grid[i] = PipeCell(type: type, rotation: rot, isPath: false);
      }
    }

    // Calculate optimal moves: count how many path cells are NOT already correct after scramble
    // First, save correct rotations, then scramble
    final Map<int, int> correctRotations = Map.from(_solutionRotations);

    // Scramble ALL cell rotations
    for (int i = 0; i < totalCells; i++) {
      final currentCorrect = correctRotations[i];
      int newRot;
      if (currentCorrect != null) {
        // Ensure path cells are NOT in their correct rotation
        final maxRotations = _grid[i].type == 0 ? 2 : 4; // straights only have 2 unique
        do {
          newRot = rng.nextInt(4);
        } while (newRot % maxRotations == currentCorrect % maxRotations);
      } else {
        newRot = rng.nextInt(4);
      }
      _grid[i] = _grid[i].copyWith(rotation: newRot);
    }

    // Compute optimal moves: minimum rotations to solve each path cell
    _optimalMoves = 0;
    for (final idx in _solutionPath) {
      final correct = correctRotations[idx]!;
      final current = _grid[idx].rotation;
      final maxRotations = _grid[idx].type == 0 ? 2 : 4;
      final diff = ((correct % maxRotations) - (current % maxRotations) + maxRotations) % maxRotations;
      _optimalMoves += diff;
    }
    if (_optimalMoves == 0) _optimalMoves = _solutionPath.length;
  }

  /// Build a random path using randomized DFS from start to end
  List<int> _buildRandomPath(int cols, int rows, int start, int end, math.Random rng) {
    final visited = <int>{};
    final path = <int>[];

    bool dfs(int current) {
      visited.add(current);
      path.add(current);

      if (current == end) return true;

      final r = current ~/ cols;
      final c = current % cols;

      // Get neighbors in random order
      final neighbors = <int>[];
      if (r > 0) neighbors.add((r - 1) * cols + c); // Up
      if (c < cols - 1) neighbors.add(r * cols + c + 1); // Right
      if (r < rows - 1) neighbors.add((r + 1) * cols + c); // Down
      if (c > 0) neighbors.add(r * cols + c - 1); // Left

      neighbors.shuffle(rng);

      for (final next in neighbors) {
        if (!visited.contains(next)) {
          if (dfs(next)) return true;
        }
      }

      path.removeLast();
      return false;
    }

    dfs(start);
    return path;
  }

  /// Get direction from (r,c) to (tr,tc): 0=Up, 1=Right, 2=Down, 3=Left
  int _directionFrom(int r, int c, int tr, int tc) {
    if (tr < r) return 0; // Up
    if (tc > c) return 1; // Right
    if (tr > r) return 2; // Down
    return 3; // Left
  }

  /// Find a pipe type and rotation that produces the given set of directions
  (int, int) _findPipeForDirections(Set<int> dirs) {
    // Try all pipe types and rotations
    for (int type = 0; type <= 2; type++) {
      for (int rot = 0; rot < 4; rot++) {
        final cell = PipeCell(type: type, rotation: rot);
        if (_setEquals(cell.connections, dirs)) {
          return (type, rot);
        }
      }
    }
    // Fallback: straight horizontal
    return (0, 1);
  }

  bool _setEquals(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.every((e) => b.contains(e));
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isSolved) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // GAME ACTIONS
  // ============================================================

  void _rotatePipe(int index) {
    if (_isSolved || _isFlowing) return;

    setState(() {
      _grid[index] = _grid[index].copyWith(
        rotation: (_grid[index].rotation + 1) % 4,
      );
      _moves++;
    });
    AudioService().playClick();
    _checkWin();
  }

  // ============================================================
  // WIN CHECK - BFS Flood Fill
  // ============================================================

  void _checkWin() {
    final cols = _currentLevel.cols;
    final rows = _currentLevel.rows;
    final startIdx = 0;
    final endIdx = cols * rows - 1;

    // BFS from startIdx checking actual pipe connections
    final visited = <int>{};
    final queue = <int>[startIdx];
    visited.add(startIdx);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final cr = current ~/ cols;
      final cc = current % cols;
      final currentConns = _grid[current].connections;

      // Check all connected directions
      for (final dir in currentConns) {
        int nr = cr, nc = cc;
        switch (dir) {
          case 0: nr = cr - 1; break; // Up
          case 1: nc = cc + 1; break; // Right
          case 2: nr = cr + 1; break; // Down
          case 3: nc = cc - 1; break; // Left
        }

        // Bounds check
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;

        final neighborIdx = nr * cols + nc;
        if (visited.contains(neighborIdx)) continue;

        // Check if neighbor connects back to us
        final oppositeDir = (dir + 2) % 4;
        final neighborConns = _grid[neighborIdx].connections;

        if (neighborConns.contains(oppositeDir)) {
          visited.add(neighborIdx);
          queue.add(neighborIdx);
        }
      }
    }

    // Win if we can reach the end cell
    if (visited.contains(endIdx)) {
      _onPuzzleSolved(visited);
    }
  }

  void _onPuzzleSolved(Set<int> connectedCells) {
    _timer?.cancel();
    setState(() => _isSolved = true);
    AudioService().playAchievement();

    // Build water flow order via BFS from start
    _buildFlowOrder(connectedCells);
    _startWaterFlow();
  }

  // ============================================================
  // WATER FLOW ANIMATION
  // ============================================================

  void _buildFlowOrder(Set<int> connectedCells) {
    final cols = _currentLevel.cols;
    final rows = _currentLevel.rows;
    final startIdx = 0;

    _flowOrder = [];
    final visited = <int>{};
    final queue = <int>[startIdx];
    visited.add(startIdx);
    _flowOrder.add(startIdx);

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final cr = current ~/ cols;
      final cc = current % cols;
      final currentConns = _grid[current].connections;

      for (final dir in currentConns) {
        int nr = cr, nc = cc;
        switch (dir) {
          case 0: nr = cr - 1; break;
          case 1: nc = cc + 1; break;
          case 2: nr = cr + 1; break;
          case 3: nc = cc - 1; break;
        }

        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        final neighborIdx = nr * cols + nc;
        if (visited.contains(neighborIdx)) continue;
        if (!connectedCells.contains(neighborIdx)) continue;

        final oppositeDir = (dir + 2) % 4;
        if (_grid[neighborIdx].connections.contains(oppositeDir)) {
          visited.add(neighborIdx);
          queue.add(neighborIdx);
          _flowOrder.add(neighborIdx);
        }
      }
    }
  }

  void _startWaterFlow() {
    setState(() => _isFlowing = true);

    int flowIndex = 0;
    Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (flowIndex >= _flowOrder.length) {
        timer.cancel();
        _onFlowComplete();
        return;
      }

      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _grid[_flowOrder[flowIndex]] = _grid[_flowOrder[flowIndex]].copyWith(
          isFilled: true,
          fillProgress: 1.0,
        );
      });
      flowIndex++;
    });
  }

  void _onFlowComplete() {
    // Calculate stars and score
    final level = _currentLevel;
    final targetTime = level.targetTime;

    // Star rating
    final bool timeStar3 = _elapsedSeconds <= targetTime;
    final bool movesStar3 = _moves <= _optimalMoves + 3;
    final bool timeStar2 = _elapsedSeconds <= (targetTime * 1.5).round();
    final bool movesStar2 = _moves <= _optimalMoves + 8;

    if (movesStar3 && timeStar3) {
      _earnedStars = 3;
    } else if (movesStar2 && timeStar2) {
      _earnedStars = 2;
    } else {
      _earnedStars = 1;
    }

    // Dynamic scoring
    final int baseScore = 100;
    final double levelMultiplier = 1.0 + (level.level - 1) * 0.3;
    final int timeBonus = math.max(0, (targetTime - _elapsedSeconds) * 2);
    final int movePenalty = math.max(0, (_moves - _optimalMoves) * 3);
    _earnedScore = ((baseScore * levelMultiplier).round() + timeBonus - movePenalty)
        .clamp(10, 999);

    // Update star ratings
    final levelIdx = level.level - 1;
    if (_earnedStars > _starRatings[levelIdx]) {
      _starRatings[levelIdx] = _earnedStars;
    }

    // Unlock next level
    if (level.level < 8 && level.level >= _highestUnlocked) {
      _highestUnlocked = level.level + 1;
    }

    // Save to AppState
    final appState = context.read<AppState>();
    appState.addPointsFromScore(_earnedScore);
    appState.addSticker('logic-pro');
    appState.updateTestResults('cognitive', {
      'completed': true,
      'score': _earnedScore,
      'timeSpent': _elapsedSeconds,
      'percentage': (_earnedStars / 3 * 100).round(),
    });

    setState(() {
      _isFlowing = false;
      _mode = _ScreenMode.victory;
    });
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _ScreenMode.levelSelect:
        return _buildLevelSelectScreen();
      case _ScreenMode.playing:
        return _buildGameScreen();
      case _ScreenMode.victory:
        return _buildVictoryScreen();
    }
  }

  // ======================== LEVEL SELECT ========================

  Widget _buildLevelSelectScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text(
          'Sambung Pipa',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.blueAccent),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Pilih Level',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Sambungkan pipa dari awal ke akhir!\nKetuk pipa untuk memutarnya.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  final level = pipeLevels[index];
                  final isUnlocked = (index + 1) <= _highestUnlocked;
                  final stars = _starRatings[index];
                  return GestureDetector(
                    onTap: isUnlocked ? () => _startLevel(index) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: isUnlocked
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF06B6D4), // Cyan-500
                                  Color(0xFF0369A1), // Sky-700
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF64748B),
                                  Color(0xFF475569),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isUnlocked ? const Color(0xFF22D3EE) : const Color(0xFF94A3B8),
                          width: 3,
                        ),
                        boxShadow: isUnlocked
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF06B6D4).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Stack(
                        children: [
                          // Decorative Valve Wheel Silhouette in the background
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(
                              Icons.settings_input_component_rounded,
                              size: 72,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          // Small rivet/screw decoration in the 4 corners
                          Positioned(top: 8, left: 8, child: CircleAvatar(radius: 3, backgroundColor: isUnlocked ? Colors.white30 : Colors.white12)),
                          Positioned(top: 8, right: 8, child: CircleAvatar(radius: 3, backgroundColor: isUnlocked ? Colors.white30 : Colors.white12)),
                          Positioned(bottom: 8, left: 8, child: CircleAvatar(radius: 3, backgroundColor: isUnlocked ? Colors.white30 : Colors.white12)),
                          Positioned(bottom: 8, right: 8, child: CircleAvatar(radius: 3, backgroundColor: isUnlocked ? Colors.white30 : Colors.white12)),
                          // Lock icon
                          if (!isUnlocked)
                            const Center(
                              child: Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white60,
                                size: 36,
                              ),
                            ),
                          // Level info
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Level ${level.level}',
                                      style: TextStyle(
                                        color: isUnlocked ? Colors.white : Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    if (isUnlocked)
                                      const Icon(
                                        Icons.water_drop_rounded,
                                        color: Color(0xFF22D3EE),
                                        size: 16,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pipa ${level.cols}×${level.rows}',
                                  style: TextStyle(
                                    color: isUnlocked ? Colors.white70 : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                // Stars
                                Row(
                                  children: List.generate(3, (s) {
                                    return Icon(
                                      s < stars ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: s < stars ? Colors.amberAccent : Colors.white30,
                                      size: 20,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  // ======================== GAME SCREEN ========================

  Widget _buildGameScreen() {
    final cols = _currentLevel.cols;
    final rows = _currentLevel.rows;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: Text(
          'Level ${_currentLevel.level}',
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.blueAccent,
          onPressed: () {
            _timer?.cancel();
            setState(() => _mode = _ScreenMode.levelSelect);
          },
        ),
        actions: [
          // Timer
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Moves
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(
                  '$_moves',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Grid info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grid: ${cols}×$rows',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  Text(
                    'Target: ${_formatTime(_currentLevel.targetTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Pipe grid
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth * 0.92;
                    final maxH = constraints.maxHeight * 0.92;
                    final cellSize = math.min(maxW / cols, maxH / rows);
                    final gridW = cellSize * cols;
                    final gridH = cellSize * rows;

                    return Container(
                      width: gridW + 8,
                      height: gridH + 8,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Start indicator
                          Positioned(
                            top: -24,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.water_drop,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          // End indicator
                          Positioned(
                            bottom: -24,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.outbound,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          // Grid
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 0,
                                mainAxisSpacing: 0,
                              ),
                              itemCount: cols * rows,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => _rotatePipe(index),
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.5),
                                    child: _PipeCellWidget(
                                      cell: _grid[index],
                                      isStart: index == 0,
                                      isEnd: index == cols * rows - 1,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Hint bar
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.blue.shade400),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Ketuk pipa untuk memutar. Hubungkan 💧 ke 🔴!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade400,
                      ),
                      textAlign: TextAlign.center,
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

  // ======================== VICTORY SCREEN ========================

  Widget _buildVictoryScreen() {
    return Scaffold(
      backgroundColor: Colors.blue.shade600,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌊', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  const Text(
                    'PIPA TERHUBUNG!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Level ${_currentLevel.level} Selesai',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < _earnedStars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: i < _earnedStars
                              ? Colors.amber
                              : Colors.white38,
                          size: 48,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Stats card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _statRow(Icons.emoji_events, 'Skor', '$_earnedScore'),
                        const Divider(color: Colors.white24, height: 20),
                        _statRow(Icons.timer, 'Waktu',
                            _formatTime(_elapsedSeconds)),
                        const Divider(color: Colors.white24, height: 20),
                        _statRow(Icons.touch_app, 'Langkah', '$_moves'),
                        const Divider(color: Colors.white24, height: 20),
                        _statRow(Icons.stars, 'Optimal', '~$_optimalMoves'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back to levels
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _mode = _ScreenMode.levelSelect);
                        },
                        icon: const Icon(Icons.grid_view, size: 20),
                        label: const Text(
                          'LEVEL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Next level or replay
                      if (_currentLevel.level < 8)
                        ElevatedButton.icon(
                          onPressed: () {
                            _startLevel(_currentLevel.level); // next level
                          },
                          icon: const Icon(Icons.arrow_forward, size: 20),
                          label: const Text(
                            'LANJUT',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.brown.shade800,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text(
                            'SELESAI',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Replay button
                  TextButton.icon(
                    onPressed: () {
                      _startLevel(_currentLevel.level - 1);
                    },
                    icon: const Icon(Icons.replay, color: Colors.white70),
                    label: const Text(
                      'Ulangi Level',
                      style: TextStyle(color: Colors.white70),
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

  Widget _statRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SCREEN MODE ENUM
// ============================================================

enum _ScreenMode { levelSelect, playing, victory }

// ============================================================
// PIPE CELL PAINTER WIDGET
// ============================================================

class _PipeCellWidget extends StatelessWidget {
  final PipeCell cell;
  final bool isStart;
  final bool isEnd;

  const _PipeCellWidget({
    required this.cell,
    this.isStart = false,
    this.isEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    if (cell.isFilled) {
      bgColor = Colors.blue.shade300;
    } else if (isStart) {
      bgColor = Colors.green.shade50;
    } else if (isEnd) {
      bgColor = Colors.red.shade50;
    } else {
      bgColor = Colors.blue.shade50;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cell.isFilled
              ? Colors.blue.shade400
              : Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      child: CustomPaint(
        painter: _PipePainter(
          type: cell.type,
          rotation: cell.rotation,
          isFilled: cell.isFilled,
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOM PIPE PAINTER
// ============================================================

class _PipePainter extends CustomPainter {
  final int type;
  final int rotation;
  final bool isFilled;

  _PipePainter({
    required this.type,
    required this.rotation,
    required this.isFilled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pipeWidth = size.width * 0.28;
    final halfPipe = pipeWidth / 2;

    // Pipe body paint
    final pipePaint = Paint()
      ..color = isFilled ? Colors.blue.shade600 : Colors.blueGrey.shade600
      ..style = PaintingStyle.fill;

    // Pipe border paint
    final borderPaint = Paint()
      ..color = isFilled ? Colors.blue.shade800 : Colors.blueGrey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Water inner paint
    final waterPaint = isFilled
        ? (Paint()
          ..color = Colors.lightBlue.shade300
          ..style = PaintingStyle.fill)
        : null;
    final innerWidth = pipeWidth * 0.45;
    final halfInner = innerWidth / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * math.pi / 2);
    canvas.translate(-center.dx, -center.dy);

    switch (type) {
      case 0: // Straight: vertical (Up-Down) at rotation=0
        _drawStraight(canvas, size, center, halfPipe, pipePaint, borderPaint,
            waterPaint, halfInner);
        break;
      case 1: // Corner: Up-Right at rotation=0
        _drawCorner(canvas, size, center, halfPipe, pipePaint, borderPaint,
            waterPaint, halfInner);
        break;
      case 2: // T-junction: Up-Right-Down at rotation=0
        _drawTJunction(canvas, size, center, halfPipe, pipePaint, borderPaint,
            waterPaint, halfInner);
        break;
    }

    canvas.restore();

    // Draw center joint circle
    final jointPaint = Paint()
      ..color = isFilled ? Colors.blue.shade500 : Colors.blueGrey.shade500
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, halfPipe * 0.6, jointPaint);

    if (waterPaint != null) {
      canvas.drawCircle(center, halfPipe * 0.3, waterPaint);
    }
  }

  void _drawStraight(
    Canvas canvas,
    Size size,
    Offset center,
    double halfPipe,
    Paint pipePaint,
    Paint borderPaint,
    Paint? waterPaint,
    double halfInner,
  ) {
    // Vertical pipe from top edge to bottom edge
    final rect = Rect.fromCenter(
      center: center,
      width: halfPipe * 2,
      height: size.height,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rrect, pipePaint);
    canvas.drawRRect(rrect, borderPaint);

    if (waterPaint != null) {
      final innerRect = Rect.fromCenter(
        center: center,
        width: halfInner * 2,
        height: size.height,
      );
      canvas.drawRect(innerRect, waterPaint);
    }
  }

  void _drawCorner(
    Canvas canvas,
    Size size,
    Offset center,
    double halfPipe,
    Paint pipePaint,
    Paint borderPaint,
    Paint? waterPaint,
    double halfInner,
  ) {
    // Up arm
    final upRect = Rect.fromLTWH(
      center.dx - halfPipe,
      0,
      halfPipe * 2,
      center.dy,
    );
    canvas.drawRect(upRect, pipePaint);
    canvas.drawRect(upRect, borderPaint);

    // Right arm
    final rightRect = Rect.fromLTWH(
      center.dx,
      center.dy - halfPipe,
      size.width - center.dx,
      halfPipe * 2,
    );
    canvas.drawRect(rightRect, pipePaint);
    canvas.drawRect(rightRect, borderPaint);

    // Water inner
    if (waterPaint != null) {
      canvas.drawRect(
        Rect.fromLTWH(center.dx - halfInner, 0, halfInner * 2, center.dy),
        waterPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
            center.dx, center.dy - halfInner, size.width - center.dx, halfInner * 2),
        waterPaint,
      );
    }
  }

  void _drawTJunction(
    Canvas canvas,
    Size size,
    Offset center,
    double halfPipe,
    Paint pipePaint,
    Paint borderPaint,
    Paint? waterPaint,
    double halfInner,
  ) {
    // Up arm
    final upRect = Rect.fromLTWH(
      center.dx - halfPipe, 0, halfPipe * 2, center.dy);
    canvas.drawRect(upRect, pipePaint);
    canvas.drawRect(upRect, borderPaint);

    // Right arm
    final rightRect = Rect.fromLTWH(
      center.dx, center.dy - halfPipe, size.width - center.dx, halfPipe * 2);
    canvas.drawRect(rightRect, pipePaint);
    canvas.drawRect(rightRect, borderPaint);

    // Down arm
    final downRect = Rect.fromLTWH(
      center.dx - halfPipe, center.dy, halfPipe * 2, size.height - center.dy);
    canvas.drawRect(downRect, pipePaint);
    canvas.drawRect(downRect, borderPaint);

    // Water
    if (waterPaint != null) {
      canvas.drawRect(
        Rect.fromLTWH(center.dx - halfInner, 0, halfInner * 2, center.dy),
        waterPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(center.dx, center.dy - halfInner, size.width - center.dx, halfInner * 2),
        waterPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(center.dx - halfInner, center.dy, halfInner * 2, size.height - center.dy),
        waterPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.rotation != rotation ||
        oldDelegate.isFilled != isFilled;
  }
}
