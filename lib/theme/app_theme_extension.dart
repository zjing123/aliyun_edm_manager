import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color filterChipBackground;
  final Color filterChipSelected;
  final Color filterChipBorder;
  final double filterChipRadius;
  final double cardRadius;
  final Color appBarBackground;
  final Color appBarForeground;
  final TextStyle appBarTitleStyle;
  // 新增按钮相关字段
  final Color elevatedButtonBackground;
  final Color elevatedButtonForeground;
  final Color elevatedButtonIconColor;
  final double elevatedButtonRadius;

  const AppThemeExtension({
    required this.filterChipBackground,
    required this.filterChipSelected,
    required this.filterChipBorder,
    required this.filterChipRadius,
    required this.cardRadius,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.appBarTitleStyle,
    required this.elevatedButtonBackground,
    required this.elevatedButtonForeground,
    required this.elevatedButtonIconColor,
    required this.elevatedButtonRadius,
  });

  // 浅色主题
  static final AppThemeExtension light = AppThemeExtension(
    filterChipBackground: Colors.white,
    filterChipSelected: const Color(0xFFBBDEFB),
    filterChipBorder: const Color(0xFFE0E0E0),
    filterChipRadius: 8,
    cardRadius: 12,
    appBarBackground: Colors.white,
    appBarForeground: Colors.black87,
    appBarTitleStyle: const TextStyle(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    elevatedButtonBackground: Colors.blue,
    elevatedButtonForeground: Colors.white,
    elevatedButtonIconColor: Colors.white,
    elevatedButtonRadius: 8,
  );

  // 深色主题（可根据需要调整）
  static final AppThemeExtension dark = AppThemeExtension(
    filterChipBackground: const Color(0xFF222222),
    filterChipSelected: const Color(0xFF1976D2),
    filterChipBorder: const Color(0xFF444444),
    filterChipRadius: 8,
    cardRadius: 12,
    appBarBackground: const Color(0xFF222222),
    appBarForeground: Colors.white,
    appBarTitleStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    elevatedButtonBackground: Color(0xFF1976D2),
    elevatedButtonForeground: Colors.white,
    elevatedButtonIconColor: Colors.white,
    elevatedButtonRadius: 8,
  );

  @override
  AppThemeExtension copyWith({
    Color? filterChipBackground,
    Color? filterChipSelected,
    Color? filterChipBorder,
    double? filterChipRadius,
    double? cardRadius,
    Color? appBarBackground,
    Color? appBarForeground,
    TextStyle? appBarTitleStyle,
    Color? elevatedButtonBackground,
    Color? elevatedButtonForeground,
    Color? elevatedButtonIconColor,
    double? elevatedButtonRadius,
  }) {
    return AppThemeExtension(
      filterChipBackground: filterChipBackground ?? this.filterChipBackground,
      filterChipSelected: filterChipSelected ?? this.filterChipSelected,
      filterChipBorder: filterChipBorder ?? this.filterChipBorder,
      filterChipRadius: filterChipRadius ?? this.filterChipRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      appBarBackground: appBarBackground ?? this.appBarBackground,
      appBarForeground: appBarForeground ?? this.appBarForeground,
      appBarTitleStyle: appBarTitleStyle ?? this.appBarTitleStyle,
      elevatedButtonBackground: elevatedButtonBackground ?? this.elevatedButtonBackground,
      elevatedButtonForeground: elevatedButtonForeground ?? this.elevatedButtonForeground,
      elevatedButtonIconColor: elevatedButtonIconColor ?? this.elevatedButtonIconColor,
      elevatedButtonRadius: elevatedButtonRadius ?? this.elevatedButtonRadius,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      filterChipBackground: Color.lerp(filterChipBackground, other.filterChipBackground, t)!,
      filterChipSelected: Color.lerp(filterChipSelected, other.filterChipSelected, t)!,
      filterChipBorder: Color.lerp(filterChipBorder, other.filterChipBorder, t)!,
      filterChipRadius: filterChipRadius + (other.filterChipRadius - filterChipRadius) * t,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      appBarBackground: Color.lerp(appBarBackground, other.appBarBackground, t)!,
      appBarForeground: Color.lerp(appBarForeground, other.appBarForeground, t)!,
      appBarTitleStyle: TextStyle.lerp(appBarTitleStyle, other.appBarTitleStyle, t)!,
      elevatedButtonBackground: Color.lerp(elevatedButtonBackground, other.elevatedButtonBackground, t)!,
      elevatedButtonForeground: Color.lerp(elevatedButtonForeground, other.elevatedButtonForeground, t)!,
      elevatedButtonIconColor: Color.lerp(elevatedButtonIconColor, other.elevatedButtonIconColor, t)!,
      elevatedButtonRadius: elevatedButtonRadius + (other.elevatedButtonRadius - elevatedButtonRadius) * t,
    );
  }
} 