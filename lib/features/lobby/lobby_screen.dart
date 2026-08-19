import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/room.dart';
import '../../services/game_service.dart';
import '../../services/persistence_service.dart';
import '../../core/widgets/housie_ticket_widget.dart';
import '../../core/widgets/star_loader.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_panel.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/widgets/animated_avatar.dart';
import '../../core/theme/app_theme.dart';
import '../game/game_screen.dart';
import '../ticket_selection/ticket_selection_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final String playerName;

  const LobbyScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    this.isHost = false,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _hasNavigatedToGame = false;
  bool _isPromoting = false;
  int _ticketPage = 0;
  late final PageController _ticketController = PageController();

  @override
  void initState() {
    super.initState();
    _saveSession();
    GameService().updatePlayerStatus(widget.roomId, widget.playerName, true);
  }

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  void _checkHostHandoff(HousieRoom room) {
    if (_isPromoting) return;
    final hostKey = room.hostName.toUpperCase();
    final host = room.players[hostKey];
    if (host == null || !host.isOnline) {
      _isPromoting = true;
      final players = room.players.entries
          .where((e) => e.value.isOnline)
          .map((e) => e.key)
          .toList()
        ..sort();
      if (players.isNotEmpty) {
        final newHost = players.first;
        debugPrint('Lobby: Host left. Promoting $newHost.');
        final playerObj = room.players[newHost]!;
        GameService()
            .promoteNewHost(widget.roomId, playerObj.name, playerObj.uid)
            .then((_) => _isPromoting = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('LEAVE LOBBY?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to leave? you can rejoin later.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              await GameService().leaveRoom(widget.roomId, widget.playerName);
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _saveSession() async {
    await PersistenceService().saveGameSession(
      roomId: widget.roomId,
      playerName: widget.playerName,
      isHost: widget.isHost,
    );
  }

  void _navigateToTicketSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketSelectionScreen(
          roomId: widget.roomId,
          playerName: widget.playerName,
          isHost: widget.isHost,
        ),
      ),
    );
  }

  Future<void> _copyRoomId(String roomId) async {
    await Clipboard.setData(ClipboardData(text: roomId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room ID copied to clipboard')),
    );
  }

  void _showQRDialog(BuildContext context, String roomId, String roomName) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                roomName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Join via QR Code',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: roomId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ROOM ID: $roomId',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CLOSE', style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Share.share(
                        'Join my Housie Game!\nRoom Name: $roomName\nRoom ID: $roomId',
                        subject: 'Housie Game Join Request',
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('SHARE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanId = widget.roomId.trim().toUpperCase();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: StreamBuilder<HousieRoom?>(
        stream: GameService().getRoomStream(cleanId),
        builder: (context, snapshot) {
          final room = snapshot.data;

          if (room == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StarLoader(size: 100, color: AppColors.accent),
                      SizedBox(height: 24),
                      Text('Loading Game...',
                          style: TextStyle(color: Colors.white70, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              );
            }
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Text('Room not found!', style: TextStyle(color: Colors.white)),
              ),
            );
          }

          _checkHostHandoff(room);
          final isHostView =
              room.hostName.toUpperCase() == widget.playerName.trim().toUpperCase();

          if (room.status == 'playing' && !_hasNavigatedToGame) {
            _hasNavigatedToGame = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    roomId: widget.roomId,
                    playerName: widget.playerName,
                    isHost: widget.isHost,
                  ),
                ),
              );
            });
          }

          final pKey = widget.playerName.trim().toUpperCase();
          final currentPlayer = room.players[pKey];

          if (currentPlayer == null) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: StarLoader(size: 80)),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            extendBodyBehindAppBar: true,
            appBar: CustomAppBar(
              title: 'Game Lobby',
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_2, color: AppColors.accent),
                  onPressed: () =>
                      _showQRDialog(context, room.roomId, room.roomName),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => Share.share(
                    'Join my Housie Game!\nRoom Name: ${room.roomName}\nRoom ID: ${room.roomId}',
                    subject: 'Housie Game Join Request',
                  ),
                ),
              ],
            ),
            body: AppBackground(
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: kToolbarHeight + 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 5, child: _buildLeftPanel(room)),
                            const SizedBox(width: 12),
                            Expanded(
                                flex: 5,
                                child:
                                    _buildTicketsPanel(room, currentPlayer)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: isHostView
                          ? _buildHostStartBar(room)
                          : _buildWaitingBar(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Left: prize hero + players grid ─────────────────────────────────────
  Widget _buildLeftPanel(HousieRoom room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PRIZE POOL',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '₹${room.totalPool.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      room.roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  _HeroAction(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () => _copyRoomId(room.roomId),
                  ),
                  const SizedBox(height: 8),
                  _HeroAction(
                    icon: Icons.qr_code_2_rounded,
                    label: 'QR',
                    onTap: () =>
                        _showQRDialog(context, room.roomId, room.roomName),
                  ),
                  const SizedBox(height: 8),
                  _HeroAction(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () => Share.share(
                      'Join my Housie Game!\nRoom Name: ${room.roomName}\nRoom ID: ${room.roomId}',
                      subject: 'Housie Game Join Request',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PLAYERS JOINED',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                '${room.players.length} / ${room.maxPlayers}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 74,
            ),
            itemCount: room.players.length,
            itemBuilder: (context, index) {
              final player = room.players.values.toList()[index];
              return _PlayerCard(
                player: player,
                isYou: player.name.trim().toUpperCase() ==
                    widget.playerName.trim().toUpperCase(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Right: tickets carousel ─────────────────────────────────────────────
  Widget _buildTicketsPanel(HousieRoom room, Player currentPlayer) {
    final tickets = currentPlayer.tickets;
    final page = _ticketPage.clamp(0, tickets.isEmpty ? 0 : tickets.length - 1);

    return AppPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'YOUR TICKETS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (tickets.isNotEmpty)
                Text(
                  '${currentPlayer.ticketCount} selected',
                  style: const TextStyle(
                      color: AppColors.success, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: tickets.isEmpty
                ? Center(child: _buildEmptyTickets())
                : PageView.builder(
                    controller: _ticketController,
                    itemCount: tickets.length,
                    onPageChanged: (i) => setState(() => _ticketPage = i),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Text(
                              'TICKET ${index + 1}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      maxWidth: AppDimens.maxTicketWidth),
                                  child: HousieTicketWidget(ticket: tickets[index]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (tickets.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tickets.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == page ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == page ? AppColors.accent : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
          if (tickets.isNotEmpty)
            TextButton.icon(
              onPressed: _navigateToTicketSelection,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('CHANGE TICKETS'),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTickets() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.confirmation_num_outlined,
            size: 64, color: Colors.white24),
        const SizedBox(height: 12),
        const Text(
          "You haven't selected any tickets yet.",
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        GlowButton(
          label: 'SELECT TICKETS',
          icon: Icons.confirmation_num_rounded,
          gradient: AppColors.goldGradient,
          glowColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          height: 48,
          onPressed: _navigateToTicketSelection,
        ),
      ],
    );
  }

  Widget _buildHostStartBar(HousieRoom room) {
    final allPicked = room.players.values.every((p) => p.hasSelectedTickets);
    final canStart = room.players.length >= 2 && allPicked;

    return Column(
      children: [
        if (!allPicked && room.players.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Waiting for players to pick tickets...',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        GlowButton(
          label: room.players.length < 2
              ? 'WAITING FOR PLAYERS...'
              : (allPicked ? 'START GAME' : 'WAITING FOR TICKETS...'),
          icon: Icons.play_arrow_rounded,
          gradient: AppColors.successGradient,
          glowColor: AppColors.success,
          foregroundColor: AppColors.onAccent,
          height: 54,
          onPressed: canStart
              ? () => GameService().startGame(widget.roomId)
              : null,
        ),
      ],
    );
  }

  Widget _buildWaitingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.accent),
          ),
          SizedBox(width: 14),
          Text(
            'Waiting for host to start...',
            style: TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final bool isYou;

  const _PlayerCard({required this.player, required this.isYou});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          AnimatedAvatar(
            name: player.name,
            isOnline: player.isOnline,
            isHost: player.isHost,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isYou ? '${player.name} (You)' : player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: player.isOnline
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.ticketCount} Ticket${player.ticketCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
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
