import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';

/// Persists per-game level progress (stars per level + highest unlocked
/// level) for the active child. Saved on the device for instant loads and
/// mirrored to users/{uid}/data/level_progress so it follows the account.
class LevelProgressStore {
  static String _childId(AppState s) => s.activeChildId ?? 'default';

  static String _prefsKey(AppState s, String game) =>
      'level_progress_${s.uid}_${_childId(s)}_$game';

  static DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('data').doc('level_progress');

  /// Merges saved progress into [stars] (in place, keeping the best value)
  /// and returns the highest unlocked level (at least 1).
  static Future<int> load(BuildContext context, String game, List<int> stars) async {
    final state = context.read<AppState>();
    if (state.uid == null) return 1;
    var unlocked = 1;

    void merge(Map<String, dynamic>? data) {
      if (data == null) return;
      final saved = (data['stars'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [];
      for (var i = 0; i < min(saved.length, stars.length); i++) {
        stars[i] = max(stars[i], saved[i]);
      }
      unlocked = max(unlocked, (data['unlocked'] as num?)?.toInt() ?? 1);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(state, game));
      if (raw != null) merge(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Level progress (local) load failed: $e');
    }

    try {
      final snap = await _doc(state.uid!).get();
      final child = snap.data()?[_childId(state)] as Map<String, dynamic>?;
      merge(child?[game] as Map<String, dynamic>?);
    } catch (e) {
      debugPrint('Level progress (server) load failed: $e');
    }

    return unlocked.clamp(1, max(1, stars.length));
  }

  /// Saves the current progress; safe to call after every level.
  static Future<void> save(BuildContext context, String game, List<int> stars, int unlocked) async {
    final state = context.read<AppState>();
    if (state.uid == null) return;
    final data = {'stars': List<int>.from(stars), 'unlocked': unlocked};

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey(state, game), jsonEncode(data));
    } catch (e) {
      debugPrint('Level progress (local) save failed: $e');
    }

    _doc(state.uid!)
        .set({
          _childId(state): {game: data},
        }, SetOptions(merge: true))
        .catchError((e) => debugPrint('Level progress (server) save failed: $e'));
  }
}
