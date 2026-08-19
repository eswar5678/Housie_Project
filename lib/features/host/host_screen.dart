import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/room.dart';
import '../../services/game_service.dart';
import '../../services/persistence_service.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/glow_button.dart';
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
    // Rebuild the live preview as the user types.
    _roomNameController.addListener(_onChanged);
    _playersController.addListener(_onChanged);
    _priceController.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _playersController.dispose();
    _hostNameController.dispose();
    _priceController.dispose();
    super.dispose();
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

  double? get _prizePool {
    final players = int.tryParse(_playersController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    if (players == null || price == null || players <= 0) return null;
    return players * price;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.xl, kToolbarHeight + 12, AppDimens.xl, AppDimens.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildForm()),
                    const SizedBox(width: AppDimens.xl),
                    Expanded(flex: 4, child: _buildLivePreview()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Host a Game',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Set up your room in seconds — the preview updates live.',
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
                        label: 'TICKET PRICE',
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
                GlowButton(
                  label: 'Create Room',
                  icon: Icons.add_circle_rounded,
                  gradient: AppColors.goldGradient,
                  glowColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  height: 54,
                  onPressed: _createRoom,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreview() {
    final roomName = _roomNameController.text.trim();
    final hostName = _hostNameController.text.trim();
    final pool = _prizePool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPanel(
          glowColor: AppColors.accent,
          title: 'LIVE ROOM PREVIEW',
          trailing: const Icon(Icons.visibility_rounded,
              color: AppColors.accent, size: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PRIZE POOL',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pool != null ? '₹${pool.toInt()}' : '₹ —',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      roomName.isEmpty ? 'Your room name' : roomName,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _PreviewRow(
                label: 'HOST',
                value: hostName.isEmpty ? 'You' : hostName,
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 10),
              _PreviewRow(
                label: 'JOIN VIA',
                value: 'Room ID + QR code',
                icon: Icons.qr_code_2_rounded,
              ),
              const SizedBox(height: 10),
              _PreviewRow(
                label: 'STATUS',
                value: 'Not started',
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Players join by typing your Room ID or scanning the QR shown in the lobby.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
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
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PreviewRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Icon(icon, color: AppColors.accent, size: 17),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
