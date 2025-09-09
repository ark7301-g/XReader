import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 主色�?
  static const Color _primaryColor = Color(0xFF4A90E2);
  static const Color _primaryDarkColor = Color(0xFF357ABD);
  
  // 明亮主题配色
  static const Color _lightBackgroundColor = Color(0xFFFFFFFF);
  static const Color _lightSurfaceColor = Color(0xFFF8F9FA);
  static const Color _lightCardColor = Color(0xFFFFFFFF);
  static const Color _lightTextColor = Color(0xFF222222);
  static const Color _lightSecondaryTextColor = Color(0xFF666666);
  
  // 夜间主题配色
  static const Color _darkBackgroundColor = Color(0xFF000000);
  static const Color _darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color _darkCardColor = Color(0xFF2A2A2A);
  static const Color _darkTextColor = Color(0xFFE5E5E5);
  static const Color _darkSecondaryTextColor = Color(0xFFB0B0B0);

  // 明亮主题
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: _createMaterialColor(_primaryColor),
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: _lightBackgroundColor,
    cardColor: _lightCardColor,
    
    // AppBar主题
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _lightTextColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.notoSans(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: _lightTextColor,
      ),
    ),
    
    // 文本主题
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.notoSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: _lightTextColor,
      ),
      headlineMedium: GoogleFonts.notoSans(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: _lightTextColor,
      ),
      headlineSmall: GoogleFonts.notoSans(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: _lightTextColor,
      ),
      titleLarge: GoogleFonts.notoSans(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: _lightTextColor,
      ),
      titleMedium: GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: _lightTextColor,
      ),
      titleSmall: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _lightTextColor,
      ),
      bodyLarge: GoogleFonts.sourceSerif4(
        fontSize: 18,
        height: 1.6,
        color: _lightTextColor,
      ),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 16,
        color: _lightTextColor,
      ),
      bodySmall: GoogleFonts.notoSans(
        fontSize: 14,
        color: _lightSecondaryTextColor,
      ),
      labelLarge: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _lightTextColor,
      ),
    ),
    
    // 卡片主题
    cardTheme: CardThemeData(
      color: _lightCardColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // 底部导航栏主�?
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightSurfaceColor,
      selectedItemColor: _primaryColor,
      unselectedItemColor: _lightSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // 滑块主题
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      activeTrackColor: _primaryColor,
      inactiveTrackColor: _primaryColor.withOpacity(0.3),
      thumbColor: _primaryColor,
    ),
  );

  // 夜间主题
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: _createMaterialColor(_primaryColor),
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    cardColor: _darkCardColor,
    
    // AppBar主题
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _darkTextColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.notoSans(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: _darkTextColor,
      ),
    ),
    
    // 文本主题
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.notoSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: _darkTextColor,
      ),
      headlineMedium: GoogleFonts.notoSans(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: _darkTextColor,
      ),
      headlineSmall: GoogleFonts.notoSans(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: _darkTextColor,
      ),
      titleLarge: GoogleFonts.notoSans(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: _darkTextColor,
      ),
      titleMedium: GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: _darkTextColor,
      ),
      titleSmall: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _darkTextColor,
      ),
      bodyLarge: GoogleFonts.sourceSerif4(
        fontSize: 18,
        height: 1.6,
        color: _darkTextColor,
      ),
      bodyMedium: GoogleFonts.notoSans(
        fontSize: 16,
        color: _darkTextColor,
      ),
      bodySmall: GoogleFonts.notoSans(
        fontSize: 14,
        color: _darkSecondaryTextColor,
      ),
      labelLarge: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _darkTextColor,
      ),
    ),
    
    // 卡片主题
    cardTheme: CardThemeData(
      color: _darkCardColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // 底部导航栏主�?
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurfaceColor,
      selectedItemColor: _primaryColor,
      unselectedItemColor: _darkSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    // 滑块主题
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      activeTrackColor: _primaryColor,
      inactiveTrackColor: _primaryColor.withOpacity(0.3),
      thumbColor: _primaryColor,
    ),
  );

  // 阅读器专用主题配�?
  static const Map<String, Color> readerColors = {
    // 明亮模式阅读背景
    'lightReaderBackground': Color(0xFFFFFDF5), // 米白色，护眼
    'lightReaderText': Color(0xFF2B2B2B),
    
    // 夜间模式阅读背景
    'darkReaderBackground': Color(0xFF1A1A1A), // 深灰色，护眼
    'darkReaderText': Color(0xFFCCCCCC),
    
    // 棕褐色模式（可选）
    'sepiaReaderBackground': Color(0xFFF4F1EA),
    'sepiaReaderText': Color(0xFF5B4636),
  };
  
  // 创建MaterialColor的辅助方�?
  static MaterialColor _createMaterialColor(Color color) {
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;
    
    final Map<int, Color> swatch = {
      50: Color.fromRGBO(r, g, b, 0.1),
      100: Color.fromRGBO(r, g, b, 0.2),
      200: Color.fromRGBO(r, g, b, 0.3),
      300: Color.fromRGBO(r, g, b, 0.4),
      400: Color.fromRGBO(r, g, b, 0.5),
      500: Color.fromRGBO(r, g, b, 0.6),
      600: Color.fromRGBO(r, g, b, 0.7),
      700: Color.fromRGBO(r, g, b, 0.8),
      800: Color.fromRGBO(r, g, b, 0.9),
      900: Color.fromRGBO(r, g, b, 1.0),
    };
    
    return MaterialColor(color.value, swatch);
  }
}
