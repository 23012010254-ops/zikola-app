import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class TestRoomScreen extends StatefulWidget {
  const TestRoomScreen({super.key});

  @override
  State<TestRoomScreen> createState() => _TestRoomScreenState();
}

class _TestRoomScreenState extends State<TestRoomScreen> {
  // We can add a "results" phase if we want to show the final results screen
  // For now, we mainly replicate the "intro" phase layout
  bool _showResults = false;

  void _navigateToTest(String routeName, String testId) async {
    await Navigator.pushNamed(context, routeName);
    // When returning from test, AppState will have been updated
    // We can call setState to rebuild
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return _buildResultsPhase();
    }
    return _buildIntroPhase();
  }

  Widget _buildIntroPhase() {
    final appState = context.watch<AppState>();
    final results = appState.testResults;

    // Define test phases matching React version
    final testPhases = [
      {
        'id': 'cognitive',
        'title': 'Game Matematika 🧮',
        'description': 'Latih logika dan kemampuan matematis!',
        'emoji': '🧮',
        'colors': [const Color(0xFF60A5FA), const Color(0xFF2563EB)], // blue-400, blue-600
        'duration': '10 menit',
        'route': '/cognitive-test',
        'completed': results.cognitive.completed,
        'score': results.cognitive.total > 0 ? ((results.cognitive.score / results.cognitive.total) * 100).round() : 0,
      },
      {
        'id': 'linguistic',
        'title': 'Game Linguistik 📖',
        'description': 'Asah kemampuan bahasa dan kata!',
        'emoji': '📖',
        'colors': [const Color(0xFFC084FC), const Color(0xFF9333EA)], // purple-400, purple-600
        'duration': '8 menit',
        'route': '/linguistic-test',
        'completed': results.linguistic.completed,
        'score': results.linguistic.total > 0 ? ((results.linguistic.score / results.linguistic.total) * 100).round() : 0,
      },
      {
        'id': 'personality',
        'title': 'Cerita Bergambar 📚',
        'description': 'Petualangan cerita interaktif untukmu!',
        'emoji': '📚',
        'colors': [const Color(0xFFFB923C), const Color(0xFFEA580C)], // orange-400, orange-600
        'duration': '12 menit',
        'route': '/personality-test',
        'completed': results.personality.completed,
        'score': results.personality.completed ? 100 : 0,
      }
    ];

    int completedCount = testPhases.where((t) => t['completed'] == true).length;
    bool allCompleted = completedCount == testPhases.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)], // slate-200 to slate-300
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF475569), size: 20),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Petualangan\nBelajar Pribadi! 🏰',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E293B),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Yuk ikuti 3 petualangan seru untuk mengetahui seberapa hebat kemampuanmu! 🌟',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Welcome Message
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text('👩‍⚕️', style: TextStyle(fontSize: 40)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Halo! Yuk, ikuti 3 petualangan seru untuk mengetahui seberapa hebat kemampuanmu! 🌟',
                                      style: AppTheme.bodyText.copyWith(color: const Color(0xFF065F46), fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                  ),
                                  Positioned(
                                    left: -6,
                                    top: 16,
                                    child: Transform.rotate(
                                      angle: 0.785398, // 45 degrees
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        color: const Color(0xFFD1FAE5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Test Progress
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                 Text('Kemajuan Petualangan', style: AppTheme.heading3.copyWith(color: const Color(0xFF065F46), fontSize: 15)),
                                 Text('$completedCount/${testPhases.length} selesai', style: AppTheme.bodyText.copyWith(color: const Color(0xFF059669), fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: completedCount / testPhases.length,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981), // emerald-500
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Test Phases List
                      Column(
                        children: testPhases.asMap().entries.map((entry) {
                          int index = entry.key;
                          var phase = entry.value;
                          
                          bool isCompleted = phase['completed'] as bool;
                          bool isNext = index == completedCount;
                          bool isLocked = index > completedCount;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: phase['colors'] as List<Color>,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: (phase['colors'] as List<Color>)[1].withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              child: Opacity(
                                opacity: isLocked ? 0.6 : 1.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    children: [
                                      // Icon/Emoji Stack
                                      SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: Stack(
                                          children: [
                                            Center(child: Text(phase['emoji'] as String, style: const TextStyle(fontSize: 32))),
                                            if (isCompleted)
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    color: AppTheme.green500,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(2),
                                                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                                                ),
                                              ),
                                            if (isLocked)
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.3),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.lock, color: Colors.white, size: 24),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              phase['title'] as String,
                                               style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 15),
                                               maxLines: 1,
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                             const SizedBox(height: 4),
                                             Text(
                                               phase['description'] as String,
                                               style: AppTheme.bodyText.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis,
                                             ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.access_time, color: Colors.white70, size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(phase['duration'] as String, style: AppTheme.bodyText.copyWith(color: Colors.white70, fontSize: 12)),
                                                  ],
                                                ),
                                                if (isCompleted)
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.emoji_events, color: Colors.white70, size: 14),
                                                      const SizedBox(width: 4),
                                                       Text('${phase['score']}% skor', style: AppTheme.bodyText.copyWith(color: Colors.white70, fontSize: 11)),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Action button
                                      const SizedBox(width: 12),
                                      if (isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.green500,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text('Selesai ✓', style: AppTheme.bodyText.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                        )
                                      else if (isNext)
                                        ElevatedButton(
                                          onPressed: () => _navigateToTest(phase['route'] as String, phase['id'] as String),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black87,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          ),
                                          child: Text('Yuk!', style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        Text('Tunggu ya...', style: AppTheme.bodyText.copyWith(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Final Result trigger
                      if (allCompleted)
                        GestureDetector(
                          onTap: () => setState(() => _showResults = true),
                          child: Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.yellow400, AppTheme.orange500],
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.orange500.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                 const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                                 const SizedBox(width: 12),
                                 Text('Lihat Hasilku! 🎉', style: AppTheme.heading2.copyWith(color: Colors.white, fontSize: 18)),
                              ],
                            ),
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
    );
  }

  Widget _buildResultsPhase() {
    final appState = context.watch<AppState>();
    final results = appState.testResults;

    int totalScore = 0;
    int testCount = 3;

    int cognitiveScore = results.cognitive.total > 0 ? ((results.cognitive.score / results.cognitive.total) * 100).round() : 0;
    int linguisticScore = results.linguistic.total > 0 ? ((results.linguistic.score / results.linguistic.total) * 100).round() : 0;
    int personalityScore = results.personality.completed ? 100 : 0;

    totalScore = ((cognitiveScore + linguisticScore + personalityScore) / testCount).round();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDE68A), Color(0xFFFED7AA)], // yellow-200 to orange-200
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showResults = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3), // yellow-100
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Color(0xFFCA8A04)), // yellow-600
                      ),
                    ),
                    Expanded(
                         child: Text(
                         'Hasil Petualanganku! 🏆',
                         style: AppTheme.heading2.copyWith(color: const Color(0xFF854D0E), fontSize: 18), // yellow-800
                         textAlign: TextAlign.center,
                       ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Overall Score
                      Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                             Text('Skor Totalku!', style: AppTheme.heading2.copyWith(color: const Color(0xFF854D0E), fontSize: 18)),
                             const SizedBox(height: 8),
                             Text('$totalScore%', style: AppTheme.heading1.copyWith(color: const Color(0xFFCA8A04), fontSize: 40)),
                            const SizedBox(height: 16),
                             Text(
                               totalScore >= 85 ? 'Kamu luar biasa banget!' : (totalScore >= 70 ? 'Kamu keren banget!' : 'Kamu hebat, terus belajar ya!'),
                               style: AppTheme.bodyText.copyWith(color: const Color(0xFFA16207), fontSize: 16),
                               textAlign: TextAlign.center,
                             ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Individual results
                      _buildResultItem('Game Matematika 🧮', '🧮', cognitiveScore, [AppTheme.blue400, AppTheme.blue600]),
                      const SizedBox(height: 16),
                      _buildResultItem('Game Linguistik 📖', '📖', linguisticScore, [AppTheme.purple400, AppTheme.purple600]),
                      const SizedBox(height: 16),
                      _buildResultItem('Cerita Bergambar 📚', '📚', personalityScore, [AppTheme.orange400, AppTheme.orange600]),
                      
                      const SizedBox(height: 32),
                      
                      Center(
                        child: Column(
                          children: [
                            const Text('🌟', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                'Selamat! Kamu sudah menyelesaikan semua petualangan dengan hebat!',
                                style: AppTheme.heading3.copyWith(color: const Color(0xFFCA8A04)),
                                textAlign: TextAlign.center,
                              ),
                            ),
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
    );
  }

  Widget _buildResultItem(String title, String emoji, int score, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(title, style: AppTheme.heading3.copyWith(color: AppTheme.gray800, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.gray200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: score / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
           Text('$score%', style: AppTheme.heading2.copyWith(color: AppTheme.gray600, fontSize: 20)),
        ],
      ),
    );
  }
}

// Ensure the colors exist
extension AppThemeExt on AppTheme {
  static const Color blue400 = Color(0xFF60a5fa);
  static const Color purple400 = Color(0xFFc084fc);
  static const Color orange400 = Color(0xFFfb923c);
}
