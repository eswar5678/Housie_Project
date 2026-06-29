import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/room.dart';
import '../services/game_service.dart';
import '../services/persistence_service.dart';
import '../widgets/housie_ticket_widget.dart';
import '../widgets/geometric_background.dart';
import 'results_screen.dart';

class GameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  const GameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Map<int, Set<int>> _ticketMarkings = {};
  bool _isSoundOn = true;
  
  // Countdown and auto-calling state
  Timer? _countdownTimer;
  
  bool _isCallingNext = false;
  double _serverTimeOffset = 0;
  bool _isPromoting = false;
  Timer? _syncTimer;
  StreamSubscription<HousieRoom?>? _roomSubscription;
  HousieRoom? _room;
  HousieRoom? _latestRoom;
  bool _isNavigatedToResults = false;

  @override
  void initState() {
    super.initState();
    _saveSession();

    // Mark as online when rejoining/entering
    GameService().updatePlayerStatus(widget.roomId, widget.playerName, true);
    
    // Track server time offset for synchronization
    FirebaseDatabase.instance.ref(".info/serverTimeOffset").onValue.listen((event) {
      if (mounted) {
        setState(() {
          _serverTimeOffset = (event.snapshot.value as num? ?? 0.0).toDouble();
        });
      }
    });

    _roomSubscription = GameService().getRoomStream(widget.roomId).listen((room) {
      if (room != null) {
        if (mounted) {
          setState(() {
            _room = room;
            _latestRoom = room;
          });

          if (room.status == 'finished' && !_isNavigatedToResults) {
            _isNavigatedToResults = true;
            _stopCountdownCycle();
            _syncTimer?.cancel();
            PersistenceService().clearSession();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ResultsScreen(room: room)),
            );
          }

          if (room.gameStartTimestamp != null && _countdownTimer == null) {
            _startCountdownCycle();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _stopCountdownCycle();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveSession() async {
    await PersistenceService().saveGameSession(
      roomId: widget.roomId,
      playerName: widget.playerName,
      isHost: widget.isHost,
    );
  }

  void _onNumberTap(int ticketIndex, int cellIndex, int number, List<int> calledNumbers) {
    // Only mark if number has been called, no alert otherwise
    if (calledNumbers.contains(number)) {
      setState(() {
        if (!_ticketMarkings.containsKey(ticketIndex)) {
          _ticketMarkings[ticketIndex] = {};
        }
        if (!_ticketMarkings[ticketIndex]!.contains(cellIndex)) {
          _ticketMarkings[ticketIndex]!.add(cellIndex);
        }
      });
    }
  }

  // Start the sync cycle when game starts
  void _startCountdownCycle() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Handle side effects outside of build
      if (_latestRoom != null) {
        final room = _latestRoom!;
        _checkHostHandoff(room);

        final serverNow = DateTime.now().millisecondsSinceEpoch + _serverTimeOffset.toInt();
        final lastCall = room.lastCallTimestamp;
        final startTimestamp = room.gameStartTimestamp;

        if (room.status == 'playing') {
          if (room.calledNumbers.isEmpty && startTimestamp != null) {
            final elapsed = (serverNow - startTimestamp) / 1000;
            if (elapsed >= 10 && room.hostName.toUpperCase() == widget.playerName.trim().toUpperCase() && !_isCallingNext) {
              _isCallingNext = true;
              GameService().callNextNumber(widget.roomId).then((_) => _isCallingNext = false);
            }
          } else if (room.calledNumbers.isNotEmpty && lastCall != null) {
            final elapsed = (serverNow - lastCall) / 1000;
            if (elapsed >= 5 && room.hostName.toUpperCase() == widget.playerName.trim().toUpperCase() && !_isCallingNext) {
              _isCallingNext = true;
              GameService().callNextNumber(widget.roomId).then((_) => _isCallingNext = false);
            }
          }
        }
      }

      setState(() {
        // Build method handles UI calculations based on server time
      });
    });
  }

  void _stopCountdownCycle() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }



  void _checkHostHandoff(HousieRoom room) {
    if (_isPromoting) return;

    final hostKey = room.hostName.toUpperCase();
    final host = room.players[hostKey];
    
    // If the host is missing OR is offline, pick a new host
    if (host == null || !host.isOnline) {
      _isPromoting = true;
      // Pick the first available online player
      final players = room.players.entries
          .where((e) => e.value.isOnline)
          .map((e) => e.key)
          .toList()..sort();
      if (players.isNotEmpty) {
        final newHost = players.first;
        debugPrint('Host $hostKey left. Promoting $newHost to Host.');
        GameService().promoteNewHost(widget.roomId, room.players[newHost]!.name).then((_) {
          _isPromoting = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF102A43),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('QUIT GAME?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to leave the game? Your progress will be saved.', 
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              await GameService().leaveRoom(widget.roomId, widget.playerName);
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('QUIT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _showClaimDialog(int ticketIndex, HousieRoom room) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final claimTypes = {
          'early_five': 'Early 5',
          'top_line': 'Top Line',
          'middle_line': 'Middle Line',
          'bottom_line': 'Bottom Line',
          'full_house': 'Full House',
        };

        return AlertDialog(
          backgroundColor: const Color(0xFF102A43),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('SELECT CLAIM', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: claimTypes.entries.map((entry) {
              final isClaimed = room.claims.any((c) => c.type == entry.key);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(entry.value, 
                  style: TextStyle(
                    color: isClaimed ? Colors.white24 : Colors.white,
                    fontWeight: isClaimed ? FontWeight.normal : FontWeight.bold,
                  )),
                trailing: isClaimed 
                  ? const Text('CLAIMED', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))
                  : const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 14),
                onTap: isClaimed ? null : () async {
                  Navigator.pop(dialogContext);
                  final error = await GameService().submitClaim(
                    widget.roomId, widget.playerName, ticketIndex, entry.key
                  );
                  if (error != null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Validating your ${entry.value} claim...'), 
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
            ),
          ],
        );
      },
    );
  }

  void _showBoardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => StreamBuilder<HousieRoom?>(
        stream: GameService().getRoomStream(widget.roomId),
        builder: (context, snapshot) {
          final room = snapshot.data;
          final calledNumbers = room?.calledNumbers ?? [];

          return Dialog(
            backgroundColor: const Color(0xFF102A43),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NUMBER BOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: 90,
                    itemBuilder: (context, index) {
                      int num = index + 1;
                      bool isCalled = calledNumbers.contains(num);
                      return Container(
                        decoration: BoxDecoration(
                          color: isCalled ? Colors.amber : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '$num',
                            style: TextStyle(
                              color: isCalled ? Colors.black : Colors.white24,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE', style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _room == null 
        ? const Scaffold(
            backgroundColor: Color(0xFF102A43),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          )
        : _buildGameContent(_room!),
    );
  }

  Widget _buildGameContent(HousieRoom room) {
    final serverNow = DateTime.now().millisecondsSinceEpoch + _serverTimeOffset.toInt();
    final lastCall = room.lastCallTimestamp;
    final startTimestamp = room.gameStartTimestamp;

    // Side Effects check (for safety, though we have the listener)
    _checkHostHandoff(room);

    // Sync cycle logic (10s total interval)
    int localCountdown = 10;
    
    if (room.status == 'playing') {
      if (room.calledNumbers.isEmpty && startTimestamp != null) {
        // Initial 10s countdown
        final elapsed = (serverNow - startTimestamp) / 1000;
        if (elapsed < 10) {
          localCountdown = (10 - elapsed).ceil();
        }
      } else if (room.calledNumbers.isNotEmpty && lastCall != null) {
        // Regular cycle 5s
        final elapsed = (serverNow - lastCall) / 1000;
        if (elapsed < 5) {
          localCountdown = (5 - elapsed).ceil();
        } else {
          localCountdown = 0;
        }
      }
    }

    // Updated labels and number display logic
    String localLabel = "";
    if (room.calledNumbers.isEmpty) {
      localLabel = "Game starting in ${localCountdown}s";
    } else {
      localLabel = "Calling in ${localCountdown}s...";
    }

    final displayNum = room.calledNumbers.isNotEmpty 
        ? room.currentNumber.toString().padLeft(2, '0') 
        : '--';

          // Final check: if finished, we already handle in listener, but for safety:
          if (room.status == 'finished') {
            return const Scaffold(backgroundColor: Color(0xFF102A43), body: Center(child: CircularProgressIndicator()));
          }
          
          final pKey = widget.playerName.trim().toUpperCase();
          final currentPlayer = room.players[pKey];
          
          if (currentPlayer == null) {
            return const Scaffold(
              backgroundColor: Color(0xFF102A43),
              body: Center(child: Text('Player not found in room!', style: TextStyle(color: Colors.white))),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFF0D1B3E),
            body: Stack(
              children: [
                GeometricBackground(
                  shapes: [
                    BackgroundShapeItem(shape: BackgroundShape.circle, color: const Color(0xFF4DB6AC), size: 200, top: -50, left: -50),
                    BackgroundShapeItem(shape: BackgroundShape.hexagon, color: const Color(0xFF9575CD), size: 150, bottom: 100, right: -30),
                    BackgroundShapeItem(shape: BackgroundShape.square, color: const Color(0xFF1E88E5), size: 100, top: 150, right: 20),
                  ],
                  child: const SizedBox.expand(),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Players Count & Board
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(15)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text('${room.players.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showBoardDialog(context),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.grid_on, color: Color(0xFFFFD54F), size: 24),
                                      SizedBox(width: 4),
                                      Text('BOARD', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 9, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Small Centered Ring
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 80,
                                  width: 80,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 65, height: 65,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle, color: Colors.white,
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
                                          border: Border.all(color: Colors.grey.shade300, width: 3),
                                        ),
                                        child: Center(
                                          child: Text(
                                            displayNum,
                                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF102A43)),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 76, height: 76,
                                        child: CircularProgressIndicator(
                                          value: room.calledNumbers.isEmpty ? (localCountdown / 10) : (localCountdown / 5),
                                          strokeWidth: 3,
                                          color: const Color(0xFFFF8A65),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  localLabel,
                                  style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),

                            // Controls
                            IconButton(
                              icon: Icon(_isSoundOn ? Icons.volume_up : Icons.volume_off, color: Colors.white, size: 24),
                              onPressed: () => setState(() => _isSoundOn = !_isSoundOn),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Previous numbers display
                      SizedBox(
                        height: 45,
                        child: room.calledNumbers.isNotEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              itemCount: room.calledNumbers.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                final number = room.calledNumbers[room.calledNumbers.length - 1 - index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: index == 0 ? Colors.amber.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: index == 0 ? Colors.amber : Colors.white24, width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      number.toString().padLeft(2, '0'),
                                      style: TextStyle(color: index == 0 ? Colors.amber : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: currentPlayer.tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = currentPlayer.tickets[index];
                            final ticketMarked = _ticketMarkings[index] ?? {};
                            return Center(
                              key: ValueKey('ticket_$index'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: SizedBox(
                                  width: (MediaQuery.of(context).size.width * 0.9).clamp(280.0, 400.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _showClaimDialog(index, room),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF8A65), foregroundColor: Colors.white,
                                              elevation: 4, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            ),
                                            child: const Text('Claim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          HousieTicketWidget(
                                            ticket: ticket, markedIndices: ticketMarked,
                                            onNumberTap: (cellIdx) => _onNumberTap(index, cellIdx, ticket.numbers[cellIdx], room.calledNumbers),
                                          ),
                                          Positioned(
                                            top: -12, right: 10,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                                              child: Text('₹${room.ticketPrice.toInt()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
