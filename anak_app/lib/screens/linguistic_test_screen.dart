import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/game_assessment.dart';
import '../services/assessment_engine.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';

class LinguisticTestScreen extends StatefulWidget {
  const LinguisticTestScreen({super.key});

  @override
  State<LinguisticTestScreen> createState() => _LinguisticTestScreenState();
}

class _LinguisticTestScreenState extends State<LinguisticTestScreen> with SingleTickerProviderStateMixin {
  // Game states: menu, options, playing, completed
  String gameState = 'menu';
  int currentLevel = 1;
  int score = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  int lives = 3;
  int timeLeft = 60;
  int totalQuestions = 0;
  int totalAttempts = 0;
  String language = 'id'; // 'id' or 'en'

  Map<String, dynamic> currentProblem = {};
  List<String> availableWords = [];
  String? droppedWord;
  List<int> usedQuestions = [];
  List<Map<String, dynamic>> gameSessionData = [];
  DateTime? startTime;
  Timer? _timer;

  late AnimationController _frogController;

  // ============ SOAL BAHASA INDONESIA (23 soal) ============
  final List<Map<String, dynamic>> problemsId = [
    // Level 1: Kata Kerja
    {'sentence': 'Kucing itu _ di atas kasur', 'answer': 'tidur', 'options': ['tidur', 'makan', 'berlari', 'terbang'], 'level': 1, 'domain': 'Kata Kerja', 'hint': 'Apa yang dilakukan kucing di kasur?'},
    {'sentence': 'Aku _ apel merah yang manis', 'answer': 'makan', 'options': ['makan', 'tidur', 'bermain', 'menyanyi'], 'level': 1, 'domain': 'Kata Kerja', 'hint': 'Apa yang kita lakukan dengan apel?'},
    {'sentence': 'Burung _ di langit biru', 'answer': 'terbang', 'options': ['terbang', 'berenang', 'berlari', 'tidur'], 'level': 1, 'domain': 'Kata Kerja', 'hint': 'Apa yang dilakukan burung di langit?'},
    {'sentence': 'Ikan _ di dalam air', 'answer': 'berenang', 'options': ['berenang', 'terbang', 'berlari', 'melompat'], 'level': 1, 'domain': 'Kata Kerja', 'hint': 'Apa yang dilakukan ikan di air?'},
    {'sentence': 'Anak-anak _ bola di halaman', 'answer': 'bermain', 'options': ['bermain', 'makan', 'tidur', 'belajar'], 'level': 1, 'domain': 'Kata Kerja', 'hint': 'Apa yang dilakukan dengan bola?'},
    {'sentence': 'Ayah _ mobil ke kantor', 'answer': 'mengendarai', 'options': ['mengendarai', 'membawa', 'mendorong', 'menarik'], 'level': 1, 'domain': 'Kata Kerja', 'hint': 'Apa yang dilakukan dengan mobil?'},
    {'sentence': 'Adik _ susu setiap pagi', 'answer': 'minum', 'options': ['minum', 'makan', 'bermain', 'belajar'], 'level': 1, 'domain': 'Kata Kerja', 'hint': 'Apa yang dilakukan dengan susu?'},

    // Level 2: Kata Sifat
    {'sentence': 'Gajah adalah hewan yang sangat _', 'answer': 'besar', 'options': ['besar', 'kecil', 'cepat', 'lambat'], 'level': 2, 'domain': 'Kata Sifat', 'hint': 'Bagaimana ukuran gajah?'},
    {'sentence': 'Es krim rasanya sangat _ dan manis', 'answer': 'dingin', 'options': ['dingin', 'panas', 'asam', 'pahit'], 'level': 2, 'domain': 'Kata Sifat', 'hint': 'Bagaimana suhu es krim?'},
    {'sentence': 'Matahari bersinar sangat _ hari ini', 'answer': 'terang', 'options': ['terang', 'gelap', 'dingin', 'basah'], 'level': 2, 'domain': 'Kata Sifat', 'hint': 'Bagaimana cahaya matahari?'},
    {'sentence': 'Semut adalah serangga yang sangat _', 'answer': 'kecil', 'options': ['kecil', 'besar', 'tinggi', 'gemuk'], 'level': 2, 'domain': 'Kata Sifat', 'hint': 'Bagaimana ukuran semut?'},
    {'sentence': 'Singa memiliki suara yang sangat _', 'answer': 'keras', 'options': ['keras', 'pelan', 'lembut', 'merdu'], 'level': 2, 'domain': 'Kata Sifat', 'hint': 'Bagaimana suara singa?'},
    {'sentence': 'Bunga mawar berwarna _ dan harum', 'answer': 'merah', 'options': ['merah', 'hitam', 'abu-abu', 'coklat'], 'level': 2, 'domain': 'Kata Sifat', 'hint': 'Warna apa yang umum untuk mawar?'},
    {'sentence': 'Air laut rasanya sangat _', 'answer': 'asin', 'options': ['asin', 'manis', 'asam', 'pahit'], 'level': 2, 'domain': 'Kata Sifat', 'hint': 'Bagaimana rasa air laut?'},

    // Level 3: Preposisi
    {'sentence': 'Buku ada _ atas meja', 'answer': 'di', 'options': ['di', 'ke', 'dari', 'untuk'], 'level': 3, 'domain': 'Preposisi', 'hint': 'Kata depan untuk menunjukkan tempat'},
    {'sentence': 'Kami pergi _ sekolah pagi ini', 'answer': 'ke', 'options': ['ke', 'di', 'dari', 'dengan'], 'level': 3, 'domain': 'Preposisi', 'hint': 'Kata depan untuk menunjukkan tujuan'},
    {'sentence': 'Ayah pulang _ kantor sore hari', 'answer': 'dari', 'options': ['dari', 'ke', 'di', 'untuk'], 'level': 3, 'domain': 'Preposisi', 'hint': 'Kata depan untuk menunjukkan asal'},
    {'sentence': 'Kupu-kupu hinggap _ bunga', 'answer': 'di', 'options': ['di', 'ke', 'dari', 'untuk'], 'level': 3, 'domain': 'Preposisi', 'hint': 'Kata depan untuk menunjukkan tempat'},
    {'sentence': 'Burung terbang _ langit', 'answer': 'di', 'options': ['di', 'ke', 'dari', 'untuk'], 'level': 3, 'domain': 'Preposisi', 'hint': 'Kata depan untuk menunjukkan tempat'},
    {'sentence': 'Kami berlari _ taman', 'answer': 'ke', 'options': ['ke', 'di', 'dari', 'untuk'], 'level': 3, 'domain': 'Preposisi', 'hint': 'Kata depan untuk menunjukkan tujuan'},

    // Level 4: Konjungsi
    {'sentence': 'Aku suka apel _ jeruk', 'answer': 'dan', 'options': ['dan', 'atau', 'tetapi', 'karena'], 'level': 4, 'domain': 'Konjungsi', 'hint': 'Kata penghubung untuk menambahkan'},
    {'sentence': 'Hari ini hujan _ aku tetap berangkat', 'answer': 'tetapi', 'options': ['tetapi', 'dan', 'atau', 'karena'], 'level': 4, 'domain': 'Konjungsi', 'hint': 'Kata penghubung untuk pertentangan'},
    {'sentence': 'Aku lapar _ aku akan makan', 'answer': 'karena', 'options': ['karena', 'tetapi', 'dan', 'atau'], 'level': 4, 'domain': 'Konjungsi', 'hint': 'Kata penghubung untuk menunjukkan sebab'},
  ];

