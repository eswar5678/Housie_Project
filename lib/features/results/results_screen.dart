import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/room.dart';
import '../../core/widgets/geometric_background.dart';
import '../../core/widgets/housie_ticket_widget.dart';
import '../../core/widgets/app_panel.dart';
import '../../services/persistence_service.dart';
import '../../services/game_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/theme/app_theme.dart';

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

    // Show rate us popup after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showRateUsDialog();
      }
    });
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
      case 'early_five':
        return 'Early 5';
      case 'top_line':
        return 'Top Line';
      case 'middle_line':
        return 'Middle Line';
      case 'bottom_line':
        return 'Bottom Line';
      case 'full_house':
        return 'Full House';
      default:
        return type.toUpperCase();
    }
  }

  void _showRateUsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int selectedStars = 0;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.white54, size: 24),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.star, color: AppColors.accent, size: 50),
                          Positioned(top: 15, left: 15, child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle))),
                          Positioned(bottom: 20, right: 15, child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle))),
                          Positioned(top: 25, right: 10, child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.lightBlueAccent, shape: BoxShape.circle))),
                          Positioned(bottom: 15, left: 20, child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Enjoying the game?',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text(
                      'If you like Tambola Multiplayer,\nplease take a moment to rate us.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => selectedStars = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < selectedStars ? Icons.star : Icons.star_border,
                              color: AppColors.accent,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap a star to rate', style: TextStyle(color: Colors.white30, fontSize: 12)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final Uri url = Uri.parse(
                              'https://play.google.com/store/apps/details?id=com.housie.developerbros');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          elevation: 8,
                        ),
                        child: const Text('Rate the App',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Maybe Later',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Smart Prize Calculation Logic
  Map<String, int> _calculatePrizes(double totalPool) {
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

    for (var type in ['top_line', 'middle_line', 'bottom_line', 'early_five']) {
      int prize = (unit * weights[type]!).floor();
      prizes[type] = prize;
      distributed += prize;
    }

    prizes['full_house'] = (totalPool.toInt() - distributed);

    return prizes;
  }

  Widget _buildWinningTickets() {
    final winningClaims = widget.room.claims.toList();

    if (winningClaims.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.border),
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
        if (player == null ||
            player.tickets.isEmpty ||
            claim.ticketIndex >= player.tickets.length) {
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
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(color: AppColors.border),
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
                          color: AppColors.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Claimed by: ${claim.playerName}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const Icon(Icons.emoji_events, color: AppColors.accent, size: 24),
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
    final allPrizeTypes = [
      'early_five',
      'top_line',
      'middle_line',
      'bottom_line',
      'full_house'
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Game Results',
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => Share.share(
                'Check out our Housie game results from room ${widget.room.roomName}!'),
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: GeometricBackground(
        shapes: [
          BackgroundShapeItem(
            shape: BackgroundShape.circle,
            color: AppColors.secondary,
            size: 300,
            top: -100,
            left: -100,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.hexagon,
            color: AppColors.primary,
            size: 200,
            bottom: -50,
            right: -50,
            rotation: 0.5,
          ),
        ],
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: kToolbarHeight + 8),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.room.roomName.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: _buildSummaryPanel(prizes, allPrizeTypes)),
                      const SizedBox(width: 12),
                      Expanded(flex: 5, child: _buildWinnersPanel()),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (_isHost) {
                      await GameService().deleteRoom(widget.room.roomId);
                    }
                    navigator.popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                  ),
                  child: const Text('BACK TO HOME',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(Map<String, int> prizes, List<String> allPrizeTypes) {
    return AppPanel(
      scrollable: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL PRIZE POOL',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${widget.room.totalPool.toInt()}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'RESULTS TABLE',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
                  children: const [
                    Padding(padding: EdgeInsets.all(14), child: Text('PRIZE', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(14), child: Text('WINNER', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(14), child: Text('EARNED', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                ...allPrizeTypes.map((type) {
                  final claim = widget.room.claims.where((c) => c.type == type).firstOrNull;
                  final isWinner = claim != null;

                  return TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10.withValues(alpha: 0.1))),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Text(_getClaimLabel(type),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Text(isWinner ? claim.playerName : '---',
                            style: TextStyle(color: isWinner ? Colors.white70 : Colors.white24, fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Text('₹${prizes[type]}',
                            style: TextStyle(color: isWinner ? AppColors.success : Colors.white24, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnersPanel() {
    return AppPanel(
      title: 'WINNING TICKETS',
      trailing: const Icon(Icons.emoji_events, color: AppColors.accent, size: 18),
      scrollable: true,
      padding: const EdgeInsets.all(16),
      child: _buildWinningTickets(),
    );
  }
}
