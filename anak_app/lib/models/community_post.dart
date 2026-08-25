import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String authorId;
  final String author;
  final String avatar;
  final String? avatarBase64;
  final String? postImage; // Added for community photos
  final DateTime time;
  final String content;
  final int likes;
  final int comments;
  final String category;
  final List<String> likedBy;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.avatar,
    this.avatarBase64,
    this.postImage,
    required this.time,
    required this.content,
    required this.likes,
    required this.comments,
    required this.category,
    required this.likedBy,
  });

  factory CommunityPost.fromFirestore(String id, Map<String, dynamic> data) {
    return CommunityPost(
      id: id,
      authorId: data['authorId'] ?? '',
      author: data['authorName'] ?? 'Anonim',
      avatar: data['authorAvatar'] ?? '👦',
      avatarBase64: data['authorAvatarBase64'],
      postImage: data['postImage'],
      time: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      content: data['content'] ?? '',
      likes: data['likesCount'] ?? 0,
      comments: data['commentsCount'] ?? 0,
      category: data['category'] ?? 'Review',
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }
}
