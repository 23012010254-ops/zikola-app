import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class MotorTipsScreen extends StatefulWidget {
  const MotorTipsScreen({super.key});

  @override
  State<MotorTipsScreen> createState() => _MotorTipsScreenState();
}

class _MotorTipsScreenState extends State<MotorTipsScreen> {
  String _selectedCategory = 'gross'; // 'gross' or 'fine'

  String _getAgeGroup(int age) {
    if (age >= 5 && age <= 7) return 'early';
    if (age >= 8 && age <= 10) return 'middle';
    return 'late'; // 11-12
  }

  // Same structure as the React component
  final Map<String, dynamic> _motorTips = {
    'gross': {
      'title': 'Motorik Kasar',
      'icon': '🏃‍♂️',
      'description': 'Gerakan otot-otot besar seperti berjalan, berlari, melompat',
      'colors': [Colors.blue.shade500, Colors.blue.shade600],
      'early': [
        {
          'title': 'Bermain Bola Sederhana',
          'type': 'video',
          'duration': '8 menit',
          'description': 'Latihan menendang, melempar, dan menangkap bola dengan cara yang menyenangkan',
          'thumbnail': '⚽',
          'difficulty': 'Mudah',
          'benefits': ['Koordinasi mata-kaki', 'Keseimbangan', 'Konsentrasi']
        },
        {
          'title': 'Senam Pagi Anak',
          'type': 'video',
          'duration': '12 menit',
          'description': 'Gerakan senam sederhana untuk mengembangkan fleksibilitas dan kekuatan',
          'thumbnail': '🤸‍♀️',
          'difficulty': 'Mudah',
          'benefits': ['Fleksibilitas', 'Kekuatan otot', 'Koordinasi']
        },
        {
          'title': 'Permainan Lari Obstacle',
          'type': 'pdf',
          'pages': '6 halaman',
          'description': 'Panduan membuat track obstacle sederhana di rumah',
          'thumbnail': '🏃‍♂️',
          'difficulty': 'Mudah',
          'benefits': ['Kelincahan', 'Kecepatan', 'Problem solving']
        },
        {
          'title': 'Yoga untuk Anak Pemula',
          'type': 'video',
          'duration': '15 menit',
          'description': 'Pose yoga dasar yang aman dan menyenangkan untuk anak',
          'thumbnail': '🧘‍♀️',
          'difficulty': 'Mudah',
          'benefits': ['Keseimbangan', 'Konsentrasi', 'Relaksasi']
        }
      ],
      'middle': [
        {
          'title': 'Basketball Skills Basic',
          'type': 'video',
          'duration': '18 menit',
          'description': 'Teknik dasar basket: dribbling, shooting, passing',
          'thumbnail': '🏀',
          'difficulty': 'Sedang',
          'benefits': ['Koordinasi tangan-mata', 'Timing', 'Konsentrasi']
        },
        {
          'title': 'Gymnastics Fun',
          'type': 'video',
          'duration': '20 menit',
          'description': 'Gerakan senam lantai sederhana yang aman',
          'thumbnail': '🤸‍♀️',
          'difficulty': 'Sedang',
          'benefits': ['Fleksibilitas', 'Kekuatan', 'Kepercayaan diri']
        },
        {
          'title': 'Martial Arts untuk Anak',
          'type': 'pdf',
          'pages': '12 halaman',
          'description': 'Gerakan dasar beladiri yang fokus pada disiplin dan kontrol',
          'thumbnail': '🥋',
          'difficulty': 'Sedang',
          'benefits': ['Disiplin', 'Koordinasi', 'Fokus']
        }
      ],
      'late': [
        {
          'title': 'Soccer Training Advanced',
          'type': 'video',
          'duration': '25 menit',
          'description': 'Teknik sepakbola tingkat menengah dengan strategi',
          'thumbnail': '⚽',
          'difficulty': 'Menantang',
          'benefits': ['Strategi', 'Teamwork', 'Atletis']
        },
        {
          'title': 'Athletic Training',
          'type': 'video',
          'duration': '30 menit',
          'description': 'Program latihan atletik yang terstruktur',
          'thumbnail': '🏃‍♂️',
          'difficulty': 'Menantang',
          'benefits': ['Stamina', 'Kecepatan', 'Kekuatan']
        }
      ]
    },
    'fine': {
      'title': 'Motorik Halus',
      'icon': '✏️',
      'description': 'Gerakan otot-otot kecil seperti menulis, menggambar, memotong',
      'colors': [Colors.purple.shade500, Colors.purple.shade600],
      'early': [
        {
          'title': 'Finger Painting Fun',
          'type': 'video',
          'duration': '10 menit',
          'description': 'Teknik melukis dengan jari untuk melatih kreativitas',
          'thumbnail': '🎨',
          'difficulty': 'Mudah',
          'benefits': ['Kreativitas', 'Koordinasi jari', 'Ekspresi diri']
        },
        {
          'title': 'Origami Sederhana',
          'type': 'pdf',
          'pages': '8 halaman',
          'description': 'Panduan melipat kertas dengan bentuk-bentuk sederhana',
          'thumbnail': '📜',
          'difficulty': 'Mudah',
          'benefits': ['Presisi', 'Konsentrasi', 'Mengikuti instruksi']
        },
        {
          'title': 'Playdough Activities',
          'type': 'video',
          'duration': '12 menit',
          'description': 'Berbagai permainan dengan plastisin untuk melatih jari',
          'thumbnail': '🎭',
          'difficulty': 'Mudah',
          'benefits': ['Kekuatan jari', 'Kreativitas', 'Tekstur']
        },
        {
          'title': 'Tracing & Writing',
          'type': 'pdf',
          'pages': '15 halaman',
          'description': 'Lembar kerja untuk latihan menebalkan garis dan huruf',
          'thumbnail': '✏️',
          'difficulty': 'Mudah',
          'benefits': ['Kontrol pensil', 'Menulis', 'Konsentrasi']
        }
      ],
      'middle': [
        {
          'title': 'Advanced Drawing',
          'type': 'video',
          'duration': '20 menit',
          'description': 'Teknik menggambar dengan detail dan proporsi',
          'thumbnail': '🖊️',
          'difficulty': 'Sedang',
          'benefits': ['Detail', 'Presisi', 'Artistik']
        },
        {
          'title': 'Paper Craft Projects',
          'type': 'pdf',
          'pages': '18 halaman',
          'description': 'Proyek kerajinan kertas yang lebih kompleks',
          'thumbnail': '📄',
          'difficulty': 'Sedang',
          'benefits': ['Perencanaan', 'Eksekusi', 'Kreativitas']
        },
        {
          'title': 'Beading & Threading',
          'type': 'video',
          'duration': '15 menit',
          'description': 'Membuat gelang dan kalung dengan manik-manik',
          'thumbnail': '📿',
          'difficulty': 'Sedang',
          'benefits': ['Koordinasi mata-tangan', 'Pola', 'Kesabaran']
        }
      ],
      'late': [
        {
          'title': 'Calligraphy Basic',
          'type': 'video',
          'duration': '25 menit',
          'description': 'Seni menulis indah dengan teknik kaligrafi',
          'thumbnail': '🖋️',
          'difficulty': 'Menantang',
          'benefits': ['Presisi tinggi', 'Estetika', 'Konsentrasi']
        },
        {
          'title': 'Model Making',
          'type': 'pdf',
          'pages': '20 halaman',
          'description': 'Membuat model 3D dengan bahan sederhana',
          'thumbnail': '🏗️',
          'difficulty': 'Menantang',
          'benefits': ['Perencanaan 3D', 'Problem solving', 'Teknis']
        }
      ]
    }
  };

