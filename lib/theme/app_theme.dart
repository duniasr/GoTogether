import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A6BFF);
  static const Color primaryDark = Color(0xFF0D4FCC);
  static const Color primaryLight = Color(0xFFE8F0FF);

  static const Color accent = Color(0xFFFF7A1A);
  static const Color accentLight = Color(0xFFFFF0E6);

  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEEF2F8);

  static const Color textPrimary = Color(0xFF0F1928);
  static const Color textSecondary = Color(0xFF5A6B80);
  static const Color textHint = Color(0xFFABB8CC);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Map<String, Color> categoryColors = {
    'Fiesta': Color(0xFFEC4899),
    'Deporte': Color(0xFF10B981),
    'Cultura': Color(0xFF8B5CF6),
    'Gastronomía': Color(0xFFF59E0B),
    'Aire libre': Color(0xFF06B6D4),
    'Naturaleza': Color(0xFF06B6D4),
    'Estudio': Color(0xFF1A6BFF),
    'Ocio': Color(0xFFFF7A1A),
    'Voluntariado': Color(0xFF22C55E),
    'Viajes': Color(0xFF0EA5E9),
    'Videojuegos': Color(0xFF7C3AED),
    'Música': Color(0xFFE11D48),
    'Networking': Color(0xFF334155),
    'Otros': Color(0xFF64748B),
  };
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get button => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.30),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(textStyle: AppTextStyles.displayLarge),
        displayMedium: GoogleFonts.inter(textStyle: AppTextStyles.displayMedium),
        headlineMedium:
            GoogleFonts.inter(textStyle: AppTextStyles.headlineMedium),
        headlineSmall: GoogleFonts.inter(textStyle: AppTextStyles.headlineSmall),
        bodyLarge: GoogleFonts.inter(textStyle: AppTextStyles.bodyLarge),
        bodyMedium: GoogleFonts.inter(textStyle: AppTextStyles.bodyMedium),
        labelLarge: GoogleFonts.inter(textStyle: AppTextStyles.labelLarge),
        labelSmall: GoogleFonts.inter(textStyle: AppTextStyles.labelSmall),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x14000000),
        titleTextStyle: GoogleFonts.inter(textStyle: AppTextStyles.headlineSmall),
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(textStyle: AppTextStyles.button),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(textStyle: AppTextStyles.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(textStyle: AppTextStyles.button),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(textStyle: AppTextStyles.bodyMedium),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.inter(textStyle: AppTextStyles.labelLarge),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEBEFF5),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent.withOpacity(0.35);
          }
          return null;
        }),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    if (onTap == null) {
      return container;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: container,
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: onPressed != null ? AppShadows.button : const [],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      textStyle: AppTextStyles.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  final String category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[category] ?? AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          category,
          style: GoogleFonts.inter(
            textStyle: AppTextStyles.labelSmall.copyWith(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
