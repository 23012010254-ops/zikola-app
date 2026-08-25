import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
class CognitiveTestScreen extends StatefulWidget {
  const CognitiveTestScreen({super.key});

  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> with TickerProviderStateMixin {
  String gameState = 'menu'; // menu, categorySelect, gameSelect
  String selectedCategory = 'logic';

  late AnimationController _brainAnimController;

  @override
  void initState() {
    super.initState();
    _brainAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _brainAnimController.dispose();
    super.dispose();
  }

  String _getAgeGroup(int age) {
    if (age >= 5 && age <= 7) return 'early';
    if (age >= 8 && age <= 10) return 'middle';
    return 'late';
  }

  final Map<String, List<Map<String, dynamic>>> _parentTips = {
    'early': [
      {'title': 'Tebak Bentuk & Warna', 'desc': 'Gunakan balok untuk membantu membedakan warna dan bentuk dasar.', 'icon': '🟦', 'diff': 'Mudah'},
      {'title': 'Petak Umpet Berpetunjuk', 'desc': 'Sembunyikan mainan favoritnya dan berikan dua petunjuk beruntun (misal: "di bawah bantal merah yang empuk").', 'icon': '🕵️', 'diff': 'Sedang'},
      {'title': 'Puzzle Sederhana', 'desc': 'Sediakan balok puzzle 4-12 keping. Puji perlahan setiap kali ada kecocokan visi spasial.', 'icon': '🧩', 'diff': 'Mudah'},
    ],
    'middle': [
      {'title': 'Permainan Memori Kartu', 'desc': 'Gunakan setumpuk kartu memori. Minta anak mengingat lokasi kartu yang tertutup selama 5 detik.', 'icon': '🃏', 'diff': 'Sedang'},
      {'title': 'Kenalkan Papan Catur', 'desc': 'Ajarkan pergerakan dasar bidak catur. Sangat krusial untuk melatih daya peramalan taktis ke depan.', 'icon': '♟️', 'diff': 'Menantang'},
      {'title': 'Rancang Labirin Sendiri', 'desc': 'Ajak anak menggambar labirin rintangan berlapis di atas kertas dan biarkan Anda yang memecahkannya.', 'icon': '🗺️', 'diff': 'Sedang'},
    ],
    'late': [
      {'title': 'Sudoku Junior (4x4 / 9x9)', 'desc': 'Melatih penalaran matematis eksklusif melalui Sudoku pemula.', 'icon': '🔢', 'diff': 'Menantang'},
      {'title': 'Pemrograman Visual Taktil', 'desc': 'Ajak anak menulis skrip urutan perintah (Maju 2x, Belok Kiri) di kertas untuk memandu orang tua mengambil barang.', 'icon': '💻', 'diff': 'Menantang'},
      {'title': 'Strategi Perdagangan (Monopoli)', 'desc': 'Mainkan board game manajemen resource untuk melatih penundaan kepuasan & kalkulasi jarak menengah.', 'icon': '🎲', 'diff': 'Menantang'},
    ]
  };

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isParentMode = appState.isParentMode;

    if (isParentMode) {
      return _buildParentMode(context, appState.childProfile.age);
    }

    if (gameState == 'menu') return _buildMenu();
    if (gameState == 'categorySelect') return _buildCategorySelect();
    return _buildGameSelect();
  }

