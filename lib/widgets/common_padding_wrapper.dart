import 'package:diagnostics_test/widgets/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommonPaddingWrapper extends StatelessWidget {
  /// Responsive EdgeInsets logic
  static EdgeInsets getPadding({
    EdgeInsets? padding,
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (padding != null) return padding;

    return REdgeInsets.only(
      top: top?.h ?? vertical?.h ?? all?.r ?? 0,
      bottom: bottom?.h ?? vertical?.h ?? all?.r ?? 0,
      left: left?.w ?? horizontal?.w ?? all?.r ?? 0,
      right: right?.w ?? horizontal?.w ?? all?.r ?? 0,
    );
  }

  final Widget child;
  final EdgeInsets? padding;
  final double? all;
  final double? horizontal;
  final double? vertical;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const CommonPaddingWrapper({
    super.key,
    required this.child,
    this.padding,
    this.all,
    this.horizontal,
    this.vertical,
    this.top,
    this.bottom,
    this.left,
    this.right,
  }) : assert(
          padding == null ||
              (all == null &&
                  horizontal == null &&
                  vertical == null &&
                  top == null &&
                  bottom == null &&
                  left == null &&
                  right == null),
          'Cannot provide both padding and individual padding values',
        );

  /// `.r` for uniform scaling
  factory CommonPaddingWrapper.all({
    Key? key,
    required Widget child,
    double padding = TSizes.defaultSpace,
  }) {
    return CommonPaddingWrapper(
      key: key,
      all: padding,
      child: child,
    );
  }

  /// `.w` for horizontal and `.h` for vertical
  factory CommonPaddingWrapper.symmetric({
    Key? key,
    required Widget child,
    double horizontal = TSizes.defaultSpace,
    double vertical = TSizes.defaultSpace,
  }) {
    return CommonPaddingWrapper(
      key: key,
      horizontal: horizontal,
      vertical: vertical,
      child: child,
    );
  }

  factory CommonPaddingWrapper.only({
    Key? key,
    required Widget child,
    double top = 0,
    double bottom = 0,
    double left = 0,
    double right = 0,
  }) {
    return CommonPaddingWrapper(
      key: key,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }

  factory CommonPaddingWrapper.horizontal({
    Key? key,
    required Widget child,
    double padding = TSizes.defaultSpace,
  }) {
    return CommonPaddingWrapper.symmetric(
      key: key,
      horizontal: padding,
      vertical: 0,
      child: child,
    );
  }

  factory CommonPaddingWrapper.vertical({
    Key? key,
    required Widget child,
    double padding = TSizes.defaultSpace,
  }) {
    return CommonPaddingWrapper.symmetric(
      key: key,
      horizontal: 0,
      vertical: padding,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = getPadding(
      padding: padding,
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
    );

    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}
