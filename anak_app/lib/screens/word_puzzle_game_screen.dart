import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/assessment_engine.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class WordData {
  final String word;
  final String hint;
  final String category;
  final String difficulty;
  final String emoji;
  final Color themeColor;

  WordData({
    required this.word,
    required this.hint,
    required this.category,
    required this.difficulty,
    required this.emoji,
    required this.themeColor,
  });
}

class LetterTile {
  final String letter;
  final int id;
  bool isPlaced;
  int correctPosition;
  int? currentPosition;
  bool isCorrect;

  LetterTile({
    required this.letter,
    required this.id,
    this.isPlaced = false,
    required this.correctPosition,
    this.currentPosition,
    this.isCorrect = false,
  });
}

class WordPuzzleGameScreen extends StatefulWidget {
  const WordPuzzleGameScreen({super.key});

  @override
  State<WordPuzzleGameScreen> createState() => _WordPuzzleGameScreenState();
}

class _WordPuzzleGameScreenState extends State<WordPuzzleGameScreen> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, completed (fail)
  int _currentLevel = 1;
  int _currentWordIndex = 0;
  List<LetterTile> _letters = [];
  List<LetterTile?> _placedLetters = [];
  int _score = 0;
  bool _showHint = false;
  int _timeElapsed = 0;
  bool _isProcessingWord = false;
  int _errors = 0;
  int _lives = 3;

  Timer? _timer;
  late AnimationController _shakeController;
  late AnimationController _bgAnimCtrl;

  final Map<int, List<WordData>> _levelWordPools = {
    1: [
      WordData(word: 'GURU', hint: 'Orang yang mengajar di sekolah', category: 'Profesi', difficulty: 'easy', emoji: '👩‍🏫', themeColor: const Color(0xFFF43F5E)),
      WordData(word: 'PILOT', hint: 'Orang yang mengemudikan pesawat', category: 'Profesi', difficulty: 'easy', emoji: '👨‍✈️', themeColor: const Color(0xFF0EA5E9)),
      WordData(word: 'MEJA', hint: 'Tempat menaruh buku atau makanan', category: 'Rumah', difficulty: 'easy', emoji: '🪑', themeColor: const Color(0xFF10B981)),
      WordData(word: 'BOLA', hint: 'Mainan berbentuk bulat untuk ditendang', category: 'Mainan', difficulty: 'easy', emoji: '⚽', themeColor: const Color(0xFFF59E0B)),
    ],
    2: [
      WordData(word: 'KAPAL', hint: 'Kendaraan besar yang berjalan di atas air', category: 'Lautan', difficulty: 'easy', emoji: '🚢', themeColor: const Color(0xFF6366F1)),
      WordData(word: 'ROKET', hint: 'Kendaraan untuk pergi ke luar angkasa', category: 'Luar Angkasa', difficulty: 'easy', emoji: '🚀', themeColor: const Color(0xFF3B82F6)),
      WordData(word: 'POHON', hint: 'Tumbuhan kayu besar berdaun rindang', category: 'Alam', difficulty: 'easy', emoji: '🌳', themeColor: const Color(0xFF10B981)),
      WordData(word: 'RUMAH', hint: 'Tempat tinggal dan berteduh kita', category: 'Rumah', difficulty: 'easy', emoji: '🏠', themeColor: const Color(0xFFEC4899)),
    ],
    3: [
      WordData(word: 'DOKTER', hint: 'Orang yang memeriksa dan menyembuhkan pasien', category: 'Profesi', difficulty: 'easy', emoji: '👨‍⚕️', themeColor: const Color(0xFF10B981)),
      WordData(word: 'TOMAT', hint: 'Buah bulat berwarna merah yang segar', category: 'Makanan', difficulty: 'easy', emoji: '🍅', themeColor: const Color(0xFFEF4444)),
      WordData(word: 'SEPATU', hint: 'Alas kaki untuk berpergian atau sekolah', category: 'Pakaian', difficulty: 'easy', emoji: '👟', themeColor: const Color(0xFF8B5CF6)),
      WordData(word: 'PENSIL', hint: 'Alat tulis berinti karbon hitam', category: 'Sekolah', difficulty: 'easy', emoji: '✏️', themeColor: const Color(0xFFF59E0B)),
    ],
    4: [
      WordData(word: 'BINTANG', hint: 'Cahaya kecil yang bersinar di langit malam', category: 'Luar Angkasa', difficulty: 'easy', emoji: '⭐', themeColor: const Color(0xFFF59E0B)),
      WordData(word: 'PISANG', hint: 'Buah kuning kesukaan monyet', category: 'Makanan', difficulty: 'easy', emoji: '🍌', themeColor: const Color(0xFFEAB308)),
      WordData(word: 'TAMAN', hint: 'Tempat bermain yang asri dengan banyak bunga', category: 'Alam', difficulty: 'easy', emoji: '🏡', themeColor: const Color(0xFF10B981)),
      WordData(word: 'SEPEDA', hint: 'Kendaraan beroda dua yang dikayuh pedal', category: 'Kendaraan', difficulty: 'easy', emoji: '🚲', themeColor: const Color(0xFF06B6D4)),
    ],
    5: [
      WordData(word: 'TERUMBU', hint: 'Rumah bagi ikan-ikan kecil di laut', category: 'Lautan', difficulty: 'medium', emoji: '🪸', themeColor: const Color(0xFFEC4899)),
      WordData(word: 'KEPITING', hint: 'Hewan laut bercapit keras yang berjalan miring', category: 'Hewan', difficulty: 'medium', emoji: '🦀', themeColor: const Color(0xFFEF4444)),
      WordData(word: 'KELINCI', hint: 'Hewan berbulu telinga panjang suka wortel', category: 'Hewan', difficulty: 'medium', emoji: '🐰', themeColor: const Color(0xFFF472B6)),
      WordData(word: 'JIRAPAH', hint: 'Hewan darat tertinggi dengan leher sangat panjang', category: 'Hewan', difficulty: 'medium', emoji: '🦒', themeColor: const Color(0xFFD97706)),
    ],
    6: [
      WordData(word: 'ASTRONOT', hint: 'Orang yang pergi ke luar angkasa', category: 'Profesi', difficulty: 'medium', emoji: '👩‍🚀', themeColor: const Color(0xFF8B5CF6)),
      WordData(word: 'HARIMAU', hint: 'Kucing besar pemangsa bermotif loreng', category: 'Hewan', difficulty: 'medium', emoji: '🐯', themeColor: const Color(0xFFD97706)),
      WordData(word: 'BELALANG', hint: 'Serangga pelompat berwarna hijau pemakan daun', category: 'Hewan', difficulty: 'medium', emoji: '🦗', themeColor: const Color(0xFF22C55E)),
      WordData(word: 'SEMANGKA', hint: 'Buah besar berkulit hijau dengan daging merah berair', category: 'Makanan', difficulty: 'medium', emoji: '🍉', themeColor: const Color(0xFFEF4444)),
    ],
    7: [
      WordData(word: 'KOMPUTER', hint: 'Mesin elektronik untuk mengolah data dan belajar', category: 'Elektronik', difficulty: 'hard', emoji: '💻', themeColor: const Color(0xFF3B82F6)),
      WordData(word: 'MATAHARI', hint: 'Bintang pusat tata surya yang menyinari bumi', category: 'Luar Angkasa', difficulty: 'hard', emoji: '☀️', themeColor: const Color(0xFFF59E0B)),
      WordData(word: 'KACAMATA', hint: 'Alat bantu visual yang dipakai di mata', category: 'Aksesoris', difficulty: 'hard', emoji: '👓', themeColor: const Color(0xFF64748B)),
      WordData(word: 'BINATANG', hint: 'Makhluk hidup yang bernapas dan bergerak bebas', category: 'Alam', difficulty: 'hard', emoji: '🦁', themeColor: const Color(0xFF8B5CF6)),
    ],
    8: [
      WordData(word: 'HELIKOPTER', hint: 'Pesawat terbang bersayap putar di atasnya', category: 'Kendaraan', difficulty: 'hard', emoji: '🚁', themeColor: const Color(0xFF0EA5E9)),
      WordData(word: 'PERPUSTAKAAN', hint: 'Tempat menyimpan dan membaca banyak buku', category: 'Sekolah', difficulty: 'hard', emoji: '📚', themeColor: const Color(0xFF6366F1)),
      WordData(word: 'DIRGANTARA', hint: 'Hal yang berhubungan dengan ruang udara atau langit', category: 'Alam', difficulty: 'hard', emoji: '✈️', themeColor: const Color(0xFF0284C7)),
    ],
  };

  List<WordData> _sessionWords = [];
  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _bgAnimCtrl.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  void _startLevel(int level) {
    final pool = _levelWordPools[level] ?? [];
    _sessionWords = List<WordData>.from(pool)..shuffle();
    _sessionWords = _sessionWords.take(3).toList();

    setState(() {
      _gameState = 'playing';
      _currentLevel = level;
      _timeElapsed = 0;
      _score = 0;
      _errors = 0;
      _lives = 3;
      _currentWordIndex = 0;
    });

    AudioService().playBGM('puzzle_music.mp3');
    _initCurrentWord();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameState == 'playing') {
        setState(() => _timeElapsed++);
      } else {
        timer.cancel();
      }
    });
  }

  void _initCurrentWord() {
    var word = _sessionWords[_currentWordIndex];
    List<LetterTile> wordLetters = [];
    for (int i = 0; i < word.word.length; i++) {
      wordLetters.add(LetterTile(letter: word.word[i], id: i, correctPosition: i));
    }
    wordLetters.shuffle(Random());
    
    setState(() {
      _letters = wordLetters;
      _placedLetters = List.filled(word.word.length, null);
      _showHint = false;
      _isProcessingWord = false;
    });
  }

  void _handleLetterClick(LetterTile letter) {
    if (letter.isPlaced || _isProcessingWord) return;
    int nextEmpty = _placedLetters.indexWhere((l) => l == null);
    if (nextEmpty == -1) return;

    setState(() {
      letter.isPlaced = true;
      letter.currentPosition = nextEmpty;
      _placedLetters[nextEmpty] = letter;
    });
    HapticFeedback.lightImpact();
    AudioService().playSFX('flip.mp3');

    _checkCompletion();
  }

  void _handlePlacedLetterClick(int position) {
    var letter = _placedLetters[position];
    if (letter == null || _isProcessingWord) return;

    setState(() {
      letter.isPlaced = false;
      letter.currentPosition = null;
      _placedLetters[position] = null;
    });
    HapticFeedback.lightImpact();
    AudioService().playSFX('flip.mp3');
  }

  void _checkCompletion() {
    if (_placedLetters.every((l) => l != null) && !_isProcessingWord) {
      String formedWord = _placedLetters.map((l) => l!.letter).join('');
      var currentWord = _sessionWords[_currentWordIndex];

      if (formedWord == currentWord.word) {
        HapticFeedback.heavyImpact();
        setState(() => _isProcessingWord = true);
        
        int earnedScore = 100;
        if (!_showHint) earnedScore += 50;
        if (currentWord.difficulty == 'medium') earnedScore += 25;

        setState(() {
          _score += earnedScore;
          for (var l in _placedLetters) {
            l!.isCorrect = true;
          }
        });
        AudioService().playSFX('success.mp3');

        if (_currentWordIndex < _sessionWords.length - 1) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            setState(() {
              _currentWordIndex++;
              _isProcessingWord = false;
            });
            _initCurrentWord();
          });
        } else {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            _completeLevel();
          });
        }
      } else {
        setState(() {
          _errors++;
          _lives--;
        });
        _shakeController.forward(from: 0);
        AudioService().playSFX('wrong.mp3');
        
        if (_lives <= 0) {
          _timer?.cancel();
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!mounted) return;
            AudioService().stopBGM();
            AudioService().playSFX('completion.mp3');
            setState(() {
              _gameState = 'completed';
            });
          });
        } else {
          Future.delayed(const Duration(milliseconds: 500), _initCurrentWord);
        }
      }
    }
  }

  void _completeLevel() {
    _timer?.cancel();
    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');

    int starsCount = _lives;
    _starRatings[_currentLevel - 1] = max(_starRatings[_currentLevel - 1], starsCount);

    if (_currentLevel == _highestUnlocked && _currentLevel < 8) {
      _highestUnlocked = _currentLevel + 1;
    }

    int totalQuestions = _sessionWords.length;
    int correctWords = _currentWordIndex + 1; // Since we completed the last one
    int accuracy = ((correctWords / totalQuestions) * 100).round().clamp(0, 100);
    final int avgRespMs = correctWords > 0 ? ((_timeElapsed * 1000) / correctWords).round() : 0;
    
    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: totalQuestions,
      correct: correctWords,
      avgResponseMs: avgRespMs,
      idealTimeMs: 15000, 
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _errors,
    );

    context.read<AppState>().updateGameAssessment('wordPuzzle', GameSession(
      score: _score,
      timeSpent: _timeElapsed,
      errors: _errors,
      totalItems: totalQuestions,
      correctAnswers: correctWords,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'livesRemaining': _lives,
      },
      subdomainScores: {
        'phonemicAwareness': assessScore,
        'receptiveLanguage': (accuracy / 100.0) * 80.0,
      },
    ));

    context.read<AppState>().addPointsFromScore(_score);

    if (_highestUnlocked >= 8 && starsCount == 3) {
      context.read<AppState>().addSticker('word-master');
    }

    setState(() {
      _gameState = 'level_complete';
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _bgAnimCtrl,
              builder: (context, child) {
                double offset1 = sin(_bgAnimCtrl.value * pi) * 10;
                double offset2 = cos(_bgAnimCtrl.value * pi) * 15;
                return Stack(
                  children: [
                    Positioned(top: 80 - offset1, left: 40, child: const Text('📝', style: TextStyle(fontSize: 48))),
                    Positioned(top: 120 + offset2, right: 60, child: const Text('⭐', style: TextStyle(fontSize: 56))),
                    Positioned(bottom: 150 - offset2, left: 70, child: const Text('🚀', style: TextStyle(fontSize: 48))),
                    Positioned(bottom: 90 + offset1, right: 50, child: const Text('✨', style: TextStyle(fontSize: 56))),
                  ],
                );
              },
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.arrow_back, color: Colors.white),
                                  ),
                                ),
                                Text('Teka-Teki Kata 📝', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 20)),
                                const SizedBox(width: 44),
                              ],
                            ),
                            const Spacer(),
                            const Text('📝', style: TextStyle(fontSize: 100)),
                            const SizedBox(height: 24),
                            Text('Teka-Teki Kata', style: AppTheme.heading1.copyWith(color: Colors.white, fontSize: 36), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            const Text(
                              'Susun huruf-huruf yang berantakan menjadi kata yang benar sesuai petunjuk!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
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
                                  foregroundColor: const Color(0xFF6366F1),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 6,
                                ),
                                child: const Text('🚀 PILIH LEVEL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildLevelSelect() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                          'Pilih Level Kata 📝',
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  gradient: isUnlocked
                                      ? const LinearGradient(
                                          colors: [Color(0xFFFCD34D), Color(0xFFD97706)], // Warm wooden/tile gradient
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)], // Slate grey tile
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(16), // Scrabble block corners
                                  border: Border.all(
                                    color: isUnlocked ? const Color(0xFF78350F) : const Color(0xFF64748B), // Dark wood/board frame border
                                    width: 4,
                                  ),
                                  boxShadow: isUnlocked
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF78350F).withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(2, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isUnlocked ? const Color(0xFF78350F).withOpacity(0.4) : Colors.transparent,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: isUnlocked
                                        ? Text(
                                            '$levelNum',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF78350F), // Imprinted/engraved wood letter style
                                              fontFamily: 'Nunito',
                                            ),
                                          )
                                        : const Icon(Icons.lock_rounded, color: Colors.white60, size: 26),
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

  Widget _buildGameScreen() {
    final word = _sessionWords[_currentWordIndex];
    final progress = _currentWordIndex / 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
          onPressed: () {
            _timer?.cancel();
            AudioService().stopBGM();
            setState(() {
              _gameState = 'level_select';
            });
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text('LEVEL $_currentLevel - KATA ${_currentWordIndex + 1}/3', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 6,
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [word.themeColor, word.themeColor.withOpacity(0.7)]),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: List.generate(3, (i) => Icon(
                Icons.favorite,
                color: i < _lives ? Colors.redAccent : Colors.black12,
                size: 18,
              )),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: word.themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: word.themeColor.withOpacity(0.2), width: 4),
                    ),
                    child: Center(child: Text(word.emoji, style: const TextStyle(fontSize: 72))),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: word.themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(word.category.toUpperCase(), style: TextStyle(color: word.themeColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showHint ? word.hint : 'Ketuk tombol lampu di bawah untuk melihat petunjuk!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w700, 
                            color: _showHint ? const Color(0xFF1E293B) : Colors.black45, 
                            height: 1.4
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildPlacedLetters(word),
                  const SizedBox(height: 36),
                  _buildLetterPool(word),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _buildActionButton(Icons.lightbulb_rounded, 'Petunjuk', () {
                  setState(() => _showHint = !_showHint);
                }, _showHint ? Colors.orange : const Color(0xFF64748B)),
                const SizedBox(width: 16),
                _buildActionButton(Icons.refresh_rounded, 'Ulang', _initCurrentWord, const Color(0xFF64748B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacedLetters(WordData word) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final double offset = (sin(_shakeController.value * 10 * pi) * 5);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(_placedLetters.length, (index) {
              final letter = _placedLetters[index];
              final isCorrect = letter?.isCorrect ?? false;
              
              return GestureDetector(
                onTap: () => _handlePlacedLetterClick(index),
                child: Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFFDCFCE7) : (letter != null ? Colors.white : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCorrect ? const Color(0xFF22C55E) : (letter != null ? word.themeColor : Colors.transparent),
                      width: 2,
                    ),
                    boxShadow: letter != null ? [BoxShadow(color: word.themeColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : null,
                  ),
                  child: Center(
                    child: Text(
                      letter?.letter ?? '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isCorrect ? const Color(0xFF166534) : (letter != null ? word.themeColor : Colors.transparent),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLetterPool(WordData word) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _letters.where((l) => !l.isPlaced).map((letter) {
        return GestureDetector(
          onTap: () => _handleLetterClick(letter),
          child: Container(
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [word.themeColor, word.themeColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: word.themeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                letter.letter,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label, 
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 16),
                        const Text(
                          'LEVEL SELESAI!',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final isStarred = i < starsCount;
                            return Icon(
                              Icons.star_rounded,
                              color: isStarred ? Colors.amber : Colors.white24,
                              size: 64,
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                          child: Column(
                            children: [
                              _buildStatRow('Benar', '3 / 3', Colors.green),
                              const Divider(),
                              _buildStatRow('Kesalahan', '$_errors', Colors.red),
                              const Divider(),
                              _buildStatRow('Waktu', _formatTime(_timeElapsed), Colors.blue),
                              const Divider(),
                              _buildStatRow('Skor', '$_score', Colors.orange),
                            ],
                          ),
                        ),
                        const Spacer(),
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
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
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
                          child: const Text('Main Lagi 🔄', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
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
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return Scaffold(
      backgroundColor: const Color(0xFFEF4444),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                child: IntrinsicHeight(
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
                        'Jangan menyerah! Coba lagi dan susun katanya dengan teliti.',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          children: [
                            _buildStatRow('Kata Selesai', '$_currentWordIndex / 3', Colors.black54),
                            const Divider(),
                            _buildStatRow('Kesalahan', '$_errors', Colors.red),
                          ],
                        ),
                      ),
                      const Spacer(),
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
            );
          }
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
