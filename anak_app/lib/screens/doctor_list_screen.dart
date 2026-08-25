import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/chat_notification_service.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _firestoreService.seedDummyDoctors();
  }

  Widget _buildAvatar(String imageStr, {double size = 48}) {
    if (imageStr.startsWith('base64:')) {
      try {
        final bytes = base64Decode(imageStr.substring(7));
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
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
    final isInitialized = context.watch<AppState>().isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pilih Tenaga Ahli', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Column(
        children: [
          if (context.watch<AppState>().initError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFFFEF3C7), // Amber 100
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Koneksi tidak stabil. Menampilkan data terakhir...',
                      style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: !isInitialized
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF9333EA)))
                : StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getDoctorsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Firestore Error (Doctors): ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('Gagal memuat data dokter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA)),
                      onPressed: () => setState(() {}), 
                      child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF9333EA)));
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Tidak ada dokter yang tersedia.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docSnapshot = docs[index];
              final doc = docSnapshot.data() as Map<String, dynamic>;
              doc['id'] = docSnapshot.id;
              
              final bool isAvailable = doc['available'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      final appState = Provider.of<AppState>(context, listen: false);
                      final userId = appState.uid ?? 'guest';
                      final chatId = 'chat_${userId}_${doc['id']}';
                      
                      final hasActive = await ChatNotificationService.hasActiveSession(chatId);
                      if (!context.mounted) return;
                      
                      if (hasActive) {
                        Navigator.pushNamed(context, '/chat', arguments: doc);
                      } else {
                        Navigator.pushNamed(context, '/doctor-detail', arguments: doc);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar with Online Badge
                              Stack(
                                children: [
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: _buildAvatar(doc['image'] ?? '👨‍⚕️', size: 72),
                                  ),
                                  if (isAvailable)
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        width: 18, height: 18,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text(doc['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)))),
                                        const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(doc['specialty'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFFFEF9C3), borderRadius: BorderRadius.circular(10)),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Color(0xFFCA8A04), size: 16),
                                              const SizedBox(width: 4),
                                              Text('${doc['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCA8A04))),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('${doc['experience'] ?? 0} thn exp', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Biaya Konsultasi', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                  const SizedBox(height: 2),
                                  Text('Rp ${AppState.formatCurrency(doc['price'])}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final appState = Provider.of<AppState>(context, listen: false);
                                  final userId = appState.uid ?? 'guest';
                                  final chatId = 'chat_${userId}_${doc['id']}';
                                  
                                  final hasActive = await ChatNotificationService.hasActiveSession(chatId);
                                  if (!context.mounted) return;
                                  
                                  if (hasActive) {
                                    Navigator.pushNamed(context, '/chat', arguments: doc);
                                  } else {
                                    Navigator.pushNamed(context, '/doctor-detail', arguments: doc);
                                  }
                                },
                                child: const Text('Chat Sekarang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  ],
),
    );
  }
}
