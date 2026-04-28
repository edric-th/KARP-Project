import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textMedium,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class InfoRowWithChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> chips;
  final VoidCallback? onAdd;

  const InfoRowWithChip({
    super.key,
    required this.icon,
    required this.label,
    required this.chips,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textMedium,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall,
                    ),
                    if (onAdd != null)
                      GestureDetector(
                        onTap: onAdd,
                        child: const Text(
                          '+ Add',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: chips.map((chip) => _buildChip(chip)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String chip) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.chipOrange,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chip,
            style: const TextStyle(
              color: AppColors.waitingOrangeText,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.close,
            size: 14,
            color: AppColors.waitingOrangeText,
          ),
        ],
      ),
    );
  }
}
