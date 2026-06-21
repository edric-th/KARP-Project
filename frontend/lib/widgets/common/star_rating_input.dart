import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

/// A row of five tappable stars (1..5). Reports the chosen value via [onChanged].
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              size: size,
              color: filled ? AppColors.warning : AppColors.textMuted,
            ),
          ),
        );
      }),
    );
  }
}