  // ============ SOAL BAHASA INGGRIS (20 soal) ============
  final List<Map<String, dynamic>> problemsEn = [
    // Level 1: Verbs
    {'sentence': 'The cat _ on the bed', 'answer': 'sleeps', 'options': ['sleeps', 'eats', 'runs', 'flies'], 'level': 1, 'domain': 'Verbs', 'hint': 'What does a cat do on a bed?'},
    {'sentence': 'I _ a red apple', 'answer': 'eat', 'options': ['eat', 'sleep', 'play', 'sing'], 'level': 1, 'domain': 'Verbs', 'hint': 'What do we do with an apple?'},
    {'sentence': 'Birds _ in the sky', 'answer': 'fly', 'options': ['fly', 'swim', 'run', 'sleep'], 'level': 1, 'domain': 'Verbs', 'hint': 'What do birds do in the sky?'},
    {'sentence': 'Fish _ in the water', 'answer': 'swim', 'options': ['swim', 'fly', 'run', 'jump'], 'level': 1, 'domain': 'Verbs', 'hint': 'What do fish do in water?'},
    {'sentence': 'Children _ games in the park', 'answer': 'play', 'options': ['play', 'eat', 'sleep', 'study'], 'level': 1, 'domain': 'Verbs', 'hint': 'What do children do with games?'},
    {'sentence': 'My mom _ delicious food', 'answer': 'cooks', 'options': ['cooks', 'eats', 'sleeps', 'runs'], 'level': 1, 'domain': 'Verbs', 'hint': 'What does mom do with food?'},
    {'sentence': 'Students _ their homework', 'answer': 'do', 'options': ['do', 'eat', 'sleep', 'fly'], 'level': 1, 'domain': 'Verbs', 'hint': 'What do students do with homework?'},

    // Level 2: Adjectives
    {'sentence': 'Elephants are very _ animals', 'answer': 'big', 'options': ['big', 'small', 'fast', 'slow'], 'level': 2, 'domain': 'Adjectives', 'hint': 'What size are elephants?'},
    {'sentence': 'Ice cream is _ and sweet', 'answer': 'cold', 'options': ['cold', 'hot', 'sour', 'bitter'], 'level': 2, 'domain': 'Adjectives', 'hint': 'What temperature is ice cream?'},
    {'sentence': 'Mice are very _ animals', 'answer': 'small', 'options': ['small', 'big', 'tall', 'fat'], 'level': 2, 'domain': 'Adjectives', 'hint': 'What size are mice?'},
    {'sentence': 'Lions have a very _ voice', 'answer': 'loud', 'options': ['loud', 'quiet', 'soft', 'sweet'], 'level': 2, 'domain': 'Adjectives', 'hint': "How does a lion's voice sound?"},
    {'sentence': 'Snow is very _ and white', 'answer': 'cold', 'options': ['cold', 'hot', 'warm', 'cool'], 'level': 2, 'domain': 'Adjectives', 'hint': 'What temperature is snow?'},
    {'sentence': 'The ocean is very _ and blue', 'answer': 'deep', 'options': ['deep', 'shallow', 'narrow', 'short'], 'level': 2, 'domain': 'Adjectives', 'hint': 'How far down does the ocean go?'},

    // Level 3: Prepositions
    {'sentence': 'The book is _ the table', 'answer': 'on', 'options': ['on', 'in', 'under', 'beside'], 'level': 3, 'domain': 'Prepositions', 'hint': 'Where is the book?'},
    {'sentence': 'We go _ school every morning', 'answer': 'to', 'options': ['to', 'at', 'from', 'with'], 'level': 3, 'domain': 'Prepositions', 'hint': 'Which direction?'},
    {'sentence': 'The cat sleeps _ the bed', 'answer': 'on', 'options': ['on', 'in', 'under', 'beside'], 'level': 3, 'domain': 'Prepositions', 'hint': 'Where does the cat sleep?'},
    {'sentence': 'The ball is _ the table', 'answer': 'under', 'options': ['under', 'on', 'in', 'beside'], 'level': 3, 'domain': 'Prepositions', 'hint': 'Where is the ball?'},

    // Level 4: Conjunctions
    {'sentence': 'I like apples _ oranges', 'answer': 'and', 'options': ['and', 'or', 'but', 'because'], 'level': 4, 'domain': 'Conjunctions', 'hint': 'Word to connect two things you like'},
    {'sentence': "It's raining _ I will go outside", 'answer': 'but', 'options': ['but', 'and', 'or', 'because'], 'level': 4, 'domain': 'Conjunctions', 'hint': 'Word showing contrast'},
    {'sentence': 'Do you want juice _ water?', 'answer': 'or', 'options': ['or', 'and', 'but', 'so'], 'level': 4, 'domain': 'Conjunctions', 'hint': 'Word for giving choices'},
  ];

