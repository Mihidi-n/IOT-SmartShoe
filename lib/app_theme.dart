import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const deepNavy = Color(0xFF021024);
  static const navy = Color(0xFF052659);
  static const blue = Color(0xFF5483B3);
  static const softBlue = Color(0xFF7DA0CA);
  static const lightBlue = Color(0xFFC1E8FF);

  static const background = Color(0xFFF4F9FF);
  static const white = Colors.white;
  static const textDark = Color(0xFF021024);
  static const textMuted = Color(0xFF5E6E82);
  static const softGrey = Color(0xFFECECEC);

  static const orangeAccent = Color(0xFFFFB85C);
}
class AppGradients {
  static const main = LinearGradient(
    colors: [
      AppColors.deepNavy,
      AppColors.navy,
      AppColors.blue,
      AppColors.softBlue,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const header = LinearGradient(
    colors: [
      AppColors.deepNavy,
      AppColors.navy,
      AppColors.blue,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardBlue = LinearGradient(
    colors: [
      AppColors.navy,
      AppColors.blue,
      AppColors.softBlue,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const lightCard = LinearGradient(
    colors: [
      AppColors.softBlue,
      AppColors.lightBlue,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
      ),
    );
  }
}

BoxShadow appShadow() {
  return BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 18,
    offset: const Offset(0, 8),
  );
}