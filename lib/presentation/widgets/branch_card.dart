import 'package:flutter/material.dart';
import 'package:lavamax/core/constants/app_colors.dart';
import 'package:lavamax/core/constants/app_dimensions.dart';
import 'package:lavamax/core/utils/formatters.dart';
import 'package:lavamax/data/models/branch_model.dart';
class BranchCard extends StatelessWidget {
  final BranchModel branch;
  final VoidCallback onTap;
  const BranchCard({
    super.key,
    required this.branch,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      branch.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (branch.allowedBrand != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.accent, width: 1),
                      ),
                      child: Text(
                        'Exclusivo ${branch.allowedBrand}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                branch.address,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(
                formatPhone(branch.phone),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
