import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/room.dart';
import '../../services/game_service.dart';
import '../../services/persistence_service.dart';
import '../../core/widgets/geometric_background.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/app_panel.dart';
import '../../core/theme/app_theme.dart';
import '../lobby/lobby_screen.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _playersController = TextEditingController();
  final _hostNameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultName();
  }

  Future<void> _loadDefaultName() async {
    final name = await PersistenceService().getDefaultPlayerName();
    if (name != null && mounted) {
      setState(() {
        _hostNameController.text = name;
      });
    }
  }

  Future<void> _createRoom() async {
    if (_formKey.currentState!.validate()) {
      // 1. Silent login if not yet done
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final uid = auth.currentUser!.uid;

      final roomId = 'HS${(1000 + (8999 * (DateTime.now().millisecond / 1000))).toInt()}';
      final hostName = _hostNameController.text.trim();
      final room = HousieRoom(
        roomId: roomId,
        roomName: _roomNameController.text,
        maxPlayers: int.parse(_playersController.text),
        hostName: hostName,
        hostUid: uid,
        ticketPrice: double.parse(_priceController.text),
        players: {
          hostName.toUpperCase(): Player(
            name: hostName,
            uid: uid,
            isHost: true,
          )
        },
      );

      await GameService().createRoom(room);
      await PersistenceService().saveDefaultPlayerName(hostName);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              roomId: roomId,
              isHost: true,
              playerName: hostName,
            ),
          ),
        );
      }
    }
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
            shape: BackgroundShape.square,
            color: AppColors.secondary,
            size: 150,
            top: 50,
            right: -40,
            rotation: 0.4,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.triangle,
            color: AppColors.primary,
            size: 100,
            bottom: 50,
            left: 20,
            rotation: -0.2,
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
          'Host a Game',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        const Text(
          'Create a private room and invite your friends in seconds.',
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
                  controller: _roomNameController,
                  label: 'ROOM NAME',
                  hint: 'Weekend Housie',
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _playersController,
                        label: 'PLAYERS',
                        hint: '10',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        controller: _priceController,
                        label: 'PRICE',
                        hint: '₹50',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildField(
                  controller: _hostNameController,
                  label: 'HOST NAME',
                  hint: 'Eswar',
                ),
                const SizedBox(height: AppDimens.lg),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Create Room →',
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
      title: 'HOW HOSTING WORKS',
      trailing: const Icon(Icons.tips_and_updates, color: AppColors.accent, size: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoStep(
            index: '1',
            title: 'Configure your room',
            body: 'Set a room name, number of players and the ticket price.',
            icon: Icons.tune,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimens.md),
          _InfoStep(
            index: '2',
            title: 'Share your Room ID or QR',
            body: 'Players join instantly by typing the code or scanning your QR.',
            icon: Icons.qr_code_2,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppDimens.md),
          _InfoStep(
            index: '3',
            title: 'Start the game',
            body: 'Once everyone picks a ticket, hit Start — numbers call automatically.',
            icon: Icons.play_circle,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppDimens.lg),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
            ),
            child: const Text(
              'Players can join using your Room ID. Keep it ready to share!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.3)),
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
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter ${label.toLowerCase()}';
            }
            return null;
          },
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
