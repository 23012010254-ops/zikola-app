import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isSoundEnabled = true;
  bool get isSoundEnabled => _isSoundEnabled;
  
  String? _currentBGM;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _isMuted = !_isSoundEnabled;
    } catch (e) {
      debugPrint('AudioService init error: $e');
    }
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    _isMuted = !enabled;
    if (_isMuted) {
      await _bgmPlayer.setVolume(0);
    } else {
      await _bgmPlayer.setVolume(1);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', enabled);
    } catch (e) {
      debugPrint('Error saving sound setting: $e');
    }
  }

  Future<void> toggleMute() async {
    await setSoundEnabled(_isMuted); // isMuted=true means sound was off, so enable it
  }

  // ========== Convenience Methods ==========

  /// Play sound for correct answer
  Future<void> playCorrect() async => playSFX('correct.mp3');

  /// Play sound for wrong answer  
  Future<void> playWrong() async => playSFX('wrong.mp3');

  /// Play sound for button tap
  Future<void> playClick() async => playSFX('laser_shoot.mp3', volume: 0.2);

  /// Play sound for achievement/sticker unlock
  Future<void> playAchievement() async => playSFX('level_complete.mp3');

  /// Play sound for level up
  Future<void> playLevelUp() async => playSFX('level_complete.mp3');

  /// Play sound for game over
  Future<void> playGameOver() async => playSFX('game_over.mp3');

  /// Play sound for streak milestone
  Future<void> playStreak() async => playSFX('level_complete.mp3');

  /// Play sound for notification
  Future<void> playNotification() async => playSFX('notification-massage.wav', volume: 0.6);

  // ========== Background Music ==========

  /// Play background music (loops indefinitely)
  Future<void> playBGM(String fileName, {double volume = 1.0}) async {
    if (_currentBGM == fileName) {
      if (!_isMuted) await _bgmPlayer.setVolume(volume);
      return;
    }
    
    try {
      await _bgmPlayer.stop();
      _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      if (!_isMuted) await _bgmPlayer.setVolume(volume);
      await _bgmPlayer.play(AssetSource('audio/bgm/$fileName'));
      _currentBGM = fileName;
    } catch (e) {
      debugPrint('Error playing BGM: $e');
    }
  }

  /// Play the default home screen BGM
  Future<void> playHomeBGM() async => playBGM('personality_bgm.mp3.wav', volume: 0.3);

  /// Play the default game BGM
  Future<void> playGameBGM() async => playBGM('space_adventure.mp3', volume: 0.4);

  Future<void> stopBGM() async {
    await _bgmPlayer.stop();
    _currentBGM = null;
  }

  /// Play an effect once (can overlap with other sounds)
  Future<void> playSFX(String fileName, {double volume = 1.0}) async {
    if (_isMuted) return;
    
    try {
      final AudioPlayer sfxPlayer = AudioPlayer();
      await sfxPlayer.setVolume(volume);
      
      sfxPlayer.onPlayerComplete.listen((_) {
        sfxPlayer.dispose();
      });

      await sfxPlayer.play(AssetSource('audio/sfx/$fileName'));
    } catch (e) {
      // Silently fail if audio file doesn't exist yet
      debugPrint('SFX not available: $fileName');
    }
  }

  void dispose() {
    _bgmPlayer.dispose();
  }
}
