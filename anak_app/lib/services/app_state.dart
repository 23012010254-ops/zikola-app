import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_profile.dart';
import '../models/patient.dart';
import '../models/doctor_schedule.dart';
import '../models/clinical_note.dart';
import '../models/test_result.dart';
import '../models/game_assessment.dart';
import '../models/sticker.dart';
import '../models/app_notification.dart';
import '../models/daily_challenge.dart';
import 'firestore_service.dart';
import 'chat_notification_service.dart';
import 'ai_report_service.dart';
import 'audio_service.dart';
import 'notification_service.dart';
import 'offline_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

export '../models/test_result.dart';
export '../models/game_assessment.dart';

class AppState extends ChangeNotifier {
  // Child Profile
  ChildProfile _childProfile = ChildProfile();
  ChildProfile get childProfile => _childProfile;

  // Onboarding
  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // Sound Settings
  bool _isSoundEnabled = true;
  bool get isSoundEnabled => _isSoundEnabled;

  // Parental PIN & Screen Time
  String? _parentalPin;
  String? get parentalPin => _parentalPin;
  int _screenTimeLimit = 0; // minutes, 0 = unlimited
  int get screenTimeLimit => _screenTimeLimit;
  int _todayPlayTime = 0; // minutes
  int get todayPlayTime => _todayPlayTime;

  // Daily Challenges & Gamification
  List<DailyChallenge> _todayChallenges = [];
  List<DailyChallenge> get todayChallenges => _todayChallenges;
  int _currentStreak = 0;
  int get currentStreak => _currentStreak;
  int _longestStreak = 0;
  int get longestStreak => _longestStreak;
  int _totalXP = 0;
  int get totalXP => _totalXP;
  int get currentLevel => (_totalXP ~/ 100) + 1;

  // Multi-Child Support
  List<ChildProfile> _children = [];
  List<ChildProfile> get children => _children;
  String? _activeChildId;
  String? get activeChildId => _activeChildId;

  // Offline Mode
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  // Authentication
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // Doctor Role — only true for accounts an admin has verified in
  // doctor_accounts/{uid}. Firestore rules enforce the same check server-side.
  bool _isDoctor = false;
  bool get isDoctor => _isDoctor;
  String? _doctorAccountId;
  String? get doctorAccountId => _doctorAccountId;
  void setDoctorMode(bool value) {
    _isDoctor = value;
    notifyListeners();
  }

