import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.secondaryText,
  );

  static const TextStyle small = TextStyle(
    fontSize: 14,
    color: AppColors.secondaryText,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 14,
    color: AppColors.hintText,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}