import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class StudentAppBrand {
  static const appTitle = 'Moeen Student';
  static const displayName = 'معين';
  static const tagline = 'المنصة التعليمية';
  static const fullTagline = 'منصتك التعليمية في مكان واحد';
  static const logoAsset = 'assets/brand/logo.jpeg';
}

abstract final class StudentFeatureFlags {
  static const showSubscriptionAndBalance = true;
  static const showFinancialLedger = true;
  static const showCardGeneration = true;
  static const showOneLineShot = true;
  static const showStudentClinical = true;
  static const showTreeFarm = true;

  static const showDelegateSubscriptionAndBalance = true;
  static const showDelegateLedger = true;
}

abstract final class StudentBrandColors {
  static Color get primary => AppColors.primary;
  static Color get primaryHover => AppColors.primaryHover;
  static Color get primaryDark => AppColors.royalBlueDark;
  static Color get accent => AppColors.gold;
  static Color get accentDeep => AppColors.goldDeep;
  static Color get background => AppColors.cream;
  static Color get backgroundAlt => AppColors.creamAlt;
  static Color get surface => AppColors.surface;
  static Color get textPrimary => AppColors.midnight;
  static Color get textSecondary => AppColors.slate500;
  static Color get textLight => AppColors.slate400;
  static Color get border => AppColors.slate200;

  static LinearGradient get authGradient => AppColors.authGradient;
  static LinearGradient get primaryGradient => AppColors.primaryGradient;
  static LinearGradient get accentGradient => AppColors.goldGradient;
  static LinearGradient get brandGradient => AppColors.brandGradient;
}
