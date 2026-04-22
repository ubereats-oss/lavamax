import 'package:flutter/material.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/data/models/slot_model.dart';
import 'package:intl/intl.dart';
class SlotCard extends StatelessWidget {
  final SlotModel slot;
  final bool isSelected;
  final VoidCallback onTap;
  const SlotCard({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final startTime = timeFormat.format(slot.startTime);
    final endTime = timeFormat.format(slot.endTime);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              startTime,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? AppColors.accentDark : AppColors.black,
              ),
            ),
            Text(
              endTime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isSelected ? AppColors.accentDark : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
