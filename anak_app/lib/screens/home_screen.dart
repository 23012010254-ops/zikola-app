import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../models/test_result.dart';
import '../services/chat_notification_service.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late ValueNotifier<Offset> _fabPosition;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  MemoryImage? _cachedAvatar;
  String? _lastAvatarBase64;
  bool _showFab = true;

  final List<Map<String, dynamic>> _testCategories = [
    {
      'id': 'cognitive-test',
      'title': 'Kognitif',
      'icon': '🧠',
      'bgColor': const Color(0xFFDBEAFE), // blue100
      'iconColor': AppTheme.blue600,
    },
    {
      'id': 'linguistic-test',
      'title': 'Linguistik',
      'icon': '📝',
      'bgColor': const Color(0xFFFFEDD5), // orange100
      'iconColor': AppTheme.orange600,
    },
    {
      'id': 'personality-test',
      'title': 'Kepribadian',
      'icon': '🎭',
      'bgColor': const Color(0xFFF3E8FF), // purple100
      'iconColor': const Color(0xFF9333EA), // purple600
    },
    {
      'id': 'motor-tips',
      'title': 'Motorik',
      'icon': '🎯',
      'bgColor': const Color(0xFFDCFCE7), // green100 (inferred)
      'iconColor': AppTheme.green500,
    },
    {
      'id': 'game',
      'title': 'Game',
      'icon': '🎮',
      'bgColor': const Color(0xFFFCE7F3), // pink100
      'iconColor': const Color(0xFFDB2777), // pink600
    }
  ];

  List<Map<String, dynamic>> _getRecentTests(TestResults results) {
    final tests = [
      {
        'id': 'cognitive',
        'title': 'Kognitif',
        'icon': '🧠',
        'bgColor': const Color(0xFFEFF6FF), // blue50
        'progressColor': AppTheme.blue500,
        'data': results.cognitive,
      },
      {
        'id': 'linguistic',
        'title': 'Linguistik',
        'icon': '📝',
        'bgColor': const Color(0xFFFFF7ED), // orange50
        'progressColor': AppTheme.orange500,
        'data': results.linguistic,
      },
      {
        'id': 'personality',
        'title': 'Kepribadian',
        'icon': '🎭',
        'bgColor': const Color(0xFFFAF5FF), // purple50
        'progressColor': const Color(0xFF9333EA), // purple500 -> purple600
        'data': results.personality,
      },
      {
        'id': 'motor',
        'title': 'Motorik',
        'icon': '🎯',
        'bgColor': const Color(0xFFF0FDF4), // green50
        'progressColor': AppTheme.green500,
        'data': results.motor,
      }
    ];

    List<Map<String, dynamic>> recent = [];
    for (var test in tests) {
      final data = test['data'] as dynamic;
      if (data != null && data.completed == true) {
        if (test['id'] == 'personality') {
          recent.add({
            ...test,
            'scoreText': 'Selesai',
            'totalText': 'Selesai',
            'progress': 1.0,
          });
        } else {
          recent.add({
            ...test,
            'scoreText': '${data.score}',
            'totalText': '${data.total}',
            'progress': data.total > 0 ? (data.score / data.total).clamp(0.0, 1.0) : 0.0,
          });
        }
      }
    }
    return recent;
  }

  @override
  void initState() {
    super.initState();
    _fabPosition = ValueNotifier(const Offset(250, 550));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabPosition.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  MemoryImage? _getAvatarImage(String? base64) {
    if (base64 == null) return null;
    if (base64 == _lastAvatarBase64 && _cachedAvatar != null) {
      return _cachedAvatar;
    }
    _lastAvatarBase64 = base64;
    _cachedAvatar = MemoryImage(base64Decode(base64));
    return _cachedAvatar;
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
          
          if (result == true || result is String) {
            if (result is String) {
              await appState.setParentalPin(result);
            }
            appState.setParentMode(true);
            await AudioService().playClick();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mode Orang Tua Aktif! 🛡️'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: appState.isParentMode ? const Color(0xFFF97316).withOpacity(0.15) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: appState.isParentMode ? const Color(0xFFF97316) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              appState.isParentMode ? Icons.security_rounded : Icons.lock_outline_rounded,
              color: appState.isParentMode ? const Color(0xFFEA580C) : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              'Orang Tua',
              style: TextStyle(
                color: appState.isParentMode ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
    final recentTests = _getRecentTests(appState.testResults);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
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

                // Premium Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang,',
                              style: TextStyle(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$childName! 👋',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), height: 1.2),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Level, XP, Streak indicators
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 10)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${appState.currentStreak} Hari',
                                          style: TextStyle(color: Colors.amber.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '🌟 Lvl ${appState.currentLevel}',
                                      style: TextStyle(color: Colors.blue.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${appState.totalXP} XP',
                                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildParentModeToggle(context, appState),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/notifications'),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 22),
                                ),
                                if (appState.totalUnreadNotifications > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: Text(
                                        appState.totalUnreadNotifications > 9 ? '9+' : appState.totalUnreadNotifications.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/child-selector'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                image: appState.childProfile.avatarBase64 != null
                                  ? DecorationImage(image: _getAvatarImage(appState.childProfile.avatarBase64!)!, fit: BoxFit.cover)
                                  : null,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: appState.childProfile.avatarBase64 == null 
                                ? Center(child: Text(appState.childProfile.avatar, style: const TextStyle(fontSize: 22)))
                                : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Banner
                    if (appState.showTesYukBanner) ...[
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Test Yuk! 🚀',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ayo cari tahu seberapa hebat kamu hari ini!',
                                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      height: 36,
                                      child: Stack(
                                        children: [
                                          Positioned(child: _buildAvatarStackItem('👦', Colors.white, const Color(0xFF6366F1))),
                                          Positioned(left: 20, child: _buildAvatarStackItem('👧', Colors.white, const Color(0xFF6366F1))),
                                          Positioned(left: 40, child: _buildAvatarStackItem('👦', Colors.white, const Color(0xFF6366F1))),
                                          Positioned(left: 60, child: _buildAvatarStackItem('+1', const Color(0xFFFBBF24), const Color(0xFF6366F1), isText: true)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _navigateTo('test-room'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFF59E0B),
                                        foregroundColor: Colors.white,
                                        elevation: 5,
                                        shadowColor: const Color(0xFFF59E0B).withOpacity(0.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                      ),
                                      child: const Text('Mulai!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                appState.setTesYukBannerDismissed();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Misi Hari Ini (Daily Challenge Card)
                    if (appState.todayChallenges.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '🎯 Misi Hari Ini',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/daily-challenge'),
                                  child: const Text(
                                    'Lihat Misi',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...appState.todayChallenges.map((challenge) {
                              final double progressVal = challenge.target > 0 
                                  ? (challenge.progress / challenge.target).clamp(0.0, 1.0)
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: challenge.isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(challenge.emoji, style: const TextStyle(fontSize: 14)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            challenge.title,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(3),
                                            child: LinearProgressIndicator(
                                              value: progressVal,
                                              backgroundColor: const Color(0xFFE2E8F0),
                                              color: challenge.isCompleted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${challenge.progress}/${challenge.target}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: challenge.isCompleted ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),

                    Text('Kategori Belajar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _testCategories.map((category) {
                        return GestureDetector(
                          onTap: () => _navigateTo(category['id'] as String),
                          child: Column(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: category['bgColor'] as Color,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (category['bgColor'] as Color).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Center(
                                  child: Text(category['icon'] as String, style: const TextStyle(fontSize: 24)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                category['title'] as String,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF475569)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Baru Saja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
                        Text('Lihat Semua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (recentTests.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 44)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada petualangan',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ayo mulai petualangan pertamamu sekarang!',
                              style: TextStyle(fontSize: 14, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: recentTests.map((test) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: (test['bgColor'] as Color).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Center(
                                    child: Text(test['icon'] as String, style: const TextStyle(fontSize: 24)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        test['title'] as String,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 10,
                                        width: double.infinity,
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(5)),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: test['progress'] as double,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(colors: [test['progressColor'] as Color, (test['progressColor'] as Color).withOpacity(0.8)]),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${test['scoreText']}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
                                    ),
                                    Text(
                                      'Skor',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ), // Expanded
          ],
        ), // outer Column

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
                                  
                                  if (result == true || result is String) {
                                    if (result is String) {
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
                                    color: activeChat != null ? Colors.blueAccent : const Color(0xFF16A34A).withOpacity(0.1), 
                                    width: 1.5
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(activeChat != null ? 0.2 : 0.08),
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
                                        color: activeChat != null ? Colors.white.withOpacity(0.2) : const Color(0xFFDCFCE7),
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
                                            color: activeChat != null ? Colors.white70 : const Color(0xFF16A34A).withOpacity(0.7), 
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

  Widget _buildAvatarStackItem(String content, Color bgColor, Color borderColor, {bool isText = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Text(
          content,
          style: TextStyle(
            fontSize: isText ? 12 : 14,
            fontWeight: isText ? FontWeight.bold : FontWeight.normal,
            color: isText ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
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
                            backgroundColor: Color(0xFF0D9488),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
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
                          colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
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
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    childGender == 'female' ? '👧' : '👦',
                                    style: const TextStyle(fontSize: 26),
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
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Usia $childAge Tahun • ${childGender == 'female' ? 'Perempuan' : 'Laki-laki'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildGrowthMiniStat('🧩 Logika', results.cognitive.completed ? '${results.cognitive.percentage.round()}%' : '85%'),
                                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2)),
                                _buildGrowthMiniStat('🗣️ Bahasa', results.linguistic.completed ? '${results.linguistic.percentage.round()}%' : '78%'),
                                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2)),
                                _buildGrowthMiniStat('🎯 Motorik', results.motor.completed ? '${results.motor.percentage.round()}%' : '90%'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/progress'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Buka Rapor & Analisis AI Lengkap',
                                    style: TextStyle(
                                      color: Color(0xFF0F766E),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F766E), size: 14),
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
                          onTap: () => Navigator.pushNamed(context, '/doctor-list'),
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
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
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
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(14),
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
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Minggu Ini',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0D9488),
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
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/parent-guide'),
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D9488),
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
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/doctor-list'),
                          child: const Text(
                            'Daftar Dokter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D9488),
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
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/community'),
                          child: const Text(
                            'Buka Forum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D9488),
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

  Widget _buildGrowthMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
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
        width: 200,
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
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
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
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                ),
                child: const Center(
                  child: Text('🌙', style: TextStyle(fontSize: 64)),
                ),
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
                  color: Colors.white.withOpacity(0.8),
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
                    if (result == true || result is String) {
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

}
