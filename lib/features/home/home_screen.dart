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
    ).show(context: context);
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
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Center(
              child: InkWell(
                key: _menuKey,
                onTap: () => Scaffold.of(context).openDrawer(),
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
      ),
      drawer: const AppDrawer(),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (_lastSession != null) _buildRejoinBanner(),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 26),
                      Expanded(child: _buildModeSplit()),
                      const SizedBox(height: 20),
                      const _FeatureChips(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top: resume banner ──────────────────────────────────────────────────
  Widget _buildRejoinBanner() {
    final roomId = _lastSession!['roomId'] ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _rejoinGame,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x33FBBF24), Color(0x14FBBF24)],
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_rounded,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Resume your game',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
                Text(
                  'ROOM $roomId',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.accent, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Centred hero ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Floaty(
          child: _LogoMark(size: 96),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => AppColors.titleGradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'HOUSIE',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Host a room or join your friends — pick a side.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  // ── Split mode selector ─────────────────────────────────────────────────
  Widget _buildModeSplit() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ModeHalf(
                cardKey: _hostKey,
                icon: Icons.add_circle_rounded,
                title: 'HOST',
                subtitle: 'Create a room &\ninvite friends',
                gradient: AppColors.brandGradient,
                glow: AppColors.primary,
                align: CrossAxisAlignment.end,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HostScreen()),
                  ).then((_) => _checkLastSession());
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModeHalf(
                cardKey: _joinKey,
                icon: Icons.group_rounded,
                title: 'JOIN',
                subtitle: 'Enter a code or\nscan the host QR',
                gradient: AppColors.secondaryGradient,
                glow: AppColors.secondary,
                align: CrossAxisAlignment.start,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const JoinScreen()),
                  ).then((_) => _checkLastSession());
                },
              ),
            ),
          ],
        ),
        const _OrDivider(),
      ],
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
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
        offset: Offset(0, -5 * _c.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _ModeHalf extends StatelessWidget {
  final GlobalKey cardKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color glow;
  final CrossAxisAlignment align;
  final VoidCallback onTap;

  const _ModeHalf({
    required this.cardKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glow,
    required this.align,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: cardKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.4),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: align,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: align == CrossAxisAlignment.end
                    ? TextAlign.right
                    : TextAlign.left,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.arrow_circle_right_rounded,
                  color: Colors.white, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderStrong, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'OR',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _FeatureChips extends StatelessWidget {
  const _FeatureChips();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.bolt_rounded, 'Live Sync'),
      (Icons.qr_code_2_rounded, 'QR Join'),
      (Icons.emoji_events_rounded, 'Instant Prizes'),
      (Icons.shield_rounded, 'Verified Claims'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (icon, label) in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ),
          ),
      ],
    );
  }
}
