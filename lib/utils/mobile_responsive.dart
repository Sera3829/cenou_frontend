import 'package:flutter/material.dart';

class Breakpoints {
  static const double small = 360.0;
  static const double tablet = 600.0;
}

/// Configuration responsive basée sur les contraintes du LayoutBuilder.
class ResponsiveConfig {
  final bool isSmall;   // largeur < 360
  final bool isMedium;  // largeur >= 360 et < 600
  final bool isTablet;  // largeur >= 600
  final bool isShortScreen;

  ResponsiveConfig({
    required this.isSmall,
    required this.isMedium,
    required this.isTablet,
    required this.isShortScreen,
  });

  factory ResponsiveConfig.fromConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final isSmall = width < Breakpoints.small;
    final isMedium = width >= Breakpoints.small && width < Breakpoints.tablet;
    final isTablet = width >= Breakpoints.tablet;
    final isShortScreen = height < 600;
    return ResponsiveConfig(
      isSmall: isSmall,
      isMedium: isMedium,
      isTablet: isTablet,
      isShortScreen: isShortScreen,
    );
  }

  /// Valeur unique pour toutes les tailles.
  double responsive({
    required double small,
    required double medium,
    required double large,
  }) {
    if (isTablet) return large;
    if (isSmall) return small;
    return medium;
  }

  /// Padding horizontal adapté.
  EdgeInsets get horizontalPadding {
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 40.0);
    return EdgeInsets.symmetric(horizontal: isSmall ? 16.0 : 24.0);
  }

  /// Hauteur utile pour l'espacement vertical.
  double get verticalSpacing => isShortScreen ? 12.0 : 24.0;
}