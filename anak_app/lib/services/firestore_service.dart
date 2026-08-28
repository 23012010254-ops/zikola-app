import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/child_profile.dart';
import '../models/test_result.dart';
import '../models/game_assessment.dart';
import '../models/app_notification.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Initialize User on Register
  Future<void> initializeUser(String uid, String name, String email) async {
    try {
      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'schemaVersion': 2,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profile': {
          'surveyCompleted': false,
        },
        'progress': {
          'totalPoints': 0,
          'collectedStickers': [],
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error initializing user: $e');
    }
  }

  // Save Child Profile (Legacy naming, but updated for new structure)
  Future<void> saveProfile(String uid, ChildProfile profile) async {
    try {
      // DATA PROTECTION: Don't save if name is unexpectedly empty on a profile that should be initialized
      if (profile.name.isEmpty && profile.surveyCompleted) {
        debugPrint('Firestore Blocked: Attempting to save an empty name for a completed profile. Ignoring to prevent data corruption.');
        return;
      }

      await _db.collection('users').doc(uid).set({
        'name': profile.name,
        'schemaVersion': 2,
        'profile': {
          'gender': profile.gender,
          'age': profile.age,
          'avatar': profile.avatar,
          'avatarBase64': profile.avatarBase64,
          'backgroundColor': profile.backgroundColor,
          'favoriteColor': profile.favoriteColor,
          'surveyData': profile.surveyData.toJson(),
          'surveyCompleted': profile.surveyCompleted,
          'followers': profile.followers,
          'following': profile.following,
        },
        'progress': {
          'badges': profile.badges,
          'showcasedStickers': profile.showcasedStickers,
          'totalPoints': profile.totalPoints,
        },
        'userIdentity': profile.toIdentityString(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving profile: $e');
    }
  }

  // Update Total Points
  Future<void> updateTotalPoints(String uid, int points) async {
    try {
      await _db.collection('users').doc(uid).set({
        'progress': {'totalPoints': points},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating total points: $e');
    }
  }

  // ATOMIC SYNC: Updates everything in one go to prevent "Snapshot Wars"
  Future<void> syncFullProfile({
    required String uid,
    required ChildProfile profile,
    required List<String> stickers,
    required int points,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'name': profile.name,
        'schemaVersion': 2,
        'profile': {
          'gender': profile.gender,
          'age': profile.age,
          'avatar': profile.avatar,
          'avatarBase64': profile.avatarBase64,
          'backgroundColor': profile.backgroundColor,
          'favoriteColor': profile.favoriteColor,
          'surveyData': profile.surveyData.toJson(),
          'surveyCompleted': profile.surveyCompleted,
          'followers': profile.followers,
          'following': profile.following,
        },
        'progress': {
          'totalPoints': points,
          'collectedStickers': stickers,
          'showcasedStickers': profile.showcasedStickers,
          'badges': profile.badges,
        },
        'userIdentity': profile.toIdentityString(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error in atomic sync: $e');
    }
  }

  // Check if User Document Exists
  Future<bool> checkUserExists(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return false;
    }
  }

  // Load Child Profile
  Future<ChildProfile?> loadProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        Map<String, dynamic> fullProfileData = {};
        
        // Root fields
        if (data.containsKey('name')) fullProfileData['name'] = data['name'];
        if (data.containsKey('email')) fullProfileData['email'] = data['email'];
        
        // Merge from profile map
        if (data.containsKey('profile')) {
          final profileMap = Map<String, dynamic>.from(data['profile'] as Map);
          fullProfileData.addAll(profileMap);
        }
        
        // Merge from progress map
        if (data.containsKey('progress')) {
          final progressMap = Map<String, dynamic>.from(data['progress'] as Map);
          if (progressMap.containsKey('totalPoints')) fullProfileData['totalPoints'] = progressMap['totalPoints'];
          if (progressMap.containsKey('badges')) fullProfileData['badges'] = progressMap['badges'];
          if (progressMap.containsKey('showcasedStickers')) fullProfileData['showcasedStickers'] = progressMap['showcasedStickers'];
          if (progressMap.containsKey('collectedStickers')) {
             fullProfileData['collectedStickers'] = List<String>.from(progressMap['collectedStickers']);
          }
        }

        // Legacy support: check for totalPoints at root
        if (data.containsKey('totalPoints')) {
          fullProfileData['totalPoints'] = data['totalPoints'];
        }
        
        if (fullProfileData.isNotEmpty) {
          return ChildProfile.fromJson(fullProfileData);
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getProfiles(List<String> uids) async {
    if (uids.isEmpty) return [];
    try {
      // Create chunks of 10 for whereIn query limitation (FieldPath.documentId())
      // For simplicity, we just fetch each doc since following/followers usually isn't massive initially,
      // or we can just fetch one by one in parallel.
      final futures = uids.map((uid) => _db.collection('users').doc(uid).get());
      final snaps = await Future.wait(futures);
      
      final results = <Map<String, dynamic>>[];
      for (int i = 0; i < snaps.length; i++) {
        final doc = snaps[i];
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            final name = data['name'] ?? 'User';
            String avatar = '👤';
            String? avatarBase64;
            
            if (data.containsKey('profile')) {
              final p = data['profile'] as Map<String, dynamic>;
              avatar = p['avatar'] ?? '👤';
              avatarBase64 = p['avatarBase64'];
            }
            
            results.add({
               'uid': doc.id,
               'name': name,
               'avatarBase64': avatarBase64,
               'avatar': avatar,
            });
          }
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      return [];
    }
  }

  // Get Profile Stream for real-time updates
  Stream<DocumentSnapshot> getProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Save Test Results (Direct to dedicated sub-collection for Dashboard visibility)
  Future<void> saveTestResults(String uid, String testType, Map<String, dynamic> results) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('data')
          .doc('tests')
          .set({
            testType: {
              ...results,
              'updatedAt': FieldValue.serverTimestamp(),
            }
          }, SetOptions(merge: true));
          
      // Also update a timestamp on root for sync detection
      await _db.collection('users').doc(uid).update({'updatedAt': FieldValue.serverTimestamp()});
      debugPrint('Test results saved to Firestore: $testType');
    } catch (e) {
      debugPrint('Error saving test results: $e');
    }
  }

  // Follow User
  Future<void> followUser(String currentUid, String targetUid) async {
    try {
      final batch = _db.batch();
      final currentUserRef = _db.collection('users').doc(currentUid);
      final targetUserRef = _db.collection('users').doc(targetUid);

      batch.set(currentUserRef, {
        'profile': {
          'following': FieldValue.arrayUnion([targetUid])
        }
      }, SetOptions(merge: true));

      batch.set(targetUserRef, {
        'profile': {
          'followers': FieldValue.arrayUnion([currentUid])
        }
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Error following user: $e');
    }
  }

  // Unfollow User
  Future<void> unfollowUser(String currentUid, String targetUid) async {
    try {
      final batch = _db.batch();
      final currentUserRef = _db.collection('users').doc(currentUid);
      final targetUserRef = _db.collection('users').doc(targetUid);

      batch.set(currentUserRef, {
        'profile': {
          'following': FieldValue.arrayRemove([targetUid])
        }
      }, SetOptions(merge: true));

      batch.set(targetUserRef, {
        'profile': {
          'followers': FieldValue.arrayRemove([currentUid])
        }
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
    }
  }


  // Load Test Results (Migrated to sub-collection)
  Future<TestResults?> loadTestResults(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('data').doc('tests').get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('results')) {
          return TestResults.fromJson(data['results'] as Map<String, dynamic>);
        }
      }
      
      // FALLBACK: Check root for legacy data
      final rootDoc = await _db.collection('users').doc(uid).get();
      if (rootDoc.exists) {
        final rootData = rootDoc.data()!;
        if (rootData.containsKey('progress') && (rootData['progress'] as Map).containsKey('testResults')) {
          return TestResults.fromJson(rootData['progress']['testResults'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error loading test results: $e');
    }
    return null;
  }

  // Save Game Assessments (Migrated to sub-collection)
  Future<void> saveGameAssessments(String uid, AllGameAssessments assessments) async {
    try {
      await _db.collection('users').doc(uid).collection('data').doc('games').set({
        'assessments': assessments.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('users').doc(uid).update({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error saving game assessments: $e');
    }
  }

  // Load Game Assessments (Migrated to sub-collection)
  Future<AllGameAssessments?> loadGameAssessments(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('data').doc('games').get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('assessments')) {
          return AllGameAssessments.fromJson(data['assessments'] as Map<String, dynamic>);
        }
      }

      // FALLBACK: Check root for legacy data
      final rootDoc = await _db.collection('users').doc(uid).get();
      if (rootDoc.exists) {
        final rootData = rootDoc.data()!;
        if (rootData.containsKey('progress') && (rootData['progress'] as Map).containsKey('gameAssessments')) {
          return AllGameAssessments.fromJson(rootData['progress']['gameAssessments'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error loading game assessments: $e');
    }
    return null;
  }

  // Save Collected Stickers (Migrated to sub-collection)
  Future<void> saveCollectedStickers(String uid, List<String> stickers) async {
    try {
      await _db.collection('users').doc(uid).collection('data').doc('stickers').set({
        'list': stickers,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('users').doc(uid).update({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error saving stickers: $e');
    }
  }

  // Load Collected Stickers (Migrated to sub-collection)
  Future<List<String>?> loadCollectedStickers(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('data').doc('stickers').get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('list')) {
          List<dynamic> list = data['list'] as List<dynamic>;
          return list.map((e) => e.toString()).toList();
        }
      }

      // FALLBACK: Check root for legacy data
      final rootDoc = await _db.collection('users').doc(uid).get();
      if (rootDoc.exists) {
        final rootData = rootDoc.data()!;
        if (rootData.containsKey('progress') && (rootData['progress'] as Map).containsKey('collectedStickers')) {
          List<dynamic> list = rootData['progress']['collectedStickers'] as List<dynamic>;
          return list.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading stickers: $e');
    }
    return null;
  }

  // --- USER IDENTITY ---

  // Save User Identity String (explicit standalone save)
  Future<void> saveUserIdentity(String uid, String identityString) async {
    try {
      await _db.collection('users').doc(uid).set({
        'userIdentity': identityString,
        'identityUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User identity saved: $identityString');
    } catch (e) {
      debugPrint('Error saving user identity: $e');
    }
  }

  // Load User Identity String
  Future<String?> loadUserIdentity(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('userIdentity')) {
          return data['userIdentity'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error loading user identity: $e');
    }
    return null;
  }

  /// Check if another user already has the same identity string.
  /// Returns the UID of the duplicate user, or null if no duplicate.
  Future<String?> checkDuplicateIdentity(String currentUid, String identityString) async {
    try {
      final query = await _db
          .collection('users')
          .where('userIdentity', isEqualTo: identityString)
          .get();
      for (var doc in query.docs) {
        if (doc.id != currentUid) {
          debugPrint('Duplicate identity found: ${doc.id} has "$identityString"');
          return doc.id;
        }
      }
    } catch (e) {
      debugPrint('Error checking duplicate identity: $e');
    }
    return null;
  }

  // Reset ALL user data (keeps Firebase Auth account intact)
  Future<void> resetUserData(String uid) async {
    try {
      // set() WITHOUT merge replaces the entire document.
      // Only 'resetAt' will remain — all previous fields (userIdentity,
      // profile, testResults, etc.) are wiped automatically.
      await _db.collection('users').doc(uid).set({
        'resetAt': FieldValue.serverTimestamp(),
      });
      debugPrint('User data reset complete for uid: $uid');
    } catch (e) {
      debugPrint('Error resetting user data: $e');
    }
  }

  // --- CONSULTATION FEATURE ---
  
  // Get all doctors stream
  Stream<QuerySnapshot> getDoctorsStream() {
    return _db.collection('doctors').snapshots();
  }

  // Get single doctor by ID
  Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    if (doctorId == 'doctor_bot') {
      return {
        'id': 'doctor_bot',
        'name': 'Asisten AI ANAK 🤖',
        'specialty': 'Asisten Kecerdasan Buatan',
        'image': '🤖',
        'available': true,
        'experience': 5,
        'rating': 5.0,
        'price': 0,
        'hospital': 'Cloud AI Server',
        'practiceLocation': 'Aplikasi ANAK',
        'education': 'Model Bahasa Besar (LLM)',
        'bio': 'Saya adalah asisten pintar berbasis kecerdasan buatan (AI) yang siap membantu Bunda & Ayah dalam memberikan tips tumbuh kembang, stimulasi sensorik-motorik, dan pola asuh anak secara instan 24/7.',
        'schedule': 'Setiap Hari, 24 Jam Nonstop',
        'licenseNumber': 'AI-ASSISTANT-001',
      };
    }
    try {
      final doc = await _db.collection('doctors').doc(doctorId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching doctor $doctorId: $e');
    }
    return null;
  }

  // Seed Dummy Doctors if empty
  Future<void> seedDummyDoctors() async {
    final doctor1Doc = await _db.collection('doctors').doc('doctor_1').get();
    
    bool needsSchemaUpdate = false;
    if (doctor1Doc.exists) {
      final data = doctor1Doc.data() as Map<String, dynamic>;
      // Check if critical professional fields exist or if old emoji image is used
      if (!data.containsKey('experience') || !data.containsKey('bio') || data['image'] == '👨\u200d⚕️') {
        needsSchemaUpdate = true;
      }
    }

    // Re-seed if doctor_1 is missing OR needs schema update
    if (!doctor1Doc.exists || needsSchemaUpdate) {
      final doctors = [
        {
          'id': 'doctor_1',
          'name': 'Dr. Andi Saputra, Sp.A',
          'specialty': 'Dokter Spesialis Anak',
          'hospital': 'RS Mitra Keluarga',
          'rating': 4.9,
          'reviews': 124,
          'price': 150000,
          'image': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?q=80&w=256&h=256&fit=crop',
          'available': true,
          'experience': 12,
          'licenseNumber': 'SIP/DKI/2019/04521',
          'practiceLocation': 'RS Mitra Keluarga Kemayoran, Jl. HBR Motik No.4, Jakarta Pusat',
          'education': 'Universitas Indonesia - Fakultas Kedokteran',
          'bio': 'Berpengalaman menangani tumbuh kembang anak, alergi anak, dan imunisasi. Aktif sebagai pembicara di seminar parenting dan kesehatan anak.',
          'schedule': 'Senin - Jumat, 09:00 - 15:00',
        },
        {
          'id': 'doctor_2',
          'name': 'Budi Santoso, M.Psi',
          'specialty': 'Psikolog Anak & Remaja',
          'hospital': 'Klinik Tumbuh Kembang',
          'rating': 4.8,
          'reviews': 89,
          'price': 200000,
          'image': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=256&h=256&fit=crop',
          'available': true,
          'experience': 8,
          'licenseNumber': 'SIPP/DKI/2020/08832',
          'practiceLocation': 'Klinik Tumbuh Kembang Anak, Jl. Gatot Subroto Kav.21, Jakarta Selatan',
          'education': 'Universitas Gadjah Mada - Magister Psikologi Klinis',
          'bio': 'Spesialis dalam asesmen perkembangan anak, terapi bermain, dan konseling orang tua. Menangani kasus ADHD, autism, dan gangguan belajar.',
          'schedule': 'Senin - Sabtu, 10:00 - 17:00',
        },
        {
          'id': 'doctor_3',
          'name': 'Dr. Anita Wijaya, Sp.A',
          'specialty': 'Dokter Spesialis Anak',
          'hospital': 'RS Siloam',
          'rating': 4.7,
          'reviews': 210,
          'price': 125000,
          'image': 'https://images.unsplash.com/photo-1594824813573-246434de83fb?q=80&w=256&h=256&fit=crop',
          'available': false,
          'experience': 15,
          'licenseNumber': 'SIP/JTG/2017/03108',
          'practiceLocation': 'RS Siloam Kebon Jeruk, Jl. Perjuangan No.8, Jakarta Barat',
          'education': 'Universitas Airlangga - Fakultas Kedokteran',
          'bio': 'Ahli dalam pediatri umum, nutrisi anak, dan penanganan penyakit infeksi pada anak. Pengalaman luas di rumah sakit swasta dan puskesmas.',
          'schedule': 'Selasa - Sabtu, 08:00 - 14:00',
        },
      ];
      
      for (var docItem in doctors) {
        final id = docItem['id'] as String?;
        if (id != null) {
          await _db.collection('doctors').doc(id).set(docItem);
        } else {
          await _db.collection('doctors').add(docItem);
        }
      }

      // Seed credentials for web login
      await _seedDoctorCredentials();

      // After seeding doctors, seed a demo chat for Andi
      await _seedDemoChatForAndi();
    }
  }

  Future<void> _seedDoctorCredentials() async {
    final creds = [
      {
        'doctorId': 'doctor_1',
        'username': 'andi-saputra',
        'email': 'andi@zikola.com',
        'password': 'ef92b778bafe771e89245b89ecbc054c66c19461d5a915c08a103bcc3f189b2b', // SHA-256 for password123
        'securityPin': '8d969eee76ec8a32a39a2b15303a446a298225b659c628655c4568f5c822e030', // SHA-256 for 123456
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'doctorId': 'doctor_2',
        'username': 'budi-santoso',
        'email': 'budi@zikola.com',
        'password': 'ef92b778bafe771e89245b89ecbc054c66c19461d5a915c08a103bcc3f189b2b',
        'securityPin': '8d969eee76ec8a32a39a2b15303a446a298225b659c628655c4568f5c822e030',
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'doctorId': 'doctor_3',
        'username': 'anita-wijaya',
        'email': 'anita@zikola.com',
        'password': 'ef92b778bafe771e89245b89ecbc054c66c19461d5a915c08a103bcc3f189b2b',
        'securityPin': '8d969eee76ec8a32a39a2b15303a446a298225b659c628655c4568f5c822e030',
        'createdAt': DateTime.now().toIso8601String(),
      }
    ];

    for (var cred in creds) {
      await _db.collection('doctor_credentials').doc(cred['doctorId'] as String).set(cred);
    }
  }

  Future<void> _seedDemoChatForAndi() async {
    const demoChatId = 'demo_chat_andi_01';
    final chatRef = _db.collection('chats').doc(demoChatId);
    final chatSnap = await chatRef.get();

    if (!chatSnap.exists) {
      // 1. Create the Chat Document
      await chatRef.set({
        'doctorId': 'doctor_1',
        'buyerId': 'demo_user_01',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))), // Extended for demo
      });

      // 2. Add some messages
      final msgCol = chatRef.collection('messages');
      
      await msgCol.add({
        'text': 'Halo Dok, saya Bunda Maria. Anak saya (Budi, 3th) sedang panas sejak semalam. Apakah perlu langsung ke RS?',
        'senderId': 'demo_user_01',
        'senderType': 'user',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await msgCol.add({
        'text': 'Halo Bunda Maria, saya Dr. Andi. Panasnya berapa derajat ya Bun? Ada gejala lain seperti batuk atau pilek?',
        'senderId': 'doctor_1',
        'senderType': 'doctor',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get chat stream
  Stream<QuerySnapshot> getChatStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send message
  Future<void> sendMessage(String chatId, String senderId, String text, String senderType, {String? doctorId}) async {
    // Memastikan dokumen induk ada, sekaligus membuat timer 30 menit sesi
    if (senderType == 'user' && doctorId != null) {
      final docRef = _db.collection('chats').doc(chatId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        await docRef.set({
          'doctorId': doctorId,
          'buyerId': senderId,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 30))),
        });
      } else {
        final data = docSnap.data();
        
        // AUTO-REPAIR: If existing chat is missing doctorId, update it
        if (data != null && !data.containsKey('doctorId')) {
          await docRef.update({'doctorId': doctorId});
          debugPrint('[FirestoreService] Repaired legacy chat with doctorId: $chatId');
        }

        // Reset timer if: no expiresAt exists, OR the existing session has expired
        bool needsNewTimer = false;
        if (data != null) {
          if (!data.containsKey('expiresAt')) {
            needsNewTimer = true;
           } else {
            DateTime? expiresAt;
            final raw = data['expiresAt'];
            if (raw is Timestamp) {
              expiresAt = raw.toDate();
            } else if (raw is String) {
              try { expiresAt = DateTime.parse(raw); } catch (_) {}
            }
            if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
              needsNewTimer = true; // Session expired, start new one
            }
          }
        }
        if (needsNewTimer) {
          await docRef.update({
            'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 30))),
          });
        }
      }
    }

    await _db.collection('chats').doc(chatId).collection('messages').add({
      'text': text,
      'senderId': senderId,
      'senderType': senderType,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMsgs = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderType', isEqualTo: 'doctor')
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMsgs.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var doc in unreadMsgs.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Create payment record
  Future<void> createPaymentRecord({
    required String orderId,
    required String userId,
    required String doctorId,
    required int amount,
    required String paymentMethod,
    required String status,
    String? snapToken,
    String? redirectUrl,
  }) async {
    try {
      await _db.collection('payments').doc(orderId).set({
        'orderId': orderId,
        'userId': userId,
        'doctorId': doctorId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': status,
        'snapToken': snapToken,
        'redirectUrl': redirectUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating payment record: $e');
      rethrow;
    }
  }

  // Update payment status (e.g. from webhook or simulation)
  Future<void> updatePaymentStatus({
    required String orderId,
    required String status,
    DateTime? paidAt,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (paidAt != null) {
        data['paidAt'] = Timestamp.fromDate(paidAt);
      }
      await _db.collection('payments').doc(orderId).update(data);
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  // Get stream for real-time payment status listening
  Stream<DocumentSnapshot> getPaymentStream(String orderId) {
    return _db.collection('payments').doc(orderId).snapshots();
  }

  // --- COMMUNITY FEATURE ---

  // Get stream of community posts
  Stream<QuerySnapshot> getCommunityPostsStream() {
    return _db
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Create a new post
  Future<void> createCommunityPost(Map<String, dynamic> postData) async {
    try {
      await _db.collection('community_posts').add({
        ...postData,
        'timestamp': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'likedBy': [],
      });
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  // Toggle like on a post
  Future<void> toggleLikePost(String postId, String uid, bool isCurrentlyLiked, {AppNotification? notification, String? targetUid}) async {
    try {
      final docRef = _db.collection('community_posts').doc(postId);
      if (isCurrentlyLiked) {
        // Remove like
        await docRef.update({
          'likedBy': FieldValue.arrayRemove([uid]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Add like
        await docRef.update({
          'likedBy': FieldValue.arrayUnion([uid]),
          'likesCount': FieldValue.increment(1),
        });
        
        // Add Notification
        if (notification != null && targetUid != null && targetUid != uid) {
          await addNotification(targetUid: targetUid, notification: notification);
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Get stream of comments for a post
  Stream<QuerySnapshot> getCommunityCommentsStream(String postId) {
    return _db
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Add a comment to a post
  Future<void> addCommunityComment(String postId, Map<String, dynamic> commentData, {AppNotification? notification, String? targetUid}) async {
    try {
      final docRef = _db.collection('community_posts').doc(postId);
      
      // We can use a batch to write the comment and update the counter safely
      final batch = _db.batch();
      
      // 1. Add comment
      final commentRef = docRef.collection('comments').doc();
      batch.set(commentRef, {
        ...commentData,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // 2. Increment comment count
      batch.update(docRef, {
        'commentsCount': FieldValue.increment(1),
      });
      
      await batch.commit();

      // Add Notification
      if (notification != null && targetUid != null && targetUid != commentData['authorId']) {
        await addNotification(targetUid: targetUid, notification: notification);
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  // Delete a community post and its subcollections (comments)
  Future<void> deleteCommunityPost(String postId) async {
    try {
      final postRef = _db.collection('community_posts').doc(postId);
      
      // 1. Delete comments subcollection first
      final commentsSnapshot = await postRef.collection('comments').get();
      final batch = _db.batch();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // 2. Delete the main post
      batch.delete(postRef);
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  // --- NOTIFICATIONS ---

  Future<void> addNotification({
    required String targetUid,
    required AppNotification notification,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(targetUid)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());
    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsRead(String uid) async {
    try {
      // Fetch the last 50 notifications to check for unread ones robustly
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      if (snapshot.docs.isEmpty) return;
      
      final batch = _db.batch();
      bool hasUpdates = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Catch both 'false' and missing (null) isRead fields
        if (data['isRead'] != true) {
          batch.update(doc.reference, {'isRead': true});
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteReadNotifications(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('Read notifications deleted for $uid');
    } catch (e) {
      debugPrint('Error deleting read notifications: $e');
    }
  }

  Stream<QuerySnapshot> getNotificationsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markChatMessagesAsRead(String chatId) async {
    try {
      final messagesSnap = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderType', isEqualTo: 'doctor')
          .where('isRead', isEqualTo: false)
          .get();

      if (messagesSnap.docs.isEmpty) return;

      final batch = _db.batch();
      for (var doc in messagesSnap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      debugPrint('All doctor messages marked as read for chat: $chatId');
    } catch (e) {
      debugPrint('Error marking chat messages as read: $e');
    }
  }

  Future<void> markAllChatsAsRead(String uid) async {
    try {
      final chatsSnap = await _db
          .collection('chats')
          .where('buyerId', isEqualTo: uid)
          .get();

      for (var chatDoc in chatsSnap.docs) {
        await markChatMessagesAsRead(chatDoc.id);
      }
      debugPrint('All chat messages marked as read for user: $uid');
    } catch (e) {
      debugPrint('Error marking all chats as read: $e');
    }
  }

  // --- MULTI-CHILD METHODS ---

  Future<void> saveChildProfile(String uid, ChildProfile child) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(child.id)
          .set(child.toJson(), SetOptions(merge: true));
      debugPrint('Child profile saved under user $uid: ${child.name}');
    } catch (e) {
      debugPrint('Error saving child profile: $e');
    }
  }

  Future<List<ChildProfile>?> loadChildrenProfiles(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('children')
          .orderBy('createdAt', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => ChildProfile.fromJson(doc.data()))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading children profiles: $e');
    }
    return null;
  }

  Future<void> deleteChildProfile(String uid, String childId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(childId)
          .delete();
      debugPrint('Child profile deleted: $childId');
    } catch (e) {
      debugPrint('Error deleting child profile: $e');
    }
  }
  // Delete User Data Permanently (Google Play Policy Compliance)
  Future<void> deleteUserData(String uid) async {
    try {
      final batch = _db.batch();
      final userRef = _db.collection('users').doc(uid);

      final notes = await userRef.collection('notes').get();
      for (var d in notes.docs) batch.delete(d.reference);

      final emr = await userRef.collection('emr').get();
      for (var d in emr.docs) batch.delete(d.reference);

      final children = await userRef.collection('children').get();
      for (var d in children.docs) batch.delete(d.reference);

      final notifications = await userRef.collection('notifications').get();
      for (var d in notifications.docs) batch.delete(d.reference);

      batch.delete(userRef);
      await batch.commit();
      debugPrint('[FirestoreService] All data deleted for user: ' + uid);
    } catch (e) {
      debugPrint('Error deleting user data: $e');
    }
  }

}
