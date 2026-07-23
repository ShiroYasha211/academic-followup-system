import 'package:flutter/widgets.dart';

class AppDimensions {
  const AppDimensions._();

  static const double pageHorizontal = 18;
  static const double pageTop = 10;
  static const double pageBottom = 34;
  static const double gridGap = 10;
  static const double sectionGap = 18;
  static const double sectionGapLarge = 24;

  static const double cardRadius = 20;
  static const double cardRadiusLarge = 24;
  static const double cardPadding = 16;

  static const double heroRadius = 24;
  static const double heroPaddingHorizontal = 18;
  static const double heroPaddingVertical = 20;
  static const double heroIconBox = 48;
  static const double heroIcon = 24;
  static const double heroTitle = 16;
  static const double heroSubtitle = 12;

  static const double statPadding = 14;
  static const double statIcon = 17;
  static const double statValue = 20;
  static const double statLabel = 10.5;
  static const double statBackgroundIcon = 54;

  static const double quickActionIconBox = 50;
  static const double quickActionIcon = 23;
  static const double quickActionLabel = 11;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    pageHorizontal,
    pageTop,
    pageHorizontal,
    pageBottom,
  );
}
