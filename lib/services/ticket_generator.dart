import 'dart:math';
import '../models/room.dart';

class TicketGenerator {
  static List<HousieTicket> generateSixTickets() {
    int attempts = 0;
    while (attempts < 500) {
      attempts++;
      // 1. Initialize numbers 1-90 distributed into 9 columns
      List<List<int>> columns = List.generate(9, (i) {
        int start = i == 0 ? 1 : i * 10;
        int end = i == 8 ? 90 : (i * 10) + 9;
        return List.generate(end - start + 1, (j) => start + j)..shuffle();
      });

      List<List<int>> rows = List.generate(18, (_) => List.filled(9, 0));
      List<int> rowCounts = List.filled(18, 0);
      List<int> colRemaining = [9, 10, 10, 10, 10, 10, 10, 10, 11];
      bool success = true;

      // Pass 1: Mandatory number in each column per ticket (54 numbers)
      for (int t = 0; t < 6; t++) {
        for (int c = 0; c < 9; c++) {
          List<int> validRows = [];
          for (int r = t * 3; r < (t * 3) + 3; r++) {
            if (rowCounts[r] < 5) validRows.add(r);
          }
          if (validRows.isEmpty) { success = false; break; }
          int r = validRows[Random().nextInt(validRows.length)];
          rows[r][c] = columns[c].removeLast();
          rowCounts[r]++;
          colRemaining[c]--;
        }
        if (!success) break;
      }

      // Pass 2: Distribute remaining 36 numbers to fill all rows to exactly 5
      if (success) {
        for (int c = 0; c < 9; c++) {
          while (colRemaining[c] > 0) {
            List<int> eligibleRows = [];
            for (int r = 0; r < 18; r++) {
              // Row must have room, and must not have a number in this column already
              if (rowCounts[r] < 5 && rows[r][c] == 0) eligibleRows.add(r);
            }
            if (eligibleRows.isEmpty) { success = false; break; }
            
            // Prioritize rows with the fewest numbers to ensure we reach 5 everywhere
            eligibleRows.sort((a, b) => rowCounts[a].compareTo(rowCounts[b]));
            int r = eligibleRows[0]; // Pick one of the least filled rows
            
            rows[r][c] = columns[c].removeLast();
            rowCounts[r]++;
            colRemaining[c]--;
          }
          if (!success) break;
        }
      }

      if (success && rowCounts.every((c) => c == 5)) {
        return _finalizeTickets(rows);
      }
    }
    return generateSixTickets(); // Fallback if 500 attempts failed (unlikely)
  }

  static List<HousieTicket> _finalizeTickets(List<List<int>> rows) {
    List<HousieTicket> tickets = [];
    for (int t = 0; t < 6; t++) {
      List<int> ticketNumbers = [];
      for (int r = t * 3; r < (t * 3) + 3; r++) {
        ticketNumbers.addAll(rows[r]);
      }
      // Sort each column within the ticket
      for (int c = 0; c < 9; c++) {
        List<int> colVals = [];
        for (int r = 0; r < 3; r++) {
          int val = ticketNumbers[r * 9 + c];
          if (val != 0) colVals.add(val);
        }
        colVals.sort();
        int vIdx = 0;
        for (int r = 0; r < 3; r++) {
          if (ticketNumbers[r * 9 + c] != 0) {
            ticketNumbers[r * 9 + c] = colVals[vIdx++];
          }
        }
      }
      tickets.add(HousieTicket(numbers: ticketNumbers));
    }
    return tickets;
  }
}
