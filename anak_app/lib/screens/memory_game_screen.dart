import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class CardData {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardData({required this.id, required this.emoji, this.isFlipped = false, this.isMatched = false});
}

class MemoryLevelConfig {
  final int level;
  final int cardCount;
  final int crossAxisCount;
  final int? timeLimit; // seconds, null if no limit
  final int star3Moves; // max moves for 3 stars
  final int star2Moves; // max moves for 2 stars

  MemoryLevelConfig({
    required this.level,
    required this.cardCount,
    required this.crossAxisCount,
    this.timeLimit,
    required this.star3Moves,
    required this.star2Moves,
  });
}

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, completed
  List<CardData> _cards = [];
  List<int> _flippedCards = [];
  int _matchedPairs = 0;
  int _moves = 0;
  int _gameTime = 0;
  bool _isTimerRunning = false;
  Timer? _timer;

  final List<String> _cardEmojis = ['🐱', '🐶', '🐸', '🦊', '🐰', '🐨', '🐼', '🦁', '🦄', '🐯', '🐵', '🐧', '🦋', '🐝', '🌸', '🌟', '🎈', '🍎'];
  int _streak = 0;
  int _bestStreak = 0;
  int _errors = 0;
  bool _isProcessing = false;

  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;
  int _currentLevel = 1;

  late AnimationController _confettiController;

  final List<MemoryLevelConfig> _levelsConfig = [
    MemoryLevelConfig(level: 1, cardCount: 4, crossAxisCount: 2, star3Moves: 3, star2Moves: 5, timeLimit: null),
    MemoryLevelConfig(level: 2, cardCount: 6, crossAxisCount: 3, star3Moves: 5, star2Moves: 7, timeLimit: null),
    MemoryLevelConfig(level: 3, cardCount: 8, crossAxisCount: 4, star3Moves: 6, star2Moves: 9, timeLimit: null),
    MemoryLevelConfig(level: 4, cardCount: 12, crossAxisCount: 4, star3Moves: 10, star2Moves: 14, timeLimit: null),
    MemoryLevelConfig(level: 5, cardCount: 12, crossAxisCount: 4, star3Moves: 10, star2Moves: 14, timeLimit: 60),
    MemoryLevelConfig(level: 6, cardCount: 16, crossAxisCount: 4, star3Moves: 14, star2Moves: 20, timeLimit: null),
    MemoryLevelConfig(level: 7, cardCount: 16, crossAxisCount: 4, star3Moves: 14, star2Moves: 20, timeLimit: 45),
    MemoryLevelConfig(level: 8, cardCount: 20, crossAxisCount: 5, star3Moves: 18, star2Moves: 25, timeLimit: 45),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  void _startLevel(int level) {
    final config = _levelsConfig[level - 1];
    int pairsCount = config.cardCount ~/ 2;

    List<String> selectedEmojis = List.from(_cardEmojis)..shuffle();
    selectedEmojis = selectedEmojis.take(pairsCount).toList();

    List<String> pairedEmojis = [...selectedEmojis, ...selectedEmojis];
    pairedEmojis.shuffle(Random());

    setState(() {
      _cards = List.generate(pairedEmojis.length, (index) => CardData(id: index, emoji: pairedEmojis[index]));
      _flippedCards = [];
      _matchedPairs = 0;
      _moves = 0;
      _streak = 0;
      _bestStreak = 0;
      _errors = 0;
      _gameTime = 0;
      _isTimerRunning = true;
      _isProcessing = false;
      _currentLevel = level;
      _gameState = 'playing';
    });

    AudioService().playBGM('puzzle_music.mp3');
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerRunning && _gameState == 'playing') {
        setState(() {
          _gameTime++;
          final limit = _levelsConfig[_currentLevel - 1].timeLimit;
          if (limit != null && _gameTime >= limit) {
            _timer?.cancel();
            _isTimerRunning = false;
            _endGame(); // failed level due to timeout
          }
        });
      }
    });
  }

  void _handleCardClick(int cardId) {
    if (_isProcessing || _flippedCards.length == 2 || _flippedCards.contains(cardId)) return;

    var clickedCard = _cards.firstWhere((c) => c.id == cardId);
    if (clickedCard.isMatched) return;

    setState(() {
      _flippedCards.add(cardId);
      clickedCard.isFlipped = true;
    });
    HapticFeedback.lightImpact();
    AudioService().playSFX('card_flip.mp3');

    if (_flippedCards.length == 2) {
      _moves++;
      _isProcessing = true;

      int firstCardId = _flippedCards[0];
      int secondCardId = _flippedCards[1];
      var firstCard = _cards.firstWhere((c) => c.id == firstCardId);
      var secondCard = _cards.firstWhere((c) => c.id == secondCardId);

      if (firstCard.emoji == secondCard.emoji) {
        // Match found
        setState(() {
          _streak++;
          if (_streak > _bestStreak) _bestStreak = _streak;
        });

        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            firstCard.isMatched = true;
            secondCard.isMatched = true;
            _matchedPairs++;
            _flippedCards = [];
            _isProcessing = false;
          });
          if (_streak >= 2) {
            HapticFeedback.heavyImpact();
          }
          AudioService().playSFX('match_success.mp3');
          _checkCompletion();
        });
      } else {
        // No match
        HapticFeedback.selectionClick();
        setState(() {
          _streak = 0;
          _errors++;
        });
        AudioService().playSFX('match_fail.mp3');
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() {
            firstCard.isFlipped = false;
            secondCard.isFlipped = false;
            _flippedCards = [];
            _isProcessing = false;
          });
        });
      }
    }
  }

  void _checkCompletion() {
    final config = _levelsConfig[_currentLevel - 1];
    int totalPairs = config.cardCount ~/ 2;
    if (_matchedPairs == totalPairs) {
      _isTimerRunning = false;
      _timer?.cancel();
      
      _confettiController.repeat();

      int stars = _getStarRatingForLevel(_moves, config);
      int score = _calculateScoreForLevel(stars, _gameTime, _errors, config);

      final levelIdx = _currentLevel - 1;
      if (stars > _starRatings[levelIdx]) {
        _starRatings[levelIdx] = stars;
      }

      if (_currentLevel == _highestUnlocked && _currentLevel < 8) {
        _highestUnlocked = _currentLevel + 1;
      }

      // Save Data using updateGameAssessment
      context.read<AppState>().updateGameAssessment('memory', GameSession(score: score, timeSpent: _gameTime, errors: _errors));
      context.read<AppState>().addPointsFromScore(score);

      if (_highestUnlocked >= 8 && stars == 3) {
        context.read<AppState>().addSticker('memory-master');
      }
      
      AudioService().stopBGM();
      AudioService().playSFX('level_complete.mp3');

      setState(() {
        _gameState = 'level_complete';
      });
    }
  }

  void _endGame() {
    setState(() => _gameState = 'completed');
    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');
  }

  int _getStarRatingForLevel(int moves, MemoryLevelConfig config) {
    if (moves <= config.star3Moves) return 3;
    if (moves <= config.star2Moves) return 2;
    return 1;
  }

  int _calculateScoreForLevel(int stars, int timeInSeconds, int errors, MemoryLevelConfig config) {
    int baseScore = stars * 30;
    int timeTarget = config.timeLimit ?? 90;
    int timeBonus = max(0, ((timeTarget - timeInSeconds) ~/ 10)) * 2;
    int errorPenalty = errors * 5;
    double levelMultiplier = 1.0 + (config.level * 0.1);

    return max(10, ((baseScore + timeBonus - errorPenalty) * levelMultiplier).round());
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_gameState == 'menu') return _buildIntroScreen();
    if (_gameState == 'level_select') return _buildLevelSelect();
    if (_gameState == 'level_complete') return _buildLevelComplete();
    if (_gameState == 'completed') return _buildCompleted();
    return _buildGameScreen();
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Stack(
        children: [
          Positioned(top: -50, left: -50, child: Container(width: 200, height: 200, decoration: const BoxDecoration(color: Color(0xFFBAE6FD), shape: BoxShape.circle))),
          Positioned(bottom: 100, right: -30, child: Container(width: 150, height: 150, decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF0369A1)),
                        ),
                      ),
                      Text('Kartu Memori', style: TextStyle(color: const Color(0xFF0369A1), fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text('🧠', style: TextStyle(fontSize: 100)),
                  const SizedBox(height: 24),
                  Text('Asah Otakmu!', style: TextStyle(color: const Color(0xFF0369A1), fontSize: 32, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text('Temukan pasangan gambar\nyang sama di balik kartu!', style: TextStyle(color: const Color(0xFF475569), fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: const Color(0xFF0369A1).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Misi Melatih Memori:', style: TextStyle(color: Color(0xFF0369A1), fontSize: 18, fontWeight: FontWeight.w800)),
                        SizedBox(height: 16),
                        Text('1. Buka dua kartu untuk mencari gambar yang sama.', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 8),
                        Text('2. Ingat posisi gambar jika salah membuka pasangan.', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 8),
                        Text('3. Selesaikan dengan gerakan sesedikit mungkin!', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _gameState = 'level_select';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF472B6), // Pink
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 8,
                      ),
                      child: const Text('Mulai Ujian Memori 🚀', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelect() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
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
                        'Pilih Level Memori 🧠',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0369A1),
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
                                 gradient: isUnlocked
                                     ? const LinearGradient(
                                         colors: [Color(0xFF38BDF8), Color(0xFF0284C7)], // Sky blue card back
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                       )
                                     : const LinearGradient(
                                         colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)], // Slate grey card back
                                         begin: Alignment.topLeft,
                                         end: Alignment.bottomRight,
                                       ),
                                 borderRadius: BorderRadius.circular(16), // Rounded game card style
                                 border: Border.all(
                                   color: isUnlocked ? Colors.white : Colors.grey.shade400,
                                   width: 3.5,
                                 ),
                                 boxShadow: isUnlocked
                                     ? [
                                         BoxShadow(
                                           color: const Color(0xFF0284C7).withOpacity(0.3),
                                           blurRadius: 8,
                                           offset: const Offset(2, 4),
                                         )
                                       ]
                                     : [],
                               ),
                               child: Stack(
                                 alignment: Alignment.center,
                                 children: [
                                   // Subtle card back pattern in the background
                                   if (isUnlocked)
                                     Positioned(
                                       top: 6,
                                       right: 6,
                                       child: Icon(
                                         Icons.help_outline_rounded,
                                         size: 16,
                                         color: Colors.white.withOpacity(0.3),
                                       ),
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
                                                 Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(1.5, 1.5))
                                               ],
                                             ),
                                           )
                                         : const Icon(Icons.lock_rounded, color: Colors.white60, size: 24),
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

  Widget _buildGameScreen() {
    final config = _levelsConfig[_currentLevel - 1];
    int totalPairs = config.cardCount ~/ 2;

    String displayTime;
    if (config.timeLimit != null) {
      int timeLeft = config.timeLimit! - _gameTime;
      displayTime = _formatTime(max(0, timeLeft));
    } else {
      displayTime = _formatTime(_gameTime);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // Internal Bubbly Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF38BDF8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _timer?.cancel();
                          AudioService().stopBGM();
                          setState(() => _gameState = 'level_select');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF0369A1)),
                        ),
                      ),
                      Column(
                        children: [
                          const Text('Kartu Memori', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          Text('Level $_currentLevel', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _startLevel(_currentLevel),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.refresh, color: Color(0xFF0369A1)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('GERAKAN', '$_moves'),
                        _buildStatCol(config.timeLimit != null ? 'SISA WAKTU' : 'WAKTU', displayTime),
                        _buildStatCol('PASANGAN', '$_matchedPairs/$totalPairs'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: config.crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      var card = _cards[index];
                      // Setup container details
                      Color containerColor = const Color(0xFFE9D5FF); // default back (purple-300ish)
                      Border border = Border.all(color: const Color(0xFFC084FC), width: 2); // purple-400
                      if (card.isFlipped) {
                        containerColor = Colors.white;
                      }
                      if (card.isMatched) {
                        containerColor = const Color(0xFFA7F3D0); // emerald-200
                        border = Border.all(color: const Color(0xFF10B981), width: 2); // emerald-500
                      }

                      return GestureDetector(
                        onTap: () => _handleCardClick(card.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: containerColor,
                            border: border,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: card.isFlipped && !card.isMatched ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)] : [],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: card.isFlipped || card.isMatched
                                  ? Text(card.emoji, key: ValueKey(card.id), style: const TextStyle(fontSize: 32))
                                  : Text('❓', key: ValueKey('back_${card.id}'), style: const TextStyle(fontSize: 24, color: Colors.white)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progres', style: TextStyle(color: Color(0xFF9333EA), fontSize: 12)),
                      Text('$_matchedPairs/$totalPairs', style: const TextStyle(color: Color(0xFF9333EA), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(6)), // purple-100
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _matchedPairs / totalPairs,
                      child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]), borderRadius: BorderRadius.circular(6))),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Color(0xFFF3E8FF), fontSize: 10)),
      ],
    );
  }

  Widget _buildLevelComplete() {
    final config = _levelsConfig[_currentLevel - 1];
    int starsCount = _getStarRatingForLevel(_moves, config);
    int score = _calculateScoreForLevel(starsCount, _gameTime, _errors, config);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'HEBAT SEKALI! 🧠',
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
                    _rowStat('Jumlah Gerakan:', '$_moves'),
                    const Divider(color: Colors.white24),
                    _rowStat('Kesalahan:', '$_errors'),
                    const Divider(color: Colors.white24),
                    _rowStat('Waktu Selesai:', '$_gameTime detik'),
                    const Divider(color: Colors.white24),
                    _rowStat('Skor Diperoleh:', '$score'),
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
                    foregroundColor: const Color(0xFF0284C7),
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
                const Text('⏰', style: TextStyle(fontSize: 100)),
                const SizedBox(height: 24),
                Text('Waktu Habis!\nLevel Gagal', style: AppTheme.heading1.copyWith(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _rowStat('Pasangan Ditemukan', '$_matchedPairs/${_levelsConfig[_currentLevel - 1].cardCount ~/ 2}'),
                      const Divider(),
                      _rowStat('Jumlah Gerakan', '$_moves'),
                      const Divider(),
                      _rowStat('Kesalahan', '$_errors'),
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
        ],
      ),
    );
  }
}
