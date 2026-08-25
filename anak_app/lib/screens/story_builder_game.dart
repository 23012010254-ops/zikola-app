import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/assessment_engine.dart';
import '../models/game_assessment.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class StoryProblem {
  final List<String> words;
  final List<int> correctOrder;
  final String correctSentence;
  final String hint;
  final int level;
  final String domain;
  final String emoji;

  StoryProblem({
    required this.words,
    required this.correctOrder,
    required this.correctSentence,
    required this.hint,
    required this.level,
    required this.domain,
    required this.emoji,
  });
}

class StoryBuilderGame extends StatefulWidget {
  const StoryBuilderGame({super.key});

  @override
  State<StoryBuilderGame> createState() => _StoryBuilderGameState();
}

class _StoryBuilderGameState extends State<StoryBuilderGame> with TickerProviderStateMixin {
  int _lives = 3;
  
  StoryProblem? _currentProblem;
  List<String> _selectedWords = [];
  List<String> _availableWords = [];
  
  DateTime? _startTime;
  int _totalQuestions = 0;
  List<Map<String, dynamic>> _gameSessionData = [];
  List<int> _usedQuestions = [];
  
  Map<String, dynamic>? _feedback; // { show: bool, isCorrect: bool, correctAnswer: String }
  
  Timer? _timer;
  final Random _random = Random();
  
  String _gameState = 'menu'; // 'menu', 'level_select', 'playing', 'level_complete', 'game_over', 'completed'
  String _language = 'id';
  int _correctAnswers = 0;
  int _score = 0;
  int _wrongAnswers = 0;
  int _timeLeft = 90;
  int _currentLevel = 1;
  int _highestUnlocked = 1;
  final List<int> _starRatings = List.filled(8, 0);
  int _levelCorrectAnswers = 0;

  late PageController _pageController;
  late AnimationController _bgFloatCtrl;

