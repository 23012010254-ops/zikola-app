import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import '../models/app_notification.dart';
import '../theme/app_theme.dart';
import 'public_profile_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Mark notifications as read when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.uid != null) {
        _firestore.markAllNotificationsRead(appState.uid!);
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }

  Future<void> _confirmDeleteReadNotifications(String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content: const Text('Anda yakin ingin menghapus semua notifikasi yang sudah terbaca? Tindakan ini tidak dapat dibatalkan.'),
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

    if (confirmed == true && mounted) {
      await _firestore.deleteReadNotifications(uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi terbaca telah dihapus')),
        );
      }
    }
  }

  Widget _buildEmptyState(String emoji, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 50))),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppTheme.heading3.copyWith(color: const Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTheme.bodyText.copyWith(color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildActivityTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.getNotificationsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final notifs = snapshot.data?.docs ?? [];
        if (notifs.isEmpty) {
          return _buildEmptyState('🔔', 'Belum ada notifikasi', 'Likes, komentar, dan aktivitas baru akan muncul di sini.');
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          itemCount: notifs.length,
          itemBuilder: (context, index) {
            final doc = notifs[index];
            final notif = AppNotification.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);

            return GestureDetector(
              onTap: () async {
                if (!notif.isRead) {
                  await _firestore.markNotificationAsRead(uid, notif.id);
                }
                if (notif.type == 'follow' || notif.type == 'unfollow') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(targetUid: notif.sourceId)));
                }
                // Jika punya post detail page kita bisa redirect kesana
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: notif.isRead ? Colors.white : const Color(0xFFEFF6FF), // Blue tint for unread
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: notif.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFBFDBFE)),
                  boxShadow: notif.isRead ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))] : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                        image: notif.sourceAvatarBase64 != null
                          ? DecorationImage(image: MemoryImage(base64Decode(notif.sourceAvatarBase64!)), fit: BoxFit.cover)
                          : null
                      ),
                      child: notif.sourceAvatarBase64 == null
                        ? Center(child: Text(notif.sourceAvatar.length <= 2 ? notif.sourceAvatar : '👦', style: const TextStyle(fontSize: 20)))
                        : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: AppTheme.bodyText.copyWith(color: AppTheme.gray900),
                              children: [
                                TextSpan(text: notif.sourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: ' ${notif.content}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_formatTime(notif.timestamp), style: const TextStyle(fontSize: 11, color: AppTheme.gray500, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (!notif.isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: AppTheme.blue600, shape: BoxShape.circle),
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

  Widget _buildChatTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('chats').where('buyerId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final chatDocs = snapshot.data?.docs ?? [];
        if (chatDocs.isEmpty) {
          return _buildEmptyState('💬', 'Tidak ada konsultasi', 'Pesan dari dokter akan muncul di sini.');
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            final chatData = chatDocs[index].data() as Map<String, dynamic>;
            final chatId = chatDocs[index].id;
            final doctorName = chatData['doctorName'] ?? 'Dokter Spesialis';

            return FutureBuilder<QuerySnapshot>(
              future: _db.collection('chats').doc(chatId).collection('messages').orderBy('timestamp', descending: true).limit(1).get(),
              builder: (context, msgSnapshot) {
                String lastMessage = 'Klik untuk melanjutkan konsultasi';
                String timeText = '';

                if (msgSnapshot.hasData && msgSnapshot.data!.docs.isNotEmpty) {
                  final lastMsgData = msgSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                  lastMessage = lastMsgData['text'] ?? '';
                  if (lastMsgData['timestamp'] != null) {
                    final ts = lastMsgData['timestamp'];
                    if (ts is Timestamp) {
                      timeText = _formatTime(ts.toDate());
                    } else if (ts is String) {
                      try {
                        timeText = _formatTime(DateTime.parse(ts).toLocal());
                      } catch (_) {}
                    }
                  }
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/chat', arguments: {
                      'id': chatData['doctorId'], 
                      'name': doctorName,
                      'image': chatData['doctorImage'] ?? '👨‍⚕️'
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF), 
                            borderRadius: BorderRadius.circular(14),
                            image: (chatData['doctorImage'] != null && chatData['doctorImage'].toString().startsWith('base64:'))
                                ? DecorationImage(
                                    image: MemoryImage(base64Decode(chatData['doctorImage'].toString().substring(7))),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (chatData['doctorImage'] == null || !chatData['doctorImage'].toString().startsWith('base64:'))
                              ? const Center(child: Text('👨‍⚕️', style: TextStyle(fontSize: 24)))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(doctorName, style: AppTheme.heading3.copyWith(fontSize: 15, color: const Color(0xFF1E293B))),
                                  if (timeText.isNotEmpty)
                                    Text(timeText, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(lastMessage, style: AppTheme.bodyText.copyWith(fontSize: 13, color: const Color(0xFF64748B), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.uid;
    final isInitialized = appState.isInitialized;

    if (!isInitialized) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.blue600)),
      );
    }

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text('Harap login untuk melihat notifikasi')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Notifikasi', style: AppTheme.heading2.copyWith(fontSize: 20, color: const Color(0xFF1E293B))),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () => _confirmDeleteReadNotifications(uid),
              child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                _firestore.markAllNotificationsRead(uid);
                _firestore.markAllChatsAsRead(uid);
              },
              child: const Text('Baca Semua', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.blue600,
            labelColor: AppTheme.blue600,
            unselectedLabelColor: AppTheme.gray500,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Aktivitas"),
                    if (appState.unreadActivityCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: Text(appState.unreadActivityCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Konsultasi"),
                    if (appState.unreadChatsCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: Text(appState.unreadChatsCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActivityTab(uid),
            _buildChatTab(uid),
          ],
        ),
      ),
    );
  }
}
