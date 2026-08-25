import 'notification_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';

/// Helper to safely parse any timestamp type (Firestore Timestamp, ISO String, int ms)
DateTime? _safeParseDateTimeGlobal(dynamic val) {
  if (val == null) return null;
  if (val is Timestamp) return val.toDate();
  if (val is String) {
    try { return DateTime.parse(val); } catch (_) { return null; }
  }
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return null;
}

/// A global service that monitors incoming chat messages from doctors
/// and shows overlay notifications regardless of the current screen.
class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final Map<String, StreamSubscription> _chatSubscriptions = {};
  final Map<String, int> _lastKnownMessageCount = {};
  final Map<String, int> _unreadCountByChat = {};
  StreamSubscription? _globalChatsSubscription;
  
  final ValueNotifier<int> unreadChatsCount = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, dynamic>?> activeChatInfo = ValueNotifier<Map<String, dynamic>?>(null);

  static String? currentViewedChatId;

  /// Global key to show SnackBars from anywhere in the app
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void _updateTotalUnreadCount() {
    int total = 0;
    for (var count in _unreadCountByChat.values) {
      total += count;
    }
    if (unreadChatsCount.value != total) {
      unreadChatsCount.value = total;
    }
  }

  /// Start listening to all chats for a specific user
  void startGlobalListening(String uid) {
    if (_globalChatsSubscription != null) return;

    _globalChatsSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('buyerId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final chatId = doc.id;
        final data = doc.data();
        
        // Auto-delete expired chats from Firestore (with 1-minute grace period)
        if (data.containsKey('expiresAt')) {
          final expiresAt = _safeParseDateTimeGlobal(data['expiresAt']);
          if (expiresAt != null) {
            // The session is truly dead only 1 minute after the formal expiration
            final trueExpiry = expiresAt.add(const Duration(minutes: 1));
            
            if (trueExpiry.isBefore(DateTime.now())) {
              // Clean up both locally and on server
              deleteChatSession(chatId); 
              if (activeChatInfo.value != null && activeChatInfo.value!['chatId'] == chatId) {
                activeChatInfo.value = null;
              }
              continue;
            }
          }
        }

        // We found an active chat! Let's get doctor info if not already set
        // Skip doctor_bot — it's a permanent AI session and should NOT
        // override the "Chat Dokter Anak" button as an active chat.
        if (activeChatInfo.value == null || activeChatInfo.value!['chatId'] != chatId) {
          final doctorId = data['doctorId'];
          if (doctorId != null && doctorId != 'doctor_bot') {
            FirestoreService().getDoctorById(doctorId).then((docData) {
              if (docData != null) {
                activeChatInfo.value = {
                  ...docData,
                  'chatId': chatId,
                };
              }
            });
          }
        }

        // Setup message listener for this chat if not already listening
        if (!_chatSubscriptions.containsKey(chatId)) {
          _lastKnownMessageCount[chatId] = -1;
          
          _chatSubscriptions[chatId] = FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .orderBy('timestamp')
              .snapshots()
              .listen((msgSnapshot) {
            final messages = msgSnapshot.docs;
            
            // Calculate unread count
            int unreadForThisChat = 0;
            for (var m in messages) {
               final msgData = m.data();
               final isRead = msgData['isRead'] as bool? ?? false;
               if (msgData['senderType'] == 'doctor' && !isRead) {
                 unreadForThisChat++;
               }
            }
            _unreadCountByChat[chatId] = unreadForThisChat;
            _updateTotalUnreadCount();
            
            if (_lastKnownMessageCount[chatId]! >= 0 && messages.length > _lastKnownMessageCount[chatId]!) {
              final lastMsg = messages.last.data();
              if (lastMsg['senderType'] == 'doctor' && currentViewedChatId != chatId) {
                // Determine doctor name and image from chat data
                final doctorName = data['doctorName'] ?? 'Dokter Zikola';
                final doctorImage = data['doctorImage'] as String?;
                final text = lastMsg['text'] ?? 'Pesan baru dari dokter';
                
                // 1. Show System Tray Push / Heads-up Notification
                NotificationService().showChatNotification(
                  doctorName: doctorName,
                  message: text,
                  chatId: chatId,
                );

                // 2. Show In-App Floating SnackBar
                _showGlobalNotification(
                  doctorName: doctorName,
                  doctorImage: doctorImage,
                  message: text,
                );
              }
            }
            _lastKnownMessageCount[chatId] = messages.length;
          }, onError: (error) {
            debugPrint('[ChatNotification] Stream error for $chatId: $error');
          });
        }
      }
    }, onError: (error) {
      debugPrint('[ChatNotification] Global chats stream error: $error');
    });
  }

  /// Stop all listening
  void stopListening() {
    _globalChatsSubscription?.cancel();
    _globalChatsSubscription = null;
    for (var sub in _chatSubscriptions.values) {
      sub.cancel();
    }
    _chatSubscriptions.clear();
    _lastKnownMessageCount.clear();
    _unreadCountByChat.clear();
    _updateTotalUnreadCount();
    currentViewedChatId = null;
  }

  /// Check if there's an active (non-expired) session for a given chatId
  static Future<bool> hasActiveSession(String chatId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null || !data.containsKey('expiresAt')) return false;

      final expiresAt = _safeParseDateTimeGlobal(data['expiresAt']);
      if (expiresAt == null) return false;
      return expiresAt.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// Delete chat session and all messages (cleanup after session ends)
  static Future<void> deleteChatSession(String chatId) async {
    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

      // Delete all messages in subcollection
      final messages = await chatRef.collection('messages').get();
      final batch = FirebaseFirestore.instance.batch();
      for (final msg in messages.docs) {
        batch.delete(msg.reference);
      }
      // Delete the chat document itself
      batch.delete(chatRef);
      await batch.commit();

      debugPrint('[ChatNotification] Deleted chat session: $chatId');
    } catch (e) {
      debugPrint('[ChatNotification] Error deleting chat: $e');
    }
  }

  void _showGlobalNotification({required String doctorName, String? doctorImage, required String message}) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                image: (doctorImage != null && doctorImage.startsWith('base64:')) 
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(doctorImage.substring(7))),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (doctorImage == null || !doctorImage.startsWith('base64:'))
                  ? const Center(child: Text('👨‍⚕️', style: TextStyle(fontSize: 20)))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.length > 60 ? '${message.substring(0, 60)}...' : message,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chat_bubble, color: Colors.white54, size: 20),
          ],
        ),
        backgroundColor: const Color(0xFF1E40AF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
        elevation: 8,
      ),
    );
  }
}
