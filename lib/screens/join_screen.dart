import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/room.dart';
import '../services/game_service.dart';
import '../services/persistence_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/geometric_background.dart';
import 'lobby_screen.dart';

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
      // 1. Silent login if not yet done
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final uid = auth.currentUser!.uid;

      final roomId = _roomIdController.text.trim().toUpperCase();
      final playerName = _playerNameController.text.trim();
      
      final errorMsg = await GameService().joinRoom(
        roomId,
        Player(
          name: playerName,
          uid: uid,
        ),
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
        height: MediaQuery.of(context).size.height * 0.7,
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
      backgroundColor: const Color(0xFF102A43),
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(),
      body: GeometricBackground(
        shapes: [
          BackgroundShapeItem(
            shape: BackgroundShape.hexagon,
            color: const Color(0xFF4DB6AC), // Teal
            size: 200,
            bottom: -50,
            right: -30,
            rotation: -0.3,
          ),
          BackgroundShapeItem(
            shape: BackgroundShape.circle,
            color: const Color(0xFF1E88E5), // Blue
            size: 120,
            top: 100,
            left: -20,
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
                        'Join a Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter details to join and play with friends in seconds.',
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
                              controller: _roomIdController,
                              label: 'ROOM ID',
                              hint: 'e.g., HS1234',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent),
                                onPressed: _scanQR,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Room ID';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
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
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _joinRoom,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Join Room →',
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
                        'Ask the host for the Room ID to join.',
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
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            suffixIcon: suffixIcon,
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
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
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
        ),
      ],
    );
  }
}
