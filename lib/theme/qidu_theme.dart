import 'package:flutter/material.dart';

class QiduTheme {
  // Qidu Signature Audio Colors
  static const Color accentColor = Color(0xFFFA243C); // Vibrant Studio Red/Pink
  static const Color backgroundBlack = Color(0xFF000000); // True OLED Deep Black
  static const Color cardDark = Color(0xFF1C1C1E); // Elevated surfaces
  static const Color cardLighter = Color(0xFF2C2C2E); // Secondary card surface
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color dividerColor = Color(0x1FFFFFFF);
  static const Color sliderTrackInactive = Color(0xFF38383A);
  static const Color hiResGold = Color(0xFFFFD60A); // Hi-Res Lossless Gold Badge
  static const Color losslessBadgeBg = Color(0x26FFFFFF);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundBlack,
    primaryColor: accentColor,
    colorScheme: const ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      surface: cardDark,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: accentColor),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentColor,
      inactiveTrackColor: sliderTrackInactive,
      thumbColor: textPrimary,
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    ),
  );
}
