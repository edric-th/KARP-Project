import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AIChatButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AIChatButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AppSpacing.md,
      bottom: AppSpacing.xxl + 80,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: AppColors.textWhite,
                size: 24,
              ),
              SizedBox(height: 2),
              Text(
                'ASK AI',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
