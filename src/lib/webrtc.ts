import { db } from './firebase';
import {
  doc, setDoc, getDoc, updateDoc, onSnapshot, collection, addDoc, getDocs, deleteDoc, serverTimestamp
} from 'firebase/firestore';

const rtcConfig: RTCConfiguration = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
    { urls: 'stun:stun2.l.google.com:19302' },
  ],
};

class DoctorWebRTCService {
  private peerConnection: RTCPeerConnection | null = null;
  private localStream: MediaStream | null = null;
  private remoteStream: MediaStream | null = null;
  private unsubscribeSignal: (() => void) | null = null;
  private unsubscribeCandidates: (() => void) | null = null;
  public isMuted: boolean = false;

  private log(msg: string) {
    console.log(`[DoctorWebRTC] ${msg}`);
  }

  private async clearOldCandidates(chatId: string) {
    this.log('Clearing old ICE candidates...');
    const collections = ['doctor_candidates', 'patient_candidates'];
    for (const col of collections) {
      try {
        const snap = await getDocs(collection(db, 'chats', chatId, col));
        const deletes = snap.docs.map(d => deleteDoc(d.ref));
        await Promise.all(deletes);
      } catch (e) {
        this.log(`Notice: clearing ${col}: ${e}`);
      }
    }
    this.log('Old candidates cleared.');
  }

