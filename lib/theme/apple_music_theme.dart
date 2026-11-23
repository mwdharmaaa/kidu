import 'package:flutter/material.dart';

class AppleMusicTheme {
  // Apple Music Signature Colors
  static const Color accentRed = Color(0xFFFA243C); // Apple Music Red/Pink Accent
  static const Color backgroundBlack = Color(0xFF000000); // True OLED Black
  static const Color cardDark = Color(0xFF1C1C1E); // Elevated surfaces
  static const Color cardLighter = Color(0xFF2C2C2E); // Secondary card surface
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color dividerColor = Color(0x1FFFFFFF);
  static const Color sliderTrackInactive = Color(0xFF38383A);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundBlack,
    primaryColor: accentRed,
    colorScheme: const ColorScheme.dark(
      primary: accentRed,
      secondary: accentRed,
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
      iconTheme: IconThemeData(color: accentRed),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accentRed,
      inactiveTrackColor: sliderTrackInactive,
      thumbColor: textPrimary,
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    ),
  );
}
