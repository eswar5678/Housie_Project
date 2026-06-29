import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/game_service.dart';
import '../widgets/geometric_background.dart';
import '../widgets/housie_ticket_widget.dart';
import 'lobby_screen.dart';

class TicketSelectionScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;

  const TicketSelectionScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  List<HousieTicket> _ticketPool = [];
  final Set<int> _selectedIndices = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicketPool();
  }

  Future<void> _loadTicketPool() async {
    setState(() => _isLoading = true);
    final pool = await GameService().generateTicketPool();
    setState(() {
      _ticketPool = pool;
      _isLoading = false;
    });
  }

  Future<void> _refreshPool() async {
    await _loadTicketPool();
    setState(() => _selectedIndices.clear());
  }

  Future<void> _confirmSelection() async {
    if (_selectedIndices.isEmpty) return;

    final selectedTickets = _selectedIndices.map((i) => _ticketPool[i]).toList();
    await GameService().updatePlayerTickets(
      widget.roomId,
      widget.playerName,
      selectedTickets.length,
      selectedTickets,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyScreen(
          roomId: widget.roomId,
          playerName: widget.playerName,
          isHost: widget.isHost,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'SELECT YOUR TICKET',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Room: ${widget.roomId}',
                      style: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Refresh Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _refreshPool,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REFRESH POOL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Ticket List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _ticketPool.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedIndices.contains(index);
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIndices.remove(index);
                                  } else {
                                    if (_selectedIndices.length < 6) {
                                      _selectedIndices.add(index);
                                    }
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? Colors.greenAccent : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.greenAccent.withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    // Ticket with standard scale for better fit
                                    Transform.scale(
                                      scale: 0.85,
                                      child: IgnorePointer(
                                        child: HousieTicketWidget(
                                          ticket: _ticketPool[index],
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.black,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Confirm Button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (_selectedIndices.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '${_selectedIndices.length} Ticket(s) Selected',
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _selectedIndices.isNotEmpty ? _confirmSelection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: const Text(
                        'CONFIRM SELECTION',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
