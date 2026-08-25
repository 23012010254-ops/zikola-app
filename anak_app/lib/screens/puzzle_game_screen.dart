import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import 'dart:async';

// ─── Data Models ────────────────────────────────────────────────────────────

class PuzzleLevel {
  final int id;
  final String title;
  final String difficulty;
  final int pieces;
  final int columns;
  final String image;
  final String description;
  final Color color;
  final Color borderColor;
  final List<String> themedPieces;
  final int targetTimeSeconds;
  final List<int> prerequisites; // puzzle ids that must be completed first

  PuzzleLevel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.pieces,
    required this.columns,
    required this.image,
    required this.description,
    required this.color,
    required this.borderColor,
    required this.themedPieces,
    required this.targetTimeSeconds,
    this.prerequisites = const [],
  });
}

class PuzzlePieceData {
  final int id;
  final int correctPosition;
  int currentPosition;
  bool placed;
  bool isInCorrectPosition;

  PuzzlePieceData({
    required this.id,
    required this.correctPosition,
    required this.currentPosition,
    required this.placed,
    required this.isInCorrectPosition,
  });
}

class PuzzleResult {
  final int stars;
  final int score;
  final int timeSeconds;
  final int moves;
  final int maxCombo;

  PuzzleResult({
    required this.stars,
    required this.score,
    required this.timeSeconds,
    required this.moves,
    required this.maxCombo,
  });
}

