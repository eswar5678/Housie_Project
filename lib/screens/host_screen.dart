import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';
import '../services/game_service.dart';
import '../services/persistence_service.dart';
import '../widgets/geometric_background.dart';
import '../widgets/custom_app_bar.dart';
import 'lobby_screen.dart';

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
      backgroundColor: const Color(0xFF102A43),
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
      body: GeometricBackground(
        shapes: [
          BackgroundShapeItem(
            shape: BackgroundShape.square,
            color: const Color(0xFF1E88E5), // Blue
            size: 150,
            top: 50,
            right: -40,
            rotation: 0.4,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.triangle,
            color: const Color(0xFF9575CD), // Purple
            size: 100,
            bottom: 50,
            left: 20,
            rotation: -0.2,
          ),
        ],
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: kToolbarHeight + 16.0),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Host a Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a private room and invite your friends in seconds.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF162A45).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildField(
                              controller: _roomNameController,
                              label: 'ROOM NAME',
                              hint: 'Weekend Housie',
                            ),
                            const SizedBox(height: 20),
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
                            const SizedBox(height: 20),
                            _buildField(
                              controller: _hostNameController,
                              label: 'HOST NAME',
                              hint: 'Eswar',
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _createRoom,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Create Room →',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Players can join using your Room ID.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
            color: Colors.amber,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.amber, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
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