  final Map<String, List<Map<String, dynamic>>> _storyProblemsRaw = {
    'id': [
      // Level 1
      {'words': ['makan', 'Saya', 'nasi'], 'correctOrder': [1, 0, 2], 'correctSentence': 'Saya makan nasi', 'hint': 'Mulai dengan siapa yang melakukan', 'level': 1, 'domain': 'Struktur Kalimat', 'emoji': '🍚'},
      {'words': ['bermain', 'Adik', 'bola'], 'correctOrder': [1, 0, 2], 'correctSentence': 'Adik bermain bola', 'hint': 'Siapa + apa yang dilakukan + objek', 'level': 1, 'domain': 'Struktur Kalimat', 'emoji': '⚽'},
      {'words': ['membaca', 'Ibu', 'buku'], 'correctOrder': [1, 0, 2], 'correctSentence': 'Ibu membaca buku', 'hint': 'Mulai dengan subjeknya', 'level': 1, 'domain': 'Struktur Kalimat', 'emoji': '📚'},
      {'words': ['minum', 'Adik', 'susu'], 'correctOrder': [1, 0, 2], 'correctSentence': 'Adik minum susu', 'hint': 'Siapa yang haus?', 'level': 1, 'domain': 'Struktur Kalimat', 'emoji': '🥛'},
      // Level 2
      {'words': ['di', 'Kucing', 'tidur', 'kursi'], 'correctOrder': [1, 2, 0, 3], 'correctSentence': 'Kucing tidur di kursi', 'hint': 'Subjek + kata kerja + lokasi', 'level': 2, 'domain': 'Kalimat Lengkap', 'emoji': '🐱'},
      {'words': ['di', 'Burung', 'terbang', 'langit'], 'correctOrder': [1, 2, 0, 3], 'correctSentence': 'Burung terbang di langit', 'hint': 'Lokasi diletakkan di akhir', 'level': 2, 'domain': 'Kalimat Lengkap', 'emoji': '🐦'},
      {'words': ['dengan', 'Kami', 'bermain', 'senang'], 'correctOrder': [1, 2, 0, 3], 'correctSentence': 'Kami bermain dengan senang', 'hint': 'Gunakan kata keterangan perasaan', 'level': 2, 'domain': 'Kalimat Lengkap', 'emoji': '😊'},
      // Level 3
      {'words': ['Ayah', 'mobil', 'ke', 'menyetir', 'mal'], 'correctOrder': [0, 3, 1, 2, 4], 'correctSentence': 'Ayah menyetir mobil ke mal', 'hint': 'Subjek + kerja + objek + tujuan', 'level': 3, 'domain': 'Kalimat Lengkap', 'emoji': '🚗'},
      {'words': ['sangat', 'Bunga', 'itu', 'merah', 'harum'], 'correctOrder': [1, 3, 2, 0, 4], 'correctSentence': 'Bunga merah itu sangat harum', 'hint': 'Sifat benda diletakkan di akhir', 'level': 3, 'domain': 'Kalimat Lengkap', 'emoji': '🌹'},
      {'words': ['di', 'Kupu-kupu', 'terbang', 'taman', 'bunga'], 'correctOrder': [1, 2, 0, 3, 4], 'correctSentence': 'Kupu-kupu terbang di taman bunga', 'hint': 'Subjek + kerja + lokasi spesifik', 'level': 3, 'domain': 'Kalimat Lengkap', 'emoji': '🦋'},
      // Level 4
      {'words': ['karena', 'senang', 'Aku', 'lomba', 'menang'], 'correctOrder': [2, 1, 0, 4, 3], 'correctSentence': 'Aku senang karena menang lomba', 'hint': 'Hubungkan alasan dengan "karena"', 'level': 4, 'domain': 'Kalimat Kompleks', 'emoji': '🏆'},
      {'words': ['panjang', 'Gajah', 'sangat', 'yang', 'belalai', 'memiliki'], 'correctOrder': [1, 5, 4, 3, 2, 0], 'correctSentence': 'Gajah memiliki belalai yang sangat panjang', 'hint': 'Deskripsikan fisik gajah', 'level': 4, 'domain': 'Kalimat Kompleks', 'emoji': '🐘'},
      {'words': ['masak', 'Ibu', 'sambil', 'di', 'dapur', 'bernyanyi'], 'correctOrder': [1, 0, 3, 4, 2, 5], 'correctSentence': 'Ibu masak di dapur sambil bernyanyi', 'hint': 'Dua kegiatan sekaligus', 'level': 4, 'domain': 'Kalimat Kompleks', 'emoji': '🍳'},
      // Level 5
      {'words': ['menyapu', 'Setiap', 'pagi', 'saya', 'ibu', 'membantu', 'lantai'], 'correctOrder': [1, 2, 3, 5, 4, 0, 6], 'correctSentence': 'Setiap pagi saya membantu ibu menyapu lantai', 'hint': 'Keterangan waktu diletakkan di awal', 'level': 5, 'domain': 'Keterangan Waktu', 'emoji': '🧹'},
      {'words': ['kecil', 'Kucing', 'itu', 'suka', 'mengejar', 'putih', 'tikus'], 'correctOrder': [1, 5, 2, 3, 4, 6, 0], 'correctSentence': 'Kucing putih itu suka mengejar tikus kecil', 'hint': 'Subjek + sifat + kesukaan + objek', 'level': 5, 'domain': 'Keterangan Waktu', 'emoji': '🐭'},
      {'words': ['belajar', 'Kakak', 'matematika', 'giat', 'dengan', 'di', 'kamar'], 'correctOrder': [1, 0, 2, 4, 3, 5, 6], 'correctSentence': 'Kakak belajar matematika dengan giat di kamar', 'hint': 'Siapa + apa + bagaimana + di mana', 'level': 5, 'domain': 'Keterangan Waktu', 'emoji': '📝'},
      // Level 6
      {'words': ['kantor', 'Ayah', 'pulang', 'dari', 'membawa', 'buah', 'tangan', 'manis'], 'correctOrder': [1, 2, 3, 0, 4, 5, 6, 7], 'correctSentence': 'Ayah pulang dari kantor membawa buah tangan manis', 'hint': 'Subjek + asal + membawa sesuatu', 'level': 6, 'domain': 'Struktur Kalimat Majemuk', 'emoji': '🎁'},
      {'words': ['bernyanyi', 'Burung', 'pipit', 'dengan', 'sangat', 'merdu', 'sekali'], 'correctOrder': [1, 2, 0, 3, 4, 5, 6], 'correctSentence': 'Burung pipit bernyanyi dengan sangat merdu sekali', 'hint': 'Burung + bernyanyi + kualitas suara', 'level': 6, 'domain': 'Struktur Kalimat Majemuk', 'emoji': '🎶'},
      {'words': ['menggambar', 'Adik', 'senang', 'pemandangan', 'gunung', 'yang', 'indah'], 'correctOrder': [1, 2, 0, 3, 4, 5, 6], 'correctSentence': 'Adik senang menggambar pemandangan gunung yang indah', 'hint': 'Siapa + perasaan + menggambar apa', 'level': 6, 'domain': 'Struktur Kalimat Majemuk', 'emoji': '🎨'},
      // Level 7
      {'words': ['pantai', 'Kemarin', 'sore', 'kami', 'sekeluarga', 'pergi', 'piknik', 'ke'], 'correctOrder': [1, 2, 3, 4, 5, 6, 7, 0], 'correctSentence': 'Kemarin sore kami sekeluarga pergi piknik ke pantai', 'hint': 'Keterangan waktu + subjek majemuk + tujuan', 'level': 7, 'domain': 'Narasi Lengkap', 'emoji': '🏖️'},
      {'words': ['menyiram', 'Kakak', 'tanaman', 'hias', 'di', 'halaman', 'rumah', 'sore', 'hari'], 'correctOrder': [1, 0, 2, 3, 4, 5, 6, 7, 8], 'correctSentence': 'Kakak menyiram tanaman hias di halaman rumah sore hari', 'hint': 'Siapa + menyiram apa + di mana + kapan', 'level': 7, 'domain': 'Narasi Lengkap', 'emoji': '🪴'},
      {'words': ['mengerjakan', 'Siswa', 'kelas', 'lima', 'sedang', 'ujian', 'dengan', 'sangat', 'tenang'], 'correctOrder': [1, 2, 3, 4, 0, 5, 6, 7, 8], 'correctSentence': 'Siswa kelas lima sedang mengerjakan ujian dengan sangat tenang', 'hint': 'Subjek + sedang melakukan apa + keterangan', 'level': 7, 'domain': 'Narasi Lengkap', 'emoji': '✍️'},
      // Level 8
      {'words': ['sarapan', 'Ibu', 'memasak', 'nasi', 'goreng', 'spesial', 'untuk', 'kami', 'sekeluarga'], 'correctOrder': [1, 2, 3, 4, 5, 6, 0, 7, 8], 'correctSentence': 'Ibu memasak nasi goreng spesial untuk sarapan kami sekeluarga', 'hint': 'Siapa + memasak apa + untuk tujuan apa', 'level': 8, 'domain': 'Narasi Kompleks', 'emoji': '🍳'},
      {'words': ['perpus', 'Buku', 'cerita', 'yang', 'dipinjam', 'dari', 'perpustakaan', 'sangat', 'seru', 'dibaca'], 'correctOrder': [1, 2, 3, 4, 5, 6, 7, 8, 9], 'correctSentence': 'Buku cerita yang dipinjam dari perpustakaan sangat seru dibaca', 'hint': 'Buku apa + dari mana + rasanya bagaimana', 'level': 8, 'domain': 'Narasi Kompleks', 'emoji': '📚'},
      {'words': ['pacu', 'Pesawat', 'terbang', 'meluncur', 'dengan', 'sangat', 'cepat', 'di', 'landasan'], 'correctOrder': [1, 2, 3, 4, 5, 6, 7, 8, 0], 'correctSentence': 'Pesawat terbang meluncur dengan sangat cepat di landasan pacu', 'hint': 'Apa + meluncur + bagaimana + di mana', 'level': 8, 'domain': 'Narasi Kompleks', 'emoji': '✈️'},
    ],
    'en': [
      // Level 1
      {'words': ['eat', 'I', 'rice'], 'correctOrder': [1, 0, 2], 'correctSentence': 'I eat rice', 'hint': 'Who is doing the action?', 'level': 1, 'domain': 'Sentence Structure', 'emoji': '🍚'},
      {'words': ['plays', 'Boy', 'ball'], 'correctOrder': [1, 0, 2], 'correctSentence': 'Boy plays ball', 'hint': 'Subject + verb + object', 'level': 1, 'domain': 'Sentence Structure', 'emoji': '⚽'},
      {'words': ['book', 'reads', 'Teacher'], 'correctOrder': [2, 1, 0], 'correctSentence': 'Teacher reads book', 'hint': 'Start with the person', 'level': 1, 'domain': 'Sentence Structure', 'emoji': '📚'},
      {'words': ['milk', 'drinks', 'Cat'], 'correctOrder': [2, 1, 0], 'correctSentence': 'Cat drinks milk', 'hint': 'Who is drinking?', 'level': 1, 'domain': 'Sentence Structure', 'emoji': '🥛'},
      // Level 2
      {'words': ['drinks', 'The', 'cat', 'milk'], 'correctOrder': [1, 2, 0, 3], 'correctSentence': 'The cat drinks milk', 'hint': 'Subject + action + target', 'level': 2, 'domain': 'Simple Sentence', 'emoji': '🐱'},
      {'words': ['loudly', 'The', 'dog', 'barks'], 'correctOrder': [1, 2, 3, 0], 'correctSentence': 'The dog barks loudly', 'hint': 'Subject + verb + description', 'level': 2, 'domain': 'Simple Sentence', 'emoji': '🐕'},
      {'words': ['in', 'Birds', 'fly', 'sky'], 'correctOrder': [1, 2, 0, 3], 'correctSentence': 'Birds fly in sky', 'hint': 'Subject + verb + location', 'level': 2, 'domain': 'Simple Sentence', 'emoji': '🐦'},
      // Level 3
      {'words': ['play', 'We', 'with', 'joy'], 'correctOrder': [1, 0, 2, 3], 'correctSentence': 'We play with joy', 'hint': 'Who + action + how', 'level': 3, 'domain': 'Prepositional Phrase', 'emoji': '😊'},
      {'words': ['car', 'Father', 'drives', 'red'], 'correctOrder': [1, 2, 3, 0], 'correctSentence': 'Father drives red car', 'hint': 'Subject + action + color + object', 'level': 3, 'domain': 'Prepositional Phrase', 'emoji': '🚗'},
      {'words': ['song', 'She', 'sings', 'sweet'], 'correctOrder': [1, 2, 3, 0], 'correctSentence': 'She sings sweet song', 'hint': 'Subject + action + description + object', 'level': 3, 'domain': 'Prepositional Phrase', 'emoji': '🎵'},
      // Level 4
      {'words': ['yesterday', 'He', 'went', 'to', 'the', 'zoo'], 'correctOrder': [1, 2, 3, 4, 5, 0], 'correctSentence': 'He went to the zoo yesterday', 'hint': 'Time description is at the end', 'level': 4, 'domain': 'Keterangan Waktu', 'emoji': '🦁'},
      {'words': ['eat', 'I', 'like', 'to', 'chocolate', 'ice', 'cream'], 'correctOrder': [1, 2, 3, 0, 4, 5, 6], 'correctSentence': 'I like to eat chocolate ice cream', 'hint': 'I like + action + food type', 'level': 4, 'domain': 'Keterangan Waktu', 'emoji': '🍦'},
      {'words': ['high', 'The', 'green', 'frog', 'jumps', 'very'], 'correctOrder': [1, 2, 3, 4, 5, 0], 'correctSentence': 'The green frog jumps very high', 'hint': 'Subject + description + action + height', 'level': 4, 'domain': 'Keterangan Waktu', 'emoji': '🐸'},
      // Level 5
      {'words': ['in', 'My', 'brother', 'plays', 'soccer', 'the', 'afternoon'], 'correctOrder': [1, 2, 3, 4, 0, 5, 6], 'correctSentence': 'My brother plays soccer in the afternoon', 'hint': 'Who + action + sports + time', 'level': 5, 'domain': 'Complex Sentence', 'emoji': '⚽'},
      {'words': ['study', 'They', 'science', 'in', 'the', 'classroom', 'today'], 'correctOrder': [1, 0, 2, 3, 4, 5, 6], 'correctSentence': 'They study science in the classroom today', 'hint': 'Subject + study what + where + when', 'level': 5, 'domain': 'Complex Sentence', 'emoji': '🧪'},
      {'words': ['elephant', 'The', 'big', 'has', 'a', 'long', 'trunk'], 'correctOrder': [1, 2, 0, 3, 4, 5, 6], 'correctSentence': 'The big elephant has a long trunk', 'hint': 'Subject + size + has + property', 'level': 5, 'domain': 'Complex Sentence', 'emoji': '🐘'},
      // Level 6
      {'words': ['hands', 'We', 'must', 'wash', 'our', 'before', 'eating', 'food'], 'correctOrder': [1, 2, 3, 4, 0, 5, 6, 7], 'correctSentence': 'We must wash our hands before eating food', 'hint': 'Advice + action + when', 'level': 6, 'domain': 'Modal Sentence', 'emoji': '🧼'},
      {'words': ['story', 'She', 'wrote', 'a', 'beautiful', 'about', 'her', 'dog'], 'correctOrder': [1, 2, 3, 4, 0, 5, 6, 7], 'correctSentence': 'She wrote a beautiful story about her dog', 'hint': 'Who + action + writing type + topic', 'level': 6, 'domain': 'Modal Sentence', 'emoji': '📝'},
      {'words': ['dinner', 'My', 'mother', 'cooks', 'delicious', 'for', 'us', 'today'], 'correctOrder': [1, 2, 3, 4, 0, 5, 6, 7], 'correctSentence': 'My mother cooks delicious dinner for us today', 'hint': 'Who + action + food + for whom + when', 'level': 6, 'domain': 'Modal Sentence', 'emoji': '🥘'},
      // Level 7
      {'words': ['books', 'The', 'students', 'read', 'history', 'in', 'the', 'library'], 'correctOrder': [1, 2, 3, 4, 0, 5, 6, 7], 'correctSentence': 'The students read history books in the library', 'hint': 'Subject + action + books + where', 'level': 7, 'domain': 'Complex Phrase', 'emoji': '📖'},
      {'words': ['outside', 'He', 'lost', 'his', 'black', 'keys', 'while', 'playing'], 'correctOrder': [1, 2, 3, 4, 5, 6, 7, 0], 'correctSentence': 'He lost his black keys while playing outside', 'hint': 'Action + what was lost + when', 'level': 7, 'domain': 'Complex Phrase', 'emoji': '🔑'},
      {'words': ['yesterday', 'The', 'little', 'girl', 'wore', 'a', 'pretty', 'dress'], 'correctOrder': [1, 2, 3, 4, 5, 6, 7, 0], 'correctSentence': 'The little girl wore a pretty dress yesterday', 'hint': 'Subject + verb + object description + time', 'level': 7, 'domain': 'Complex Phrase', 'emoji': '👗'},
      // Level 8
      {'words': ['present', 'Grandfather', 'bought', 'a', 'new', 'bicycle', 'for', 'my', 'birthday'], 'correctOrder': [1, 2, 3, 4, 5, 6, 7, 8, 0], 'correctSentence': 'Grandfather bought a new bicycle for my birthday present', 'hint': 'Subject + action + object + purpose', 'level': 8, 'domain': 'Advanced Narrative', 'emoji': '🚲'},
      {'words': ['useful', 'Learning', 'a', 'new', 'language', 'is', 'very', 'for', 'everyone'], 'correctOrder': [1, 2, 3, 4, 5, 6, 0, 7, 8], 'correctSentence': 'Learning a new language is very useful for everyone', 'hint': 'Subject + is + property + for whom', 'level': 8, 'domain': 'Advanced Narrative', 'emoji': '🗣️'},
      {'words': ['sun', 'Eight', 'planets', 'in', 'solar', 'system', 'move', 'around', 'the'], 'correctOrder': [1, 2, 3, 4, 5, 6, 7, 8, 0], 'correctSentence': 'Eight planets in solar system move around the sun', 'hint': 'Subject + location + action + target', 'level': 8, 'domain': 'Advanced Narrative', 'emoji': '🪐'},
    ]
  };