// ─── Main Widget ────────────────────────────────────────────────────────────

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> with TickerProviderStateMixin {
  // Game State
  PuzzleLevel? _selectedPuzzle;
  List<PuzzlePieceData> _puzzlePieces = [];
  List<int> _completedPieces = [];
  bool _gameCompleted = false;
  bool _showHint = false;
  int? _selectedPiece;
  bool _wrongMoveShake = false;

  // Combo System
  int _combo = 0;
  int _maxCombo = 0;
  int _lastCorrectTime = 0;

  // Timer System
  Timer? _gameTimer;
  int _elapsedSeconds = 0;

  // Scoring
  int _totalMoves = 0;

  // Completion Tracking: puzzleId -> PuzzleResult
  final Map<int, PuzzleResult> _completedPuzzles = {};

  // Results Screen
  PuzzleResult? _lastResult;

  // Animation Controllers
  late AnimationController _shakeController;
  late AnimationController _comboController;
  late AnimationController _placedController;

  // ─── Puzzle Definitions ─────────────────────────────────────────────────

  final List<PuzzleLevel> _puzzles = [
    PuzzleLevel(
      id: 1,
      title: 'Cute Fox',
      difficulty: 'Easy',
      pieces: 6,
      columns: 2,
      image: '🦊',
      description: 'Susun puzzle rubah lucu ini!',
      color: const Color(0xFFFFEDD5),
      borderColor: const Color(0xFFFDBA74),
      themedPieces: ['🦊', '🍂', '🌲', '🍄', '🐿️', '🌰'],
      targetTimeSeconds: 60,
    ),
    PuzzleLevel(
      id: 2,
      title: 'Happy Elephant',
      difficulty: 'Easy',
      pieces: 9,
      columns: 3,
      image: '🐘',
      description: 'Bentuk gajah yang bahagia!',
      color: const Color(0xFFF3F4F6),
      borderColor: const Color(0xFFD1D5DB),
      themedPieces: ['🐘', '🌿', '🌍', '💧', '🌴', '🍃', '🦒', '🌺', '🌸'],
      targetTimeSeconds: 90,
    ),
    PuzzleLevel(
      id: 3,
      title: 'Tropical Bird',
      difficulty: 'Easy',
      pieces: 9,
      columns: 3,
      image: '🦜',
      description: 'Burung tropis yang indah!',
      color: const Color(0xFFDCFCE7),
      borderColor: const Color(0xFF86EFAC),
      themedPieces: ['🦜', '🌺', '🌴', '🍍', '🌈', '🦩', '🌸', '🌊', '🐚'],
      targetTimeSeconds: 90,
    ),
    PuzzleLevel(
      id: 4,
      title: 'Colorful Butterfly',
      difficulty: 'Medium',
      pieces: 12,
      columns: 3,
      image: '🦋',
      description: 'Kupu-kupu berwarna cantik!',
      color: const Color(0xFFF3E8FF),
      borderColor: const Color(0xFFD8B4FE),
      themedPieces: ['🦋', '🌸', '🌺', '🌻', '🌹', '🌷', '🌼', '💐', '🏵️', '🍀', '🌿', '🌱'],
      targetTimeSeconds: 120,
    ),
    PuzzleLevel(
      id: 5,
      title: 'Ocean Fish',
      difficulty: 'Medium',
      pieces: 16,
      columns: 4,
      image: '🐠',
      description: 'Ikan cantik di lautan biru!',
      color: const Color(0xFFDBEAFE),
      borderColor: const Color(0xFF93C5FD),
      themedPieces: ['🐠', '🐟', '🐡', '🦈', '🐙', '🦑', '🦐', '🦀', '🐚', '🌊', '🪸', '🐳', '🧜‍♀️', '🫧', '🪼', '🐬'],
      targetTimeSeconds: 150,
    ),
    PuzzleLevel(
      id: 6,
      title: 'Wild Lion',
      difficulty: 'Medium',
      pieces: 16,
      columns: 4,
      image: '🦁',
      description: 'Raja hutan yang gagah!',
      color: const Color(0xFFFEF08A),
      borderColor: const Color(0xFFFDE047),
      themedPieces: ['🦁', '🌍', '🌅', '🦒', '🐘', '🦓', '🌴', '🐆', '🦏', '🐃', '🦛', '🌿', '🐊', '🦩', '🦅', '🐾'],
      targetTimeSeconds: 150,
    ),
    PuzzleLevel(
      id: 7,
      title: 'Space Rocket',
      difficulty: 'Hard',
      pieces: 20,
      columns: 4,
      image: '🚀',
      description: 'Petualangan luar angkasa!',
      color: const Color(0xFFE0E7FF),
      borderColor: const Color(0xFFA5B4FC),
      themedPieces: ['🚀', '🌟', '⭐', '💫', '🛸', '👽', '🌙', '🪐', '🌍', '🛰️', '☄️', '🌌', '✨', '🔭', '🌠', '🌛', '🌝', '💥', '🌕', '🌑'],
      targetTimeSeconds: 200,
      prerequisites: [4, 5, 6], // Must complete all 3 Medium puzzles
    ),
    PuzzleLevel(
      id: 8,
      title: 'Magic Dragon',
      difficulty: 'Hard',
      pieces: 25,
      columns: 5,
      image: '🐉',
      description: 'Naga ajaib dari dunia fantasi!',
      color: const Color(0xFFFEE2E2),
      borderColor: const Color(0xFFFCA5A5),
      themedPieces: ['🐉', '🏰', '🗡️', '🛡️', '👑', '💎', '🔥', '⚡', '🌟', '🧙‍♂️', '🏴‍☠️', '🦅', '🐲', '🎭', '🏆', '🔮', '🗝️', '💀', '🌋', '🎪', '🧝‍♂️', '🧌', '🧚‍♀️', '🐺', '🦄'],
      targetTimeSeconds: 300,
      prerequisites: [1, 2, 3, 4, 5, 6, 7], // Must complete ALL others
    ),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _comboController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _placedController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    AudioService().stopBGM();
    _shakeController.dispose();
    _comboController.dispose();
    _placedController.dispose();
    super.dispose();
  }

  // ─── Lock System ────────────────────────────────────────────────────────

  bool _isPuzzleLocked(PuzzleLevel puzzle) {
    if (puzzle.prerequisites.isEmpty) return false;
    for (final reqId in puzzle.prerequisites) {
      if (!_completedPuzzles.containsKey(reqId)) return true;
    }
    return false;
  }

  // ─── Game Initialization ────────────────────────────────────────────────

  void _initializePuzzle() {
    _gameTimer?.cancel();

    List<PuzzlePieceData> pieces = List.generate(
      _selectedPuzzle!.pieces,
      (i) => PuzzlePieceData(
        id: i,
        correctPosition: i,
        currentPosition: i,
        placed: false,
        isInCorrectPosition: false,
      ),
    );
    pieces.shuffle(Random());

    setState(() {
      _puzzlePieces = pieces;
      _completedPieces = [];
      _gameCompleted = false;
      _showHint = false;
      _selectedPiece = null;
      _combo = 0;
      _maxCombo = 0;
      _wrongMoveShake = false;
      _elapsedSeconds = 0;
      _totalMoves = 0;
      _lastResult = null;
    });

    // Start timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_gameCompleted) {
        setState(() => _elapsedSeconds++);
      }
    });

    AudioService().playGameBGM();
  }

  // ─── Piece Selection ────────────────────────────────────────────────────

  void _handlePieceSelect(int pieceId) {
    if (_completedPieces.contains(pieceId)) return;
    setState(() {
      _selectedPiece = _selectedPiece == pieceId ? null : pieceId;
    });
    AudioService().playClick();
  }

  // ─── Slot Placement ─────────────────────────────────────────────────────

  void _handleSlotPlace(int slotId) {
    if (_selectedPiece == null || _selectedPuzzle == null) return;

    _totalMoves++;
    final piece = _puzzlePieces.firstWhere((p) => p.id == _selectedPiece);

    if (piece.correctPosition == slotId) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      int timeSinceLastCorrect = currentTime - _lastCorrectTime;

      setState(() {
        if (timeSinceLastCorrect < 3000 && _completedPieces.isNotEmpty) {
          _combo++;
        } else {
          _combo = 1;
        }
        if (_combo > _maxCombo) _maxCombo = _combo;
        _lastCorrectTime = currentTime;

        piece.placed = true;
        piece.isInCorrectPosition = true;
        piece.currentPosition = slotId;

        _completedPieces.add(_selectedPiece!);
        _selectedPiece = null;
      });

      // Play placed animation
      _placedController.forward(from: 0);

      // Combo visual flair
      if (_combo >= 3) {
        _comboController.forward(from: 0);
      }

      // Check game completion
      if (_completedPieces.length == _selectedPuzzle!.pieces) {
        _onGameCompleted();
      }

      AudioService().playCorrect();
    } else {
      setState(() {
        _wrongMoveShake = true;
        _combo = 0;
      });
      AudioService().playSFX('wrong.mp3');
      _shakeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _wrongMoveShake = false;
            _selectedPiece = null;
          });
        }
      });
    }
  }

  // ─── Game Completion ────────────────────────────────────────────────────

  void _onGameCompleted() {
    _gameTimer?.cancel();

    // Calculate score
    final int pieceCount = _selectedPuzzle!.pieces;
    final double comboMultiplier = 1.0 + (_maxCombo * 0.2);
    final int targetTime = _selectedPuzzle!.targetTimeSeconds;
    final int timeBonus = max(0, (targetTime - _elapsedSeconds) * 5);
    final int rawScore = (pieceCount * 10 * comboMultiplier).round() + timeBonus;

    // Calculate stars
    int stars = 1; // Completed = at least 1 star
    if (_maxCombo >= 2 && _elapsedSeconds <= (targetTime * 1.5).round()) {
      stars = 2;
    }
    if (_maxCombo >= 3 && _elapsedSeconds <= targetTime) {
      stars = 3;
    }

    final result = PuzzleResult(
      stars: stars,
      score: rawScore,
      timeSeconds: _elapsedSeconds,
      moves: _totalMoves,
      maxCombo: _maxCombo,
    );

    setState(() {
      _gameCompleted = true;
      _lastResult = result;

      // Track completion (keep best result)
      final existing = _completedPuzzles[_selectedPuzzle!.id];
      if (existing == null || result.stars > existing.stars || result.score > existing.score) {
        _completedPuzzles[_selectedPuzzle!.id] = result;
      }
    });

    // Save to app state
    context.read<AppState>().updateTestResults('cognitive', {
      'score': rawScore,
      'total': 100,
      'percentage': (stars / 3 * 100).round(),
      'timeSpent': _elapsedSeconds,
      'gameMode': 'Puzzle Game - ${_selectedPuzzle?.title ?? "Default"}',
    });

    context.read<AppState>().updateGameAssessment('puzzleGame', GameSession(
      score: rawScore, 
      timeSpent: _elapsedSeconds, 
      errors: _totalMoves > 10 ? _totalMoves - 10 : 0,
      correctAnswers: stars,
      totalItems: 3,
      avgResponseTimeMs: 0,
      fastestResponseTimeMs: 0,
      slowestResponseTimeMs: 0,
      medianResponseTimeMs: 0,
      itemsPerMinute: _elapsedSeconds > 0 ? (_totalMoves / (_elapsedSeconds / 60)) : 0.0,
      maxLevelReached: _selectedPuzzle?.difficulty == 'Easy' ? 1 : (_selectedPuzzle?.difficulty == 'Medium' ? 2 : 3),
    ));

    context.read<AppState>().addSticker('puzzle-master');
    context.read<AppState>().addPointsFromScore(rawScore);

    AudioService().stopBGM();
    AudioService().playAchievement();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return const Color(0xFF15803D);
      case 'Medium':
        return const Color(0xFFA16207);
      case 'Hard':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getDifficultyBgColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return const Color(0xFFDCFCE7);
      case 'Medium':
        return const Color(0xFFFEF08A);
      case 'Hard':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameCompleted && _lastResult != null) return _buildResultsScreen();
    if (_selectedPuzzle != null) return _buildPlayingScreen();
    return _buildPuzzleSelection();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PUZZLE SELECTION SCREEN
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPuzzleSelection() {
    final totalStars = _completedPuzzles.values.fold<int>(0, (sum, r) => sum + r.stars);
    final maxStars = _puzzles.length * 3;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF9333EA)]),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      Text(
                        'Puzzle Games',
                        style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 20),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Pilih Puzzle Favoritmu! 🧩',
                          style: AppTheme.heading3.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Susun potongan-potongan untuk membuat gambar yang sempurna',
                          style: AppTheme.bodyText.copyWith(color: const Color(0xFFDBEAFE)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Star progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.yellowAccent, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '$totalStars / $maxStars',
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${_completedPuzzles.length}/${_puzzles.length} selesai',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Puzzle List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _puzzles.length,
                itemBuilder: (context, index) {
                  final puzzle = _puzzles[index];
                  final isLocked = _isPuzzleLocked(puzzle);
                  final completedResult = _completedPuzzles[puzzle.id];
                  final isCompleted = completedResult != null;

                  return GestureDetector(
                    onTap: isLocked
                        ? () => _showLockedDialog(puzzle)
                        : () {
                            setState(() => _selectedPuzzle = puzzle);
                            _initializePuzzle();
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLocked ? const Color(0xFFF3F4F6) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF22C55E)
                              : isLocked
                                  ? const Color(0xFFD1D5DB)
                                  : AppTheme.gray100,
                          width: isCompleted ? 2 : 1,
                        ),
                        boxShadow: isLocked
                            ? []
                            : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          // Puzzle icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isLocked ? const Color(0xFFE5E7EB) : puzzle.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLocked ? const Color(0xFFD1D5DB) : puzzle.borderColor,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isLocked
                                  ? const Icon(Icons.lock, color: Color(0xFF9CA3AF), size: 32)
                                  : Text(puzzle.image, style: const TextStyle(fontSize: 40)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        puzzle.title,
                                        style: AppTheme.heading3.copyWith(
                                          color: isLocked ? const Color(0xFF9CA3AF) : AppTheme.gray900,
                                        ),
                                      ),
                                    ),
                                    if (isCompleted) ...[
                                      const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                                    ],
                                  ],
                                ),
                                Text(
                                  puzzle.description,
                                  style: AppTheme.bodyText.copyWith(
                                    color: isLocked ? const Color(0xFFD1D5DB) : AppTheme.gray600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isLocked
                                            ? const Color(0xFFE5E7EB)
                                            : _getDifficultyBgColor(puzzle.difficulty),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        puzzle.difficulty,
                                        style: TextStyle(
                                          color: isLocked
                                              ? const Color(0xFF9CA3AF)
                                              : _getDifficultyColor(puzzle.difficulty),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '🧩 ${puzzle.pieces} pieces',
                                      style: TextStyle(
                                        color: isLocked ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280),
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (isCompleted) ...[
                                      const SizedBox(width: 8),
                                      ...List.generate(3, (i) {
                                        return Icon(
                                          Icons.star,
                                          size: 14,
                                          color: i < completedResult.stars
                                              ? const Color(0xFFFACC15)
                                              : const Color(0xFFE5E7EB),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Play/Lock indicator
                          Icon(
                            isLocked ? Icons.lock_outline : Icons.play_arrow,
                            color: isLocked
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFFA855F7),
                            size: 32,
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

  void _showLockedDialog(PuzzleLevel puzzle) {
    String message;
    if (puzzle.id == 8) {
      final remaining = _puzzles.where((p) => p.id != 8 && !_completedPuzzles.containsKey(p.id)).toList();
      message = 'Selesaikan semua ${remaining.length} puzzle lainnya dulu untuk membuka ${puzzle.title}!';
    } else {
      final needed = puzzle.prerequisites
          .where((id) => !_completedPuzzles.containsKey(id))
          .map((id) => _puzzles.firstWhere((p) => p.id == id).title)
          .toList();
      message = 'Selesaikan puzzle berikut dulu: ${needed.join(", ")}';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Color(0xFFA855F7)),
            const SizedBox(width: 8),
            Text('Terkunci! 🔒', style: AppTheme.heading3),
          ],
        ),
        content: Text(message, style: AppTheme.bodyText.copyWith(color: AppTheme.gray600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RESULTS SCREEN
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildResultsScreen() {
    final result = _lastResult!;
    final puzzle = _selectedPuzzle!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFACC15), Color(0xFFF97316)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy
                    const Text('🎉', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 16),
                    Text(
                      'Selamat! 🏆',
                      style: AppTheme.heading2.copyWith(color: AppTheme.gray900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kamu berhasil menyelesaikan puzzle ${puzzle.title}!',
                      style: AppTheme.bodyText.copyWith(color: AppTheme.gray600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star,
                            size: 44,
                            color: i < result.stars
                                ? const Color(0xFFFACC15)
                                : const Color(0xFFE5E7EB),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Stats Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow('⏱️ Waktu', _formatTime(result.timeSeconds)),
                          const Divider(height: 16),
                          _buildStatRow('👆 Langkah', '${result.moves}'),
                          const Divider(height: 16),
                          _buildStatRow('🔥 Max Combo', '${result.maxCombo}x'),
                          const Divider(height: 16),
                          _buildStatRow(
                            '💯 Skor',
                            '${result.score}',
                            valueColor: const Color(0xFFA855F7),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sticker reward
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium, color: Color(0xFFCA8A04), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hadiah Diperoleh!',
                                  style: TextStyle(color: Color(0xFFA16207), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  'Stiker "Puzzle Master" + ${result.score ~/ 10} poin!',
                                  style: const TextStyle(color: Color(0xFFCA8A04), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        // Replay Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _gameCompleted = false;
                                _lastResult = null;
                              });
                              _initializePuzzle();
                            },
                            icon: const Icon(Icons.replay, color: Colors.white, size: 18),
                            label: const Text(
                              'Main Lagi',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Back Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedPuzzle = null;
                                _gameCompleted = false;
                                _lastResult = null;
                              });
                            },
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF374151), size: 18),
                            label: const Text(
                              'Kembali',
                              style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5E7EB),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyText.copyWith(color: AppTheme.gray600)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.gray900,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PLAYING SCREEN
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPlayingScreen() {
    final puzzle = _selectedPuzzle!;
    final crossAxisCount = puzzle.columns;
    final progress = _completedPieces.length / puzzle.pieces;

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF9333EA)]),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _gameTimer?.cancel();
                          AudioService().stopBGM();
                          setState(() => _selectedPuzzle = null);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          puzzle.title,
                          style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showHint = !_showHint),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: _showHint ? Colors.yellowAccent : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Timer + Combo + Progress
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Timer
                            Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(_elapsedSeconds),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            // Combo indicator
                            if (_combo > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '🔥 x$_combo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            // Progress counter
                            Text(
                              '${_completedPieces.length}/${puzzle.pieces}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Game Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Combo banner
                    if (_combo >= 3)
                      AnimatedBuilder(
                        animation: _comboController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_comboController.value * 0.05),
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '🔥🔥🔥 COMBO x$_combo! Kamu lagi on fire! 🔥🔥🔥',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else if (_combo == 2)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '🔥 COMBO x$_combo! Teruskan!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // Wrong move indicator
                    if (_wrongMoveShake)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('😅', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Oops! Posisi Salah',
                                  style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Coba lagi ya! Kamu pasti bisa!',
                                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Hint
                    if (_showHint)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFCE8),
                          border: Border.all(color: const Color(0xFFFDE047)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Color(0xFFCA8A04)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Klik setiap bagian puzzle sesuai urutan yang benar untuk menyusun gambar ${puzzle.title}!',
                                style: const TextStyle(color: Color(0xFFA16207), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Preview: emoji grid
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: puzzle.color,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: puzzle.borderColor, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                            ),
                            child: _buildEmojiPreviewGrid(puzzle),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gambar yang harus disusun',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Instruction text
                    if (_selectedPiece == null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            '🧩 Pilih potongan puzzle, lalu ketuk posisi yang tepat di area puzzle',
                            style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    if (_selectedPiece != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '✨ Potongan "${puzzle.themedPieces[_selectedPiece!]}" dipilih! Ketuk posisinya di area puzzle',
                            style: const TextStyle(color: Color(0xFFC2410C), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    const Text(
                      'Area Puzzle',
                      style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // ── Puzzle Board ──
                    Center(
                      child: SizedBox(
                        width: crossAxisCount == 2
                            ? 160.0
                            : crossAxisCount == 3
                                ? 240.0
                                : crossAxisCount == 4
                                    ? 300.0
                                    : 340.0,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            childAspectRatio: 1,
                          ),
                          itemCount: puzzle.pieces,
                          itemBuilder: (context, slotIndex) {
                            final placedPiece = _puzzlePieces
                                .where((p) => p.currentPosition == slotIndex && p.placed)
                                .firstOrNull;
                            final isTargeted = _selectedPiece != null &&
                                _puzzlePieces.firstWhere((p) => p.id == _selectedPiece).correctPosition == slotIndex;

                            return GestureDetector(
                              onTap: () => _handleSlotPlace(slotIndex),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: placedPiece != null
                                      ? const Color(0xFFDCFCE7)
                                      : isTargeted
                                          ? const Color(0xFFFFEDD5)
                                          : const Color(0xFFF9FAFB),
                                  border: Border.all(
                                    color: placedPiece != null
                                        ? const Color(0xFF22C55E)
                                        : isTargeted
                                            ? const Color(0xFFF97316)
                                            : const Color(0xFFD1D5DB),
                                    width: placedPiece != null ? 3 : isTargeted ? 3 : 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: placedPiece != null
                                      ? Text(
                                          puzzle.themedPieces[placedPiece.id],
                                          style: TextStyle(fontSize: crossAxisCount >= 5 ? 18 : 24),
                                        )
                                      : Text(
                                          '${slotIndex + 1}',
                                          style: TextStyle(
                                            color: isTargeted
                                                ? const Color(0xFFF97316)
                                                : const Color(0xFF9CA3AF),
                                            fontSize: crossAxisCount >= 5 ? 12 : 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Potongan Puzzle',
                      style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // ── Pieces ──
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _puzzlePieces.where((p) => !p.placed).map((piece) {
                        final isSelected = _selectedPiece == piece.id;
                        final emoji = puzzle.themedPieces[piece.id];
                        final pieceSize = crossAxisCount >= 5 ? 48.0 : 56.0;

                        return GestureDetector(
                          onTap: () => _handlePieceSelect(piece.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: pieceSize,
                            height: pieceSize,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFFDBEAFE),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF93C5FD),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected
                                  ? const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: TextStyle(fontSize: crossAxisCount >= 5 ? 20 : 24),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Reset Button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _initializePuzzle,
                        icon: const Icon(Icons.refresh, color: Color(0xFF374151)),
                        label: const Text(
                          'Reset Puzzle',
                          style: TextStyle(color: Color(0xFF374151)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5E7EB),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }

  // ─── Emoji Preview Grid ─────────────────────────────────────────────────

  Widget _buildEmojiPreviewGrid(PuzzleLevel puzzle) {
    final cols = puzzle.columns;
    final rows = (puzzle.pieces / cols).ceil();
    final emojiSize = cols >= 5 ? 14.0 : cols >= 4 ? 16.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(cols, (col) {
            final idx = row * cols + col;
            if (idx >= puzzle.pieces) return const SizedBox(width: 20);
            return Padding(
              padding: const EdgeInsets.all(1),
              child: Text(
                puzzle.themedPieces[idx],
                style: TextStyle(fontSize: emojiSize),
              ),
            );
          }),
        );
      }),
    );
  }
}

// ─── AnimatedBuilder helper (same as AnimatedBuilder but named to avoid conflicts) ──

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
