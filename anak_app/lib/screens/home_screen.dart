import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/custom_bottom_nav.dart';
import '../services/chat_notification_service.dart';
import '../services/audio_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late ValueNotifier<Offset> _fabPosition;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  MemoryImage? _cachedAvatar;
  String? _lastAvatarBase64;
  bool _showFab = true;

  // Phase 4: Weather & Easter Egg
  late AnimationController _weatherController;
  Timer? _easterEggTimer;
  bool _showEasterEgg = false;
  double _easterEggX = -100;
  double _easterEggY = 200;
  bool? _previewNightMode = false; // Default to Day Mode so morning sunshine and clouds are immediately visible

  @override
  void initState() {
    super.initState();
    _fabPosition = ValueNotifier(const Offset(250, 550));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = const AlwaysStoppedAnimation(1.0);

    // Weather Controller: Gerak halus & melayang berkesinambungan
    _weatherController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();

    // Easter Egg Spawner
    _startEasterEggTimer();

  }

  void _startEasterEggTimer() {
    _easterEggTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      if (!_showEasterEgg) {
        setState(() {
          _showEasterEgg = true;
          // random Y position
          _easterEggY = 100 + (DateTime.now().second * 10).toDouble() % 400;
          _easterEggX = -20; // peaks out
        });
        // Auto hide after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _showEasterEgg) {
            setState(() => _showEasterEgg = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _weatherController.dispose();
    _easterEggTimer?.cancel();
    _fabPosition.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  MemoryImage? _getAvatarImage(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    if (base64 == _lastAvatarBase64 && _cachedAvatar != null) {
      return _cachedAvatar;
    }
    try {
      _lastAvatarBase64 = base64;
      _cachedAvatar = MemoryImage(base64Decode(base64));
      return _cachedAvatar;
    } catch (_) {
      return null;
    }
  }

  Widget _buildParentModeToggle(BuildContext context, AppState appState) {
    return GestureDetector(
      onTap: () async {
        if (appState.isParentMode) {
          appState.setParentMode(false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kembali ke Mode Anak 🧒'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          final bool hasPin = appState.parentalPin != null && appState.parentalPin!.isNotEmpty;
          final dynamic result = await Navigator.pushNamed(
            context, 
            '/parental-pin', 
            arguments: {
              'isSetup': !hasPin,
              'currentPin': appState.parentalPin,
            }
          );
          
          if (result == true || (result is String && result.length == 4)) {
            if (result is String && result.length == 4) {
              await appState.setParentalPin(result);
            }
            appState.setParentMode(true);
            AudioService().stopBGM();
            await AudioService().playClick();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mode Orang Tua Aktif! 🛡️'),
                  backgroundColor: Color(0xFFF97316),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: appState.isParentMode ? const Color(0xFFF97316).withValues(alpha: 0.15) : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: appState.isParentMode ? const Color(0xFFF97316) : const Color(0xFFFED7AA),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF97316).withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              appState.isParentMode ? Icons.security_rounded : Icons.lock_rounded,
              color: const Color(0xFFEA580C),
              size: 14,
            ),
            const SizedBox(width: 4),
            const Text(
              'Orang Tua',
              style: TextStyle(
                color: Color(0xFFEA580C),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(String screen) {
    String route = '/$screen';
    if (screen == 'test-room') route = '/test-room';
    if (screen == 'cognitive-test') route = '/cognitive-test';
    if (screen == 'linguistic-test') route = '/linguistic-test';
    if (screen == 'personality-test') route = '/personality-test';
    Navigator.pushNamed(context, route);
  }

  Widget _buildMockupHeader(BuildContext context, AppState appState, String greetingPrefix, String childName, bool isNightMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: ZIKOLA Official 3D Inflatable Logo (Tap to Switch Day/Night Mode)
          GestureDetector(
            onTap: () {
              AudioService().playPop();
              Navigator.pushNamed(context, '/photo-booth');
            },
            onLongPress: () => Navigator.pushNamed(context, '/motor-tips'),
            child: Image.asset(
              'assets/images/zikola_3d_logo.png',
              height: 44,
              fit: BoxFit.contain,
            ),
          ),

          // Right Controls: [🔒 Orang Tua (PIN)] + [🔔 Bell] + [Avatar]
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. PIN-Protected Parent Mode Toggle
              _buildParentModeToggle(context, appState),
              const SizedBox(width: 8),

              // 2. Notification Bell
              GestureDetector(
                onTap: () {
                  AudioService().playClick();
                  Navigator.pushNamed(context, '/notifications');
                },
                onLongPress: () {
                  AudioService().playClick();
                  Navigator.pushNamed(context, '/onboarding');
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isNightMode ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isNightMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9), 
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isNightMode ? 0.3 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: isNightMode ? Colors.white : const Color(0xFF1E293B),
                        size: 20,
                      ),
                      if (appState.totalUnreadNotifications > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Profile Avatar
              GestureDetector(
                onTap: () {
                  AudioService().playClick();
                  Navigator.pushNamed(context, '/child-selector');
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: appState.childProfile.avatarBase64 != null
                        ? Image(image: _getAvatarImage(appState.childProfile.avatarBase64!)!, fit: BoxFit.cover)
                        : Image.asset('assets/images/characters/character_round_green.png', fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMockupBanner(BuildContext context, AppState appState) {
    return Container(
      width: double.infinity,
      height: 195,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFBEB), // warm pastel cream
            Color(0xFFEFF6FF), // soft pastel sky blue
          ],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Left content
            Positioned(
              top: 20,
              left: 20,
              bottom: 20,
              right: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kenali Potensi\nTerbaik Si Kecil',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bersama ZIKOLA, bantu anak mengembangkan kemampuan kognitif, bahasa, dan kepribadiannya.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      AudioService().playPop();
                      _navigateTo('test-room');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mulai Asesmen',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right Mascot
            Positioned(
              right: 4,
              bottom: 0,
              top: 8,
              width: 150,
              child: Image.asset(
                'assets/images/kula_hero_mascot.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingkasanPerkembanganSection(BuildContext context, AppState appState) {
    final results = appState.testResults;
    final cognitive = results.cognitive;
    final linguistic = results.linguistic;
    final personalityDone = results.personality.completed;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ringkasan Perkembangan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Pantau progres si kecil.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  AudioService().playClick();
                  Navigator.pushNamed(context, '/progress');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Domain Cards Row
          Row(
            children: [
              // 1. Kognitif
              Expanded(
                child: _buildDomainSummaryCard(
                  title: 'Kognitif',
                  scoreText: cognitive.completed ? '${cognitive.score}' : null,
                  isFinished: false,
                  iconAsset: 'assets/images/emoji/games/brain.png',
                  iconBgColor: const Color(0xFFFEE2E2),
                  progressColor: const Color(0xFFF87171),
                  progressValue: cognitive.completed ? (cognitive.percentage / 100).clamp(0.0, 1.0) : 0.0,
                  onTap: () => Navigator.pushNamed(context, '/cognitive-test'),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Linguistik
              Expanded(
                child: _buildDomainSummaryCard(
                  title: 'Linguistik',
                  scoreText: linguistic.completed ? '${linguistic.score}' : null,
                  isFinished: false,
                  iconAsset: 'assets/images/emoji/games/books.png',
                  iconBgColor: const Color(0xFFE0F2FE),
                  progressColor: const Color(0xFF3B82F6),
                  progressValue: linguistic.completed ? (linguistic.percentage / 100).clamp(0.0, 1.0) : 0.0,
                  onTap: () => Navigator.pushNamed(context, '/linguistic-test'),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Kepribadian
              Expanded(
                child: _buildDomainSummaryCard(
                  title: 'Kepribadian',
                  scoreText: null,
                  isFinished: personalityDone,
                  iconAsset: 'assets/images/emoji/games/palette.png',
                  iconBgColor: const Color(0xFFF3E8FF),
                  progressColor: const Color(0xFFA855F7),
                  progressValue: personalityDone ? 1.0 : 0.0,
                  onTap: () => Navigator.pushNamed(context, '/personality-test'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainSummaryCard({
    required String title,
    // null = test not taken yet.
    required String? scoreText,
    required bool isFinished,
    required String iconAsset,
    required Color iconBgColor,
    required Color progressColor,
    required double progressValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AudioService().playPop();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(iconAsset, fit: BoxFit.contain),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2),
            if (!isFinished && scoreText == null)
              const Text(
                'Mulai tes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                ),
              )
            else if (isFinished)
              Text(
                'Selesai',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: progressColor,
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    scoreText!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'Skor',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 5,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCepatSection(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Tes & Latihan
          Expanded(
            child: _buildQuickNavItem(
              icon: Icons.assignment_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBgColor: const Color(0xFFEFF6FF),
              title: 'Tes &\nLatihan',
              onTap: () => _navigateTo('test-room'),
            ),
          ),
          _buildVerticalSeparator(),

          // 2. Game Edukasi
          Expanded(
            child: _buildQuickNavItem(
              icon: Icons.sports_esports_rounded,
              iconColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFDCFCE7),
              title: 'Game\nEdukasi',
              onTap: () => Navigator.pushNamed(context, '/game'),
            ),
          ),
          _buildVerticalSeparator(),

          // 3. Koleksi Stiker
          Expanded(
            child: _buildQuickNavItem(
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFF8B5CF6),
              iconBgColor: const Color(0xFFF3E8FF),
              title: 'Koleksi\nStiker',
              onTap: () => Navigator.pushNamed(context, '/stickers'),
            ),
          ),
          _buildVerticalSeparator(),

          // 4. Komunitas Diskusi
          Expanded(
            child: _buildQuickNavItem(
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              title: 'Komunitas\nDiskusi',
              onTap: () => Navigator.pushNamed(context, '/community'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalSeparator() {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildQuickNavItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        AudioService().playPop();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  height: 1.2,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 13, color: Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRekomendasiSection(BuildContext context, bool isNightMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFBBF24),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi Untukmu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isNightMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                AudioService().playClick();
                Navigator.pushNamed(context, '/game');
              },
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isNightMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded, 
                    size: 16, 
                    color: isNightMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Featured Card
        GestureDetector(
          onTap: () {
            AudioService().playPop();
            Navigator.pushNamed(context, '/desert-road-logic');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFF6FF), // soft blue
                  Color(0xFFF8FAFC), // white
                ],
              ),
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Illustration
                Image.asset(
                  'assets/images/recom_math_icon.png',
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Latihan Logika Matematika',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Yuk, asah kemampuan berpikir logis melalui permainan yang seru!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Arrow Button
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayChallengeMiniCard(BuildContext context, AppState appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎯 Misi Hari Ini',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
              ),
              GestureDetector(
                onTap: () {
                  AudioService().playClick();
                  Navigator.pushNamed(context, '/daily-challenge');
                },
                child: const Text(
                  'Lihat Misi',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...appState.todayChallenges.take(2).map((challenge) {
            final double progressVal = challenge.target > 0 
                ? (challenge.progress / challenge.target).clamp(0.0, 1.0)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(challenge.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progressVal,
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: challenge.isCompleted ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${challenge.progress}/${challenge.target}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: challenge.isCompleted ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.isScreenTimeLocked) {
      return _buildScreenTimeRestLockView(context, appState);
    }

    if (appState.isParentMode) {
      return _buildParentDashboard(context, appState);
    }

    final childName = appState.childProfile.name;
    final hour = DateTime.now().hour;
    final isNightMode = _previewNightMode ?? (hour >= 18 || hour < 6);
    final greetingPrefix = isNightMode ? 'Selamat Malam,' : (hour < 12 ? 'Selamat Pagi,' : 'Selamat Siang,');



    return Scaffold(
      backgroundColor: isNightMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            _buildWeatherLayer(isNightMode),
            Column(
              children: [
                // Offline mode indicator
                if (appState.isOffline)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mode Offline Aktif. Progress Anda akan disinkronkan otomatis saat online.',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Mockup Header: Zikola Logo, Greeting, Notification with badge
                _buildMockupHeader(context, appState, greetingPrefix, childName, isNightMode),

            // Scrollable Body matching reference mockup
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Banner: "Kenali Potensi Terbaik Si Kecil" with Mascot KULA
                    _buildHeroMockupBanner(context, appState),
                    const SizedBox(height: 18),

                    // 2. Ringkasan Perkembangan (Kognitif, Linguistik, Kepribadian)
                    _buildRingkasanPerkembanganSection(context, appState),
                    const SizedBox(height: 20),

                    // 3. Menu Cepat: Tes & Latihan, Game Edukasi, Konsultasi Psikolog, Komunitas Orang Tua
                    _buildMenuCepatSection(context),
                    const SizedBox(height: 20),

                    // 4. Rekomendasi Untukmu (Latihan Logika Matematika)
                    _buildRekomendasiSection(context, isNightMode),
                    const SizedBox(height: 16),

                    // 5. Active Prescription & Therapy Banner (if active)
                    _buildActivePrescriptionReminder(context),

                    // 6. Misi Hari Ini (Daily Challenge mini card if active)
                    if (appState.todayChallenges.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildTodayChallengeMiniCard(context, appState),
                    ],

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            )
              ],
            ), // outer Column

        if (_showEasterEgg && !appState.isParentMode)
          _buildEasterEgg(),


        // Draggable FAB for Consultation
            if (_showFab && appState.isParentMode)
              ValueListenableBuilder<Offset>(
                valueListenable: _fabPosition,
                builder: (context, position, child) {
                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: child!,
                  );
                },
                child: ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: ChatNotificationService().activeChatInfo,
                  builder: (context, activeChat, child) {
                    return GestureDetector(
                      onPanUpdate: (details) {
                        final size = MediaQuery.of(context).size;
                        // Clamp to prevent moving outside screen
                        double newX = (_fabPosition.value.dx + details.delta.dx).clamp(16.0, size.width - 200.0); // Wider for active text
                        double newY = (_fabPosition.value.dy + details.delta.dy).clamp(size.height * 0.1, size.height - 100.0);
                        _fabPosition.value = Offset(newX, newY);
                      },
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (!appState.isParentMode) {
                                  final bool hasPin = appState.parentalPin != null && appState.parentalPin!.isNotEmpty;
                                  final dynamic result = await Navigator.pushNamed(
                                    context, 
                                    '/parental-pin', 
                                    arguments: {
                                      'isSetup': !hasPin,
                                      'currentPin': appState.parentalPin,
                                    }
                                  );
                                  
                                  if (result == true || (result is String && result.length == 4)) {
                                    if (result is String && result.length == 4) {
                                      await appState.setParentalPin(result);
                                    }
                                    appState.setParentMode(true);
                                    if (context.mounted) {
                                      if (activeChat != null) {
                                        Navigator.pushNamed(context, '/chat', arguments: activeChat);
                                      } else {
                                        Navigator.pushNamed(context, '/consultation');
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Akses Dibatalkan. Hanya untuk orang tua 🔒'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (activeChat != null) {
                                    Navigator.pushNamed(context, '/chat', arguments: activeChat);
                                  } else {
                                    Navigator.pushNamed(context, '/consultation');
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: activeChat != null ? const Color(0xFF1E40AF) : Colors.white, // Blue 800 if active
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: activeChat != null ? Colors.blueAccent : const Color(0xFF16A34A).withValues(alpha: 0.1), 
                                    width: 1.5
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: activeChat != null ? 0.2 : 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: activeChat != null ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text('👨‍⚕️', style: TextStyle(fontSize: 16)),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeChat != null ? 'Kembali Sesi' : 'Tanya Ahli',
                                          style: TextStyle(
                                            color: activeChat != null ? Colors.white : const Color(0xFF16A34A), 
                                            fontWeight: FontWeight.w900, 
                                            fontSize: 11
                                          ),
                                        ),
                                        Text(
                                          activeChat != null ? 'Sesi Aktif' : 'Konsultasi Sekarang',
                                          style: TextStyle(
                                            color: activeChat != null ? Colors.white70 : const Color(0xFF16A34A).withValues(alpha: 0.7), 
                                            fontSize: 8, 
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Dismiss Button
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => setState(() => _showFab = false),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildCloudWidget({
    required double width,
    required double height,
    double opacity = 0.95,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Soft sky drop shadow underneath
          Positioned(
            left: 2,
            right: 2,
            bottom: -3,
            child: Container(
              height: height * 0.52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height * 0.35),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.18 * opacity),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          // 2. Cloud Base Pill (Smooth base)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: height * 0.56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(height * 0.35),
                border: Border.all(
                  color: const Color(0xFFBAE6FD).withValues(alpha: 0.70 * opacity),
                  width: 1.0,
                ),
              ),
            ),
          ),
          // 3. Fluffy Circle Left
          Positioned(
            left: width * 0.08,
            bottom: height * 0.12,
            child: Container(
              width: height * 0.68,
              height: height * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity),
                border: Border.all(
                  color: const Color(0xFFBAE6FD).withValues(alpha: 0.65 * opacity),
                  width: 0.8,
                ),
              ),
            ),
          ),
          // 4. Fluffy Circle Center (Highest Peak)
          Positioned(
            left: width * 0.28,
            bottom: height * 0.24,
            child: Container(
              width: height * 0.90,
              height: height * 0.90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity),
                border: Border.all(
                  color: const Color(0xFFBAE6FD).withValues(alpha: 0.65 * opacity),
                  width: 0.8,
                ),
              ),
            ),
          ),
          // 5. Fluffy Circle Right
          Positioned(
            left: width * 0.58,
            bottom: height * 0.10,
            child: Container(
              width: height * 0.64,
              height: height * 0.64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity),
                border: Border.all(
                  color: const Color(0xFFBAE6FD).withValues(alpha: 0.65 * opacity),
                  width: 0.8,
                ),
              ),
            ),
          ),
          // 6. Center Fill Mask (seamlessly blends internal lines)
          Positioned(
            left: width * 0.12,
            right: width * 0.12,
            bottom: height * 0.08,
            top: height * 0.26,
            child: Container(
              color: Colors.white.withValues(alpha: opacity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSun(double t) {
    // 360 rotation over cycle
    final double rayAngle = t * 2 * math.pi;
    // Breathing pulse for the halo and sun (0.97 to 1.04)
    final double pulse = 1.0 + 0.035 * math.sin(t * 4 * math.pi);
    // Subtle ray brightness pulsation
    final double raysOpacity = (0.70 + 0.25 * math.sin(t * 2 * math.pi)).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _previewNightMode = true;
        });
      },
      child: Transform.scale(
        scale: pulse,
        child: SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Ambient Sun Rays Corona Glow
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFDE047).withValues(alpha: 0.45),
                      const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // 2. Rotating Sun Rays (Sinarnya yang memancar keluar)
              Transform.rotate(
                angle: rayAngle,
                child: Opacity(
                  opacity: raysOpacity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: List.generate(12, (index) {
                      final double angle = index * (math.pi / 6);
                      return Transform.rotate(
                        angle: angle,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 5,
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xFFFDE047),
                                  Color(0x00F59E0B),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // 3. Sun Core Disk (Matahari Pagi Cerah 3D)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.25, -0.25),
                    radius: 0.85,
                    colors: [
                      Color(0xFFFFFBEB), // Highlight lembut
                      Color(0xFFFEF08A), // Kuning cerah
                      Color(0xFFFBBF24), // Emas
                      Color(0xFFF59E0B), // Oranye hangat
                    ],
                    stops: [0.0, 0.35, 0.70, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFEF08A).withValues(alpha: 0.75),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 2.0,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '☀️',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherLayer(bool isNightMode) {
    if (isNightMode) {
      // Night Mode: Starry Sky with Glowing Crescent Moon & Ambient Nebula (Animated Twinkle)
      return AnimatedBuilder(
        animation: _weatherController,
        builder: (context, child) {
          final t = _weatherController.value;
          return Stack(
            children: [
              // 1. Ambient Cosmic Glow
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withValues(alpha: 0.12),
                        const Color(0xFF1E3A8A).withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 260,
                left: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF818CF8).withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Glowing Crescent Moon (Bulan Sabit Bersinar dengan Tap Switch)
              Positioned(
                top: 15,
                right: 80,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _previewNightMode = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFDE047).withValues(alpha: 0.35 + 0.15 * math.sin(t * 2 * math.pi)),
                          blurRadius: 26,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text('🌙', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ),

              // 3. Sparkling Stars (Bintang-Bintang Berkelap-Kelip)
              Positioned(
                top: 20,
                left: 115,
                child: Opacity(
                  opacity: (0.5 + 0.5 * math.sin(t * 4 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('✨', style: TextStyle(fontSize: 15)),
                ),
              ),
              Positioned(
                top: 55,
                left: 180,
                child: Opacity(
                  opacity: (0.6 + 0.4 * math.cos(t * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFEF08A), size: 14),
                ),
              ),
              Positioned(
                top: 42,
                right: 25,
                child: Opacity(
                  opacity: (0.5 + 0.5 * math.sin((t + 0.2) * 4 * math.pi)).clamp(0.0, 1.0),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFBAE6FD), size: 11),
                ),
              ),
              Positioned(
                top: 105,
                left: 28,
                child: Opacity(
                  opacity: (0.6 + 0.4 * math.sin((t + 0.5) * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFDE047), size: 14),
                ),
              ),
              Positioned(
                top: 135,
                right: 45,
                child: Opacity(
                  opacity: (0.5 + 0.5 * math.cos((t + 0.3) * 4 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('⭐', style: TextStyle(fontSize: 13)),
                ),
              ),
              Positioned(
                top: 200,
                left: 16,
                child: Opacity(
                  opacity: (0.6 + 0.4 * math.sin((t + 0.7) * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Icon(Icons.star_rounded, color: Colors.white70, size: 12),
                ),
              ),
              Positioned(
                top: 270,
                right: 20,
                child: Opacity(
                  opacity: (0.5 + 0.5 * math.sin((t + 0.4) * 4 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('✨', style: TextStyle(fontSize: 15)),
                ),
              ),
              Positioned(
                top: 350,
                left: 24,
                child: Opacity(
                  opacity: (0.6 + 0.4 * math.cos((t + 0.6) * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFEF08A), size: 15),
                ),
              ),
              Positioned(
                top: 430,
                right: 18,
                child: Opacity(
                  opacity: (0.5 + 0.5 * math.sin((t + 0.8) * 4 * math.pi)).clamp(0.0, 1.0),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFBAE6FD), size: 12),
                ),
              ),
              Positioned(
                top: 510,
                left: 30,
                child: Opacity(
                  opacity: (0.5 + 0.5 * math.cos((t + 0.1) * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('⭐', style: TextStyle(fontSize: 13)),
                ),
              ),
              Positioned(
                top: 600,
                right: 32,
                child: Opacity(
                  opacity: (0.6 + 0.4 * math.sin((t + 0.9) * 4 * math.pi)).clamp(0.0, 1.0),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFDE047), size: 14),
                ),
              ),
              Positioned(
                top: 680,
                left: 18,
                child: Opacity(
                  opacity: (0.5 + 0.5 * math.sin((t + 0.3) * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('✨', style: TextStyle(fontSize: 14)),
                ),
              ),
              Positioned(
                top: 750,
                right: 60,
                child: Opacity(
                  opacity: (0.6 + 0.4 * math.cos((t + 0.5) * 4 * math.pi)).clamp(0.0, 1.0),
                  child: const Icon(Icons.star_rounded, color: Colors.white70, size: 12),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Day Mode: Warm Radiant Sun with Rotating Rays, Gentle Floating Clouds & Morning Sparkles
      return AnimatedBuilder(
        animation: _weatherController,
        builder: (context, child) {
          final t = _weatherController.value;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 0. Soft Pastel Morning Sky Gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 380,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFBAE6FD).withValues(alpha: 0.35),
                        const Color(0xFFE0F2FE).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 1. Ambient Morning Sun Corona Glow
              Positioned(
                top: -45,
                left: 70,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFEF08A).withValues(alpha: 0.38),
                        const Color(0xFFFED7AA).withValues(alpha: 0.20),
                        const Color(0xFFBAE6FD).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Fresh Sky Blue Ambient Tint di Kiri Atas
              Positioned(
                top: -40,
                left: -50,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withValues(alpha: 0.14),
                        const Color(0xFFE0F2FE).withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Matahari & Sinarnya yang Memancar dan Berputar Lembut (Di Celah Header Atas)
              Positioned(
                top: 0,
                left: 110,
                child: _buildAnimatedSun(t),
              ),

              // 4. Awan-Awan Lucu Bergerak Tipis (Gentle Floating Clouds)
              // Cloud 1: Kiri Atas (Awan Utama yang Mengapung Halus di Bawah Logo)
              Positioned(
                top: 52 + math.cos(t * 2 * math.pi) * 3.5,
                left: 10 + math.sin(t * 2 * math.pi) * 16.0,
                child: _buildCloudWidget(width: 90, height: 42, opacity: 0.95),
              ),

              // Cloud 2: Kanan Atas (Di Bawah Avatar/Bel)
              Positioned(
                top: 56 + math.sin((t + 0.3) * 2 * math.pi) * 3.0,
                right: 12 + math.sin((t + 0.3) * 2 * math.pi) * -14.0,
                child: _buildCloudWidget(width: 80, height: 38, opacity: 0.90),
              ),

              // Cloud 3: Kiri Tengah (Melayang Lembut di Samping Ringkasan Perkembangan)
              Positioned(
                top: 255 + math.cos((t + 0.6) * 2 * math.pi) * 4.0,
                left: -14 + math.sin((t + 0.6) * 2 * math.pi) * 18.0,
                child: _buildCloudWidget(width: 96, height: 44, opacity: 0.88),
              ),

              // Cloud 4: Kanan Tengah (Di Samping Menu Cepat)
              Positioned(
                top: 470 + math.sin((t + 0.8) * 2 * math.pi) * 3.0,
                right: -12 + math.sin((t + 0.8) * 2 * math.pi) * -16.0,
                child: _buildCloudWidget(width: 86, height: 40, opacity: 0.85),
              ),

              // Cloud 5: Kiri Bawah (Di Samping Rekomendasi)
              Positioned(
                top: 670 + math.cos((t + 0.45) * 2 * math.pi) * 3.5,
                left: 10 + math.sin((t + 0.45) * 2 * math.pi) * 14.0,
                child: _buildCloudWidget(width: 80, height: 36, opacity: 0.82),
              ),

              // 5. Kilauan Cahaya Pagi / Sparkles yang Berkelap-Kelip Tipis
              Positioned(
                top: 25,
                left: 110,
                child: Opacity(
                  opacity: (0.45 + 0.45 * math.sin(t * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('✨', style: TextStyle(fontSize: 16)),
                ),
              ),
              Positioned(
                top: 145,
                right: 32,
                child: Opacity(
                  opacity: (0.40 + 0.45 * math.cos(t * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('⭐', style: TextStyle(fontSize: 13, color: Color(0xFFFBBF24))),
                ),
              ),
              Positioned(
                top: 380,
                left: 20,
                child: Opacity(
                  opacity: (0.35 + 0.40 * math.sin((t + 0.5) * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('✨', style: TextStyle(fontSize: 14)),
                ),
              ),
              Positioned(
                top: 590,
                right: 25,
                child: Opacity(
                  opacity: (0.35 + 0.40 * math.cos((t + 0.5) * 3 * math.pi)).clamp(0.0, 1.0),
                  child: const Text('⭐', style: TextStyle(fontSize: 13, color: Color(0xFFFBBF24))),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildEasterEgg() {
    return Positioned(
      left: _easterEggX,
      top: _easterEggY,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hore! Kamu menemukan Zikola! +5 XP 🌟')),
          );
          setState(() {
            _showEasterEgg = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(seconds: 1),
          child: Image.asset(
            'assets/images/stickers/hehe.png',
            width: 80,
            height: 80,
          ),
        ),
      ),
    );
  }

  /// Average score of the logic games the child has actually played (0–100).
  double _logicScore(AppState appState) {
    final g = appState.gameAssessments;
    final played = [g.patternRecognition, g.numberSequence, g.puzzleGame]
        .where((a) => a.totalPlayed > 0)
        .toList();
    if (played.isEmpty) return 0;
    final avg = played.map((a) => a.averageScore).reduce((a, b) => a + b) / played.length;
    return avg.toDouble().clamp(0.0, 100.0);
  }

  Widget _buildParentDashboard(BuildContext context, AppState appState) {
    final childName = appState.childProfile.name.isNotEmpty ? appState.childProfile.name : 'Si Kecil';
    final childAge = appState.childProfile.age;
    final childGender = appState.childProfile.gender;
    final results = appState.testResults;

    // Calculate overall completion / score index
    int completedCount = 0;
    double totalScore = 0;
    if (results.cognitive.completed) { completedCount++; totalScore += results.cognitive.percentage; }
    if (results.linguistic.completed) { completedCount++; totalScore += results.linguistic.percentage; }
    if (results.motor.completed) { completedCount++; totalScore += results.motor.percentage; }
    if (results.personality.completed) { completedCount++; totalScore += 85; }
    final double overallIndex = completedCount > 0 ? (totalScore / completedCount) : 82.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Sleek Modern Header with Greeting and Child Mode Toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Halo, Ayah & Bunda',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                fontFamily: 'Nunito',
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('👋', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Dasbor Pantau Tumbuh Kembang Zikola',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    // Switch back to Child Mode Button
                    GestureDetector(
                      onTap: () {
                        appState.setParentMode(false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Beralih kembali ke Mode Anak 🧒'),
                            backgroundColor: Color(0xFF2563EB),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👶', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 6),
                            Text(
                              'Mode Anak',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                fontFamily: 'Nunito',
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

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. CHILD GROWTH SPOTLIGHT CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/profile'),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                                  ),
                                  child: Center(
                                    child: (appState.childProfile.avatarBase64 != null &&
                                            appState.childProfile.avatarBase64!.isNotEmpty &&
                                            _getAvatarImage(appState.childProfile.avatarBase64!) != null)
                                        ? ClipOval(
                                            child: Image(
                                              image: _getAvatarImage(appState.childProfile.avatarBase64!)!,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : appState.childProfile.avatar.startsWith('assets/')
                                            ? ClipOval(
                                                child: Image.asset(
                                                  appState.childProfile.avatar,
                                                  width: 44,
                                                  height: 44,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Text(
                                                appState.childProfile.avatar.isNotEmpty
                                                    ? appState.childProfile.avatar
                                                    : (childGender == 'female' ? '👧' : '👦'),
                                                style: const TextStyle(fontSize: 26),
                                              ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      childName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Usia $childAge Tahun • ${childGender == 'female' ? 'Perempuan' : 'Laki-laki'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Text('⭐', style: TextStyle(fontSize: 10)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${overallIndex.round()}/100',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: RadarChart(
                              RadarChartData(
                                radarShape: RadarShape.polygon,
                                tickCount: 3,
                                ticksTextStyle: const TextStyle(color: Colors.transparent),
                                gridBorderData: const BorderSide(color: Colors.white38, width: 1.5),
                                tickBorderData: const BorderSide(color: Colors.white24, width: 1),
                                titleTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                ),
                                getTitle: (index, angle) {
                                  switch (index) {
                                    case 0: return const RadarChartTitle(text: 'Kognitif');
                                    case 1: return const RadarChartTitle(text: 'Linguistik');
                                    case 2: return const RadarChartTitle(text: 'Motorik');
                                    case 3: return const RadarChartTitle(text: 'Emosi');
                                    case 4: return const RadarChartTitle(text: 'Logika');
                                    default: return const RadarChartTitle(text: '');
                                  }
                                },
                                dataSets: [
                                  RadarDataSet(
                                    fillColor: Colors.white.withValues(alpha: 0.35),
                                    borderColor: Colors.white,
                                    borderWidth: 2.5,
                                    entryRadius: 4,
                                    dataEntries: [
                                      // Real data only; untested domains stay at 0.
                                      RadarEntry(value: results.cognitive.completed ? results.cognitive.percentage : 0),
                                      RadarEntry(value: results.linguistic.completed ? results.linguistic.percentage : 0),
                                      RadarEntry(value: results.motor.completed ? results.motor.percentage : 0),
                                      RadarEntry(value: (results.personality.emotionalScore?.toDouble() ?? 0).clamp(0.0, 100.0)),
                                      RadarEntry(value: _logicScore(appState)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/progress'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Buka Rapor & Analisis AI Lengkap',
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB), size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 3. 4-GRID PARENTING ACTION HUB
                    const Text(
                      'Pusat Kendali Orang Tua',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        _buildActionHubCard(
                          icon: '🩺',
                          title: 'Konsultasi Ahli',
                          desc: 'Chat & call dokter anak',
                          bgGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          accentColor: const Color(0xFF2563EB),
                          onTap: () => Navigator.pushNamed(context, '/consultation'),
                        ),
                        _buildActionHubCard(
                          icon: '📊',
                          title: 'Rapor Tumbuh',
                          desc: 'Grafik radar & skor game',
                          bgGradient: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                          accentColor: const Color(0xFF16A34A),
                          onTap: () => Navigator.pushNamed(context, '/progress'),
                        ),
                        _buildActionHubCard(
                          icon: '📚',
                          title: 'Panduan Ortu',
                          desc: 'Solusi tantrum & feeding',
                          bgGradient: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                          accentColor: const Color(0xFF9333EA),
                          onTap: () => Navigator.pushNamed(context, '/parent-guide'),
                        ),
                        _buildActionHubCard(
                          icon: '⏱️',
                          title: 'Waktu Layar',
                          desc: 'Batas main & PIN proteksi',
                          bgGradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                          accentColor: const Color(0xFFEA580C),
                          onTap: () => Navigator.pushNamed(context, '/screen-time-settings'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // 4. SMART AI PARENTING RECOMMENDATION
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('💡', style: TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Rekomendasi Stimulasi AI',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Minggu Ini',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2563EB),
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$childName menunjukkan daya ingat visual yang kuat. Berikan tantangan puzzle bertahap 15 menit per hari untuk melatih fokus berkelanjutan.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                    height: 1.4,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 5. PARENTING TOOLKIT CAROUSEL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Panduan Praktis Parenting',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/parent-guide'),
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 130,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildToolkitCard(
                            icon: '🧘',
                            title: 'Tenang Hadapi Tantrum',
                            subtitle: '5 langkah validasi emosi tanpa membentak',
                            color: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.pushNamed(context, '/parent-guide'),
                          ),
                          const SizedBox(width: 12),
                          _buildToolkitCard(
                            icon: '🥗',
                            title: 'Aturan Makan Anti-GTM',
                            subtitle: 'Protokol IDAI suasana makan bahagia',
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.pushNamed(context, '/parent-guide'),
                          ),
                          const SizedBox(width: 12),
                          _buildToolkitCard(
                            icon: '😴',
                            title: 'Ritual Tidur Berkualitas',
                            subtitle: 'Merangsang hormon pertumbuhan anak',
                            color: const Color(0xFFF59E0B),
                            onTap: () => Navigator.pushNamed(context, '/parent-guide'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 6. DOCTOR CONSULTATION SPOTLIGHT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dokter & Psikolog Siaga',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/doctor-list'),
                          child: const Text(
                            'Daftar Dokter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDoctorCard(
                      name: 'Dra. Rina Melati, M.Psi.',
                      specialty: 'Psikolog Klinis Tumbuh Kembang Anak',
                      status: 'Online • Siap Konsultasi',
                      experience: 'Pengalaman 9+ Tahun',
                    ),

                    const SizedBox(height: 28),

                    // 7. COMMUNITY DISCUSSIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Diskusi Komunitas Bunda',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/community'),
                          child: const Text(
                            'Buka Forum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCommunitySection(),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildActionHubCard({
    required String icon,
    required String title,
    required String desc,
    required List<Color> bgGradient,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolkitCard({
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: color),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Nunito',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    height: 1.25,
                    fontFamily: 'Nunito',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required String status,
    required String experience,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '👨‍⚕️',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialty,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      experience,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, '/doctor-list'),
              icon: const Icon(
                Icons.chat_bubble_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Column(
      children: [
        _buildCommunityCard(
          title: 'Strategi melatih konsentrasi belajar anak usia 6 tahun di rumah',
          author: 'Ibu Sarah',
          time: '2 jam lalu',
          replies: 14,
        ),
        const SizedBox(height: 12),
        _buildCommunityCard(
          title: 'Rekomendasi mainan edukatif terstruktur melatih motorik halus',
          author: 'Ayah Budi',
          time: '1 hari lalu',
          replies: 8,
        ),
      ],
    );
  }

  Widget _buildCommunityCard({
    required String title,
    required String author,
    required String time,
    required int replies,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Oleh $author • $time',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.forum_rounded,
                    size: 14,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$replies balasan',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTimeRestLockView(BuildContext context, AppState appState) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF31104B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 180,
                height: 180,
                alignment: Alignment.center,
                child: Image.asset('assets/images/stickers/zzz.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 32),
              const Text(
                'Waktunya Istirahat! 😴',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Mata dan tubuhmu sudah bekerja keras hari ini. Yuk regangkan badan, minum air, dan bersiap istirahat!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final bool hasPin = appState.parentalPin != null && appState.parentalPin!.isNotEmpty;
                    final dynamic result = await Navigator.pushNamed(
                      context, 
                      '/parental-pin', 
                      arguments: {
                        'isSetup': !hasPin,
                        'currentPin': appState.parentalPin,
                      }
                    );
                    if (result == true || (result is String && result.length == 4)) {
                      if (result is String && result.length == 4) {
                        await appState.setParentalPin(result);
                      }
                      appState.unlockScreenTime();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Waktu layar berhasil dibuka! 🔓')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.lock_open_rounded, color: Color(0xFF0F172A), size: 18),
                  label: const Text(
                    'Buka Kunci Orang Tua (PIN)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivePrescriptionReminder(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('prescriptions')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final itemName = data['itemName']?.toString() ?? 'Rekomendasi Terapi';
        final dosage = data['dosage']?.toString() ?? '-';
        final type = data['type']?.toString() ?? 'suplemen';
        final doctorName = data['doctorName']?.toString() ?? 'Dokter Spesialis Anak';

        final isTerapi = type == 'terapi';
        final isMedis = type == 'medis';

        final typeTitle = isTerapi ? 'PROGRAM TERAPI AKTIF' : isMedis ? 'RESEP OBAT MEDIS' : 'SUPLEMEN TUMBUH KEMBANG';
        final gradientColors = isTerapi
            ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
            : isMedis
                ? [const Color(0xFFE11D48), const Color(0xFFBE123C)]
                : [const Color(0xFF0284C7), const Color(0xFF0369A1)];

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: GestureDetector(
            onTap: () {
              AudioService().playClick();
              Navigator.pushNamed(context, '/progress', arguments: {'tab': 'emr'});
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 12,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💊', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            Text(
                              typeTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Buka EMR',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dosis: $dosage • $doctorName',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}



