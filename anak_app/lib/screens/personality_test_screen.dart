import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';

class PersonalityTestScreen extends StatefulWidget {
  const PersonalityTestScreen({super.key});

  @override
  State<PersonalityTestScreen> createState() => _PersonalityTestScreenState();
}

class _PersonalityTestScreenState extends State<PersonalityTestScreen> with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  List<String> answers = [];
  bool isCompleted = false;
  Map<String, dynamic>? animalResult;
  int? selectedOption;
  bool _isStarted = false;

  late AnimationController _backgroundParticlesController;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _backgroundParticlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['showResult'] == true && !isCompleted) {
      final appState = Provider.of<AppState>(context, listen: false);
      final mbtiType = appState.testResults.personality.type;
      if (mbtiType != null && mbtiType.isNotEmpty && animalTypes.containsKey(mbtiType)) {
        setState(() {
          animalResult = animalTypes[mbtiType];
          isCompleted = true;
          _isStarted = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _backgroundParticlesController.dispose();
    _spinController.dispose();
    AudioService().stopBGM();
    super.dispose();
  }

  final List<Map<String, dynamic>> questions = [
    {
      'emoji': '🤕',
      'situation': 'Ketika temanmu terjatuh, kamu akan:',
      'choices': [
        {'emoji': '🏃', 'text': 'Langsung lari menghampiri dan menolong', 'trait': 'E'},
        {'emoji': '🤗', 'text': 'Tanya apakah dia baik-baik saja', 'trait': 'F'},
        {'emoji': '👨‍⚕️', 'text': 'Panggil guru atau orang dewasa', 'trait': 'T'},
        {'emoji': '🩹', 'text': 'Ambilkan obat merah dan plester', 'trait': 'S'}
      ]
    },
    {
      'emoji': '🎂',
      'situation': 'Temanmu tidak diundang ke pesta ulang tahun:',
      'choices': [
        {'emoji': '🎉', 'text': 'Ajak temanku ikut bersamaku', 'trait': 'E'},
        {'emoji': '💝', 'text': 'Hibur dia dan bilang nanti kita main', 'trait': 'F'},
        {'emoji': '📞', 'text': 'Beritahu yang punya pesta', 'trait': 'J'},
        {'emoji': '🎁', 'text': 'Ajak dia bikin pesta sendiri besok', 'trait': 'N'}
      ]
    },
    {
      'emoji': '📚',
      'situation': 'Saat kerja kelompok, kamu biasanya:',
      'choices': [
        {'emoji': '🗣️', 'text': 'Ngobrol sama semua anggota', 'trait': 'E'},
        {'emoji': '📝', 'text': 'Catat dan bagi tugas dengan jelas', 'trait': 'J'},
        {'emoji': '💡', 'text': 'Kasih ide-ide kreatif', 'trait': 'N'},
        {'emoji': '🤝', 'text': 'Pastikan semua setuju dan senang', 'trait': 'F'}
      ]
    },
    {
      'emoji': '🎮',
      'situation': 'Ada teman baru di sekolah, kamu:',
      'choices': [
        {'emoji': '👋', 'text': 'Langsung kenalan dan ajak main', 'trait': 'E'},
        {'emoji': '😊', 'text': 'Senyum dan tunggu dia mendekat', 'trait': 'I'},
        {'emoji': '🏫', 'text': 'Tunjukkan ruang kelas dan aturan', 'trait': 'S'},
        {'emoji': '❓', 'text': 'Tanya dari mana dan hobi apa', 'trait': 'N'}
      ]
    },
    {
      'emoji': '😢',
      'situation': 'Temanmu menangis di kelas, kamu:',
      'choices': [
        {'emoji': '🪑', 'text': 'Duduk di sebelahnya menemani', 'trait': 'I'},
        {'emoji': '💬', 'text': 'Tanya kenapa dia menangis', 'trait': 'T'},
        {'emoji': '🤗', 'text': 'Peluk dan hibur sampai tenang', 'trait': 'F'},
        {'emoji': '🧃', 'text': 'Ambilkan tisu dan minum', 'trait': 'S'}
      ]
    },
    {
      'emoji': '⚽',
      'situation': 'Saat bermain, ada yang curang, kamu:',
      'choices': [
        {'emoji': '🗣️', 'text': 'Bilang ke semua kalau itu curang', 'trait': 'E'},
        {'emoji': '⚖️', 'text': 'Ingatkan aturan mainnya', 'trait': 'T'},
        {'emoji': '😔', 'text': 'Kasih tahu perasaanku yang kecewa', 'trait': 'F'},
        {'emoji': '🔄', 'text': 'Usul main ulang yang adil', 'trait': 'J'}
      ]
    },
    {
      'emoji': '🍕',
      'situation': 'Ada 1 pizza terakhir, tapi temanmu juga mau:',
      'choices': [
        {'emoji': '✂️', 'text': 'Potong jadi dua, bagi rata', 'trait': 'S'},
        {'emoji': '💝', 'text': 'Kasih ke temanku saja', 'trait': 'F'},
        {'emoji': '🎲', 'text': 'Suit batu gunting kertas', 'trait': 'T'},
        {'emoji': '🍕🍕', 'text': 'Beli pizza lagi buat berdua', 'trait': 'N'}
      ]
    },
    {
      'emoji': '🏆',
      'situation': 'Temanmu kalah lomba dan sedih, kamu:',
      'choices': [
        {'emoji': '🎮', 'text': 'Ajak main game untuk melupakan', 'trait': 'E'},
        {'emoji': '⭐', 'text': 'Bilang dia sudah hebat dan berusaha', 'trait': 'F'},
        {'emoji': '📊', 'text': 'Analisis apa yang bisa diperbaiki', 'trait': 'T'},
        {'emoji': '🎯', 'text': 'Ajak latihan untuk lomba berikutnya', 'trait': 'J'}
      ]
    },
    {
      'emoji': '🎨',
      'situation': 'Ada teman yang kesulitan mengerjakan tugas:',
      'choices': [
        {'emoji': '👥', 'text': 'Ajak belajar bersama-sama', 'trait': 'E'},
        {'emoji': '📖', 'text': 'Jelaskan cara mengerjakannya', 'trait': 'S'},
        {'emoji': '💪', 'text': 'Semangatin dia pasti bisa', 'trait': 'F'},
        {'emoji': '🔍', 'text': 'Bantu cari cara yang lebih mudah', 'trait': 'N'}
      ]
    },
    {
      'emoji': '🎁',
      'situation': 'Kamu punya 2 mainan, temanmu tidak punya:',
      'choices': [
        {'emoji': '🎮🎮', 'text': 'Main bersama dengan mainanku', 'trait': 'E'},
        {'emoji': '🎁', 'text': 'Kasih 1 mainan untuknya', 'trait': 'F'},
        {'emoji': '⏰', 'text': 'Bergantian pakai dengan jadwal', 'trait': 'J'},
        {'emoji': '🤝', 'text': 'Tukar mainan supaya seru', 'trait': 'P'}
      ]
    },
    {
      'emoji': '🚌',
      'situation': 'Di bus, kamu lihat orang tua berdiri:',
      'choices': [
        {'emoji': '🪑', 'text': 'Langsung berdiri kasih tempat duduk', 'trait': 'S'},
        {'emoji': '😊', 'text': 'Tawarkan dengan sopan', 'trait': 'I'},
        {'emoji': '❤️', 'text': 'Kasihan, langsung bantu', 'trait': 'F'},
        {'emoji': '✅', 'text': 'Itu yang benar, harus dilakukan', 'trait': 'T'}
      ]
    },
    {
      'emoji': '🗑️',
      'situation': 'Ada sampah di kelas tapi bukan sampahmu:',
      'choices': [
        {'emoji': '👥', 'text': 'Ajak teman-teman bersih-bersih', 'trait': 'E'},
        {'emoji': '🧹', 'text': 'Langsung buang ke tempat sampah', 'trait': 'S'},
        {'emoji': '📢', 'text': 'Ingatkan semua jangan buang sembarangan', 'trait': 'T'},
        {'emoji': '♻️', 'text': 'Bikin sistem daur ulang di kelas', 'trait': 'N'}
      ]
    },
    {
      'emoji': '🎈',
      'situation': 'Hari ini hari ulang tahunmu, kamu ingin:',
      'choices': [
        {'emoji': '🎉', 'text': 'Pesta besar ajak semua teman', 'trait': 'E'},
        {'emoji': '👨‍👩‍👧', 'text': 'Rayakan dengan keluarga saja', 'trait': 'I'},
        {'emoji': '📋', 'text': 'Rencanakan semua detail dengan rapih', 'trait': 'J'},
        {'emoji': '🎊', 'text': 'Surprise! Lihat nanti aja', 'trait': 'P'}
      ]
    },
    {
      'emoji': '🐶',
      'situation': 'Ada anak kucing kelaparan di jalan:',
      'choices': [
        {'emoji': '🥛', 'text': 'Langsung kasih makan dan minum', 'trait': 'F'},
        {'emoji': '📞', 'text': 'Hubungi penyelamat hewan', 'trait': 'T'},
        {'emoji': '🏠', 'text': 'Bawa pulang dan rawat', 'trait': 'I'},
        {'emoji': '👥', 'text': 'Ajak teman-teman untuk bantu', 'trait': 'E'}
      ]
    },
    {
      'emoji': '🎯',
      'situation': 'PR banyak sekali! Kamu akan:',
      'choices': [
        {'emoji': '📝', 'text': 'Buat daftar dan kerjakan satu-satu', 'trait': 'J'},
        {'emoji': '🎲', 'text': 'Kerjakan yang paling mudah dulu', 'trait': 'P'},
        {'emoji': '👥', 'text': 'Ajak teman mengerjakan bersama', 'trait': 'E'},
        {'emoji': '🤔', 'text': 'Kerjakan sendiri dengan tenang', 'trait': 'I'}
      ]
    },
    {
      'emoji': '🍰',
      'situation': 'Kamu bawa kue, tapi cuma cukup untuk sendiri:',
      'choices': [
        {'emoji': '🍰', 'text': 'Bagi ke teman walaupun jadi sedikit', 'trait': 'F'},
        {'emoji': '🏃', 'text': 'Makan di tempat sepi sendiri', 'trait': 'I'},
        {'emoji': '💰', 'text': 'Besok beli lebih banyak buat semua', 'trait': 'J'},
        {'emoji': '🤷', 'text': 'Makan aja, besok mereka juga bawa', 'trait': 'T'}
      ]
    },
    {
      'emoji': '🎭',
      'situation': 'Disuruh tampil di panggung depan banyak orang:',
      'choices': [
        {'emoji': '🎤', 'text': 'Seru! Aku suka tampil!', 'trait': 'E'},
        {'emoji': '😰', 'text': 'Waduh, takut... malu', 'trait': 'I'},
        {'emoji': '📋', 'text': 'Oke, tapi mau persiapan dulu', 'trait': 'J'},
        {'emoji': '🎨', 'text': 'Boleh! Mau tampil yang kreatif', 'trait': 'N'}
      ]
    },
    {
      'emoji': '🎮',
      'situation': 'Temanmu marah karena kalah main game:',
      'choices': [
        {'emoji': '🤗', 'text': 'Hibur dan peluk dia', 'trait': 'F'},
        {'emoji': '🎯', 'text': 'Ajari cara menang yang benar', 'trait': 'T'},
        {'emoji': '🆚', 'text': 'Main lagi sampai dia menang', 'trait': 'E'},
        {'emoji': '😌', 'text': 'Kasih waktu dia untuk tenang dulu', 'trait': 'I'}
      ]
    },
    {
      'emoji': '🧩',
      'situation': 'Dapat mainan baru yang rumit:',
      'choices': [
        {'emoji': '📖', 'text': 'Baca instruksi dengan teliti', 'trait': 'S'},
        {'emoji': '🔧', 'text': 'Langsung coba-coba sendiri', 'trait': 'P'},
        {'emoji': '💡', 'text': 'Bikin cara main yang baru', 'trait': 'N'},
        {'emoji': '👥', 'text': 'Main bareng teman lebih seru', 'trait': 'E'}
      ]
    },
    {
      'emoji': '🌧️',
      'situation': 'Hujan deras, temanmu tidak bawa payung:',
      'choices': [
        {'emoji': '☂️', 'text': 'Ajak berteduh bareng payungku', 'trait': 'F'},
        {'emoji': '🏫', 'text': 'Bilang dia tunggu di sekolah dulu', 'trait': 'T'},
        {'emoji': '🏃', 'text': 'Ajak lari bareng sambil ketawa', 'trait': 'E'},
        {'emoji': '📞', 'text': 'Pinjamkan payung, aku tunggu dijemput', 'trait': 'I'}
      ]
    }
  ];

  final Map<String, Map<String, dynamic>> animalTypes = {
    'ENFJ': {
      'animal': '🦁', 'name': 'Singa Pemimpin', 'personality': 'Pemimpin yang Peduli',
      'traits': 'Karismatik, Inspiratif, dan Empati',
      'description': '{NAME} adalah pemimpin alami yang selalu peduli dengan teman-teman! Kamu suka membantu orang lain dan punya kemampuan membuat semua orang merasa spesial.',
      'strengths': ['Pemimpin Natural', 'Mudah Bergaul', 'Peduli Orang Lain', 'Komunikatif'],
      'tips': 'Dukung jiwa kepemimpinan dengan memberikan tanggung jawab kecil dan ajari untuk mendengarkan berbagai pendapat.',
      'colorStart': const Color(0xFFFBBF24), 'colorEnd': const Color(0xFFF97316),
      'bgStart': const Color(0xFFFFFBEB), 'bgEnd': const Color(0xFFFFF7ED),
    },
    'ENFP': {
      'animal': '🐰', 'name': 'Kelinci Petualang', 'personality': 'Petualang Ceria',
      'traits': 'Kreatif, Antusias, dan Imajinatif',
      'description': '{NAME} adalah petualang yang penuh energi! Kamu punya ide-ide kreatif yang luar biasa dan selalu optimis melihat hal baru.',
      'strengths': ['Sangat Kreatif', 'Mudah Beradaptasi', 'Antusias', 'Imajinatif'],
      'tips': 'Berikan banyak aktivitas kreatif dan hindari rutinitas yang terlalu kaku. Biarkan bereksplorasi!',
      'colorStart': const Color(0xFFF472B6), 'colorEnd': const Color(0xFFA855F7),
      'bgStart': const Color(0xFFFDF2F8), 'bgEnd': const Color(0xFFFAF5FF),
    },
    'ENTJ': {
      'animal': '🦅', 'name': 'Elang Komandan', 'personality': 'Komandan Cilik',
      'traits': 'Tegas, Strategis, dan Ambisius',
      'description': '{NAME} punya visi besar dan determinasi kuat! Kamu suka membuat rencana dan mencapai target yang kamu tetapkan.',
      'strengths': ['Terorganisir', 'Berani', 'Strategis', 'Goal-Oriented'],
      'tips': 'Tantang dengan target yang achievable dan ajarkan fleksibilitas serta empati.',
      'colorStart': const Color(0xFF60A5FA), 'colorEnd': const Color(0xFF6366F1),
      'bgStart': const Color(0xFFEFF6FF), 'bgEnd': const Color(0xFFEEF2FF),
    },
    'ENTP': {
      'animal': '🦊', 'name': 'Rubah Inovator', 'personality': 'Innovator Pintar',
      'traits': 'Cerdik, Adaptif, dan Inovatif',
      'description': '{NAME} adalah problem solver yang pintar! Kamu suka debat, punya ide-ide fresh, dan selalu curious.',
      'strengths': ['Problem Solver', 'Quick Learner', 'Inovatif', 'Sangat Curious'],
      'tips': 'Stimulasi rasa ingin tahu dengan eksperimen, debat, dan diskusi yang menantang.',
      'colorStart': const Color(0xFFFB923C), 'colorEnd': const Color(0xFFEF4444),
      'bgStart': const Color(0xFFFFF7ED), 'bgEnd': const Color(0xFFFEF2F2),
    },
    'ESFJ': {
      'animal': '🐨', 'name': 'Koala Penolong', 'personality': 'Penolong Setia',
      'traits': 'Peduli, Harmonis, dan Supportive',
      'description': '{NAME} adalah teman yang hangat dan selalu siap membantu! Kamu peduli dengan perasaan orang lain dan suka menjaga keharmonisan.',
      'strengths': ['Supportive', 'Reliable', 'Team Player', 'Sangat Peduli'],
      'tips': 'Apresiasi kebaikannya dan ajarkan untuk kadang prioritaskan diri sendiri juga.',
      'colorStart': const Color(0xFF4ADE80), 'colorEnd': const Color(0xFF14B8A6),
      'bgStart': const Color(0xFFF0FDF4), 'bgEnd': const Color(0xFFF0FDFA),
    },
    'ESFP': {
      'animal': '🐹', 'name': 'Hamster Entertainer', 'personality': 'Entertainer Lucu',
      'traits': 'Fun, Spontan, dan Cheerful',
      'description': '{NAME} adalah mood booster! Kamu suka bikin orang senang, spontan, dan selalu bawa energy positif ke mana-mana.',
      'strengths': ['Sangat Cheerful', 'Spontan', 'People Person', 'Praktis'],
      'tips': 'Dukung ekspresi dirinya dan ajarkan perencanaan sederhana untuk keseimbangan.',
      'colorStart': const Color(0xFFFACC15), 'colorEnd': const Color(0xFFEC4899),
      'bgStart': const Color(0xFFFEFCE8), 'bgEnd': const Color(0xFFFDF2F8),
    },
    'ESTJ': {
      'animal': '🐝', 'name': 'Lebah Organizer', 'personality': 'Organizer Teliti',
      'traits': 'Disiplin, Sistematis, dan Responsible',
      'description': '{NAME} suka kerapihan dan punya jadwal jelas! Kamu sangat reliable dan bisa diandalkan untuk menyelesaikan tugas.',
      'strengths': ['Sangat Organized', 'Responsible', 'Hardworking', 'Loyal'],
      'tips': 'Hargai kedisiplinannya tapi ajak untuk lebih fleksibel dan spontan sesekali.',
      'colorStart': const Color(0xFFFACC15), 'colorEnd': const Color(0xFFF97316),
      'bgStart': const Color(0xFFFEFCE8), 'bgEnd': const Color(0xFFFFF7ED),
    },
    'ESTP': {
      'animal': '🐯', 'name': 'Harimau Athlete', 'personality': 'Athlete Berani',
      'traits': 'Sporty, Aktif, dan Berani',
      'description': '{NAME} sangat energik dan suka tantangan fisik! Kamu berani coba hal baru dan suka action.',
      'strengths': ['Sangat Energetic', 'Adaptable', 'Hands-On', 'Courageous'],
      'tips': 'Sediakan banyak aktivitas fisik dan olahraga untuk menyalurkan energi.',
      'colorStart': const Color(0xFFFB923C), 'colorEnd': const Color(0xFFEF4444),
      'bgStart': const Color(0xFFFFF7ED), 'bgEnd': const Color(0xFFFEF2F2),
    },
    'INFJ': {
      'animal': '🦉', 'name': 'Burung Hantu Visioner', 'personality': 'Visioner Bijak',
      'traits': 'Bijaksana, Intuitif, dan Idealistik',
      'description': '{NAME} punya pemikiran yang dalam dan insight bagus! Kamu sangat peduli dengan orang lain dan punya visi yang indah.',
      'strengths': ['Insightful', 'Sangat Empati', 'Kreatif', 'Idealistic'],
      'tips': 'Berikan waktu sendiri untuk recharge dan dukung kreativitas serta idealisme.',
      'colorStart': const Color(0xFFA855F7), 'colorEnd': const Color(0xFF6366F1),
      'bgStart': const Color(0xFFFAF5FF), 'bgEnd': const Color(0xFFEEF2FF),
    },
    'INFP': {
      'animal': '🐼', 'name': 'Panda Dreamer', 'personality': 'Dreamer Baik Hati',
      'traits': 'Sensitif, Imajinatif, dan Autentik',
      'description': '{NAME} punya dunia dalam yang kaya dan indah! Kamu sangat peduli keadilan dan autentik dengan diri sendiri.',
      'strengths': ['Sangat Kreatif', 'Authentic', 'Compassionate', 'Open-Minded'],
      'tips': 'Dukung ekspresi kreatif dan hargai sensitivitas serta nilai-nilai yang dipegang.',
      'colorStart': const Color(0xFF4ADE80), 'colorEnd': const Color(0xFF3B82F6),
      'bgStart': const Color(0xFFF0FDF4), 'bgEnd': const Color(0xFFEFF6FF),
    },
    'INTJ': {
      'animal': '🐺', 'name': 'Serigala Mastermind', 'personality': 'Mastermind Muda',
      'traits': 'Strategis, Independent, dan Analytical',
      'description': '{NAME} suka berpikir deep dan punya rencana jangka panjang! Kamu mandiri dan sangat analitis.',
      'strengths': ['Strategic', 'Independent', 'Analytical', 'Determined'],
      'tips': 'Respect kebutuhan waktu sendiri dan tantang dengan puzzle serta strategi games.',
      'colorStart': const Color(0xFF9CA3AF), 'colorEnd': const Color(0xFF3B82F6),
      'bgStart': const Color(0xFFF9FAFB), 'bgEnd': const Color(0xFFEFF6FF),
    },
    'INTP': {
      'animal': '🐧', 'name': 'Penguin Scientist', 'personality': 'Scientist Kecil',
      'traits': 'Logis, Eksploratif, dan Objektif',
      'description': '{NAME} sangat curious dan suka eksperimen! Kamu selalu tanya "kenapa" dan suka memahami cara kerja sesuatu.',
      'strengths': ['Sangat Logical', 'Curious', 'Objective', 'Innovative'],
      'tips': 'Fasilitasi rasa ingin tahu dengan buku, eksperimen sains, dan diskusi mendalam.',
      'colorStart': const Color(0xFF60A5FA), 'colorEnd': const Color(0xFF06B6D4),
      'bgStart': const Color(0xFFEFF6FF), 'bgEnd': const Color(0xFFECFEFF),
    },
    'ISFJ': {
      'animal': '🐑', 'name': 'Domba Protector', 'personality': 'Protector Lembut',
      'traits': 'Nurturing, Supportive, dan Detail-Oriented',
      'description': '{NAME} lembut dan selalu siap bantu! Kamu menjaga harmoni di group dan sangat perhatian dengan detail.',
      'strengths': ['Sangat Caring', 'Detail-Oriented', 'Loyal', 'Patient'],
      'tips': 'Apresiasi kebaikan dan ajarkan untuk assertive saat dibutuhkan.',
      'colorStart': const Color(0xFFF472B6), 'colorEnd': const Color(0xFFF43F5E),
      'bgStart': const Color(0xFFFDF2F8), 'bgEnd': const Color(0xFFFFF1F2),
    },
    'ISFP': {
      'animal': '🐻', 'name': 'Beruang Artist', 'personality': 'Artist Lembut',
      'traits': 'Kreatif, Peace-Loving, dan Artistik',
      'description': '{NAME} artistik dan kalem! Kamu passionate dengan hal yang kamu suka dan punya jiwa seni yang kuat.',
      'strengths': ['Sangat Artistic', 'Gentle', 'Flexible', 'Observant'],
      'tips': 'Sediakan banyak medium artistik dan berikan ruang untuk eksplorasi kreatif.',
      'colorStart': const Color(0xFFA16207), 'colorEnd': const Color(0xFFF97316),
      'bgStart': const Color(0xFFFFF7ED), 'bgEnd': const Color(0xFFFEFCE8),
    },
    'ISTJ': {
      'animal': '🐘', 'name': 'Gajah Guardian', 'personality': 'Guardian Setia',
      'traits': 'Reliable, Traditional, dan Methodical',
      'description': '{NAME} sangat bisa diandalkan! Kamu detail-oriented dan selalu menepati janji.',
      'strengths': ['Sangat Reliable', 'Methodical', 'Loyal', 'Responsible'],
      'tips': 'Hargai konsistensi dan sesekali ajak untuk coba pendekatan baru.',
      'colorStart': const Color(0xFF9CA3AF), 'colorEnd': const Color(0xFF3B82F6),
      'bgStart': const Color(0xFFF9FAFB), 'bgEnd': const Color(0xFFEFF6FF),
    },
    'ISTP': {
      'animal': '🐱', 'name': 'Kucing Mechanic', 'personality': 'Mechanic Cool',
      'traits': 'Praktis, Independent, dan Hands-On',
      'description': '{NAME} hands-on dan suka oprek-oprek! Kamu solve masalah dengan praktek langsung.',
      'strengths': ['Sangat Practical', 'Adaptable', 'Calm', 'Problem-Solver'],
      'tips': 'Berikan banyak aktivitas hands-on dan respect kebutuhan personal space.',
      'colorStart': const Color(0xFFFB923C), 'colorEnd': const Color(0xFFEAB308),
      'bgStart': const Color(0xFFFFF7ED), 'bgEnd': const Color(0xFFFEFCE8),
    }
  };

  String calculateMBTI(List<String> userAnswers) {
    int e = 0, i = 0, s = 0, n = 0, t = 0, f = 0, j = 0, p = 0;
    for (var a in userAnswers) {
      if (a == 'E') { e++; } else if (a == 'I') { i++; }
      else if (a == 'S') { s++; } else if (a == 'N') { n++; }
      else if (a == 'T') { t++; } else if (a == 'F') { f++; }
      else if (a == 'J') { j++; } else if (a == 'P') { p++; }
    }
    String res = '';
    res += (e > i) ? 'E' : 'I';
    res += (s > n) ? 'S' : 'N';
    res += (t > f) ? 'T' : 'F';
    res += (j > p) ? 'J' : 'P';
    return res;
  }

  Map<String, int> calculateAspectScores(List<String> userAnswers) {
    int e = 0, i = 0, s = 0, n = 0, t = 0, f = 0, j = 0, p = 0;
    for (var a in userAnswers) {
      if (a == 'E') { e++; } else if (a == 'I') { i++; }
      else if (a == 'S') { s++; } else if (a == 'N') { n++; }
      else if (a == 'T') { t++; } else if (a == 'F') { f++; }
      else if (a == 'J') { j++; } else if (a == 'P') { p++; }
    }
    
    final socialTotal = e + i;
    final socialRatio = socialTotal > 0 ? e / socialTotal : 0.5;
    final socialScore = (30 + socialRatio * 40).round();

    final emotionalTotal = f + t;
    final emotionalRatio = emotionalTotal > 0 ? f / emotionalTotal : 0.5;
    final emotionalScore = (30 + emotionalRatio * 40).round();

    final characterResponsible = j + s;
    final characterFlexible = p + n;
    final characterTotal = characterResponsible + characterFlexible;
    final characterRatio = characterTotal > 0 ? characterResponsible / characterTotal : 0.5;
    final characterScore = (30 + characterRatio * 40).round();

    return {
      'socialScore': socialScore,
      'emotionalScore': emotionalScore,
      'characterScore': characterScore,
    };
  }

  void _handleOptionSelect(String trait, int index) {
    if (selectedOption != null) return;
    setState(() {
      selectedOption = index;
    });
    AudioService().playSFX('correct_personality.mp3.wav');

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        answers.add(trait);
        selectedOption = null;

        if (currentQuestionIndex < questions.length - 1) {
          currentQuestionIndex++;
        } else {
          // Finish
          final mbtiType = calculateMBTI(answers);
          final aspectScores = calculateAspectScores(answers);
          animalResult = animalTypes[mbtiType];
          isCompleted = true;

          final appState = Provider.of<AppState>(context, listen: false);
          appState.addSticker('animal-mbti-complete');
          AudioService().playSFX('level_complete.mp3');
          
          String childName = appState.childProfile.name;
          if (childName.isEmpty) childName = 'Kamu';
          
          appState.updateTestResults('personality', {
            'type': mbtiType,
            'animal': animalResult!['name'],
            'animalEmoji': animalResult!['animal'],
            'personality': animalResult!['personality'],
            'traits': List<String>.from(animalResult!['strengths']),
            'description': animalResult!['description'].replaceAll('{NAME}', childName),
            'tips': animalResult!['tips'] ?? '',
            'socialScore': aspectScores['socialScore'],
            'emotionalScore': aspectScores['emotionalScore'],
            'characterScore': aspectScores['characterScore'],
          });
          appState.addPointsFromScore(500); // 500 score = 50 points fixed bonus for personality test
        }
      });
    });
  }

  Widget _buildBackgroundParticles() {
    final List<String> emojis = ['⭐', '✨', '💫', '🌟', '💝', '🎈'];
    return Stack(
      children: List.generate(20, (index) {
        final random = math.Random(index * 100);
        final x = random.nextDouble();
        final y = random.nextDouble();
        final emoji = emojis[random.nextInt(emojis.length)];
        
        return AnimatedBuilder(
          animation: _backgroundParticlesController,
          builder: (context, child) {
            final progress = (_backgroundParticlesController.value + (index / 20)) % 1.0;
            final currentY = y - (progress * 0.5); // float up
            final displayY = currentY < 0 ? currentY + 1 : currentY;
            final alpha = math.sin(progress * math.pi);
            
            return Positioned(
              left: x * MediaQuery.of(context).size.width,
              top: displayY * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: 0.1 + (alpha * 0.2), // 0.1 to 0.3
                child: Transform.rotate(
                  angle: progress * 2 * math.pi,
                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildCompletedScreen() {
    final appState = Provider.of<AppState>(context);
    String childName = appState.childProfile.name;
    if (childName.isEmpty) childName = 'Kamu';
    
    final desc = animalResult!['description'].replaceAll('{NAME}', childName);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [animalResult!['colorStart'], animalResult!['colorEnd']],
        ),
      ),
      child: Stack(
        children: [
          _buildBackgroundParticles(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    builder: (context, val, child) {
                      return Transform.scale(
                        scale: val,
                        child: AnimatedBuilder(
                          animation: _spinController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: math.sin(_spinController.value * math.pi * 2) * 0.1,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(animalResult!['animal'], style: const TextStyle(fontSize: 120)),
                                  Positioned(
                                    top: 0, right: -10,
                                    child: Transform.rotate(
                                      angle: _spinController.value * math.pi * 2,
                                      child: const Text('✨', style: TextStyle(fontSize: 40)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    animalResult!['name'],
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Fredoka'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    animalResult!['personality'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    animalResult!['traits'],
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // About Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.purple, size: 24),
                            const SizedBox(width: 8),
                            Text('Tentang Kepribadianmu', style: AppTheme.heading3.copyWith(color: AppTheme.gray800)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(desc, style: AppTheme.bodyText.copyWith(fontSize: 16, height: 1.5, color: AppTheme.gray700), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Strengths Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.orange, size: 24),
                            const SizedBox(width: 8),
                            Text('Kekuatan Kamu ✨', style: AppTheme.heading3.copyWith(color: AppTheme.gray800)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: (animalResult!['strengths'] as List<String>).map((str) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [animalResult!['colorStart'], animalResult!['colorEnd']]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: animalResult!['colorStart'].withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(str, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
                                  const SizedBox(height: 4),
                                  AnimatedBuilder(
                                    animation: _spinController,
                                    builder: (context, child) => Transform.rotate(
                                      angle: _spinController.value * math.pi * 2,
                                      child: const Text('⭐', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tips Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFEFCE8)]), // orange-50 to yellow-50
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFED7AA), width: 2), // orange-200
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _spinController,
                              builder: (context, child) => Transform.scale(
                                scale: 1.0 + math.sin(_spinController.value * math.pi * 2) * 0.1,
                                child: const Text('💡', style: TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Tips untuk Orang Tua', style: AppTheme.heading3.copyWith(color: const Color(0xFFC2410C))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(animalResult!['tips'], style: AppTheme.bodyText.copyWith(color: const Color(0xFFEA580C), fontSize: 16, height: 1.5), textAlign: TextAlign.center),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      minimumSize: const Size(double.infinity, 60),
                      elevation: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Kembali ke Home', style: AppTheme.heading3.copyWith(color: AppTheme.gray800)),
                        const SizedBox(width: 12),
                        const Text('🏠', style: TextStyle(fontSize: 24)),
                      ],
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

  Widget _buildIntroScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFFF472B6)],
        ),
      ),
      child: Stack(
        children: [
          _buildBackgroundParticles(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 1),
                    curve: Curves.elasticOut,
                    builder: (context, val, child) => Transform.scale(
                      scale: val,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                        ),
                        child: const Text('✨', style: TextStyle(fontSize: 64)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Profil\nSosial-Emosional 🌟',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Jawab pertanyaan seru ini untuk mengetahui apakah kamu pemberani seperti Singa atau cerdas seperti Serigala!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Penting',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tes ini didesain untuk bersenang-senang dan memberikan gambaran kasar karakter anak. Bukan untuk diagnosis psikologis yang serius.',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isStarted = true);
                      AudioService().playBGM('personality_bgm.mp3.wav', volume: 0.5);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF818CF8),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 8,
                      minimumSize: const Size(double.infinity, 64),
                    ),
                    child: Text(
                      'Mulai Petualangan! 🚀',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF6366F1)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Mungkin Nanti',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
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

  String _getAgeGroup(int age) {
    if (age >= 5 && age <= 7) return 'early';
    if (age >= 8 && age <= 10) return 'middle';
    return 'late';
  }

  final Map<String, List<Map<String, dynamic>>> _parentTips = {
    'early': [
      {'title': 'Mengenal Ragam Emosi', 'desc': 'Gunakan flashcard wajah emoji. Minta anak mempraktikkan ekspresi sedih, marah, dan gembira.', 'icon': '🎭', 'diff': 'Mudah'},
      {'title': 'Seni Berbagi (Sharing)', 'desc': 'Biasakan anak meminjamkan satu mainan favoritnya kepada teman atau saudara selama 10 menit.', 'icon': '🤝', 'diff': 'Sedang'},
      {'title': 'Regulasi Tangisan', 'desc': 'Ajarkan metode tarik napas dalam (Belly Breathing) saat ia mulai tantrum.', 'icon': '🌬️', 'diff': 'Mudah'},
    ],
    'middle': [
      {'title': 'Olahraga Beregu', 'desc': 'Libatkan dalam aktivitas kelompok untuk memupuk kerja sama dan menekan ego individu.', 'icon': '⚽', 'diff': 'Menantang'},
      {'title': 'Berlatih Simpati Aktif', 'desc': 'Saat melihat anak lain menangis, tanyakan "Menurutmu kenapa dia sedih? Apa yang bisa kita bantu?".', 'icon': '💖', 'diff': 'Sedang'},
      {'title': 'Tugas Harian Mandiri', 'desc': 'Berikan tanggung jawab permanen (misal: membereskan tempat tidur) untuk melatih karakter.', 'icon': '🧹', 'diff': 'Sedang'},
    ],
    'late': [
      {'title': 'Resolusi Konflik Dasar', 'desc': 'Saat ia bertengkar dengan teman, arahkan untuk menulis sudut pandang dari posisi temannya.', 'icon': '🕊️', 'diff': 'Menantang'},
      {'title': 'Simulasi Kepemimpinan', 'desc': 'Minta anak menjadi komandan rekreasi akhir pekan keluarga (menyusun rute dan jadwal kegiatan).', 'icon': '👑', 'diff': 'Menantang'},
      {'title': 'Membangun Batasan', 'desc': 'Latih anak berani berkata "Tidak" dengan sopan pada ajakan temannya jika ia merasa tidak nyaman.', 'icon': '🛡️', 'diff': 'Menantang'},
    ]
  };

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isParentMode = appState.isParentMode;

    if (isParentMode) {
      return _buildParentMode(context, appState.childProfile.age);
    }

    if (isCompleted && animalResult != null) {
      return Scaffold(body: _buildCompletedScreen());
    }

    if (!_isStarted) {
      return Scaffold(body: _buildIntroScreen());
    }

    final question = questions[currentQuestionIndex];
    final progress = ((currentQuestionIndex + 1) / questions.length);

    return Scaffold(
      backgroundColor: const Color(0xFF818CF8), // Using indigo background base
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFFF472B6)], // indigo-400, purple-400, pink-400
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundParticles(),
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                                child: const Icon(Icons.arrow_back, color: AppTheme.gray700, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: (MediaQuery.of(context).size.width - 48) * progress, // dynamic width
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                                alignment: Alignment.centerRight,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('🎯 Pertanyaan ${currentQuestionIndex + 1} dari ${questions.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),

                  // Question Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation), child: child));
                      },
                      child: SingleChildScrollView(
                        key: ValueKey<int>(currentQuestionIndex),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                        child: Column(
                          children: [
                            // Big Emoji
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                              builder: (context, val, child) {
                                return Transform.scale(
                                  scale: val,
                                  child: AnimatedBuilder(
                                    animation: _spinController,
                                    builder: (context, child) => Transform.rotate(
                                      angle: math.sin(_spinController.value * math.pi * 2) * 0.1,
                                      child: Text(question['emoji'], style: const TextStyle(fontSize: 72)),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Situation Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                              ),
                              child: Text(
                                question['situation'],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.gray900, height: 1.3),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Choices
                            ...List.generate((question['choices'] as List).length, (index) {
                              final choice = question['choices'][index];
                              final isSelected = selectedOption == index;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () => _handleOptionSelect(choice['trait'], index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white.withOpacity(0.95), // green-50 if selected
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF4ADE80) : Colors.white.withOpacity(0.5),
                                        width: isSelected ? 3 : 2,
                                      ),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                                    ),
                                    transform: isSelected ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
                                    child: Row(
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
                                          duration: const Duration(milliseconds: 300),
                                          builder: (context, val, child) => Transform.scale(
                                            scale: val,
                                            child: Text(choice['emoji'], style: const TextStyle(fontSize: 32)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            choice['text'],
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.gray900),
                                          ),
                                        ),
                                        if (isSelected)
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            duration: const Duration(milliseconds: 400),
                                            builder: (context, val, child) => Transform.scale(
                                              scale: val,
                                              child: Transform.rotate(
                                                angle: val * math.pi * 2,
                                                child: const Text('✅', style: TextStyle(fontSize: 24)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
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

  Widget _buildParentMode(BuildContext context, int childAge) {
    final ageGroup = _getAgeGroup(childAge);
    final tipsList = _parentTips[ageGroup] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF4FF), // Fuchsia background for personality
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFC084FC),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFE879F9), Color(0xFFC084FC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                            child: const Text('💖', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Panduan Sosio-Emosional (Usia $childAge)', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 16)),
                                Text('Stimulasi EQ dan kemandirian.', style: TextStyle(color: Colors.purple.shade50, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              title: Text('Modul Kepribadian (Orang Tua)', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 18)),
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
                    decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.purple),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Mode Orang Tua aktif. Matikan mode ini dari menu profil untuk membiarkan anak mengakses kuis kepribadian.', style: TextStyle(color: Colors.purple, fontSize: 12))),
                      ],
                    ),
                  ),

                  Text('Aktivitas Rekomendasi', style: AppTheme.heading2.copyWith(color: AppTheme.gray900)),
                  const SizedBox(height: 16),

                  ...tipsList.map((tip) {
                    final isHard = tip['diff'] == 'Menantang';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.gray200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.pink]),
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
                                    Expanded(child: Text(tip['title'], style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 16))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: isHard ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text(tip['diff'], style: TextStyle(color: isHard ? Colors.red.shade700 : Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(tip['desc'], style: AppTheme.bodyText.copyWith(color: AppTheme.gray600, fontSize: 13, height: 1.4)),
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
}
