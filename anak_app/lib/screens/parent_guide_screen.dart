import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ParentGuideScreen extends StatefulWidget {
  const ParentGuideScreen({super.key});

  @override
  State<ParentGuideScreen> createState() => _ParentGuideScreenState();
}

class _ParentGuideScreenState extends State<ParentGuideScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final Set<String> _bookmarkedIds = {};

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'Semua', 'icon': '📚'},
    {'id': 'tantrum', 'label': 'Emosi & Tantrum', 'icon': '🧘'},
    {'id': 'feeding', 'label': 'Aturan Makan', 'icon': '🥗'},
    {'id': 'stimulasi', 'label': 'Stimulasi & Bahasa', 'icon': '🧠'},
    {'id': 'sleep', 'label': 'Pola Tidur', 'icon': '😴'},
    {'id': 'screen_time', 'label': 'Gadget & Layar', 'icon': '📱'},
  ];

  final List<Map<String, dynamic>> _guides = [
    {
      'id': 'g1',
      'category': 'tantrum',
      'title': 'Cara Mengatasi Tantrum dengan Validasi Emosi',
      'subtitle': 'Langkah tenang menghadapi ledakan emosi anak tanpa membentak.',
      'age': '2 - 6 Tahun',
      'readTime': '4 mnt baca',
      'icon': '🧘',
      'color': const Color(0xFF8B5CF6),
      'overview': 'Tantrum adalah respons wajar saat anak merasa kewalahan oleh emosi besar yang belum mampu diungkapkan dengan kata-kata. Kuncinya adalah mendampingi, bukan menghukum.',
      'steps': [
        'Tetap tenang dan atur napas Anda sendiri terlebih dahulu.',
        'Turunkan posisi tubuh sejajar dengan pandangan mata anak.',
        'Validasi perasaannya: "Bunda tahu kamu kecewa karena mainan belum boleh dibeli."',
        'Beri pelukan atau ruang aman hingga emosinya mereda secara bertahap.',
        'Diskusikan solusinya setelah anak benar-benar tenang.'
      ],
      'dos': [
        'Tetap hadir dan beri kehadiran fisik yang menenangkan',
        'Gunakan nada suara yang rendah dan stabil',
        'Beri pilihan sederhana saat anak mulai tenang'
      ],
      'donts': [
        'Membentak, mempermalukan, atau memukul',
        'Menuruti semua tuntutan hanya agar anak berhenti menangis',
        'Mengajak berdebat logika saat anak sedang histeris'
      ],
      'expertTip': 'Anak tidak sedang "mencari masalah", melainkan sedang "mengalami masalah". Kehadiran Anda adalah jangkar ketenangannya.'
    },
    {
      'id': 'g2',
      'category': 'feeding',
      'title': 'Feeding Rules: Solusi Anak GTM (Gerakan Tutup Mulut)',
      'subtitle': 'Panduan IDAI menciptakan hubungan sehat anak dengan makanan.',
      'age': '1 - 7 Tahun',
      'readTime': '5 mnt baca',
      'icon': '🥗',
      'color': const Color(0xFF10B981),
      'overview': 'GTM seringkali bukan karena anak tidak lapar, melainkan karena suasana makan yang penuh tekanan atau terdistraksi gadget.',
      'steps': [
        'Terapkan jadwal makan teratur (3x makan utama, 2x snack).',
        'Batasi durasi makan maksimal 30 menit per sesi.',
        'Ciptakan lingkungan bebas distraksi (tanpa TV, HP, atau mainan).',
        'Jangan paksa anak makan jika sudah menolak; tawarkan kembali di jadwal berikutnya.',
        'Libatkan anak dalam menyiapkan makanan untuk memicu nafsu makan.'
      ],
      'dos': [
        'Makan bersama keluarga di meja makan',
        'Hargai sinyal kenyang dari anak',
        'Sajikan porsi kecil terlebih dahulu'
      ],
      'donts': [
        'Menyuapi sambil menonton video gadget (Screen-feeding)',
        'Memaksa atau mengancam agar makanan habis',
        'Memberi susu berlebih mendekati jam makan utama'
      ],
      'expertTip': 'Tugas orang tua adalah menentukan APA, KAPAN, dan DI MANA makan. Tugas anak adalah menentukan BERAPA BANYAK mereka makan.'
    },
    {
      'id': 'g3',
      'category': 'stimulasi',
      'title': 'Stimulasi Bicara & Cegah Speech Delay',
      'subtitle': 'Latihan komunikasi interaktif sehari-hari di rumah.',
      'age': '1 - 5 Tahun',
      'readTime': '4 mnt baca',
      'icon': '🗣️',
      'color': const Color(0xFF3B82F6),
      'overview': 'Kemampuan bahasa berkembang pesat lewat percakapan 2 arah yang responsif dan kaya kosakata.',
      'steps': [
        'Narasikan setiap aktivitas harian (contoh: "Bunda sedang memotong wortel oranye").',
        'Bacakan buku cerita interaktif setiap hari minimal 15 menit.',
        'Tunggu 5-10 detik setelah bertanya agar anak punya waktu menyusun kata.',
        'Ulangi dan perluas kalimat anak dengan benar tanpa mengkritik.',
        'Ajak bermain cilukba, tebak suara hewan, atau bernyanyi bersama.'
      ],
      'dos': [
        'Gunakan kontak mata dan ekspresi wajah yang jelas',
        'Gunakan kata yang benar (hindari bahasa bayi/cadel yang disengaja)',
        'Dengarkan anak dengan penuh perhatian saat ia mencoba bicara'
      ],
      'donts': [
        'Membiarkan anak menonton video pasif lebih dari 1 jam per hari',
        'Langsung memberikan barang sebelum anak mencoba menunjuk atau mengucapkannya',
        'Memotong kalimat anak saat ia sedang berusaha mengekspresikan diri'
      ],
      'expertTip': 'Kualitas percakapan tatap muka 10x lebih efektif meningkatkan kosakata dibandingkan aplikasi edukatif apa pun di layar.'
    },
    {
      'id': 'g4',
      'category': 'sleep',
      'title': 'Sleep Hygiene: Jadwal Tidur Anak yang Berkualitas',
      'subtitle': 'Ritual sebelum tidur agar anak tidur lelap dan hormon tumbuh optimal.',
      'age': 'Semua Usia',
      'readTime': '3 mnt baca',
      'icon': '😴',
      'color': const Color(0xFFF59E0B),
      'overview': 'Hormon pertumbuhan (Growth Hormone) diproduksi maksimal saat anak tidur nyenyak di fase deep sleep antara jam 22.00 - 02.00.',
      'steps': [
        'Tentukan jam tidur yang konsisten setiap malam.',
        'Mulai rutinitas relaksasi 30 menit sebelum tidur (mandi air hangat, gosok gigi, dongeng).',
        'Redupkan lampu kamar dan pastikan suhu ruangan sejuk.',
        'Matikan seluruh layar gadget minimal 1 jam sebelum waktu tidur.',
        'Beri afirmasi positif dan pelukan hangat sebelum anak terlelap.'
      ],
      'dos': [
        'Jaga suasana kamar tenang dan nyaman',
        'Buat rutinitas tidur yang berurutan dan teratur',
        'Pastikan anak cukup aktivitas fisik di siang hari'
      ],
      'donts': [
        'Memberi minuman manis atau cokelat di malam hari',
        'Menggunakan gadget sebagai pengantar tidur',
        'Menjadikan tempat tidur sebagai tempat hukuman'
      ],
      'expertTip': 'Kamar yang gelap total merangsang hormon melatonin, membuat anak tidur lebih nyenyak dan bangun dengan suasana hati ceria.'
    },
    {
      'id': 'g5',
      'category': 'screen_time',
      'title': 'Panduan Bijak Screen Time Sesuai Rekomendasi WHO',
      'subtitle': 'Mencegah kecanduan gadget dan menjaga fokus belajar anak.',
      'age': '2 - 12 Tahun',
      'readTime': '4 mnt baca',
      'icon': '📱',
      'color': const Color(0xFFEC4899),
      'overview': 'Gadget adalah alat yang bermanfaat jika digunakan dengan batasan yang jelas, terstruktur, dan didampingi secara aktif oleh orang tua.',
      'steps': [
        'Anak usia < 2 tahun: Nol screen time (kecuali video call dengan keluarga).',
        'Anak usia 2 - 5 tahun: Maksimal 1 jam per hari dengan konten berkualitas tinggi.',
        'Terapkan zona bebas gadget di meja makan dan kamar tidur.',
        'Dampingi anak saat bermain game edukatif untuk membangun interaksi 2 arah.',
        'Sediakan alternatif aktivitas fisik seperti mewarnai, bermain balok, atau bersepeda.'
      ],
      'dos': [
        'Pilih konten interaktif yang melatih logika dan sensorik',
        'Buat kesepakatan batas waktu sebelum gadget diberikan',
        'Jadilah teladan dengan tidak bermain gadget saat bersama anak'
      ],
      'donts': [
        'Menjadikan gadget sebagai "babysitter" saat anak rewel',
        'Mengizinkan penggunaan gadget saat makan atau sebelum tidur',
        'Memberikan akses tanpa filter keamanan anak'
      ],
      'expertTip': 'Bukan hanya tentang durasi layar, tapi juga apa yang anak lewatkan (seperti interaksi sosial dan gerak fisik) saat menatap layar.'
    },
  ];

  List<Map<String, dynamic>> get _filteredGuides {
    return _guides.where((g) {
      final matchesCategory = _selectedCategory == 'all' || g['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          g['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g['subtitle'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showGuideDetail(Map<String, dynamic> guide) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (guide['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Usia: ${guide['age']}',
                            style: TextStyle(
                              color: guide['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _bookmarkedIds.contains(guide['id']) ? Icons.bookmark : Icons.bookmark_border,
                            color: _bookmarkedIds.contains(guide['id']) ? Colors.amber.shade700 : AppTheme.gray400,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_bookmarkedIds.contains(guide['id'])) {
                                _bookmarkedIds.remove(guide['id']);
                              } else {
                                _bookmarkedIds.add(guide['id'] as String);
                              }
                            });
                            Navigator.pop(ctx);
                            _showGuideDetail(guide);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      guide['title'] as String,
                      style: AppTheme.heading2.copyWith(color: AppTheme.gray900, fontSize: 20, height: 1.25),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      guide['subtitle'] as String,
                      style: AppTheme.bodyText.copyWith(color: AppTheme.gray500, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.gray200),
                      ),
                      child: Text(
                        guide['overview'] as String,
                        style: AppTheme.bodyText.copyWith(color: AppTheme.gray700, fontSize: 13, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Langkah Praktis', style: AppTheme.heading3.copyWith(fontSize: 16)),
                    const SizedBox(height: 12),
                    ...(guide['steps'] as List<String>).asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: (guide['color'] as Color).withValues(alpha: 0.15),
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(color: guide['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppTheme.bodyText.copyWith(color: AppTheme.gray800, fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Color(0xFF059669), size: 16),
                                    SizedBox(width: 6),
                                    Text('Dianjurkan', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...(guide['dos'] as List<String>).map((d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('• $d', style: const TextStyle(color: Color(0xFF064E3B), fontSize: 11, height: 1.35)),
                                )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.cancel, color: Color(0xFFDC2626), size: 16),
                                    SizedBox(width: 6),
                                    Text('Hindari', style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ...(guide['donts'] as List<String>).map((d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('• $d', style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 11, height: 1.35)),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (guide['color'] as Color).withValues(alpha: 0.1),
                            (guide['color'] as Color).withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: (guide['color'] as Color).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pesan Pakar', style: TextStyle(color: guide['color'] as Color, fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  guide['expertTip'] as String,
                                  style: AppTheme.bodyText.copyWith(color: AppTheme.gray800, fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: guide['color'] as Color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup Panduan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Panduan & Tips Orang Tua', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back, color: Color(0xFF475569), size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: AppTheme.gray400, size: 20),
                      hintText: 'Cari panduan (misal: tantrum, makan, tidur)...',
                      hintStyle: TextStyle(fontSize: 13, color: AppTheme.gray400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['id'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(cat['icon'] as String, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 6),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.gray600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
          Expanded(
            child: _filteredGuides.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Tidak ada panduan ditemukan', style: AppTheme.heading3.copyWith(color: AppTheme.gray700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Coba gunakan kata kunci pencarian yang lain.', style: AppTheme.bodyText.copyWith(color: AppTheme.gray400, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredGuides.length,
                    itemBuilder: (ctx, i) {
                      final guide = _filteredGuides[i];
                      final isBookmarked = _bookmarkedIds.contains(guide['id']);

                      return GestureDetector(
                        onTap: () => _showGuideDetail(guide),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.gray100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: (guide['color'] as Color).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(guide['icon'] as String, style: const TextStyle(fontSize: 24)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (guide['color'] as Color).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                guide['age'] as String,
                                                style: TextStyle(color: guide['color'] as Color, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              guide['readTime'] as String,
                                              style: const TextStyle(color: AppTheme.gray400, fontSize: 10, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          guide['title'] as String,
                                          style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 15, height: 1.25),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                      color: isBookmarked ? Colors.amber.shade700 : AppTheme.gray300,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (isBookmarked) {
                                          _bookmarkedIds.remove(guide['id']);
                                        } else {
                                          _bookmarkedIds.add(guide['id'] as String);
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                guide['subtitle'] as String,
                                style: AppTheme.bodyText.copyWith(color: AppTheme.gray500, fontSize: 12, height: 1.4),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.verified, color: Color(0xFF8B5CF6), size: 14),
                                      const SizedBox(width: 4),
                                      Text('Ditinjau Pakar Psikologi', style: TextStyle(color: Colors.purple.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text('Baca Selengkapnya', style: TextStyle(color: guide['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 2),
                                      Icon(Icons.arrow_forward_ios, color: guide['color'] as Color, size: 10),
                                    ],
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
        ],
      ),
    );
  }
}
