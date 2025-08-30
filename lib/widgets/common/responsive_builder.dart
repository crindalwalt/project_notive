import 'package:flutter/material.dart';
import '../../core/utils/helpers.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (DeviceHelper.isDesktop(constraints.maxWidth)) {
          return desktop ?? tablet ?? mobile;
        } else if (DeviceHelper.isTablet(constraints.maxWidth)) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
