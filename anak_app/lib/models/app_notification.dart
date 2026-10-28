import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // 'like', 'comment', 'follow', 'unfollow', 'prescription', 'action_plan', 'appointment', 'notes', 'material', 'clinic'
  final String sourceId;
  final String sourceName;
  final String sourceAvatar;
  final String? sourceAvatarBase64;
  final String? targetId; // Post ID or target screen ('emr', 'consultation', 'chat_xxx')
  final String? title;
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
    this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  bool get isClinicNotification =>
      type == 'prescription' ||
      type == 'action_plan' ||
      type == 'appointment' ||
      type == 'notes' ||
      type == 'material' ||
      type == 'clinic';

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parsedTime = DateTime.now();
    if (data['timestamp'] != null) {
      final ts = data['timestamp'];
      if (ts is Timestamp) {
        parsedTime = ts.toDate();
      } else if (ts is String) {
        try {
          parsedTime = DateTime.parse(ts);
        } catch (_) {}
      }
    } else if (data['createdAt'] != null) {
      final ca = data['createdAt'];
      if (ca is Timestamp) {
        parsedTime = ca.toDate();
      } else if (ca is String) {
        try {
          parsedTime = DateTime.parse(ca);
        } catch (_) {}
      }
    }

    return AppNotification(
      id: id,
      type: data['type'] ?? 'unknown',
      sourceId: data['sourceId'] ?? '',
      sourceName: data['sourceName'] ?? 'Klinik Zikola',
      sourceAvatar: data['sourceAvatar'] ?? '🏥',
      sourceAvatarBase64: data['sourceAvatarBase64'],
      targetId: data['targetId']?.toString(),
      title: data['title']?.toString(),
      content: data['content']?.toString() ?? data['message']?.toString() ?? '',
      timestamp: parsedTime,
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
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
