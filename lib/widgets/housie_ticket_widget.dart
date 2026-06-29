import 'package:flutter/material.dart';
import '../models/room.dart';

class HousieTicketWidget extends StatelessWidget {
  final HousieTicket ticket;
  final Set<int> markedIndices;
  final Function(int)? onNumberTap;

  const HousieTicketWidget({
    super.key, 
    required this.ticket,
    this.markedIndices = const {},
    this.onNumberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Fill parent width (compatible with GridView cells)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            childAspectRatio: 1.0, // Square cells for responsive height
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: 27,
          itemBuilder: (context, index) {
            final number = ticket.numbers[index];
            bool isMarked = markedIndices.contains(index);

            return InkWell(
              onTap: number != 0 ? () => onNumberTap?.call(index) : null,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 0.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (number != 0)
                      Text(
                        number.toString(),
                        style: TextStyle(
                          color: const Color(0xFF1E88E5), // Reference Blue
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: isMarked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    if (isMarked)
                      const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 28,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
