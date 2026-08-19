import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/room.dart';

/// Immutable, UI-only state for the [GameScreen].
///
/// Room/game data (the Firebase room stream, timers, host handoff) remains
/// inside the screen's State; only local presentation state lives here.
class GameUiState {
  final bool soundOn;

  /// ticketIndex -> set of marked cell indices (0..26) on that ticket.
  final Map<int, Set<int>> ticketMarkings;

  final HousieClaim? activeClaimNotification;

  const GameUiState({
    this.soundOn = true,
    this.ticketMarkings = const {},
    this.activeClaimNotification,
  });

  GameUiState copyWith({
    bool? soundOn,
    Map<int, Set<int>>? ticketMarkings,
    HousieClaim? activeClaimNotification,
    bool clearClaimNotification = false,
  }) {
    return GameUiState(
      soundOn: soundOn ?? this.soundOn,
      ticketMarkings: ticketMarkings ?? this.ticketMarkings,
      activeClaimNotification: clearClaimNotification
          ? null
          : (activeClaimNotification ?? this.activeClaimNotification),
    );
  }
}

class GameUiController extends Notifier<GameUiState> {
  @override
  GameUiState build() => const GameUiState();

  void toggleSound() {
    state = state.copyWith(soundOn: !state.soundOn);
  }

  /// Marks a ticket cell only if its number has actually been called.
  void toggleMark({
    required int ticketIndex,
    required int cellIndex,
    required int number,
    required List<int> calledNumbers,
  }) {
    if (!calledNumbers.contains(number)) return;

    final markings = <int, Set<int>>{
      for (final entry in state.ticketMarkings.entries)
        entry.key: Set<int>.from(entry.value),
    };

    final cells = markings[ticketIndex] ?? <int>{};
    if (!cells.contains(cellIndex)) {
      cells.add(cellIndex);
      markings[ticketIndex] = cells;
      state = state.copyWith(ticketMarkings: markings);
    }
  }

  void showClaimNotification(HousieClaim claim) {
    state = state.copyWith(activeClaimNotification: claim);
  }

  void dismissClaimNotification() {
    state = state.copyWith(clearClaimNotification: true);
  }
}

final gameUiControllerProvider =
    NotifierProvider<GameUiController, GameUiState>(GameUiController.new);
