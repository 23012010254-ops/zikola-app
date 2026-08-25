import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_notification_service.dart';
import '../theme/app_theme.dart';
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
        slivers: [
          // Elegant Sliver Header
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF9333EA),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // violet-500 to violet-700
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20, right: -20,
                      child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
                    ),
                    Positioned(
                      bottom: -40, left: -40,
                      child: CircleAvatar(radius: 120, backgroundColor: Colors.white.withOpacity(0.03)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: const Text('✨ Konsultasi Terpercaya', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),
                          Text('Tanya Ahli\nSekarang', style: AppTheme.heading1.copyWith(color: Colors.white, fontSize: 32, height: 1.1)),
                          const SizedBox(height: 8),
                          Text('Solusi tumbuh kembang dalam satu genggaman.', 
                            style: AppTheme.bodyText.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 13)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                ),
              ),
            ),
          ),

          // Content Area
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Options Card
                  _buildModernOption(
                    context,
                    'Chat Dokter Anak',
                    'Mulai chat privat dengan dokter spesialis anak berlisensi.',
                    '👨‍⚕️',
                    [const Color(0xFF8C52FF), const Color(0xFF5E17EB)], // purple/violet
                    '/doctor-list',
                    isPrimary: true,
                  ),
                  const SizedBox(height: 16),
                  _buildModernOption(
                    context,
                    'Konsultasi Asisten AI',
                    'Tanya jawab instan tentang tumbuh kembang anak dengan AI Pintar.',
                    '🤖',
                    [const Color(0xFF06B6D4), const Color(0xFF0891B2)], // cyan-500 to cyan-600
                    'doctor_bot',
                  ),
                  const SizedBox(height: 16),
                  _buildModernOption(
                    context,
                    'Panduan Parenting',
                    'Pelajari tips perkembangan & pola asuh dari pakar.',
                    '📖',
                    [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                    '/parent-guide',
                  ),

                  const SizedBox(height: 32),

                  // TOP EXPERTS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Top Ahli Minggu Ini', style: AppTheme.heading2.copyWith(fontSize: 18)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/doctor-list'),
                        child: Text('Lihat Semua', style: TextStyle(color: AppTheme.blue600, fontWeight: FontWeight.bold, fontSize: 12))
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // DYNAMIC EXPERT LIST FROM FIRESTORE
                  SizedBox(
                    height: 170,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('doctors').orderBy('rating', descending: true).limit(5).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) return const Center(child: Text('Belum ada ahli tersedia.'));

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            return _buildExpertCard(context, docs[index].id, data);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // Trust Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.gray100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Layanan Terpercaya', style: AppTheme.heading3.copyWith(fontSize: 16)),
                        const SizedBox(height: 16),
                        _buildTrustItem(Icons.verified_user, 'Ahli Berlisensi', 'Tervalidasi SIPP/STR.'),
                        const Divider(height: 24),
                        _buildTrustItem(Icons.lock, 'Privasi Aman', 'Chat dienkripsi penuh.'),
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

  Widget _buildModernOption(BuildContext context, String title, String desc, String emoji, List<Color> colors, String route, {bool isPrimary = false}) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: ChatNotificationService().activeChatInfo,
      builder: (context, activeChat, _) {
        bool hasActiveChat = activeChat != null && isPrimary;

        return GestureDetector(
          onTap: () {
            if (route == 'doctor_bot') {
              final doc = {
                'id': 'doctor_bot',
                'name': 'Asisten AI ANAK 🤖',
                'specialty': 'Asisten Kecerdasan Buatan',
                'image': '🤖',
                'available': true,
                'experience': 5,
                'rating': 5.0,
                'price': 0,
                'hospital': 'Cloud AI Server',
                'practiceLocation': 'Aplikasi ANAK',
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
                if (hasActiveChat)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.mark_chat_unread, color: Color(0xFF5E17EB), size: 16),
                  )
                else
                  Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
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
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.gray100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatar(data['image'] ?? data['photoUrl'] ?? '👨‍⚕️', size: 52),
            const SizedBox(height: 12),
            Text(data['name'] ?? 'Ahli', 
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.gray900),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(data['role'] ?? 'Spesialis', 
              style: TextStyle(color: AppTheme.gray500, fontSize: 10, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                  const SizedBox(width: 4),
                  Text((data['rating'] ?? 0.0).toString(), style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
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
          decoration: BoxDecoration(color: AppTheme.gray50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF6D28D9), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppTheme.gray900, fontSize: 14)),
              Text(desc, style: TextStyle(color: AppTheme.gray500, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