  @override
  void initState() {
    super.initState();
    _bgFloatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _pageController = PageController();
    _gameState = 'menu';
  }

  @override
  void dispose() {
    AudioService().stopBGM();
    _bgFloatCtrl.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameState = 'level_select';
    });
  }

  void _startLevel(int level) {
    setState(() {
      _gameState = 'playing';
      _score = 0;
      _lives = 3;
      _correctAnswers = 0;
      _levelCorrectAnswers = 0;
      _wrongAnswers = 0;
      _timeLeft = 90;
      _currentLevel = level;
      _startTime = DateTime.now();
      _totalQuestions = 0;
      _gameSessionData = [];
      _selectedWords = [];
      _usedQuestions = [];
      _feedback = null;
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
          _endGame();
        }
      }
    });
  }

  void _generateNewProblem() {
    var languageProblems = _storyProblemsRaw[_language]!;
    
    List<StoryProblem> problems = languageProblems.map((p) => StoryProblem(
      words: List<String>.from(p['words']),
      correctOrder: List<int>.from(p['correctOrder'] ?? []),
      correctSentence: p['correctSentence'],
      hint: p['hint'],
      level: p['level'],
      domain: p['domain'],
      emoji: p['emoji'],
    )).toList();

    List<StoryProblem> levelProblems = problems.where((p) => p.level == _currentLevel).toList();
    
    List<StoryProblem> availableProblems = levelProblems.where((p) {
      int globalIndex = problems.indexOf(p);
      return !_usedQuestions.contains(globalIndex);
    }).toList();

    if (availableProblems.isEmpty) {
      // If we run out of questions in this level session, reset and reuse them
      setState(() {
        _usedQuestions.clear();
      });
      _generateNewProblem();
      return;
    }

    StoryProblem problem = availableProblems[_random.nextInt(availableProblems.length)];
    int originalIndex = problems.indexOf(problem);

    setState(() {
      _usedQuestions.add(originalIndex);
      _currentProblem = problem;
      
      List<String> shuffled = List<String>.from(problem.words)..shuffle(_random);
      _availableWords = shuffled;
      _selectedWords = [];
      _totalQuestions++;
    });
  }

  void _handleWordClick(String word, bool fromAvailable) {
    if (_feedback != null) return;
    setState(() {
      if (fromAvailable) {
        _availableWords.remove(word);
        _selectedWords.add(word);
      } else {
        _selectedWords.remove(word);
        _availableWords.add(word);
      }
    });
    AudioService().playSFX('flip.mp3');
  }

  void _checkAnswer() {
    if (_currentProblem == null || _selectedWords.isEmpty || _feedback != null) return;
    
    bool isCorrect = _selectedWords.join(' ') == _currentProblem!.correctSentence;
    
    setState(() {
      _feedback = {
        'show': true,
        'isCorrect': isCorrect,
        'correctAnswer': _currentProblem!.correctSentence,
      };
      
      _gameSessionData.add({
        'problem': _currentProblem!.words.join(', '),
        'correctAnswer': _currentProblem!.correctSentence,
        'selectedAnswer': _selectedWords.join(' '),
        'isCorrect': isCorrect,
        'domain': _currentProblem!.domain,
        'timeSpent': DateTime.now().difference(_startTime!).inMilliseconds,
        'level': _currentLevel,
        'language': _language
      });
      
      if (isCorrect) {
        _score += 25;
        _correctAnswers++;
        _levelCorrectAnswers++;
        context.read<AppState>().addSticker('story-builder');
        AudioService().playSFX('success.mp3');
      } else {
        _wrongAnswers++;
        _lives--;
        AudioService().playSFX('wrong.mp3');
      }
    });

    if (_lives <= 0) {
      _timer?.cancel();
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _gameState = 'game_over';
        });
      });
    } else if (isCorrect && _levelCorrectAnswers >= 3) {
      // Level beaten!
      _timer?.cancel();
      
      // Calculate stars based on remaining lives
      int stars = 1;
      if (_lives == 3) stars = 3;
      else if (_lives == 2) stars = 2;
      
      _starRatings[_currentLevel - 1] = max(_starRatings[_currentLevel - 1], stars);
      
      if (_currentLevel == _highestUnlocked && _highestUnlocked < 8) {
        _highestUnlocked = _currentLevel + 1;
      }
      
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _gameState = 'level_complete';
        });
      });
    } else {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        if (_gameState == 'playing') {
          setState(() => _feedback = null);
          _generateNewProblem();
        }
      });
    }
  }

  void _resetCurrentProblem() {
    if (_currentProblem != null && _feedback == null) {
      setState(() {
        _availableWords = List<String>.from(_currentProblem!.words)..shuffle(_random);
        _selectedWords = [];
      });
    }
  }

  void _endGame() {
    _timer?.cancel();
    
    int totalTime = DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    int accuracy = _totalQuestions > 0 ? ((_correctAnswers / _totalQuestions) * 100).round() : 0;
    
    context.read<AppState>().updateTestResults('linguistic', {
      'score': _correctAnswers,
      'total': _totalQuestions,
      'percentage': accuracy,
      'timeSpent': totalTime,
      'gameMode': 'Story Builder Premium',
      'language': _language,
      'level': _currentLevel,
      'categoryScores': {
        'accuracy': accuracy,
        'livesRemaining': _lives
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

    context.read<AppState>().updateGameAssessment('storyBuilderGame', GameSession(
      score: _score,
      timeSpent: totalTime,
      errors: _wrongAnswers,
      totalItems: _totalQuestions,
      correctAnswers: _correctAnswers,
      avgResponseTimeMs: avgRespMs,
      maxLevelReached: _currentLevel,
      hintsUsed: 0,
      assessmentScore: assessScore,
      detailedMetrics: {
        'livesRemaining': _lives,
      },
      subdomainScores: {
        'expressiveLanguage': assessScore,
      },
    ));

    context.read<AppState>().addPointsFromScore(_score);

    AudioService().stopBGM();
    AudioService().playSFX('completion.mp3');
    setState(() => _gameState = 'completed');
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
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFFCD34D)]
          ),
        ),
        child: Stack(
          children: [
            // Decorative background patterns
            Positioned(top: -50, right: -50, child: Opacity(opacity: 0.1, child: Icon(Icons.menu_book, size: 300, color: Colors.orange.shade700))),
            Positioned(bottom: 20, left: 10, child: Opacity(opacity: 0.2, child: const Text('✍️', style: TextStyle(fontSize: 100)))),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        _buildGlassButton(Icons.arrow_back, () => Navigator.pop(context)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Premium Title Section
                  Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withOpacity(0.6)),
                    ),
                    child: Column(
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 100)),
                        const SizedBox(height: 16),
                        Text(
                          'STORY\nBUILDER',
                          textAlign: TextAlign.center,
                          style: AppTheme.heading1.copyWith(color: const Color(0xFF92400E), fontSize: 40, letterSpacing: 4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Susun kata menjadi cerita magis!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFB45309), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // Language Selection Glass
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildLangOption('id', '🇮🇩 INDO')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildLangOption('en', '🇬🇧 EN')),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Start Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: _buildPremiumButton('MULAI MENULIS 🖊️', _startGame),
                  ),
                ],
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
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Icon(icon, color: const Color(0xFF92400E)),
      ),
    );
  }

  Widget _buildLangOption(String code, String label) {
    bool isSelected = _language == code;
    return GestureDetector(
      onTap: () => setState(() => _language = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF92400E) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF92400E).withOpacity(isSelected ? 1 : 0.2)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF92400E),
            fontWeight: FontWeight.w900,
            letterSpacing: 2
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumButton(String text, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF92400E), Color(0xFF78350F)]),
        boxShadow: [BoxShadow(color: const Color(0xFF78350F).withOpacity(0.4), offset: const Offset(0, 8), blurRadius: 16)],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildCompleted() {
    int accuracy = _totalQuestions > 0 ? ((_correctAnswers / _totalQuestions) * 100).round() : 0;
    String childName = context.read<AppState>().childProfile.name;

    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 100)),
              const SizedBox(height: 24),
              Text('Penulis Hebat!', style: AppTheme.heading1.copyWith(color: const Color(0xFF92400E))),
              const SizedBox(height: 8),
              Text(
                'Selamat $childName!\nKamu telah menyusun $_correctAnswers kalimat sempurna.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB45309), fontSize: 18),
              ),
              const SizedBox(height: 48),
              
              _buildStatRow('Ketepatan', '$accuracy%'),
              const SizedBox(height: 12),
              _buildStatRow('Skor Akhir', '$_score pts'),
              
              const Spacer(),
              _buildPremiumButton('MAIN LAGI 🔄', () => setState(() => _gameState = 'menu')),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keluar Game', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Color(0xFF92400E), fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPlaying() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: _currentProblem == null 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Nav
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildGlassButton(Icons.close, () => setState(() => _gameState = 'level_select')),
                      const Spacer(),
                      // Lives
                      Row(
                        children: List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.favorite,
                            color: i < _lives ? Colors.redAccent : Colors.black12,
                            size: 28,
                          ),
                        )),
                      ),
                    ],
                  ),
                ),

                // Question Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Hint Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Column(
                            children: [
                              Text(_currentProblem!.emoji, style: const TextStyle(fontSize: 72)),
                              const SizedBox(height: 16),
                              Text(
                                _currentProblem!.hint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF92400E), fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Construction Zone (Paper Theme)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 120),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                          ),
                          child: Wrap(
                            spacing: 12, runSpacing: 12,
                            children: _selectedWords.isEmpty 
                              ? [const Text('Ketuk kata di bawah untuk menyusun...', style: TextStyle(color: Colors.black26, fontStyle: FontStyle.italic))]
                              : _selectedWords.map((word) => _buildWordTile(word, false)).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Word Bank
                        Wrap(
                          spacing: 12, runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: _availableWords.map((word) => _buildWordTile(word, true)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Controls
                if (_feedback == null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _resetCurrentProblem,
                            child: const Text('RESET', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildPremiumButton('CEK HASIL ✅', _checkAnswer),
                        ),
                      ],
                    ),
                  ),

                // Feedback Banner
                if (_feedback != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, child) {
                      return Container(
                        width: double.infinity,
                        height: 160 * value,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _feedback!['isCorrect'] ? Colors.green.shade600 : Colors.red.shade600,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _feedback!['isCorrect'] ? 'YAY! BENAR 🎉' : 'COBA LAGI! 💡',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            if (!_feedback!['isCorrect'])
                              Text(
                                'Harusnya: ${_feedback!['correctAnswer']}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
      ),
    );
  }

  Widget _buildWordTile(String word, bool isAvailable) {
    return GestureDetector(
      onTap: () => _handleWordClick(word, isAvailable),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : const Color(0xFF92400E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF92400E).withOpacity(0.3), width: 2),
          boxShadow: isAvailable ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          word,
          style: TextStyle(
            color: const Color(0xFF92400E),
            fontWeight: FontWeight.w900,
            fontSize: 16
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
                          'Pilih Level 📖',
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  child: Column(
                    children: [
                      // Shelf 1 (Levels 1 & 2)
                      _buildShelf(0),
                      // Shelf 2 (Levels 3 & 4)
                      _buildShelf(1),
                      // Shelf 3 (Levels 5 & 6)
                      _buildShelf(2),
                      // Shelf 4 (Levels 7 & 8)
                      _buildShelf(3),
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

  Widget _buildShelf(int shelfIndex) {
    int levelIndex1 = shelfIndex * 2;
    int levelIndex2 = shelfIndex * 2 + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBookItem(levelIndex1),
              _buildBookItem(levelIndex2),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Wooden Shelf Divider
        Container(
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF78350F), Color(0xFF92400E), Color(0xFF78350F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 3),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBookItem(int index) {
    final int levelNum = index + 1;
    final bool isUnlocked = levelNum <= _highestUnlocked;
    final int rating = _starRatings[index];

    List<Color> bookColors;
    if (!isUnlocked) {
      bookColors = [const Color(0xFF64748B), const Color(0xFF475569)];
    } else {
      switch (index ~/ 2) {
        case 0:
          bookColors = [const Color(0xFFB91C1C), const Color(0xFF7F1D1D)];
          break;
        case 1:
          bookColors = [const Color(0xFF047857), const Color(0xFF064E3B)];
          break;
        case 2:
          bookColors = [const Color(0xFF1D4ED8), const Color(0xFF172554)];
          break;
        default:
          bookColors = [const Color(0xFF6D28D9), const Color(0xFF4C1D95)];
      }
    }

    return GestureDetector(
      onTap: isUnlocked
          ? () {
              AudioService().playClick();
              _startLevel(levelNum);
            }
          : () {
              AudioService().playWrong();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Selesaikan bab sebelumnya untuk membuka cerita ini!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 85,
            height: 115,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bookColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(
                color: isUnlocked ? const Color(0xFFFDE68A).withOpacity(0.5) : Colors.white12,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(3, 4),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Dark spine background
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                      ),
                      border: Border(
                        right: BorderSide(
                          color: isUnlocked ? const Color(0xFFFDE68A).withOpacity(0.3) : Colors.white10,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // Spine golden bands (horizontal gold ridges)
                if (isUnlocked) ...[
                  Positioned(left: 2, top: 18, child: Container(width: 6, height: 1.5, color: const Color(0xFFFDE68A).withOpacity(0.6))),
                  Positioned(left: 2, top: 56, child: Container(width: 6, height: 1.5, color: const Color(0xFFFDE68A).withOpacity(0.6))),
                  Positioned(left: 2, top: 94, child: Container(width: 6, height: 1.5, color: const Color(0xFFFDE68A).withOpacity(0.6))),
                  // Gold filigree corner studs
                  Positioned(top: 6, left: 14, child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Color(0xFFFDE68A), shape: BoxShape.circle))),
                  Positioned(top: 6, right: 6, child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Color(0xFFFDE68A), shape: BoxShape.circle))),
                  Positioned(bottom: 6, left: 14, child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Color(0xFFFDE68A), shape: BoxShape.circle))),
                  Positioned(bottom: 6, right: 6, child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Color(0xFFFDE68A), shape: BoxShape.circle))),
                  // Hanging ribbon bookmark
                  Positioned(
                    bottom: 0,
                    right: 18,
                    width: 8,
                    height: 14,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), // Crimson ribbon
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(1.5),
                          bottomRight: Radius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                ],
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isUnlocked) ...[
                          Icon(
                            index % 2 == 0 ? Icons.menu_book_rounded : Icons.auto_stories_rounded,
                            size: 16,
                            color: const Color(0xFFFDE68A).withOpacity(0.7),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'BAB',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFDE68A).withOpacity(0.8),
                              letterSpacing: 1.2,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$levelNum',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'serif',
                              shadows: [
                                Shadow(color: Colors.black45, offset: Offset(1.5, 1.5), blurRadius: 2),
                              ],
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.lock_rounded,
                            color: Colors.white54,
                            size: 24,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF78350F).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (starIdx) {
                final isStarred = starIdx < rating;
                return Icon(
                  Icons.star_rounded,
                  color: isStarred ? Colors.amber : Colors.black12,
                  size: 12,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCompleteScreen() {
    final stars = _starRatings[_currentLevel - 1];

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
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
                  color: Colors.cyanAccent,
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
                'Skor: $_score  •  Nyawa Tersisa: $_lives',
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
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
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
      backgroundColor: const Color(0xFF1E293B),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😢', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const Text(
                'GAME OVER!',
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
                'Kamu kehabisan nyawa di Level $_currentLevel',
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
                    backgroundColor: Colors.blueAccent,
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
}
