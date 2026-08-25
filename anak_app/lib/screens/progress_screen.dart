import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/app_state.dart';
import '../services/ai_report_service.dart';
import '../services/assessment_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _activeTab = 'current';

  void _generateAIReport() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    appState.setAIReportStatus(AIReportStatus.loading);

    try {
      final service = AIReportService();
      final providerKey = dotenv.env['AI_PROVIDER'] ?? 'mock';
      String apiKey = '';
      if (providerKey == 'gemini') apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      else if (providerKey == 'openai') apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
      else if (providerKey == 'anthropic') apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';

      final report = await service.generateReport(
        childName: appState.childProfile.name.isNotEmpty ? appState.childProfile.name : 'Siswa',
        childAge: appState.childProfile.age > 0 ? appState.childProfile.age : 7,
        childGender: appState.childProfile.gender.isNotEmpty ? appState.childProfile.gender : 'Laki-laki',
        games: appState.gameAssessments,
        testResults: appState.testResults,
        provider: providerKey,
        apiKey: apiKey,
        forceRefresh: true, // Force refresh when user explicitly clicks generate
      );

      appState.updateAIReport(report);
    } catch (e) {
      debugPrint('AI Report Generation Error: $e');
      appState.setAIReportStatus(AIReportStatus.error);
    }
  }

  void _deleteReport() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan AI ini? Anda dapat men-generate-nya kembali kapan saja.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await appState.deleteAIReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final childProfile = appState.childProfile;

    // Calculate user stats
    int completedTests = 0;
    if (appState.testResults.cognitive.completed) completedTests++;
    if (appState.testResults.linguistic.completed) completedTests++;
    if (appState.testResults.personality.completed) completedTests++;
    if (appState.testResults.motor.completed) completedTests++;

    double avgScore = 0;
    int totalScore = 0;
    int totalPossible = 0;
    if (appState.testResults.cognitive.completed) {
      totalScore += appState.testResults.cognitive.score;
      totalPossible += appState.testResults.cognitive.total;
    }
    if (appState.testResults.linguistic.completed) {
      totalScore += appState.testResults.linguistic.score;
      totalPossible += appState.testResults.linguistic.total;
    }
    if (appState.testResults.motor.completed) {
      totalScore += appState.testResults.motor.score;
      totalPossible += appState.testResults.motor.total;
    }
    if (totalPossible > 0) {
      avgScore = (totalScore / totalPossible) * 100;
    }

    String rank = 'Pemula';
    if (avgScore >= 90) rank = 'Luar Biasa';
    else if (avgScore >= 80) rank = 'Sangat Baik';
    else if (avgScore >= 70) rank = 'Baik';
    else if (avgScore >= 60) rank = 'Cukup';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Text(
                    'Dashboard Perkembangan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Navigation
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton('current', 'Saat Ini', Icons.bar_chart_rounded),
                        _buildTabButton('weekly', 'Mingguan', Icons.calendar_today_rounded),
                        _buildTabButton('charts', 'Grafik', Icons.trending_up_rounded),
                        _buildTabButton('emr', 'Rekam Medis', Icons.medical_services_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // ── User Identity ───────────────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dashboard Perkembangan Pengguna',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  childProfile.name.isNotEmpty ? childProfile.name : 'Anak',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Level Saat Ini: ${completedTests > 0 ? completedTests : 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              children: [
                                Text(
                                  rank,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${avgScore.toInt()}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Waktu Layar Card
                    _buildScreenTimeCard(appState),
                    const SizedBox(height: 24),

                    // Tab Views
                    if (_activeTab == 'current') _buildCurrentTab(appState, avgScore, completedTests),
                    if (_activeTab == 'weekly') _buildWeeklyTab(appState),
                    if (_activeTab == 'charts') _buildChartsTab(appState),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  Widget _buildScreenTimeCard(AppState appState) {
    final weeklyData = appState.getWeeklyScreenTimeData();
    
    int maxMinutes = weeklyData.fold<int>(0, (max, day) {
      final m = day['minutes'] as int? ?? 0;
      return m > max ? m : max;
    });
    if (maxMinutes < 60) maxMinutes = 60;
    
    final int todayMinutes = appState.todayPlayTime;
    final int limitMinutes = appState.screenTimeLimit;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('⏱️', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Waktu Layar Anak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
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
                    if (result is String) {
                      await appState.setParentalPin(result);
                    }
                    await appState.resetTodayPlayTime();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Waktu layar hari ini di-reset ke 0 menit ⏱️'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primaryBlue),
                label: const Text(
                  'Reset Harian',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: AppTheme.primaryBlueLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PENGGUNAAN HARI INI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$todayMinutes Menit',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (limitMinutes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: todayMinutes >= limitMinutes 
                          ? Colors.red.shade50 
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Batas: $limitMinutes m',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: todayMinutes >= limitMinutes 
                            ? Colors.red.shade700 
                            : Colors.green.shade700,
                      ),
                    ),
                  )
                else
                  const Text(
                    'Tanpa Batas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Riwayat Penggunaan Mingguan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyData.map((day) {
              final int mins = day['minutes'] as int? ?? 0;
              final String label = day['dayLabel'] as String? ?? '';
              final bool isToday = day['isToday'] as bool? ?? false;
              
              final double heightRatio = mins / maxMinutes;
              final double barHeight = (heightRatio * 100).clamp(6.0, 100.0);
              
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      '${mins}m',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? const Color(0xFFF97316) : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 100,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 16,
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          gradient: isToday
                              ? const LinearGradient(
                                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFF97316).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                        color: isToday ? const Color(0xFFEA580C) : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String id, String label, IconData icon) {
    final bool isActive = _activeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(AppState appState, double avgScore, int completedTests) {
    final report = appState.latestAIReport;
    final status = appState.aiStatus;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDoctorActionPlanSection(appState),
          _buildAIReportSection(appState, report, status),
          const SizedBox(height: 24),
          _buildTestProgressGrid(appState),
          const SizedBox(height: 24),
          _buildRecommendationCard(appState),
        ],
      ),
    );
  }


  Widget _buildDoctorActionPlanSection(AppState appState) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildDefaultStimulationPrompt(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('buyerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return _buildDefaultStimulationPrompt(context);
        }

        final chatDoc = chatSnapshot.data!.docs.first;
        final chatId = chatDoc.id;
        final doctorName = (chatDoc.data() as Map<String, dynamic>)['doctorName'] ?? 'Dokter Spesialis Anak';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, msgSnapshot) {
            if (!msgSnapshot.hasData || msgSnapshot.data!.docs.isEmpty) {
              return _buildDefaultStimulationPrompt(context);
            }

            Map<String, dynamic>? actionPlanMsg;
            for (final doc in msgSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final text = data['text']?.toString() ?? '';
              if (text.contains('ACTION PLAN') || text.contains('Target Fokus')) {
                actionPlanMsg = data;
                break;
              }
            }

            if (actionPlanMsg == null) {
              return _buildDefaultStimulationPrompt(context);
            }

            final rawText = actionPlanMsg['text']?.toString() ?? '';
            String target = 'Motorik & Regulasi Emosi';
            String screenTime = 'Maks. 30 Menit/Hari';
            String notes = 'Dampingi anak saat bermain dan konsisten dengan jadwal makan bebas layar.';

            final targetMatch = RegExp(r'Target Fokus\*?:\\s*([^\\n]+)').firstMatch(rawText);
            if (targetMatch != null) target = targetMatch.group(1)?.trim() ?? target;

            final screenMatch = RegExp(r'Batas Waktu Layar\*?:\\s*([^\\n]+)').firstMatch(rawText);
            if (screenMatch != null) screenTime = screenMatch.group(1)?.trim() ?? screenTime;

            final notesMatch = RegExp(r'Instruksi Khusus\*?:\\s*([\\s\\S]+?)(?=\\n\\n|Silakan|$)').firstMatch(rawText);
            if (notesMatch != null) notes = notesMatch.group(1)?.trim() ?? notes;

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('RESEP STIMULASI DOKTER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Aktif Minggu Ini', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        child: Text('👨‍⚕️', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Rekomendasi Spesialis Anak', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  children: [
                                    const TextSpan(text: 'Target Fokus: ', style: TextStyle(color: Colors.white70)),
                                    TextSpan(text: target, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          children: [
                            const Text('📱', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  children: [
                                    const TextSpan(text: 'Batas Layar: ', style: TextStyle(color: Colors.white70)),
                                    TextSpan(text: screenTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notes,
                                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pushNamed(context, '/consultation');
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Buka Konsultasi Dokter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultStimulationPrompt(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('📋', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rencana Stimulasi Dokter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.gray900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Konsultasikan hasil asesmen untuk mendapatkan resep stimulasi resmi.',
                  style: TextStyle(fontSize: 11, color: AppTheme.gray500, height: 1.3),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/consultation'),
                  child: const Row(
                    children: [
                      Text('Tanya Dokter Spesialis', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 12, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIReportSection(AppState appState, AIReport? report, AIReportStatus status) {
    if (status == AIReportStatus.loading) {
      return _buildAIStatusCard(
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI sedang menganalisis data...', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Mohon tunggu sebentar', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    if (report == null || status == AIReportStatus.idle) {
      return _buildAIStatusCard(
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Analisis Perkembangan AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Dapatkan laporan mendalam tentang potensi dan area perkembangan anak menggunakan AI Gemini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateAIReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Generate Laporan AI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (status == AIReportStatus.error) {
      return _buildAIStatusCard(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Gagal Membuat Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Terjadi kesalahan saat menghubungi server AI.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextButton(onPressed: _generateAIReport, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    return _buildAIReportContent(report);
  }

  Widget _buildAIStatusCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  void _exportReport(BuildContext context, AIReport report, String childName) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final String cleanChildName = childName.isEmpty ? 'Anak' : childName;
    final String fileName = 'Laporan_Perkembangan_${cleanChildName.replaceAll(' ', '_')}.md';
    
    // Copy to clipboard is a guaranteed fallback
    await Clipboard.setData(ClipboardData(text: report.rawMarkdown));
    
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Laporan Perkembangan',
        fileName: fileName,
        bytes: utf8.encode(report.rawMarkdown),
      );
      
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(report.rawMarkdown);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Laporan berhasil diekspor ke $outputFile! Laporan juga disalin ke clipboard.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('File picker save error or not supported: $e');
    }
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('Laporan perkembangan telah disalin ke clipboard!'),
        backgroundColor: AppTheme.primaryBlue,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildAIReportContent(AIReport report) {
    final appState = Provider.of<AppState>(context, listen: false);
    final childProfile = appState.childProfile;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hasil Analisis AI Gemini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Dihasilkan: ${report.generatedAt.toLocal().toString().split('.')[0]}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _generateAIReport,
                  tooltip: 'Regenerasi Laporan',
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  onPressed: () => _exportReport(context, report, childProfile.name),
                  tooltip: 'Ekspor Laporan',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _deleteReport,
                  tooltip: 'Hapus Laporan',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: MarkdownBody(
              data: report.rawMarkdown,
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.5),
                h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, height: 1.5),
                p: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                listBullet: TextStyle(fontSize: 14, color: AppTheme.primaryBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // WEEKLY TAB
  // ============================
  Widget _buildWeeklyTab(AppState appState) {
    final tr = appState.testResults;
    final games = appState.gameAssessments;
    
    // Hitung real scores and clamp to 100%
    final double cogScore = AssessmentEngine.calculateCognitiveComposite(games).clamp(0.0, 100.0);
    final double linScore = AssessmentEngine.calculateLinguisticComposite(games, tr.linguistic).clamp(0.0, 100.0);
    final double perSocial = tr.personality.socialScore?.toDouble() ?? 0.0;
    final double perEmotional = tr.personality.emotionalScore?.toDouble() ?? 0.0;
    final double perCharacter = tr.personality.characterScore?.toDouble() ?? 0.0;
    final double socemScore = (tr.personality.completed ? (perSocial + perEmotional + perCharacter) / 3 : 0.0).clamp(0.0, 100.0);
    
    // Hitung motorik composite and clamp to 100%
    final double motorComposite = (tr.motor.completed 
        ? (tr.motor.percentage + games.coloringGame.averageScore.toDouble()) / (games.coloringGame.totalPlayed > 0 ? 2 : 1)
        : (games.coloringGame.totalPlayed > 0 ? games.coloringGame.averageScore.toDouble() : 0.0)).clamp(0.0, 100.0);

    List<double> genCurve(double finalScore) {
       return [0.0, (finalScore * 0.33).roundToDouble(), (finalScore * 0.66).roundToDouble(), finalScore];
    }
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress Mingguan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Color(0xFFF3F4F6),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const labels = ['Mg 1', 'Mg 2', 'Mg 3', 'Mg 4'];
                            if (value.toInt() >= 0 && value.toInt() < labels.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(labels[value.toInt()], style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 25,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toInt().toString(), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 3,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      _createLineData(genCurve(socemScore), const Color(0xFF3B82F6)),
                      _createLineData(genCurve(cogScore), const Color(0xFFF97316)),
                      _createLineData(genCurve(linScore), const Color(0xFF10B981)),
                      _createLineData(genCurve(motorComposite), const Color(0xFFE11D48)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildLegendItem('Kepribadian', const Color(0xFF3B82F6)),
                  _buildLegendItem('Kognitif', const Color(0xFFF97316)),
                  _buildLegendItem('Linguistik', const Color(0xFF10B981)),
                  _buildLegendItem('Motorik', const Color(0xFFE11D48)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Weekly Summary Cards (2x2 Grid)
        Column(
          children: [
            Row(
              children: [
                _buildWeeklySummaryCard('Kepribadian', socemScore.round(), tr.personality.completed ? '+Aktif' : 'N/A', const Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                _buildWeeklySummaryCard('Kognitif', cogScore.round(), 'Aktif', const Color(0xFFF97316)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildWeeklySummaryCard('Linguistik', linScore.round(), 'Aktif', const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _buildWeeklySummaryCard('Motorik', motorComposite.round(), tr.motor.completed ? 'Aktif' : 'N/A', const Color(0xFFE11D48)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  LineChartBarData _createLineData(List<double> spots, Color color) {
    return LineChartBarData(
      spots: List.generate(spots.length, (i) => FlSpot(i.toDouble(), spots[i])),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: color,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(String title, int value, String change, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Text(
              '$value%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$change minggu ini',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // CHARTS TAB
  // ============================
  Widget _buildChartsTab(AppState appState) {
    final tr = appState.testResults;
    final games = appState.gameAssessments;

    // Subdomains kognitif
    final gf = AssessmentEngine.calculateFluidReasoning(games).clamp(0.0, 100.0);
    final gwm = AssessmentEngine.calculateWorkingMemory(games).clamp(0.0, 100.0);
    final gs = AssessmentEngine.calculateProcessingSpeed(games).clamp(0.0, 100.0);
    final gv = AssessmentEngine.calculateVisualProcessing(games).clamp(0.0, 100.0);

    // Subdomains linguistik
    final gc = AssessmentEngine.calculateCrystallizedKnowledge(games).clamp(0.0, 100.0);
    final expressive = games.storyBuilderGame.averageScore.toDouble().clamp(0.0, 100.0);
    final phonemic = ((games.wordPuzzle.averageScore + games.spellBeeGame.averageScore) / 2.0).clamp(0.0, 100.0);

    // Subdomains kepribadian
    final perSocial = (tr.personality.socialScore?.toDouble() ?? 0.0).clamp(0.0, 100.0);
    final perEmotional = (tr.personality.emotionalScore?.toDouble() ?? 0.0).clamp(0.0, 100.0);
    final perCharacter = (tr.personality.characterScore?.toDouble() ?? 0.0).clamp(0.0, 100.0);

    return Column(
      children: [
        _buildBarChartCard('Analisis Kognitif (CHC)', const Color(0xFFF97316), [
          {'name': 'Logika/Gf', 'score': gf, 'target': 100.0},
          {'name': 'Memori/Gwm', 'score': gwm, 'target': 100.0},
          {'name': 'Visual/Gv', 'score': gv, 'target': 100.0},
          {'name': 'Kecepatan/Gs', 'score': gs, 'target': 100.0},
        ]),
        const SizedBox(height: 20),
        _buildBarChartCard('Analisis Linguistik', const Color(0xFF10B981), [
          {'name': 'Pengetahuan/Gc', 'score': gc, 'target': 100.0},
          {'name': 'Ekspresi/Glr', 'score': expressive > 0 ? expressive : (tr.linguistic.completed ? tr.linguistic.percentage : 0.0).clamp(0.0, 100.0), 'target': 100.0},
          {'name': 'Fonemik', 'score': phonemic, 'target': 100.0},
        ]),
        const SizedBox(height: 20),
        _buildBarChartCard('Analisis Sosial-Emosional', const Color(0xFF3B82F6), [
          {'name': 'Emosional', 'score': perEmotional, 'target': 100.0},
          {'name': 'Karakter', 'score': perCharacter, 'target': 100.0},
          {'name': 'Sosial', 'score': perSocial, 'target': 100.0},
        ]),
        const SizedBox(height: 20),
        _buildBarChartCard('Analisis Motorik', const Color(0xFFE11D48), [
          {'name': 'Kasar', 'score': (tr.motor.completed ? tr.motor.percentage : 0.0).clamp(0.0, 100.0), 'target': 100.0},
          {'name': 'Halus', 'score': games.coloringGame.averageScore.toDouble().clamp(0.0, 100.0), 'target': 100.0},
          {'name': 'Ketelitian', 'score': (games.coloringGame.totalPlayed > 0 ? (100.0 - (games.coloringGame.averageErrors.toDouble() * 5.0).clamp(0.0, 50.0)) : 0.0).clamp(0.0, 100.0), 'target': 100.0},
        ]),
      ],
    );
  }

  Widget _buildBarChartCard(String title, Color mainColor, List<Map<String, dynamic>> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              data[value.toInt()]['name'],
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 25 || value == 50 || value == 75 || value == 100) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF3F4F6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['score'],
                        color: mainColor,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: entry.value['target'],
                        color: Colors.grey.shade300,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Skor Saat Ini', mainColor),
              _buildLegendItem('Target', Colors.grey.shade300),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestProgressGrid(AppState appState) {
    final results = appState.testResults;
    final games = appState.gameAssessments;
    
    final double cogScore = AssessmentEngine.calculateCognitiveComposite(games).clamp(0.0, 100.0);
    final double linScore = AssessmentEngine.calculateLinguisticComposite(games, results.linguistic).clamp(0.0, 100.0);
    
    final double perSocial = results.personality.socialScore?.toDouble() ?? 0.0;
    final double perEmotional = results.personality.emotionalScore?.toDouble() ?? 0.0;
    final double perCharacter = results.personality.characterScore?.toDouble() ?? 0.0;
    final double socemScore = (results.personality.completed ? (perSocial + perEmotional + perCharacter) / 3 : 0.0).clamp(0.0, 100.0);
    
    final bool motorCompleted = results.motor.completed;
    final double motorScore = results.motor.score.toDouble().clamp(0.0, 100.0);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildProgressCard('Kognitif', 'Logika & Memori', cogScore.toInt(), const Color(0xFFF97316)),
        _buildProgressCard('Linguistik', 'Bahasa & Kata', linScore.toInt(), const Color(0xFF10B981)),
        _buildProgressCard('Kepribadian', 'Sosial Emosional', socemScore.toInt(), const Color(0xFF3B82F6)),
        _buildProgressCard('Motorik', 'Sensor & Ketelitian', motorCompleted ? motorScore.toInt() : 0, const Color(0xFFE11D48)),
      ],
    );
  }

  Widget _buildProgressCard(String title, String subtitle, int percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$percentage', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color)),
                const Text('%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(AppState appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tips_and_updates_rounded, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Rekomendasi Belajar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Selesaikan lebih banyak tes kognitif, linguistik, dan motorik untuk mendapatkan analisis mendalam dari AI.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/test-room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Mulai Tes Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmrTab(BuildContext context, AppState appState, ChildProfile profile) {
    final uid = appState.uid;
    if (uid == null) {
      return const Center(child: Text('Silakan login untuk melihat rekam medis.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. EMR Summary Card
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('emr').doc('latest').snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.hasData && snapshot.data!.exists ? snapshot.data!.data() as Map<String, dynamic> : null;
            final birthCondition = data?['birthCondition'] ?? 'Normal (Cukup Bulan)';
            final allergies = data?['allergies'] ?? 'Tidak ada alergi';
            final previousTherapy = data?['previousTherapy'] ?? 'Belum ada terapi sebelumnya';

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rekam Medis Digital Pasien',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Terintegrasi dengan Portal Dokter Zikola',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildEmrRow('Kondisi Kelahiran', birthCondition),
                  const SizedBox(height: 8),
                  _buildEmrRow('Riwayat Alergi', allergies),
                  const SizedBox(height: 8),
                  _buildEmrRow('Riwayat Terapi', previousTherapy),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // 2. Doctor Notes Stream
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Catatan Klinis Dokter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Terverifikasi Dokter',
                style: TextStyle(color: Color(0xFF059669), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notes')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum Ada Catatan Dokter',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catatan evaluasi akan muncul setelah sesi konsultasi dengan dokter selesai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final note = doc.data() as Map<String, dynamic>;
                final category = note['category'] ?? 'Konsultasi';
                final text = note['text'] ?? '';
                final doctorName = note['doctorName'] ?? 'Dokter Zikola';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFFEFF6FF),
                                child: Text('👨‍⚕️', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                doctorName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 24),

        // 3. Share Report Summary Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final summary = 'Rapor Tumbuh Kembang ${profile.name} (Usia ${profile.age} Thn): Perkembangan kognitif dan stimulasi terpantau baik di Aplikasi Zikola.';
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ringkasan rapor berhasil disalin ke clipboard! 📋'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Salin Ringkasan Rapor Tumbuh Kembang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmrRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

}
