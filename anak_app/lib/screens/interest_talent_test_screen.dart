import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class InterestTalentTestScreen extends StatefulWidget {
  const InterestTalentTestScreen({super.key});

  @override
  State<InterestTalentTestScreen> createState() => _InterestTalentTestScreenState();
}

class _InterestTalentTestScreenState extends State<InterestTalentTestScreen> {
  final List<String> _selectedInterests = [];
  bool _showResult = false;

  final List<Map<String, dynamic>> _interests = [
    {
      'id': 'sains',
      'emoji': '🔬',
      'label': 'Sains & Eksperimen',
      'category': 'Logika Eksplorasi',
      'color': const Color(0xFF3B82F6),
      'desc': 'Suka mengamati fenomena alam, mencampur warna, dan bertanya "mengapa".',
      'activities': ['Eksperimen gunung meletus sederhana', 'Buku ensiklopedia bergambar', 'Kaca pembesar untuk serangga'],
      'extracurricular': ['Klub Sains Anak', 'Robotik Dasar', 'Eksplorasi Alam'],
    },
    {
      'id': 'seni',
      'emoji': '🎨',
      'label': 'Seni & Kreativitas',
      'category': 'Kecerdasan Spasial',
      'color': const Color(0xFFEC4899),
      'desc': 'Suka menggambar, mewarnai, membuat kreasi origami, dan bermain playdough.',
      'activities': ['Finger painting & kolase', 'Membuat diorama dari kardus bekas', 'Bermain tanah liat / lilin mainan'],
      'extracurricular': ['Kelas Lukis / Menggambar', 'Crafting & Keramik', 'Desain Kreatif'],
    },
    {
      'id': 'musik',
      'emoji': '🎵',
      'label': 'Musik & Irama',
      'category': 'Kecerdasan Musikal',
      'color': const Color(0xFF8B5CF6),
      'desc': 'Peka terhadap ketukan nada, suka bernyanyi, dan menari mengikuti irama.',
      'activities': ['Bermain alat musik perkusi sederhana', 'Tebak instrumen dari lagu', 'Membuat lirik lagu pendek bersama'],
      'extracurricular': ['Les Piano / Keyboard', 'Kelas Vokal Anak', 'Tari & Balet'],
    },
    {
      'id': 'olahraga',
      'emoji': '⚽',
      'label': 'Olahraga & Fisik',
      'category': 'Kinestetik Tubuh',
      'color': const Color(0xFF10B981),
      'desc': 'Sangat aktif bergerak, lincah memanjat, bersepeda, dan punya stamina tinggi.',
      'activities': ['Bermain rintangan halang rintang di rumah', 'Berenang rutin', 'Sepak bola & lempar tangkap bola'],
      'extracurricular': ['Renang', 'Senam Gymnastic', 'Bela Diri (Taekwondo / Silat)'],
    },
    {
      'id': 'bahasa',
      'emoji': '📚',
      'label': 'Bahasa & Cerita',
      'category': 'Kecerdasan Linguistik',
      'color': const Color(0xFFF97316),
      'desc': 'Senang bercerita, mudah meniru kosakata baru, dan gemar didongengi buku.',
      'activities': ['Mendongeng dengan boneka tangan', 'Permainan sambung cerita keluarga', 'Membuat buku harian bergambar'],
      'extracurricular': ['Klub Debat / Storytelling', 'Kursus Bahasa Asing', 'Drama / Teater Anak'],
    },
    {
      'id': 'matematika',
      'emoji': '🔢',
      'label': 'Logika & Puzzle',
      'category': 'Logika-Matematika',
      'color': const Color(0xFF6366F1),
      'desc': 'Menyukai pola angka, teka-teki logika, catur, balok susun, dan susun maze.',
      'activities': ['Permainan balok susun / Lego kompleks', 'Teka-teki Sudoku gambar', 'Permainan papan strategi (Monopoli/Ular Tangga)'],
      'extracurricular': ['Catur Anak', 'Matematika Kreatif (Sempoa)', 'Coding Anak (Scratch)'],
    },
    {
      'id': 'alam',
      'emoji': '🌿',
      'label': 'Alam & Satwa',
      'category': 'Kecerdasan Naturalis',
      'color': const Color(0xFF14B8A6),
      'desc': 'Penuh kasih pada hewan peliharaan, suka berkebun, dan menikmati kegiatan outdoor.',
      'activities': ['Menanam bibit kacang hijau / bunga', 'Mengamati burung dan serangga di taman', 'Membuat herbarium daun kering'],
      'extracurricular': ['Pramuka / Petualang Cilik', 'Klub Sayang Satwa', 'Fotografi Alam'],
    },
    {
      'id': 'teknologi',
      'emoji': '💻',
      'label': 'Teknologi & Coding',
      'category': 'Digital Literacy',
      'color': const Color(0xFF0EA5E9),
      'desc': 'Cepat memahami navigasi gawai edukatif, suka merakit mekanisme mainan bongkar pasang.',
      'activities': ['Bermain coding blok visual (Scratch Jr)', 'Merakit sirkuit mainan baterai aman', 'Eksplorasi puzzle simulasi fisika'],
      'extracurricular': ['Kelas Coding & Game Making', 'Klub Robotik Mekanik', 'Animasi Sederhana'],
    },
    {
      'id': 'sosial',
      'emoji': '🤝',
      'label': 'Sosial & Teman',
      'category': 'Kecerdasan Interpersonal',
      'color': const Color(0xFFF59E0B),
      'desc': 'Mudah akrab dengan teman baru, berempati tinggi, dan senang memimpin kelompok bermain.',
      'activities': ['Bermain peran (Dokter-dokteran, Toko-tokoan)', 'Mengadakan sesi playdate bersama teman', 'Bakti sosial berbagi mainan'],
      'extracurricular': ['Organisasi Kepemimpinan Cilik', 'Public Speaking Anak', 'Palang Merah Remaja Cilik'],
    },
  ];

