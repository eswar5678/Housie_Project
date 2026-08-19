import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/persistence_service.dart';
import '../theme/app_theme.dart';

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
    return Drawer(
      backgroundColor: AppColors.surface, // dark blueish black
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            
            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    label: 'Themes & Ticket Skins',
                    iconColor: Colors.pink[200]!,
                    onTap: () => _showComingSoon('Themes & Ticket Skins'),
                    isComingSoon: _comingSoonItem == 'Themes & Ticket Skins',
                  ),
                  
                  const SizedBox(height: 16),
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
                  
                  const SizedBox(height: 16),
                  _buildSectionTitle('APP'),
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
                      if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
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
                ],
              ),
            ),
            
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2845),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE040FB), Color(0xFF651FFF)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _playerName.isNotEmpty ? _playerName[0].toUpperCase() : 'P',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _playerName.isEmpty ? 'Player' : _playerName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text('Level 12 • Housie Pro', style: TextStyle(color: Colors.amber, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Text('Housie Multiplayer v2.0', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 4),
          const Text('100% Free Forever', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book, color: Colors.blue[300], size: 24),
              const SizedBox(width: 20),
              Icon(Icons.camera_alt, color: Colors.grey[500], size: 24),
              const SizedBox(width: 20),
              Icon(Icons.play_circle_filled, color: Colors.blue[400], size: 24),
              const SizedBox(width: 20),
              Icon(Icons.favorite, color: Colors.teal[300], size: 24),
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

  void _showHowToPlay() {
    Navigator.pop(context); // Close the drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.only(top: 20, left: 24, right: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        title: Row(
          children: [
            Icon(Icons.menu_book, color: Colors.blue[300], size: 28),
            const SizedBox(width: 12),
            const Text(
              'How to Play',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRuleSection(
                  '1. Introduction',
                  'Housie (also known as Tambola or Bingo 90) is a game of probability. The Host draws random numbers from 1 to 90 and calls them out. Players mark these numbers on their ticket(s).',
                ),
                const SizedBox(height: 16),
                _buildRuleSection(
                  '2. The Ticket',
                  'Each ticket has 3 horizontal lines and 9 vertical columns, containing 15 numbers (5 per line). Columns represent number ranges (e.g., Column 1 has 1-9, Column 2 has 10-19, and so on).',
                ),
                const SizedBox(height: 16),
                _buildRuleSection(
                  '3. Winning Patterns',
                  'Claim a winning prize as soon as you complete one of these patterns:\n\n'
                  '• EARLY 5: Mark any 5 numbers anywhere on your ticket.\n'
                  '• TOP LINE: Mark all 5 numbers in the top row.\n'
                  '• MIDDLE LINE: Mark all 5 numbers in the middle row.\n'
                  '• BOTTOM LINE: Mark all 5 numbers in the bottom row.\n'
                  '• FULL HOUSE: Mark all 15 numbers on your ticket.',
                ),
                const SizedBox(height: 16),
                _buildRuleSection(
                  '4. Gameplay Flow',
                  '• Select your tickets in the lobby after joining.\n'
                  '• Listen to the numbers called by the host.\n'
                  '• Tap the called numbers on your ticket to mark them.\n'
                  '• Press "Claim" when you achieve a winning pattern. If valid, the prize is yours!',
                ),
              ],
            ),
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

  Widget _buildRuleSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Future<void> _inviteFriends() async {
    Navigator.pop(context); // Close the drawer
    await Share.share(
      'Hey! Let\'s play Housie (Tambola) together! Join my room or host a new game. Download the app here: https://play.google.com/store/apps/details?id=com.housie.developerbros',
      subject: 'Let\'s play Housie Multiplayer!',
    );
  }

  Future<void> _showSettings() async {
    Navigator.pop(context); // Close the drawer
    
    final persistence = PersistenceService();
    final nameController = TextEditingController(text: _playerName);
    bool soundEnabled = await persistence.isSoundEnabled();
    bool musicEnabled = await persistence.isMusicEnabled();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF162A45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.settings, color: Colors.grey[300], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'PLAYER PROFILE',
                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.amber, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'AUDIO PREFERENCES',
                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  SwitchListTile(
                    title: const Text('Sound Effects', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text('Play sound triggers on game events', style: TextStyle(color: Colors.white54, fontSize: 11)),
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
                  SwitchListTile(
                    title: const Text('Background Music', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: const Text('Enjoy looping background tunes', style: TextStyle(color: Colors.white54, fontSize: 11)),
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
                  const SizedBox(height: 16),
                  const Text(
                    'HELP & TUTORIAL',
                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await persistence.resetTutorial();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tutorial reset successfully! Return to Home Screen to view it.')),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('RESET COACHMARKS TUTORIAL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    await persistence.saveDefaultPlayerName(newName);
                    setState(() {
                      _playerName = newName;
                    });
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('SAVE', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    Navigator.pop(context); // Close the drawer
    final Uri url = Uri.parse('https://developerbros.com/privacy-policy/housie');
    
    // Attempt standard URL launch
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }

    // Fallback privacy dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.description, color: Colors.grey[300], size: 28),
            const SizedBox(width: 12),
            const Text('Privacy Policy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Housie Multiplayer is 100% free and respects user privacy. We do not sell or collect private personal data. Information stored locally (e.g. settings, name) stays on your device. Firebase auth is done anonymously without requesting email/password unless linked.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'For updates, contact developerbros@gmail.com.',
                style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout() async {
    Navigator.pop(context); // Close the drawer
    
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162A45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.jpg',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Housie Multiplayer',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Version $version (Build $buildNumber)',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enjoy a classic game of Housie (Tambola/Bingo) with real-time multiplayer features. Join, select ticket, and check prizes instantly!',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            const Text(
              'Developed by Developer Bros',
              style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const Text(
              '100% Free Forever • Made with ❤️',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.amber)),
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
        color: isSelected || isComingSoon ? const Color(0xFF2A3B5A) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(
          isComingSoon ? 'Coming Soon' : label,
          style: TextStyle(
            color: isComingSoon ? Colors.amber : Colors.white,
            fontSize: 15,
            fontWeight: isComingSoon ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isComingSoon ? null : badge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
