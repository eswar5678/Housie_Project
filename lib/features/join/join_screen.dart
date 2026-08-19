import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/room.dart';
import '../../services/game_service.dart';
import '../../services/persistence_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/geometric_background.dart';
import '../../core/widgets/app_panel.dart';
import '../../core/theme/app_theme.dart';
import '../lobby/lobby_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomIdController = TextEditingController();
  final _playerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultName();
  }

  Future<void> _loadDefaultName() async {
    final name = await PersistenceService().getDefaultPlayerName();
    if (name != null && mounted) {
      setState(() {
        _playerNameController.text = name;
      });
    }
  }

  Future<void> _joinRoom() async {
    if (_formKey.currentState!.validate()) {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final uid = auth.currentUser!.uid;

      final roomId = _roomIdController.text.trim().toUpperCase();
      final playerName = _playerNameController.text.trim();

      final errorMsg = await GameService().joinRoom(
        roomId,
        Player(name: playerName, uid: uid),
      );

      if (errorMsg == null) {
        await PersistenceService().saveDefaultPlayerName(playerName);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              roomId: roomId,
              playerName: playerName,
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  void _scanQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            CustomAppBar(
              title: 'Scan Room QR',
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      setState(() {
                        _roomIdController.text = barcode.rawValue!;
                      });
                      Navigator.pop(context);
                      break;
                    }
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Align the QR code within the frame',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
      body: GeometricBackground(
        shapes: [
          BackgroundShapeItem(
            shape: BackgroundShape.hexagon,
            color: AppColors.secondary,
            size: 200,
            bottom: -50,
            right: -30,
            rotation: -0.3,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.circle,
            color: const Color(0xFF1E88E5),
            size: 120,
            top: 100,
            left: -20,
          ),
        ],
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.xl, kToolbarHeight + 12, AppDimens.xl, AppDimens.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildFormPanel()),
                    const SizedBox(width: AppDimens.xl),
                    Expanded(flex: 4, child: _buildInfoPanel()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Join a Game',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        const Text(
          'Enter details to join and play with friends in seconds.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: AppDimens.lg),
        AppPanel(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(
                  controller: _roomIdController,
                  label: 'ROOM ID',
                  hint: 'e.g., HS1234',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: AppColors.secondary),
                    onPressed: _scanQR,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Room ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _playerNameController,
                  label: 'YOUR NAME',
                  hint: 'Enter your name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.lg),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _joinRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Join Room →',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return AppPanel(
      title: 'JOIN IN SECONDS',
      trailing: const Icon(Icons.qr_code_scanner, color: AppColors.secondary, size: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoStep(
            index: '1',
            title: 'Get the Room ID',
            body: 'Ask the host for the code, or just scan their QR.',
            icon: Icons.tag,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimens.md),
          _InfoStep(
            index: '2',
            title: 'Pick your ticket',
            body: 'Choose a ticket from the pool before the game starts.',
            icon: Icons.confirmation_num,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppDimens.md),
          _InfoStep(
            index: '3',
            title: 'Tap numbers as they call',
            body: 'Mark called numbers and claim prizes when you win.',
            icon: Icons.touch_app,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppDimens.lg),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _scanQR,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text(
                'SCAN QR CODE',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            errorStyle: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

class _InfoStep extends StatelessWidget {
  final String index;
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const _InfoStep({
    required this.index,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. $title',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
