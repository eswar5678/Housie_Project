import 'package:flutter/material.dart';
import 'host_screen.dart';
import 'join_screen.dart';
import 'lobby_screen.dart';
import 'game_screen.dart';
import '../widgets/geometric_background.dart';
import '../services/persistence_service.dart';
import '../services/game_service.dart';
import '../services/version_check_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_drawer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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
      // Use a more direct check or a timeout to avoid hangs
      try {
        final room = await GameService().getRoomStream(roomId).first.timeout(const Duration(seconds: 3));
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
        // If timeout or error, keep the session for now? Or clear it?
        // Let's keep it if we can't reach the server, maybe it's a temp network issue
        setState(() { _lastSession = session; });
      }
    }
  }

  void _rejoinGame() {
    if (_lastSession == null) return;

    // Check room status to decide which screen to push
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
      backgroundColor: const Color(0xFF0D1B3E),
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
                      color: const Color(0xFF1B2845),
                      borderRadius: BorderRadius.circular(16),
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
            color: const Color(0xFF4DB6AC),
            size: 300,
            top: -100,
            left: -50,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.triangle,
            color: const Color(0xFF9575CD),
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
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 60),
                if (_lastSession != null) ...[
                  _MenuButton(
                    label: 'REJOIN GAME',
                    icon: Icons.refresh,
                    color: Colors.greenAccent,
                    onPressed: _rejoinGame,
                  ),
                  const SizedBox(height: 20),
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
                const SizedBox(height: 20),
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
      width: 280,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black87),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
      ),
    );
  }
}
