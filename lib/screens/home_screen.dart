import 'package:flutter/material.dart';
import 'host_screen.dart';
import 'join_screen.dart';
import 'lobby_screen.dart';
import 'game_screen.dart';
import '../widgets/geometric_background.dart';
import '../services/persistence_service.dart';
import '../services/game_service.dart';
import '../services/version_check_service.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _lastSession;

  @override
  void initState() {
    super.initState();
    _checkLastSession();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await VersionCheckService().checkUpdate();
    if (updateInfo != null && updateInfo['needsUpdate'] == true) {
      if (!mounted) return;
      _showUpdateDialog(
        isMandatory: updateInfo['isMandatory'],
        latestVersion: updateInfo['latestVersion'],
        updateUrl: updateInfo['updateUrl'],
      );
    }
  }

  void _showUpdateDialog({
    required bool isMandatory,
    required String latestVersion,
    required String updateUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isMandatory,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A2A4D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isMandatory ? 'UPDATE REQUIRED' : 'UPDATE AVAILABLE',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version ($latestVersion) is available. Please update to continue enjoying the best experience.',
                style: const TextStyle(color: Colors.white70),
              ),
              if (isMandatory) ...[
                const SizedBox(height: 12),
                const Text(
                  'This update is required to keep playing.',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            if (!isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('LATER', style: TextStyle(color: Colors.white60)),
              ),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(updateUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('UPDATE NOW', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(context),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0D1B3E),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1A2A4D)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.jpg', height: 60, width: 60),
                ),
                const SizedBox(height: 12),
                const Text('Housie Multiplayer', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('v1.0.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.help_outline,
            label: 'How to Play',
            onTap: () => _showHowToPlay(context),
          ),
          _DrawerItem(
            icon: Icons.info_outline,
            label: 'About App',
            onTap: () => _showAbout(context),
          ),
          _DrawerItem(
            icon: Icons.copyright,
            label: 'Copyright',
            onTap: () => _showCopyright(context),
          ),
          _DrawerItem(
            icon: Icons.settings_outlined,
            label: 'Reset Session',
            onTap: () async {
              await PersistenceService().clearSession();
              if (context.mounted) {
                setState(() => _lastSession = null);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('HOW TO PLAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ruleSection('1. Number Range', 'The game uses numbers from 1 to 90.'),
              _ruleSection('2. Your Ticket', 'Each ticket is a 3x9 grid with 15 numbers. Every column has at least one number.'),
              _ruleSection('3. Gameplay', 'Keep an eye on the central number. If it appears on your ticket, tap it!'),
              _ruleSection('4. Winning Patterns', 'Claim prizes whenever you complete these:\n\n'
                  '• Early 5: First 5 numbers marked.\n'
                  '• Top Line: All numbers in the 1st row.\n'
                  '• Middle Line: All numbers in the 2nd row.\n'
                  '• Bottom Line: All numbers in the 3rd row.\n'
                  '• Full House: All 15 numbers marked.'),
              _ruleSection('5. Claiming', 'Be fast! Click "CLAIM" on your ticket once you hit a pattern. Only the first valid claim wins!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _ruleSection(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    Navigator.pop(context);
    showAboutDialog(
      context: context,
      applicationName: 'Housie Multiplayer',
      applicationVersion: '1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset('assets/images/logo.jpg', height: 40, width: 40),
      ),
      children: const [
        Text('Housie Multiplayer is a premium, real-time bingo experience built for speed and fun. Play with friends or host big groups effortlessly!'),
      ],
    );
  }

  void _showCopyright(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('COPYRIGHT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          '© 2026 Housie Multiplayer Team. All rights reserved.\n\n'
          'Unauthorized reproduction or redistribution of this software is strictly prohibited.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
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
