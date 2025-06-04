import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSizes {
  /// Sizing inspired by Tailwind CSS
  static const double zero = 0;

  static const double px = 1;

  static const double px1 = 2;

  static const double xs = 4.0;

  static const double xs1 = 6.0;

  static const double s = 8.0;

  static const double s1 = 10.0;

  static const double m = 12.0;

  static const double m1 = 14.0;

  static const double l = 16.0;

  static const double l1 = 20.0;

  static const double l2 = 24.0;

  static const double l3 = 28.0;

  static const double xl = 32.0;

  static const double xl1 = 40.0;

  static const double xl2 = 48.0;

  static const double xl3 = 56.0;

  static const double xxl = 64.0;

  static const double xxl1 = 80.0;

  static const double xxl2 = 96.0;

  static const double xxl3 = 112.0;

  static const double x = 128.0;

  static const double x1 = 144.0;

  static const double x2 = 160.0;

  static const double x3 = 176.0;

  static const double x5 = 208.0;

  /// Spacers for height and width
  static Widget verticalHeight(double value) => SizedBox(height: value.r);

  static Widget horizontalWidth(double value) => SizedBox(width: value.r);

  static double resSize(double size) => size.r;
}

class TSizes {
  TSizes._();

  // Padding and margin sizes
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double m = 12.0;
  static const double m1 = 14.0;
  static const double md = 16.0;
  static const double l1 = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  // Icon Sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // Font Sizes
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;

  // Button Sizes
  static const double buttonHeight = 48.0;
  static const double buttonRadius = 12.0;
  static const double buttonWidth = 120.0;

  // AppBar Height
  static const double appBarHeight = 56.0;

  // Image Sizes
  static const double imageThumbSize = 80.0;

  // Default spacing between sections
  static const double defaultSpace = 24.0;
  static const double spaceBtwItems = 16.0;
  static const double spaceBtwSections = 32.0;

  // Border Radius
  static const double borderRadiusSm = 4.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 12.0;

  // Divider Height
  static const double dividerHeight = 1.0;

  // Product Item Dimension
  static const double productImageSize = 120.0;
  static const double productImageRadius = 16.0;
  static const double productImageHeight = 160.0;

  // Input Field
  static const double inputFieldRadius = 12.0;
  static const double spaceBtwInputFields = 16.0;

  // Card Sizes
  static const double cardRadiusLg = 16.0;
  static const double cardRadiusMd = 12.0;
  static const double cardRadiusSm = 10.0;
  static const double cardRadiusXs = 6.0;
  static const double cardElevation = 2.0;

  // Image Curosel Height
  static const double imageCuroselHeight = 200.0;

  // Loading Indicator Size
  static const double loadingIndicatorSize = 36.0;

  // Grid View Spacing
  static const double gridViewSpacing = 16.0;

  // Zero
  static const double zero = 0.0;

  // Spacers for height and width
  static Widget verticalHeight(double value) => SizedBox(height: value.r);
  static Widget horizontalWidth(double value) => SizedBox(width: value.r);
}
