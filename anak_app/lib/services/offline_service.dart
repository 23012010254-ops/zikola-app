import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  StreamSubscription? _connectivitySubscription;

  Future<void> initialize() async {
    // Check initial connectivity
    final results = await Connectivity().checkConnectivity();
    _updateOfflineState(results);

    // Subscribe to changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateOfflineState(results);
    });
  }

  void _updateOfflineState(List<ConnectivityResult> results) async {
    final bool hasConnection = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    bool actualOnline = false;

    if (hasConnection) {
      // Even if connectivity indicates a connection, verify we can actually reach the internet
      actualOnline = await _verifyActualInternet();
    }

    final newOfflineState = !actualOnline;
    if (_isOffline != newOfflineState) {
      _isOffline = newOfflineState;
      _connectivityController.add(_isOffline);
      if (kDebugMode) {
        print("Offline state changed: $_isOffline");
      }
      if (!_isOffline) {
        // Auto sync when back online
        processSyncQueue();
      }
    }
  }

  Future<bool> _verifyActualInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Fallback: If network interface is active, avoid false offline triggers
      return true;
    }
  }

  // Check connectivity on demand
  Future<bool> checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final bool hasConnection = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (!hasConnection) {
      _isOffline = true;
      _connectivityController.add(true);
      return false;
    }

    final actualOnline = await _verifyActualInternet();
    _isOffline = !actualOnline;
    _connectivityController.add(_isOffline);
    return actualOnline;
  }

  // Queue a sync operation for later
  Future<void> queueSyncOperation(String collectionPath, String docId, Map<String, dynamic> data, String operationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList('offline_sync_queue') ?? [];

      final syncItem = {
        'collectionPath': collectionPath,
        'docId': docId,
        'data': data,
        'operationType': operationType, // 'set', 'update', 'add'
        'timestamp': DateTime.now().toIso8601String(),
      };

      queue.add(jsonEncode(syncItem));
      await prefs.setStringList('offline_sync_queue', queue);
      if (kDebugMode) {
        print("Queued sync operation: $operationType on $collectionPath/$docId");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to queue sync operation: $e");
      }
    }
  }

  // Process all queued operations (must be resolved by AppState/FirestoreService)
  // We allow AppState or external services to listen or supply a sync handler
  Future<void> processSyncQueue() async {
    if (_isOffline) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList('offline_sync_queue') ?? [];
      if (queue.isEmpty) return;

      if (kDebugMode) {
        print("Processing ${queue.length} pending sync operations...");
      }

      // We will let the AppState trigger the actual sync using FirestoreService.
      // But we can also trigger a listener if registered.
      if (_syncHandler != null) {
        final List<Map<String, dynamic>> parsedQueue = queue
            .map((item) => jsonDecode(item) as Map<String, dynamic>)
            .toList();
        
        bool success = await _syncHandler!(parsedQueue);
        if (success) {
          await prefs.setStringList('offline_sync_queue', []);
          if (kDebugMode) {
            print("Sync queue processed and cleared successfully.");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error processing sync queue: $e");
      }
    }
  }

  // Sync handler type: Future<bool> Function(List<Map<String, dynamic>> operations)
  Future<bool> Function(List<Map<String, dynamic>> operations)? _syncHandler;

  void registerSyncHandler(Future<bool> Function(List<Map<String, dynamic>> operations) handler) {
    _syncHandler = handler;
    // Process queue immediately if we are online
    if (!_isOffline) {
      processSyncQueue();
    }
  }

  // Get pending sync count
  Future<int> getPendingSyncCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList('offline_sync_queue') ?? [];
    return queue.length;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
