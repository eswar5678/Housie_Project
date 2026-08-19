import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../host/host_screen.dart';
import '../join/join_screen.dart';
import '../lobby/lobby_screen.dart';
import '../game/game_screen.dart';
import '../../core/widgets/geometric_background.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/theme/app_theme.dart';
import '../../services/persistence_service.dart';
import '../../services/game_service.dart';
import '../../services/version_check_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _lastSession;
  final GlobalKey _hostKey = GlobalKey();
  final GlobalKey _joinKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkLastSession();
    _checkForUpdates();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final hasSeen = await PersistenceService().hasSeenTutorial();
    if (!hasSeen) {
      Future.delayed(const Duration(milliseconds: 500), _showTutorial);
    }
  }

  void _showTutorial() {
    final targets = [
      TargetFocus(
        identify: "HostGame",
        keyTarget: _hostKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Host a Game",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Create a new game room and invite your friends to play!",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "JoinGame",
        keyTarget: _joinKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Join a Game",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Enter a Room ID or scan a QR code to join an existing game.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Menu",
        keyTarget: _menuKey,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Explore More",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Access leaderboards, settings, and other features here.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0D1B3E),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        PersistenceService().markTutorialAsSeen();
      },
      onClickTarget: (target) {
        // Continue
      },
      onSkip: () {
        PersistenceService().markTutorialAsSeen();
        return true;
      },
    )..show(context: context);
  }

  Future<void> _checkForUpdates() async {
    await VersionCheckService().checkForUpdates();
  }

  Future<void> _checkLastSession() async {
    final session = await PersistenceService().getLastSession();
    if (session != null) {
      final roomId = session['roomId'];
      try {
        final room = await GameService()
            .getRoomStream(roomId)
            .first
            .timeout(const Duration(seconds: 3));
        if (room != null && room.status != 'finished') {
          setState(() {
            _lastSession = session;
          });
        } else {
          await PersistenceService().clearSession();
          setState(() => _lastSession = null);
        }
      } catch (e) {
        debugPrint('Error checking last session: $e');
        setState(() {
          _lastSession = session;
        });
      }
    }
  }

  void _rejoinGame() {
    if (_lastSession == null) return;

    GameService().getRoomStream(_lastSession!['roomId']).first.then((room) {
      if (!mounted) return;
      if (room == null) {
        PersistenceService().clearSession();
        setState(() => _lastSession = null);
        return;
      }

      if (!context.mounted) return;
      if (room.status == 'lobby') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              roomId: room.roomId,
              playerName: _lastSession!['playerName'],
              isHost: _lastSession!['isHost'],
            ),
          ),
        );
      } else {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              roomId: room.roomId,
              playerName: _lastSession!['playerName'],
              isHost: _lastSession!['isHost'],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        showBackButton: false,
        actions: [
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: InkWell(
                  key: _menuKey,
                  onTap: () => Scaffold.of(context).openEndDrawer(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(Icons.menu, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: GeometricBackground(
        shapes: [
          BackgroundShapeItem(
            shape: BackgroundShape.circle,
            color: AppColors.secondary,
            size: 300,
            top: -100,
            left: -50,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.triangle,
            color: AppColors.primary,
            size: 150,
            bottom: 100,
            right: 20,
            rotation: 0.4,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.hexagon,
            color: const Color(0xFF1E88E5),
            size: 120,
            top: 200,
            right: -30,
            rotation: -0.2,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.square,
            color: Colors.purpleAccent,
            size: 80,
            bottom: 50,
            left: 40,
            rotation: 0.2,
          ),
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
            child: Row(
              children: [
                Expanded(flex: 5, child: _buildBrandPanel()),
                const SizedBox(width: AppDimens.xl),
                Expanded(flex: 5, child: _buildActionsPanel()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/images/logo.jpg',
              height: 140,
              width: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          const Text(
            'HOUSIE MULTIPLAYER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          const Text(
            'Real-time Tambola, reimagined for groups.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          if (_lastSession != null) ...[
            const SizedBox(height: AppDimens.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle, color: AppColors.success, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'You have an active game',
                    style: TextStyle(color: AppColors.success, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsPanel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_lastSession != null) ...[
              _MenuButton(
                label: 'REJOIN GAME',
                icon: Icons.refresh,
                color: Colors.greenAccent,
                onPressed: _rejoinGame,
              ),
              const SizedBox(height: 16),
            ],
            _MenuButton(
              key: _hostKey,
              label: 'HOST A GAME',
              icon: Icons.add_circle_outline,
              color: Colors.amber,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HostScreen()),
                ).then((_) => _checkLastSession());
              },
            ),
            const SizedBox(height: 16),
            _MenuButton(
              key: _joinKey,
              label: 'JOIN A GAME',
              icon: Icons.group_add_outlined,
              color: Colors.cyanAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JoinScreen()),
                ).then((_) => _checkLastSession());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black87),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          ),
          elevation: 8,
        ),
      ),
    );
  }
}
