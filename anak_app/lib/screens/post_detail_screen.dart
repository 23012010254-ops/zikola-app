import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/community_post.dart';
import '../services/app_state.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../models/app_notification.dart';
import '../widgets/full_screen_image.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _commentController = TextEditingController();
  
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likes;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<AppState>().uid;
    _isLiked = uid != null && widget.post.likedBy.contains(uid);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} menit lalu';
    return 'Baru saja';
  }

  void _toggleLike() {
    final uid = context.read<AppState>().uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap login terlebih dahulu")));
      return;
    }
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    
    final appState = context.read<AppState>();
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'like',
      sourceId: uid,
      sourceName: appState.childProfile.name,
      sourceAvatar: appState.childProfile.avatar,
      sourceAvatarBase64: appState.childProfile.avatarBase64,
      targetId: widget.post.id,
      content: 'menyukai postingan Anda.',
      timestamp: DateTime.now(),
    );

    _firestore.toggleLikePost(widget.post.id, uid, !_isLiked, notification: notif, targetUid: widget.post.authorId); 
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final appState = context.read<AppState>();
    final uid = appState.uid;
    if (uid == null) return;

    final commentData = {
      'authorId': uid,
      'authorName': appState.childProfile.name,
      'authorAvatar': appState.childProfile.avatar,
      'authorAvatarBase64': appState.childProfile.avatarBase64,
      'content': text,
    };

    _commentController.clear();
    FocusScope.of(context).unfocus();

    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'comment',
      sourceId: uid,
      sourceName: appState.childProfile.name,
      sourceAvatar: appState.childProfile.avatar,
      sourceAvatarBase64: appState.childProfile.avatarBase64,
      targetId: widget.post.id,
      content: 'mengomentari: "$text"',
      timestamp: DateTime.now(),
    );

    await _firestore.addCommunityComment(widget.post.id, commentData, notification: notif, targetUid: widget.post.authorId);
  }

  Color _getCategoryBg(String category) {
    switch (category) {
      case 'Tips': return const Color(0xFFDBEAFE);
      case 'Pencapaian': return const Color(0xFFDCFCE7);
      case 'Tanya': return const Color(0xFFFFEDD5);
      case 'Review': return const Color(0xFFF3E8FF);
      default: return AppTheme.gray100;
    }
  }

  Color _getCategoryText(String category) {
    switch (category) {
      case 'Tips': return const Color(0xFF1D4ED8);
      case 'Pencapaian': return const Color(0xFF15803D);
      case 'Tanya': return const Color(0xFFC2410C);
      case 'Review': return const Color(0xFF7E22CE);
      default: return AppTheme.gray700;
    }
  }

  Widget _buildMainPost() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE), 
                  shape: BoxShape.circle,
                  image: widget.post.avatarBase64 != null
                    ? DecorationImage(image: MemoryImage(base64Decode(widget.post.avatarBase64!)), fit: BoxFit.cover)
                    : null
                ),
                child: widget.post.avatarBase64 == null
                  ? Center(child: Text(widget.post.avatar.length <= 2 ? widget.post.avatar : '👦', style: const TextStyle(fontSize: 24)))
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post.author, style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 16)),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: AppTheme.gray500, size: 12),
                        const SizedBox(width: 4),
                        Text(_formatTime(widget.post.time), style: AppTheme.bodyText.copyWith(color: AppTheme.gray500, fontSize: 12)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _getCategoryBg(widget.post.category), borderRadius: BorderRadius.circular(12)),
                          child: Text(widget.post.category, style: TextStyle(color: _getCategoryText(widget.post.category), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(widget.post.content, style: AppTheme.bodyText.copyWith(color: AppTheme.gray700, fontSize: 15, height: 1.5)),
          if (widget.post.postImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(
                        base64Image: widget.post.postImage,
                        tag: 'post_image_${widget.post.id}',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'post_image_${widget.post.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      base64Decode(widget.post.postImage!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : AppTheme.gray500,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text('$_likesCount', style: TextStyle(
                      color: _isLiked ? Colors.red : AppTheme.gray500,
                      fontSize: 14, fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppTheme.gray500, size: 20),
                  const SizedBox(width: 6),
                  Text('${widget.post.comments}', style: TextStyle(color: AppTheme.gray500, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text("Komentar", style: AppTheme.heading3.copyWith(color: AppTheme.gray900)),
        iconTheme: IconThemeData(color: AppTheme.gray900),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMainPost(),
                  
                  // Comments Section
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.getCommunityCommentsStream(widget.post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              "Belum ada komentar.\nJadilah yang pertama!", 
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyText.copyWith(color: AppTheme.gray500)
                            )
                          ),
                        );
                      }

                      final comments = snapshot.data!.docs;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: comments.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final author = data['authorName'] ?? 'Anonim';
                            final avatar = data['authorAvatar'] ?? '👦';
                            final avatarBase64 = data['authorAvatarBase64'];
                            final content = data['content'] ?? '';
                            final ts = data['timestamp'] as Timestamp?;
                            final time = ts != null ? ts.toDate() : DateTime.now();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: AppTheme.gray100, 
                                      shape: BoxShape.circle,
                                      image: avatarBase64 != null
                                        ? DecorationImage(image: MemoryImage(base64Decode(avatarBase64!)), fit: BoxFit.cover)
                                        : null
                                    ),
                                    child: avatarBase64 == null
                                      ? Center(child: Text(avatar.length <= 2 ? avatar : '👦', style: const TextStyle(fontSize: 16)))
                                      : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(author, style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 13)),
                                              Text(_formatTime(time), style: AppTheme.bodyText.copyWith(color: AppTheme.gray400, fontSize: 10)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(content, style: AppTheme.bodyText.copyWith(color: AppTheme.gray700, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
          
          // Comment Input
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              left: 16, right: 16, top: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.gray200)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Tulis komentar...",
                      hintStyle: TextStyle(color: AppTheme.gray400),
                      filled: true,
                      fillColor: AppTheme.gray100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
