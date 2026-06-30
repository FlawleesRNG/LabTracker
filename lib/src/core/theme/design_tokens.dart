part of '../../../main.dart';

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double card = lg;
  static const double input = md;
  static const double pill = 999;
}

abstract final class AppTouchTarget {
  static const double minimum = 48;
}

abstract final class AppMaxWidth {
  static const double compact = 720;
  static const double standard = 980;
  static const double wide = 1200;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
}