  List<Map<String, dynamic>> get _selectedInterestsData {
    return _interests.where((item) => _selectedInterests.contains(item['id'])).toList();
  }

  void _analyzeTalent() {
    if (_selectedInterests.isEmpty) return;
    setState(() {
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final childName = appState.childProfile.name.isNotEmpty ? appState.childProfile.name : 'Anak Bunda';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _showResult ? 'Laporan Potensi Bakat' : 'Eksplorasi Minat & Bakat',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back, color: Color(0xFF475569), size: 20),
          ),
          onPressed: () {
            if (_showResult) {
              setState(() => _showResult = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _showResult ? _buildResultView(childName) : _buildSelectionView(childName),
    );
  }

  Widget _buildSelectionView(String childName) {
    return Column(
      children: [
        // Intro Banner
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                    child: const Text('🎯', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apa yang paling disukai $childName?',
                          style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pilih 2 hingga 4 minat yang paling sering ditunjukkan.',
                          style: TextStyle(color: AppTheme.gray500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedInterests.length >= 2 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _selectedInterests.length >= 2 ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedInterests.length >= 2 ? '✓ Terpilih: ${_selectedInterests.length} Minat' : 'Pilih minimal 2 minat (${_selectedInterests.length}/2)',
                      style: TextStyle(
                        color: _selectedInterests.length >= 2 ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grid Selection
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: _interests.length,
            itemBuilder: (ctx, i) {
              final item = _interests[i];
              final isSelected = _selectedInterests.contains(item['id']);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(item['id']);
                    } else {
                      if (_selectedInterests.length < 5) {
                        _selectedInterests.add(item['id'] as String);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Maksimal memilih 5 minat utama')),
                        );
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? (item['color'] as Color).withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? (item['color'] as Color) : AppTheme.gray200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? (item['color'] as Color).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(item['emoji'] as String, style: const TextStyle(fontSize: 24)),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected ? (item['color'] as Color) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? (item['color'] as Color) : AppTheme.gray300,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? (item['color'] as Color) : AppTheme.gray900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['category'] as String,
                            style: const TextStyle(fontSize: 10, color: AppTheme.gray400, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Action Bottom Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.gray100)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                disabledBackgroundColor: AppTheme.gray300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: _selectedInterests.length >= 2 ? 4 : 0,
              ),
              onPressed: _selectedInterests.length >= 2 ? _analyzeTalent : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Analisis Potensi Bakat', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(String childName) {
    final selected = _selectedInterestsData;
    final primaryTalent = selected.isNotEmpty ? selected.first : _interests.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header Hero Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('✨ Profil Bakat Utama', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Text(primaryTalent['emoji'] as String, style: const TextStyle(fontSize: 32)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$childName adalah Tipe:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Penjelajah ${primaryTalent['label']}',
                style: AppTheme.heading1.copyWith(color: Colors.white, fontSize: 22, height: 1.2),
              ),
              const SizedBox(height: 10),
              Text(
                primaryTalent['desc'] as String,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section: Dominant Pillars
        Text('Pilar Potensi Unggulan', style: AppTheme.heading3.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        ...selected.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gray100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(item['emoji'] as String, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(item['category'] as String, style: const TextStyle(color: AppTheme.gray400, fontSize: 11)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.85,
                          backgroundColor: (item['color'] as Color).withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),

        // Section: Recommended Activities at Home
        Text('Rekomendasi Stimulasi di Rumah', style: AppTheme.heading3.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.home_work, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Text('Aktivitas Pendukung Bakat', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              ...selected.expand((s) => (s['activities'] as List<String>).take(1)).map((act) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎯 ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(act, style: const TextStyle(color: Color(0xFF166534), fontSize: 12, height: 1.35, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Suggested Extracurriculars
        Text('Saran Kegiatan / Ekstrakurikuler', style: AppTheme.heading3.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.school, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 8),
                  Text('Pilihan Kelas & Komunitas', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected.expand((s) => (s['extracurricular'] as List<String>)).toSet().map((extra) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Text(
                      extra,
                      style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppTheme.gray300),
                ),
                onPressed: () => setState(() => _showResult = false),
                child: const Text('Ulangi Asesmen', style: TextStyle(color: AppTheme.gray700, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Laporan Minat & Bakat berhasil disimpan ke rekam perkembangan anak! ✅'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Simpan Laporan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
