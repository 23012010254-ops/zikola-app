import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
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
import 'screens/onboarding_screen.dart';
import 'screens/motor_test_game_screen.dart';
import 'screens/motor_trace_game_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sticker_collection_screen.dart';
import 'screens/photo_booth_screen.dart';
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
import 'screens/doctor_web_screen.dart';
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

  // Initialize Local Notifications & Smart Auto Reminders immediately & unconditionally
  NotificationService().initialize().catchError((e) {
    debugPrint('NotificationService init error: $e');
  });
  
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
            ?child,
            const StickerNotificationWidget(),
          ],
        );
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
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
        '/sticker-collection': (context) => const StickerCollectionScreen(),
        '/photo-booth': (context) => const PhotoBoothScreen(),
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
        '/doctor-portal': (context) => const DoctorWebScreen(),
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
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Gentle breathing / pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Fade in transition
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    // Let animation play smoothly for at least 2 seconds so users can enjoy the splash screen
    await Future.delayed(const Duration(milliseconds: 2000));
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        debugPrint('Splash: Existing session found for uid=');
        final appState = Provider.of<AppState>(context, listen: false);
        try {
          await appState.setLoggedIn(true, uid: currentUser.uid).timeout(
            const Duration(milliseconds: 3500),
            onTimeout: () {
              debugPrint('Splash: setLoggedIn timed out, continuing with cached/offline data');
            },
          );
        } catch (err) {
          debugPrint('Splash: setLoggedIn error caught: $err');
        }

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
      backgroundColor: const Color(0xFF6EB9FD),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Sky blue gradient background base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6EB9FD),
                  Color(0xFFBCE0FA),
                  Color(0xFFD6EEFD),
                ],
              ),
            ),
          ),

          // 2. Full 3D Master Splash Artwork with gentle breathing animation & fade in
          FadeTransition(
            opacity: _fadeAnimation,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double bobbing = math.sin(_pulseController.value * 2 * math.pi) * 2;
                final double scale = 1.0 + (math.sin(_pulseController.value * 2 * math.pi) * 0.008);
                return Transform.translate(
                  offset: Offset(0, bobbing),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/zikola_splash_full.png',
                fit: BoxFit.cover,
                width: size.width,
                height: size.height,
              ),
            ),
          ),

          // 3. Magical sparkling stars in the sky
          _buildSparkles(size),

          // 4. Subtle loading indicator or Error UI at bottom
          Positioned(
            bottom: math.max(MediaQuery.of(context).padding.bottom + 16, 28),
            left: 0,
            right: 0,
            child: Center(
              child: Consumer<AppState>(
                builder: (context, appState, child) {
                  if (appState.initError != null) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            appState.initError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => appState.retryInitialization().then((_) {
                              if (appState.initError == null) {
                                _checkSession();
                              }
                            }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            ),
                            child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSparkles(Size size) {
    final sparklePoints = [
      Offset(size.width * 0.12, size.height * 0.08),
      Offset(size.width * 0.88, size.height * 0.12),
      Offset(size.width * 0.20, size.height * 0.36),
      Offset(size.width * 0.84, size.height * 0.40),
      Offset(size.width * 0.14, size.height * 0.62),
    ];

    return Stack(
      children: List.generate(sparklePoints.length, (index) {
        final pt = sparklePoints[index];
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            final phase = (_pulseController.value + index * 0.25) % 1.0;
            final scale = math.sin(phase * math.pi);
            final opacity = (0.2 + 0.8 * scale).clamp(0.0, 1.0);
            return Positioned(
              left: pt.dx,
              top: pt.dy,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: _pulseController.value * math.pi * 0.5,
                  child: Icon(
                    Icons.star_rounded,
                    color: index % 2 == 0 ? const Color(0xFFFDE047) : Colors.white,
                    size: 14 + (8 * scale),
                    shadows: const [
                      Shadow(
                        color: Colors.white70,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildLoadingDots() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final colors = [
            const Color(0xFF06B6D4), // Cyan
            const Color(0xFF8B5CF6), // Purple
            const Color(0xFFF59E0B), // Amber
          ];
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final phase = (_pulseController.value + index * 0.33) % 1.0;
              final scale = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: colors[index % colors.length].withValues(alpha: 0.5 + 0.5 * scale),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
