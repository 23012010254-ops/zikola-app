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
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/ai_report_service.dart';
import '../services/assessment_engine.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

class ProgressScreen extends StatefulWidget {
  final String? initialTab;
  const ProgressScreen({super.key, this.initialTab});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _activeTab = 'current';
  bool _tabInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _activeTab = widget.initialTab!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['tab'] is String) {
        _activeTab = args['tab'] as String;
      } else if (args is String) {
        _activeTab = args;
      }
      _tabInitialized = true;
    }
  }

  void _generateAIReport() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    appState.setAIReportStatus(AIReportStatus.loading);

    try {
      final service = AIReportService();
      final providerKey = dotenv.env['AI_PROVIDER'] ?? 'mock';
      String apiKey = '';
      if (providerKey == 'gemini') {
        apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      } else if (providerKey == 'openai') apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
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
    if (avgScore >= 90) {
      rank = 'Luar Biasa';
    } else if (avgScore >= 80) rank = 'Sangat Baik';
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
                        _buildTabButton('emr', 'Medis', Icons.medical_services_rounded),
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
                    // â”€â”€ User Identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
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
                                    color: Colors.white.withValues(alpha: 0.8),
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
                                  'Level Saat Ini: ${appState.currentLevel}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              children: [
                                Text(
                                  rank,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
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
                    if (_activeTab != 'emr') ...[
                      _buildScreenTimeCard(appState),
                      const SizedBox(height: 24),
                    ],

                    // Tab Views
                    if (_activeTab == 'current') _buildCurrentTab(appState, avgScore, completedTests),
                    if (_activeTab == 'weekly') _buildWeeklyTab(appState),
                    if (_activeTab == 'charts') _buildChartsTab(appState),
                    if (_activeTab == 'emr') _buildEmrTab(appState),
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
            color: Colors.black.withValues(alpha: 0.04),
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
                  
                  if (result == true || (result is String && result.length == 4)) {
                    if (result is String && result.length == 4) {
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
                                    color: const Color(0xFFF97316).withValues(alpha: 0.3),
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  ),
                  maxLines: 1,
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
              child: const Text('Buat Laporan AI', style: TextStyle(fontWeight: FontWeight.bold)),
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
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                      Text('Dihasilkan: ${report.generatedAt.toLocal().toString().split('.')[0]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
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
                color: Colors.black.withValues(alpha: 0.04),
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
              color: Colors.black.withValues(alpha: 0.04),
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
            color: Colors.black.withValues(alpha: 0.04),
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
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          final String rawName = data[value.toInt()]['name'].toString();
                          final List<String> parts = rawName.split('/');
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  parts[0],
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (parts.length > 1)
                                  Text(
                                    '(${parts[1]})',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
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
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withValues(alpha: 0.15)),
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
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
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

  // ─── EMR & DIGITAL PRESCRIPTION TAB ───────────────────────────────────────────
  Widget _buildEmrTab(AppState appState) {
    final user = FirebaseAuth.instance.currentUser;
    final childProfile = appState.childProfile;
    final childName = childProfile.name.isNotEmpty ? childProfile.name : 'Pasien Anak';
    final childAge = childProfile.age > 0 ? childProfile.age : 5;
    final childGender = childProfile.gender.isNotEmpty ? childProfile.gender : 'Laki-laki';
    final rmNumber = 'ZK-SBY-${(childName.hashCode.abs() % 900000 + 100000)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Kop Medis Resmi Klinik Zikola Surabaya
        _buildEmrClinicHeader(childName, childAge, childGender, rmNumber),
        const SizedBox(height: 20),

        // 2. Tugas Stimulasi & Materi Edukasi Dokter
        _buildDoctorHomeworkAndMaterialsSection(user?.uid),
        const SizedBox(height: 24),

        // 3. Daftar Resep & Paket Terapi Aktif
        _buildPrescriptionsSection(user?.uid),
        const SizedBox(height: 24),

        // 4. Rekam Medis (EMR) & Diagnosa Klinis Dokter
        _buildEmrDetailsSection(user?.uid),
        const SizedBox(height: 24),

        // 5. Bantuan Konsultasi & Layanan Klinik Surabaya
        _buildEmrContactActionCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmrClinicHeader(String childName, int age, String gender, String rmNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KLINIK TUMBUH KEMBANG ZIKOLA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pusat Layanan Terpadu Tumbuh Kembang Anak, Surabaya',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Layanan Resmi Zikola Care • Rekam Medis Elektronik (RME)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Patient Data Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildEmrDataCell('NO. REKAM MEDIS', rmNumber, isBold: true, isHighlight: true),
                    _buildEmrDataCell('TANGGAL CETAK', DateFormat('dd MMM yyyy').format(DateTime.now())),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildEmrDataCell('NAMA PASIEN ANAK', childName, isBold: true),
                    _buildEmrDataCell('USIA / GENDER', '$age Thn / $gender'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tervalidasi Resmi: Pasien Aktif Terdaftar di Zikola Care Center Surabaya',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildEmrDataCell(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isHighlight ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // ─── TUGAS STIMULASI & MATERI EDUKASI DOKTER ───────────────────────────────────
  Widget _buildDoctorHomeworkAndMaterialsSection(String? uid) {
    if (uid == null) {
      return _buildHomeworkEmptyCard();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('action_plans')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, planSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('materials')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, matSnap) {
            if (planSnap.connectionState == ConnectionState.waiting && matSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            final planDocs = planSnap.data?.docs ?? [];
            final matDocs = matSnap.data?.docs ?? [];
            final totalCount = planDocs.length + matDocs.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF0F766E), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tugas Stimulasi & Edukasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    if (totalCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalCount Item',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (totalCount == 0)
                  _buildHomeworkEmptyCard()
                else ...[
                  if (planDocs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Rencana Stimulasi Mandiri (Action Plan)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    ...planDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildActionPlanCard(uid, doc.id, data);
                    }),
                    const SizedBox(height: 8),
                  ],
                  if (matDocs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        'Materi & Panduan Klinis Terlampir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    ...matDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildMaterialCard(data);
                    }),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHomeworkEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCFBF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFCCFBF1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0D9488), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Panduan Stimulasi Standar Zikola',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF115E59),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Dokter spesialis belum memberikan tugas stimulasi khusus untuk sesi ini. Berikut panduan stimulasi harian dasar:',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF134E4A), height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF0D9488)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Screen-time maksimal 1 jam per hari dengan pendampingan aktif',
                        style: TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF0D9488)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aktivitas bercerita dan tanya jawab interaktif 15 menit sebelum tidur',
                        style: TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlanCard(String uid, String docId, Map<String, dynamic> data) {
    final target = data['target']?.toString() ?? 'Stimulasi Harian';
    final screenTime = data['screenTime']?.toString() ?? 'Maks. 1 Jam per Hari';
    final notes = data['notes']?.toString() ?? 'Ikuti stimulasi dengan konsisten di rumah.';
    final doctorName = data['doctorName']?.toString() ?? 'Dokter Spesialis';
    final completedToday = data['completedToday'] == true;
    final createdAt = data['createdAt'];

    String dateStr = '-';
    if (createdAt is String && createdAt.isNotEmpty) {
      try {
        final parsed = DateTime.parse(createdAt);
        dateStr = DateFormat('dd MMM yyyy').format(parsed);
      } catch (_) {
        dateStr = createdAt;
      }
    } else if (createdAt is Timestamp) {
      dateStr = DateFormat('dd MMM yyyy').format(createdAt.toDate());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completedToday ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: completedToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: completedToday ? const Color(0xFF10B981).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: completedToday ? const Color(0xFFF0FDF4) : const Color(0xFFF0FDFA),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      completedToday ? Icons.check_circle_rounded : Icons.flag_rounded,
                      size: 16,
                      color: completedToday ? const Color(0xFF16A34A) : const Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      target.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: completedToday ? const Color(0xFF15803D) : const Color(0xFF0F766E),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.screen_lock_portrait_rounded, size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Text(
                        'Batas Layar: $screenTime',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Doctor notes
                Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF334155),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Footer & Interactive Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dr: $doctorName',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                    InkWell(
                      onTap: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('action_plans')
                              .doc(docId)
                              .update({
                            'completedToday': !completedToday,
                            'lastCompletedAt': DateTime.now().toIso8601String(),
                          });
                        } catch (e) {
                          debugPrint('Error updating action plan checklist: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: completedToday ? const Color(0xFFDCFCE7) : const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              completedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 14,
                              color: completedToday ? const Color(0xFF16A34A) : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              completedToday ? 'Selesai Hari Ini' : 'Tandai Selesai',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: completedToday ? const Color(0xFF16A34A) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'Materi Edukasi';
    final desc = data['desc']?.toString() ?? 'Panduan stimulasi tumbuh kembang anak.';
    final icon = data['icon']?.toString() ?? '📚';
    final doctorName = data['doctorName']?.toString() ?? 'Dokter Spesialis';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Disusun oleh: $doctorName',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                    InkWell(
                      onTap: () {
                        _showMaterialDetailDialog(title, desc, icon, doctorName);
                      },
                      child: const Text(
                        'Baca Panduan →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMaterialDetailDialog(String title, String desc, String icon, String doctorName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Panduan Klinis Resmi • $doctorName',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                desc,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lightbulb_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Praktikkan secara konsisten 15-30 menit setiap hari bersama anak untuk hasil optimal.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsSection(String? uid) {
    if (uid == null) {
      return _buildPrescriptionsEmptyCard();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('prescriptions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication_rounded, color: Color(0xFF0284C7), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Resep & Terapi Aktif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                if (docs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${docs.length} Aktif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              _buildPrescriptionsEmptyCard()
            else
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildPrescriptionDetailCard(data);
              }),
          ],
        );
      },
    );
  }

  Widget _buildPrescriptionsEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_information_outlined, color: Color(0xFF94A3B8), size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum Ada Resep atau Terapi Baru',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Resep suplemen, obat medis, atau jadwal terapi yang diberikan oleh dokter saat konsultasi akan langsung muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionDetailCard(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'suplemen';
    final itemName = data['itemName']?.toString() ?? 'Resep Terapi';
    final dosage = data['dosage']?.toString() ?? '-';
    final duration = data['duration']?.toString() ?? '-';
    final notes = data['notes']?.toString() ?? '-';
    final doctorName = data['doctorName']?.toString() ?? 'Dokter Spesialis Anak';
    final createdAt = data['createdAt'];

    String dateStr = '-';
    if (createdAt is Timestamp) {
      dateStr = DateFormat('dd MMM yyyy').format(createdAt.toDate());
    }

    final isTerapi = type == 'terapi';
    final isMedis = type == 'medis';

    final badgeBg = isTerapi ? const Color(0xFFF3E8FF) : isMedis ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5);
    final badgeColor = isTerapi ? const Color(0xFF7E22CE) : isMedis ? const Color(0xFFB91C1C) : const Color(0xFF047857);
    final typeTitle = isTerapi ? 'PAKET TERAPI KLINIS' : isMedis ? 'RESEP OBAT MEDIS' : 'SUPLEMEN TUMBUH KEMBANG';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: badgeBg.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    typeTitle,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⏱️ DOSIS & ATURAN',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dosage,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 24, width: 1, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📅 DURASI',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              duration,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (notes.isNotEmpty && notes != '-') ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78350F),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Diresepkan oleh: $doctorName',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '✓ Terverifikasi',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmrDetailsSection(String? uid) {
    if (uid == null) {
      return _buildEmrDetailsEmptyCard();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('emr')
          .doc('latest')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (data == null || !snapshot.data!.exists) {
          return _buildEmrDetailsEmptyCard();
        }

        final diagnosis = data['diagnosis']?.toString() ?? '';
        final treatmentPlan = data['treatmentPlan']?.toString() ?? '';
        final birthCondition = data['birthCondition']?.toString() ?? 'Normal (Cukup Bulan)';
        final pregnancyNotes = data['pregnancyNotes']?.toString() ?? '';
        final allergies = data['allergies']?.toString() ?? '';
        final previousTherapy = data['previousTherapy']?.toString() ?? '';
        final updatedBy = data['updatedBy']?.toString() ?? 'Tim Dokter Spesialis Anak Zikola';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFFD97706), size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hasil Diagnosa & Rencana Terapi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card Diagnosa Dokter
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: Color(0xFF0284C7), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'DIAGNOSA KLINIS DOKTER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diagnosis.isNotEmpty ? diagnosis : 'Hasil observasi perkembangan anak berjalan baik sesuai tonggak usianya.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 6),

                  const Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: Color(0xFF7C3AED), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'RENCANA TINDAKAN & STIMULASI RUMAH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    treatmentPlan.isNotEmpty ? treatmentPlan : 'Lanjutkan stimulasi sensori motorik harian dan batasi paparan layar gawai sesuai anjuran aplikasi.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Riwayat Kelahiran & Medis
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Medis Pasien',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildEmrHistoryRow('Kondisi Lahir', birthCondition),
                  if (pregnancyNotes.isNotEmpty) _buildEmrHistoryRow('Catatan Kehamilan', pregnancyNotes),
                  _buildEmrHistoryRow('Riwayat Alergi', allergies.isNotEmpty ? allergies : 'Tidak ada riwayat alergi'),
                  if (previousTherapy.isNotEmpty) _buildEmrHistoryRow('Terapi Sebelumnya', previousTherapy),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tanda Tangan & Verifikasi Medis
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DIVERIFIKASI DOKTER SPESIALIS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          updatedBy,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        const Text(
                          'SIP/SBY/2024/0981 • Klinik Terpadu Tumbuh Kembang Zikola, Surabaya',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmrDetailsEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, color: Color(0xFF94A3B8), size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            'Rekam Medis Siap Disinkronkan',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Saat dokter spesialis mengisi lembar evaluasi atau rekam medis digital dari Portal Dokter, hasil diagnosa dan stimulasi akan otomatis tercatat permanen di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmrHistoryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmrContactActionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text(
                'Layanan Terpadu Klinik Zikola Surabaya',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Butuh penyesuaian resep atau konsultasi lanjutan? Tim dokter spesialis kami siap membantu memantau tumbuh kembang ananda.',
            style: TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/consultation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('Konsultasi dengan Dokter Spesialis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
