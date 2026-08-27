import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/persistence_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _comingSoonItem;
  String _playerName = 'Player';

  @override
  void initState() {
    super.initState();
    _loadPlayerName();
  }

  Future<void> _loadPlayerName() async {
    final name = await PersistenceService().getDefaultPlayerName();
    if (name != null && mounted) {
      setState(() {
        _playerName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final drawerWidth = min(screenSize.width * 0.72, 600.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: const Color(0xFF111A30),
      child: SafeArea(
        child: Column(
          children: [
            // Top Landscape Header
            _buildLandscapeHeader(context),

            const Divider(color: Colors.white10, height: 1),

            // Scrollable Landscape 2-Column Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Game & Social
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('GAME'),
                          _DrawerItem(
                            icon: Icons.menu_book,
                            label: 'How to Play',
                            iconColor: Colors.blue[200]!,
                            onTap: _showHowToPlay,
                          ),
                          _DrawerItem(
                            icon: Icons.emoji_events,
                            label: 'Leaderboard',
                            iconColor: Colors.amber,
                            onTap: () => _showComingSoon('Leaderboard'),
                            isComingSoon: _comingSoonItem == 'Leaderboard',
                          ),
                          _DrawerItem(
                            icon: Icons.military_tech,
                            label: 'Achievements',
                            iconColor: Colors.orangeAccent,
                            badge: _buildBadge('3', Colors.pinkAccent),
                            isSelected: true,
                            onTap: () => _showComingSoon('Achievements'),
                            isComingSoon: _comingSoonItem == 'Achievements',
                          ),
                          _DrawerItem(
                            icon: Icons.bar_chart,
                            label: 'My Stats',
                            iconColor: Colors.cyan,
                            onTap: () => _showComingSoon('My Stats'),
                            isComingSoon: _comingSoonItem == 'My Stats',
                          ),
                          _DrawerItem(
                            icon: Icons.palette,
                            label: 'Themes & Skins',
                            iconColor: Colors.pink[200]!,
                            onTap: () => _showComingSoon('Themes & Skins'),
                            isComingSoon: _comingSoonItem == 'Themes & Skins',
                          ),
                          const SizedBox(height: 12),
                          _buildSectionTitle('SOCIAL'),
                          _DrawerItem(
                            icon: Icons.people,
                            label: 'Friends',
                            iconColor: Colors.deepPurple[300]!,
                            onTap: () => _showComingSoon('Friends'),
                            isComingSoon: _comingSoonItem == 'Friends',
                          ),
                          _DrawerItem(
                            icon: Icons.favorite,
                            label: 'Invite Friends',
                            iconColor: Colors.pinkAccent,
                            badge: _buildBadge('FREE', Colors.green),
                            onTap: _inviteFriends,
                          ),
                          _DrawerItem(
                            icon: Icons.chat_bubble,
                            label: 'Community',
                            iconColor: Colors.white70,
                            onTap: () => _showComingSoon('Community'),
                            isComingSoon: _comingSoonItem == 'Community',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // RIGHT COLUMN: App, Preferences & Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('APP & SETTINGS'),
                          _DrawerItem(
                            icon: Icons.settings,
                            label: 'Settings',
                            iconColor: Colors.grey[400]!,
                            onTap: _showSettings,
                          ),
                          _DrawerItem(
                            icon: Icons.notifications,
                            label: 'Notifications',
                            iconColor: Colors.amber,
                            onTap: _showSettings,
                          ),
                          _DrawerItem(
                            icon: Icons.volume_up,
                            label: 'Sound & Music',
                            iconColor: Colors.lightBlue,
                            onTap: _showSettings,
                          ),
                          _DrawerItem(
                            icon: Icons.language,
                            label: 'Language',
                            iconColor: Colors.blue,
                            onTap: () => _showComingSoon('Language'),
                            isComingSoon: _comingSoonItem == 'Language',
                          ),
                          _DrawerItem(
                            icon: Icons.star,
                            label: 'Rate Us',
                            iconColor: Colors.amber,
                            isSelected: true,
                            onTap: () async {
                              Navigator.pop(context);
                              final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.housie.developerbros');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          _DrawerItem(
                            icon: Icons.campaign,
                            label: 'Send Feedback',
                            iconColor: Colors.pink,
                            onTap: () => _showComingSoon('Send Feedback'),
                            isComingSoon: _comingSoonItem == 'Send Feedback',
                          ),
                          _DrawerItem(
                            icon: Icons.description,
                            label: 'Privacy Policy',
                            iconColor: Colors.grey[300]!,
                            onTap: _openPrivacyPolicy,
                          ),
                          _DrawerItem(
                            icon: Icons.info,
                            label: 'About',
                            iconColor: Colors.blue,
                            onTap: _showAbout,
                          ),

                          const SizedBox(height: 14),
                          // Compact Landscape Footer
                          _buildLandscapeFooter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: const Color(0xFF182442),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE040FB), Color(0xFF651FFF)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _playerName.isNotEmpty ? _playerName[0].toUpperCase() : 'P',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _playerName.isEmpty ? 'Player' : _playerName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 13),
                    SizedBox(width: 4),
                    Text('Level 12 • Housie Pro', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 22),
            tooltip: 'Close Menu',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, top: 4.0, bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLandscapeFooter() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Housie Multiplayer v2.0', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
              const SizedBox(height: 2),
              const Text('100% Free Forever', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.sports_esports, color: Colors.blue[300], size: 18),
              const SizedBox(width: 10),
              Icon(Icons.favorite, color: Colors.teal[300], size: 18),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String featureName) {
    setState(() {
      _comingSoonItem = featureName;
    });
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (mounted) {
        setState(() {
          if (_comingSoonItem == featureName) _comingSoonItem = null;
        });
      }
    });
  }

  // Unified Full-Landscape Dialog Frame that prevents shrinkage
  Widget _buildLandscapeDialogFrame({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
    List<Widget>? actions,
    double maxWidth = 760,
    double maxHeight = 390,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = min(screenSize.width * 0.92, maxWidth);
    final dialogHeight = min(screenSize.height * 0.92, maxHeight);

    return Dialog(
      backgroundColor: const Color(0xFF13203C),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white12, width: 1.2),
      ),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Close',
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 16),

            // Main Expanded Content Area
            Expanded(child: content),

            // Optional Actions Footer
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHowToPlay() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => _buildLandscapeDialogFrame(
        context: dialogCtx,
        icon: Icons.menu_book,
        iconColor: Colors.blue[300]!,
        title: 'How to Play Housie',
        maxWidth: 780,
        maxHeight: 390,
        content: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRuleSection(
                      '1. Introduction',
                      'Housie (Tambola / Bingo 90) is played with numbers 1 to 90 called out in real time. Players mark matching numbers on their tickets.',
                    ),
                    const SizedBox(height: 12),
                    _buildRuleSection(
                      '2. Ticket Structure',
                      'Each ticket contains 3 rows and 9 columns with 15 numbers (5 numbers per row). Columns group numbers from 1-9, 10-19, etc.',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              // Column 2
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRuleSection(
                      '3. Winning Patterns',
                      '• EARLY 5: Any 5 marked numbers\n'
                      '• TOP LINE: All 5 numbers in top row\n'
                      '• MIDDLE LINE: All 5 numbers in middle row\n'
                      '• BOTTOM LINE: All 5 numbers in bottom row\n'
                      '• FULL HOUSE: All 15 numbers completed',
                    ),
                    const SizedBox(height: 12),
                    _buildRuleSection(
                      '4. How to Win',
                      'When your ticket satisfies a pattern, tap the CLAIM button immediately to lock in your victory!',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.amber, fontSize: 13.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteFriends() async {
    Navigator.pop(context);
    await Share.share(
      'Hey! Let\'s play Housie (Tambola) together! Join my room or host a new game. Download the app here: https://play.google.com/store/apps/details?id=com.housie.developerbros',
      subject: 'Let\'s play Housie Multiplayer!',
    );
  }

  Future<void> _showSettings() async {
    Navigator.pop(context);

    final persistence = PersistenceService();
    final nameController = TextEditingController(text: _playerName);
    bool soundEnabled = await persistence.isSoundEnabled();
    bool musicEnabled = await persistence.isMusicEnabled();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return _buildLandscapeDialogFrame(
            context: dialogContext,
            icon: Icons.settings,
            iconColor: Colors.amber,
            title: 'Game Settings',
            maxWidth: 780,
            maxHeight: 390,
            content: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: Player Profile & Tutorial
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PLAYER PROFILE',
                                style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: 'Enter your name',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13.5),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.06),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.amber, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TUTORIALS & GUIDES',
                                style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await persistence.resetTutorial();
                                  if (!dialogContext.mounted) return;
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(content: Text('Tutorial reset successfully! Return to Home Screen to view it.')),
                                  );
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('RESET COACHMARKS TUTORIAL', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // RIGHT COLUMN: Audio & Sound Toggles
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AUDIO & FEEDBACK',
                            style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            title: const Text('Sound Effects', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                            subtitle: const Text('Audio triggers on game actions', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            value: soundEnabled,
                            activeThumbColor: Colors.amber,
                            activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) async {
                              await persistence.setSoundEnabled(val);
                              setDialogState(() {
                                soundEnabled = val;
                              });
                            },
                          ),
                          const Divider(color: Colors.white10),
                          SwitchListTile(
                            title: const Text('Background Music', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                            subtitle: const Text('Relaxing background music', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            value: musicEnabled,
                            activeThumbColor: Colors.amber,
                            activeTrackColor: Colors.amber.withValues(alpha: 0.5),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) async {
                              await persistence.setMusicEnabled(val);
                              setDialogState(() {
                                musicEnabled = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    await persistence.saveDefaultPlayerName(newName);
                    if (mounted) {
                      setState(() {
                        _playerName = newName;
                      });
                    }
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    Navigator.pop(context);
    final Uri url = Uri.parse('https://developerbros.com/privacy-policy/housie');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => _buildLandscapeDialogFrame(
        context: dialogCtx,
        icon: Icons.description,
        iconColor: Colors.cyan[300]!,
        title: 'Privacy Policy',
        maxWidth: 720,
        maxHeight: 380,
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Housie Multiplayer is 100% free and respects user privacy. We do not sell or collect private personal data. Information stored locally (e.g. preferences, custom player name) stays safely on your device.\n\n'
                  'Multiplayer games utilize Firebase for real-time room communication with anonymous authentication, requiring no passwords or unnecessary permissions.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.45),
                ),
                SizedBox(height: 12),
                Text(
                  'For inquiries or questions: contact@developerbros.com',
                  style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout() async {
    Navigator.pop(context);

    String version = '1.0.0';
    String buildNumber = '3';
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    } catch (e) {
      debugPrint('Error getting package info: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => _buildLandscapeDialogFrame(
        context: dialogCtx,
        icon: Icons.info,
        iconColor: Colors.blue[300]!,
        title: 'About Housie Multiplayer',
        maxWidth: 720,
        maxHeight: 380,
        content: Row(
          children: [
            // Left App Identity Card
            Container(
              width: 190,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Housie Multiplayer',
                    style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v$version ($buildNumber)',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right Info Details
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Real-Time Multiplayer Experience',
                            style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Play classic Housie / Tambola with family and friends anywhere. Host custom games, pick tickets, and celebrate winning patterns together.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developed by Developer Bros',
                            style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '100% Free Forever • Made with ❤️ for players everywhere.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? badge;
  final bool isSelected;
  final bool isComingSoon;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.badge,
    this.isSelected = false,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected || isComingSoon ? const Color(0xFF223254) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          isComingSoon ? 'Coming Soon' : label,
          style: TextStyle(
            color: isComingSoon ? Colors.amber : Colors.white,
            fontSize: 13.5,
            fontWeight: isComingSoon ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isComingSoon ? null : badge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}
