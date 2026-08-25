import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // 'like', 'comment', 'follow', 'unfollow'
  final String sourceId;
  final String sourceName;
  final String sourceAvatar;
  final String? sourceAvatarBase64;
  final String? targetId; // Post ID or other target entity
  final String content;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.sourceName,
    required this.sourceAvatar,
    this.sourceAvatarBase64,
    this.targetId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      type: data['type'] ?? 'unknown',
      sourceId: data['sourceId'] ?? '',
      sourceName: data['sourceName'] ?? 'Seseorang',
      sourceAvatar: data['sourceAvatar'] ?? '👦',
      sourceAvatarBase64: data['sourceAvatarBase64'],
      targetId: data['targetId'],
      content: data['content'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'sourceId': sourceId,
      'sourceName': sourceName,
      'sourceAvatar': sourceAvatar,
      'sourceAvatarBase64': sourceAvatarBase64,
      'targetId': targetId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
