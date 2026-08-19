import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../host/host_screen.dart';
import '../join/join_screen.dart';
import '../lobby/lobby_screen.dart';
import '../game/game_screen.dart';
import '../../core/widgets/app_background.dart';
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
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: AppColors.borderStrong),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              children: [
                Expanded(flex: 11, child: _buildBrand()),
                const SizedBox(width: 48),
                Expanded(flex: 9, child: _buildActions()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Left: brand / hero ───────────────────────────────────────────────────
  Widget _buildBrand() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Floaty(
            child: _LogoMark(size: 132),
          ),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.titleGradient.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: const Text(
              'HOUSIE',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Real-time Tambola, reimagined for friends & family.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          if (_lastSession != null) ...[
            const SizedBox(height: 20),
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
          const SizedBox(height: 28),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FeatureChip(icon: Icons.bolt_rounded, label: 'Live Sync'),
              SizedBox(width: 10),
              _FeatureChip(icon: Icons.qr_code_2_rounded, label: 'QR Join'),
              SizedBox(width: 10),
              _FeatureChip(icon: Icons.emoji_events_rounded, label: 'Instant Prizes'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Right: primary actions ───────────────────────────────────────────────
  Widget _buildActions() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionCard(
              key: _hostKey,
              icon: Icons.add_circle_rounded,
              title: 'HOST A GAME',
              subtitle: 'Create a room & invite your friends',
              gradient: AppColors.brandGradient,
              glowColor: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HostScreen()),
                ).then((_) => _checkLastSession());
              },
            ),
            const SizedBox(height: 18),
            _ActionCard(
              key: _joinKey,
              icon: Icons.group_rounded,
              title: 'JOIN A GAME',
              subtitle: 'Enter a code or scan the host\u2019s QR',
              gradient: AppColors.secondaryGradient,
              glowColor: AppColors.secondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const JoinScreen()),
                ).then((_) => _checkLastSession());
              },
            ),
            if (_lastSession != null) ...[
              const SizedBox(height: 18),
              _ActionCard(
                icon: Icons.replay_rounded,
                title: 'REJOIN GAME',
                subtitle: 'Jump back into your last room',
                gradient: AppColors.goldGradient,
                glowColor: AppColors.accent,
                onTap: _rejoinGame,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Decorative pieces ──────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 46,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Image.asset(
          'assets/images/logo.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _Floaty extends StatefulWidget {
  final Widget child;
  const _Floaty({required this.child});

  @override
  State<_Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<_Floaty>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * _c.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
