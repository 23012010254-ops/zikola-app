import 'package:flutter/material.dart';

class AppTheme {
  // Primary Tailwind Colors used in the React App
  static const Color primaryBlue = Color(0xFF3B82F6); // blue-500
  static const Color primaryBlueDark = Color(0xFF2563EB); // blue-600
  static const Color primaryBlueLight = Color(0xFFEFF6FF); // blue-50
  static const Color blue500 = primaryBlue;
  
  static const Color primaryOrange = Color(0xFFF97316); // orange-500
  static const Color primaryOrangeLight = Color(0xFFFFEDD5); // orange-100
  static const Color orange500 = primaryOrange;
  
  static const Color primaryPurple = Color(0xFFA855F7); // purple-500
  static const Color primaryPurpleLight = Color(0xFFF3E8FF); // purple-100
  static const Color purple500 = primaryPurple;
  
  static const Color primaryGreen = Color(0xFF22C55E); // green-500
  static const Color primaryGreenLight = Color(0xFFDCFCE7); // green-100
  static const Color green500 = primaryGreen;
  
  static const Color primaryPink = Color(0xFFEC4899); // pink-500
  static const Color primaryPinkLight = Color(0xFFFCE7F3); // pink-100

  // 50-600 weight fallbacks
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange300 = Color(0xFFFDBA74);
  static const Color orange400 = Color(0xFFFB923C);
  static const Color orange600 = Color(0xFFEA580C);

  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue600 = Color(0xFF2563EB);

  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky200 = Color(0xFFBAE6FD);
  static const Color sky300 = Color(0xFF7DD3FC);

  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple300 = Color(0xFFD8B4FE);
  static const Color purple400 = Color(0xFFC084FC);
  static const Color purple600 = Color(0xFF9333EA);

  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green300 = Color(0xFF86EFAC);
  static const Color green600 = Color(0xFF16A34A);

  static const Color pink100 = Color(0xFFFCE7F3);
  static const Color pink300 = Color(0xFFF9A8D4);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);

  static const Color yellow300 = Color(0xFFFDE047);
  static const Color yellow400 = Color(0xFFFACC15);
  static const Color yellow500 = Color(0xFFEAB308);
  static const Color yellow600 = Color(0xFFCA8A04);
  // Restored Gray Scale for backwards compatibility
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Typography for backwards compatibility
  static const TextStyle heading1 = TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Nunito');
  static const TextStyle heading2 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Nunito');
  static const TextStyle heading3 = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Nunito');
  static const TextStyle bodyText = TextStyle(fontSize: 14, fontFamily: 'Nunito');
  static const TextStyle subtitle = TextStyle(fontSize: 16, fontFamily: 'Nunito');
  static const TextStyle buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Nunito');
  static const TextStyle caption = TextStyle(fontSize: 12, fontFamily: 'Nunito');
  
  static const Color cyan500 = Color(0xFF06B6D4);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color indigo500 = Color(0xFF6366F1);

  // Background Colors
  static const Color bgLight = Color(0xFFF9FAFB); // gray-50
  static const Color bgWhite = Colors.white;

  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-500
  static const Color textMuted = Color(0xFF9CA3AF); // gray-400

  // Rarity Colors
  static const Color rarityCommon = Color(0xFF9CA3AF);
  static const Color rarityRare = Color(0xFF3B82F6);
  static const Color rarityEpic = Color(0xFFA855F7);
  static const Color rarityLegendary = Color(0xFFF59E0B);

  static Color getRarityColor(String rarity) {
    switch (rarity) {
      case 'common': return rarityCommon;
      case 'rare': return rarityRare;
      case 'epic': return rarityEpic;
      case 'legendary': return rarityLegendary;
      default: return rarityCommon;
    }
  }

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        surface: bgLight,
      ),
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryOrange.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: bgWhite,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
