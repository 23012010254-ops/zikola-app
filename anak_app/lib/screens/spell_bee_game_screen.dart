import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/level_progress_store.dart';
import '../services/audio_service.dart';
import '../services/app_state.dart';
import '../services/assessment_engine.dart';
import '../services/age_difficulty.dart';
import '../widgets/age_mode_chip.dart';
import '../theme/app_theme.dart';

class SpellBeeGame extends StatefulWidget {
  const SpellBeeGame({super.key});

  @override
  State<SpellBeeGame> createState() => _SpellBeeGameState();
}

class _SpellBeeGameState extends State<SpellBeeGame> with TickerProviderStateMixin {
  String _gameState = 'menu'; // menu, level_select, playing, level_complete, completed (fail)
  int _currentLevel = 1;
  int _score = 0;
  int _lives = 3;
  int _currentWordIndex = 0;
  int _correctAnswers = 0;
  int _errors = 0;
  DateTime? _gameStartTime;

  final Map<int, List<Map<String, dynamic>>> _levelWordPools = {
    1: [
      {'word': 'AIR', 'image': '💧', 'hint': 'Diminum saat haus'},
      {'word': 'TAS', 'image': '🎒', 'hint': 'Tempat membawa buku sekolah'},
      {'word': 'BUS', 'image': '🚌', 'hint': 'Kendaraan umum berukuran besar'},
      {'word': 'CAT', 'image': '🎨', 'hint': 'Cairan pewarna untuk menggambar atau mewarnai'},
      {'word': 'API', 'image': '🔥', 'hint': 'Panas dan menyala, jangan disentuh'},
      {'word': 'KUE', 'image': '🍰', 'hint': 'Makanan manis saat ulang tahun'},
      {'word': 'JAM', 'image': '⏰', 'hint': 'Menunjukkan waktu'},
      {'word': 'TEH', 'image': '🍵', 'hint': 'Minuman hangat dari daun'},
      {'word': 'SUP', 'image': '🥣', 'hint': 'Makanan berkuah dimakan dengan sendok'},
      {'word': 'IBU', 'image': '👩', 'hint': 'Orang yang melahirkan dan menyayangi kita'},
    ],
    2: [
      {'word': 'MEJA', 'image': '🪑', 'hint': 'Tempat menaruh buku atau makanan'},
      {'word': 'BUKU', 'image': '📖', 'hint': 'Dibaca untuk belajar'},
      {'word': 'BOLA', 'image': '⚽', 'hint': 'Mainan berbentuk bulat'},
      {'word': 'TOPI', 'image': '🧢', 'hint': 'Pelindung kepala dari panas matahari'},
      {'word': 'DAUN', 'image': '🍃', 'hint': 'Bagian pohon yang berwarna hijau'},
      {'word': 'AWAN', 'image': '☁️', 'hint': 'Benda putih atau abu-abu di langit'},
      {'word': 'SAPI', 'image': '🐄', 'hint': 'Hewan penghasil susu'},
      {'word': 'BAJU', 'image': '👕', 'hint': 'Dipakai untuk menutupi badan'},
      {'word': 'KAKI', 'image': '🦶', 'hint': 'Dipakai untuk berjalan'},
      {'word': 'ROTI', 'image': '🍞', 'hint': 'Sarapan lembut yang bisa diberi selai'},
    ],
    3: [
      {'word': 'MADU', 'image': '🍯', 'hint': 'Cairan manis hasil lebah'},
      {'word': 'RATU', 'image': '👑', 'hint': 'Pemimpin para lebah atau kerajaan'},
      {'word': 'APEL', 'image': '🍎', 'hint': 'Buah merah yang manis dan renyah'},
      {'word': 'IKAN', 'image': '🐟', 'hint': 'Berenang di dalam air'},
      {'word': 'ULAR', 'image': '🐍', 'hint': 'Hewan panjang tanpa kaki'},
      {'word': 'SUSU', 'image': '🥛', 'hint': 'Minuman putih yang menyehatkan tulang'},
      {'word': 'KUDA', 'image': '🐴', 'hint': 'Hewan yang bisa ditunggangi dan berlari cepat'},
      {'word': 'GIGI', 'image': '🦷', 'hint': 'Dipakai untuk mengunyah, rajin disikat ya'},
      {'word': 'LAUT', 'image': '🌊', 'hint': 'Air asin yang sangat luas'},
      {'word': 'LEBAH', 'image': '🐝', 'hint': 'Serangga rajin penghasil madu'},
    ],
    4: [
      {'word': 'POHON', 'image': '🌳', 'hint': 'Tumbuhan kayu besar berdaun rindang'},
      {'word': 'RUMAH', 'image': '🏠', 'hint': 'Tempat tinggal dan berlindung kita'},
      {'word': 'MOBIL', 'image': '🚗', 'hint': 'Kendaraan darat beroda empat'},
      {'word': 'BUNGA', 'image': '🌻', 'hint': 'Tempat lebah mencari nektar manis'},
      {'word': 'MANIS', 'image': '🍭', 'hint': 'Rasa khas dari madu atau permen'},
      {'word': 'GAJAH', 'image': '🐘', 'hint': 'Hewan besar berbelalai panjang'},
      {'word': 'TOMAT', 'image': '🍅', 'hint': 'Buah merah untuk saus dan sambal'},
      {'word': 'KAPAL', 'image': '🚢', 'hint': 'Kendaraan besar yang berlayar di laut'},
      {'word': 'HUJAN', 'image': '🌧️', 'hint': 'Air yang turun dari langit'},
      {'word': 'JERUK', 'image': '🍊', 'hint': 'Buah oranye yang segar dan asam manis'},
    ],
    5: [
      {'word': 'KUCING', 'image': '🐱', 'hint': 'Hewan peliharaan lucu berbulu yang mengeong'},
      {'word': 'ANJING', 'image': '🐶', 'hint': 'Hewan setia penjaga rumah yang menggonggong'},
      {'word': 'BURUNG', 'image': '🐦', 'hint': 'Hewan bersayap yang bisa terbang bebas'},
      {'word': 'SEPATU', 'image': '👟', 'hint': 'Alas kaki untuk berpergian atau sekolah'},
      {'word': 'KERETA', 'image': '🚆', 'hint': 'Kendaraan panjang yang berjalan di atas rel'},
      {'word': 'KELAPA', 'image': '🥥', 'hint': 'Buah berair segar dari pohon tinggi di pantai'},
      {'word': 'KOMODO', 'image': '🦎', 'hint': 'Kadal raksasa asli Indonesia'},
      {'word': 'JAGUNG', 'image': '🌽', 'hint': 'Bijinya kuning, enak direbus atau dibakar'},
    ],
    6: [
      {'word': 'PENSIL', 'image': '✏️', 'hint': 'Alat tulis berinti karbon hitam'},
      {'word': 'SEPEDA', 'image': '🚲', 'hint': 'Kendaraan beroda dua yang dikayuh pedal'},
      {'word': 'TAMAN', 'image': '🏡', 'hint': 'Tempat indah bermain yang penuh bunga'},
      {'word': 'PISANG', 'image': '🍌', 'hint': 'Buah kuning kesukaan monyet'},
      {'word': 'KAMERA', 'image': '📷', 'hint': 'Alat untuk memotret'},
      {'word': 'TELUR', 'image': '🥚', 'hint': 'Dihasilkan ayam, bisa digoreng atau direbus'},
      {'word': 'MONYET', 'image': '🐒', 'hint': 'Hewan lincah yang suka memanjat pohon'},
      {'word': 'PAYUNG', 'image': '☂️', 'hint': 'Melindungi kita dari hujan'},
      {'word': 'BALON', 'image': '🎈', 'hint': 'Ditiup lalu bisa melayang'},
    ],
    7: [
      {'word': 'KELINCI', 'image': '🐰', 'hint': 'Hewan berbulu telinga panjang suka wortel'},
      {'word': 'KEPITING', 'image': '🦀', 'hint': 'Hewan laut bercapit keras berjalan miring'},
      {'word': 'HARIMAU', 'image': '🐯', 'hint': 'Kucing besar pemangsa bermotif loreng'},
      {'word': 'JERAPAH', 'image': '🦒', 'hint': 'Hewan darat tertinggi dengan leher sangat panjang'},
      {'word': 'PESAWAT', 'image': '✈️', 'hint': 'Kendaraan yang terbang di langit'},
      {'word': 'BINTANG', 'image': '⭐', 'hint': 'Berkelip di langit malam'},
      {'word': 'GURITA', 'image': '🐙', 'hint': 'Hewan laut berkaki delapan'},
    ],
    8: [
      {'word': 'MATAHARI', 'image': '☀️', 'hint': 'Bintang pusat tata surya yang menyinari bumi'},
      {'word': 'KACAMATA', 'image': '👓', 'hint': 'Alat bantu visual yang dipakai di mata'},
      {'word': 'BELALANG', 'image': '🦗', 'hint': 'Serangga pelompat berwarna hijau pemakan daun'},
      {'word': 'KOMPUTER', 'image': '💻', 'hint': 'Mesin elektronik untuk mengolah data dan belajar'},
      {'word': 'SEMANGKA', 'image': '🍉', 'hint': 'Buah besar hijau di luar, merah di dalam'},
      {'word': 'STROBERI', 'image': '🍓', 'hint': 'Buah merah kecil berbintik'},
      {'word': 'ASTRONOT', 'image': '🧑‍🚀', 'hint': 'Orang yang terbang ke luar angkasa'},
    ],
  };

