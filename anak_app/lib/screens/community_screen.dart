import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/community_post.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/full_screen_image.dart';
import 'post_detail_screen.dart';
import 'public_profile_screen.dart';
import '../models/app_notification.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _activeTab = 'recent';
  final FirestoreService _firestore = FirestoreService();
  final ImagePicker _picker = ImagePicker();
  String? _pickedImageBase64;

  final _tabs = [
    {'id': 'trending', 'label': 'Trending', 'icon': '🔥'},
    {'id': 'recent', 'label': 'Terbaru', 'icon': '⏰'},
    {'id': 'following', 'label': 'Mengikuti', 'icon': '👥'},
  ];

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) {
      if (difference.inDays == 1) return '1 hari lalu';
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  void _toggleLike(CommunityPost post, bool isLiked) {
    final appState = context.read<AppState>();
    final uid = appState.uid;
    if (uid != null) {
      final notif = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'like',
        sourceId: uid,
        sourceName: appState.childProfile.name,
        sourceAvatar: appState.childProfile.avatar,
        sourceAvatarBase64: appState.childProfile.avatarBase64,
        targetId: post.id,
        content: 'menyukai postingan Anda.',
        timestamp: DateTime.now(),
      );
      _firestore.toggleLikePost(post.id, uid, isLiked, notification: notif, targetUid: post.authorId);
    }
  }

  Color _getCategoryBg(String category) {
    switch (category) {
      case 'Tips': return const Color(0xFFDBEAFE); // blue-100
      case 'Pencapaian': return const Color(0xFFDCFCE7); // green-100
      case 'Tanya': return const Color(0xFFFFEDD5); // orange-100
      case 'Review': return const Color(0xFFF3E8FF); // purple-100
      default: return AppTheme.gray100;
    }
  }

  Color _getCategoryText(String category) {
    switch (category) {
      case 'Tips': return const Color(0xFF1D4ED8); // blue-700
      case 'Pencapaian': return const Color(0xFF15803D); // green-700
      case 'Tanya': return const Color(0xFFC2410C); // orange-700
      case 'Review': return const Color(0xFF7E22CE); // purple-700
      default: return AppTheme.gray700;
    }
  }

  void _showCreatePostModal() {
    final textController = TextEditingController();
    String selectedCategory = 'Tips';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Buat Postingan Baru", style: AppTheme.heading3.copyWith(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Tips', 'Pencapaian', 'Tanya', 'Review'].map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setStateModal(() => selectedCategory = cat);
                        },
                        selectedColor: _getCategoryBg(cat),
                        backgroundColor: AppTheme.gray100,
                        labelStyle: TextStyle(
                          color: isSelected ? _getCategoryText(cat) : AppTheme.gray600,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Apa yang ingin Anda bagikan?",
                      hintStyle: TextStyle(color: AppTheme.gray400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Image selection
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 50,
                          maxWidth: 800,
                          maxHeight: 800,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setStateModal(() {
                            _pickedImageBase64 = base64Encode(bytes);
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.gray200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.add_a_photo, color: AppTheme.gray600, size: 20),
                      label: Text(
                        _pickedImageBase64 != null ? "Ganti Foto" : "Tambahkan Foto",
                        style: TextStyle(color: AppTheme.gray700, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_pickedImageBase64 != null)
                    Stack(
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(base64Decode(_pickedImageBase64!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setStateModal(() => _pickedImageBase64 = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_pickedImageBase64 != null) const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (textController.text.trim().isEmpty) return;
                        final appState = context.read<AppState>();
                        final uid = appState.uid;
                        if (uid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap login terlebih dahulu")));
                          return;
                        }
                        
                        final postData = {
                          'authorId': uid,
                          'authorName': appState.childProfile.name,
                          'authorAvatar': appState.childProfile.avatar,
                          'authorAvatarBase64': appState.childProfile.avatarBase64,
                          'content': textController.text.trim(),
                          'category': selectedCategory,
                        };
                        
                        if (_pickedImageBase64 != null) {
                          postData['postImage'] = _pickedImageBase64!;
                        }

                        Navigator.pop(context); 
                        setState(() => _pickedImageBase64 = null); // Reset for next time

                        await _firestore.createCommunityPost(postData);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Posting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<AppState>().uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // gray-50
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Sticky emulation)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.arrow_back, color: AppTheme.gray700, size: 20),
                          ),
                        ),
                        Text('Komunitas', style: AppTheme.heading2.copyWith(color: AppTheme.gray900)),
                        GestureDetector(
                          onTap: _showCreatePostModal,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(12)), // blue-500
                            child: const Icon(Icons.add, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Tabs
                    Row(
                      children: _tabs.map((tab) {
                        bool isActive = _activeTab == tab['id'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = tab['id']!),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF3B82F6) : AppTheme.gray100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(tab['icon']!, style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(tab['label']!, style: TextStyle(
                                    color: isActive ? Colors.white : AppTheme.gray600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Connection Warning Banner
              if (context.watch<AppState>().initError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                  color: const Color(0xFFFEF3C7),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFD97706)),
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

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFFA855F7)]), // blue-500 to purple-500
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bergabung dengan Diskusi', style: AppTheme.heading3.copyWith(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Tanyakan, berbagi pengalaman, dan dapatkan tips dari sesama orang tua', style: AppTheme.bodyText.copyWith(color: const Color(0xFFEFF6FF), fontSize: 13)), // blue-50
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _showCreatePostModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2563EB), // blue-600
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Buat Postingan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cari Topik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Posts List from Firestore
              !context.watch<AppState>().isInitialized
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                    )
                  : StreamBuilder<QuerySnapshot>(
                stream: _firestore.getCommunityPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint('Firestore Error (Community): ${snapshot.error}');
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 40),
                            const SizedBox(height: 16),
                            Text("Gagal memuat postingan", style: AppTheme.heading3),
                            const SizedBox(height: 8),
                            Text("${snapshot.error}", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.gray500, fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                              child: const Text("Coba Lagi", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                    );
                  }
                  
                  // Handling potential null data to avoid build errors
                  if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          "Belum ada postingan komunitas.\nJadilah yang pertama memposting!", 
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyText.copyWith(color: AppTheme.gray500)
                        )
                      ),
                    );
                  }

                  List<CommunityPost> posts = snapshot.data!.docs
                      .map((doc) => CommunityPost.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
                      .toList();

                  // Optional tab filtering
                  final currentProfile = context.watch<AppState>().childProfile;
                  if (_activeTab == 'trending') {
                    posts.sort((a, b) => b.likes.compareTo(a.likes));
                  } else if (_activeTab == 'following') {
                    // Following logic: show posts from users in the 'following' list + current user
                    posts = posts.where((p) => currentProfile.following.contains(p.authorId) || p.authorId == currentUid).toList();
                    if (posts.isEmpty) {
                       return const Padding(
                         padding: EdgeInsets.all(40),
                         child: Center(child: Text("Anda belum mengikuti siapa pun atau belum ada postingan.", textAlign: TextAlign.center)),
                       );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: posts.map((post) {
                        final isLiked = currentUid != null && post.likedBy.contains(currentUid);
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(post: post),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(targetUid: post.authorId)));
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDBEAFE), 
                                        shape: BoxShape.circle,
                                        image: post.avatarBase64 != null
                                          ? DecorationImage(image: MemoryImage(base64Decode(post.avatarBase64!)), fit: BoxFit.cover)
                                          : null
                                      ),
                                      child: post.avatarBase64 == null
                                        ? Center(child: Text(post.avatar.length <= 2 ? post.avatar : '👦', style: const TextStyle(fontSize: 20)))
                                        : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(post.author, style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 14)),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, color: AppTheme.gray500, size: 12),
                                            const SizedBox(width: 4),
                                            Text(_formatTime(post.time), style: AppTheme.bodyText.copyWith(color: AppTheme.gray500, fontSize: 12)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(color: _getCategoryBg(post.category), borderRadius: BorderRadius.circular(12)),
                                              child: Text(post.category, style: TextStyle(color: _getCategoryText(post.category), fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(post.content, style: AppTheme.bodyText.copyWith(color: AppTheme.gray700, fontSize: 13, height: 1.5)),
                            if (post.postImage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenImageViewer(
                                            base64Image: post.postImage,
                                            tag: 'post_image_${post.id}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: Hero(
                                      tag: 'post_image_${post.id}',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          base64Decode(post.postImage!),
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: Color(0xFFF3F4F6)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (currentUid == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap login terlebih dahulu")));
                                        return;
                                      }
                                      _toggleLike(post, isLiked);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? Colors.red : AppTheme.gray500,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${post.likes}', style: TextStyle(
                                          color: isLiked ? Colors.red : AppTheme.gray500,
                                          fontSize: 12, fontWeight: FontWeight.bold,
                                        )),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, color: AppTheme.gray500, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${post.comments}', style: TextStyle(color: AppTheme.gray500, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Spacer(),
                                if (currentUid == post.authorId)
                                  GestureDetector(
                                    onTap: () => _confirmDeletePost(post.id),
                                    child: Icon(Icons.delete_outline, color: AppTheme.red500.withOpacity(0.7), size: 18),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  void _confirmDeletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _firestore.deleteCommunityPost(postId);
            }, 
            child: const Text('Hapus', style: TextStyle(color: AppTheme.red500))
          ),
        ],
      ),
    );
  }
}
