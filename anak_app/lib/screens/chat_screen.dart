import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/webrtc_service.dart';
import '../services/app_state.dart';
import '../services/chat_notification_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploading = false;
  bool _isBotTyping = false;
  late String _chatId;
  late Map<String, dynamic> _doctor;
  bool _isInitialized = false;
  MemoryImage? _doctorAvatarImage;

  bool _isExpired = false;
  int _userRating = 5;
  bool _hasSubmittedReview = false;

  bool _isGracePeriod = false;
  String _timeRemaining = "30:00";
  Timer? _timer;
  int _lastWarnedMinute = 99; // Track which warning was last shown
  int _lastMessageCount = 0; // Track message count for doctor message notifications

  DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) {
      try {
        return DateTime.parse(val).toLocal();
      } catch (_) {
        return null;
      }
    }
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final appState = Provider.of<AppState>(context, listen: false);
      final rawArgs = ModalRoute.of(context)?.settings.arguments;

      if (rawArgs is Map<String, dynamic>) {
        if (rawArgs.containsKey('chatId') && rawArgs['chatId'] != null) {
          _chatId = rawArgs['chatId'].toString();
          _doctor = {
            'id': rawArgs['doctorId'] ?? rawArgs['id'] ?? 'dummy_doc',
            'name': rawArgs['name'] ?? rawArgs['doctorName'] ?? 'Dr. Jhon Doe',
            'image': rawArgs['image'] ?? rawArgs['doctorAvatar'] ?? '👨‍⚕️',
            'specialty': rawArgs['specialty'] ?? 'Spesialis Tumbuh Kembang',
          };
        } else {
          _doctor = Map<String, dynamic>.from(rawArgs);
          final docId = _doctor['id'] ?? 'dummy_doc';
          _chatId = 'chat_${appState.uid}_$docId';
        }
      } else {
        _doctor = {
          'id': 'dummy_doc',
          'name': 'Dr. Jhon Doe',
          'image': '👨‍⚕️',
          'specialty': 'Spesialis Tumbuh Kembang',
        };
        _chatId = 'chat_${appState.uid}_dummy_doc';
      }

      _isInitialized = true;
      
      // Initialize doctor avatar image to prevent flickering
      if (_doctor['image'] != null && _doctor['image'].toString().startsWith('base64:')) {
        try {
          _doctorAvatarImage = MemoryImage(base64Decode(_doctor['image'].substring(7)));
        } catch (e) {
          debugPrint('Error decoding doctor avatar: $e');
        }
      }

      // Mark this chat as currently viewed to suppress global notifications for it
      ChatNotificationService.currentViewedChatId = _chatId;
      _markAsRead(); // Mark existing messages as read
      _watchMessagesForReadStatus(); // Continuously mark incoming messages as read
      _listenForIncomingDoctorCalls(); // Listen for live In-App WebRTC audio calls
      if (_doctor['id'] != 'doctor_bot') {
        _watchSessionTimer();
      } else {
        _timeRemaining = "Asisten AI";
      }
    }
  }

  void _markAsRead() {
    _firestoreService.markChatMessagesAsRead(_chatId);
  }

  void _watchMessagesForReadStatus() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .where('senderType', isEqualTo: 'doctor')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && ChatNotificationService.currentViewedChatId == _chatId) {
        _markAsRead();
      }
    }, onError: (error) {
      debugPrint('[ChatScreen] Read-status stream error: $error');
    });
  }

  void _watchSessionTimer() {
    final docRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    docRef.snapshots().listen((snap) {
      if (snap.exists && _timer == null) {
        final data = snap.data();
        if (data != null && data.containsKey('expiresAt')) {
          final expiresAt = _parseDateTime(data['expiresAt']);
          if (expiresAt != null) {
            _startTimer(expiresAt);
          }
        }
      }
    }, onError: (error) {
      debugPrint('[ChatScreen] Session timer stream error: $error');
    });
  }

  void _startTimer(DateTime expiresAt) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = expiresAt.difference(now);
      
      if (diff.isNegative) {
        // Main session is over. Check Grace Period (1 min)
        final graceDiff = expiresAt.add(const Duration(minutes: 1)).difference(now);
        
        if (graceDiff.isNegative) {
          // Grace period is ALSO over. Terminate everything.
          timer.cancel();
          if (mounted) {
            setState(() {
              _timeRemaining = "Habis";
              _isExpired = true;
              _isGracePeriod = false;
            });
            _handleSessionExpired();
          }
        } else {
          // Inside Grace Period
          if (mounted) {
            setState(() {
              _isGracePeriod = true;
              _timeRemaining = "Tenggang: ${graceDiff.inSeconds}s";
            });
          }
        }
      } else {
        final minutesLeft = diff.inMinutes;
        if (mounted) {
          setState(() {
            _isGracePeriod = false;
            _timeRemaining = "${diff.inMinutes.toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
          });

          // Show warnings at 20, 10, and 5 minutes
          if (minutesLeft == 20 && _lastWarnedMinute != 20) {
            _lastWarnedMinute = 20;
            _showTimeWarning('⏰ Waktu konsultasi tersisa 20 menit', Colors.orange.shade600);
          } else if (minutesLeft == 10 && _lastWarnedMinute != 10) {
            _lastWarnedMinute = 10;
            _showTimeWarning('⚠️ Waktu konsultasi tersisa 10 menit', Colors.orange.shade800);
          } else if (minutesLeft == 5 && _lastWarnedMinute != 5) {
            _lastWarnedMinute = 5;
            _showTimeWarning('🚨 Waktu konsultasi tinggal 5 menit!', Colors.red.shade600);
          }
        }
      }
    });
  }

  void _handleSessionExpired() async {
    // Delete chat history from Firestore
    await ChatNotificationService.deleteChatSession(_chatId);

    if (!mounted) return;

    // Show dialog informing the user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⏰', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Sesi Berakhir',
                style: AppTheme.heading3.copyWith(color: AppTheme.gray900)),
            ),
          ],
        ),
        content: Text(
          'Waktu konsultasi 30 menit Anda dengan ${_doctor['name'] ?? 'Dokter'} telah habis.\n\nRiwayat chat telah dihapus secara otomatis.',
          style: AppTheme.bodyText.copyWith(color: AppTheme.gray700, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed('/consultation');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blue500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Kembali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTimeWarning(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _confirmEndSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Text('Akhiri Sesi?'),
          ],
        ),
        content: const Text(
          'Anda yakin ingin mengakhiri sesi konsultasi ini sekarang?\n\nSesi akan ditutup secara permanen dan riwayat chat akan dihapus.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: AppTheme.gray500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _terminateSessionNow();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Akhiri Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _terminateSessionNow() async {
    try {
      // Optimistic UI Update: change state immediately without waiting for Firestore
      if (mounted) {
        setState(() {
          _isExpired = true;
          _isGracePeriod = true;
          _timeRemaining = "Habis";
        });
      }

      // Set expiresAt to 1 second ago to trigger instant expiration on all clients
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .update({
            'expiresAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(seconds: 1)))
          });
      debugPrint('Session terminated manually via UI (Optimistic Update applied)');
    } catch (e) {
      debugPrint('Error terminating session: $e');
    }
  }

  void _showDoctorMessageNotification(String doctorName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Center(child: Text('👨‍⚕️', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text('Mengirim pesan baru', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    if (ChatNotificationService.currentViewedChatId == _chatId) {
      ChatNotificationService.currentViewedChatId = null;
    }
    super.dispose();
  }

  // Auto-scroll to bottom of ListView (used mainly when writing messages or when streams add up)
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty || _isExpired) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.uid ?? 'guest';
    final msgText = text.trim();

    _messageController.clear();
    
    // Write User Message to DB
    await _firestoreService.sendMessage(_chatId, userId, msgText, 'user', doctorId: _doctor['id']);
    
    Future.delayed(const Duration(milliseconds: 500), _scrollToBottom);

    if (_doctor['id'] == 'doctor_bot') {
      _triggerBotReply(msgText);
    }
  }

  Future<String?> _uploadFile(File file, String fileName) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'base64:$base64String';
    } catch (e) {
      debugPrint('Upload error: $e');
      throw Exception('Gagal memproses gambar: ${e.toString()}');
    }
  }

  Future<void> _sendMediaMessage({
    required String url,
    required String fileName,
    required String type, // 'image' or 'document'
    int? fileSize,
  }) async {
    if (_isExpired) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.uid ?? 'guest';

    // Ensure chat doc exists (same logic as sendMessage)
    final docRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set({
        'doctorId': _doctor['id'],
        'buyerId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 30))),
      });
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'text': type == 'image' ? '📷 Foto' : '📎 $fileName',
      'senderId': userId,
      'senderType': 'user',
      'timestamp': FieldValue.serverTimestamp(),
      'attachmentUrl': url,
      'attachmentType': type,
      'attachmentName': fileName,
      if (fileSize != null) 'attachmentSize': fileSize,
    });

    Future.delayed(const Duration(milliseconds: 500), _scrollToBottom);
  }

  void _pickImage(ImageSource source) async {
    if (_isExpired || _isUploading) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 50,
      );
      if (picked == null) return;

      setState(() => _isUploading = true);

      final file = File(picked.path);
      final fileName = picked.name;
      final url = await _uploadFile(file, fileName);

      if (url != null && mounted) {
        await _sendMediaMessage(url: url, fileName: fileName, type: 'image');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah foto'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _pickDocument() async {
    if (_isExpired || _isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'png', 'jpg', 'jpeg'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      if (pickedFile.path == null) return;

      setState(() => _isUploading = true);

      final file = File(pickedFile.path!);
      final fileName = pickedFile.name;
      final fileSize = pickedFile.size;
      final url = await _uploadFile(file, fileName);

      if (url != null && mounted) {
        final ext = fileName.split('.').last.toLowerCase();
        final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
        await _sendMediaMessage(
          url: url,
          fileName: fileName,
          type: isImage ? 'image' : 'document',
          fileSize: fileSize,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah dokumen'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Pick document error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppTheme.gray300, borderRadius: BorderRadius.circular(2)),
            ),
            Text('Kirim Lampiran', style: AppTheme.heading3.copyWith(color: AppTheme.gray900)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildAttachOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildAttachOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Dokumen',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDocument();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTheme.bodyText.copyWith(color: AppTheme.gray700, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }


  Widget _buildCompletedSessionCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.gray200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sesi Konsultasi Telah Selesai',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.gray900),
                    ),
                    const Text(
                      'Rencana stimulasi & catatan telah tersimpan ke rekam medis.',
                      style: TextStyle(fontSize: 11, color: AppTheme.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (!_hasSubmittedReview && _doctor['id'] != 'doctor_bot') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Column(
                children: [
                  Text(
                    'Bagaimana pengalaman konsultasi dengan ${_doctor['name'] ?? 'Dokter'}?',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.gray700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        iconSize: 28,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          star <= _userRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: star <= _userRating ? Colors.amber.shade500 : AppTheme.gray300,
                        ),
                        onPressed: () => setState(() => _userRating = star),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() => _hasSubmittedReview = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terima kasih! Ulasan bintang berhasil dikirim ke dokter. ⭐'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      child: const Text('Kirim Penilaian Dokter', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/progress'),
                  icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF4F46E5)),
                  label: const Text('Rekam Medis', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/doctor-list'),
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                  label: const Text('Sesi Baru', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildActionPlanMessageCard(Map<String, dynamic> msgMap, String formattedTime) {
    final rawText = msgMap['text']?.toString() ?? '';
    String target = 'Motorik & Regulasi Emosi';
    String screenTime = 'Maks. 30 Menit/Hari';
    String notes = 'Dampingi anak saat bermain dan konsisten dengan jadwal makan bebas layar.';

    final targetMatch = RegExp(r'Target Fokus\*?:\\s*([^\\n]+)').firstMatch(rawText);
    if (targetMatch != null) target = targetMatch.group(1)?.trim() ?? target;

    final screenMatch = RegExp(r'Batas Waktu Layar\*?:\\s*([^\\n]+)').firstMatch(rawText);
    if (screenMatch != null) screenTime = screenMatch.group(1)?.trim() ?? screenTime;

    final notesMatch = RegExp(r'Instruksi Khusus\*?:\\s*([\\s\\S]+?)(?=\\n\\n|Silakan|$)').firstMatch(rawText);
    if (notesMatch != null) notes = notesMatch.group(1)?.trim() ?? notes;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('📋', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'RENCANA STIMULASI DOKTER',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                      ),
                    ],
                  ),
                ),

                // Card Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                children: [
                                  const TextSpan(text: 'Target Fokus: ', style: TextStyle(color: Colors.white70)),
                                  TextSpan(text: target, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('📱', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                children: [
                                  const TextSpan(text: 'Batas Layar: ', style: TextStyle(color: Colors.white70)),
                                  TextSpan(text: screenTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notes,
                                style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4338CA),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/progress'),
                          icon: const Icon(Icons.trending_up, size: 16),
                          label: const Text('Buka di Dashboard Tumbuh Kembang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialReportMessageCard(Map<String, dynamic> msgMap, String formattedTime) {
    final rawText = msgMap['text']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text('📄', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'LAPORAN ASESMEN RESMI DOKTER',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rawText.replaceAll('📄 **LAPORAN ASESMEN RESMI**', '').trim(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F766E),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/progress'),
                          icon: const Icon(Icons.description, size: 16),
                          label: const Text('Buka Rekam Medis Pasien', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionEndedMessageCard(Map<String, dynamic> msgMap, String formattedTime) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF475569), size: 18),
              SizedBox(width: 6),
              Text(
                'SESI KONSULTASI DITUTUP RESMI',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF334155), letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Catatan hasil konsultasi & resep stimulasi telah tersimpan secara aman.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(formattedTime, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }



  final PatientWebRTCService _webrtcService = PatientWebRTCService();
  bool _isCallModalOpen = false;
  int _callDurationSec = 0;
  Timer? _callDurationTimer;
  StreamSubscription? _incomingCallSub;

  void _listenForIncomingDoctorCalls() {
    _incomingCallSub?.cancel();
    _incomingCallSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('webrtc')
        .doc('session')
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] as String?;
      final caller = data['caller'] as String?;

      if (status == 'ringing' && caller == 'doctor' && !_isCallModalOpen) {
        _showIncomingDoctorCallSheet();
      } else if (status == 'ended' && _isCallModalOpen) {
        _callDurationTimer?.cancel();
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _isCallModalOpen = false;
        _webrtcService.cleanup();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi panggilan suara dengan dokter telah selesai. 🎙️'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
      }
    });
  }

  void _startInAppPatientCall() async {
    _isCallModalOpen = true;
    _callDurationSec = 0;

    await _webrtcService.initRenderer();
    _webrtcService.startPatientCall(
      _chatId,
      onRemoteStream: (stream) {
        debugPrint('[WebRTC] Receiving doctor audio stream');
      },
      onStatusChange: (status) {
        if (status == 'connected') {
          _callDurationTimer?.cancel();
          _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (t) {
            if (mounted) setState(() => _callDurationSec++);
          });
        } else if (status == 'ended') {
          _callDurationTimer?.cancel();
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          _isCallModalOpen = false;
        }
      },
    );

    _showActiveCallModal(isInitiator: true);
  }

  void _showIncomingDoctorCallSheet() {
    _isCallModalOpen = true;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 3),
              ),
              child: Center(
                child: _buildAvatar(_doctor['image'] ?? '👨‍⚕️', size: 48),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _doctor['name'] ?? 'Dokter Spesialis',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Panggilan Telekonsultasi Suara Masuk...',
              style: TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'reject_doctor_call',
                      backgroundColor: Colors.red.shade600,
                      onPressed: () async {
                        _isCallModalOpen = false;
                        Navigator.pop(ctx);
                        await _webrtcService.endCall(_chatId);
                      },
                      child: const Icon(Icons.call_end, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tolak', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'accept_doctor_call',
                      backgroundColor: const Color(0xFF10B981),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _webrtcService.initRenderer();
                        await _webrtcService.answerDoctorCall(
                          _chatId,
                          onRemoteStream: (stream) => debugPrint('[WebRTC] Doctor audio connected'),
                          onStatusChange: (status) {
                            if (status == 'ended') {
                              _callDurationTimer?.cancel();
                              if (mounted && Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                              _isCallModalOpen = false;
                            }
                          },
                        );
                        _callDurationTimer?.cancel();
                        _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                          if (mounted) setState(() => _callDurationSec++);
                        });
                        _showActiveCallModal(isInitiator: false);
                      },
                      child: const Icon(Icons.call, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text('Terima', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showActiveCallModal({required bool isInitiator}) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6366F1), width: 3),
                      ),
                      child: Center(
                        child: _buildAvatar(_doctor['image'] ?? '👨‍⚕️', size: 54),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _doctor['name'] ?? 'Dokter Spesialis',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Telekonsultasi Audio In-App (WebRTC)',
                      style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(_callDurationSec ~/ 60).toString().padLeft(2, '0')}:${(_callDurationSec % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Button
                    IconButton(
                      iconSize: 48,
                      onPressed: () {
                        _webrtcService.toggleMute();
                        setModalState(() {});
                      },
                      icon: CircleAvatar(
                        radius: 28,
                        backgroundColor: _webrtcService.isMuted ? Colors.red.shade600 : const Color(0xFF334155),
                        child: Icon(
                          _webrtcService.isMuted ? Icons.mic_off : Icons.mic,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // End Call Button
                    IconButton(
                      iconSize: 56,
                      onPressed: () async {
                        _callDurationTimer?.cancel();
                        _isCallModalOpen = false;
                        Navigator.pop(ctx);
                        await _webrtcService.endCall(_chatId);
                      },
                      icon: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.red.shade600,
                        child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                      ),
                    ),

                    // Speaker Button
                    IconButton(
                      iconSize: 48,
                      onPressed: () {
                        _webrtcService.toggleSpeaker();
                        setModalState(() {});
                      },
                      icon: CircleAvatar(
                        radius: 28,
                        backgroundColor: _webrtcService.isSpeakerOn ? const Color(0xFF6366F1) : const Color(0xFF334155),
                        child: Icon(
                          _webrtcService.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String imageStr, {double size = 40}) {
    if (imageStr.startsWith('base64:')) {
      if (_doctorAvatarImage != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image(
            image: _doctorAvatarImage!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => Text('👨‍⚕️', style: TextStyle(fontSize: size)),
          ),
        );
      }
      try {
        final bytes = base64Decode(imageStr.substring(7));
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            bytes,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => Text('👨‍⚕️', style: TextStyle(fontSize: size)),
          ),
        );
      } catch (e) {
        return Text('👨‍⚕️', style: TextStyle(fontSize: size));
      }
    }
    return Text(imageStr, style: TextStyle(fontSize: size));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.gray100)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.gray600),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: AppTheme.gray100),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppTheme.blue100, shape: BoxShape.circle),
                child: Center(child: _buildAvatar(_doctor['image'] ?? '👨‍⚕️', size: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _doctor['name'] ?? 'Dokter', 
                      style: AppTheme.heading3.copyWith(color: AppTheme.gray900, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: AppTheme.green500, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Online', style: AppTheme.bodyText.copyWith(color: AppTheme.green600, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        if (_doctor['id'] == 'doctor_bot')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.cyan.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text("Asisten AI", style: TextStyle(color: Color(0xFF0891B2), fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else if (!_isExpired && _timeRemaining != "30:00")
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.orange100, borderRadius: BorderRadius.circular(4)),
                            child: Text(_timeRemaining, style: TextStyle(color: AppTheme.orange600, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (_isExpired && _doctor['id'] != 'doctor_bot')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                            child: Text("Sesi Berakhir", style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isExpired && !_isGracePeriod && _doctor['id'] != 'doctor_bot')
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppTheme.primaryBlue, size: 22),
                      onPressed: _startInAppPatientCall,
                      tooltip: 'Panggilan Suara Telekonsultasi',
                    ),
                    IconButton(
                      icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 22),
                      onPressed: _confirmEndSession,
                      tooltip: 'Akhiri Sesi',
                    ),
                  ],
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppTheme.gray600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.pushNamed(context, '/doctor-detail', arguments: _doctor);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20, color: AppTheme.blue600),
                        const SizedBox(width: 12),
                        Text('Lihat Profil Dokter', style: AppTheme.bodyText.copyWith(color: AppTheme.gray800)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.report_problem_outlined, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text('Laporkan Sesi', style: AppTheme.bodyText.copyWith(color: AppTheme.gray800)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Real-time Chat Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getChatStream(_chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text('Gagal memuat pesan', style: AppTheme.heading3.copyWith(color: AppTheme.gray800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }
                
                final docs = snapshot.data?.docs ?? [];
                final List<Map<String, dynamic>> messages = [];
                for (var doc in docs) {
                  final data = doc.data();
                  if (data != null && data is Map<String, dynamic>) {
                    messages.add(data);
                  }
                }

                if (messages.isEmpty && _doctor['id'] == 'doctor_bot') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _sendBotWelcomeMessage();
                  });
                }

                // Mark messages as read IF there are any unread doctor messages
                bool hasUnread = messages.any((msgData) {
                  return msgData['senderType'] == 'doctor' && (msgData['isRead'] == false || msgData['isRead'] == null);
                });
                
                if (hasUnread) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final appState = Provider.of<AppState>(context, listen: false);
                    _firestoreService.markMessagesAsRead(_chatId, appState.uid ?? '');
                  });
                }

                // Detect new doctor message for notification
                if (messages.length > _lastMessageCount && _lastMessageCount > 0) {
                  final lastMsg = messages.last;
                  if (lastMsg['senderType'] == 'doctor' && !_isExpired) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showDoctorMessageNotification(_doctor['name'] ?? 'Dokter');
                      _scrollToBottom();
                    });
                  }
                }
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _lastMessageCount = messages.length;
                  }
                });
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (_isBotTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isBotTyping) {
                      return _buildTypingIndicator();
                    }
                    
                    final msgMap = messages[index];
                    final isUser = msgMap['senderType'] == 'user';
                    
                    String formattedTime = '';
                    final parsedDate = _parseDateTime(msgMap['timestamp']);
                    if (parsedDate != null) {
                      formattedTime = DateFormat('HH:mm').format(parsedDate);
                    }

                    final textContent = msgMap['text']?.toString() ?? '';
                    if (textContent.contains('ACTION PLAN') || textContent.contains('Target Fokus')) {
                      return _buildActionPlanMessageCard(msgMap, formattedTime);
                    }
                    if (textContent.contains('LAPORAN ASESMEN RESMI')) {
                      return _buildOfficialReportMessageCard(msgMap, formattedTime);
                    }
                    if (textContent.contains('SESI KONSULTASI RESMI SELESAI')) {
                      return _buildSessionEndedMessageCard(msgMap, formattedTime);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isUser ? AppTheme.blue500 : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isUser ? 16 : 0),
                                bottomRight: Radius.circular(isUser ? 0 : 16),
                              ),
                              boxShadow: isUser ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                // Image attachment
                                if (msgMap['attachmentType'] == 'image' && msgMap['attachmentUrl'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: GestureDetector(
                                        onTap: () => _showFullImage(msgMap['attachmentUrl']),
                                        child: msgMap['attachmentUrl'].startsWith('base64:')
                                          ? Image.memory(
                                              base64Decode(msgMap['attachmentUrl'].substring(7)),
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              gaplessPlayback: true,
                                            )
                                          : Image.network(
                                              msgMap['attachmentUrl'],
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (ctx, child, progress) {
                                                if (progress == null) return child;
                                                return Container(
                                                  height: 150,
                                                  decoration: BoxDecoration(
                                                    color: isUser ? Colors.white.withAlpha(30) : AppTheme.gray100,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                );
                                              },
                                              errorBuilder: (ctx, err, stack) => Container(
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  color: isUser ? Colors.white.withAlpha(30) : AppTheme.gray100,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Center(child: Icon(Icons.broken_image, size: 40)),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                // Document attachment
                                if (msgMap['attachmentType'] == 'document' && msgMap['attachmentUrl'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isUser ? Colors.white.withAlpha(30) : AppTheme.gray100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getFileIcon(msgMap['attachmentName'] ?? ''),
                                          color: isUser ? Colors.white : AppTheme.blue500,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                msgMap['attachmentName'] ?? 'Dokumen',
                                                style: TextStyle(
                                                  color: isUser ? Colors.white : AppTheme.gray900,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (msgMap['attachmentSize'] != null)
                                                Text(
                                                  _formatFileSize(msgMap['attachmentSize']),
                                                  style: TextStyle(
                                                    color: isUser ? Colors.white70 : AppTheme.gray500,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Text (only show if not an attachment-only message)
                                if (msgMap['attachmentType'] == null)
                                  Text(
                                    msgMap['text'] ?? '',
                                    style: AppTheme.bodyText.copyWith(
                                      color: isUser ? Colors.white : AppTheme.gray900,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isUser ? Colors.white.withAlpha(200) : AppTheme.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Quick Responses (Hide when expired or in grace period)
          if (!_isExpired && !_isGracePeriod)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.gray100)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Terima kasih dokter',
                    'Saya mengerti',
                    'Apakah ada efek samping?',
                    'Berapa lama pengobatan?'
                  ].map((response) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _sendMessage(response),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.gray100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          response,
                          style: AppTheme.bodyText.copyWith(color: AppTheme.gray700, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),

          // Message Input Bar or Completed Card
          if (_isExpired || _isGracePeriod)
            _buildCompletedSessionCard()
          else
            Container(
              padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.gray100)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, -4))],
              ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isGracePeriod)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                    child: Center(
                      child: Text(
                        'MASA TENGGANG MEMBACA - KIRIM PESAN NONAKTIF',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.blue500, size: 30),
                      onPressed: (_isExpired || _isGracePeriod) ? null : _showAttachmentOptions,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.gray100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          enabled: !_isExpired && !_isGracePeriod,
                          decoration: InputDecoration(
                            hintText: _isGracePeriod ? 'Sesi berakhir...' : 'Tulis pesan...',
                            hintStyle: AppTheme.bodyText.copyWith(color: AppTheme.gray500, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          style: AppTheme.bodyText.copyWith(fontSize: 14),

                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: (_isExpired || _isGracePeriod) ? null : () => _sendMessage(_messageController.text),
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: (_isExpired || _isGracePeriod) ? AppTheme.gray300 : AppTheme.blue500,
                          shape: BoxShape.circle,
                          boxShadow: (_isExpired || _isGracePeriod) ? [] : [BoxShadow(color: AppTheme.blue500.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  child: url.startsWith('base64:')
                      ? Image.memory(
                          base64Decode(url.substring(7)), 
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        )
                      : Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'txt':
        return Icons.article_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(200),
                const SizedBox(width: 4),
                _buildDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.gray400.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  void _sendBotWelcomeMessage() async {
    final docRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      final appState = Provider.of<AppState>(context, listen: false);
      await docRef.set({
        'doctorId': 'doctor_bot',
        'buyerId': appState.uid ?? 'guest',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final messagesSnap = await docRef.collection('messages').limit(1).get();
    if (messagesSnap.docs.isEmpty) {
      final welcomeText = "Halo Bunda & Ayah! Saya Asisten AI ANAK 🤖. Saya siap mendampingi perjalanan tumbuh kembang Si Kecil dan menjawab pertanyaan seputar kesehatan fisik, kecerdasan kognitif, psikologi anak, serta tips stimulasi.\n\nAda yang bisa saya bantu hari ini?";
      await _firestoreService.sendMessage(_chatId, 'doctor_bot', welcomeText, 'doctor');
    }
  }

  void _triggerBotReply(String userMessage) async {
    if (!mounted) return;
    setState(() {
      _isBotTyping = true;
    });

    // Scroll to bottom so typing indicator is visible
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    // Wait a brief delay to simulate typing
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final rawReply = await _callGeminiForBot(userMessage);
      final reply = rawReply.replaceAll('**', '');
      if (mounted) {
        setState(() {
          _isBotTyping = false;
        });

        // Write Bot Message to DB
        await _firestoreService.sendMessage(_chatId, 'doctor_bot', reply, 'doctor');

        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    } catch (e) {
      debugPrint('Error getting bot response: $e');
      if (mounted) {
        setState(() {
          _isBotTyping = false;
        });
        // Write a fallback error message
        await _firestoreService.sendMessage(_chatId, 'doctor_bot', 'Maaf Ayah/Bunda, saya sedang mengalami gangguan koneksi ke server AI. Silakan coba kirim pesan kembali beberapa saat lagi.', 'doctor');
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    }
  }

  Future<String> _callGeminiForBot(String userMessage) async {
    final provider = dotenv.env['AI_PROVIDER'] ?? 'mock';
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (provider != 'gemini' || apiKey.isEmpty) {
      return _generateMockBotResponse(userMessage);
    }

    try {
      // Fetch conversation history from Firestore
      final msgsRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(8);

      final msgsSnap = await msgsRef.get();
      final contents = <Map<String, dynamic>>[];

      // Construct historical context in chronological order
      for (var doc in msgsSnap.docs.reversed) {
        final data = doc.data();
        final text = data['text'] as String? ?? '';
        final isUser = data['senderType'] == 'user';
        contents.add({
          'role': isUser ? 'user' : 'model',
          'parts': [{'text': text}],
        });
      }

      // If list is empty, add current message
      if (contents.isEmpty) {
        contents.add({
          'role': 'user',
          'parts': [{'text': userMessage}],
        });
      }

      const model = 'gemini-3.5-flash';
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

      final systemPrompt = 
          "Anda adalah Asisten AI ANAK 🤖 (Aplikasi Tumbuh Kembang Anak). Anda berperan sebagai konsultan tumbuh kembang anak, psikolog anak, dan dokter spesialis anak yang ramah, hangat, empati, dan profesional. "
          "Tugas Anda adalah mendampingi orang tua (Bunda & Ayah) dengan memberikan informasi tumbuh kembang, tips stimulasi fisik/kognitif, serta saran parenting praktis. "
          "Aturan penting:\n"
          "1. Selalu gunakan Bahasa Indonesia yang hangat, ramah, dan mendukung.\n"
          "2. Jawablah dengan ringkas (maksimal 3 paragraf pendek) agar mudah dibaca di layar chat.\n"
          "3. Berikan saran praktis dan terstruktur (gunakan bullet points jika perlu).\n"
          "4. Ingatkan orang tua untuk berkonsultasi dengan dokter spesialis secara langsung jika kondisi anak tampak darurat atau memerlukan pemeriksaan medis langsung.";

      final requestBody = {
        'system_instruction': {
          'parts': [{'text': systemPrompt}],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 800,
          'responseMimeType': 'text/plain',
        },
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        ],
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) return text.trim();
      }

      return _generateMockBotResponse(userMessage);
    } catch (e) {
      debugPrint('[ChatScreen Bot] Gemini Error: $e');
      return _generateMockBotResponse(userMessage);
    }
  }

  String _generateMockBotResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    if (msg.contains('panas') || msg.contains('demam') || msg.contains('suhu')) {
      return "Halo Bunda & Ayah. Jika anak mengalami demam:\n\n"
          "1. **Kompres Hangat**: Kompres ketiak dan lipatan selangkangan menggunakan air hangat (bukan air dingin/es).\n"
          "2. **Penuhi Cairan**: Berikan ASI, air putih, atau sup hangat sesering mungkin untuk mencegah dehidrasi.\n"
          "3. **Pakaian Nyaman**: Pakaikan baju tidur tipis yang menyerap keringat.\n"
          "4. **Obat Demam**: Berikan parasetamol sesuai dosis berat badan jika suhu mencapai > 38.5°C.\n\n"
          "Jika demam berlangsung lebih dari 3 hari, atau disertai kejang, leher kaku, atau anak tampak sangat lemas, segera bawa ke rumah sakit terdekat ya.";
    }

    if (msg.contains('makan') || msg.contains('lahap') || msg.contains('gtm') || msg.contains('nafsu')) {
      return "Mengatasi anak yang sulit makan (GTM/Gerakan Tutup Mulut) memang butuh kesabaran ekstra. Beberapa tips yang bisa dicoba:\n\n"
          "1. **Feeding Rules**: Buat jadwal makan teratur, batasi waktu makan maksimal 30 menit, dan hindari distrasi (gadget/TV/mainan) saat makan.\n"
          "2. **Variasi Menu**: Sajikan makanan dengan tampilan menarik, porsi kecil tapi sering, dan biarkan anak makan sendiri untuk melatih motoriknya.\n"
          "3. **Hindari Memaksa**: Memaksa anak justru bisa membuatnya trauma dengan waktu makan.\n\n"
          "Tetap tawarkan makanan secara konsisten dan jadikan suasana makan menyenangkan ya Bun/Yah!";
    }

    if (msg.contains('bicara') || msg.contains('lambat') || msg.contains('telat') || msg.contains('bicara') || msg.contains('speech delay')) {
      return "Untuk merangsang kemampuan bicara dan bahasa Si Kecil, Ayah & Bunda dapat menerapkan langkah berikut:\n\n"
          "1. **Bebas Layar (No Screen Time)**: Hindari gawai/gadget dan TV sama sekali untuk anak di bawah 2 tahun.\n"
          "2. **Ajak Mengobrol**: Narasikan aktivitas sehari-hari (misal: 'Bunda sedang mencuci piring', 'Ini bola merah').\n"
          "3. **Membaca Buku**: Bacakan buku cerita bergambar dengan suara ekspresif setiap hari.\n"
          "4. **Bahasa Jelas**: Jangan meniru bahasa bayi (cedal). Sebutkan kata yang benar dengan pelan.\n\n"
          "Jika di usia 18-24 bulan anak belum bisa mengucapkan kata berarti atau menunjuk benda, sebaiknya konsultasikan ke klinik tumbuh kembang ya.";
    }

    if (msg.contains('jalan') || msg.contains('merangkak') || msg.contains('motorik') || msg.contains('fisik')) {
      return "Stimulasi perkembangan motorik kasar anak sangat penting di awal usianya:\n\n"
          "1. **Tummy Time**: Lakukan sejak bayi baru lahir beberapa menit sehari untuk melatih otot leher dan dada.\n"
          "2. **Mainan Pancingan**: Taruh mainan favorit sedikit di luar jangkauannya agar anak tertarik merayap, merangkak, atau melangkah.\n"
          "3. **Bebas Eksplorasi**: Ciptakan area bermain yang aman di lantai agar anak bebas bergerak.\n\n"
          "Pastikan perkembangan Si Kecil selalu dipantau sesuai dengan milestonenya ya Bunda/Ayah.";
    }

    return "Terima kasih atas pertanyaannya Bunda/Ayah. Sebagai Asisten AI Tumbuh Kembang, saya menyarankan untuk selalu menjaga nutrisi seimbang, membatasi penggunaan gawai (screen time), dan memberikan stimulasi motorik serta bahasa yang konsisten sesuai usia Si Kecil.\n\nApakah ada pertanyaan spesifik tentang perilaku atau perkembangan Si Kecil yang ingin didiskusikan hari ini?";
  }
}
