import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/game_service.dart';
import '../widgets/custom_app_bar.dart';
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

  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
    _loadTicketPool();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
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
              // Header & Progress Tracker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Tickets',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Room ID: ${widget.roomId}',
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                        // Refresh button styled floating-like
                        IconButton.filledTonal(
                          onPressed: _isLoading ? null : _refreshPool,
                          icon: const Icon(Icons.refresh),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Progress bar
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.style, color: Colors.amber, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'SELECTION PROGRESS',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    Text(
                                      '${_selectedIndices.length} / 6 selected',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _selectedIndices.length / 6,
                                    backgroundColor: Colors.white10,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Carousel PageView Area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _ticketPool.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedIndices.contains(index);
                          
                          // Scaling transform based on page slider position
                          double difference = index - _currentPage;
                          double scale = (1 - (difference.abs() * 0.08)).clamp(0.85, 1.0);
                          double opacity = (1 - (difference.abs() * 0.3)).clamp(0.5, 1.0);

                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: _buildTicketCard(index, isSelected),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Page Indicators
              if (!_isLoading)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_ticketPool.length, (index) {
                    double currentPercent = (1 - (index - _currentPage).abs()).clamp(0.0, 1.0);
                    return Container(
                      width: 8 + (currentPercent * 8),
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: currentPercent > 0.5 ? Colors.amber : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

              const SizedBox(height: 24),

              // Confirm Selection Action Button
              Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _selectedIndices.isNotEmpty
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: _selectedIndices.isNotEmpty ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                      foregroundColor: Colors.black,
                      disabledForegroundColor: Colors.white30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CONFIRM SELECTION →',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(int index, bool isSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIndices.remove(index);
          } else {
            if (_selectedIndices.length < 6) {
              _selectedIndices.add(index);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You can select a maximum of 6 tickets!')),
              );
            }
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF162A45).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.greenAccent : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
        ),
        child: Column(
          children: [
            // Card Header details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TICKET #${index + 1}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.greenAccent : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.black : Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSelected ? 'SELECTED' : 'SELECT',
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Actual Ticket Grid
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Transform.scale(
                    scale: 0.85,
                    child: IgnorePointer(
                      child: HousieTicketWidget(
                        ticket: _ticketPool[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
