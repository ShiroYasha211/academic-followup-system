import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class StaffAppVariant {
  static const value = String.fromEnvironment(
    'APP_VARIANT',
    defaultValue: 'moeen',
  );

  static bool get isDemo => value == 'demo';
}

abstract final class StaffAppBrand {
  static String get appTitle =>
      StaffAppVariant.isDemo ? 'نظام المتابعة الأكاديمية' : 'Moeen Doctor';

  static String get displayName =>
      StaffAppVariant.isDemo ? 'المتابعة الأكاديمية' : 'معين';

  static String get compactTagline =>
      StaffAppVariant.isDemo ? 'لوحة الكادر' : 'المنصة التعليمية';

  static String get tagline => StaffAppVariant.isDemo
      ? 'إدارة أكاديمية مبسطة'
      : 'منصتك التعليمية في مكان واحد';

  static String get logoAsset => StaffAppVariant.isDemo
      ? 'assets/brand/logo_demo.png'
      : 'assets/brand/logo.jpeg';
}

abstract final class StaffFeatureFlags {
  static bool get showSubscriptionAndBalance => !StaffAppVariant.isDemo;
  static bool get showFinancialLedger => !StaffAppVariant.isDemo;
  static bool get showDoctorClinical => !StaffAppVariant.isDemo;
  static bool get showDoctorRareCases => !StaffAppVariant.isDemo;
  static bool get showDoctorVolunteers => !StaffAppVariant.isDemo;
}

abstract final class StaffBrandColors {
  static Color get primary =>
      StaffAppVariant.isDemo ? const Color(0xFF4338CA) : AppColors.primary;
  static Color get primaryHover =>
      StaffAppVariant.isDemo ? const Color(0xFF3730A3) : AppColors.primaryHover;
  static Color get primaryDark => StaffAppVariant.isDemo
      ? const Color(0xFF3730A3)
      : AppColors.royalBlueDark;
  static Color get accent =>
      StaffAppVariant.isDemo ? const Color(0xFF7C3AED) : AppColors.gold;
  static Color get accentDeep =>
      StaffAppVariant.isDemo ? const Color(0xFF6366F1) : AppColors.goldDeep;
  static Color get background =>
      StaffAppVariant.isDemo ? const Color(0xFFF1F5F9) : AppColors.cream;
  static Color get backgroundAlt =>
      StaffAppVariant.isDemo ? const Color(0xFFF8FAFC) : AppColors.creamAlt;
  static Color get surface => AppColors.surface;
  static Color get textPrimary =>
      StaffAppVariant.isDemo ? const Color(0xFF1E293B) : AppColors.midnight;
  static Color get textSecondary =>
      StaffAppVariant.isDemo ? const Color(0xFF64748B) : AppColors.slate500;
  static Color get textLight =>
      StaffAppVariant.isDemo ? const Color(0xFF94A3B8) : AppColors.slate400;
  static Color get border =>
      StaffAppVariant.isDemo ? const Color(0xFFE2E8F0) : AppColors.slate200;

  static LinearGradient get authGradient => StaffAppVariant.isDemo
      ? const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE0E7FF)],
        )
      : AppColors.authGradient;

  static LinearGradient get primaryGradient => StaffAppVariant.isDemo
      ? const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4338CA), Color(0xFF3730A3)],
        )
      : AppColors.primaryGradient;

  static LinearGradient get accentGradient => StaffAppVariant.isDemo
      ? const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        )
      : AppColors.goldGradient;

  static LinearGradient get brandGradient => StaffAppVariant.isDemo
      ? const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4338CA), Color(0xFF4F46E5), Color(0xFF7C3AED)],
        )
      : AppColors.brandGradient;
}

abstract final class StaffDemoRouteGuard {
  static String? redirect(String path) {
    if (!StaffAppVariant.isDemo) return null;

    if ((path == '/doctor/subscription' &&
            !StaffFeatureFlags.showSubscriptionAndBalance) ||
        (path == '/administrative/subscription' &&
            !StaffFeatureFlags.showSubscriptionAndBalance) ||
        (path == '/doctor/ledger' && !StaffFeatureFlags.showFinancialLedger) ||
        (path == '/administrative/ledger' &&
            !StaffFeatureFlags.showFinancialLedger) ||
        (path == '/doctor/rare-cases' &&
            !StaffFeatureFlags.showDoctorRareCases) ||
        (path == '/doctor/volunteers' &&
            !StaffFeatureFlags.showDoctorVolunteers) ||
        (path == '/doctor/clinical' && !StaffFeatureFlags.showDoctorClinical) ||
        (path.startsWith('/doctor/clinical/') &&
            !StaffFeatureFlags.showDoctorClinical)) {
      return '/staff/dashboard';
    }

    return null;
  }
}
