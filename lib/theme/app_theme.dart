import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════
// SplitSpot Premium Design System — Light Green & White
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFFF6FAF7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // ── Primary Green Palette ────────────────────────────────────
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryDeep = Color(0xFF2E7D32);
  static const Color primarySoft = Color(0xFFE8F5E9);
  static const Color primarySofter = Color(0xFFC8E6C9);

  // ── Accent ───────────────────────────────────────────────────
  static const Color accent = Color(0xFF00C853);

  // ── Text Colors ──────────────────────────────────────────────
  static const Color textDark = Color(0xFF1A2E1D);
  static const Color textBody = Color(0xFF37474F);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color textHint = Color(0xFFB0BEC5);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA726);
  static const Color danger = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // ── Border / Divider ─────────────────────────────────────────
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient primarySoft = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient button = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );

  static const LinearGradient header = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A), Color(0xFF81C784)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient danger = LinearGradient(
    colors: [Color(0xFFEF5350), Color(0xFFE53935)],
    begin: Alignment.centerLeft, end: Alignment.centerRight,
  );
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> get card => [
    BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get cardHover => [
    BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get button => [
    BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: -2),
  ];
  static List<BoxShadow> get soft => [
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
  ];
}

class AppDecorations {
  AppDecorations._();

  static BoxDecoration get card => BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(18),
    boxShadow: AppShadows.card,
  );

  static InputDecoration input({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.scaffoldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: hasError ? AppColors.danger : AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: hasError ? AppColors.danger : AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
    );
  }
}

class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary, secondary: AppColors.accent,
        surface: AppColors.white, error: AppColors.danger,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white, foregroundColor: AppColors.textDark,
        elevation: 0, surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.scaffoldBg,
        hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 2)),
      ),
      cardTheme: CardThemeData(color: AppColors.cardBg, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      snackBarTheme: SnackBarThemeData(backgroundColor: AppColors.textDark, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
        contentTextStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.textBody)),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary, linearTrackColor: AppColors.primarySofter),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    );
  }
}

/// Premium gradient button
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double borderRadius;
  final Gradient? gradient;
  const GradientButton({super.key, this.onPressed, required this.child, this.isLoading = false, this.borderRadius = 14, this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: onPressed != null ? (gradient ?? AppGradients.button) : null,
        color: onPressed == null ? AppColors.textHint : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed != null ? AppShadows.button : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: isLoading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2.5))
              : child),
          ),
        ),
      ),
    );
  }
}
