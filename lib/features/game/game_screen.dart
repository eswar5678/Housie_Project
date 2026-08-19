import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/room.dart';
import '../../services/game_service.dart';
import '../../services/persistence_service.dart';
import '../../core/widgets/housie_ticket_widget.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/glow_button.dart';
import '../../core/theme/app_theme.dart';
import '../results/results_screen.dart';
import 'game_ui_controller.dart';
import 'widgets/number_board.dart';
import 'widgets/current_number_ring.dart';
import 'widgets/animated_avatar.dart';

/// Landscape, two-panel game screen.
///
/// Left panel  → the player's ticket(s) + claim button.
/// Right panel → live number ring, recent calls and the full 1–90 board.
class GameScreen extends ConsumerStatefulWidget {
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
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  int? _lastSpokenNumber;

  // Countdown and auto-calling state
  Timer? _countdownTimer;
  bool _isCallingNext = false;
  double _serverTimeOffset = 0;
  bool _isPromoting = false;

  StreamSubscription<HousieRoom?>? _roomSubscription;
  HousieRoom? _room;
  HousieRoom? _latestRoom;
  bool _isNavigatedToResults = false;

  // Real-time claim notification state
  final Set<String> _shownClaimKeys = {};
  Timer? _notificationDismissTimer;

  bool get _soundOn => ref.read(gameUiControllerProvider).soundOn;

