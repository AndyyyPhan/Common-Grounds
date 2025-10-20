/// Design System - Spacing & Layout
///
/// Defines consistent spacing, padding, and layout constants.
/// Uses 4px base unit for spacing (similar to Material Design).
library;

import 'package:flutter/material.dart';

/// Spacing system using 4px base unit
class AppSpacing {
  AppSpacing._(); // Private constructor

  // ===========================
  // BASE SPACING UNITS
  // ===========================

  static const double unit = 4.0;

  static const double xxs = unit * 1; // 4px
  static const double xs = unit * 2; // 8px
  static const double sm = unit * 3; // 12px
  static const double md = unit * 4; // 16px
  static const double lg = unit * 5; // 20px
  static const double xl = unit * 6; // 24px
  static const double xxl = unit * 8; // 32px
  static const double xxxl = unit * 10; // 40px

  // ===========================
  // SEMANTIC SPACING
  // ===========================

  /// Screen edge padding (horizontal)
  static const double screenPaddingH = md; // 16px

  /// Screen edge padding (vertical)
  static const double screenPaddingV = lg; // 20px

  /// Card padding
  static const double cardPadding = md; // 16px

  /// Card margin
  static const double cardMargin = xs; // 8px

  /// List item padding
  static const double listItemPadding = md; // 16px

  /// Section spacing (between major sections)
  static const double sectionSpacing = xl; // 24px

  /// Element spacing (between related elements)
  static const double elementSpacing = sm; // 12px

  /// Compact spacing (for tight layouts)
  static const double compactSpacing = xs; // 8px

  // ===========================
  // BORDER RADIUS
  // ===========================

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 9999.0; // For pills/circles

  /// Card border radius
  static const double cardRadius = radiusLg; // 16px

  /// Button border radius
  static const double buttonRadius = radiusMd; // 12px

  /// Input field border radius
  static const double inputRadius = radiusMd; // 12px

  /// Dialog border radius
  static const double dialogRadius = radiusXl; // 20px

  /// Bottom sheet border radius
  static const double bottomSheetRadius = radiusXl; // 20px

  // ===========================
  // ICON SIZES
  // ===========================

  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ===========================
  // AVATAR SIZES
  // ===========================

  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;
  static const double avatarXxl = 120.0;

  // ===========================
  // BUTTON HEIGHTS
  // ===========================

  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  // ===========================
  // INPUT HEIGHTS
  // ===========================

  static const double inputHeightSm = 40.0;
  static const double inputHeightMd = 48.0;
  static const double inputHeightLg = 56.0;

  // ===========================
  // DIVIDER THICKNESS
  // ===========================

  static const double dividerThin = 0.5;
  static const double dividerMedium = 1.0;
  static const double dividerThick = 2.0;

  // ===========================
  // ELEVATION (Shadows)
  // ===========================

  static const double elevationNone = 0;
  static const double elevationSm = 2;
  static const double elevationMd = 4;
  static const double elevationLg = 8;
  static const double elevationXl = 12;

  // ===========================
  // EDGE INSETS PRESETS
  // ===========================

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );

  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: AppSpacing.screenPaddingH,
  );

  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(
    vertical: AppSpacing.screenPaddingV,
  );

  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);

  static const EdgeInsets listItemPaddingAll = EdgeInsets.all(listItemPadding);

  static const EdgeInsets listItemPaddingH = EdgeInsets.symmetric(
    horizontal: listItemPadding,
  );

  static const EdgeInsets listItemPaddingV = EdgeInsets.symmetric(
    vertical: listItemPadding,
  );

  // ===========================
  // BORDER RADIUS PRESETS
  // ===========================

  static const BorderRadius borderRadiusXs = BorderRadius.all(
    Radius.circular(radiusXs),
  );
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusXxl = BorderRadius.all(
    Radius.circular(radiusXxl),
  );

  /// Rounded corners for cards
  static const BorderRadius cardBorderRadius = borderRadiusLg;

  /// Rounded corners for buttons
  static const BorderRadius buttonBorderRadius = borderRadiusMd;

  /// Rounded corners for input fields
  static const BorderRadius inputBorderRadius = borderRadiusMd;

  /// Top-rounded corners for bottom sheets
  static const BorderRadius bottomSheetBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(radiusXl),
    topRight: Radius.circular(radiusXl),
  );
}
