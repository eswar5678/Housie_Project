import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';
import '../services/game_service.dart';
import '../widgets/geometric_background.dart';
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
      appBar: AppBar(
        title: const Text('Host New Game'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _roomNameController,
                      label: 'Room Name',
                      icon: Icons.meeting_room,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _playersController,
                      label: 'Number of Players',
                      icon: Icons.people,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _hostNameController,
                      label: 'Host Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _priceController,
                      label: 'Price per Ticket',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CREATE ROOM & GO TO LOBBY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    ),
  );
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.amber),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber),
        ),
        filled: true,
        fillColor: Colors.white10,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
