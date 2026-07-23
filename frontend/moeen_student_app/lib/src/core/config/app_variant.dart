import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class AppVariant {
  static const value = String.fromEnvironment(
    'APP_VARIANT',
    defaultValue: 'moeen',
  );

  static const isDemo = value == 'demo';
}

abstract final class StudentAppBrand {
  static const appTitle = AppVariant.isDemo ? 'متابعة الطالب' : 'Moeen Student';
  static const displayName = AppVariant.isDemo ? 'المتابعة الأكاديمية' : 'معين';
  static const tagline = AppVariant.isDemo
      ? 'نظام المتابعة الأكاديمية'
      : 'المنصة التعليمية';
  static const fullTagline = AppVariant.isDemo
      ? 'نظام المتابعة الأكاديمية للطالب'
      : 'منصتك التعليمية في مكان واحد';
  static const logoAsset = AppVariant.isDemo
      ? 'assets/brand/logo_demo.png'
      : 'assets/brand/logo.jpeg';
}

abstract final class StudentFeatureFlags {
  static const showSubscriptionAndBalance = !AppVariant.isDemo;
  static const showFinancialLedger = !AppVariant.isDemo;
  static const showCardGeneration = !AppVariant.isDemo;
  static const showOneLineShot = !AppVariant.isDemo;
  static const showStudentClinical = !AppVariant.isDemo;
  static const showTreeFarm = !AppVariant.isDemo;

  static const showDelegateSubscriptionAndBalance = !AppVariant.isDemo;
  static const showDelegateLedger = !AppVariant.isDemo;
}

abstract final class StudentBrandColors {
  static Color get primary =>
      AppVariant.isDemo ? const Color(0xFF4338CA) : AppColors.primary;
  static Color get primaryHover =>
      AppVariant.isDemo ? const Color(0xFF3730A3) : AppColors.primaryHover;
  static Color get primaryDark =>
      AppVariant.isDemo ? const Color(0xFF3730A3) : AppColors.royalBlueDark;
  static Color get accent =>
      AppVariant.isDemo ? const Color(0xFF7C3AED) : AppColors.gold;
  static Color get accentDeep =>
      AppVariant.isDemo ? const Color(0xFF6366F1) : AppColors.goldDeep;
  static Color get background =>
      AppVariant.isDemo ? const Color(0xFFF1F5F9) : AppColors.cream;
  static Color get backgroundAlt =>
      AppVariant.isDemo ? const Color(0xFFF8FAFC) : AppColors.creamAlt;
  static Color get surface => AppColors.surface;
  static Color get textPrimary =>
      AppVariant.isDemo ? const Color(0xFF1E293B) : AppColors.midnight;
  static Color get textSecondary =>
      AppVariant.isDemo ? const Color(0xFF64748B) : AppColors.slate500;
  static Color get textLight =>
      AppVariant.isDemo ? const Color(0xFF94A3B8) : AppColors.slate400;
  static Color get border =>
      AppVariant.isDemo ? const Color(0xFFE2E8F0) : AppColors.slate200;

  static LinearGradient get authGradient => AppVariant.isDemo
      ? const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE0E7FF)],
        )
      : AppColors.authGradient;

  static LinearGradient get primaryGradient => AppVariant.isDemo
      ? const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4338CA), Color(0xFF3730A3)],
        )
      : AppColors.primaryGradient;

  static LinearGradient get accentGradient => AppVariant.isDemo
      ? const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        )
      : AppColors.goldGradient;

  static LinearGradient get brandGradient => AppVariant.isDemo
      ? const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4338CA), Color(0xFF4F46E5), Color(0xFF7C3AED)],
        )
      : AppColors.brandGradient;
}