  List<Map<String, dynamic>> get _currentProblems => language == 'id' ? problemsId : problemsEn;

  @override
  void initState() {
    super.initState();
    _frogController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _frogController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      gameState = 'playing';
      score = 0;
      correctAnswers = 0;
      wrongAnswers = 0;
      lives = 3;
      timeLeft = 60;
      currentLevel = 1;
      totalQuestions = 0;
      totalAttempts = 0;
      usedQuestions = [];
      gameSessionData = [];
      startTime = DateTime.now();
      droppedWord = null;
    });
    _generateNewProblem();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || gameState != 'playing') {
        timer.cancel();
        return;
      }
      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          timer.cancel();
          _endGame();
        }
      });
    });
  }

  void _generateNewProblem() {
    final problems = _currentProblems;
    final levelProblems = problems.where((p) => p['level'] == currentLevel).toList();

    final available = <Map<String, dynamic>>[];
    for (int i = 0; i < levelProblems.length; i++) {
      final globalIndex = problems.indexOf(levelProblems[i]);
      if (!usedQuestions.contains(globalIndex)) {
        available.add(levelProblems[i]);
      }
    }

    if (available.isEmpty) {
      if (currentLevel < 4) {
        setState(() => currentLevel++);
        _generateNewProblem();
        return;
      } else {
        setState(() {
          usedQuestions = [];
          currentLevel = 1;
        });
        _generateNewProblem();
        return;
      }
    }

    final problem = available[math.Random().nextInt(available.length)];
    final originalIndex = problems.indexOf(problem);

    setState(() {
      usedQuestions.add(originalIndex);
      currentProblem = problem;
      availableWords = List<String>.from(problem['options'])..shuffle();
      droppedWord = null;
      totalQuestions++;
    });
  }

  void _checkAnswer(String word) {
    if (gameState != 'playing') return;
    
    final isCorrect = word == currentProblem['answer'];
    setState(() => totalAttempts++);

    setState(() {
      droppedWord = word;
      if (!isCorrect) {
        availableWords.remove(word);
      }
    });

    gameSessionData.add({
      'question': currentProblem['sentence'],
      'correctAnswer': currentProblem['answer'],
      'selectedAnswer': word,
      'isCorrect': isCorrect,
      'domain': currentProblem['domain'],
      'level': currentLevel,
      'language': language,
    });

    if (isCorrect) {
      setState(() {
        score += 10;
        correctAnswers++;
        if (correctAnswers % 3 == 0 && currentLevel < 4) {
          currentLevel++;
        }
      });
      Provider.of<AppState>(context, listen: false).addSticker('linguistic-word-master');
      AudioService().playSFX('success.mp3');
      
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted || gameState != 'playing') return;
        _generateNewProblem();
      });
    } else {
      setState(() {
        wrongAnswers++;
        lives--;
      });
      AudioService().playSFX('wrong.mp3');
      
      if (lives <= 0) {
        Future.delayed(const Duration(milliseconds: 1000), _endGame);
      } else {
        // Allow another try for the same question
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() => droppedWord = null);
        });
      }
    }
  }


  void _endGame() {
    _timer?.cancel();
    setState(() => gameState = 'completed');

    final appState = Provider.of<AppState>(context, listen: false);
    // Modified accuracy: (Correct / Total Attempts) to be more strict
    final accuracy = totalAttempts > 0 ? ((correctAnswers / totalAttempts) * 100).round() : 0;
    final totalTime = startTime != null ? DateTime.now().difference(startTime!).inSeconds : 60;

    // Domain analysis
    final Map<String, Map<String, int>> domainAnalysis = {};
    for (final session in gameSessionData) {
      final domain = session['domain'] as String;
      domainAnalysis.putIfAbsent(domain, () => {'correct': 0, 'total': 0});
      domainAnalysis[domain]!['total'] = (domainAnalysis[domain]!['total'] ?? 0) + 1;
      if (session['isCorrect'] == true) {
        domainAnalysis[domain]!['correct'] = (domainAnalysis[domain]!['correct'] ?? 0) + 1;
      }
    }

    appState.updateTestResults('linguistic', {
      'score': correctAnswers,
      'total': totalQuestions,
      'percentage': accuracy,
      'timeSpent': totalTime,
      'gameMode': 'Ocean Word Adventure',
      'language': language,
      'level': currentLevel,
      'categoryScores': {
        'receptive': ((accuracy / 100) * 25).round(),
        'expressive': ((correctAnswers / math.max(totalQuestions, 1)) * 25).round(),
        'phonemic': ((currentLevel / 4) * 25).round(),
      },
      'domainAnalysis': domainAnalysis,
      'detailedResults': {
        'accuracy': accuracy,
        'levelReached': currentLevel,
        'languageTested': language == 'id' ? 'Bahasa Indonesia' : 'English',
      },
    });

    final int avgRespMs = totalQuestions > 0 ? ((totalTime * 1000) / totalQuestions).round() : 0;
    final double assessScore = AssessmentEngine.calculateGameScore(
      totalItems: totalQuestions,
      correct: correctAnswers,
      avgResponseMs: avgRespMs,
      idealTimeMs: 7000, 
      maxLevel: currentLevel,
      totalLevels: 4,
      hintsUsed: 0,
      errors: wrongAnswers,
    );

    appState.updateGameAssessment('linguisticGame', GameSession(
      score: accuracy.toInt(),
      timeSpent: totalTime,
      errors: wrongAnswers,
      totalItems: totalQuestions,
      correctAnswers: correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'totalAttempts': totalAttempts,
        'domainAnalysis': domainAnalysis,
      },
      subdomainScores: {
        'receptiveLanguage': assessScore,
        'expressiveLanguage': (accuracy / 100.0) * 80.0,
      },
    ));

    appState.addPointsFromScore(accuracy.toInt());
    // Award stickers based on performance
    if (accuracy >= 90) appState.addSticker('linguistic-expert');
    if (correctAnswers >= 10) appState.addSticker('word-master');
    if (currentLevel >= 4) appState.addSticker('grammar-champion');
    appState.addSticker('linguistic-test-complete');
  }

  String _getAgeGroup(int age) {
    if (age >= 5 && age <= 7) return 'early';
    if (age >= 8 && age <= 10) return 'middle';
    return 'late';
  }

  final Map<String, List<Map<String, dynamic>>> _parentTips = {
    'early': [
      {'title': 'Membaca Nyaring (Read Aloud)', 'desc': 'Bacakan cerita anak dengan intonasi menarik. Berhenti sejenak dan tanyakan "apa yang terjadi selanjutnya?".', 'icon': '📚', 'diff': 'Mudah'},
      {'title': 'Tebak Hewan/Benda', 'desc': 'Sebutkan 3 ciri-ciri benda atau hewan, minta anak menebak nama dan huruf depannya.', 'icon': '🦁', 'diff': 'Sedang'},
      {'title': 'Bernyanyi Rima', 'desc': 'Nyanyikan lagu anak-anak yang memiliki rima berulang untuk melatih fonologi dasar.', 'icon': '🎵', 'diff': 'Mudah'},
    ],
    'middle': [
      {'title': 'Scrabble Modifikasi', 'desc': 'Mainkan Scrabble tanpa perhitungan poin rumit, fokus murni pada perluasan kosakata.', 'icon': '🔠', 'diff': 'Sedang'},
      {'title': 'Jurnal Harian Sederhana', 'desc': 'Ajak anak menulis 3 kalimat setiap malam tentang apa yang paling membuatnya senang hari itu.', 'icon': '📝', 'diff': 'Menantang'},
      {'title': 'Permainan Rantai Kata', 'desc': 'Sebut satu kata, anak harus menyebut kata baru yang berawalan dari huruf terakhir kata Anda.', 'icon': '🔗', 'diff': 'Sedang'},
    ],
    'late': [
      {'title': 'Debat Ringan Keluarga', 'desc': 'Lemparkan opsi sederhana (misal: "Sekolah dari rumah vs di kelas") dan latih ia memberikan argumen penunjang.', 'icon': '🗣️', 'diff': 'Menantang'},
      {'title': 'Review Film/Kisah', 'desc': 'Setelah menonton layar lebar, minta anak menceritakan kembali plot film menurut sudut pandangnya.', 'icon': '🎬', 'diff': 'Menantang'},
      {'title': 'Eksplorasi Sinonim', 'desc': 'Saat berbicara, gunakan kata yang sedikit puitis dan minta anak menebak padanan kata sederhananya.', 'icon': '⚖️', 'diff': 'Sedang'},
    ]
  };

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isParentMode = appState.isParentMode;

    if (isParentMode) {
      return _buildParentMode(context, appState.childProfile.age);
    }

    switch (gameState) {
      case 'menu':
        return _buildMenu();
      case 'options':
        return _buildOptions();
      case 'playing':
        return _buildPlaying();
      case 'completed':
        return _buildCompleted();
      default:
        return _buildMenu();
    }
  }

  Widget _buildParentMode(BuildContext context, int childAge) {
    final ageGroup = _getAgeGroup(childAge);
    final tipsList = _parentTips[ageGroup] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFF97316),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFDBA74), Color(0xFFF97316)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: const Text('📝', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Panduan Linguistik (Usia $childAge)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Stimulasi verbal dan baca-tulis.', style: TextStyle(color: Colors.orange.shade50, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              title: const Text('Modul Linguistik (Orang Tua)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.deepOrange),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Mode Orang Tua aktif. Matikan mode ini dari menu profil untuk membiarkan anak mengakses kuis linguistik.', style: TextStyle(color: Colors.deepOrange, fontSize: 12))),
                      ],
                    ),
                  ),

                  const Text('Aktivitas Rekomendasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  ...tipsList.map((tip) {
                    final isHard = tip['diff'] == 'Menantang';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.orange.shade300]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(child: Text(tip['icon'], style: const TextStyle(fontSize: 28))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(tip['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: isHard ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text(tip['diff'], style: TextStyle(color: isHard ? Colors.red.shade700 : Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(tip['desc'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildMenu() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF67E8F9), Color(0xFF60A5FA), Color(0xFF2563EB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Hero Section
                _buildHeroHeader(
                  'Asah Kemampuan\nLinguistik! 📖',
                  'Mari berpetualang di dunia kata dan asah kemampuan bahasamu dengan permainan seru!',
                ),
                
                const SizedBox(height: 32),

                _buildNavCard('🐸', '1. Petualangan Kata', 'Seret kata yang tepat untuk melengkapi kalimat', () => setState(() => gameState = 'options')),
                _buildNavCard('📝', '2. Teka-Teki Kata', 'Susun huruf menjadi kata yang benar dengan petunjuk gambar', () => Navigator.pushNamed(context, '/word-puzzle-game')),
                _buildNavCard('📖', '3. Story Builder', 'Susun kata-kata menjadi kalimat yang benar dan sempurna', () => Navigator.pushNamed(context, '/story-builder-game')),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNavCard(String icon, String title, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(icon, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), height: 1.2)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.5), size: 28),
          ],
        ),
      ),
    );
  }

  // ==================== OPTIONS SCREEN ====================
  Widget _buildOptions() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF67E8F9), Color(0xFF60A5FA), Color(0xFF2563EB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => gameState = 'menu'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    Expanded(child: Text('Petualangan Kata', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text('🐸', style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 16),
                      Text('Petualangan Kata di Lautan!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Seret kata yang tepat untuk melengkapi kalimat dan bantu kodok mencapai tujuan!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: const Color(0xFFCFFAFE))),
                      const SizedBox(height: 24),

                      // Language Selection
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text('Pilih Bahasa:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildLangButton('🇮🇩 Bahasa Indonesia', 'id')),
                                const SizedBox(width: 12),
                                Expanded(child: _buildLangButton('🇺🇸 English', 'en')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cara Bermain:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            _buildInstructionRow(Icons.gps_fixed, const Color(0xFF06B6D4), 'Seret kata ke tempat yang kosong'),
                            const SizedBox(height: 12),
                            _buildInstructionRow(Icons.timer, const Color(0xFF3B82F6), 'Selesaikan dalam 60 detik'),
                            const SizedBox(height: 12),
                            _buildInstructionRow(Icons.trending_up, const Color(0xFFA855F7), 'Naik level setiap 3 jawaban benar'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                          ),
                          onPressed: _startGame,
                          child: Text('🌊 Mulai Petualangan!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildLangButton(String label, String lang) {
    final isSelected = language == lang;
    return GestureDetector(
      onTap: () => setState(() => language = lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2563EB) : Colors.white)),
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Container(
height: 36,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: const Color(0xFFCFFAFE)))),
      ],
    );
  }

  // ==================== PLAYING SCREEN ====================
  Widget _buildPlaying() {
    String qText = currentProblem['sentence'] ?? '';
    List<String> parts = qText.split('_');
    int accuracyPct = totalQuestions > 0 ? ((correctAnswers / totalQuestions) * 100).round() : 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF67E8F9), Color(0xFF60A5FA), Color(0xFF2563EB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium HUD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _timer?.cancel();
                          setState(() => gameState = 'menu');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                      // Lives
                      Row(
                        children: List.generate(3, (i) => Icon(
                          Icons.favorite,
                          color: i < lives ? Colors.redAccent : Colors.white24,
                          size: 20,
                        )),
                      ),
                      _buildHUDStat(Icons.timer_rounded, '$timeLeft', 'Detik'),
                      _buildHUDStat(Icons.stars_rounded, '$currentLevel', 'Level'),
                      _buildHUDStat(Icons.trending_up_rounded, '$accuracyPct%', 'Akurasi'),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Frog Area
                      AnimatedBuilder(
                        animation: _frogController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -10 * _frogController.value),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 180, height: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const Text('🐸', style: TextStyle(fontSize: 100)),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Sentence Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))
                            ],
                          ),
                          child: Column(
                            children: [
                              if (currentProblem['domain'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                                  child: Text(currentProblem['domain'].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF3B82F6))),
                                ),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8, runSpacing: 12,
                                children: _buildSentenceWidgets(parts),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Word Selection Bubbles
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -10))],
                ),
                child: Column(
                  children: [
                    Text(
                      'Ketuk kata yang tepat! ✨',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: (currentProblem['options'] is List ? currentProblem['options'] as List : []).map((choice) {
                        final word = choice.toString();
                        return Draggable<String>(
                          data: word,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))
                                ],
                              ),
                              child: Text(
                                word,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, decoration: TextDecoration.none),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                word,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Text(
                              word,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildHUDStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }

  List<Widget> _buildSentenceWidgets(List<String> parts) {
    List<Widget> widgets = [];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        widgets.add(Text(parts[i], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))));
      }
      if (i < parts.length - 1) {
        widgets.add(
          DragTarget<String>(
            onAcceptWithDetails: (details) {
              _checkAnswer(details.data);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isHovering ? const Color(0xFFDBEAFE) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHovering ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE), 
                    width: isHovering ? 2.5 : 1.5
                  ),
                ),
                child: Text(
                  droppedWord ?? '____',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    color: isHovering ? const Color(0xFF1E40AF) : const Color(0xFF3B82F6)
                  ),
                ),
              );
            },
          ),
        );
      }
    }
    return widgets;
  }

  // ==================== COMPLETED SCREEN ====================
  Widget _buildCompleted() {
    final accuracy = totalQuestions > 0 ? ((correctAnswers / totalQuestions) * 100).round() : 0;
    final receptiveScore = ((accuracy / 100) * 25).round();
    final expressiveScore = ((correctAnswers / math.max(totalQuestions, 1)) * 25).round();
    final adaptScore = ((currentLevel / 4) * 25).round();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF67E8F9), Color(0xFF60A5FA), Color(0xFF2563EB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text('🏆', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                Text(
                  'Petualangan Selesai!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 24),

                // Stats Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // 4-stat grid
                      Row(
                        children: [
                          _buildStatBox('$correctAnswers', 'Kata Benar'),
                          _buildStatBox('$accuracy%', 'Akurasi'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatBox('$currentLevel', 'Level Tertinggi'),
                          _buildStatBox('$score', 'Total Skor'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Skill Analysis
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Analisis Kemampuan:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      _buildSkillRow('Pemahaman Kata', receptiveScore, 25),
                      const SizedBox(height: 8),
                      _buildSkillRow('Tata Bahasa', expressiveScore, 25),
                      const SizedBox(height: 8),
                      _buildSkillRow('Kemampuan Adaptasi', adaptScore, 25),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFFCFFAFE))),
                          Text('Bahasa: ${language == 'id' ? 'Bahasa Indonesia' : 'English'}', style: TextStyle(fontSize: 14, color: const Color(0xFFCFFAFE))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Feedback
                      _buildFeedbackBanner(accuracy),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => setState(() => gameState = 'menu'),
                    child: Text('🔄 Main Lagi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/progress'),
                    child: Text('📊 Lihat Progress Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: const Color(0xFFCFFAFE))),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String label, int score, int maxScore) {
    return Row(
      children: [
        const Text('• ', style: TextStyle(color: Color(0xFFCFFAFE))),
        Expanded(child: Text('$label: $score/$maxScore', style: TextStyle(fontSize: 14, color: const Color(0xFFCFFAFE)))),
      ],
    );
  }

  Widget _buildFeedbackBanner(int accuracy) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    String message;

    if (accuracy >= 90) {
      bgColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green.withOpacity(0.3);
      textColor = const Color(0xFFBBF7D0);
      message = '🌟 Excellent! Kemampuan bahasamu sangat baik!';
    } else if (accuracy >= 70) {
      bgColor = Colors.blue.withOpacity(0.2);
      borderColor = Colors.blue.withOpacity(0.3);
      textColor = const Color(0xFFBFDBFE);
      message = '👍 Good! Terus latih kemampuan bahasamu!';
    } else {
      bgColor = Colors.purple.withOpacity(0.2);
      borderColor = Colors.purple.withOpacity(0.3);
      textColor = const Color(0xFFE9D5FF);
      message = '💪 Keep practicing! Kemampuan bahasamu akan terus berkembang!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}
