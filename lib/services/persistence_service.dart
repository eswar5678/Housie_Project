import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static final PersistenceService _instance = PersistenceService._internal();
  factory PersistenceService() => _instance;
  PersistenceService._internal();

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
}
