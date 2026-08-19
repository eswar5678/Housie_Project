import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/room.dart';
import '../../services/game_service.dart';
import '../../services/persistence_service.dart';
import '../../core/widgets/housie_ticket_widget.dart';
import '../../core/widgets/star_loader.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/geometric_background.dart';
import '../../core/widgets/app_panel.dart';
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

  @override
  void initState() {
    super.initState();
    _saveSession();
    GameService().updatePlayerStatus(widget.roomId, widget.playerName, true);
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
            body: GeometricBackground(
              shapes: [
                BackgroundShapeItem(
                    shape: BackgroundShape.triangle,
                    color: AppColors.secondary,
                    size: 250,
                    top: -100,
                    right: -50,
                    rotation: 0.2),
                BackgroundShapeItem(
                    shape: BackgroundShape.circle,
                    color: const Color(0xFF1E88E5),
                    size: 180,
                    bottom: -40,
                    left: -30),
                BackgroundShapeItem(
                    shape: BackgroundShape.hexagon,
                    color: AppColors.primary,
                    size: 120,
                    top: 200,
                    left: 10,
                    rotation: -0.4),
              ],
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
                                child: _buildTicketsPanel(room, currentPlayer)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: isHostView
                          ? _buildHostStartBar(room)
                          : Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                  SizedBox(width: 16),
                                  Text(
                                    'Waiting for host to start...',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
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
    );
  }

  Widget _buildLeftPanel(HousieRoom room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.black54, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PRIZE POOL',
                      style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2),
                    ),
                    Text(
                      '₹${room.totalPool.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 34,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                'Room ID: ${room.roomId}',
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PLAYERS JOINED',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
              Text(
                '${room.players.length} / ${room.maxPlayers}',
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: room.players.length,
            itemBuilder: (context, index) {
              final player = room.players.values.toList()[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: player.isHost
                        ? AppColors.accent
                        : AppColors.secondary,
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    player.name == widget.playerName
                        ? '${player.name} (You)'
                        : player.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${player.ticketCount} Ticket${player.ticketCount > 1 ? 's' : ''}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                  ),
                  trailing: player.isHost
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                          ),
                          child: const Text(
                            'HOST',
                            style: TextStyle(color: AppColors.accent, fontSize: 10),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsPanel(HousieRoom room, Player currentPlayer) {
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
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5),
              ),
              const Spacer(),
              Text(
                '${currentPlayer.ticketCount} selected',
                style: const TextStyle(color: AppColors.success, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: currentPlayer.tickets.isEmpty
                ? Center(child: _buildEmptyTickets())
                : ListView.builder(
                    itemCount: currentPlayer.tickets.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            Text(
                              'TICKET ${index + 1}',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxWidth: AppDimens.maxTicketWidth),
                              child: HousieTicketWidget(
                                  ticket: currentPlayer.tickets[index]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (currentPlayer.tickets.isNotEmpty)
            TextButton.icon(
              onPressed: _navigateToTicketSelection,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('RE-SELECT TICKET'),
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
        const Icon(Icons.confirmation_num_outlined, size: 64, color: Colors.white24),
        const SizedBox(height: 12),
        const Text(
          "You haven't selected any tickets yet.",
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _navigateToTicketSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
          child: const Text(
            'SELECT TICKETS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canStart ? () => GameService().startGame(widget.roomId) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.onAccent,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
            ),
            child: Text(
              room.players.length < 2
                  ? 'WAITING FOR PLAYERS...'
                  : (allPicked ? 'START GAME' : 'WAITING FOR TICKETS...'),
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
        ),
      ],
    );
  }
}
