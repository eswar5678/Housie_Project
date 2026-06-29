class HousieTicket {
  final List<int> numbers; // 27 numbers (flat list of 3 rows * 9 columns)

  HousieTicket({required this.numbers});

  Map<String, dynamic> toMap() {
    return {'numbers': numbers};
  }

  factory HousieTicket.fromMap(Map<dynamic, dynamic> map) {
    var list = (map['numbers'] as List<dynamic>).cast<int>();
    if (list.length < 27) {
      list = [...list, ...List.filled(27 - list.length, 0)];
    }
    return HousieTicket(numbers: list);
  }
}

class Player {
  final String name;
  final String uid; // Added for security
  final bool isHost;
  final int ticketCount;
  final List<HousieTicket> tickets;
  final bool isOnline;

  Player({
    required this.name,
    required this.uid,
    this.isHost = false,
    this.ticketCount = 1,
    this.tickets = const [],
    this.isOnline = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uid': uid,
      'isHost': isHost,
      'ticketCount': ticketCount,
      'tickets': tickets.map((t) => t.toMap()).toList(),
      'isOnline': isOnline,
    };
  }

  factory Player.fromMap(Map<dynamic, dynamic> map) {
    var ticketsList = map['tickets'] as List<dynamic>? ?? [];
    return Player(
      name: map['name'] ?? '',
      uid: map['uid'] ?? '',
      isHost: map['isHost'] ?? false,
      ticketCount: map['ticketCount'] ?? 1,
      tickets: ticketsList.map((t) => HousieTicket.fromMap(t)).toList(),
      isOnline: map['isOnline'] ?? true,
    );
  }

  bool get hasSelectedTickets => tickets.isNotEmpty;
}

class HousieClaim {
  final String type; // 'early_five', 'top_line', 'middle_line', 'bottom_line', 'full_house'
  final String playerName;
  final int ticketIndex;
  final DateTime timestamp;

  HousieClaim({
    required this.type,
    required this.playerName,
    required this.ticketIndex,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'playerName': playerName,
      'ticketIndex': ticketIndex,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory HousieClaim.fromMap(Map<dynamic, dynamic> map) {
    return HousieClaim(
      type: map['type'] ?? '',
      playerName: map['playerName'] ?? '',
      ticketIndex: map['ticketIndex'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
}

class HousieRoom {
  final String roomId;
  final String roomName;
  final int maxPlayers;
  final String hostName;
  final double ticketPrice;
  final Map<String, Player> players; // Changed from List to Map for O(1) joins
  final String status; // 'lobby', 'playing', 'finished'
  final List<int> calledNumbers;
  final int? currentNumber;
  final List<HousieClaim> claims;
  final int? gameStartTimestamp;

  HousieRoom({
    required this.roomId,
    required this.roomName,
    required this.maxPlayers,
    required this.hostName,
    required this.ticketPrice,
    required this.players,
    this.status = 'lobby',
    this.calledNumbers = const [],
    this.currentNumber,
    this.lastCallTimestamp,
    this.claims = const [],
    this.gameStartTimestamp,
  });

  final int? lastCallTimestamp;

  // Helper to calculate prize pool
  double get totalPool => players.values.fold(0.0, (sum, p) => sum + (p.ticketCount * ticketPrice));

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'maxPlayers': maxPlayers,
      'hostName': hostName,
      'ticketPrice': ticketPrice,
      'players': players.map((k, v) => MapEntry(k, v.toMap())),
      'status': status,
      'calledNumbers': calledNumbers,
      'currentNumber': currentNumber,
      'lastCallTimestamp': lastCallTimestamp,
      'gameStartTimestamp': gameStartTimestamp,
      'claims': claims.map((c) => c.toMap()).toList(),
    };
  }

  factory HousieRoom.fromMap(Map<dynamic, dynamic> map) {
    var rawPlayers = map['players'] as Map<dynamic, dynamic>? ?? {};
    Map<String, Player> playersMap = {};
    rawPlayers.forEach((key, value) {
      playersMap[key.toString()] = Player.fromMap(value);
    });

    var claimsList = map['claims'] as List<dynamic>? ?? [];
    return HousieRoom(
      roomId: map['roomId'] ?? '',
      roomName: map['roomName'] ?? '',
      maxPlayers: map['maxPlayers'] ?? 0,
      hostName: map['hostName'] ?? '',
      ticketPrice: (map['ticketPrice'] ?? 0.0).toDouble(),
      players: playersMap,
      status: map['status'] ?? 'lobby',
      calledNumbers: (map['calledNumbers'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      currentNumber: map['currentNumber'],
      lastCallTimestamp: map['lastCallTimestamp'],
      gameStartTimestamp: map['gameStartTimestamp'],
      claims: claimsList.map((c) => HousieClaim.fromMap(c)).toList(),
    );
  }
}
