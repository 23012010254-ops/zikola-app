import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_state.dart';
import '../services/chat_notification_service.dart';

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    final name = doc['name'] ?? 'Dokter';
    final specialty = doc['specialty'] ?? '';
    final hospital = doc['hospital'] ?? '';
    final rating = (doc['rating'] ?? 0).toDouble();
    final reviews = doc['reviews'] ?? 0;
    final price = doc['price'] ?? 0;
    final image = doc['image'] ?? '👩‍⚕️';
    final experience = doc['experience'] ?? 0;
    final licenseNumber = doc['licenseNumber'] ?? '-';
    final practiceLocation = doc['practiceLocation'] ?? '-';
    final education = doc['education'] ?? '-';
    final bio = doc['bio'] ?? '';
    final schedule = doc['schedule'] ?? '-';
    final available = doc['available'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF9333EA),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFA855F7), Color(0xFF9333EA), Color(0xFF7C3AED)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _buildAvatar(image, size: 48),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Rating + Hospital badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '$rating ($reviews ulasan)',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_hospital_rounded, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(hospital, style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      _buildStatCard(Icons.work_history_rounded, '$experience Tahun', 'Pengalaman', const Color(0xFF3B82F6)),
                      const SizedBox(width: 12),
                      _buildStatCard(Icons.verified_rounded, 'Terverifikasi', 'Lisensi', const Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      _buildStatCard(Icons.schedule_rounded, '30 Menit', 'Per Sesi', const Color(0xFFF59E0B)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionTitle('Tentang Dokter'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(),
                    child: Text(
                      bio.isNotEmpty ? bio : 'Belum ada bio.',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detail Info Cards
                  _buildSectionTitle('Informasi Detail'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.badge_outlined, 'Nomor Izin Praktik', licenseNumber, const Color(0xFF6366F1)),
                        const Divider(height: 1, indent: 56),
                        _buildInfoRow(Icons.location_on_outlined, 'Lokasi Praktik', practiceLocation, const Color(0xFFEF4444)),
                        const Divider(height: 1, indent: 56),
                        _buildInfoRow(Icons.school_outlined, 'Pendidikan', education, const Color(0xFF0EA5E9)),
                        const Divider(height: 1, indent: 56),
                        _buildInfoRow(Icons.calendar_today_outlined, 'Jadwal Praktik', schedule, const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Availability Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: available ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: available ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: available ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            available ? 'Tersedia untuk konsultasi saat ini' : 'Sedang tidak tersedia untuk konsultasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: available ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            ),
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

      // ── Bottom CTA ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status Section (Payment Removed for Store Approval)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sesi Telekonsultasi', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text(
                    'Layanan Gratis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            // CTA Button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: available ? const Color(0xFF9333EA) : const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    elevation: available ? 4 : 0,
                    shadowColor: const Color(0xFF9333EA).withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: available
                      ? () async {
                          final appState = Provider.of<AppState>(context, listen: false);
                          final userId = appState.uid ?? 'guest';
                          final chatId = 'chat_${userId}_${doc['id']}';

                          if (doc['id'] == 'doctor_bot') {
                            Navigator.pushNamed(context, '/chat', arguments: doc);
                            return;
                          }

                          // Auto-create chat session if needed without payment barrier
                          final docRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
                          final docSnap = await docRef.get();
                          if (!docSnap.exists) {
                            await docRef.set({
                              'doctorId': doc['id'],
                              'buyerId': userId,
                              'doctorName': doc['name'] ?? 'Dokter Zikola',
                              'doctorImage': doc['image'] ?? '',
                              'specialty': doc['specialty'] ?? '',
                              'createdAt': FieldValue.serverTimestamp(),
                              'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 30))),
                              'status': 'active',
                            }, SetOptions(merge: true));
                          }

                          if (!context.mounted) return;
                          Navigator.pushNamed(context, '/chat', arguments: doc);
                        }
                      : null,
                  child: Text(
                    available ? 'Mulai Konsultasi' : 'Tidak Tersedia',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildAvatar(String imageStr, {double size = 40}) {
    if (imageStr.startsWith('base64:')) {
      try {
        final bytes = base64Decode(imageStr.substring(7));
        return ClipRRect(
          borderRadius: BorderRadius.circular(50), 
          child: Image.memory(
            bytes,
            width: size * 2,
            height: size * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text('👨‍⚕️', style: TextStyle(fontSize: size)),
          ),
        );
      } catch (e) {
        return Text('👨‍⚕️', style: TextStyle(fontSize: size));
      }
    } else if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.network(
          imageStr,
          width: size * 2,
          height: size * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text('👨‍⚕️', style: TextStyle(fontSize: size)),
        ),
      );
    }
    return Text(imageStr, style: TextStyle(fontSize: size));
  }
}