  @override
  void initState() {
    super.initState();
    _saveSession();

    // Mark as online when rejoining/entering
    GameService().updatePlayerStatus(widget.roomId, widget.playerName, true);

    // Track server time offset for synchronization
    FirebaseDatabase.instance
        .ref('.info/serverTimeOffset')
        .onValue
        .listen((event) {
      if (mounted) {
        setState(() {
          _serverTimeOffset = (event.snapshot.value as num? ?? 0.0).toDouble();
        });
      }
    });

    _roomSubscription =
        GameService().getRoomStream(widget.roomId).listen((room) {
      if (room == null || !mounted) return;

      _detectNewClaims(room);

      if (_room == null) {
        _lastSpokenNumber = room.currentNumber;
      } else if (_soundOn &&
          room.currentNumber != null &&
          room.currentNumber != _lastSpokenNumber) {
        _lastSpokenNumber = room.currentNumber;
        _speakNumber(room.currentNumber!);
      }

      setState(() {
        _room = room;
        _latestRoom = room;
      });

      if (room.status == 'finished' && !_isNavigatedToResults) {
        _isNavigatedToResults = true;
        _stopCountdownCycle();
        PersistenceService().clearSession();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResultsScreen(room: room)),
        );
      }

      if (room.gameStartTimestamp != null && _countdownTimer == null) {
        _startCountdownCycle();
      }
    });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _stopCountdownCycle();
    _notificationDismissTimer?.cancel();
    super.dispose();
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

  void _detectNewClaims(HousieRoom room) {
    if (_room == null) {
      // First load: cache all existing claims to prevent old notifications
      for (var claim in room.claims) {
        _shownClaimKeys.add('${claim.playerName}_${claim.type}');
      }
      return;
    }

    for (var claim in room.claims) {
      final key = '${claim.playerName}_${claim.type}';
      if (!_shownClaimKeys.contains(key)) {
        _shownClaimKeys.add(key);
        _triggerClaimNotification(claim);
      }
    }
  }

  Future<void> _speakNumber(int number) async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.speak(number.toString());
    } catch (e) {
      debugPrint('TTS speaking error: $e');
    }
  }

  void _triggerClaimNotification(HousieClaim claim) {
    _notificationDismissTimer?.cancel();
    ref.read(gameUiControllerProvider.notifier).showClaimNotification(claim);

    _notificationDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        ref.read(gameUiControllerProvider.notifier).dismissClaimNotification();
      }
    });
  }

  void _showPlayersDialog(HousieRoom room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
      ),
      builder: (context) {
        final playersList = room.players.values.toList();
        playersList.sort((a, b) {
          if (a.isHost && !b.isHost) return -1;
          if (!a.isHost && b.isHost) return 1;
          if (a.isOnline && !b.isOnline) return -1;
          if (!a.isOnline && b.isOnline) return 1;
          return a.name.compareTo(b.name);
        });

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PLAYERS (${playersList.where((p) => p.isOnline).length}/${playersList.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playersList.length,
                    itemBuilder: (context, index) {
                      final player = playersList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                          border: Border.all(
                            color: player.isOnline
                                ? AppColors.border
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedAvatar(
                              name: player.name,
                              isOnline: player.isOnline,
                              isHost: player.isHost,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          player.name,
                                          style: TextStyle(
                                            color: player.isOnline ? Colors.white : Colors.white30,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (player.name.trim().toUpperCase() ==
                                          widget.playerName.trim().toUpperCase()) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                          ),
                                          child: const Text(
                                            'YOU',
                                            style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    player.isOnline
                                        ? (player.isHost ? 'Hosting the game' : 'Online & Playing')
                                        : 'Offline / Disconnected',
                                    style: TextStyle(
                                      color: player.isOnline ? AppColors.online : Colors.white24,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${player.ticketCount} ${player.ticketCount > 1 ? 'Tickets' : 'Ticket'}',
                              style: TextStyle(
                                color: player.isOnline ? Colors.white60 : Colors.white24,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveSession() async {
    await PersistenceService().saveGameSession(
      roomId: widget.roomId,
      playerName: widget.playerName,
      isHost: widget.isHost,
    );
  }

  // Start the sync cycle when the game starts
  void _startCountdownCycle() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_latestRoom != null) {
        final room = _latestRoom!;
        _checkHostHandoff(room);

        final serverNow =
            DateTime.now().millisecondsSinceEpoch + _serverTimeOffset.toInt();
        final lastCall = room.lastCallTimestamp;
        final startTimestamp = room.gameStartTimestamp;

        if (room.status == 'playing') {
          final isHostDevice =
              room.hostName.toUpperCase() == widget.playerName.trim().toUpperCase();
          if (room.calledNumbers.isEmpty && startTimestamp != null) {
            final elapsed = (serverNow - startTimestamp) / 1000;
            if (elapsed >= 10 && isHostDevice && !_isCallingNext) {
              _isCallingNext = true;
              GameService()
                  .callNextNumber(widget.roomId)
                  .then((_) => _isCallingNext = false);
            }
          } else if (room.calledNumbers.isNotEmpty && lastCall != null) {
            final elapsed = (serverNow - lastCall) / 1000;
            if (elapsed >= 5 && isHostDevice && !_isCallingNext) {
              _isCallingNext = true;
              GameService()
                  .callNextNumber(widget.roomId)
                  .then((_) => _isCallingNext = false);
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

    if (host == null || !host.isOnline) {
      _isPromoting = true;
      final players = room.players.entries
          .where((e) => e.value.isOnline)
          .map((e) => e.key)
          .toList()
        ..sort();
      if (players.isNotEmpty) {
        final newHost = players.first;
        final playerObj = room.players[newHost]!;
        debugPrint('Host $hostKey left. Promoting $newHost to Host.');
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        ),
        title: const Text('QUIT GAME?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to leave the game? Your progress will be saved.',
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
        const claimTypes = {
          'early_five': 'Early 5',
          'top_line': 'Top Line',
          'middle_line': 'Middle Line',
          'bottom_line': 'Bottom Line',
          'full_house': 'Full House',
        };

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          ),
          title: const Text('SELECT CLAIM',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: claimTypes.entries.map((entry) {
              final isClaimed = room.claims.any((c) => c.type == entry.key);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  entry.value,
                  style: TextStyle(
                    color: isClaimed ? Colors.white24 : Colors.white,
                    fontWeight: isClaimed ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                trailing: isClaimed
                    ? const Text('CLAIMED',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold))
                    : const Icon(Icons.arrow_forward_ios,
                        color: AppColors.accent, size: 14),
                onTap: isClaimed
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        final error = await GameService().submitClaim(
                          widget.roomId,
                          widget.playerName,
                          ticketIndex,
                          entry.key,
                        );
                        if (!mounted) return;
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.redAccent),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Validating your ${entry.value} claim...'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 1),
                            ),
                          );
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
              backgroundColor: AppColors.surface,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : _buildGameContent(_room!),
    );
  }

  Widget _buildGameContent(HousieRoom room) {
    final serverNow =
        DateTime.now().millisecondsSinceEpoch + _serverTimeOffset.toInt();
    final lastCall = room.lastCallTimestamp;
    final startTimestamp = room.gameStartTimestamp;

    // Safety check (in addition to the stream listener)
    _checkHostHandoff(room);

    // Sync cycle logic (10s initial, 5s regular)
    int localCountdown = 10;
    if (room.status == 'playing') {
      if (room.calledNumbers.isEmpty && startTimestamp != null) {
        final elapsed = (serverNow - startTimestamp) / 1000;
        if (elapsed < 10) {
          localCountdown = (10 - elapsed).ceil();
        }
      } else if (room.calledNumbers.isNotEmpty && lastCall != null) {
        final elapsed = (serverNow - lastCall) / 1000;
        localCountdown = elapsed < 5 ? (5 - elapsed).ceil() : 0;
      }
    }

    final String localLabel = room.calledNumbers.isEmpty
        ? 'Game starting in ${localCountdown}s'
        : 'Calling in ${localCountdown}s...';

    final displayNum = room.calledNumbers.isNotEmpty
        ? room.currentNumber.toString().padLeft(2, '0')
        : '--';

    final progress = room.calledNumbers.isEmpty
        ? (localCountdown / 10)
        : (localCountdown / 5);

    // Final check: finished is handled in the listener, this is a safety net.
    if (room.status == 'finished') {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pKey = widget.playerName.trim().toUpperCase();
    final currentPlayer = room.players[pKey];

    if (currentPlayer == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Text('Player not found in room!',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final onlinePlayerCount =
        room.players.values.where((p) => p.isOnline).length;
    final ui = ref.watch(gameUiControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AppBackground(child: const SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(room, onlinePlayerCount),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildTicketsPanel(room, currentPlayer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: _buildBoardPanel(
                              room, displayNum, progress, localLabel),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildClaimNotificationBanner(ui.activeClaimNotification),
        ],
      ),
    );
  }

  Widget _buildTopBar(HousieRoom room, int onlinePlayerCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showPlayersDialog(room),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, color: AppColors.accent, size: 15),
                  const SizedBox(width: 4),
                  Text('$onlinePlayerCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ROOM ${room.roomId}',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () =>
                ref.read(gameUiControllerProvider.notifier).toggleSound(),
            icon: Icon(
              ref.watch(gameUiControllerProvider).soundOn
                  ? Icons.volume_up
                  : Icons.volume_off,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Toggle sound',
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsPanel(HousieRoom room, Player currentPlayer) {
    final ui = ref.watch(gameUiControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Text(
                    '₹${room.ticketPrice.toInt()} / ticket',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: currentPlayer.tickets.length,
              itemBuilder: (context, index) {
                final ticket = currentPlayer.tickets[index];
                final ticketMarked = ui.ticketMarkings[index] ?? const <int>{};
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: AppDimens.maxTicketWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TICKET ${index + 1}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 108,
                                height: 34,
                                child: GlowButton(
                                  label: 'Claim',
                                  gradient: AppColors.dangerGradient,
                                  glowColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                  height: 34,
                                  fontSize: 12,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  onPressed: () => _showClaimDialog(index, room),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          HousieTicketWidget(
                            ticket: ticket,
                            markedIndices: ticketMarked,
                            onNumberTap: (cellIdx) => ref
                                .read(gameUiControllerProvider.notifier)
                                .toggleMark(
                                  ticketIndex: index,
                                  cellIndex: cellIdx,
                                  number: ticket.numbers[cellIdx],
                                  calledNumbers: room.calledNumbers,
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
        ],
      ),
    );
  }

  Widget _buildBoardPanel(
    HousieRoom room,
    String displayNum,
    double progress,
    String localLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CurrentNumberRing(
                displayNumber: displayNum,
                progress: progress,
                countdownLabel: localLabel,
              ),
              const SizedBox(width: 12),
              Expanded(child: _calledNumbersStrip(room)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: NumberBoard(calledNumbers: room.calledNumbers)),
      ],
    );
  }

  Widget _calledNumbersStrip(HousieRoom room) {
    if (room.calledNumbers.isEmpty) {
      return const Align(
        alignment: Alignment.centerRight,
        child: Text(
          'Waiting for the first number...',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: const EdgeInsets.only(left: 8),
      itemCount: room.calledNumbers.length,
      itemBuilder: (context, index) {
        final number = room.calledNumbers[room.calledNumbers.length - 1 - index];
        final latest = index == 0;
        return Container(
          margin: const EdgeInsets.only(right: 5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: latest
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.surfaceHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(
                color: latest ? AppColors.accent : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString().padLeft(2, '0'),
            style: TextStyle(
              color: latest ? AppColors.accent : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildClaimNotificationBanner(HousieClaim? claim) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      top: claim != null ? 8 : -120,
      left: 120,
      right: 120,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border:
              Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    claim != null
                        ? '${claim.playerName} claimed ${_getClaimLabel(claim.type)}!'
                        : '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Claim verified successfully',
                    style: TextStyle(color: AppColors.success, fontSize: 10),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white38, size: 18),
              onPressed: () =>
                  ref.read(gameUiControllerProvider.notifier).dismissClaimNotification(),
            ),
          ],
        ),
      ),
    );
  }
}
