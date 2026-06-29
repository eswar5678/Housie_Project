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
}
