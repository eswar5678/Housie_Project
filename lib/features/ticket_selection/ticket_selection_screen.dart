import 'package:flutter/material.dart';

import '../../models/room.dart';
import '../../services/game_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/housie_ticket_widget.dart';
import '../../core/widgets/app_panel.dart';
import '../../core/theme/app_theme.dart';
import '../lobby/lobby_screen.dart';

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
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 8, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: _buildCarouselPanel()),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: _buildSummaryPanel()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Tickets',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Room ID: ${widget.roomId}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: _isLoading ? null : _refreshPool,
              icon: const Icon(Icons.refresh),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 44),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _ticketPool.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndices.contains(index);

                    double difference = index - _currentPage;
                    double scale =
                        (1 - (difference.abs() * 0.08)).clamp(0.85, 1.0);
                    double opacity =
                        (1 - (difference.abs() * 0.3)).clamp(0.5, 1.0);

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
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_ticketPool.length, (index) {
                double currentPercent =
                    (1 - (index - _currentPage).abs()).clamp(0.0, 1.0);
                return Container(
                  width: 8 + (currentPercent * 8),
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: currentPercent > 0.5 ? AppColors.accent : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryPanel() {
    final selected = _selectedIndices.toList()..sort();
    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'SELECTION SUMMARY',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
              const Spacer(),
              Text(
                '${_selectedIndices.length} / 6',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            child: LinearProgressIndicator(
              value: _selectedIndices.length / 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedIndices.isEmpty)
            const Text(
              'Tap a ticket on the left to select it. You can pick up to 6 tickets.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            )
          else ...[
            const Text(
              'SELECTED TICKETS',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected
                  .map((i) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Ticket #${i + 1}',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const Spacer(),
          GlowButton(
            label: 'CONFIRM SELECTION',
            icon: Icons.check_circle_rounded,
            gradient: AppColors.successGradient,
            glowColor: AppColors.success,
            foregroundColor: AppColors.onAccent,
            height: 52,
            onPressed: _selectedIndices.isNotEmpty ? _confirmSelection : null,
          ),
        ],
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
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(
            color: isSelected
                ? AppColors.success
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.25),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TICKET #${index + 1}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.success
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
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
