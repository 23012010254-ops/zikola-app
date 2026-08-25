import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/home_screen.dart';
import 'screens/test_room_screen.dart';
import 'screens/cognitive_test_screen.dart';
import 'screens/linguistic_test_screen.dart';
import 'screens/personality_test_screen.dart';
import 'screens/interest_talent_test_screen.dart';
import 'screens/game_screen.dart';
import 'screens/memory_game_screen.dart';
import 'screens/word_puzzle_game_screen.dart';
import 'screens/number_sequence_game_screen.dart';
import 'screens/pattern_recognition_game_screen.dart';
import 'screens/alien_shooter_game.dart';
import 'screens/desert_tank_shooter_game.dart';
import 'screens/desert_road_logic_game.dart';
import 'screens/story_builder_game.dart';
import 'screens/shape_sorting_game.dart';
import 'screens/sequence_memory_game.dart';
import 'screens/number_memory_game.dart';
import 'screens/motor_tips_screen.dart';
import 'screens/motor_test_game_screen.dart';
import 'screens/motor_trace_game_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sticker_collection_screen.dart';
import 'screens/consultation_screen.dart';
import 'screens/doctor_list_screen.dart';
import 'screens/doctor_detail_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/parent_guide_screen.dart';
import 'screens/community_screen.dart';
import 'screens/coloring_game_screen.dart';
import 'screens/maze_game_screen.dart';
import 'screens/spell_bee_game_screen.dart';
import 'screens/sticker_pesta_screen.dart';
import 'screens/shadow_match_game_screen.dart';
import 'screens/pipe_puzzle_game_screen.dart';
import 'screens/bubble_popper_game.dart';
import 'widgets/sticker_notification.dart';
import 'services/chat_notification_service.dart';
import 'screens/notification_screen.dart';
import 'screens/follows_screen.dart';
import 'screens/public_profile_screen.dart';

import 'screens/daily_challenge_screen.dart';
import 'screens/parental_pin_screen.dart';
import 'screens/child_selector_screen.dart';
import 'screens/screen_time_settings_screen.dart';

// Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("[FCM Background] Message received: ${message.messageId}");
  final notification = message.notification;
  final title = notification?.title ?? message.data['title'] ?? 'Zikola';
  final body = notification?.body ?? message.data['body'] ?? 'Notifikasi baru';
  
  final localPlugin = FlutterLocalNotificationsPlugin();
  const androidDetails = AndroidNotificationDetails(
    'anak_app_chat',
    'Pesan & Konsultasi Dokter',
    channelDescription: 'Notifikasi pesan baru dan panggilan telekonsultasi dokter',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  const platformDetails = NotificationDetails(android: androidDetails);
  await localPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    platformDetails,
    payload: message.data['chatId'] != null ? 'chat:${message.data['chatId']}' : 'general',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables
  await dotenv.load(fileName: ".env");
  
  bool firebaseInitialized = false;
  String? initError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // OPTIMIZATION: Explicitly enable offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    // Bind the background push messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Local Notifications & FCM Channels
    await NotificationService().initialize();
    
    firebaseInitialized = true;
  } catch (e) {
    initError = e.toString();
    debugPrint('Firebase Initialization Error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: ZikolaApp(
        initError: initError,
        firebaseInitialized: firebaseInitialized,
      ),
    ),
  );
}

class ZikolaApp extends StatelessWidget {
  final String? initError;
  final bool firebaseInitialized;

