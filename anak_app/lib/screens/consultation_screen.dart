import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/chat_notification_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_bottom_nav.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  
  Widget _buildAvatar(String imageStr, {double size = 48}) {
    if (imageStr.startsWith('base64:')) {
      try {
        final bytes = base64Decode(imageStr.substring(7));
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.3),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Text('👨‍⚕️', style: TextStyle(fontSize: size * 0.6)),
          ),
        );
      } catch (e) {
        return Text('👨‍⚕️', style: TextStyle(fontSize: size * 0.6));
      }
    } else if (imageStr.startsWith('http://') || imageStr.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: Image.network(
          imageStr,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text('👨‍⚕️', style: TextStyle(fontSize: size * 0.6)),
        ),
      );
    }
    return Text(imageStr, style: TextStyle(fontSize: size * 0.6));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Sliver Header in Royal Blue & Indigo
          SliverAppBar(
            expandedHeight: 230,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: CircleAvatar(
                        radius: 90,
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: CircleAvatar(
                        radius: 110,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    // Anchored to the bottom so the text never runs past the header.
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('✨', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text(
                                  'Konsultasi Ahli & Dokter Zikola',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tanya Ahli\nSekarang 🩺',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.3,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Dampingi tumbuh kembang optimal bersama pakar berlisensi.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                ),
              ),
            ),
          ),

          // Content Area
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sesi & Janji Temu Saya (Real-time Hub)
                  _buildMyConsultationHub(context, FirebaseAuth.instance.currentUser?.uid),

                  const Text(
                    'Pilihan Layanan Konsultasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Chat Dokter Anak
                  _buildModernOption(
                    context,
                    title: 'Chat Dokter Anak',
                    desc: 'Mulai chat privat dengan dokter spesialis anak berlisensi STR.',
                    emoji: '🩺',
                    tag: 'Spesialis Anak',
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    route: '/doctor-list',
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),

                  // 2. Konsultasi Asisten AI
                  _buildModernOption(
                    context,
                    title: 'Konsultasi Asisten AI',
                    desc: 'Tanya jawab instan 24/7 tentang stimulasi sensorik & motorik.',
                    emoji: '🤖',
                    tag: 'Instan Bebas Biaya',
                    iconBg: const Color(0xFFECFEFF),
                    iconColor: const Color(0xFF0284C7),
                    route: 'doctor_bot',
                  ),
                  const SizedBox(height: 12),

                  // 3. Panduan Parenting
                  _buildModernOption(
                    context,
                    title: 'Panduan Praktis Parenting',
                    desc: 'Solusi tantrum, aturan makan, dan jadwal stimulasi anak.',
                    emoji: '📚',
                    tag: 'Protokol IDAI',
                    iconBg: const Color(0xFFFAF5FF),
                    iconColor: const Color(0xFF9333EA),
                    route: '/parent-guide',
                  ),
                  const SizedBox(height: 12),

                  // 4. Portal Dokter Zikola (verified doctors only)
                  if (context.watch<AppState>().isDoctor)
                    _buildModernOption(
                      context,
                      title: 'Portal Dokter Zikola',
                      desc: 'Khusus tenaga medis: Kelola pasien, pantau asesmen & EMR.',
                      emoji: '🏥',
                      tag: 'Khusus Medis',
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      route: '/doctor-portal',
                    ),

                  const SizedBox(height: 28),

                  // TOP EXPERTS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top Dokter & Psikolog Siaga',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/doctor-list'),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  
                  // DYNAMIC EXPERT LIST FROM FIRESTORE
                  SizedBox(
                    height: 180,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('doctors').orderBy('rating', descending: true).limit(5).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        // Hide doctors still waiting for admin verification.
                        final docs = snapshot.data!.docs
                            .where((d) => (d.data() as Map<String, dynamic>)['verified'] != false)
                            .toList();
                        if (docs.isEmpty) return const Center(child: Text('Belum ada ahli tersedia.'));

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return _buildExpertCard(context, docs[index].id, data);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),
                  
                  // Trust Section
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jaminan Keamanan & Privasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTrustItem(Icons.verified_user_rounded, 'Ahli Medis Berlisensi', 'Tervalidasi STR & SIPP resmi kemenkes.'),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _buildTrustItem(Icons.lock_rounded, 'Privasi Terenkripsi', 'Sesi konsultasi privat dan data rekam medis aman.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildModernOption(
    BuildContext context, {
    required String title,
    required String desc,
    required String emoji,
    required String tag,
    required Color iconBg,
    required Color iconColor,
    required String route,
    bool isPrimary = false,
  }) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ChatNotificationService().activeChatInfo,
      builder: (context, activeChat, _) {
        bool hasActiveChat = activeChat != null && isPrimary;

        return GestureDetector(
          onTap: () {
            if (route == 'doctor_bot') {
              final doc = {
                'id': 'doctor_bot',
                'name': 'Asisten AI ZIKOLA 🤖',
                'specialty': 'Asisten Kecerdasan Buatan',
                'image': '🤖',
                'available': true,
                'experience': 5,
                'rating': 5.0,
                'price': 0,
                'hospital': 'Cloud AI Server',
                'practiceLocation': 'Aplikasi ZIKOLA',
                'education': 'Model Bahasa Besar (LLM)',
                'bio': 'Saya adalah asisten pintar berbasis kecerdasan buatan (AI) yang siap membantu Bunda & Ayah dalam memberikan tips tumbuh kembang, stimulasi sensorik-motorik, dan pola asuh anak secara instan 24/7.',
                'schedule': 'Setiap Hari, 24 Jam Nonstop',
                'licenseNumber': 'AI-ASSISTANT-001',
              };
              Navigator.pushNamed(context, '/chat', arguments: doc);
            } else {
              Navigator.pushNamed(context, hasActiveChat ? '/chat' : route, arguments: hasActiveChat ? activeChat : null);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              fontFamily: 'Nunito',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          fontFamily: 'Nunito',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasActiveChat)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_chat_unread_rounded, color: Colors.white, size: 16),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpertCard(BuildContext context, String docId, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/doctor-detail', arguments: {
          'id': docId,
          ...data,
        });
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                _buildAvatar(data['image'] ?? data['photoUrl'] ?? '👨‍⚕️', size: 54),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data['name'] ?? 'Ahli Medis',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Color(0xFF0F172A),
                fontFamily: 'Nunito',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              data['role'] ?? 'Spesialis Anak',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                  const SizedBox(width: 3),
                  Text(
                    (data['rating'] ?? 5.0).toString(),
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String title, String desc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontFamily: 'Nunito',
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── REAL-TIME SESSIONS & APPOINTMENTS HUB ──────────────────────────────────
  Widget _buildMyConsultationHub(BuildContext context, String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('buyerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, chatSnap) {
        final chatDocs = chatSnap.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('patientId', isEqualTo: userId)
              .snapshots(),
          builder: (context, apptSnap) {
            final apptDocs = apptSnap.data?.docs ?? [];

            if (chatDocs.isEmpty && apptDocs.isEmpty) {
              return const SizedBox.shrink();
            }

            final activeChats = chatDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'active').toList();
            final completedChats = chatDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'completed').toList();
            final upcomingAppts = apptDocs.where((d) {
              final s = (d.data() as Map<String, dynamic>)['status'];
              return s != 'completed' && s != 'cancelled';
            }).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.event_note_rounded, color: Color(0xFF9333EA), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Sesi & Janji Temu Saya',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      if (activeChats.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(
                                '${activeChats.length} Aktif',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 1. Sesi Aktif
                  ...activeChats.map((doc) => _buildActiveChatCard(context, doc)),

                  // 2. Janji Temu Mendatang
                  ...upcomingAppts.map((doc) => _buildAppointmentCard(context, doc)),

                  // 3. Riwayat Selesai
                  if (completedChats.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(color: Color(0xFFF1F5F9)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Riwayat Konsultasi Selesai',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        Text(
                          '${completedChats.length} Sesi',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...completedChats.map((doc) => _buildCompletedChatCard(context, doc)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveChatCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final doctorName = data['doctorName'] ?? 'Dokter Spesialis Anak';
    final doctorImage = data['doctorImage'] ?? '👨‍⚕️';
    final specialty = data['specialty'] ?? 'Spesialis Tumbuh Kembang';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          _buildAvatar(doctorImage, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('SESI BERLANGSUNG', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 4),
                Text(
                  doctorName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  specialty,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/chat', arguments: {
                'id': data['doctorId'] ?? '',
                'name': doctorName,
                'image': doctorImage,
                'specialty': specialty,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final doctorName = data['doctorName'] ?? 'Dokter Zikola';
    final dateTimeStr = data['dateTime']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'scheduled';

    String formattedDate = dateTimeStr;
    try {
      if (dateTimeStr.contains('T')) {
        final dt = DateTime.parse(dateTimeStr);
        formattedDate = '${DateFormat('dd MMM yyyy, HH:mm').format(dt)} WIB';
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status == 'confirmed' ? 'TERKONFIRMASI' : 'JANJI TEMU DOKTER',
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctorName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  '🗓️ $formattedDate',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedChatCard(BuildContext context, QueryDocumentSnapshot doc) {
    final chatId = doc.id;
    final data = doc.data() as Map<String, dynamic>;
    final doctorName = data['doctorName'] ?? 'Dokter Spesialis Anak';
    final doctorImage = data['doctorImage'] ?? '👨‍⚕️';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _buildAvatar(doctorImage, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Sesi Selesai',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/progress', arguments: {'tab': 'emr'}),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.medical_services_outlined, size: 13, color: Color(0xFF0284C7)),
            label: const Text('EMR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _confirmDeleteChatSession(context, chatId, doctorName),
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Hapus Riwayat',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteChatSession(BuildContext context, String chatId, String doctorName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat Konsultasi?'),
        content: Text('Apakah Anda yakin ingin menghapus riwayat sesi dengan $doctorName? Seluruh pesan akan dihapus dari server.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final firestoreService = FirestoreService();
        await firestoreService.deleteChatSession(chatId);
        ChatNotificationService().clearActiveChat();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Riwayat konsultasi berhasil dihapus.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus riwayat: $e')),
          );
        }
      }
    }
  }

}
