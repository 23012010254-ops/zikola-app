import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/test_result.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _FeaturedGame {
  final String id;
  final String title;
  final String description;
  final String image;
  final List<Color> gradient;
  final List<String> domains;
  final String gameKey;

  _FeaturedGame({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.gradient,
    required this.domains,
    required this.gameKey,
  });
}

class _AvailableGame {
  final String id;
  final String title;
  final String description;
  final String image;
  final Color bgColor;
  final List<String> domains;
  final String difficulty;
  final String time;
  final String reward;
  final Color rewardColor;
  final String rating;
  final String gameKey;

  _AvailableGame({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.bgColor,
    required this.domains,
    required this.difficulty,
    required this.time,
    required this.reward,
    required this.rewardColor,
    required this.rating,
    required this.gameKey,
  });
}

class _GameScreenState extends State<GameScreen> {
  bool _showDashboard = false;

  final _featuredGames = [
    _FeaturedGame(
      id: 'tank-shooter',
      title: 'Tantangan Tank',
      description: 'Pertahankan markas dari serangan tank!',
      image: '🚜',
      gradient: [const Color(0xFF10B981), const Color(0xFF047857)], 
      domains: ['Aksi', 'Kecepatan'],
      gameKey: 'tankShooter',
    )
  ];

  final _literacyGames = [
    _AvailableGame(
      id: 'spell-bee',
      title: 'Lomba Eja',
      description: 'Susun huruf jadi kata manis',
      image: '🐝',
      bgColor: const Color(0xFFFEF9C3),
      domains: ['Ejaan'],
      difficulty: 'Easy',
      time: '3 min',
      reward: '+30 ⭐',
      rewardColor: const Color(0xFFA16207),
      rating: '4.9',
      gameKey: 'spellBee',
    ),
  ];

  final _logicGames = [
    _AvailableGame(
      id: 'maze-game',
      title: 'Maze Adventure',
      description: 'Geser keluar!',
      image: '🗺️',
      bgColor: const Color(0xFFFFEDD5),
      domains: ['Spasial'],
      difficulty: 'Medium',
      time: '5 min',
      reward: '+50 ⭐',
      rewardColor: const Color(0xFFC2410C),
      rating: '4.9',
      gameKey: 'mazeGame',
    ),
    _AvailableGame(
      id: 'alien-shooter',
      title: 'Alien Shooter',
      description: 'Tembak alien jahat!',
      image: '🛸',
      bgColor: const Color(0xFFE0E7FF),
      domains: ['Aksi'],
      difficulty: 'Hard',
      time: '10 min',
      reward: '+40 ⭐',
      rewardColor: const Color(0xFF4338CA),
      rating: '4.7',
      gameKey: 'alienShooter',
    ),
  ];

  final _creativeGames = [
    _AvailableGame(
      id: 'shadow-match',
      title: 'Tebak Bayangan',
      description: 'Cocokkan rupa benda',
      image: '👥',
      bgColor: const Color(0xFFFCE7F3),
      domains: ['Visual', 'Ketelitian'],
      difficulty: 'Easy',
      time: '3 min',
      reward: '+80 ⭐',
      rewardColor: const Color(0xFFDB2777),
      rating: '4.9',
      gameKey: 'shadowMatch',
    ),
    _AvailableGame(
      id: 'sticker-fun',
      title: 'Pesta Stiker',
      description: 'Koleksi stiker lucu',
      image: '🌈',
      bgColor: const Color(0xFFF0FDF4),
      domains: ['Kreativitas'],
      difficulty: 'Easy',
      time: '5 min',
      reward: '+10 ⭐',
      rewardColor: const Color(0xFF16A34A),
      rating: '5.0',
      gameKey: 'stickerFun',
    ),
  ];

  void _handleGameClick(String id) {
    switch (id) {
      case 'spell-bee':
        Navigator.pushNamed(context, '/spell-bee');
        break;
      case 'tank-shooter':
        Navigator.pushNamed(context, '/desert-tank-shooter');
        break;
      case 'maze-game':
        Navigator.pushNamed(context, '/maze-game');
        break;
      case 'alien-shooter':
        Navigator.pushNamed(context, '/alien-shooter');
        break;
      case 'coloring-game':
        Navigator.pushNamed(context, '/coloring-game');
        break;
      case 'sticker-fun':
        Navigator.pushNamed(context, '/sticker-pesta');
        break;
      case 'pipe-puzzle':
        Navigator.pushNamed(context, '/pipe-puzzle');
        break;
      case 'shadow-match':
        Navigator.pushNamed(context, '/shadow-match');
        break;
      case 'bubble-popper':
        Navigator.pushNamed(context, '/bubble-popper');
        break;
      default:
        context.read<AppState>().addSticker('game-player');
        break;
    }
  }