  const ZikolaApp({
    super.key, 
    this.initError, 
    this.firebaseInitialized = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zikola',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: ChatNotificationService().scaffoldMessengerKey,
      // Start at splash screen to check existing session
      initialRoute: firebaseInitialized ? '/splash' : '/init-error',
      builder: (context, child) {
        if (!firebaseInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      const Text(
                        'Configuration Error',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aplikasi tidak bisa terhubung ke database. Coba jalankan `flutterfire configure` atau periksa koneksi internet Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          initError ?? 'Unknown Error',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return Stack(
          children: [
            if (child != null) child,
            const StickerNotificationWidget(),
          ],
        );
      },
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/survey': (context) => const SurveyScreen(),
        '/home': (context) => const HomeScreen(),
        '/test-room': (context) => const TestRoomScreen(),
        '/cognitive-test': (context) => const CognitiveTestScreen(),
        '/linguistic-test': (context) => const LinguisticTestScreen(),
        '/personality-test': (context) => const PersonalityTestScreen(),
        '/interest-talent-test': (context) => const InterestTalentTestScreen(),
        '/game': (context) => const GameScreen(),
        '/memory-game': (context) => const MemoryGameScreen(),
        '/word-puzzle-game': (context) => const WordPuzzleGameScreen(),
        '/number-sequence-game': (context) => const NumberSequenceGameScreen(),
        '/pattern-recognition-game': (context) => const PatternRecognitionGameScreen(),
        '/alien-shooter': (context) => const AlienShooterGame(),
        '/desert-tank-shooter': (context) => const DesertTankShooterGame(),
        '/desert-road-logic': (context) => const DesertRoadLogicGame(),
        '/story-builder-game': (context) => const StoryBuilderGame(),
        '/shape-sorting-game': (context) => const ShapeSortingGame(),
        '/sequence-memory-game': (context) => const SequenceMemoryGame(),
        '/number-memory-game': (context) => const NumberMemoryGame(),
        '/motor-tips': (context) => const MotorTipsScreen(),
        '/motor-test-game': (context) => const MotorTestGameScreen(),
        '/motor-trace-game': (context) => const MotorTraceGameScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/stickers': (context) => const StickerCollectionScreen(),
        '/consultation': (context) => const ConsultationScreen(),
        '/doctor-list': (context) => const DoctorListScreen(),
        '/doctor-detail': (context) => const DoctorDetailScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/chat': (context) => const ChatScreen(),
        '/parent-guide': (context) => const ParentGuideScreen(),
        '/community': (context) => const CommunityScreen(),
        '/coloring-game': (context) => const ColoringGameScreen(),
        '/maze-game': (context) => const MazeGameScreen(),
        '/spell-bee': (context) => const SpellBeeGame(),
        '/sticker-pesta': (context) => const StickerPestaScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/follows-screen': (context) => const FollowsScreen(),
        '/shadow-match': (context) => const ShadowMatchGameScreen(),
        '/pipe-puzzle': (context) => const PipePuzzleGameScreen(),
        '/bubble-popper': (context) => const BubblePopperGameScreen(),
        '/public-profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final targetUid = args?['targetUid'] as String? ?? '';
          return PublicProfileScreen(targetUid: targetUid);
        },

        '/daily-challenges': (context) => const DailyChallengeScreen(),
        '/daily-challenge': (context) => const DailyChallengeScreen(),
        '/parental-pin': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final isSetup = args?['isSetup'] as bool? ?? false;
          final currentPin = args?['currentPin'] as String?;
          return ParentalPinScreen(isSetup: isSetup, currentPin: currentPin);
        },
        '/parental-pin-setup': (context) => const ParentalPinScreen(isSetup: true),
        '/child-selector': (context) => const ChildSelectorScreen(),
        '/screen-time-settings': (context) => const ScreenTimeSettingsScreen(),
      },
    );
  }
}

