import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isSuccess = false,
    bool isError = false,
  }) {
    final color = isSuccess
        ? AppColors.success
        : isError
            ? AppColors.error
            : AppColors.primary;

    final icon = isSuccess
        ? Icons.check_circle_rounded
        : isError
            ? Icons.error_rounded
            : Icons.info_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.lg),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: AppSizes.fontSm, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}