  Widget _buildParentMode(BuildContext context, int childAge) {
    final ageGroup = _getAgeGroup(childAge);
    final tipsList = _parentTips[ageGroup] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Light green for cognitive parenting theme diff
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF3B82F6),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                            child: const Text('🧠', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Panduan Kognitif (Usia $childAge)', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 16)),
                                Text('Stimulasi kecerdasan logis berjenjang.', style: TextStyle(color: Colors.blue.shade50, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              title: Text('Modul Kognitif (Orang Tua)', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 18)),
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
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Mode Orang Tua aktif. Matikan mode ini dari menu profil untuk membiarkan layar anak bermain.', style: TextStyle(color: Colors.blue, fontSize: 12))),
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
                              gradient: LinearGradient(colors: [Colors.blue.shade100, Colors.blue.shade300]),
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

  Widget _buildMenu() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFBFDBFE), Color(0xFF93C5FD), Color(0xFF60A5FA)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              right: 20,
              child: AnimatedBuilder(
                animation: _brainAnimController,
                builder: (_, child) {
                  return Transform.rotate(
                    angle: _brainAnimController.value * 2 * 3.14159,
                    child: const Text('💡', style: TextStyle(fontSize: 60)),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
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
                    
                    _buildHeroHeader(
                      'Latih Kemampuan\nKognitif! 🧠',
                      'Pilih kategori untuk melatih berbagai aspek kemampuan kognitifmu melalui permainan yang seru!',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Area Fokus:', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 20),
                          _buildAreaItem(Icons.my_location_rounded, 'Logika & Penalaran', const Color(0xFF60A5FA)),
                          _buildAreaItem(Icons.psychology_rounded, 'Memori & Konsentrasi', const Color(0xFF34D399)),
                          _buildAreaItem(Icons.grid_view_rounded, 'Visual & Bayangan', const Color(0xFFF472B6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 8,
                        ),
                        onPressed: () => setState(() => gameState = 'categorySelect'),
                        child: Text('🧠 Pilih Kategori!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaItem(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 16, child: Icon(icon, size: 16, color: Colors.white)),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.blue.shade50)),
        ],
      ),
    );
  }

  Widget _buildCategorySelect() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFC084FC), Color(0xFFA855F7), Color(0xFF9333EA)], // purple-400, purple-500, purple-600
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
                      onTap: () => setState(() => gameState = 'menu'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Hero Section
                _buildHeroHeader(
                  'Pilih Bidang\nKekuatanmu! 🌟',
                  'Setiap kategori menguji kemampuan yang berbeda. Mana yang ingin kamu latih lebih dulu?',
                ),
                
                const SizedBox(height: 32),
                
                _buildCategoryCard('🎯', 'Logika & Penalaran', 'Latih kemampuan berpikir logis dan matematis.', ['Matematika', 'Logika'], 'logic'),
                _buildCategoryCard('🧠', 'Memori & Konsentrasi', 'Tingkatkan daya ingat jangka pendek dan fokus.', ['Memori', 'Konsentrasi'], 'memory'),
                _buildCategoryCard('🔮', 'Visual & Bayangan', 'Asah kemampuan mengenali pola, bentuk, dan bayangan visual.', ['Visual', 'Ketelitian'], 'abstract'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(String title, String subtitle) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(String icon, String title, String desc, List<String> tags, String id) {
    return GestureDetector(
      onTap: () {
        selectedCategory = id;
        setState(() => gameState = 'gameSelect');
      },
      child: Container(
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
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: Text(icon, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), height: 1.2)),
                  const SizedBox(height: 12),
                  Row(
                    children: tags.map((t) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(t, style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    )).toList(),
                  )
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.5), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSelect() {
    String title = '';
    String subtitle = '';
    List<Color> gradient = [];

    if (selectedCategory == 'logic') {
      title = 'Asah Logika\n& Nalar! 🎯';
      subtitle = 'Game di kategori ini melatih kemampuanmu dalam memecahkan masalah dan berpikir kritis.';
      gradient = [const Color(0xFF60A5FA), const Color(0xFF3B82F6), const Color(0xFF2563EB)]; // blue
    } else if (selectedCategory == 'memory') {
      title = 'Siap Melatih\nIngatan? 🧠';
      subtitle = 'Latih daya ingat jangka pendek dan fokus konsentrasimu dengan berbagai permainan seru.';
      gradient = [const Color(0xFF34D399), const Color(0xFF10B981), const Color(0xFF059669)]; // green
    } else {
      title = 'Visual &\nBayangan! 🔮';
      subtitle = 'Kategori ini membantumu mengenali presisi bentuk, pola visual, dan melatih ketelitian mata.';
      gradient = [const Color(0xFFF472B6), const Color(0xFFEC4899), const Color(0xFFDB2777)]; // pink
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: gradient,
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
                      onTap: () => setState(() => gameState = 'categorySelect'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Hero Section
                _buildHeroHeader(title, subtitle),
                
                const SizedBox(height: 32),

                // Games List
                if (selectedCategory == 'logic') ...[
                  _buildGameCard('🛸', 'Alien Math Shooter', 'Tembak jawaban yang benar!', () {
                    Navigator.pushNamed(context, '/alien-shooter');
                  }),
                  const SizedBox(height: 16),
                  _buildGameCard('🏜️', 'Desert Road Logic', 'Logika di jalan gurun!', () {
                    Navigator.pushNamed(context, '/desert-road-logic');
                  }),
                  const SizedBox(height: 16),
                  _buildGameCard('🚰', 'Pipa Air', 'Sambung aliran air pipa!', () {
                    Navigator.pushNamed(context, '/pipe-puzzle');
                  }),
                  const SizedBox(height: 16),
                  _buildGameCard('🧮', 'Urutan Angka', 'Lengkapi angka yang hilang!', () {
                    Navigator.pushNamed(context, '/number-sequence-game');
                  }),
                ],
                if (selectedCategory == 'memory') ...[
                  _buildGameCard('🃏', 'Memory Card Flip', 'Cocokkan kartu yang sama!', () {
                    Navigator.pushNamed(context, '/memory-game');
                  }),
                  const SizedBox(height: 16),
                  _buildGameCard('🔢', 'Sequence Memory', 'Ingat urutan yang muncul!', () {
                    Navigator.pushNamed(context, '/sequence-memory-game');
                  }),
                  const SizedBox(height: 16),
                  _buildGameCard('🔟', 'Number Memory', 'Ingat angka yang ditampilkan!', () {
                    Navigator.pushNamed(context, '/number-memory-game');
                  }),
                ],
                if (selectedCategory == 'abstract') ...[
                  _buildGameCard('🔮', 'Pattern Recognition', 'Kenali pola dan lanjutkan!', () {
                    Navigator.pushNamed(context, '/pattern-recognition-game');
                  }),
                  const SizedBox(height: 16),
                  _buildGameCard('👥', 'Tebak Bayangan', 'Cocokkan rupa benda dengan siluetnya!', () {
                    Navigator.pushNamed(context, '/shadow-match');
                  }),
                  const SizedBox(height: 16),
                  _buildGameCard('🎨', 'Pilah Bentuk', 'Sortir bentuk berdasarkan pola!', () {
                    Navigator.pushNamed(context, '/shape-sorting-game');
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(String icon, String title, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
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
                  Text(desc, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill_rounded, color: Colors.white.withOpacity(0.8), size: 32),
          ],
        ),
      ),
    );
  }

}
