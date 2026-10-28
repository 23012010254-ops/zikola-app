import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '510792598386-m4c8993mdg4qvnad51lr1ba8h3a5oir1.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Get the current user UID
  String? get currentUid => _auth.currentUser?.uid;

  /// Get the current auth token
  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  String? lastAuthError;

  String _parseFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Akun dengan email ini belum terdaftar. Silakan klik "Daftar sekarang" di bawah.';
      case 'wrong-password':
        return 'Password salah. Silakan periksa kembali kata sandi Anda.';
      case 'invalid-credential':
        return 'Email atau password salah. Silakan periksa kembali.';
      case 'invalid-email':
        return 'Format email tidak valid. Masukkan email yang benar (contoh: nama@gmail.com).';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan oleh administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat lagi.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Pastikan perangkat terhubung ke internet.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan login atau gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi (${e.code}).';
    }
  }

  /// Perform email & password login with guaranteed Firestore synchronization
  Future<bool> login(String email, String password) async {
    lastAuthError = null;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Pastikan dokumen pengguna di Firestore selalu ada dan tersinkronisasi
      if (credential.user != null) {
        final uid = credential.user!.uid;
        try {
          final exists = await _firestore.checkUserExists(uid);
          if (!exists) {
            await _firestore.initializeUser(
              uid,
              credential.user!.displayName ?? email.trim().split('@').first,
              credential.user!.email ?? email.trim(),
            );
          }
        } catch (e) {
          debugPrint('Error verifying Firestore document on login: $e');
        }
      }

      return true;
    } on FirebaseAuthException catch (e) {
      lastAuthError = _parseFirebaseAuthError(e);
      debugPrint('Firebase Login Error: [${e.code}] ${e.message}');
      return false;
    } catch (e) {
      lastAuthError = 'Gagal masuk: $e';
      debugPrint('General Login Error: $e');
      return false;
    }
  }

  final GoogleSignIn _googleSignInFallback = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  String? lastGoogleError;

  String _parseGoogleError(Object e) {
    final str = e.toString();
    // Match the ApiException status code itself, not any digit in the message.
    final code = RegExp(r'ApiException:\s*(\d+)').firstMatch(str)?.group(1);
    if (code == '10' || str.contains('DEVELOPER_ERROR')) {
      return 'Konfigurasi SHA-1 atau OAuth Client ID belum cocok di Firebase Console (ApiException: 10).';
    } else if (code == '12500') {
      return 'Layanan ditolak oleh Google. Pastikan OAuth Consent Screen aktif & Support Email diisi di Firebase Console (ApiException: 12500).';
    } else if (code == '7' ||
        str.contains('NETWORK_ERROR') ||
        str.contains('network_error')) {
      return 'Koneksi jaringan internet terputus atau tidak stabil (Network Error: 7).';
    } else if (str.contains('TimeoutException') ||
        str.contains('Waktu koneksi')) {
      return 'Waktu koneksi habis. Layanan Google Play di perangkat tidak merespons.';
    } else if (str.contains('sign_in_canceled') || str.contains('dibatalkan')) {
      return 'Login dibatalkan oleh pengguna.';
    }
    return 'Google Sign-In Error: $str';
  }

  /// Android/iOS: native Google account picker, then Firebase credential.
  Future<UserCredential?> _signInWithGoogleNative() async {
    // Force sign out first to clear any stuck internal state or cached invalid sessions.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    GoogleSignInAccount? googleUser;
    try {
      // Try with serverClientId first
      googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Waktu koneksi Google Sign-In habis (15 detik).',
        ),
      );
    } catch (firstError) {
      debugPrint(
        'Google Sign-In attempt 1 failed: $firstError. Trying fallback auto-discovery...',
      );
      // Fallback to auto-discovery without explicit serverClientId
      googleUser = await _googleSignInFallback.signIn().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Waktu koneksi Google Sign-In habis (15 detik).',
        ),
      );
    }

    if (googleUser == null) {
      lastGoogleError = 'Login dibatalkan oleh pengguna.';
      return null;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      lastGoogleError =
          'Google Play Services tidak mengembalikan token autentikasi. Periksa konfigurasi SHA-1.';
      return null;
    }

    // Create a new credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await _auth.signInWithCredential(credential);
  }

  /// Perform Google Sign In with auto-retry and timeout protection
  Future<bool> signInWithGoogle() async {
    lastGoogleError = null;
    try {
      // Web uses Firebase's own popup; the google_sign_in plugin needs a
      // separate web client ID there and isn't required.
      final userCred = kIsWeb
          ? await _auth.signInWithPopup(GoogleAuthProvider())
          : await _signInWithGoogleNative();
      if (userCred == null) return false;

      // Ensure user document exists in Firestore
      if (userCred.user != null) {
        try {
          await _firestore.initializeUser(
            userCred.user!.uid,
            userCred.user!.displayName ?? 'Anak Pintar',
            userCred.user!.email ?? '',
          );
        } catch (e) {
          debugPrint('Failed to initialize Firestore user on Google Login: $e');
        }
      }

      return true;
    } on FirebaseAuthException catch (e) {
      lastGoogleError = 'Firebase Error: [${e.code}] ${e.message}';
      debugPrint(lastGoogleError);
      return false;
    } catch (e) {
      lastGoogleError = _parseGoogleError(e);
      debugPrint(lastGoogleError);
      return false;
    }
  }

  /// Sign in as simulated/demo Google user (instant fallback so developer/tester is never blocked)
  Future<Map<String, dynamic>> signInAsDemoGoogleUser({
    String email = 'adit.zikola@gmail.com',
    String name = 'Adit (Google User)',
  }) async {
    const demoUid = 'google_demo_adit_user';
    try {
      await _firestore.initializeUser(demoUid, name, email);
    } catch (_) {}
    return {'uid': demoUid, 'name': name, 'email': email};
  }

  /// Perform registration
  Future<bool> register(String name, String email, String password) async {
    lastAuthError = null;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name.trim());

      // Initialize Firestore document
      if (credential.user != null) {
        await _firestore.initializeUser(
          credential.user!.uid,
          name.trim(),
          email.trim(),
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      lastAuthError = _parseFirebaseAuthError(e);
      debugPrint('Firebase Register Error: [${e.code}] ${e.message}');
      return false;
    } catch (e) {
      lastAuthError = 'Gagal mendaftar: $e';
      debugPrint('General Register Error: $e');
      return false;
    }
  }

  /// Perform logout
  Future<void> logout() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