  async initLocalAudio(): Promise<MediaStream> {
    if (this.localStream) return this.localStream;
    try {
      this.log('Requesting microphone access...');
      this.localStream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
        video: false,
      });
      this.log('Microphone access granted.');
      return this.localStream;
    } catch (err) {
      this.log('Microphone error: ' + err);
      // Fallback silent stream
      const audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const osc = audioCtx.createOscillator();
      const dst = audioCtx.createMediaStreamDestination();
      osc.connect(dst);
      osc.start();
      this.localStream = dst.stream;
      return this.localStream;
    }
  }

  private setupConnectionStateLogging() {
    if (!this.peerConnection) return;
    this.peerConnection.oniceconnectionstatechange = () => {
      this.log('ICE state: ' + this.peerConnection?.iceConnectionState);
    };
    this.peerConnection.onconnectionstatechange = () => {
      this.log('Connection state: ' + this.peerConnection?.connectionState);
    };
    this.peerConnection.onsignalingstatechange = () => {
      this.log('Signaling state: ' + this.peerConnection?.signalingState);
    };
  }

  async startDoctorCall(
    chatId: string,
    onRemoteStream: (stream: MediaStream) => void,
    onStatusChange?: (status: string) => void
  ) {
    this.log('=== START DOCTOR CALL ===');
    await this.cleanup();
    await this.clearOldCandidates(chatId);
    const localStream = await this.initLocalAudio();

    this.peerConnection = new RTCPeerConnection(rtcConfig);
    this.setupConnectionStateLogging();

    localStream.getTracks().forEach((track) => {
      this.peerConnection?.addTrack(track, localStream);
      this.log('Added local track: ' + track.kind);
    });

    this.peerConnection.ontrack = (event) => {
      this.log('Received remote track: ' + event.track.kind);
      if (event.streams && event.streams[0]) {
        this.remoteStream = event.streams[0];
        onRemoteStream(this.remoteStream);
      }
    };

    this.peerConnection.onicecandidate = async (event) => {
      if (event.candidate) {
        this.log('Sending doctor ICE candidate');
        await addDoc(collection(db, 'chats', chatId, 'doctor_candidates'), event.candidate.toJSON());
      }
    };

    const offer = await this.peerConnection.createOffer({
      offerToReceiveAudio: true,
      offerToReceiveVideo: false,
    });
    await this.peerConnection.setLocalDescription(offer);
    this.log('Created and set local offer');

    const callDocRef = doc(db, 'chats', chatId, 'webrtc', 'session');
    await setDoc(callDocRef, {
      offer: { type: offer.type, sdp: offer.sdp },
      answer: null,
      status: 'ringing',
      caller: 'doctor',
      updatedAt: serverTimestamp(),
    });
    this.log('Wrote offer to Firestore, status=ringing');

    // Listen for answer
    this.unsubscribeSignal = onSnapshot(callDocRef, async (snap) => {
      if (!snap.exists()) return;
      const data = snap.data();
      if (data?.answer && this.peerConnection && this.peerConnection.signalingState === 'have-local-offer') {
        this.log('Received SDP answer from patient, setting remote description...');
        try {
          await this.peerConnection.setRemoteDescription(new RTCSessionDescription(data.answer));
          this.log('Remote description set successfully');
          onStatusChange?.('connected');
        } catch (e) {
          this.log('Error setting remote description: ' + e);
        }
      }
      if (data?.status === 'ended') {
        this.log('Call ended by remote');
        onStatusChange?.('ended');
      }
    });

    // Listen for patient ICE candidates
    this.unsubscribeCandidates = onSnapshot(collection(db, 'chats', chatId, 'patient_candidates'), (snapshot) => {
      snapshot.docChanges().forEach(async (change) => {
        if (change.type === 'added' && this.peerConnection && this.peerConnection.remoteDescription) {
          this.log('Adding patient ICE candidate');
          try {
            await this.peerConnection.addIceCandidate(new RTCIceCandidate(change.doc.data()));
          } catch (e) {
            this.log('Error adding patient ICE candidate: ' + e);
          }
        }
      });
    });
  }

  async answerPatientCall(
    chatId: string,
    onRemoteStream: (stream: MediaStream) => void,
    onStatusChange?: (status: string) => void
  ) {
    this.log('=== ANSWER PATIENT CALL ===');
    await this.cleanup();
    const localStream = await this.initLocalAudio();

    this.peerConnection = new RTCPeerConnection(rtcConfig);
    this.setupConnectionStateLogging();

    localStream.getTracks().forEach((track) => {
      this.peerConnection?.addTrack(track, localStream);
      this.log('Added local track: ' + track.kind);
    });

    this.peerConnection.ontrack = (event) => {
      this.log('Received remote track: ' + event.track.kind);
      if (event.streams && event.streams[0]) {
        this.remoteStream = event.streams[0];
        onRemoteStream(this.remoteStream);
      }
    };

    this.peerConnection.onicecandidate = async (event) => {
      if (event.candidate) {
        this.log('Sending doctor ICE candidate');
        await addDoc(collection(db, 'chats', chatId, 'doctor_candidates'), event.candidate.toJSON());
      }
    };

    const callDocRef = doc(db, 'chats', chatId, 'webrtc', 'session');
    const callSnap = await getDoc(callDocRef);
    if (!callSnap.exists() || !callSnap.data()?.offer) {
      this.log('ERROR: No offer found to answer');
      return;
    }

    const offer = callSnap.data()?.offer;
    this.log('Setting remote description (patient offer)...');
    await this.peerConnection.setRemoteDescription(new RTCSessionDescription(offer));

    const answer = await this.peerConnection.createAnswer();
    await this.peerConnection.setLocalDescription(answer);
    this.log('Created and set local answer');

    await updateDoc(callDocRef, {
      answer: { type: answer.type, sdp: answer.sdp },
      status: 'connected',
      answeredAt: serverTimestamp(),
    });
    this.log('Wrote answer to Firestore, status=connected');
    onStatusChange?.('connected');

    // Listen for patient ICE candidates
    this.unsubscribeCandidates = onSnapshot(collection(db, 'chats', chatId, 'patient_candidates'), (snapshot) => {
      snapshot.docChanges().forEach(async (change) => {
        if (change.type === 'added' && this.peerConnection && this.peerConnection.remoteDescription) {
          this.log('Adding patient ICE candidate');
          try {
            await this.peerConnection.addIceCandidate(new RTCIceCandidate(change.doc.data()));
          } catch (e) {
            this.log('Error adding candidate: ' + e);
          }
        }
      });
    });

    // Listen for status changes (ended)
    this.unsubscribeSignal = onSnapshot(callDocRef, (snap) => {
      if (snap.exists() && snap.data()?.status === 'ended') {
        this.log('Call ended by remote');
        onStatusChange?.('ended');
      }
    });
  }

  toggleMute(): boolean {
    if (!this.localStream) return false;
    this.isMuted = !this.isMuted;
    this.localStream.getAudioTracks().forEach((track) => { track.enabled = !this.isMuted; });
    this.log('Mute toggled: ' + this.isMuted);
    return this.isMuted;
  }

  async endCall(chatId: string) {
    this.log('=== END CALL ===');
    if (chatId) {
      try {
        const callDocRef = doc(db, 'chats', chatId, 'webrtc', 'session');
        const snap = await getDoc(callDocRef);
        if (snap.exists()) {
          await updateDoc(callDocRef, { status: 'ended', endedAt: serverTimestamp() });
        }
      } catch (e) {
        this.log('Error ending call: ' + e);
      }
    }
    await this.cleanup();
  }

  async cleanup() {
    this.log('Cleanup...');
    if (this.unsubscribeSignal) { this.unsubscribeSignal(); this.unsubscribeSignal = null; }
    if (this.unsubscribeCandidates) { this.unsubscribeCandidates(); this.unsubscribeCandidates = null; }
    if (this.localStream) { this.localStream.getTracks().forEach((t) => t.stop()); this.localStream = null; }
    if (this.peerConnection) { this.peerConnection.close(); this.peerConnection = null; }
    this.remoteStream = null;
    this.isMuted = false;
  }
}

export const doctorWebRTC = new DoctorWebRTCService();
