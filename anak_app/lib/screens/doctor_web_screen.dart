import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/patient.dart';
import '../models/doctor_schedule.dart';
import '../models/clinical_note.dart';
import '../theme/app_theme.dart';

class DoctorWebScreen extends StatefulWidget {
  const DoctorWebScreen({super.key});

  @override
  State<DoctorWebScreen> createState() => _DoctorWebScreenState();
}

class _DoctorWebScreenState extends State<DoctorWebScreen> {
  // Navigation & filtering states
  String _activeTab = 'patients'; // 'patients' or 'schedules'
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive, new
  String _scheduleFilter = 'all'; // all, upcoming, completed
  Patient? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (!appState.isDoctor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portal Dokter')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Akses ditolak. Portal ini hanya untuk dokter yang sudah diverifikasi admin Zikola.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(appState),
      body: Column(
        children: [
          // Segmented Tab Switcher (Pasien vs Jadwal)
          _buildTopTabSwitcher(),

          // Body Content depending on active tab
          Expanded(
            child: _activeTab == 'patients'
                ? _buildPatientsBody(appState)
                : _buildSchedulesBody(appState),
          ),
        ],
      ),
      floatingActionButton: _activeTab == 'schedules'
          ? FloatingActionButton.extended(
              onPressed: () => _openAddScheduleModal(appState),
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Jadwal Baru', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ─── Top Tab Switcher (Stage 2) ───────────────────────────
  Widget _buildTopTabSwitcher() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              id: 'patients',
              icon: Icons.people_alt_rounded,
              label: 'Daftar Pasien',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              id: 'schedules',
              icon: Icons.calendar_month_rounded,
              label: 'Jadwal Konsultasi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String id,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _activeTab == id;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = id;
          _selectedPatient = null;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppState appState) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF7C3AED),
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_hospital_rounded, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Portal Dokter Zikola',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              Text(
                'Kelola pasien, jadwal & rekam medis',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Badge(
            label: Text('3', style: TextStyle(fontSize: 9)),
            child: Icon(Icons.notifications_outlined),
          ),
          tooltip: 'Notifikasi Dokter',
          onPressed: () => _openDoctorNotificationsModal(appState),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Muat Ulang Data',
          onPressed: () => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openDoctorProfileModal(),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Text(
                '👩‍⚕️',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Tab 1: Pasien Body ───────────────────────────────────
  Widget _buildPatientsBody(AppState appState) {
    return FutureBuilder<List<Patient>>(
      future: appState.getDoctorPatients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryPurple),
                SizedBox(height: 16),
                Text('Memuat data pasien...', style: TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final patients = snapshot.data ?? [];
        final filtered = _applyPatientFilters(patients);

        if (_selectedPatient != null) {
          return _buildPatientDetail(_selectedPatient!, appState);
        }

        return Column(
          children: [
            _buildStatsBar(patients),
            _buildSearchFilterBar(),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildPatientCard(filtered[index], appState);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsBar(List<Patient> patients) {
    final active = patients.where((p) => p.status == 'active').length;
    final newPatients = patients.where((p) => p.status == 'new').length;
    final total = patients.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('👥', '$total', 'Total Pasien'),
          _buildStatDivider(),
          _buildStatItem('✅', '$active', 'Aktif'),
          _buildStatDivider(),
          _buildStatItem('🆕', '$newPatients', 'Baru'),
          _buildStatDivider(),
          _buildStatItem('📅', '3', 'Sesi Aktif'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Cari pasien...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF64748B)),
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Semua')),
                  DropdownMenuItem(value: 'active', child: Text('Aktif')),
                  DropdownMenuItem(value: 'inactive', child: Text('Tidak Aktif')),
                  DropdownMenuItem(value: 'new', child: Text('Baru')),
                ],
                onChanged: (v) => setState(() => _filterStatus = v ?? 'all'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _openAddPatientModal(Provider.of<AppState>(context, listen: false)),
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
              tooltip: 'Daftarkan Pasien Baru',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient, AppState appState) {
    final statusColor = switch (patient.status) {
      'active' => const Color(0xFF22C55E),
      'new' => const Color(0xFF3B82F6),
      'inactive' => const Color(0xFF94A3B8),
      _ => const Color(0xFF94A3B8),
    };
    final statusLabel = switch (patient.status) {
      'active' => 'Aktif',
      'new' => 'Baru',
      'inactive' => 'Tidak Aktif',
      _ => patient.status,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _selectedPatient = patient),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(patient.avatar, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${patient.gender} • ${patient.age} tahun${patient.parentName != null ? ' • Ortu: ${patient.parentName}' : ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      if (patient.lastVisit != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Kunjungan terakhir: ${patient.lastVisit}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ],
                  ),
                ),
                // Interactive quick actions (Chat & Video Call)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickAction(
                      Icons.chat_bubble_outline_rounded,
                      const Color(0xFF3B82F6),
                      () => _openChatWithPatient(patient),
                    ),
                    const SizedBox(width: 6),
                    _buildQuickAction(
                      Icons.videocam_outlined,
                      const Color(0xFF22C55E),
                      () => _openVideoCallWithPatient(patient),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ─── Patient Detail View (Stage 2 with EMR / Clinical Notes) ──
  Widget _buildPatientDetail(Patient patient, AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _selectedPatient = null),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Kembali ke Daftar Pasien'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),

          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(patient.avatar, style: const TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${patient.gender} • ${patient.age} tahun',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                      ),
                      if (patient.parentName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Orang tua: ${patient.parentName}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildDetailAction(
                      Icons.videocam_rounded,
                      'Video Call',
                      const Color(0xFF22C55E),
                      () => _openVideoCallWithPatient(patient),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailAction(
                      Icons.chat_rounded,
                      'Chat',
                      const Color(0xFF3B82F6),
                      () => _openChatWithPatient(patient),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Info Cards
          Row(
            children: [
              _buildInfoCard('📋', 'Status', patient.status == 'active' ? 'Aktif' : patient.status == 'new' ? 'Baru' : 'Tidak Aktif', const Color(0xFF22C55E)),
              const SizedBox(width: 12),
              _buildInfoCard('📅', 'Kunjungan Terakhir', patient.lastVisit ?? '-', const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _buildInfoCard('🧠', 'Tes Selesai', '${patient.latestAssessment?['completedTests'] ?? 0}', const Color(0xFFF59E0B)),
            ],
          ),

          const SizedBox(height: 20),

          // Recent Activities (Dynamic from Cloud & Assessments)
          _buildSectionHeader('Aktivitas Terkini (Asesmen & Stimulasi)', onSeeAll: null),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: appState.getPatientActivities(patient.id),
            builder: (context, actSnapshot) {
              final activities = actSnapshot.data ?? [];
              if (activities.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Belum ada riwayat asesmen terbaru.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                );
              }
              return Column(
                children: activities.map((act) {
                  return _buildActivityCard(
                    act['emoji'] ?? '🧩',
                    act['title'] ?? 'Tes Perkembangan',
                    act['score'] ?? 'Selesai',
                    act['time'] ?? 'Tersimpan',
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Catatan Klinis Dokter (Stage 2 Dynamic EMR)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catatan Klinis Dokter (EMR)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openAddPrescriptionModal(patient, appState),
                    icon: const Icon(Icons.medication_rounded, size: 16),
                    label: const Text('E-Resep', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAddClinicalNoteModal(patient, appState),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Tambah Catatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<ClinicalNote>>(
            future: appState.getPatientClinicalNotes(patient.id),
            builder: (context, snapshot) {
              final notes = snapshot.data ?? [];
              if (notes.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Text('📝', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text(
                        'Belum ada catatan klinis untuk pasien ini.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Dokumentasikan observasi & rekomendasi stimulasi untuk panduan orang tua.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => _openAddClinicalNoteModal(patient, appState),
                        icon: const Icon(Icons.note_add_outlined, size: 16),
                        label: const Text('Tulis Evaluasi Pertama'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: notes.map((note) => _buildClinicalNoteCard(note)).toList(),
              );
            },
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildClinicalNoteCard(ClinicalNote note) {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note.category,
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (note.isActionPlan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Action Plan Rapor',
                        style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Observasi Klinis:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 2),
          Text(
            note.observation,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.4),
          ),
          if (note.recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Rekomendasi Stimulasi:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
            ),
            const SizedBox(height: 2),
            Text(
              note.recommendation,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
            ),
          ],
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Oleh: ${note.doctorName}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
              ),
              Text(
                dateFormat.format(note.createdAt),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: Jadwal Konsultasi Body (Stage 2) ──────────────
  Widget _buildSchedulesBody(AppState appState) {
    return FutureBuilder<List<DoctorSchedule>>(
      future: appState.getDoctorSchedules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryPurple),
                SizedBox(height: 16),
                Text('Memuat jadwal konsultasi...', style: TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          );
        }

        final schedules = snapshot.data ?? [];
        final filteredSchedules = _applyScheduleFilters(schedules);

        return Column(
          children: [
            // Filter Bar (Semua, Mendatang, Selesai)
            _buildScheduleFilterBar(schedules),

            Expanded(
              child: filteredSchedules.isEmpty
                  ? _buildEmptySchedulesState(appState)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: filteredSchedules.length,
                      itemBuilder: (context, index) {
                        return _buildScheduleCard(filteredSchedules[index], appState);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScheduleFilterBar(List<DoctorSchedule> schedules) {
    final upcomingCount = schedules.where((s) => s.isUpcoming).length;
    final completedCount = schedules.where((s) => s.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildFilterChip('all', 'Semua (${schedules.length})'),
          const SizedBox(width: 8),
          _buildFilterChip('upcoming', 'Mendatang ($upcomingCount)'),
          const SizedBox(width: 8),
          _buildFilterChip('completed', 'Selesai ($completedCount)'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _scheduleFilter == id;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selectedColor: const Color(0xFF7C3AED),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
      onSelected: (_) => setState(() => _scheduleFilter = id),
    );
  }

  Widget _buildScheduleCard(DoctorSchedule schedule, AppState appState) {
    final dateFormat = DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID');
    final isVideo = schedule.sessionType == 'video';
    final statusColor = schedule.isUpcoming
        ? const Color(0xFFF59E0B)
        : schedule.isCompleted
            ? const Color(0xFF10B981)
            : const Color(0xFF94A3B8);

    final statusText = schedule.isUpcoming
        ? 'Mendatang'
        : schedule.isCompleted
            ? 'Selesai'
            : schedule.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(schedule.patientAvatar, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.patientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isVideo ? Icons.videocam_rounded : Icons.chat_rounded,
                            size: 14,
                            color: isVideo ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isVideo ? 'Sesi Video Call' : 'Sesi Chat Konsultasi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isVideo ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Topic & Time
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(schedule.dateTime),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.topic_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    schedule.topic,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
            if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      schedule.notes!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            // Actions
            Row(
              children: [
                if (schedule.isUpcoming) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final mockPatient = Patient(
                          id: schedule.patientId,
                          name: schedule.patientName,
                          avatar: schedule.patientAvatar,
                        );
                        if (isVideo) {
                          _openVideoCallWithPatient(mockPatient);
                        } else {
                          _openChatWithPatient(mockPatient);
                        }
                      },
                      icon: Icon(isVideo ? Icons.videocam_rounded : Icons.chat_rounded, size: 16),
                      label: Text(isVideo ? 'Masuk Video Call' : 'Mulai Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isVideo ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await appState.updateScheduleStatus(schedule.id, 'completed');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sesi konsultasi ditandai selesai ✅')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    child: const Text('Selesai', style: TextStyle(fontSize: 12)),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final mockPatient = Patient(
                          id: schedule.patientId,
                          name: schedule.patientName,
                          avatar: schedule.patientAvatar,
                        );
                        _openChatWithPatient(mockPatient);
                      },
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('Lihat Riwayat Chat'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySchedulesState(AppState appState) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Jadwal Sesi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Jadwalkan sesi konsultasi chat atau video call dengan pasien.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openAddScheduleModal(appState),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Jadwal Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Modal Dialog: Buat Jadwal Baru (Stage 2) ─────────────
  Future<void> _openAddScheduleModal(AppState appState) async {
    final patients = await appState.getDoctorPatients();
    if (!mounted) return;

    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada pasien terdaftar untuk dijadwalkan.')),
      );
      return;
    }

    Patient selectedPatient = patients.first;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String sessionType = 'video';
    final topicController = TextEditingController(text: 'Evaluasi Perkembangan Anak');
    final notesController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Buat Jadwal Konsultasi',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Pilih Pasien
                    const Text('Pilih Pasien', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Patient>(
                          isExpanded: true,
                          value: selectedPatient,
                          items: patients.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text('${p.avatar} ${p.name} (${p.age} thn)'),
                            );
                          }).toList(),
                          onChanged: (p) {
                            if (p != null) setModalState(() => selectedPatient = p);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Jenis Sesi (Chat / Video)
                    const Text('Tipe Sesi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => sessionType = 'video'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sessionType == 'video' ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                                border: Border.all(color: sessionType == 'video' ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam_rounded, size: 18, color: Color(0xFF16A34A)),
                                  SizedBox(width: 6),
                                  Text('Video Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => sessionType = 'chat'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sessionType == 'chat' ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFC),
                                border: Border.all(color: sessionType == 'chat' ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_rounded, size: 18, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text('Chat Konsultasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tanggal & Waktu
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 90)),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(DateFormat('d MMM yyyy').format(selectedDate)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedTime = picked);
                                  }
                                },
                                icon: const Icon(Icons.access_time, size: 16),
                                label: Text(selectedTime.format(ctx)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Topik
                    const Text('Topik Konsultasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: topicController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Catatan Tambahan
                    const Text('Catatan Tambahan (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Persiapan atau arahan sebelum sesi dimulai...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final combinedDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          final newSchedule = DoctorSchedule(
                            id: 'sched-${DateTime.now().millisecondsSinceEpoch}',
                            patientId: selectedPatient.id,
                            patientName: selectedPatient.name,
                            patientAvatar: selectedPatient.avatar,
                            dateTime: combinedDateTime,
                            sessionType: sessionType,
                            topic: topicController.text.trim().isNotEmpty
                                ? topicController.text.trim()
                                : 'Konsultasi Rutin',
                            notes: notesController.text.trim().isNotEmpty
                                ? notesController.text.trim()
                                : null,
                          );

                          await appState.addDoctorSchedule(newSchedule);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Jadwal konsultasi untuk ${selectedPatient.name} berhasil dibuat! 📅'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan & Terbitkan Jadwal', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Modal Dialog: Terbitkan E-Resep & Rekomendasi Terapi ─
  Future<void> _openAddPrescriptionModal(Patient patient, AppState appState) async {
    String selectedCategory = 'Nutrisi Otak & Perkembangan';
    final itemController = TextEditingController();
    final dosageController = TextEditingController();
    final instructionsController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.medication_liquid_rounded, color: Color(0xFF059669), size: 22),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Buat E-Resep & Terapi',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'Pasien: ${patient.name}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text('Kategori Terapi / Suplemen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'Nutrisi Otak & Perkembangan', child: Text('Nutrisi Otak & Perkembangan')),
                              DropdownMenuItem(value: 'Stimulasi Sensori & Motorik', child: Text('Stimulasi Sensori & Motorik')),
                              DropdownMenuItem(value: 'Vitamin & Daya Tahan Tubuh', child: Text('Vitamin & Daya Tahan Tubuh')),
                              DropdownMenuItem(value: 'Panduan Terapi Perilaku & Tidur', child: Text('Panduan Terapi Perilaku & Tidur')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedCategory = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Nama Item / Suplemen / Alat Terapi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: itemController,
                        decoration: InputDecoration(
                          hintText: 'Cth: Minyak Ikan DHA Anak / Playdough Sensori...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Dosis / Frekuensi Latihan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: dosageController,
                        decoration: InputDecoration(
                          hintText: 'Cth: 1x sehari 5ml sesudah sarapan / 20 menit per sesi...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Instruksi Khusus & Catatan Dokter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: instructionsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Panduan orang tua dalam pendampingan di rumah...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (itemController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Harap masukkan nama item atau terapi.')),
                              );
                              return;
                            }

                            await appState.dispatchDigitalPrescription(
                              patient.id,
                              category: selectedCategory,
                              itemName: itemController.text.trim(),
                              dosage: dosageController.text.trim().isEmpty
                                  ? 'Sesuai anjuran dokter'
                                  : dosageController.text.trim(),
                              instructions: instructionsController.text.trim().isEmpty
                                  ? 'Lakukan secara konsisten setiap hari.'
                                  : instructionsController.text.trim(),
                            );

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('E-Resep untuk ${patient.name} berhasil terbit & tersinkronisasi! 💊'),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Terbitkan & Kirim E-Resep', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Modal Dialog: Tambah Catatan Klinis / EMR (Stage 2) ──
  Future<void> _openAddClinicalNoteModal(Patient patient, AppState appState) async {
    String selectedCategory = 'Sensori & Motorik';
    final observationController = TextEditingController();
    final recommendationController = TextEditingController();
    bool isActionPlan = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Catatan Klinis: ${patient.name}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    const Text('Kategori Asesmen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          items: const [
                            DropdownMenuItem(value: 'Sensori & Motorik', child: Text('Sensori & Motorik')),
                            DropdownMenuItem(value: 'Wicara & Bahasa', child: Text('Wicara & Bahasa')),
                            DropdownMenuItem(value: 'Kognitif & Perilaku', child: Text('Kognitif & Perilaku')),
                            DropdownMenuItem(value: 'Nutrisi & Pertumbuhan', child: Text('Nutrisi & Pertumbuhan')),
                            DropdownMenuItem(value: 'Umum', child: Text('Umum')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => selectedCategory = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Hasil Observasi Klinis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: observationController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Temuan perkembangan, respon stimulasi, atau observasi dokter...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Rekomendasi & Rencana Tindak Lanjut', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: recommendationController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Latihan mandiri di rumah, frekuensi stimulasi, panduan screen time...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Checkbox Action Plan
                    CheckboxListTile(
                      value: isActionPlan,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF7C3AED),
                      title: const Text(
                        'Kirim sebagai Action Plan Resmi ke Rapor Anak',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      subtitle: const Text(
                        'Rekomendasi ini akan langsung tampil di dashboard progres orang tua.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      onChanged: (v) => setModalState(() => isActionPlan = v ?? true),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (observationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Harap masukkan hasil observasi klinis.')),
                            );
                            return;
                          }

                          final newNote = ClinicalNote(
                            id: 'note-${DateTime.now().millisecondsSinceEpoch}',
                            patientId: patient.id,
                            patientName: patient.name,
                            doctorName: 'Dr. Spesialis Anak Zikola',
                            category: selectedCategory,
                            observation: observationController.text.trim(),
                            recommendation: recommendationController.text.trim(),
                            isActionPlan: isActionPlan,
                          );

                          await appState.addClinicalNote(newNote);
                          if (isActionPlan) {
                            await appState.dispatchDoctorActionPlan(patient.id, newNote);
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isActionPlan
                                  ? 'Catatan klinis & Action Plan untuk ${patient.name} terkirim ke rapor anak! 📋'
                                  : 'Catatan klinis untuk ${patient.name} tersimpan! 📝'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Catatan Klinis', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Helpers: Navigation to Chat & Video Call ─────────────
  void _openChatWithPatient(Patient patient) {
    final chatArgs = {
      'id': 'doctor_zikola',
      'name': patient.name,
      'doctorId': 'doctor_zikola',
      'doctorName': 'Dr. Sarah Amelia, Sp.A',
      'doctorAvatar': '👩‍⚕️',
      'specialty': 'Spesialis Tumbuh Kembang',
      'chatId': 'chat_doctor_${patient.id}',
      'patientName': patient.name,
      'isDoctorView': true,
    };
    Navigator.pushNamed(context, '/chat', arguments: chatArgs);
  }

  void _openVideoCallWithPatient(Patient patient) {
    final chatArgs = {
      'id': 'doctor_zikola',
      'name': patient.name,
      'doctorId': 'doctor_zikola',
      'doctorName': 'Dr. Sarah Amelia, Sp.A',
      'doctorAvatar': '👩‍⚕️',
      'specialty': 'Spesialis Tumbuh Kembang',
      'chatId': 'chat_doctor_${patient.id}',
      'patientName': patient.name,
      'isDoctorView': true,
      'autoStartCall': true,
    };
    Navigator.pushNamed(context, '/chat', arguments: chatArgs);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membuka sesi video call terenkripsi untuk ${patient.name} 📹'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  // ─── Modal Dialog: Notifikasi Dokter ──────────────────────
  Future<void> _openDoctorNotificationsModal(AppState appState) async {
    final notifications = await appState.getDoctorNotifications();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: Color(0xFF7C3AED), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Pemberitahuan Klinis',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              ...notifications.map((notif) {
                final isUnread = notif['isUnread'] as bool? ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnread ? const Color(0xFFF3E8FF).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isUnread ? const Color(0xFFE9D5FF) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (notif['color'] as Color? ?? const Color(0xFF7C3AED)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          notif['icon'] as IconData? ?? Icons.notifications,
                          color: notif['color'] as Color? ?? const Color(0xFF7C3AED),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notif['title'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notif['desc'] ?? '',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        notif['time'] ?? '',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ─── Modal Dialog: Profil Dokter ──────────────────────────
  void _openDoctorProfileModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('👩‍⚕️', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Dr. Sarah Amelia, Sp.A',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              const Text(
                'Spesialis Anak & Tumbuh Kembang',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildProfileRow('No. STR', 'STR-3171-8892-KEMKES'),
                    const Divider(height: 16),
                    _buildProfileRow('No. SIP', '503/SIP.DS/042/DPMPTSP/2024'),
                    const Divider(height: 16),
                    _buildProfileRow('Rumah Sakit', 'Klinik Tumbuh Kembang Zikola Surabaya'),
                    const Divider(height: 16),
                    _buildProfileRow('Status', 'Praktik Aktif Online 🟢'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Tutup Profil', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }

  // ─── Modal Dialog: Tambah Pasien Baru ─────────────────────
  Future<void> _openAddPatientModal(AppState appState) async {
    final nameController = TextEditingController();
    final parentController = TextEditingController();
    int age = 5;
    String gender = 'Laki-laki';
    String avatar = '👦';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftarkan Pasien Baru',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Nama Anak
                    const Text('Nama Lengkap Anak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Misal: Keenan Alfarezel',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Usia & Gender
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Usia (Tahun)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: age,
                                    items: [2, 3, 4, 5, 6, 7, 8, 9, 10].map((a) {
                                      return DropdownMenuItem(value: a, child: Text('$a Tahun'));
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) setModalState(() => age = v);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jenis Kelamin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: gender,
                                    items: const [
                                      DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki 👦')),
                                      DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan 👧')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setModalState(() {
                                          gender = v;
                                          avatar = v == 'Laki-laki' ? '👦' : '👧';
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Nama Orang Tua / Wali
                    const Text('Nama Orang Tua / Wali', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: parentController,
                      decoration: InputDecoration(
                        hintText: 'Misal: Ibu Maya / Bapak Rizky',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Harap masukkan nama anak.')),
                            );
                            return;
                          }

                          final newPatient = Patient(
                            id: 'user-pat-${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            age: age,
                            gender: gender,
                            avatar: avatar,
                            parentName: parentController.text.trim().isNotEmpty
                                ? parentController.text.trim()
                                : 'Orang Tua',
                            lastVisit: 'Baru Terdaftar',
                            status: 'new',
                            latestAssessment: {
                              'cognitive': 0,
                              'linguistic': 0,
                              'motor': 0,
                              'completedTests': 0,
                            },
                          );

                          await appState.addNewPatient(newPatient);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pasien $name berhasil didaftarkan ke daftar pantau! 👶'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Daftarkan Pasien', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Common UI Components ─────────────────────────────────
  Widget _buildDetailAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String emoji, String title, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accentColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Lihat Semua', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
          ),
      ],
    );
  }

  Widget _buildActivityCard(String emoji, String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👨‍⚕️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Pasien',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pasien yang terdaftar akan muncul di sini.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openAddPatientModal(Provider.of<AppState>(context, listen: false)),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('Daftarkan Pasien Baru', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  List<Patient> _applyPatientFilters(List<Patient> patients) {
    var result = patients;
    if (_filterStatus != 'all') {
      result = result.where((p) => p.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.parentName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  List<DoctorSchedule> _applyScheduleFilters(List<DoctorSchedule> schedules) {
    if (_scheduleFilter == 'upcoming') {
      return schedules.where((s) => s.isUpcoming).toList();
    }
    if (_scheduleFilter == 'completed') {
      return schedules.where((s) => s.isCompleted).toList();
    }
    return schedules;
  }
}
