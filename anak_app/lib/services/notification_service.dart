import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      if (kDebugMode) {
        print("Failed to get local timezone, falling back to Asia/Jakarta: $e");
      }
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (err) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    // 2. Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // 3. iOS/Darwin Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _localNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );
      _initialized = true;

      // 4. Create explicit Android Notification Channels for Android 8.0+
      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'anak_app_chat',
            'Pesan & Konsultasi Dokter',
            description: 'Notifikasi pesan baru dan panggilan telekonsultasi dokter',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'anak_app_reminders',
            'Pengingat Harian & Stimulasi',
            description: 'Pengingat harian melatih perkembangan anak',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'anak_app_general',
            'Informasi Umum & Pencapaian',
            description: 'Notifikasi info umum, tantangan harian, dan stiker baru',
            importance: Importance.high,
          ),
        );

        // Request permissions on Android 13+
        await androidPlugin.requestNotificationsPermission();
      }

      // 5. Set up Firebase Cloud Messaging
      await setupFirebaseMessaging();

      // 6. Schedule Default Daily Reminders
      await scheduleDefaultDailyReminders();

      if (kDebugMode) {
        print("[NotificationService] Initialized successfully with all channels.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("[NotificationService] Initialization error: $e");
      }
    }
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (kDebugMode) {
      print("Notification clicked with payload: $payload");
    }
  }

  // Setup Firebase Cloud Messaging
  Future<void> setupFirebaseMessaging() async {
    try {
      // 1. Request FCM Push Permission
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted push permission: ${settings.authorizationStatus}');
      }

      // 2. Retrieve the FCM Device Token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        if (kDebugMode) {
          print("FCM Token successfully retrieved: $fcmToken");
        }
        await _saveTokenToFirestore(fcmToken);
      }

      // 3. Listen for token refresh events
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        await _saveTokenToFirestore(token);
      });

      // 4. Handle incoming foreground push messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("FCM Foreground Message received: ${message.notification?.title}");
        }
        final notification = message.notification;
        if (notification != null) {
          showNotification(
            id: notification.hashCode,
            title: notification.title ?? 'Notifikasi Baru',
            body: notification.body ?? '',
            payload: message.data.toString(),
          );
        }
      });

      // 5. Handle app opened via notification click
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print("App opened via FCM notification click: ${message.data}");
        }
      });

    } catch (e) {
      if (kDebugMode) {
        print("Error setting up Firebase Messaging: $e");
      }
    }
  }

  // Save/Update FCM Token in User Firestore Profile document
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        if (kDebugMode) {
          print("FCM Token successfully linked to UID: ${currentUser.uid}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to store FCM Token: $e");
      }
    }
  }

  // Show immediate general notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'anak_app_general',
      'Informasi Umum & Pencapaian',
      channelDescription: 'Notifikasi info umum, tantangan harian, dan stiker baru',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Show doctor chat message notification (Heads-up / Max Priority)
  Future<void> showChatNotification({
    required String doctorName,
    required String message,
    String? chatId,
  }) async {
    if (!_initialized) await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'anak_app_chat',
      'Pesan & Konsultasi Dokter',
      channelDescription: 'Notifikasi pesan baru dan panggilan telekonsultasi dokter',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Pesan baru dari $doctorName',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(message),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      doctorName,
      message,
      platformDetails,
      payload: chatId != null ? 'chat:$chatId' : 'chat',
    );
  }

  // Schedule default daily reminders for parents & children
  Future<void> scheduleDefaultDailyReminders() async {
    // 08:30 Pagi: Waktunya Stimulasi & Main Game
    await scheduleDailyNotification(
      id: 1001,
      title: 'Waktunya Bermain & Belajar! 🌟',
      body: 'Yuk selesaikan 1 puzzle harian untuk melatih logika dan raih stiker baru!',
      hour: 8,
      minute: 30,
    );

    // 18:30 Malam: Review Tumbuh Kembang
    await scheduleDailyNotification(
      id: 1002,
      title: 'Rapor Tumbuh Kembang Si Kecil 📊',
      body: 'Cek perkembangan kognitif dan stimulasi harian anak Anda di aplikasi Zikola.',
      hour: 18,
      minute: 30,
    );
  }

  // Schedule daily notification at specific hour and minute
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'anak_app_reminders',
      'Pengingat Harian & Stimulasi',
      channelDescription: 'Pengingat harian melatih perkembangan anak',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.cancel(id);

    try {
      final scheduledTime = _nextInstanceOfTime(hour, minute);
      
      try {
        await _localNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        await _localNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to schedule daily notification: $e");
      }
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
  }
}
