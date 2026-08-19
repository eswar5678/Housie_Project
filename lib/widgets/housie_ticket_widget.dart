import 'package:flutter/material.dart';
import '../models/room.dart';
import '../core/theme/app_theme.dart';

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
        color: AppColors.ticketBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.ticketBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            childAspectRatio: 1.0, // Square cells for responsive height
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
          ),
          itemCount: 27,
          itemBuilder: (context, index) {
            final number = ticket.numbers[index];
            bool isMarked = markedIndices.contains(index);

            return InkWell(
              onTap: number != 0 ? () => onNumberTap?.call(index) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: number == 0
                      ? AppColors.ticketEmpty // Shaded empty slate blocks
                      : AppColors.ticketBg, // High-contrast number blocks
                  border: Border.all(
                    color: AppColors.ticketGridLine, // Defined visible grid lines
                    width: 0.75,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (number != 0)
                      Text(
                        number.toString(),
                        style: TextStyle(
                          color: AppColors.ticketNumber, // Dark charcoal/slate
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isMarked ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.redAccent,
                          decorationThickness: 2,
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
