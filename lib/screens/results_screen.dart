import 'package:flutter/material.dart';
import '../models/room.dart';
import '../widgets/geometric_background.dart';
import '../widgets/housie_ticket_widget.dart';
import '../services/persistence_service.dart';
import '../services/game_service.dart';

class ResultsScreen extends StatefulWidget {
  final HousieRoom room;

  const ResultsScreen({super.key, required this.room});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    _checkHostAndClear();
  }

  Future<void> _checkHostAndClear() async {
    final session = await PersistenceService().getLastSession();
    if (session != null && mounted) {
      setState(() {
        _isHost = session['isHost'] ?? false;
      });
    }
    PersistenceService().clearSession();
  }

  String _getClaimLabel(String type) {
    switch (type) {
      case 'early_five': return 'Early 5';
      case 'top_line': return 'Top Line';
      case 'middle_line': return 'Middle Line';
      case 'bottom_line': return 'Bottom Line';
      case 'full_house': return 'Full House';
      default: return type.toUpperCase();
    }
  }

  // Smart Prize Calculation Logic
  Map<String, int> _calculatePrizes(double totalPool) {
    // Weights: Lines = 4, Early5 = 6, FullHouse = 10. Total = (4*3) + 6 + 10 = 28.
    // This ensures: Full House > Early 5 > Lines
    const weights = {
      'top_line': 4,
      'middle_line': 4,
      'bottom_line': 4,
      'early_five': 6,
      'full_house': 10,
    };
    
    int totalWeight = 28;
    double unit = totalPool / totalWeight;
    
    Map<String, int> prizes = {};
    int distributed = 0;
    
    // Calculate floors for all except Full House
    for (var type in ['top_line', 'middle_line', 'bottom_line', 'early_five']) {
      int prize = (unit * weights[type]!).floor();
      prizes[type] = prize;
      distributed += prize;
    }
    
    // Full House gets the remainder to ensure 100% distribution and integer values
    prizes['full_house'] = (totalPool.toInt() - distributed);
    
    return prizes;
  }

  Widget _buildWinningTickets(BuildContext context) {
    final winningClaims = widget.room.claims.toList();

    if (winningClaims.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text(
            'No winning claims registered.',
            style: TextStyle(color: Colors.white30, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: winningClaims.map((claim) {
        final playerKey = claim.playerName.toUpperCase();
        final player = widget.room.players[playerKey];
        if (player == null || player.tickets.isEmpty || claim.ticketIndex >= player.tickets.length) {
          return const SizedBox.shrink();
        }

        final ticket = player.tickets[claim.ticketIndex];
        
        final markedIndices = <int>{};
        for (int i = 0; i < ticket.numbers.length; i++) {
          final number = ticket.numbers[i];
          if (number != 0 && widget.room.calledNumbers.contains(number)) {
            markedIndices.add(i);
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getClaimLabel(claim.type),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Claimed by: ${claim.playerName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              HousieTicketWidget(
                ticket: ticket,
                markedIndices: markedIndices,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prizes = _calculatePrizes(widget.room.totalPool);
    final allPrizeTypes = ['early_five', 'top_line', 'middle_line', 'bottom_line', 'full_house'];

    return Scaffold(
      backgroundColor: const Color(0xFF102A43),
      body: GeometricBackground(
        shapes: [
          BackgroundShapeItem(
            shape: BackgroundShape.circle,
            color: const Color(0xFF4DB6AC),
            size: 300,
            top: -100,
            left: -100,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.hexagon,
            color: const Color(0xFF9575CD),
            size: 200,
            bottom: -50,
            right: -50,
            rotation: 0.5,
          ),
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.room.roomName.toUpperCase(),
                  style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              const Text('TOTAL PRIZE POOL', 
                                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              const SizedBox(height: 8),
                              Text('₹${widget.room.totalPool.toInt()}', 
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Text(
                          'RESULTS TABLE',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        const SizedBox(height: 12),
                        
                        // Result Table UI
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(2.5),
                              2: FlexColumnWidth(1.5),
                            },
                            children: [
                              // Table Header
                              TableRow(
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
                                children: const [
                                  Padding(padding: EdgeInsets.all(16), child: Text('PRIZE', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(16), child: Text('WINNER', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(16), child: Text('EARNED', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              // Table Rows
                              ...allPrizeTypes.map((type) {
                                final claim = widget.room.claims.where((c) => c.type == type).firstOrNull;
                                final isWinner = claim != null;
                                
                                return TableRow(
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.white10.withValues(alpha: 0.1))),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                      child: Text(_getClaimLabel(type), 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                      child: Text(isWinner ? claim.playerName : '---', 
                                        style: TextStyle(color: isWinner ? Colors.white70 : Colors.white24, fontSize: 13)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                      child: Text('₹${prizes[type]}', 
                                        style: TextStyle(color: isWinner ? Colors.greenAccent : Colors.white24, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        const Text(
                          'WINNING TICKETS',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        const SizedBox(height: 12),
                        _buildWinningTickets(context),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (_isHost) {
                      await GameService().deleteRoom(widget.room.roomId);
                    }
                    navigator.popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