  Map<String, dynamic>? _getOverallAssessment(TestResults results) {
    List<Map<String, dynamic>> played = [];
    if (results.cognitive.completed) played.add({'key': 'cognitive', 'averageScore': results.cognitive.percentage.round(), 'averageTime': results.cognitive.timeSpent, 'domains': ['KOGNITIF']});
    if (results.linguistic.completed) played.add({'key': 'linguistic', 'averageScore': results.linguistic.percentage.round(), 'averageTime': results.linguistic.timeSpent, 'domains': ['LINGUISTIK']});
    if (results.motor.completed) played.add({'key': 'motor', 'averageScore': results.motor.percentage.round(), 'averageTime': 0, 'domains': ['MOTORIK']});

    if (played.isEmpty) return null;

    int totalSessions = played.length;
    int avgScore = (played.fold(0, (sum, item) => sum + (item['averageScore'] as int)) / played.length).round();
    int avgTime = (played.fold(0, (sum, item) => sum + (item['averageTime'] as int)) / played.length).round();

    return {
      'totalSessions': totalSessions,
      'avgScore': avgScore,
      'avgTime': avgTime,
      'playedGames': played,
    };
  }

  @override
  Widget build(BuildContext context) {
    final assessments = context.watch<AppState>().testResults;
    final assessmentStat = _getOverallAssessment(assessments);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPremiumHeader(),
                  
                  if (_showDashboard && assessmentStat != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildDashboard(assessmentStat),
                    ),

                  const SizedBox(height: 24),
                  
                  _buildFeaturedSection(),
                  
                  const SizedBox(height: 36),
                  
                  _buildDiscoverySection("Membaca & Menulis", const Color(0xFF3B82F6), _literacyGames),
                  const SizedBox(height: 36),
                  
                  _buildDiscoverySection("Logika & Angka", const Color(0xFF10B981), _logicGames),
                  const SizedBox(height: 36),
                  
                  _buildDiscoverySection("Kreativitas", const Color(0xFFEC4899), _creativeGames),
                  
                  const SizedBox(height: 48),
                  
                  // Pro Tip Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), offset: const Offset(0, 10), blurRadius: 20)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: const Text('💡', style: TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kejutan Harian!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                                Text('Mainkan 3 game hari ini untuk mendapatkan stiker spesial!', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 10))],
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_rounded, '/home', false),
                  if (context.watch<AppState>().isParentMode)
                    _buildNavItem(Icons.chat_bubble_rounded, '/consultation', false),
                  _buildNavItem(Icons.videogame_asset_rounded, '/game', true),
                  _buildNavItem(Icons.bar_chart_rounded, '/progress', false),
                  _buildNavItem(Icons.person_rounded, '/profile', false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Petualangan Seru,', style: TextStyle(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
              Text('Pilih Gamemu! 🎮', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _showDashboard = !_showDashboard),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56, height: 56,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  ),
                ),
                Container(
                  width: 42, height: 42,
                  decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle),
                  child: const Center(child: Text('5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Baru & Seru! 🔥', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
              const Icon(Icons.star_outline_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredGames.length,
            itemBuilder: (context, index) {
              final game = _featuredGames[index];
              return Container(
                width: 310,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: game.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: game.gradient[1].withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 10))],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10, bottom: -10,
                      child: Opacity(
                        opacity: 0.15,
                        child: Text(game.image, style: const TextStyle(fontSize: 140)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                            child: Text(game.domains[0], style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(height: 12),
                          Text(game.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(game.description, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () => _handleGameClick(game.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: game.gradient[1],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: Text('Main Sekarang', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverySection(String title, Color accentColor, List<_AvailableGame> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
              Text('Lihat Semua', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accentColor)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildLingokidsCard(game);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLingokidsCard(_AvailableGame game) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: game.bgColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(child: Text(game.image, style: const TextStyle(fontSize: 52))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Column(
              children: [
                Text(game.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text(game.rating, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleGameClick(game.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF6FF),
                      foregroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Main', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactStat(Icons.videogame_asset_rounded, '${stats['totalSessions']}', 'Main', const Color(0xFF3B82F6)),
          _buildCompactStat(Icons.stars_rounded, '${stats['avgScore']}%', 'Skor', const Color(0xFFF59E0B)),
          _buildCompactStat(Icons.timer_rounded, '${stats['avgTime']}s', 'Waktu', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, String val, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
        Text(label, style: TextStyle(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String route, bool active) {
    return GestureDetector(
      onTap: () async {
        final appState = Provider.of<AppState>(context, listen: false);
        if (route == '/consultation' && !appState.isParentMode) {
          final bool hasPin = appState.parentalPin != null && appState.parentalPin!.isNotEmpty;
          final dynamic result = await Navigator.pushNamed(
            context, 
            '/parental-pin', 
            arguments: {
              'isSetup': !hasPin,
              'currentPin': appState.parentalPin,
            }
          );
          
          if (result == true || result is String) {
            if (result is String) {
              await appState.setParentalPin(result);
            }
            appState.setParentMode(true);
            if (mounted) {
              Navigator.pushReplacementNamed(context, route);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Akses Dibatalkan. Hanya untuk orang tua 🔒'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: active ? const Color(0xFF2563EB) : Colors.grey.shade400, size: 28),
      ),
    );
  }
}
