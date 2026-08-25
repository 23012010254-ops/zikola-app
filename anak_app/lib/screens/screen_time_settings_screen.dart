import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class ScreenTimeSettingsScreen extends StatefulWidget {
  const ScreenTimeSettingsScreen({super.key});

  @override
  State<ScreenTimeSettingsScreen> createState() => _ScreenTimeSettingsScreenState();
}

class _ScreenTimeSettingsScreenState extends State<ScreenTimeSettingsScreen>
    with SingleTickerProviderStateMixin {
  static const List<Map<String, dynamic>> _limitOptions = [
    {'label': '30 menit', 'minutes': 30, 'icon': Icons.timer_outlined},
    {'label': '1 jam', 'minutes': 60, 'icon': Icons.schedule_rounded},
    {'label': '2 jam', 'minutes': 120, 'icon': Icons.hourglass_bottom_rounded},
    {
      'label': 'Tidak terbatas',
      'minutes': -1,
      'icon': Icons.all_inclusive_rounded,
    },
  ];

  late int _selectedLimitMinutes;
  late int _usedMinutesToday;
  bool _bedtimeEnabled = true;
  TimeOfDay _bedtimeStart = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _bedtimeEnd = const TimeOfDay(hour: 6, minute: 0);

  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _selectedLimitMinutes = appState.screenTimeLimit == 0 ? -1 : appState.screenTimeLimit;
    _usedMinutesToday = appState.todayPlayTime;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _updateProgressAnimation();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateProgressAnimation() {
    final target = _selectedLimitMinutes > 0
        ? (_usedMinutesToday / _selectedLimitMinutes).clamp(0.0, 1.0)
        : 0.0;
    _progressAnimation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  void _selectLimit(int minutes) {
    setState(() {
      _selectedLimitMinutes = minutes;
      _updateProgressAnimation();
      _animController
        ..reset()
        ..forward();
    });
  }

  void _instantLockApp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: Colors.orange),
            SizedBox(width: 10),
            Text('Kunci Aplikasi Sekarang?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Layar anak akan segera dialihkan ke mode istirahat dengan pesan ramah agar anak berhenti bermain dan bersiap makan/tidur.',
          style: TextStyle(fontSize: 13, color: AppTheme.gray600, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.gray500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppState>().lockScreenTime();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Kunci Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    final appState = context.read<AppState>();
    final int saveLimit = _selectedLimitMinutes == -1 ? 0 : _selectedLimitMinutes;
    appState.setScreenTimeLimit(saveLimit);

    final label = _limitOptions.firstWhere(
      (o) => o['minutes'] == _selectedLimitMinutes,
    )['label'];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pengaturan disimpan: $label ${_bedtimeEnabled ? '(Waktu Tenang Aktif)' : ''} ✅',
          style: const TextStyle(fontFamily: 'Nunito'),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) return AppTheme.primaryGreen;
    if (progress < 0.8) return AppTheme.primaryOrange;
    return AppTheme.red500;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Waktu Layar',
          style: AppTheme.heading2.copyWith(
            fontSize: 18,
            color: AppTheme.gray900,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instant Lock Shortcut
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.lock_clock, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kunci Aplikasi Sekarang',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Minta anak istirahat tanpa mengubah batas harian.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFC2410C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: _instantLockApp,
                    child: const Text('Kunci', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Circular progress card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Waktu Bermain Hari Ini',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final progress = _progressAnimation.value;
                      return SizedBox(
                        width: 170,
                        height: 170,
                        child: CustomPaint(
                          painter: _CircularProgressPainter(
                            progress: progress,
                            backgroundColor: AppTheme.gray100,
                            progressColor: _getProgressColor(progress),
                            strokeWidth: 14,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_usedMinutesToday',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: _getProgressColor(progress),
                                  ),
                                ),
                                const Text(
                                  'menit',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.gray50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedLimitMinutes > 0
                          ? '$_usedMinutesToday dari $_selectedLimitMinutes menit digunakan'
                          : 'Tidak ada batas waktu bermain',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Limit options header
            const Text(
              'Batas Durasi Bermain Harian',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.gray800,
              ),
            ),
            const SizedBox(height: 14),

            // Selectable limit cards
            ...List.generate(_limitOptions.length, (index) {
              final option = _limitOptions[index];
              final isSelected = option['minutes'] == _selectedLimitMinutes;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildLimitCard(
                  label: option['label'] as String,
                  icon: option['icon'] as IconData,
                  isSelected: isSelected,
                  onTap: () => _selectLimit(option['minutes'] as int),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Bedtime Mode Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.nightlight_round, color: Color(0xFF6366F1), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadwal Waktu Tenang (Bedtime)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.gray900),
                              ),
                              Text(
                                'Kunci otomatis saat jam tidur malam',
                                style: TextStyle(fontSize: 11, color: AppTheme.gray500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _bedtimeEnabled,
                        activeThumbColor: const Color(0xFF6366F1),
                        onChanged: (v) => setState(() => _bedtimeEnabled = v),
                      ),
                    ],
                  ),
                  if (_bedtimeEnabled) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeChip('Mulai Tidur', _bedtimeStart.format(context), () async {
                          final t = await showTimePicker(context: context, initialTime: _bedtimeStart);
                          if (t != null) setState(() => _bedtimeStart = t);
                        }),
                        const Icon(Icons.arrow_forward, color: AppTheme.gray400, size: 16),
                        _buildTimeChip('Bangun Pagi', _bedtimeEnd.format(context), () async {
                          final t = await showTimePicker(context: context, initialTime: _bedtimeEnd);
                          if (t != null) setState(() => _bedtimeEnd = t);
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Simpan Pengaturan',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, String timeStr, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.gray500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(timeStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlueLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                    : AppTheme.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.gray400,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.gray700,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.gray300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      progressColor != oldDelegate.progressColor;
}
