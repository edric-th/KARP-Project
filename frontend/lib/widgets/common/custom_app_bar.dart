import 'package:flutter/material.dart';
import 'package:frontend/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? iconColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.backgroundLight,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 70,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: iconColor ?? AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: titleColor ?? AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
