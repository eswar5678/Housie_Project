import 'package:flutter/material.dart';

import '../../models/room.dart';
import '../theme/app_theme.dart';

/// A premium paper-style Housie ticket (9 columns × 3 rows).
///
/// Warm paper gradient, crisp grid lines, and a "stamped" pop-in red cross
/// when a number is marked.
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
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEFA), Color(0xFFF7F2E7)],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg + 2),
        border: Border.all(color: AppColors.ticketBorder, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 30,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Stack(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
                childAspectRatio: 1.0,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: 27,
              itemBuilder: (context, index) {
                final number = ticket.numbers[index];
                final isMarked = markedIndices.contains(index);
                final isEmpty = number == 0;

                return InkWell(
                  onTap: isEmpty ? null : () => onNumberTap?.call(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? AppColors.ticketEmpty
                          : (isMarked
                              ? const Color(0xFFFEE2E2)
                              : Colors.transparent),
                      border: Border.all(
                        color: AppColors.ticketGridLine,
                        width: 0.75,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!isEmpty)
                          Text(
                            number.toString(),
                            style: TextStyle(
                              color: AppColors.ticketNumber,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              decoration: isMarked
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: const Color(0xFFE11D48),
                              decorationThickness: 2,
                            ),
                          ),
                        if (isMarked)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.elasticOut,
                            builder: (context, v, child) => Transform.scale(
                              scale: v,
                              child: child,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFE11D48),
                              size: 26,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Soft sheen across the top of the ticket.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.35, 1.0],
                    colors: [
                      Color(0x14FFFFFF),
                      Color(0x00FFFFFF),
                      Color(0x00FFFFFF),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