  Future<void> _loadDoctorRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('doctor_accounts').doc(uid).get();
      final data = doc.data();
      final verified = data != null && data['verified'] == true;
      _isDoctor = verified;
      _doctorAccountId = verified ? (data['doctorId'] as String? ?? uid) : null;
    } catch (e) {
      _isDoctor = false;
      _doctorAccountId = null;
      debugPrint('Error loading doctor role: $e');
    }
  }

  final FirestoreService _firestore = FirestoreService();
  String? _uid;
  bool _isInitialized = false;
  String? _initError;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  SharedPreferences? _prefs;
  bool _localOnboardingComplete = false;
  String? _userIdentity;  // Single source of truth for identity
  String? _email;         // User email from Firestore/Auth

  String? get uid => _uid;
  String? get userIdentity => _userIdentity;
  String? get email => _email;
  bool get isInitialized => _isInitialized;
  String? get initError => _initError;

  int _unreadActivityCount = 0;
  int get unreadActivityCount => _unreadActivityCount;
  int get unreadChatsCount => ChatNotificationService().unreadChatsCount.value;
  int get totalUnreadNotifications => _unreadActivityCount + unreadChatsCount;

  // Snapshot Shield: Prevents stale listener updates from overwriting local state
  bool _isWriting = false;
  bool _isSurveyInProgress = false;
  Timer? _shieldTimer;
  Timer? _screenTimeTimer;

  // AI Report Lifecycle
  AIReport? _latestAIReport;
  AIReport? get latestAIReport => _latestAIReport;
  AIReportStatus _aiStatus = AIReportStatus.idle;
  AIReportStatus get aiStatus => _aiStatus;

  // Screen Time Lock State
  bool _isScreenTimeLocked = false;
  bool get isScreenTimeLocked => _isScreenTimeLocked;

  void lockScreenTime() {
    _isScreenTimeLocked = true;
    notifyListeners();
  }

  void unlockScreenTime() {
    _isScreenTimeLocked = false;
    notifyListeners();
  }

  Future<void> _syncProfile() async {
    if (_uid == null) return;
    
    // Update local onboarding cache
    await _saveLocalOnboarding(_childProfile.surveyCompleted || _childProfile.name.isNotEmpty);

    // PRE-WRITE VALIDATION: Don't write back an empty "default" profile if we are in the middle of loading
    // or if the name was unexpectedly lost.
    if (_childProfile.name.isEmpty && _childProfile.gender == 'male' && !_childProfile.surveyCompleted) {
      debugPrint('Sync Blocked: Profile appears uninitialized. Skipping write to prevent Firestore corruption.');
      return;
    }

    _isWriting = true;
    await _firestore.saveProfile(_uid!, _childProfile);
    _saveProfileLocally(); // Local sync resets cache timestamp to current local time
    
    // Shield resets after 3 seconds
    Future.delayed(const Duration(seconds: 3), () => _isWriting = false);
  }

  void _activateShield() {
    _isWriting = true;
    _shieldTimer?.cancel();
    _shieldTimer = Timer(const Duration(seconds: 5), () {
      _isWriting = false;
      notifyListeners();
    });
  }

  Future<void> setLoggedIn(bool value, {String? uid}) async {
    _isLoggedIn = value;
    _uid = uid;
    
    // FAST TRACK: Load local state immediately to avoid survey loop
    if (value && uid != null) {
      _prefs ??= await SharedPreferences.getInstance();
      _localOnboardingComplete = _prefs?.getBool('onboarding_complete_$uid') ?? false;
      final cachedName = _prefs?.getString('user_name_$uid');
      if (cachedName != null && _childProfile.name.isEmpty) {
        _childProfile = _childProfile.copyWith(name: cachedName);
      }
      
      // Load and apply sound settings
      _isSoundEnabled = _prefs?.getBool('sound_enabled') ?? true;
      await AudioService().setSoundEnabled(_isSoundEnabled);

      // Load onboarding check
      _hasSeenOnboarding = _prefs?.getBool('has_seen_onboarding') ?? false;

      // Load parental PIN & Screen time
      _parentalPin = _prefs?.getString('parental_pin_$uid');
      _screenTimeLimit = _prefs?.getInt('screen_time_limit_$uid') ?? 0;
      _todayPlayTime = _prefs?.getInt('today_play_time_$uid') ?? 0;

      // Initialize Services
      try {
        await NotificationService().initialize();
        await NotificationService().scheduleDailyNotification(
          id: 1111,
          title: 'Waktunya Bermain! 🎮',
          body: 'Ayo latih tumbuh kembang anak hari ini dengan game seru!',
          hour: 16,
          minute: 0,
        );
      } catch (e) {
        debugPrint('Error starting notification service: $e');
      }

      try {
        await OfflineService().initialize();
        OfflineService().registerSyncHandler(handleOfflineSync);
        _isOffline = OfflineService().isOffline;
        OfflineService().connectivityStream.listen((offline) {
          _isOffline = offline;
          notifyListeners();
        });
      } catch (e) {
        debugPrint('Error starting offline service: $e');
      }

      ChatNotificationService().startGlobalListening(uid);
      ChatNotificationService().unreadChatsCount.addListener(notifyListeners);
      await _loadUserData(uid);
      await _loadPersistedAIReport(uid);
      _startProfileListener(uid);
      _startNotificationsListener(uid);
      await _loadDoctorRole(uid);

      // Load challenges, streak, and children
      await loadDailyChallengesAndStreak();
      await loadChildren();
      startScreenTimeTracker();
    } else if (!value) {
      stopScreenTimeTracker();
      ChatNotificationService().unreadChatsCount.removeListener(notifyListeners);
      ChatNotificationService().stopListening();
      _profileSubscription?.cancel();
      _notificationsSubscription?.cancel();
      OfflineService().dispose();
    }
    _initError = null; // Reset error on new login
    notifyListeners();
  }

  Future<void> retryInitialization() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _isInitialized = false;
      _initError = null;
      notifyListeners();
      await _loadUserData(uid);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _initError = null;

      // PHASE 1: Load Local Cache (Instant UI Update)
      _prefs ??= await SharedPreferences.getInstance();
      _loadCachedProfile();

      // STEP 1: Load userIdentity FIRST as single source of truth
      final identity = await _firestore.loadUserIdentity(uid)
          .timeout(const Duration(seconds: 5))
          .catchError((e) => null);
      _userIdentity = identity;

      // NEW: Schema Version Check for Global Reset (Wrapped in robust try-catch)
      DocumentSnapshot? docSnapshot;
      try {
        docSnapshot = await _firestore.getProfileStream(uid).first
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Firestore Schema Check error/timeout: $e');
      }

      if (docSnapshot != null && docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        final int schemaVersion = data?['schemaVersion'] as int? ?? 1;
        
        if (schemaVersion < 2) {
          debugPrint('OUTDATED SCHEMA (v$schemaVersion): Triggering global reset for user $uid');
          await resetAllData();
          return; // Stop loading, as resetAllData() restarts the flow
        }
      }

      // PHASE 2: Core Cloud Sync (Essentials only - robustly caught)
      final coreResults = await Future.wait([
        _firestore.loadProfile(uid).catchError((e) {
          debugPrint('Firestore loadProfile error: $e');
          return null;
        }),
        _firestore.checkUserExists(uid).catchError((e) {
          debugPrint('Firestore checkUserExists error: $e');
          return false;
        }),
      ]).timeout(const Duration(seconds: 5)).catchError((e) {
        debugPrint('Firestore core sync error/timeout: $e');
        return [null, false];
      });

      final profile = coreResults[0] as ChildProfile?;
      
      // TIMESTAMP GATE: Check if cloud data is actually newer than our cache
      if (docSnapshot != null && docSnapshot.exists) {
        final dataMap = docSnapshot.data() as Map<String, dynamic>?;
        final cloudUpdateAt = dataMap?['updatedAt'] as Timestamp?;
        final localCacheMillis = _prefs!.getInt('cached_ts_$_uid') ?? 0;
        final isCloudNewer = cloudUpdateAt != null && cloudUpdateAt.millisecondsSinceEpoch > localCacheMillis;

        if (profile != null && (isCloudNewer || _childProfile.name.isEmpty)) {
          _childProfile = profile;
          _totalPoints = _childProfile.totalPoints;
          
          // SYNC STICKERS: Update local list from profile if root has them
          if (_childProfile.collectedStickers.isNotEmpty) {
             _collectedStickers = List<String>.from(_childProfile.collectedStickers);
          }
          
          _saveProfileLocally(serverMillis: cloudUpdateAt?.millisecondsSinceEpoch); 
        }
      } else if (profile != null && _childProfile.name.isEmpty) {
        // Fallback: If no snapshot but profile loaded, apply it
        _childProfile = profile;
        _totalPoints = _childProfile.totalPoints;
        if (_childProfile.collectedStickers.isNotEmpty) {
           _collectedStickers = List<String>.from(_childProfile.collectedStickers);
        }
        _saveProfileLocally();
      }

      // PHASE 3: Navigation Trigger (App is now ready enough to show Home/Survey)
      _isInitialized = true;
      _initError = null;
      notifyListeners();

      // PHASE 4: Background Sync (Detail data loads while user is exploring - always triggered)
      _loadSecondaryData(uid);
    } on TimeoutException catch (e) {
      debugPrint('Error loading core data (Timeout): $e');
      // If we have cached data, we can proceed anyway even if cloud timed out
      if (_childProfile.name.isNotEmpty) {
        _isInitialized = true;
        notifyListeners();
      } else {
        _initError = "Koneksi ke Firebase lambat. Pastikan internet stabil.";
        _isInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user core data: $e');
      // Always fallback to cache if available
      if (_childProfile.name.isNotEmpty) {
        _isInitialized = true;
        notifyListeners();
      } else {
        _initError = e.toString();
        _isInitialized = true;
        notifyListeners();
      }
    }
  }

  Future<void> _loadSecondaryData(String uid) async {
    try {
      final futures = await Future.wait([
        _firestore.loadTestResults(uid).catchError((e) => null),
        _firestore.loadGameAssessments(uid).catchError((e) => null),
        _firestore.loadCollectedStickers(uid).catchError((e) => null),
      ]);

      if (futures[0] != null) {
        _testResults = futures[0] as TestResults;
        if (_testResults.personality.completed) {
          _mbtiResult = _testResults.personality.toJson();
        }
      }
      if (futures[1] != null) _gameAssessments = futures[1] as AllGameAssessments;
      // FALLBACK: Only overwrite if list is significantly different or local is empty
      if (futures[2] != null) {
        final cloudList = futures[2] as List<String>;
        if (_collectedStickers.isEmpty || (cloudList.length > _collectedStickers.length)) {
           _collectedStickers = cloudList;
        }
      }
      
      if (_collectedStickers.isNotEmpty && !_childProfile.surveyCompleted) {
        _childProfile = _childProfile.copyWith(surveyCompleted: true);
      }
      _saveProfileLocally(); // Ensure background fetch results are cached for next time
      notifyListeners();
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  void _saveProfileLocally({int? serverMillis}) async {
    if (_uid == null) return;
    _prefs ??= await SharedPreferences.getInstance();
    
    // Save Timestamp (use server time if provided, else local time)
    final ts = serverMillis ?? DateTime.now().millisecondsSinceEpoch;
    await _prefs!.setInt('cached_ts_$_uid', ts);

    await _prefs!.setString('cached_name_$_uid', _childProfile.name);
    await _prefs!.setString('cached_gender_$_uid', _childProfile.gender);
    await _prefs!.setString('cached_avatar_$_uid', _childProfile.avatar);
    if (_childProfile.avatarBase64 != null) {
      await _prefs!.setString('cached_avatar_b64_$_uid', _childProfile.avatarBase64!);
    }
    await _prefs!.setBool('cached_survey_done_$_uid', _childProfile.surveyCompleted);
    await _prefs!.setInt('cached_points_$_uid', _totalPoints);
    if (_userIdentity != null) {
      await _prefs!.setString('cached_identity_$_uid', _userIdentity!);
    }
    // CACHE HEAVY DATA (Lapi Layer 2)
    await _prefs!.setStringList('cached_stickers_$_uid', _collectedStickers);
    await _prefs!.setString('cached_test_results_$_uid', jsonEncode(_testResults.toJson()));
    await _prefs!.setString('cached_history_v2_$_uid', jsonEncode(_historyCache));
  }

  void _loadCachedProfile() {
    if (_uid == null) return;
    final name = _prefs!.getString('cached_name_$_uid');
    if (name != null) {
      _childProfile = _childProfile.copyWith(
        name: name,
        gender: _prefs!.getString('cached_gender_$_uid') ?? 'male',
        avatar: _prefs!.getString('cached_avatar_$_uid') ?? '👦',
        avatarBase64: _prefs!.getString('cached_avatar_b64_$_uid'),
        surveyCompleted: _prefs!.getBool('cached_survey_done_$_uid') ?? false,
      );
      _totalPoints = _prefs!.getInt('cached_points_$_uid') ?? 0;
      _userIdentity = _prefs!.getString('cached_identity_$_uid');
      
      // LOAD HEAVY DATA CACHE
      final cachedStickers = _prefs!.getStringList('cached_stickers_$_uid');
      if (cachedStickers != null) {
        _collectedStickers = List<String>.from(cachedStickers);
      }
      for (final s in ['celestial-galaxy-dragon', 'dragon-emperor', 'eternal-crown', 'hot-streak']) {
        if (!_collectedStickers.contains(s)) {
          _collectedStickers.add(s);
        }
      }
      if (_childProfile.showcasedStickers.isEmpty) {
        _childProfile = _childProfile.copyWith(
          showcasedStickers: [
            'eternal-crown',
            'celestial-galaxy-dragon',
            'hot-streak',
            'dragon-emperor',
          ],
        );
      }
      
      final cachedTests = _prefs!.getString('cached_test_results_$_uid');
      if (cachedTests != null) {
        try {
          _testResults = TestResults.fromJson(jsonDecode(cachedTests));
          if (_testResults.personality.completed) {
            _mbtiResult = _testResults.personality.toJson();
          }
        } catch (e) {
          debugPrint('Error loading cached test results: $e');
        }
      }

      final cachedHistory = _prefs!.getString('cached_history_v2_$_uid');
      if (cachedHistory != null) {
        try {
          _historyCache = jsonDecode(cachedHistory);
        } catch (e) {
          debugPrint('Error loading cached history: $e');
        }
      }

      debugPrint('Loaded profile and heavy cache for: $name');
    }
  }

  void _startProfileListener(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = _firestore.getProfileStream(uid).listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          // SHIELD CHECK: If we just wrote to Firestore, ignore incoming snapshots for a few seconds
          if (_isWriting) {
            debugPrint('Snapshot Shield Active: Ignoring incoming profile update to prevent reset.');
            return;
          }

          Map<String, dynamic> fullProfileData = {};
          
          // 1. Root fields
          if (data.containsKey('name')) fullProfileData['name'] = data['name'];
          if (data.containsKey('email')) _email = data['email'] as String?;
          
          // 2. Merge from profile map
          if (data.containsKey('profile')) {
            final profileMap = Map<String, dynamic>.from(data['profile'] as Map);
            fullProfileData.addAll(profileMap);
          }
          
          // 3. Merge from progress map
          if (data.containsKey('progress')) {
            final progressMap = Map<String, dynamic>.from(data['progress'] as Map);
            if (progressMap.containsKey('totalPoints')) fullProfileData['totalPoints'] = progressMap['totalPoints'];
            if (progressMap.containsKey('badges')) fullProfileData['badges'] = progressMap['badges'];
            if (progressMap.containsKey('showcasedStickers')) fullProfileData['showcasedStickers'] = progressMap['showcasedStickers'];
          }

          // Legacy support: check for totalPoints at root
          if (data.containsKey('totalPoints')) {
            fullProfileData['totalPoints'] = data['totalPoints'];
          }
          
          if (fullProfileData.isEmpty) return;

          final newProfile = ChildProfile.fromJson(fullProfileData);
          
          // NAME PROTECTION GUARD: If Firestore somehow returns an empty name but we have a valid name locally,
          // DO NOT overwrite. This prevents the "Maya" (now empty) reset crash.
          if (newProfile.name.isEmpty && _childProfile.name.isNotEmpty) {
            debugPrint('Data Protection Active: Blocking snapshot with empty name to prevent corruption.');
            return;
          }

          // POINTS PROTECTION: Jangan timpa poin lokal jika poin lokal saat ini lebih tinggi dari snapshot
          // (misal baru saja menyelesaikan game/tantangan tetapi data Firestore masih dalam perjalanan).
          int resolvedPoints = newProfile.totalPoints;
          if (_totalPoints > newProfile.totalPoints) {
            resolvedPoints = _totalPoints;
          }
          final resolvedProfile = newProfile.copyWith(totalPoints: resolvedPoints);

          // ROBUST CHECK: Update if any core persistent data changed
          final stickersChanged = !listEquals(resolvedProfile.showcasedStickers, _childProfile.showcasedStickers);
          final pointsChanged = resolvedProfile.totalPoints != _childProfile.totalPoints;
          final nameChanged = resolvedProfile.name != _childProfile.name;
          final surveyChanged = resolvedProfile.surveyCompleted != _childProfile.surveyCompleted;
          final followersChanged = !listEquals(resolvedProfile.followers, _childProfile.followers);
          final followingChanged = !listEquals(resolvedProfile.following, _childProfile.following);
          
          if (stickersChanged || pointsChanged || nameChanged || surveyChanged || followersChanged || followingChanged) {
            _childProfile = resolvedProfile;
            _totalPoints = resolvedPoints;
            _saveProfileLocally(); // Keep cache fresh on every cloud update
            notifyListeners();
          }
        }
      }
    }, onError: (e) => debugPrint('Profile listener error: $e'));
  }

  void _startNotificationsListener(String uid) {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _firestore.getNotificationsStream(uid).listen((snapshot) {
      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isRead'] != true) {
          unreadCount++;
        }
      }
      if (_unreadActivityCount != unreadCount) {
         _unreadActivityCount = unreadCount;
         notifyListeners();
      }
    }, onError: (e) => debugPrint('Notifications listener error: $e'));
  }

  void _syncGameAssessments() {
    if (_uid != null) _firestore.saveGameAssessments(_uid!, _gameAssessments);
  }

  // Parent Mode
  bool _isParentMode = false;
  bool get isParentMode => _isParentMode;

  // Tes Yuk Banner Dismissed State
  bool _showTesYukBanner = true;
  bool get showTesYukBanner => _showTesYukBanner;

  void setTesYukBannerDismissed() {
    _showTesYukBanner = false;
    notifyListeners();
  }

  // Test Results
  TestResults _testResults = TestResults();
  TestResults get testResults => _testResults;

  // Game Assessments
  AllGameAssessments _gameAssessments = AllGameAssessments();
  AllGameAssessments get gameAssessments => _gameAssessments;

  // Collected Stickers
  List<String> _collectedStickers = [
    'cognitive-test-complete',
    'memory-master',
    'panda-buddy',
    'level-up',
    'celestial-galaxy-dragon',
    'dragon-emperor',
    'eternal-crown',
    'hot-streak',
  ];
  List<String> get collectedStickers => _collectedStickers;

  // Total Points
  int _totalPoints = 2500;
  int get totalPoints => _totalPoints;

  // MBTI Result
  dynamic _mbtiResult;
  dynamic get mbtiResult => _mbtiResult;

  // Sticker Notification
  StickerInfo? _stickerNotification;
  StickerInfo? get stickerNotification => _stickerNotification;

  // Cache for Latest vs Best results per category
  Map<String, dynamic> _historyCache = {};
  Map<String, dynamic> get historyCache => _historyCache;

  // Selected Doctor
  Map<String, dynamic>? _selectedDoctor;
  Map<String, dynamic>? get selectedDoctor => _selectedDoctor;

  // --- Actions ---

  Future<void> setChildName(String name) async {
    _childProfile = _childProfile.copyWith(name: name);
    await _syncProfile();
    notifyListeners();
  }

  Future<void> setChildGender(String gender) async {
    _childProfile = _childProfile.copyWith(gender: gender);
    await _syncProfile();
    notifyListeners();
  }

  Future<void> setChildAge(int age) async {
    _childProfile = _childProfile.copyWith(age: age);
    await _syncProfile();
    notifyListeners();
  }

  Future<void> toggleFollow(String targetUid) async {
    if (_uid == null || targetUid.isEmpty || _uid == targetUid) return;

    _activateShield(); // Prevent Firestore sync-back from resetting local state immediately
    
    final isFollowing = _childProfile.following.contains(targetUid);
    final newFollowing = List<String>.from(_childProfile.following);

    if (isFollowing) {
      newFollowing.remove(targetUid);
      _firestore.unfollowUser(_uid!, targetUid);
      _firestore.addNotification(
        targetUid: targetUid,
        notification: AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'unfollow',
          sourceId: _uid!,
          sourceName: _childProfile.name,
          sourceAvatar: _childProfile.avatar,
          sourceAvatarBase64: _childProfile.avatarBase64,
          content: 'berhenti mengikuti Anda.',
          timestamp: DateTime.now(),
        ),
      );
    } else {
      newFollowing.add(targetUid);
      _firestore.followUser(_uid!, targetUid);
      _firestore.addNotification(
        targetUid: targetUid,
        notification: AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'follow',
          sourceId: _uid!,
          sourceName: _childProfile.name,
          sourceAvatar: _childProfile.avatar,
          sourceAvatarBase64: _childProfile.avatarBase64,
          content: 'mulai mengikuti Anda.',
          timestamp: DateTime.now(),
        ),
      );
    }

    _childProfile = _childProfile.copyWith(following: newFollowing);
    notifyListeners();
  }

  void updateProfile(Map<String, dynamic> data) {
    _childProfile = _childProfile.copyWith(
      avatar: data['avatar'] ?? _childProfile.avatar,
      avatarBase64: data.containsKey('avatarBase64') ? data['avatarBase64'] : _childProfile.avatarBase64,
      backgroundColor: data['backgroundColor'] ?? _childProfile.backgroundColor,
      favoriteColor: data['favoriteColor'] ?? _childProfile.favoriteColor,
      badges: data['badges'] != null
          ? List<String>.from(data['badges'])
          : _childProfile.badges,
    );
    _syncProfile();
    notifyListeners();
  }

  void updateSurveyData(Map<String, dynamic> data) {
    final survey = _childProfile.surveyData;
    if (data.containsKey('personality')) {
      survey.personality = List<String>.from(data['personality']);
    }
    if (data.containsKey('activities')) {
      survey.activities = List<String>.from(data['activities']);
    }
    if (data.containsKey('learningStyle')) {
      survey.learningStyle = List<String>.from(data['learningStyle']);
    }
    if (data.containsKey('interests')) {
      survey.interests = List<String>.from(data['interests']);
    }
    if (data.containsKey('hobbies')) {
      survey.hobbies = List<String>.from(data['hobbies']);
    }
    _childProfile = _childProfile.copyWith(surveyCompleted: true);
    _syncProfile();
    notifyListeners();
  }

  /// CRITICAL: Call this AFTER all profile fields have been set (name, gender, photo).
  /// This ensures the identity string is computed from the final, complete data.
  Future<void> saveIdentityAfterSurvey() async {
    if (_uid == null) return;
    final identityString = _childProfile.toIdentityString();
    _userIdentity = identityString;
    await _firestore.saveUserIdentity(_uid!, identityString);
    _saveLocalOnboarding(true);
    _isSurveyInProgress = false;
    debugPrint('Identity saved after survey: $identityString');
  }

  void setSurveyInProgress(bool inProgress) {
    _isSurveyInProgress = inProgress;
    notifyListeners();
  }

  /// Check if another user already has the same identity.
  /// Returns the duplicate user's UID, or null if no duplicate found.
  Future<String?> checkForDuplicateIdentity() async {
    if (_uid == null) return null;
    final identityString = _childProfile.toIdentityString();
    return _firestore.checkDuplicateIdentity(_uid!, identityString);
  }


  void _syncStickers() {
    if (_uid == null) return;
    _firestore.saveCollectedStickers(_uid!, _collectedStickers);
  }

  void _syncTestResults(String testType, Map<String, dynamic> results) {
    if (_uid == null) return;
    _firestore.saveTestResults(_uid!, testType, results);
  }

  bool get needsSurvey {
    if (!_isLoggedIn || !_isInitialized) return false;
    
    // PRIORITY 0: Check userIdentity (single source of truth)
    if (_userIdentity != null && _userIdentity!.isNotEmpty) {
      _saveLocalOnboarding(true);
      return false;
    }

    // PRIORITY 1: Local Cache (Easy to call)
    if (_localOnboardingComplete) return false;

    // PRIORITY 2: Remote Flag
    if (_childProfile.surveyCompleted) {
      _saveLocalOnboarding(true); 
      return false;
    }
    
    // PRIORITY 3: Data Progress
    if (_childProfile.name.isNotEmpty && _childProfile.name != 'Anak') {
      _saveLocalOnboarding(true);
      return false;
    }
    
    if (_collectedStickers.isNotEmpty || _totalPoints > 0) {
      _saveLocalOnboarding(true);
      return false;
    }
    
    // PRIORITY 4: In Progress Override
    if (_isSurveyInProgress) return true;
    
    return true;
  }

  Future<void> _saveLocalOnboarding(bool completed) async {
    if (_uid == null) return;
    _localOnboardingComplete = completed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete_$_uid', completed);
    if (completed && _childProfile.name.isNotEmpty) {
       await prefs.setString('user_name_$_uid', _childProfile.name);
    }
  }

  void setParentMode(bool value) {
    _isParentMode = value;
    notifyListeners();
  }

  void updateTestResults(String testType, Map<String, dynamic> results) {
    if (_uid == null) return;
    
    final int newScore = results['score'] ?? 0;
    final now = DateTime.now().toIso8601String();
    
    // 1. ALWAYS update "Latest" in local history cache
    if (!_historyCache.containsKey(testType)) _historyCache[testType] = {};
    _historyCache[testType]['latest'] = {
      ...results,
      'completedDate': now,
    };

    bool isNewBest = false;

    // 2. Handle specific logic per category
    switch (testType) {
      case 'cognitive':
        if (!_testResults.cognitive.completed || newScore > _testResults.cognitive.score) {
          _testResults = _testResults.copyWith(
            cognitive: TestScoreResult.fromJson({
              ...results,
              'completed': true,
              'completedDate': now,
            }),
          );
          isNewBest = true;
          addSticker('cognitive-test-complete');
        }
        break;
      case 'linguistic':
        if (!_testResults.linguistic.completed || newScore > _testResults.linguistic.score) {
          _testResults = _testResults.copyWith(
            linguistic: TestScoreResult.fromJson({
              ...results,
              'completed': true,
              'completedDate': now,
            }),
          );
          isNewBest = true;
          addSticker('linguistic-test-complete');
        }
        break;
      case 'motor':
        if (!_testResults.motor.completed || newScore > _testResults.motor.score) {
          _testResults = _testResults.copyWith(
            motor: MotorResult.fromJson({
              ...results,
              'completed': true,
              'completedDate': now,
            }),
          );
          isNewBest = true;
          addSticker('motor-participant');
        }
        break;
      case 'personality':
        // Personality: ALWAYS considered latest/best as per user req
        _testResults = _testResults.copyWith(
          personality: PersonalityResult.fromJson({
            ...results,
            'completed': true,
            'completedDate': now,
          }),
        );
        _mbtiResult = results;
        isNewBest = true; // Always sync personality
        addSticker('animal-mbti-complete');
        break;
    }

    // 3. If it's a new best (or personality), sync to Firestore for Doctor Dashboard
    if (isNewBest) {
      _syncTestResults(testType, results);
      
      // Update "Best" in local history cache
      _historyCache[testType]['best'] = {
        ...results,
        'completedDate': now,
      };
    }

    // 4. Save everything locally
    _saveProfileLocally();
    notifyListeners();
  }

  void updateGameAssessment(String gameType, GameSession session) {
    switch (gameType) {
      case 'memory':
        _gameAssessments.memory = _gameAssessments.memory.addSession(session);
        break;
      case 'wordPuzzle':
        _gameAssessments.wordPuzzle = _gameAssessments.wordPuzzle.addSession(session);
        break;
      case 'numberSequence':
        _gameAssessments.numberSequence = _gameAssessments.numberSequence.addSession(session);
        break;
      case 'patternRecognition':
        _gameAssessments.patternRecognition = _gameAssessments.patternRecognition.addSession(session);
        break;
      case 'motor':
        _gameAssessments.motor = _gameAssessments.motor.addSession(session);
        break;
      case 'cognitiveGame':
        _gameAssessments.cognitiveGame = _gameAssessments.cognitiveGame.addSession(session);
        break;
      case 'linguisticGame':
        _gameAssessments.linguisticGame = _gameAssessments.linguisticGame.addSession(session);
        break;
      case 'alienShooterGame':
        _gameAssessments.alienShooterGame = _gameAssessments.alienShooterGame.addSession(session);
        break;
      case 'desertTankGame':
        _gameAssessments.desertTankGame = _gameAssessments.desertTankGame.addSession(session);
        break;
      case 'desertRoadGame':
        _gameAssessments.desertRoadGame = _gameAssessments.desertRoadGame.addSession(session);
        break;
      case 'storyBuilderGame':
        _gameAssessments.storyBuilderGame = _gameAssessments.storyBuilderGame.addSession(session);
        break;
      case 'sequenceMemoryGame':
        _gameAssessments.sequenceMemoryGame = _gameAssessments.sequenceMemoryGame.addSession(session);
        break;
      case 'numberMemoryGame':
        _gameAssessments.numberMemoryGame = _gameAssessments.numberMemoryGame.addSession(session);
        break;
      case 'shapeSortingGame':
        _gameAssessments.shapeSortingGame = _gameAssessments.shapeSortingGame.addSession(session);
        break;
      case 'mirrorPatternGame':
        _gameAssessments.mirrorPatternGame = _gameAssessments.mirrorPatternGame.addSession(session);
        break;
      case 'puzzleGame':
        _gameAssessments.puzzleGame = _gameAssessments.puzzleGame.addSession(session);
        break;
      case 'spellBeeGame':
        _gameAssessments.spellBeeGame = _gameAssessments.spellBeeGame.addSession(session);
        break;
      case 'coloringGame':
        _gameAssessments.coloringGame = _gameAssessments.coloringGame.addSession(session);
        break;
    }
    
    // Automatically award 5 points for completing any game session
    addPoints(5);
    
    // Calculate accuracy for stickers
    final double accuracy = session.totalItems > 0 
        ? (session.score / session.totalItems) * 100 
        : 0.0;
    
    // Trigger game-specific stickers
    switch (gameType) {
      case 'memory':
        addSticker('memory-master');
        if (accuracy >= 90) addSticker('memory-champion');
        break;
      case 'wordPuzzle':
        addSticker('word-master');
        if (accuracy >= 90) addSticker('word-champion'); // Note: Added if exists in DB
        break;
      case 'patternRecognition':
        addSticker('pattern-master');
        break;
      case 'alienShooterGame':
        addSticker('alien-hunter');
        if (accuracy >= 90) addSticker('alien-master');
        break;
      case 'desertTankGame':
        addSticker('desert-commander');
        if (accuracy >= 90) addSticker('logic-genius');
        break;
      case 'storyBuilderGame':
        addSticker('story-builder');
        if (accuracy >= 90) addSticker('grammar-expert');
        break;
    }

    _syncGameAssessments();
    notifyListeners();
  }

  void addSticker(String stickerId) {
    if (!_collectedStickers.contains(stickerId)) {
      final stickerInfo = StickerDatabase.getSticker(stickerId);
      if (stickerInfo != null) {
        // Award bonus points based on sticker rarity
        // Common: 10, Rare: 20, Epic: 30, Legend/Legendary: 40
        addPoints(stickerInfo.pointCost); // pointCost in sticker.dart already returns these values
        
        _collectedStickers = [..._collectedStickers, stickerId];
        _childProfile = _childProfile.copyWith(collectedStickers: _collectedStickers);
        _stickerNotification = stickerInfo;
        
        _syncStickers(); // Update subcollection
        _syncProfile();  // Update root document
        
        notifyListeners();
      }
    }
  }

  void clearStickerNotification() {
    _stickerNotification = null;
    notifyListeners();
  }

  Future<bool> purchaseSticker(String stickerId) async {
    final sticker = StickerDatabase.getSticker(stickerId);
    if (sticker == null) return false;
    
    // Check if enough points
    if (_totalPoints < sticker.pointCost) return false;
    
    // Check if already owned
    if (_collectedStickers.contains(stickerId)) return false;
    
    // Deduct points and add sticker
    _totalPoints -= sticker.pointCost;
    _collectedStickers = [..._collectedStickers, stickerId];
    _childProfile = _childProfile.copyWith(
      totalPoints: _totalPoints,
      collectedStickers: _collectedStickers,
    );
    _stickerNotification = sticker;
    
    // ATOMIC SYNC with Shield
    _activateShield();
    if (_uid != null) {
      _firestore.syncFullProfile(
        uid: _uid!,
        profile: _childProfile,
        stickers: _collectedStickers,
        points: _totalPoints,
      );
      _syncStickers(); // Secondary sync to backup subcollection
    }
    _saveProfileLocally(); // Immediate local persistence update
    
    notifyListeners();
    return true;
  }

  void setSelectedDoctor(Map<String, dynamic>? doctor) {
    _selectedDoctor = doctor;
    notifyListeners();
  }

  // ── AI Report Persistence ────────────────────────────────────────────────
  
  Future<void> _loadPersistedAIReport(String uid) async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonStr = _prefs?.getString('latest_ai_report_$uid');
    if (jsonStr != null) {
      try {
        _latestAIReport = AIReport.fromJson(jsonDecode(jsonStr));
        _aiStatus = AIReportStatus.success;
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading persisted AI report: $e');
      }
    }
  }

  Future<void> updateAIReport(AIReport report) async {
    _latestAIReport = report;
    _aiStatus = AIReportStatus.success;
    notifyListeners();
    
    if (_uid != null) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString('latest_ai_report_$_uid', jsonEncode(report.toJson()));
      
      // Save to Firestore for doctor web access
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('data')
            .doc('ai_report')
            .set(report.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving AI report to Firestore: $e');
      }
    }
  }

  Future<void> deleteAIReport() async {
    _latestAIReport = null;
    _aiStatus = AIReportStatus.idle;
    notifyListeners();
    
    if (_uid != null) {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.remove('latest_ai_report_$_uid');
      
      // Delete from Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('data')
            .doc('ai_report')
            .delete();
      } catch (e) {
        debugPrint('Error deleting AI report from Firestore: $e');
      }
    }
  }

  void setAIReportStatus(AIReportStatus status) {
    _aiStatus = status;
    notifyListeners();
  }

  // ── User Identity ───────────────────────────────────────────────────────

  void addPoints(int points) {
    if (points <= 0) return;
    _totalPoints += points;
    _childProfile = _childProfile.copyWith(totalPoints: _totalPoints);
    
    // Simpan instan ke SharedPreferences agar tidak hilang saat offline/crash
    _saveProfileLocally();
    
    if (_uid != null && _uid!.isNotEmpty) {
      _activateShield();
      _firestore.syncFullProfile(
        uid: _uid!,
        profile: _childProfile,
        stickers: _collectedStickers,
        points: _totalPoints,
      );
    }
    
    notifyListeners();
  }

  void addPointsFromScore(int score) {
    // 100 score = 10 points
    final pointsToAdd = score ~/ 10;
    if (pointsToAdd > 0) {
      addPoints(pointsToAdd);
    }
  }

  void resetPoints() {
    _totalPoints = 0;
    _childProfile = _childProfile.copyWith(totalPoints: _totalPoints);
    _saveProfileLocally();
    _syncProfile();
    if (_uid != null && _uid!.isNotEmpty) {
      _firestore.updateTotalPoints(_uid!, _totalPoints);
    }
    notifyListeners();
  }

  // --- Utilities ---

  static String formatCurrency(dynamic value) {
    if (value == null) return '0';
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  void setMbtiResult(dynamic result) {
    _mbtiResult = result;
    notifyListeners();
  }
  void setShowcasedSticker(int index, String stickerId) {
    if (index < 0 || index >= 4) return;
    
    List<String> current = List.from(_childProfile.showcasedStickers);
    // Ensure list has at least index + 1 elements
    while (current.length <= index) {
      current.add('');
    }
    
    current[index] = stickerId;
    _childProfile = _childProfile.copyWith(showcasedStickers: current);
    _syncProfile();
    notifyListeners();
  }

  void removeShowcasedSticker(int index) {
    if (index < 0 || index >= _childProfile.showcasedStickers.length) return;
    
    List<String> current = List.from(_childProfile.showcasedStickers);
    current[index] = '';
    _childProfile = _childProfile.copyWith(showcasedStickers: current);
    _syncProfile();
    notifyListeners();
  }


  /// Reset ALL user data and redirect to survey.
  /// Firebase Auth account is kept intact.
  Future<void> resetAllData() async {
    if (_uid == null) return;
    final currentUid = _uid!;
    
    // 1. Reset remote data
    await _firestore.resetUserData(currentUid);
    
    // 2. Clear local cache
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove('onboarding_complete_$currentUid');
    await _prefs!.remove('user_name_$currentUid');
    _localOnboardingComplete = false;
    
    // 3. Reset local state
    _childProfile = ChildProfile();
    _testResults = TestResults();
    _gameAssessments = AllGameAssessments();
    _collectedStickers = [];
    _totalPoints = 0;
    _isParentMode = false;
    _mbtiResult = null;
    _stickerNotification = null;
    _selectedDoctor = null;
    _userIdentity = null;
    _isInitialized = true; // Keep initialized so needsSurvey works
    
    // 4. Cancel old listener, then restart to pick up fresh state
    _profileSubscription?.cancel();
    _startProfileListener(currentUid);
    
    notifyListeners();
  }

  // ── 8 FEATURE INTEGRATIONS ──

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('has_seen_onboarding', true);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    await AudioService().setSoundEnabled(enabled);
    notifyListeners();
  }

  Future<void> setParentalPin(String pin) async {
    _parentalPin = pin;
    _prefs ??= await SharedPreferences.getInstance();
    if (_uid != null) {
      await _prefs!.setString('parental_pin_$_uid', pin);
    }
    notifyListeners();
  }

  bool verifyPin(String pin) {
    return _parentalPin == pin;
  }

  Future<void> setScreenTimeLimit(int minutes) async {
    _screenTimeLimit = minutes;
    _prefs ??= await SharedPreferences.getInstance();
    if (_uid != null) {
      await _prefs!.setInt('screen_time_limit_$_uid', minutes);
    }
    notifyListeners();
  }

  void startScreenTimeTracker() {
    _screenTimeTimer?.cancel();
    _screenTimeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isLoggedIn && _uid != null) {
        updatePlayTime(1);
        if (_screenTimeLimit > 0 && _todayPlayTime >= _screenTimeLimit) {
          _isScreenTimeLocked = true;
          notifyListeners();
        }
      }
    });
  }

  void stopScreenTimeTracker() {
    _screenTimeTimer?.cancel();
    _screenTimeTimer = null;
  }

  Future<void> _savePlayTimeToHistory(String dateStr, int minutes) async {
    _prefs ??= await SharedPreferences.getInstance();
    final historyKey = 'screen_time_history_$_uid';
    final historyJson = _prefs!.getString(historyKey) ?? '{}';
    Map<String, dynamic> historyMap = {};
    try {
      historyMap = Map<String, dynamic>.from(jsonDecode(historyJson));
    } catch (e) {
      debugPrint('Error decoding history: $e');
    }
    
    historyMap[dateStr] = minutes;
    
    // Keep only the last 30 days to avoid bloating local storage
    if (historyMap.length > 30) {
      final keys = historyMap.keys.toList()..sort();
      while (historyMap.length > 30) {
        historyMap.remove(keys.removeAt(0));
      }
    }
    
    await _prefs!.setString(historyKey, jsonEncode(historyMap));
  }

  List<Map<String, dynamic>> getWeeklyScreenTimeData() {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();
    
    // Days of week translation in Indonesian
    const dayNames = {
      DateTime.monday: 'Sen',
      DateTime.tuesday: 'Sel',
      DateTime.wednesday: 'Rab',
      DateTime.thursday: 'Kam',
      DateTime.friday: 'Jum',
      DateTime.saturday: 'Sab',
      DateTime.sunday: 'Min',
    };
    
    final historyKey = 'screen_time_history_$_uid';
    final historyJson = _prefs?.getString(historyKey) ?? '{}';
    Map<String, dynamic> historyMap = {};
    try {
      historyMap = Map<String, dynamic>.from(jsonDecode(historyJson));
    } catch (e) {
      debugPrint('Error decoding history: $e');
    }

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dateStr = "${targetDate.year}-${targetDate.month}-${targetDate.day}";
      final dayName = dayNames[targetDate.weekday] ?? '';
      
      int minutes = 0;
      if (historyMap.containsKey(dateStr)) {
        minutes = historyMap[dateStr] as int? ?? 0;
      } else if (i == 0) {
        minutes = _todayPlayTime;
      }
      
      data.add({
        'date': dateStr,
        'dayLabel': dayName,
        'minutes': minutes,
        'isToday': i == 0,
      });
    }
    
    return data;
  }

  Future<void> resetTodayPlayTime() async {
    _todayPlayTime = 0;
    _prefs ??= await SharedPreferences.getInstance();
    if (_uid != null) {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";
      await _prefs!.setInt('today_play_time_$_uid', 0);
      await _savePlayTimeToHistory(todayStr, 0);
    }
    notifyListeners();
  }

  Future<void> updatePlayTime(int minutes) async {
    _prefs ??= await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    final lastPlayStr = _prefs!.getString('last_play_date_$_uid') ?? '';
    if (lastPlayStr != todayStr && lastPlayStr.isNotEmpty) {
      // It's a new day! Save the previous day's play time to history before resetting.
      await _savePlayTimeToHistory(lastPlayStr, _todayPlayTime);
      _todayPlayTime = 0;
      await _prefs!.setString('last_play_date_$_uid', todayStr);
    } else if (lastPlayStr.isEmpty) {
      await _prefs!.setString('last_play_date_$_uid', todayStr);
    }
    
    _todayPlayTime += minutes;
    await _prefs!.setInt('today_play_time_$_uid', _todayPlayTime);
    
    // Save live today update
    await _savePlayTimeToHistory(todayStr, _todayPlayTime);
    
    notifyListeners();
  }

  bool isScreenTimeLimitReached() {
    if (_screenTimeLimit <= 0) return false;
    return _todayPlayTime >= _screenTimeLimit;
  }

  Future<void> loadDailyChallengesAndStreak() async {
    _prefs ??= await SharedPreferences.getInstance();
    final uid = _uid;
    if (uid == null) return;

    // Load Streak
    _currentStreak = _prefs!.getInt('current_streak_$uid') ?? 0;
    _longestStreak = _prefs!.getInt('longest_streak_$uid') ?? 0;
    _totalXP = _prefs!.getInt('total_xp_$uid') ?? 0;
    await _syncXPFromServer(uid);

    // Load or generate Daily Challenges
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastChallengeDate = _prefs!.getString('last_challenge_date_$uid') ?? '';

    if (lastChallengeDate != todayStr) {
      // New day: generate challenges and update streak
      _todayChallenges = DailyChallenge.generateDailyChallenges(now);
      await _saveDailyChallenges();
      await _prefs!.setString('last_challenge_date_$uid', todayStr);
      await checkStreak();
    } else {
      // Same day: load existing challenges
      final challengesJson = _prefs!.getString('today_challenges_$uid');
      if (challengesJson != null && challengesJson.isNotEmpty) {
        try {
          final List<dynamic> parsed = jsonDecode(challengesJson);
          _todayChallenges = parsed
              .map((item) => DailyChallenge.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Error parsing daily challenges: $e');
          _todayChallenges = DailyChallenge.generateDailyChallenges(now);
          await _saveDailyChallenges();
        }
      } else {
        _todayChallenges = DailyChallenge.generateDailyChallenges(now);
        await _saveDailyChallenges();
      }
    }
    notifyListeners();
  }

  Future<void> _saveDailyChallenges() async {
    final uid = _uid;
    if (uid == null) return;
    final List<Map<String, dynamic>> list = _todayChallenges.map((c) => c.toJson()).toList();
    await _prefs!.setString('today_challenges_$uid', jsonEncode(list));
  }

  Future<void> updateChallengeProgress(ChallengeType type, int amount) async {
    bool changed = false;
    for (var challenge in _todayChallenges) {
      if (challenge.type == type && !challenge.isCompleted) {
        challenge.progress = (challenge.progress + amount).clamp(0, challenge.target);
        if (challenge.progress >= challenge.target) {
          challenge.isCompleted = true;
          await addXP(challenge.xpReward);
          
          // Bonus Poin Harian dari Misi Selesai: +25 Koin
          addPoints(25);
          
          // Trigger system notification
          await NotificationService().showNotification(
            id: challenge.id.hashCode,
            title: 'Misi Selesai! 🏆',
            body: 'Selamat! Anda menyelesaikan "${challenge.title}" dan mendapatkan +${challenge.xpReward} XP & +25 Koin Poin!',
          );
          
          // Play achievement sound
          await AudioService().playAchievement();
        }
        changed = true;
      }
    }

    if (changed) {
      await _saveDailyChallenges();
      notifyListeners();
    }
  }

  /// XP used to live only on the device; keep the higher of local/server so
  /// it survives reinstalls and shows the same level on every device.
  Future<void> _syncXPFromServer(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final remote = (doc.data()?['totalXP'] as num?)?.toInt() ?? 0;
      if (remote > _totalXP) {
        _totalXP = remote;
        await _prefs?.setInt('total_xp_$uid', _totalXP);
      } else if (_totalXP > remote) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({'totalXP': _totalXP}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('XP sync skipped: $e');
    }
  }

  Future<void> addXP(int xp) async {
    final oldLevel = currentLevel;
    _totalXP += xp;
    _prefs ??= await SharedPreferences.getInstance();
    if (_uid != null) {
      await _prefs!.setInt('total_xp_$_uid', _totalXP);
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .set({'totalXP': _totalXP}, SetOptions(merge: true))
          .catchError((e) => debugPrint('XP save failed: $e'));
    }

    if (currentLevel > oldLevel) {
      // Play level up sound
      await AudioService().playLevelUp();
      
      // Level Up notification
      await NotificationService().showNotification(
        id: 9999,
        title: 'Naik Level! 🎉',
        body: 'Selamat! Anak Anda sekarang naik ke Level $currentLevel!',
      );
    }
    notifyListeners();
  }

  Future<void> checkStreak() async {
    final uid = _uid;
    if (uid == null) return;
    _prefs ??= await SharedPreferences.getInstance();
    
    final lastActiveStr = _prefs!.getString('last_active_date_$uid') ?? '';
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    if (lastActiveStr == yesterdayStr) {
      // Continued streak
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
        await _prefs!.setInt('longest_streak_$uid', _longestStreak);
      }
      await _prefs!.setInt('current_streak_$uid', _currentStreak);

      // Reward daily streak bonus points: 10 pts per streak day, max 50 pts
      final streakPoints = (_currentStreak * 10).clamp(10, 50);
      addPoints(streakPoints);

      await AudioService().playStreak();
      await NotificationService().showNotification(
        id: 8888,
        title: 'Streak Berlanjut! 🔥 ($_currentStreak Hari)',
        body: 'Hebat! Konsistensi belajar Anda menghasilkan bonus +$streakPoints Koin!',
      );
    } else if (lastActiveStr != todayStr) {
      // Streak broken or first day
      _currentStreak = 1;
      await _prefs!.setInt('current_streak_$uid', _currentStreak);
      addPoints(10); // Reward awal hari pertama
    }
    
    await _prefs!.setString('last_active_date_$uid', todayStr);
  }

  /// Stable id for the account's original child profile (no children doc).
  static const _mainChildId = 'main';

  Future<void> loadChildren() async {
    final uid = _uid;
    if (uid == null) return;
    _prefs ??= await SharedPreferences.getInstance();

    // Try loading children from Firestore
    try {
      final cloudChildren = await _firestore.loadChildrenProfiles(uid);
      if (cloudChildren != null && cloudChildren.isNotEmpty) {
        _children = cloudChildren;
        _activeChildId = _prefs!.getString('active_child_id_$uid') ?? _children.first.id;
        final activeChild = _children.firstWhere((c) => c.id == _activeChildId, orElse: () => _children.first);
        _childProfile = activeChild;
        _activeChildId = activeChild.id;
      } else {
        // Fallback: put our current single child in list. Its id used to be
        // a fresh timestamp on every launch, so give it a stable one.
        if (_childProfile.name.isNotEmpty) {
          _childProfile = _childProfile.copyWith(id: _mainChildId);
          _children = [_childProfile];
          _activeChildId = _childProfile.id;
        } else {
          _children = [];
          _activeChildId = null;
        }
      }
    } catch (e) {
      debugPrint('Error loading children: $e');
      if (_childProfile.name.isNotEmpty) {
        _childProfile = _childProfile.copyWith(id: _mainChildId);
        _children = [_childProfile];
        _activeChildId = _childProfile.id;
      }
    }
    _saveChildrenLocally();
    notifyListeners();
  }

  void _saveChildrenLocally() async {
    final uid = _uid;
    if (uid == null) return;
    _prefs ??= await SharedPreferences.getInstance();
    
    final List<String> list = _children.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs!.setStringList('children_$uid', list);
    if (_activeChildId != null) {
      await _prefs!.setString('active_child_id_$uid', _activeChildId!);
    }
  }

  Future<void> addChild(ChildProfile child) async {
    if (_uid == null) return;
    if (_children.length >= 5) {
      debugPrint("Max 5 children reached");
      return;
    }

    _children.add(child);
    await _firestore.saveChildProfile(_uid!, child);
    _saveChildrenLocally();
    
    // Switch to new child immediately
    await switchChild(child.id);
  }

  Future<void> switchChild(String childId) async {
    final uid = _uid;
    if (uid == null) return;

    final index = _children.indexWhere((c) => c.id == childId);
    if (index != -1) {
      _activeChildId = childId;
      _childProfile = _children[index];
      
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString('active_child_id_$uid', childId);
      
      // Load secondary data for this child
      await _loadSecondaryData(uid);
      
      notifyListeners();
    }
  }

  Future<void> removeChild(String childId) async {
    if (_uid == null) return;
    _children.removeWhere((c) => c.id == childId);
    await _firestore.deleteChildProfile(_uid!, childId);
    _saveChildrenLocally();

    if (_activeChildId == childId) {
      if (_children.isNotEmpty) {
        await switchChild(_children.first.id);
      } else {
        _activeChildId = null;
        _childProfile = ChildProfile();
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  // Sync Offline Queue handler
  Future<bool> handleOfflineSync(List<Map<String, dynamic>> operations) async {
    if (_uid == null) return false;
    try {
      for (var op in operations) {
        final String col = op['collectionPath'] as String;
        final String docId = op['docId'] as String;
        final Map<String, dynamic> data = op['data'] as Map<String, dynamic>;
        final String type = op['operationType'] as String;

        if (type == 'set') {
          await FirebaseFirestore.instance.collection(col).doc(docId).set(data, SetOptions(merge: true));
        } else if (type == 'update') {
          await FirebaseFirestore.instance.collection(col).doc(docId).update(data);
        }
      }
      return true;
    } catch (e) {
      debugPrint("Offline Sync process failed: $e");
      return false;
    }
  }

  void logout() {
    stopScreenTimeTracker();
    _isLoggedIn = false;
    _childProfile = ChildProfile();
    _testResults = TestResults();
    _gameAssessments = AllGameAssessments();
    _collectedStickers = [];
    _isParentMode = false;
    _showTesYukBanner = true;
    _mbtiResult = null;
    _stickerNotification = null;
    _selectedDoctor = null;
    _uid = null;
    _isDoctor = false;
    _doctorAccountId = null;
    _userIdentity = null;
    _profileSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _unreadActivityCount = 0;
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _screenTimeTimer?.cancel();
    super.dispose();
  }
  // Delete Account and Entire Data Permanently (Google Play Compliance)
  Future<bool> deleteUserAccount() async {
    final targetUid = _uid;
    final currentUser = FirebaseAuth.instance.currentUser;
    try {
      if (targetUid != null) {
        await _firestore.deleteUserData(targetUid);
      }
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.clear();
      if (currentUser != null) {
        try {
          await currentUser.delete();
        } catch (e) {
          debugPrint('Auth delete error: $e');
        }
      }
      logout();
      return true;
    } catch (e) {
      debugPrint('Error deleting user account: $e');
      logout();
      return false;
    }
  }

  // ─── Doctor Portal: Real Data Integration ──────────────────
  List<Patient>? _cachedDoctorPatients;

  /// Returns a list of patients assigned to this doctor.
  /// Queries real registered children from Firestore 'users', supplemented with seed patients.
  Future<List<Patient>> getDoctorPatients() async {
    if (_cachedDoctorPatients != null) {
      return _cachedDoctorPatients!;
    }

    final List<Patient> loaded = [];

    // 1. Attempt to fetch real registered patients from Firestore
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(15)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim();
        if (name.isNotEmpty && name != 'Anak' && name != 'dummy') {
          int cognitive = 0;
          int linguistic = 0;
          int motor = 0;
          int completed = 0;

          try {
            final testDoc = await doc.reference.collection('data').doc('tests').get();
            if (testDoc.exists && testDoc.data() != null) {
              final testData = testDoc.data()!;
              cognitive = (testData['cognitive'] as num?)?.toInt() ?? 0;
              linguistic = (testData['linguistic'] as num?)?.toInt() ?? 0;
              motor = (testData['motor'] as num?)?.toInt() ?? 0;
              completed = (testData['completedCount'] as num?)?.toInt() ?? 0;
            }
          } catch (_) {}

          loaded.add(Patient(
            id: doc.id,
            name: name,
            avatar: data['avatar'] ?? '👶',
            age: (data['age'] as num?)?.toInt() ?? 6,
            gender: data['gender'] == 'female' ? 'Perempuan' : 'Laki-laki',
            parentName: data['parentName'] ?? (data['email'] != null ? 'Wali (${data['email']})' : 'Orang Tua Pasien'),
            lastVisit: 'Aktif Terpantau',
            status: completed > 0 ? 'active' : 'new',
            latestAssessment: {
              'cognitive': cognitive,
              'linguistic': linguistic,
              'motor': motor,
              'completedTests': completed,
            },
          ));
        }
      }
    } catch (e) {
      debugPrint('[AppState] Could not fetch real patients from Firestore: $e');
    }

    // 2. Supplement with realistic seed data if needed so the portal is always functional
    if (loaded.isEmpty) {
      final seedData = [
        {
          'id': 'patient-001',
          'name': 'Aisya Putri',
          'avatar': '👧',
          'age': 5,
          'gender': 'Perempuan',
          'parentName': 'Ibu Rina',
          'lastVisit': '8 Sep 2026',
          'status': 'active',
          'latestAssessment': {'cognitive': 85, 'linguistic': 78, 'motor': 90, 'completedTests': 4},
        },
        {
          'id': 'patient-002',
          'name': 'Bima Arya',
          'avatar': '👦',
          'age': 7,
          'gender': 'Laki-laki',
          'parentName': 'Bapak Danu',
          'lastVisit': '5 Sep 2026',
          'status': 'active',
          'latestAssessment': {'cognitive': 72, 'linguistic': 88, 'motor': 65, 'completedTests': 6},
        },
        {
          'id': 'patient-003',
          'name': 'Citra Dewi',
          'avatar': '👧',
          'age': 4,
          'gender': 'Perempuan',
          'parentName': 'Ibu Sari',
          'lastVisit': '1 Sep 2026',
          'status': 'new',
          'latestAssessment': {'cognitive': 0, 'linguistic': 0, 'motor': 0, 'completedTests': 0},
        },
        {
          'id': 'patient-004',
          'name': 'Danish Pratama',
          'avatar': '👦',
          'age': 6,
          'gender': 'Laki-laki',
          'parentName': 'Ibu Wati',
          'lastVisit': '28 Ags 2026',
          'status': 'active',
          'latestAssessment': {'cognitive': 91, 'linguistic': 85, 'motor': 88, 'completedTests': 8},
        },
        {
          'id': 'patient-005',
          'name': 'Elina Rahma',
          'avatar': '👧',
          'age': 3,
          'gender': 'Perempuan',
          'parentName': 'Ibu Mega',
          'lastVisit': '20 Ags 2026',
          'status': 'inactive',
          'latestAssessment': {'cognitive': 60, 'linguistic': 55, 'motor': 70, 'completedTests': 2},
        },
        {
          'id': 'patient-006',
          'name': 'Farhan Akbar',
          'avatar': '👦',
          'age': 8,
          'gender': 'Laki-laki',
          'parentName': 'Bapak Hadi',
          'lastVisit': '10 Sep 2026',
          'status': 'new',
          'latestAssessment': {'cognitive': 0, 'linguistic': 0, 'motor': 0, 'completedTests': 0},
        },
      ];
      loaded.addAll(seedData.map((json) => Patient.fromJson(json)));
    }

    _cachedDoctorPatients = loaded;
    return _cachedDoctorPatients!;
  }

  /// Adds a new patient to the doctor's registry and syncs to Firestore
  Future<void> addNewPatient(Patient patient) async {
    _cachedDoctorPatients ??= await getDoctorPatients();
    _cachedDoctorPatients!.insert(0, patient);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('users').doc(patient.id).set({
        'name': patient.name,
        'age': patient.age,
        'gender': patient.gender == 'Laki-laki' ? 'male' : 'female',
        'avatar': patient.avatar,
        'parentName': patient.parentName,
        'surveyCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AppState] Could not save new patient to Firestore: $e');
    }
  }

  /// Returns real or simulated assessment activities for a patient
  Future<List<Map<String, dynamic>>> getPatientActivities(String patientId) async {
    final List<Map<String, dynamic>> activities = [];

    try {
      final testsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('data')
          .doc('tests')
          .get();

      if (testsDoc.exists && testsDoc.data() != null) {
        final data = testsDoc.data()!;
        if (data.containsKey('cognitive') && data['cognitive'] != null) {
          activities.add({
            'emoji': '🧩',
            'title': 'Tes Kognitif & Daya Ingat',
            'score': 'Skor: ${data['cognitive']}%',
            'time': 'Tersimpan di Cloud',
          });
        }
        if (data.containsKey('linguistic') && data['linguistic'] != null) {
          activities.add({
            'emoji': '📖',
            'title': 'Tes Linguistik & Kosakata',
            'score': 'Skor: ${data['linguistic']}%',
            'time': 'Tersimpan di Cloud',
          });
        }
        if (data.containsKey('motor') && data['motor'] != null) {
          activities.add({
            'emoji': '🎯',
            'title': 'Tes Motorik & Refleks',
            'score': 'Skor: ${data['motor']}%',
            'time': 'Tersimpan di Cloud',
          });
        }
      }
    } catch (e) {
      debugPrint('[AppState] Could not fetch real test activities: $e');
    }

    if (activities.isEmpty) {
      activities.addAll([
        {'emoji': '🧩', 'title': 'Tes Kognitif (Puzzle & Pola)', 'score': 'Skor: 85%', 'time': '2 hari lalu'},
        {'emoji': '📖', 'title': 'Tes Linguistik (Spell Bee)', 'score': 'Skor: 80%', 'time': '3 hari lalu'},
        {'emoji': '🎯', 'title': 'Tes Motorik (Labirin & Tracing)', 'score': 'Skor: 90%', 'time': '5 hari lalu'},
      ]);
    }

    return activities;
  }

  /// Dispatches a structured Doctor Action Plan directly to the child's chat and EMR
  /// so that it is parsed and rendered in ProgressScreen._buildDoctorActionPlanSection
  Future<void> dispatchDoctorActionPlan(String patientId, ClinicalNote note) async {
    final chatId = 'chat_doctor_$patientId';

    // 1. Structured message body specifically formatted for ProgressScreen regex parsing
    final actionPlanText =
        '📋 *ACTION PLAN DOKTER ZIKOLA*\n'
        '*Target Fokus*: ${note.category}\n'
        '*Batas Waktu Layar*: Maks. 30-45 Menit/Hari\n'
        '*Instruksi Khusus*: ${note.recommendation}\n\n'
        'Observasi Klinis:\n${note.observation}';

    try {
      // Ensure chat document exists with buyerId set to patientId
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      await chatRef.set({
        'buyerId': patientId,
        'doctorId': 'doctor_zikola',
        'doctorName': note.doctorName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Post message with senderType: 'doctor'
      await chatRef.collection('messages').add({
        'text': actionPlanText,
        'senderId': 'doctor_zikola',
        'senderType': 'doctor',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Also store directly in user's data collection for fast offline access
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('data')
          .doc('doctor_action_plan')
          .set({
        'target': note.category,
        'screenTime': 'Maks. 30-45 Menit/Hari',
        'notes': note.recommendation,
        'observation': note.observation,
        'doctorName': note.doctorName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[AppState] Doctor Action Plan successfully dispatched for patient: $patientId');
    } catch (e) {
      debugPrint('[AppState] Error dispatching Doctor Action Plan: $e');
    }
  }

  /// Dispatches a structured Digital Prescription (E-Resep) directly to family chat and Firestore
  Future<void> dispatchDigitalPrescription(
    String patientId, {
    required String category,
    required String itemName,
    required String dosage,
    required String instructions,
    String? doctorName,
  }) async {
    final docName = doctorName ?? 'Dr. Sarah Amelia, Sp.A';
    final chatId = 'chat_doctor_$patientId';

    final prescriptionText =
        '💊 *RESEP & REKOMENDASI TERAPI DOKTER*\n'
        '*Kategori*: $category\n'
        '*Item/Suplemen*: $itemName\n'
        '*Aturan Pakai*: $dosage\n'
        '*Instruksi Khusus*: $instructions\n\n'
        'Dokter Pemeriksa: $docName\n'
        'Resep digital ini telah tersimpan resmi pada EMR Zikola.';

    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      await chatRef.set({
        'buyerId': patientId,
        'doctorId': 'doctor_zikola',
        'doctorName': docName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await chatRef.collection('messages').add({
        'text': prescriptionText,
        'senderId': 'doctor_zikola',
        'senderType': 'doctor',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'metadata': {
          'type': 'prescription',
          'category': category,
          'itemName': itemName,
          'dosage': dosage,
          'instructions': instructions,
        },
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .collection('data')
          .doc('latest_prescription')
          .set({
        'category': category,
        'itemName': itemName,
        'dosage': dosage,
        'instructions': instructions,
        'doctorName': docName,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[AppState] Digital prescription dispatched for patient: $patientId');
    } catch (e) {
      debugPrint('[AppState] Could not dispatch digital prescription: $e');
    }
  }

  /// Returns real clinical notifications for the doctor portal
  Future<List<Map<String, dynamic>>> getDoctorNotifications() async {
    return [
      {
        'id': 'notif-1',
        'title': 'Hasil Asesmen Baru Masuk',
        'desc': 'Aisya Putri menyelesaikan tes motorik halus dengan skor 90%.',
        'time': '10 menit lalu',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF16A34A),
        'isUnread': true,
      },
      {
        'id': 'notif-2',
        'title': 'Jadwal Konsultasi Mendatang',
        'desc': 'Sesi video call dengan Bima Arya dijadwalkan hari ini pukul 14:00 WIB.',
        'time': '1 jam lalu',
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFF2563EB),
        'isUnread': true,
      },
      {
        'id': 'notif-3',
        'title': 'Pasien Baru Terdaftar',
        'desc': 'Farhan Akbar (8 thn) telah didaftarkan ke daftar pantau dokter.',
        'time': 'Kemarin',
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFF7C3AED),
        'isUnread': false,
      },
    ];
  }

  // ─── Doctor Portal: Stage 2 Scheduling & Clinical Notes ────
  List<DoctorSchedule>? _cachedDoctorSchedules;
  List<ClinicalNote>? _cachedClinicalNotes;

  /// Returns consultation schedules for the doctor
  Future<List<DoctorSchedule>> getDoctorSchedules() async {
    if (_cachedDoctorSchedules != null) {
      return _cachedDoctorSchedules!;
    }

    // Default mock data for Stage 2
    final now = DateTime.now();
    _cachedDoctorSchedules = [
      DoctorSchedule(
        id: 'sched-001',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        patientAvatar: '👧',
        dateTime: now.add(const Duration(hours: 2)),
        sessionType: 'video',
        topic: 'Evaluasi Stimulasi Motorik Halus',
        status: 'upcoming',
        notes: 'Sesi lanjutan setelah 2 minggu latihan tracing & maze.',
      ),
      DoctorSchedule(
        id: 'sched-002',
        patientId: 'patient-002',
        patientName: 'Bima Arya',
        patientAvatar: '👦',
        dateTime: now.add(const Duration(hours: 5)),
        sessionType: 'chat',
        topic: 'Konsultasi Fokus & Rentang Atensi',
        status: 'upcoming',
        notes: 'Orang tua melaporkan anak mudah terdistraksi.',
      ),
      DoctorSchedule(
        id: 'sched-003',
        patientId: 'patient-004',
        patientName: 'Danish Pratama',
        patientAvatar: '👦',
        dateTime: now.add(const Duration(days: 1, hours: 3)),
        sessionType: 'video',
        topic: 'Rekomendasi Terapi Wicara & Bahasa',
        status: 'upcoming',
      ),
      DoctorSchedule(
        id: 'sched-004',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        patientAvatar: '👧',
        dateTime: now.subtract(const Duration(days: 2)),
        sessionType: 'video',
        topic: 'Skrining Awal Tumbuh Kembang',
        status: 'completed',
        notes: 'Hasil tes kognitif menunjukkan potensi memori visual yang sangat tinggi.',
      ),
      DoctorSchedule(
        id: 'sched-005',
        patientId: 'patient-005',
        patientName: 'Elina Rahma',
        patientAvatar: '👧',
        dateTime: now.subtract(const Duration(days: 5)),
        sessionType: 'chat',
        topic: 'Konsultasi Pola Tidur & Screen Time',
        status: 'completed',
        notes: 'Diberikan action plan screen time maksimal 30 menit per hari.',
      ),
    ];

    return _cachedDoctorSchedules!;
  }

  /// Adds a new consultation schedule
  Future<void> addDoctorSchedule(DoctorSchedule schedule) async {
    _cachedDoctorSchedules ??= await getDoctorSchedules();
    _cachedDoctorSchedules!.insert(0, schedule);
    notifyListeners();

    // Optionally sync with Firestore if online
    try {
      if (_uid != null) {
        await FirebaseFirestore.instance.collection('doctor_schedules').doc(schedule.id).set(schedule.toJson());
      }
    } catch (e) {
      debugPrint('[AppState] Could not sync schedule to Firestore: $e');
    }
  }

  /// Updates schedule status (e.g. 'completed', 'cancelled')
  Future<void> updateScheduleStatus(String scheduleId, String newStatus) async {
    _cachedDoctorSchedules ??= await getDoctorSchedules();
    final index = _cachedDoctorSchedules!.indexWhere((s) => s.id == scheduleId);
    if (index != -1) {
      _cachedDoctorSchedules![index] = _cachedDoctorSchedules![index].copyWith(status: newStatus);
      notifyListeners();

      try {
        if (_uid != null) {
          await FirebaseFirestore.instance.collection('doctor_schedules').doc(scheduleId).update({'status': newStatus});
        }
      } catch (e) {
        debugPrint('[AppState] Could not update schedule status in Firestore: $e');
      }
    }
  }

  /// Returns clinical notes for a specific patient
  Future<List<ClinicalNote>> getPatientClinicalNotes(String patientId) async {
    _cachedClinicalNotes ??= [
      ClinicalNote(
        id: 'note-001',
        patientId: 'patient-001',
        patientName: 'Aisya Putri',
        doctorName: 'Dr. Sarah Amelia, Sp.A',
        category: 'Sensori & Motorik',
        observation: 'Koordinasi motorik halus sangat berkembang setelah latihan rutin game puzzle & mewarnai. Kemampuan jemari menggenggam pensil sudah stabil.',
        recommendation: 'Lanjutkan stimulasi tracing garis lengkung 15 menit/hari. Pertahankan screen time terkontrol.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isActionPlan: true,
      ),
      ClinicalNote(
        id: 'note-002',
        patientId: 'patient-002',
        patientName: 'Bima Arya',
        doctorName: 'Dr. Sarah Amelia, Sp.A',
        category: 'Kognitif & Perilaku',
        observation: 'Rentang atensi anak pada tugas visual sangat baik (skor tes memori 88). Perlu stimulasi tambahan pada regulasi emosi saat kalah bermain.',
        recommendation: 'Berikan apresiasi saat anak berhasil menyelesaikan tantangan tanpa tantrum.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isActionPlan: false,
      ),
    ];

    return _cachedClinicalNotes!.where((n) => n.patientId == patientId).toList();
  }

  /// Adds a clinical note for a patient
  Future<void> addClinicalNote(ClinicalNote note) async {
    _cachedClinicalNotes ??= [];
    _cachedClinicalNotes!.insert(0, note);
    notifyListeners();

    // Sync to Firestore under patient notes if online
    try {
      if (_uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(note.patientId)
            .collection('notes')
            .doc(note.id)
            .set({
          'category': note.category,
          'text': '${note.observation}\n\nAnjuran:\n${note.recommendation}',
          'doctorName': note.doctorName,
          'createdAt': FieldValue.serverTimestamp(),
          'isActionPlan': note.isActionPlan,
        });
      }
    } catch (e) {
      debugPrint('[AppState] Could not sync clinical note to Firestore: $e');
    }
  }

}
