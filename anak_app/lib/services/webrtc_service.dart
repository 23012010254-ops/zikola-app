import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientWebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  StreamSubscription? _signalSub;
  StreamSubscription? _candidatesSub;

  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool isMuted = false;
  bool isSpeakerOn = true;

  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<void> initRenderer() async {
    await remoteRenderer.initialize();
  }

  Future<void> _clearOldCandidates(String chatId) async {
    debugPrint('[WebRTC] Clearing old ICE candidates...');
    final collections = ['doctor_candidates', 'patient_candidates'];
    for (final col in collections) {
      final snap = await FirebaseFirestore.instance
          .collection('chats').doc(chatId).collection(col).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
    debugPrint('[WebRTC] Old candidates cleared.');
  }

  Future<MediaStream> _initLocalAudio() async {
    if (_localStream != null) return _localStream!;
    try {
      debugPrint('[WebRTC] Requesting microphone...');
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      debugPrint('[WebRTC] Microphone access granted.');
      return _localStream!;
    } catch (e) {
      debugPrint('[WebRTC] Microphone init error: $e');
      rethrow;
    }
  }

  void _setupConnectionLogging() {
    _peerConnection?.onIceConnectionState = (state) {
      debugPrint('[WebRTC] ICE state: $state');
    };
    _peerConnection?.onConnectionState = (state) {
      debugPrint('[WebRTC] Connection state: $state');
    };
    _peerConnection?.onSignalingState = (state) {
      debugPrint('[WebRTC] Signaling state: $state');
    };
  }

  Future<void> startPatientCall(
    String chatId, {
    required Function(MediaStream stream) onRemoteStream,
    required Function(String status) onStatusChange,
  }) async {
    debugPrint('[WebRTC] === START PATIENT CALL ===');
    await cleanup();
    await _clearOldCandidates(chatId);
    final localStream = await _initLocalAudio();

    _peerConnection = await createPeerConnection(_rtcConfig);
    _setupConnectionLogging();

    localStream.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream);
      debugPrint('[WebRTC] Added local track: ${track.kind}');
    });

    _peerConnection?.onTrack = (event) {
      debugPrint('[WebRTC] Received remote track: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onRemoteStream(_remoteStream!);
      }
    };

    _peerConnection?.onIceCandidate = (candidate) async {
      if (candidate.candidate != null) {
        debugPrint('[WebRTC] Sending patient ICE candidate');
        await FirebaseFirestore.instance
            .collection('chats').doc(chatId)
            .collection('patient_candidates')
            .add(candidate.toMap());
      }
    };

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
    });
    await _peerConnection!.setLocalDescription(offer);
    debugPrint('[WebRTC] Created and set local offer');

    final callDocRef = FirebaseFirestore.instance
        .collection('chats').doc(chatId)
        .collection('webrtc').doc('session');
    await callDocRef.set({
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'answer': null,
      'status': 'ringing',
      'caller': 'user',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[WebRTC] Wrote offer to Firestore, status=ringing');

    // Listen for doctor's SDP answer
    _signalSub = callDocRef.snapshots().listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

      if (data.containsKey('answer') && data['answer'] != null &&
          _peerConnection?.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        debugPrint('[WebRTC] Received SDP answer from doctor');
        try {
          final answerMap = data['answer'] as Map<String, dynamic>;
          final answer = RTCSessionDescription(answerMap['sdp'], answerMap['type']);
          await _peerConnection?.setRemoteDescription(answer);
          debugPrint('[WebRTC] Remote description set successfully');
          onStatusChange('connected');
        } catch (e) {
          debugPrint('[WebRTC] Error setting remote description: $e');
        }
      }
      if (data['status'] == 'ended') {
        debugPrint('[WebRTC] Call ended by remote');
        onStatusChange('ended');
      }
    });

    // Listen for doctor's ICE candidates
    _candidatesSub = FirebaseFirestore.instance
        .collection('chats').doc(chatId)
        .collection('doctor_candidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added && _peerConnection != null) {
          // Only add if remote description is set
          if (_peerConnection?.getRemoteDescription() != null) {
            final data = change.doc.data();
            if (data != null) {
              debugPrint('[WebRTC] Adding doctor ICE candidate');
              final candidate = RTCIceCandidate(
                data['candidate'], data['sdpMid'], data['sdpMLineIndex'],
              );
              _peerConnection?.addCandidate(candidate);
            }
          }
        }
      }
    });
  }

  Future<void> answerDoctorCall(
    String chatId, {
    required Function(MediaStream stream) onRemoteStream,
    required Function(String status) onStatusChange,
  }) async {
    debugPrint('[WebRTC] === ANSWER DOCTOR CALL ===');
    await cleanup();
    final localStream = await _initLocalAudio();

    _peerConnection = await createPeerConnection(_rtcConfig);
    _setupConnectionLogging();

    localStream.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream);
      debugPrint('[WebRTC] Added local track: ${track.kind}');
    });

    _peerConnection?.onTrack = (event) {
      debugPrint('[WebRTC] Received remote track: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onRemoteStream(_remoteStream!);
      }
    };

    _peerConnection?.onIceCandidate = (candidate) async {
      if (candidate.candidate != null) {
        debugPrint('[WebRTC] Sending patient ICE candidate');
        await FirebaseFirestore.instance
            .collection('chats').doc(chatId)
            .collection('patient_candidates')
            .add(candidate.toMap());
      }
    };

    final callDocRef = FirebaseFirestore.instance
        .collection('chats').doc(chatId)
        .collection('webrtc').doc('session');
    final callSnap = await callDocRef.get();
    if (!callSnap.exists || !(callSnap.data()?.containsKey('offer') ?? false)) {
      debugPrint('[WebRTC] ERROR: No offer found to answer');
      return;
    }

    final offerMap = callSnap.data()!['offer'] as Map<String, dynamic>;
    debugPrint('[WebRTC] Setting remote description (doctor offer)...');
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(offerMap['sdp'], offerMap['type']),
    );

    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 0,
    });
    await _peerConnection!.setLocalDescription(answer);
    debugPrint('[WebRTC] Created and set local answer');

    await callDocRef.update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'connected',
      'answeredAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[WebRTC] Wrote answer to Firestore, status=connected');
    onStatusChange('connected');

    // Listen for doctor's ICE candidates
    _candidatesSub = FirebaseFirestore.instance
        .collection('chats').doc(chatId)
        .collection('doctor_candidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added && _peerConnection != null) {
          final data = change.doc.data();
          if (data != null) {
            debugPrint('[WebRTC] Adding doctor ICE candidate');
            final candidate = RTCIceCandidate(
              data['candidate'], data['sdpMid'], data['sdpMLineIndex'],
            );
            _peerConnection?.addCandidate(candidate);
          }
        }
      }
    });

    // Listen for status ended
    _signalSub = callDocRef.snapshots().listen((snap) {
      if (snap.exists && snap.data()?['status'] == 'ended') {
        debugPrint('[WebRTC] Call ended by remote');
        onStatusChange('ended');
      }
    });
  }

  void toggleMute() {
    if (_localStream != null) {
      isMuted = !isMuted;
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
      debugPrint('[WebRTC] Mute: $isMuted');
    }
  }

  void toggleSpeaker() {
    isSpeakerOn = !isSpeakerOn;
    if (_remoteStream != null) {
      for (var track in _remoteStream!.getAudioTracks()) {
        track.enableSpeakerphone(isSpeakerOn);
      }
    }
    debugPrint('[WebRTC] Speaker: $isSpeakerOn');
  }

  Future<void> endCall(String chatId) async {
    debugPrint('[WebRTC] === END CALL ===');
    try {
      final callDocRef = FirebaseFirestore.instance
          .collection('chats').doc(chatId)
          .collection('webrtc').doc('session');
      final snap = await callDocRef.get();
      if (snap.exists) {
        await callDocRef.update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[WebRTC] Error updating end call: $e');
    }
    await cleanup();
  }

  Future<void> cleanup() async {
    debugPrint('[WebRTC] Cleanup...');
    await _signalSub?.cancel();
    _signalSub = null;
    await _candidatesSub?.cancel();
    _candidatesSub = null;

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }

    _remoteStream = null;
    remoteRenderer.srcObject = null;
    isMuted = false;
  }
}
