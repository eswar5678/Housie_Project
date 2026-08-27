import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static final PersistenceService _instance = PersistenceService._internal();
  factory PersistenceService() => _instance;
  PersistenceService._internal() {
    _initFallingBallsState();
  }

  static const String _keyRoomId = 'last_room_id';
  static const String _keyPlayerName = 'last_player_name';
  static const String _keyIsHost = 'last_is_host';

  Future<void> saveGameSession({
    required String roomId,
    required String playerName,
    required bool isHost,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoomId, roomId);
    await prefs.setString(_keyPlayerName, playerName);
    await prefs.setBool(_keyIsHost, isHost);
  }

  Future<Map<String, dynamic>?> getLastSession() async {
    final prefs = await SharedPreferences.getInstance();
    final roomId = prefs.getString(_keyRoomId);
    final playerName = prefs.getString(_keyPlayerName);
    final isHost = prefs.getBool(_keyIsHost);

    if (roomId != null && playerName != null && isHost != null) {
      return {
        'roomId': roomId,
        'playerName': playerName,
        'isHost': isHost,
      };
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRoomId);
    await prefs.remove(_keyPlayerName);
    await prefs.remove(_keyIsHost);
  }

  static const String _keyDefaultPlayerName = 'default_player_name';
  static const String _keyHasSeenTutorial = 'has_seen_tutorial';

  Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenTutorial) ?? false;
  }

  Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenTutorial, true);
  }

  Future<void> saveDefaultPlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultPlayerName, name);
  }

  Future<String?> getDefaultPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultPlayerName);
  }

  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyMusicEnabled = 'music_enabled';
  static const String _keyFallingBallsEnabled = 'falling_balls_enabled';

  // Global reactive notifier for instant background toggling
  static final ValueNotifier<bool> fallingBallsNotifier = ValueNotifier<bool>(true);

  Future<void> _initFallingBallsState() async {
    final prefs = await SharedPreferences.getInstance();
    fallingBallsNotifier.value = prefs.getBool(_keyFallingBallsEnabled) ?? true;
  }

  Future<bool> isFallingBallsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyFallingBallsEnabled) ?? true;
    fallingBallsNotifier.value = enabled;
    return enabled;
  }

  Future<void> setFallingBallsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFallingBallsEnabled, enabled);
    fallingBallsNotifier.value = enabled;
  }

  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundEnabled) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
  }

  Future<bool> isMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMusicEnabled) ?? true;
  }

  Future<void> setMusicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMusicEnabled, enabled);
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenTutorial, false);
  }

  // ================= RATING LOGIC =================
  static const String _keyHasRatedApp = 'has_rated_app';
  static const String _keyGameFinishedCount = 'games_finished_count';
  static const String _keyLastRatingPromptTime = 'last_rating_prompt_time';

  Future<bool> hasRatedApp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasRatedApp) ?? false;
  }

  Future<void> markAppAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasRatedApp, true);
  }

  Future<bool> shouldShowRatingPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyRated = prefs.getBool(_keyHasRatedApp) ?? false;
    if (alreadyRated) return false;

    final int gamesCount = (prefs.getInt(_keyGameFinishedCount) ?? 0) + 1;
    await prefs.setInt(_keyGameFinishedCount, gamesCount);

    final int? lastPromptTime = prefs.getInt(_keyLastRatingPromptTime);
    final int now = DateTime.now().millisecondsSinceEpoch;

    // Don't bother the user more than once every 48 hours
    if (lastPromptTime != null) {
      final int diffHours = ((now - lastPromptTime) / (1000 * 60 * 60)).floor();
      if (diffHours < 48) {
        return false;
      }
    }

    // Only prompt after game 1, and subsequently every 4 completed games
    if (gamesCount == 1 || gamesCount % 4 == 0) {
      await prefs.setInt(_keyLastRatingPromptTime, now);
      return true;
    }

    return false;
  }
}