  List<Map<String, dynamic>> _sessionWords = [];
  late List<String> _shuffledLetters;
  late List<String?> _slots;
  // Slots filled in advance as help for younger children.
  Set<int> _prefilled = {};
  late AgeDifficulty _age;
  late Map<String, dynamic> _currentWordData;

  final List<int> _starRatings = List.filled(8, 0);
  int _highestUnlocked = 1;

  late AnimationController _bgAnimCtrl;

  /// Restores saved stars and unlocked levels for this child.
  Future<void> _restoreLevelProgress() async {
    final unlocked = await LevelProgressStore.load(context, 'spellBee', _starRatings);
    if (!mounted) return;
    setState(() => _highestUnlocked = unlocked > _highestUnlocked ? unlocked : _highestUnlocked);
  }

  @override
  void initState() {
    super.initState();
    _restoreLevelProgress();
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimCtrl.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  void _startLevel(int level) {
    _age = AgeDifficulty.of(context);
    final pool = _levelWordPools[level] ?? [];
    _sessionWords = List<Map<String, dynamic>>.from(pool)..shuffle();
    _sessionWords = _sessionWords.take(_age.pick(toddler: 3, preschool: 4, school: 5)).toList();

    setState(() {
      _gameState = 'playing';
      _currentLevel = level;
      _score = 0;
      _lives = 3;
      _currentWordIndex = 0;
      _correctAnswers = 0;
      _errors = 0;
      _gameStartTime = DateTime.now();
    });

    AudioService().playHomeBGM();
    _startNewWord();
  }

  void _startNewWord() {
    _currentWordData = _sessionWords[_currentWordIndex];
    _setupWord();
    setState(() {});
  }

  /// Lays out slots and letter tiles for the current word, scaled to age:
  /// toddlers only fill in the last 1–2 letters, preschoolers get the first
  /// letter on long words, school-age kids get extra decoy letters.
  void _setupWord() {
    final word = _currentWordData['word'] as String;
    final letters = word.split('');
    final reveal = _age.pick(
      toddler: max(0, letters.length - 2),
      preschool: letters.length >= 6 ? 1 : 0,
      school: 0,
    );
    _prefilled = {for (var i = 0; i < reveal; i++) i};
    _slots = List<String?>.generate(letters.length, (i) => _prefilled.contains(i) ? letters[i] : null);

    final pool = [for (var i = 0; i < letters.length; i++) if (!_prefilled.contains(i)) letters[i]];
    final decoys = _age.pick(toddler: 0, preschool: 0, school: 2);
    const alphabet = 'ABCDEGHIJKLMNOPRSTUW';
    final rnd = Random();
    for (var i = 0; i < decoys; i++) {
      pool.add(alphabet[rnd.nextInt(alphabet.length)]);
    }
    _shuffledLetters = pool..shuffle();
  }

  void _onLetterDrop(int slotIndex, String letter, int letterIndex) {
    if (_slots[slotIndex] != null) return;

    AudioService().playPop();
    setState(() {
      _slots[slotIndex] = letter;
      _shuffledLetters[letterIndex] = ''; // Remove from pool
    });

    _checkWord();
  }

  void _resetCurrentWord() {
    setState(_setupWord);
    AudioService().playFlip();
  }

  void _checkWord() {
    if (_slots.any((s) => s == null)) return;

    String formedWord = _slots.join('');
    if (formedWord == _currentWordData['word']) {
      _onCorrect();
    } else {
      _onWrong();
    }
  }

  void _onCorrect() {
    AudioService().playSparkle();
    setState(() {
      _score += 20;
      _correctAnswers++;
    });
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _currentWordIndex++;
        if (_currentWordIndex >= _sessionWords.length) {
          _completeLevel();
        } else {
          _startNewWord();
        }
      });
    });
  }

  void _onWrong() {
    AudioService().playWrong();
    setState(() {
      _lives--;
      _errors++;
      if (_lives <= 0) {
        _gameState = 'completed'; // fail
        AudioService().stopBGM();
        AudioService().playGameOver();
      } else {
        _startNewWord(); // Reset current word
      }
    });
  }

  void _completeLevel() {
    AudioService().stopBGM();
    AudioService().playSparkle();

    int starsCount = _lives;
    _starRatings[_currentLevel - 1] = max(_starRatings[_currentLevel - 1], starsCount);

    if (_currentLevel == _highestUnlocked && _currentLevel < 8) {
      _highestUnlocked = _currentLevel + 1;
    }
    LevelProgressStore.save(context, 'spellBee', _starRatings, _highestUnlocked);

    final appState = context.read<AppState>();
    int totalTime = _gameStartTime != null ? DateTime.now().difference(_gameStartTime!).inSeconds : 0;
    int totalAttempts = _correctAnswers + _errors;
    if (totalAttempts == 0) totalAttempts = 1;
    int accuracy = ((_correctAnswers / totalAttempts) * 100).round().clamp(0, 100);
    int avgRespMs = _correctAnswers > 0 ? ((totalTime * 1000) / _correctAnswers).round() : 0;

    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: _sessionWords.length,
      correct: _correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 15000,
      maxLevel: _currentLevel,
      totalLevels: 8,
      hintsUsed: 0,
      errors: _errors,
    );

    appState.updateTestResults('linguistic', {
      'score': _correctAnswers,
      'total': _sessionWords.length,
      'percentage': accuracy,
      'timeSpent': totalTime,
      'gameMode': 'Spelling Bee',
      'level': _currentLevel,
      'spellingScore': assessScore,
    });

    appState.updateGameAssessment('spellBeeGame', GameSession(
      score: _score,
      timeSpent: totalTime,
      errors: _errors,
      totalItems: _sessionWords.length,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'livesRemaining': _lives,
      },
      subdomainScores: {
        'phonemicAwareness': assessScore,
        'vocabulary': (accuracy / 100.0) * 80.0,
      },
    ));

    appState.addPointsFromScore(_score);

    if (_highestUnlocked >= 8 && starsCount == 3) {
      appState.addSticker('spelling-bee-champion');
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
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFF59E0B)],
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
                    Positioned(top: 80 - offset1, left: 40, child: const Text('🐝', style: TextStyle(fontSize: 48))),
                    Positioned(top: 120 + offset2, right: 60, child: const Text('🍯', style: TextStyle(fontSize: 56))),
                    Positioned(bottom: 150 - offset2, left: 70, child: const Text('🌻', style: TextStyle(fontSize: 48))),
                    Positioned(bottom: 90 + offset1, right: 50, child: const Text('⭐', style: TextStyle(fontSize: 56))),
                  ],
                );
              },
            ),
            SafeArea(
              child: SingleChildScrollView(
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
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.arrow_back, color: Color(0xFF92400E)),
                          ),
                        ),
                        Text('Lomba Eja 🐝', style: AppTheme.heading2.copyWith(color: const Color(0xFF92400E), fontSize: 20)),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('🍯', style: TextStyle(fontSize: 100)),
                    const SizedBox(height: 24),
                    Text('Lomba Eja', style: AppTheme.heading1.copyWith(color: const Color(0xFF78350F), fontSize: 36), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text(
                      'Bantu lebah menyusun kata manis dengan menyeret huruf ke kotak yang tepat!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF78350F), fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                    ),
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
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD97706),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 6,
                        ),
                        child: const Text('🍯 PILIH LEVEL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFF59E0B)],
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
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF92400E)),
                      onPressed: () {
                        setState(() {
                          _gameState = 'menu';
                        });
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Pilih Level Ejaan 🐝',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF78350F),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const AgeModeChip(),
              const SizedBox(height: 8),
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
                                clipper: HoneycombClipper(),
                                child: Container(
                                  color: isUnlocked ? const Color(0xFFD97706) : const Color(0xFF94A3B8), // Outer border color
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0), // Outer border width
                                    child: ClipPath(
                                      clipper: HoneycombClipper(),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: isUnlocked
                                              ? const LinearGradient(
                                                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)], // Honey golden gradient
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : const LinearGradient(
                                                  colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)], // Grey honeycombs
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                        ),
                                        child: Center(
                                          child: isUnlocked
                                              ? Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '$levelNum',
                                                      style: const TextStyle(
                                                        fontSize: 26,
                                                        fontWeight: FontWeight.w900,
                                                        color: Color(0xFF78350F), // warm brown text color
                                                        shadows: [
                                                          Shadow(color: Colors.white60, blurRadius: 4, offset: Offset(1, 1))
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : const Icon(Icons.lock_rounded, color: Colors.white60, size: 24),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFBBF24)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Spacer(),
              _buildWordDisplay(),
              const SizedBox(height: 20),
              // Reset Button
              IconButton(
                onPressed: _resetCurrentWord,
                icon: const Icon(Icons.refresh_rounded, size: 36, color: Color(0xFF92400E)),
                tooltip: 'Reset Kata',
              ),
              const Text('Reset', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 30),
              _buildLetterPool(),
              const Spacer(),
              _buildHint(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF92400E), size: 30),
            onPressed: () {
              AudioService().stopBGM();
              setState(() {
                _gameState = 'level_select';
              });
            },
          ),
          Column(
            children: [
              Text('Level $_currentLevel', style: const TextStyle(color: Color(0xFF78350F), fontSize: 20, fontWeight: FontWeight.w900)),
              Text('Kata ${_currentWordIndex + 1} dari ${_sessionWords.length}', style: const TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: List.generate(3, (i) => Icon(
              Icons.favorite,
              color: i < _lives ? Colors.redAccent : Colors.white24,
              size: 28,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDisplay() {
    return Column(
      children: [
        Text(_currentWordData['image'], style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 20),
        // Slot size shrinks so 8-letter words still fit on narrow phones.
        LayoutBuilder(builder: (context, constraints) {
          final n = _slots.length;
          final slotW = ((constraints.maxWidth - 8.0 * n) / n).clamp(30.0, 55.0);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(n, (i) {
              final given = _prefilled.contains(i);
              return DragTarget<Map<String, dynamic>>(
                onAcceptWithDetails: (details) => _onLetterDrop(i, details.data['letter'], details.data['index']),
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: slotW,
                    height: slotW * 1.18,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: given
                          ? const Color(0xFFFEF3C7)
                          : Colors.white.withValues(alpha: _slots[i] == null ? 0.35 : 1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _slots[i] ?? '',
                        style: TextStyle(
                          fontSize: slotW * 0.58,
                          fontWeight: FontWeight.bold,
                          color: given ? const Color(0xFFB45309).withValues(alpha: 0.6) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildLetterPool() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(_shuffledLetters.length, (i) {
        if (_shuffledLetters[i] == '') return const SizedBox(width: 50, height: 60);
        return Draggable<Map<String, dynamic>>(
          data: {'letter': _shuffledLetters[i], 'index': i},
          feedback: _buildLetterTile(_shuffledLetters[i], isDragging: true),
          childWhenDragging: Opacity(opacity: 0.3, child: _buildLetterTile(_shuffledLetters[i])),
          child: _buildLetterTile(_shuffledLetters[i]),
        );
      }),
    );
  }

  Widget _buildLetterTile(String letter, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 50,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
      child: Text(
        'Petunjuk: ${_currentWordData['hint']}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.bold),
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
            colors: [Color(0xFFFEF3C7), Color(0xFFFBBF24)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 10),
                  const Text(
                    'LEVEL SELESAI!',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
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
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24)),
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
                        foregroundColor: const Color(0xFFD97706),
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
                    child: const Text('Main Lagi 🔄', style: TextStyle(fontSize: 16, color: Color(0xFF78350F), fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _gameState = 'level_select';
                      });
                    },
                    child: const Text('Kembali ke Peta Level 🗺️', style: TextStyle(fontSize: 16, color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
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
                  'Jangan menyerah! Coba lagi dan eja katanya dengan teliti.',
                  style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      _buildStatRow('Kata Selesai', '$_correctAnswers / 3', valueColor: const Color(0xFFEF4444)),
                      const Divider(),
                      _buildStatRow('Kesalahan', '$_errors', valueColor: const Color(0xFFEF4444)),
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

  Widget _buildStatRow(String label, String value, {Color valueColor = const Color(0xFFD97706)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valueColor)),
        ],
      ),
    );
  }
}

class HoneycombClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.75);
    path.lineTo(0, size.height * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
