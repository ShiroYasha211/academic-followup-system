import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class StaffAppBrand {
  static const appTitle = 'Moeen Doctor';
  static const displayName = 'معين';
  static const compactTagline = 'المنصة التعليمية';
  static const tagline = 'منصتك التعليمية في مكان واحد';
  static const logoAsset = 'assets/brand/logo.jpeg';
}

abstract final class StaffFeatureFlags {
  static const showSubscriptionAndBalance = true;
  static const showFinancialLedger = true;
  static const showDoctorClinical = true;
  static const showDoctorRareCases = true;
  static const showDoctorVolunteers = true;
}

abstract final class StaffBrandColors {
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
