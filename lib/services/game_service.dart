import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/room.dart';
import 'ticket_generator.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('rooms');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      debugPrint('Firebase: Signing in anonymously...');
      await _auth.signInAnonymously();
    }
  }

  Future<void> createRoom(HousieRoom room) async {
    await _ensureAuthenticated();
    final cleanId = room.roomId.trim().toUpperCase();
    debugPrint('Firebase: Creating room $cleanId');
    await _dbRef.child(cleanId).set(room.toMap());
  }

  Future<String?> joinRoom(String roomId, Player player) async {
    await _ensureAuthenticated();
    final cleanId = roomId.trim().toUpperCase();
    final playerNameClean = player.name.trim().toUpperCase();

    // 1. Check if room exists
    final snap = await _dbRef.child(cleanId).child('roomId').get();
    if (!snap.exists) return "Room not found!";

    // 2. Check if name is already taken by another player (different UID)
    final playerSnap = await _dbRef.child(cleanId).child('players').child(playerNameClean).get();
    if (playerSnap.exists) {
      final val = playerSnap.value;
      if (val is Map) {
        final existingUid = val['uid'];
        if (existingUid != player.uid) {
          return "Name already taken in this room! Please use a different name.";
        }
      }
    }

    // 3. Write player data
    await _dbRef.child(cleanId).child('players').child(playerNameClean).set(player.toMap());

    // 4. Setup presence
    _dbRef.child(cleanId).child('players').child(playerNameClean).onDisconnect().update({
      'isOnline': false,
    });
    
    debugPrint('Firebase: Player ${player.name} joined $cleanId (UID: ${player.uid})');
    return null;
  }

  Future<void> updatePlayerStatus(String roomId, String playerName, bool isOnline) async {
    final cleanId = roomId.trim().toUpperCase();
    final playerNameClean = playerName.trim().toUpperCase();
    await _dbRef.child(cleanId).child('players').child(playerNameClean).update({
      'isOnline': isOnline,
    });
  }

  Future<void> leaveRoom(String roomId, String playerName) async {
    final cleanId = roomId.trim().toUpperCase();
    await updatePlayerStatus(roomId, playerName, false);
    debugPrint('Firebase: Player $playerName left $cleanId');
  }

  Future<void> deleteRoom(String roomId) async {
    final cleanId = roomId.trim().toUpperCase();
    await _dbRef.child(cleanId).remove();
    debugPrint('Firebase: Room $cleanId deleted');
  }

  Future<void> startGame(String roomId) async {
    final cleanId = roomId.trim().toUpperCase();
    await _dbRef.child(cleanId).update({
      'status': 'playing',
      'gameStartTimestamp': ServerValue.timestamp,
    });
  }

  Future<void> callNextNumber(String roomId) async {
    final cleanId = roomId.trim().toUpperCase();
    final snapshot = await _dbRef.child(cleanId).get();
    
    if (snapshot.exists) {
      final roomData = snapshot.value as Map<dynamic, dynamic>;
      final room = HousieRoom.fromMap(roomData);
      
      if (room.calledNumbers.length >= 90) return;

      // Generate pool of available numbers
      final available = List.generate(90, (i) => i + 1)
          .where((n) => !room.calledNumbers.contains(n))
          .toList();
      
      if (available.isNotEmpty) {
        final next = available[Random().nextInt(available.length)];
        final updatedCalled = List<int>.from(room.calledNumbers)..add(next);
        
        await _dbRef.child(cleanId).update({
          'currentNumber': next,
          'calledNumbers': updatedCalled,
          'lastCallTimestamp': ServerValue.timestamp,
        });
      }
    }
  }

  Future<void> updatePlayerTickets(String roomId, String playerName, int ticketCount, List<HousieTicket> tickets) async {
    final cleanId = roomId.trim().toUpperCase();
    final playerNameClean = playerName.trim().toUpperCase();
    
    // Direct update to specific player node
    await _dbRef.child(cleanId).child('players').child(playerNameClean).update({
      'ticketCount': ticketCount,
      'tickets': tickets.map((t) => t.toMap()).toList(),
    });
  }

  Future<String?> submitClaim(String roomId, String playerName, int ticketIndex, String claimType) async {
    final cleanId = roomId.trim().toUpperCase();
    final snapshot = await _dbRef.child(cleanId).get();
    
    if (snapshot.exists) {
      final roomData = snapshot.value as Map<dynamic, dynamic>;
      final room = HousieRoom.fromMap(roomData);
      
      // 1. Check if this claim type was already won by someone else
      if (room.claims.any((c) => c.type == claimType)) {
        return "This prize has already been claimed!";
      }

      final pKey = playerName.trim().toUpperCase();
      if (!room.players.containsKey(pKey)) return "Player not found!";
      
      final ticket = room.players[pKey]!.tickets[ticketIndex];
      final called = room.calledNumbers;

      bool isValid = false;
      
      switch (claimType) {
        case 'early_five':
          int count = ticket.numbers.where((n) => n != 0 && called.contains(n)).length;
          isValid = count >= 5;
          break;
        case 'top_line':
          List<int> row = ticket.numbers.sublist(0, 9).where((n) => n != 0).toList();
          isValid = row.isNotEmpty && row.every((n) => called.contains(n));
          break;
        case 'middle_line':
          List<int> row = ticket.numbers.sublist(9, 18).where((n) => n != 0).toList();
          isValid = row.isNotEmpty && row.every((n) => called.contains(n));
          break;
        case 'bottom_line':
          List<int> row = ticket.numbers.sublist(18, 27).where((n) => n != 0).toList();
          isValid = row.isNotEmpty && row.every((n) => called.contains(n));
          break;
        case 'full_house':
          int count = ticket.numbers.where((n) => n != 0 && called.contains(n)).length;
          isValid = count == 15;
          break;
      }

      if (isValid) {
        final newClaim = HousieClaim(
          type: claimType,
          playerName: playerName,
          ticketIndex: ticketIndex,
          timestamp: DateTime.now(),
        );
        
        final updatedClaims = List<HousieClaim>.from(room.claims)..add(newClaim);
        
        Map<String, dynamic> updates = {
          'claims': updatedClaims.map((c) => c.toMap()).toList(),
        };

        if (claimType == 'full_house') {
          updates['status'] = 'finished';
        }

        await _dbRef.child(cleanId).update(updates);
        return null; // Success
      } else {
        return "Invalid claim! Check your ticket again.";
      }
    }
    return "Room not found!";
  }

  Future<void> promoteNewHost(String roomId, String newHostName, String newHostUid) async {
    final cleanId = roomId.trim().toUpperCase();
    final newHostKey = newHostName.trim().toUpperCase();
    
    await _dbRef.child(cleanId).update({
      'hostName': newHostName,
      'hostUid': newHostUid,
    });
    
    await _dbRef.child(cleanId).child('players').child(newHostKey).update({
      'isHost': true,
    });
    
    debugPrint('Firebase: Promoted $newHostName to Host in $cleanId (UID: $newHostUid)');
  }

  // Generate a pool of 6 tickets for selection
  Future<List<HousieTicket>> generateTicketPool() async {
    final tickets = TicketGenerator.generateSixTickets();
    return tickets;
  }

  // Select a single ticket for the player
  Future<void> selectTicket(String roomId, String playerName, HousieTicket ticket) async {
    await updatePlayerTickets(roomId, playerName, 1, [ticket]);
  }

  Stream<HousieRoom?> getRoomStream(String roomId) {
    final cleanId = roomId.trim().toUpperCase();
    return _dbRef.child(cleanId).onValue.map((event) {
      if (event.snapshot.value != null) {
        return HousieRoom.fromMap(event.snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    });
  }
}
