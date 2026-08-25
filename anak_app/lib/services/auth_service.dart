import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '510792598386-m4c8993mdg4qvnad51lr1ba8h3a5oir1.apps.googleusercontent.com',
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

  /// Perform login
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Login Error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('General Login Error: $e');
      return false;
    }
  }

  /// Perform Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      // Force sign out first to clear any stuck internal state or cached invalid sessions.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google Sign-In Error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('General Google Sign-In Error: $e');
      return false;
    }
  }

  /// Perform registration
  Future<bool> register(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(name);

      // Initialize Firestore document
      if (credential.user != null) {
        await _firestore.initializeUser(credential.user!.uid, name, email);
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Register Error: ${e.message}');
      return false;
    } catch (e) {
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