  Map<String, dynamic> _getDifficultyStyle(String difficulty) {
    switch (difficulty) {
      case 'Mudah':
        return {'bg': Colors.green.shade100, 'text': Colors.green.shade700};
      case 'Sedang':
        return {'bg': Colors.yellow.shade100, 'text': Colors.yellow.shade800};
      case 'Menantang':
        return {'bg': Colors.red.shade100, 'text': Colors.red.shade700};
      default:
        return {'bg': Colors.grey.shade100, 'text': Colors.grey.shade700};
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final childAge = appState.childProfile.age;
    final isParentMode = appState.isParentMode;

    if (!isParentMode) {
      return _buildChildMode(context, childAge);
    }
    
    final ageGroup = _getAgeGroup(childAge);
    final currentCategoryData = _motorTips[_selectedCategory];
    final List<dynamic> currentTips = currentCategoryData[ageGroup];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // gray-50
      body: CustomScrollView(
        slivers: [
          _buildHeader(childAge, isParentMode: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Mode Orang Tua: Ketuk profil Anda untuk melihat versi game anak.', style: TextStyle(color: Colors.blue.shade700, fontSize: 12))),
                      ],
                    ),
                  ),

                  _buildCategoryTabs(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentCategoryData['title'],
                        style: AppTheme.heading2.copyWith(color: AppTheme.gray900),
                      ),
                      Text(
                        '${currentTips.length} aktivitas',
                        style: AppTheme.bodyText.copyWith(color: AppTheme.gray500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ...currentTips.map((tip) => _buildTipCard(tip, currentCategoryData, appState)).toList(),
                  
                  const SizedBox(height: 32),
                  _buildParentInfoCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildMode(BuildContext context, int childAge) {
    return Scaffold(
      backgroundColor: const Color(0xFFC0FBDF), // soft vibrant green 
      body: Stack(
        children: [
          // Background Elements
          Positioned(top: -50, right: -50, child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.5), size: 150)),
          Positioned(top: 200, left: -30, child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.4), size: 100)),
          Positioned(bottom: 100, right: -20, child: Icon(Icons.park, color: Colors.white.withOpacity(0.3), size: 180)),
          Positioned(bottom: 300, left: 10, child: Icon(Icons.park, color: Colors.white.withOpacity(0.2), size: 120)),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: 1050, 
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Header title
                    Positioned(
                      top: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.green.shade700.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]
                        ),
                        child: Text(
                          'Peta Petualangan! 🗺️',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _MapPathPainter(),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 150, 
                      left: 60,
                      child: _MapNode(title: 'Tangkap\nKelinci', icon: '🐰', color: Colors.green, onTap: () => Navigator.pushNamed(context, '/motor-test-game')),
                    ),
                    Positioned(
                      bottom: 400,
                      right: 60,
                      child: _MapNode(title: 'Galaksi\nGaris', icon: '🌟', color: Colors.purple, onTap: () => Navigator.pushNamed(context, '/motor-trace-game')),
                    ),
                    Positioned(
                      bottom: 650,
                      left: 80,
                      child: _MapNode(title: 'Buku\nMewarnai', icon: '🎨', color: Colors.pink, onTap: () => Navigator.pushNamed(context, '/coloring-game')),
                    ),
                    Positioned(
                      bottom: 800,
                      right: 80,
                      child: _MapNode(title: 'Pecah\nGelembung', icon: '🫧', color: Colors.blue, onTap: () => Navigator.pushNamed(context, '/bubble-popper')),
                    ),
                    
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(int childAge, {required bool isParentMode}) {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: Colors.green.shade600,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('🎯', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesuai Usia $childAge Tahun',
                            style: AppTheme.heading3.copyWith(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Konten disesuaikan dengan tahap perkembangan anak',
                            style: AppTheme.bodyText.copyWith(color: Colors.green.shade50, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Text(isParentMode ? 'Tips Motorik (Orang Tua)' : 'Game Motorik', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 18)),
      centerTitle: true,
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: _motorTips.entries.map((entry) {
          final isSelected = _selectedCategory == entry.key;
          final category = entry.value;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [Colors.green.shade500, Colors.green.shade600],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(category['icon'], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(
                      category['title'],
                      style: AppTheme.heading3.copyWith(
                        color: isSelected ? Colors.white : AppTheme.gray700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['description'],
                      style: AppTheme.bodyText.copyWith(
                        color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.gray500,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }



  Widget _buildTipCard(Map<String, dynamic> tip, Map<String, dynamic> category, AppState appState) {
    final diffStyle = _getDifficultyStyle(tip['difficulty']);
    final isVideo = tip['type'] == 'video';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: category['colors']),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(tip['thumbnail'], style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tip['title'],
                        style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isVideo ? Colors.blue.shade50 : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVideo ? Icons.play_arrow : Icons.description,
                            color: isVideo ? Colors.blue.shade600 : Colors.purple.shade600,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVideo ? tip['duration'] : tip['pages'],
                            style: TextStyle(
                              color: isVideo ? Colors.blue.shade600 : Colors.purple.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tip['description'],
                  style: AppTheme.bodyText.copyWith(color: AppTheme.gray600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffStyle['bg'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tip['difficulty'],
                    style: TextStyle(color: diffStyle['text'], fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                
                Text('Manfaat:', style: AppTheme.bodyText.copyWith(color: AppTheme.gray500, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (tip['benefits'] as List).map((b) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      b.toString(),
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Membuka ${isVideo ? 'video' : 'PDF'}: ${tip['title']}')),
                      );
                      appState.addSticker('tips-explorer');
                    },
                    icon: Icon(isVideo ? Icons.play_arrow : Icons.download),
                    label: Text(isVideo ? 'Tonton' : 'Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVideo ? Colors.blue.shade500 : Colors.purple.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('💡', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips untuk Orang Tua',
                  style: AppTheme.heading3.copyWith(color: Colors.orange.shade800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dampingi anak saat melakukan aktivitas dan berikan pujian atas usahanya. Konsistensi latihan lebih penting daripada kesempurnaan.',
                  style: AppTheme.bodyText.copyWith(color: Colors.orange.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNode extends StatefulWidget {
  final String title;
  final String icon;
  final Color color;
  final VoidCallback onTap;
  
  const _MapNode({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  State<_MapNode> createState() => _MapNodeState();
}

class _MapNodeState extends State<_MapNode> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -10 * _ctrl.value),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withOpacity(0.5), width: 8),
                boxShadow: [
                  BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10))
                ],
              ),
              child: Center(child: Text(widget.icon, style: const TextStyle(fontSize: 50))),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 4))],
              ),
              child: Text(
                widget.title, 
                textAlign: TextAlign.center, 
                style: TextStyle(fontWeight: FontWeight.w900, color: widget.color, fontSize: 14, height: 1.2)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2 + 50, size.height - 150);
    path.quadraticBezierTo(size.width * 0.9, size.height - 250, size.width * 0.8 - 50, size.height - 400);
    path.quadraticBezierTo(size.width * 0.1, size.height - 550, size.width * 0.2 + 50, size.height - 650);
    path.quadraticBezierTo(size.width * 0.9, size.height - 725, size.width * 0.8 - 50, size.height - 800);
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