/// Splash screen that checks for existing Firebase Auth session.
/// If user is already logged in, loads their data and routes accordingly.
/// If not, redirects to the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _cloudController;
  late AnimationController _sunController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Logo pulse (subtle)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Cloud drift
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Sun rotation
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _logoSlideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // Sequence: fade in logo → check session
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cloudController.dispose();
    _sunController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    // Let animations play for at least 1.5s
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        debugPrint('Splash: Existing session found for uid=${currentUser.uid}');
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.setLoggedIn(true, uid: currentUser.uid);

        if (!mounted) return;

        // The build method will show the error UI.
        if (appState.initError != null) return;

        if (appState.needsSurvey) {
          Navigator.pushReplacementNamed(context, '/survey');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Splash: Error checking session: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background - Solid White
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),

          // Animated drifting clouds at the bottom (Lavender/Purple)
          AnimatedBuilder(
            animation: _cloudController,
            builder: (context, _) {
              final val = _cloudController.value * (size.width + 120);
              final lavender = const Color(0xFFDDD6FE).withOpacity(0.95);
              return Stack(
                children: [
                  _buildCloud(size, offsetX: val, offsetY: size.height - 120, scale: 1.4, opacity: 0.85, color: lavender),
                  _buildCloud(size, offsetX: val + size.width * 0.45, offsetY: size.height - 100, scale: 1.6, opacity: 0.95, color: lavender),
                  _buildCloud(size, offsetX: val + size.width * 0.8, offsetY: size.height - 130, scale: 1.2, opacity: 0.8, color: lavender),
                ],
              );
            },
          ),

          // Floating yellow stars at the bottom cloud cluster
          ...List.generate(3, (index) {
            final double left = [0.10, 0.60, 0.85][index];
            final double topFactor = [0.85, 0.88, 0.82][index];
            final double scaleFactor = [1.2, 0.8, 1.4][index];
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final double bobbing = math.sin((_pulseController.value * 2 * math.pi) + index) * 6;
                return Positioned(
                  left: size.width * left,
                  top: size.height * topFactor + bobbing,
                  child: Transform.scale(
                    scale: scaleFactor,
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFBBF24), // yellow-400
                      size: 28,
                      shadows: [
                        Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
                      ],
                    ),
                  ),
                );
              },
            );
          }),

          // Floating green puzzle piece at the bottom right cloud
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final double bobbing = math.cos(_pulseController.value * 2 * math.pi) * 8;
              return Positioned(
                right: size.width * 0.15,
                top: size.height * 0.84 + bobbing,
                child: Transform.rotate(
                  angle: _pulseController.value * 2 * math.pi * 0.2, // slow rotation
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Text(
                      '🧩',
                      style: TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              );
            },
          ),

          // White sparkles pulsing on top of clouds
          ...List.generate(4, (index) {
            final double left = [0.22, 0.70, 0.40, 0.90][index];
            final double top = [0.88, 0.90, 0.86, 0.87][index];
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final double phase = (_pulseController.value + index * 0.25) % 1.0;
                final double scale = math.sin(phase * math.pi);
                return Positioned(
                  left: size.width * left,
                  top: size.height * top,
                  child: Opacity(
                    opacity: 0.8 * scale,
                    child: Transform.scale(
                      scale: 0.6 + 0.6 * scale,
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Main Waving Character Logo, Colorful Brand Name & Slogan
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bobbing Character Logo in the center
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulseController, _logoSlideAnimation]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _logoSlideAnimation.value + (math.sin(_pulseController.value * 2 * math.pi) * 6)),
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: size.width * 0.68,
                            height: size.width * 0.68,
                            child: Image.asset(
                              'assets/images/zikola_logo_char.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // ZIKOLA Colorful Text Brand
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Z", style: TextStyle(fontFamily: 'Heading', fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFF2563EB), letterSpacing: 2)),
                      Text("I", style: TextStyle(fontFamily: 'Heading', fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 2)),
                      Text("K", style: TextStyle(fontFamily: 'Heading', fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B), letterSpacing: 2)),
                      Text("O", style: TextStyle(fontFamily: 'Heading', fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFF0D9488), letterSpacing: 2)),
                      Text("L", style: TextStyle(fontFamily: 'Heading', fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED), letterSpacing: 2)),
                      Text("A", style: TextStyle(fontFamily: 'Heading', fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFFEF4444), letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Slogan Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      "Memahami Potensi,\nMembangun Masa Depan Anak.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Heading',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3A8A), // deep dark blue
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading dots or Error UI positioned above the clouds
          Positioned(
            bottom: size.height * 0.18,
            left: 0,
            right: 0,
            child: Center(
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  if (appState.initError != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            appState.initError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => appState.retryInitialization().then((_) {
                              if (appState.initError == null) {
                                _checkSession(); // Re-trigger navigation if fixed
                              }
                            }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text("Coba Lagi"),
                          ),
                        ],
                      ),
                    );
                  }
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildLoadingDots(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloud(Size size, {required double offsetX, required double offsetY, double scale = 1.0, double opacity = 0.5, Color? color}) {
    return Positioned(
      left: offsetX % (size.width + 120) - 60,
      top: offsetY,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 120,
            height: 50,
            child: CustomPaint(painter: _CloudPainter(color: color ?? Colors.white.withOpacity(0.9))),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return SizedBox(
      width: 60,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: Duration(milliseconds: 600 + index * 200),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final phase = (_pulseController.value + index * 0.33) % 1.0;
                  final scale = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4 + 0.6 * scale),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }
}

/// Custom cloud painter for the splash screen background
class _CloudPainter extends CustomPainter {
  final Color color;
  const _CloudPainter({this.color = const Color(0xE6FFFFFF)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Main body
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 5), width: size.width * 0.8, height: size.height * 0.6), paint);
    canvas.drawCircle(Offset(cx - size.width * 0.2, cy), size.height * 0.35, paint);
    canvas.drawCircle(Offset(cx + size.width * 0.2, cy), size.height * 0.4, paint);
    canvas.drawCircle(Offset(cx, cy - size.height * 0.15), size.height * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => oldDelegate.color != color;
}
