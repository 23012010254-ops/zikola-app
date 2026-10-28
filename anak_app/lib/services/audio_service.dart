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
  String? get currentBGM => _currentBGM;

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
      await pauseBGM();
    } else {
      await resumeBGM();
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
  Future<void> playCorrect() async => playSFX('correct.mp3', volume: 0.7);

  /// Play sound for wrong answer  
  Future<void> playWrong() async => playSFX('wrong.mp3', volume: 0.6);

  /// Play sound for button tap / UI tactile feedback
  Future<void> playClick() async => playSFX('click.mp3', volume: 0.4);

  /// Play crisp bubble popping sound
  Future<void> playPop() async => playSFX('pop.mp3', volume: 0.6);

  /// Play bubble sound effect
  Future<void> playBubble() async => playSFX('bubble.mp3', volume: 0.6);

  /// Play card flip / turn effect
  Future<void> playFlip() async => playSFX('card_flip.mp3', volume: 0.6);

  /// Play swipe / swish / brush stroke sound
  Future<void> playSwish() async => playSFX('swish.mp3', volume: 0.5);

  /// Play magic sparkle / star reward sound
  Future<void> playSparkle() async => playSFX('sparkle.mp3', volume: 0.7);

  /// Play laser shoot sound
  Future<void> playLaser() async => playSFX('laser_shoot.mp3', volume: 0.5);

  /// Play sound for achievement/sticker unlock
  Future<void> playAchievement() async => playSFX('level_complete.mp3', volume: 0.8);

  /// Play sound for level up
  Future<void> playLevelUp() async => playSFX('level_complete.mp3', volume: 0.8);

  /// Play sound for game over
  Future<void> playGameOver() async => playSFX('game_over.mp3', volume: 0.6);

  /// Play sound for streak milestone
  Future<void> playStreak() async => playSFX('level_complete.mp3', volume: 0.8);

  /// Play sound for notification
  Future<void> playNotification() async => playSFX('notification-massage.wav', volume: 0.6);

  // ========== Background Music ==========

  /// Play background music (loops indefinitely with duplicate prevention)
  Future<void> playBGM(String fileName, {double volume = 0.3}) async {
    if (_isMuted || !_isSoundEnabled) return;
    if (_currentBGM == fileName) return;
    _currentBGM = fileName;

    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(volume);
      await _bgmPlayer.play(AssetSource('audio/bgm/$fileName'));
      debugPrint('BGM started: $fileName at volume $volume');
    } catch (e) {
      debugPrint('BGM playback notice ($fileName): $e');
    }
  }

  /// Pause current background music
  Future<void> pauseBGM() async {
    try {
      await _bgmPlayer.pause();
    } catch (_) {}
  }

  /// Resume current background music
  Future<void> resumeBGM() async {
    if (_isMuted || !_isSoundEnabled) return;
    try {
      await _bgmPlayer.resume();
    } catch (_) {}
  }

  /// Stop current background music
  Future<void> stopBGM() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
    _currentBGM = null;
  }

  /// Play the cheerful home screen BGM
  Future<void> playHomeBGM() async => playBGM('cheerful_kids_bgm.mp3', volume: 0.25);

  /// Play the adventure game BGM (desert, exploration)
  Future<void> playAdventureBGM() async => playBGM('adventure_music.mp3', volume: 0.25);

  /// Play the puzzle game BGM (logic, mirror, memory)
  Future<void> playPuzzleBGM() async => playBGM('puzzle_music.mp3', volume: 0.25);

  /// Play upbeat arcade game BGM (bubbles, speed arcade)
  Future<void> playArcadeBGM() async => playBGM('arcade_fun_bgm.mp3', volume: 0.25);

  /// Play curious mystery game BGM (maze, shadows, pipes)
  Future<void> playMysteryBGM() async => playBGM('curious_mystery_bgm.mp3', volume: 0.25);

  /// Play night mode BGM
  Future<void> playNightBGM() async => playBGM('cheerful_kids_bgm.mp3', volume: 0.15);

  /// Play the default game BGM (space, arcade)
  Future<void> playGameBGM() async => playBGM('space_adventure.mp3', volume: 0.25);

  static const Map<String, String> _sfxAliases = {
    'completion.mp3': 'level_complete.mp3',
    'success.mp3': 'level_complete.mp3',
    'match_success.mp3': 'level_complete.mp3',
    'match_fail.mp3': 'wrong.mp3',
  };

  /// Play an effect once (can overlap with other sounds)
  Future<void> playSFX(String fileName, {double volume = 1.0}) async {
    if (_isMuted || !_isSoundEnabled) return;
    final resolvedFile = _sfxAliases[fileName] ?? fileName;
    
    AudioPlayer? sfxPlayer;
    try {
      sfxPlayer = AudioPlayer();
      await sfxPlayer.setVolume(volume);
      
      sfxPlayer.onPlayerComplete.listen((_) {
        sfxPlayer?.dispose();
      });

      await sfxPlayer.play(AssetSource('audio/sfx/$resolvedFile'));
    } catch (e) {
      debugPrint('SFX playback notice ($resolvedFile): $e');
      try {
        sfxPlayer?.dispose();
      } catch (_) {}
    }
  }

  /// Alias for playSFX
  Future<void> playSfx(String fileName, {double volume = 1.0}) => playSFX(fileName, volume: volume);

  void dispose() {
    _bgmPlayer.dispose();
  }
}
