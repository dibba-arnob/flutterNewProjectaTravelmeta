import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final bg      = isLight ? AppColors.bgLight     : AppColors.bgDark;
    final surface = isLight ? AppColors.surfaceLight : AppColors.surfaceDark;
    final text    = isLight ? AppColors.textLight    : AppColors.textDark;
    final border  = isLight ? AppColors.borderLight  : AppColors.borderDark;
    final accent  = AppColors.secondary;
    final muted   = AppColors.textMuted;

    // helpers
    BorderRadius br(double r) => BorderRadius.circular(r);
    OutlineInputBorder ib(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: br(12), borderSide: BorderSide(color: c, width: w),
    );
    WidgetStateProperty<T> ws<T>(T selected, T fallback) =>
        WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? selected : fallback,
        );

    return ThemeData(
      useMaterial3:            true,
      brightness:              brightness,
      scaffoldBackgroundColor: bg,
      fontFamily:              'Inter',
      textTheme:               _textTheme(text, muted),

      colorScheme: ColorScheme(
        brightness:           brightness,
        primary:              AppColors.primary,
        onPrimary:            Colors.white,
        primaryContainer:     isLight ? const Color(0xFFE0F2FE) : const Color(0xFF0C2240),
        onPrimaryContainer:   isLight ? AppColors.primary : accent,
        secondary:            accent,
        onSecondary:          Colors.white,
        secondaryContainer:   isLight ? const Color(0xFFCFF7FE) : const Color(0xFF0E3A4A),
        onSecondaryContainer: isLight ? const Color(0xFF0C4A6E) : accent,
        tertiary:             AppColors.accent,
        onTertiary:           Colors.white,
        tertiaryContainer:    isLight ? const Color(0xFFE0FBFF) : const Color(0xFF0A2E38),
        onTertiaryContainer:  isLight ? const Color(0xFF164E63) : const Color(0xFF67E8F9),
        error:                AppColors.error,
        onError:              Colors.white,
        errorContainer:       AppColors.error.withValues(alpha: 0.1),
        onErrorContainer:     const Color(0xFF7F1D1D),
        surface:              surface,
        onSurface:            text,
        onSurfaceVariant:     muted,
        outline:              border,
        outlineVariant:       border.withValues(alpha: 0.5),
        shadow:               AppColors.shadow,
        scrim:                Colors.black54,
        inverseSurface:       isLight ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        onInverseSurface:     isLight ? Colors.white : AppColors.textLight,
        inversePrimary:       accent,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:        bg,
        foregroundColor:        text,
        elevation:              0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor:       Colors.transparent,
        centerTitle:            false,
        titleTextStyle:         AppTextStyles.h5.copyWith(color: text),
        iconTheme:              IconThemeData(color: text, size: 24),
        systemOverlayStyle:     isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:  bg.withValues(alpha: 0.9),
        elevation:        0,
        indicatorColor:   accent.withValues(alpha: 0.12),
        indicatorShape:   RoundedRectangleBorder(borderRadius: br(12)),
        labelTextStyle:   ws(
          AppTextStyles.labelSm.copyWith(color: accent, fontWeight: FontWeight.w600),
          AppTextStyles.labelSm.copyWith(color: muted),
        ),
        iconTheme: ws(
          IconThemeData(color: accent, size: 24),
          IconThemeData(color: muted,  size: 24),
        ),
      ),

      cardTheme: CardThemeData(
        color:        surface,
        elevation:    0,
        margin:       EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: br(16),
          side: BorderSide(color: border, width: 0.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation:       0,
          shadowColor:     Colors.transparent,
          textStyle:       AppTextStyles.btn,
          minimumSize:     const Size(double.infinity, 52),
          shape:           RoundedRectangleBorder(borderRadius: br(12)),
          padding:         const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:       AppTextStyles.btn,
          minimumSize:     const Size(double.infinity, 52),
          side:            const BorderSide(color: AppColors.primary, width: 1.5),
          shape:           RoundedRectangleBorder(borderRadius: br(12)),
          padding:         const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle:       AppTextStyles.btn,
          shape:           RoundedRectangleBorder(borderRadius: br(12)),
          padding:         const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:             true,
        fillColor:          surface,
        contentPadding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:        const BoxConstraints(minHeight: 52),
        border:             ib(border),
        enabledBorder:      ib(border),
        focusedBorder:      ib(accent, 1.5),
        errorBorder:        ib(AppColors.error),
        focusedErrorBorder: ib(AppColors.error, 1.5),
        labelStyle:         AppTextStyles.body.copyWith(color: muted),
        hintStyle:          AppTextStyles.body.copyWith(color: muted),
        floatingLabelStyle: AppTextStyles.label.copyWith(color: accent),
        prefixIconColor:    muted,
        suffixIconColor:    muted,
        errorStyle:         AppTextStyles.caption.copyWith(color: AppColors.error),
      ),

      dividerTheme:  DividerThemeData(color: border, thickness: 0.5, space: 0),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle:      AppTextStyles.label.copyWith(color: text),
        selectedColor:   accent.withValues(alpha: 0.15),
        side:            BorderSide(color: border),
        shape:           RoundedRectangleBorder(borderRadius: br(999)),
        padding:         const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelPadding:    const EdgeInsets.symmetric(horizontal: 4),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor:           accent,
        unselectedLabelColor: muted,
        labelStyle:           AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.label,
        indicator:            UnderlineTabIndicator(
          borderSide:   BorderSide(color: accent, width: 2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor:  border,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:      surface,
        modalBackgroundColor: surface,
        surfaceTintColor:     Colors.transparent,
        elevation:            0,
        showDragHandle:       true,
        dragHandleColor:      border,
        dragHandleSize:       const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:  surface,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        shape:            RoundedRectangleBorder(borderRadius: br(20)),
        titleTextStyle:   AppTextStyles.h5.copyWith(color: text),
        contentTextStyle: AppTextStyles.body.copyWith(color: muted),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  isLight ? AppColors.primary : const Color(0xFF1E293B),
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        shape:            RoundedRectangleBorder(borderRadius: br(12)),
        behavior:         SnackBarBehavior.floating,
        insetPadding:     const EdgeInsets.all(16),
        elevation:        0,
      ),

      listTileTheme: ListTileThemeData(
        tileColor:          Colors.transparent,
        contentPadding:     const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle:     AppTextStyles.body.copyWith(color: text),
        subtitleTextStyle:  AppTextStyles.bodySm.copyWith(color: muted),
        iconColor:          muted,
        leadingAndTrailingTextStyle: AppTextStyles.label.copyWith(color: muted),
        minVerticalPadding: 12,
      ),

      switchTheme: SwitchThemeData(
        thumbColor:        ws(Colors.white, border),
        trackColor:        ws(accent, surface),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor:  ws(accent, Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side:       BorderSide(color: border, width: 1.5),
        shape:      RoundedRectangleBorder(borderRadius: br(6)),
      ),

      radioTheme:  RadioThemeData(fillColor: ws(accent, muted)),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:              accent,
        linearTrackColor:   isLight ? const Color(0xFFE0F2FE) : const Color(0xFF0C2240),
        circularTrackColor: Colors.transparent,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor:    accent,
        foregroundColor:    Colors.white,
        elevation:          0,
        highlightElevation: 0,
        shape:              RoundedRectangleBorder(borderRadius: br(12)),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor:   accent,
        inactiveTrackColor: isLight ? const Color(0xFFE0F2FE) : const Color(0xFF0C2240),
        thumbColor:         accent,
        overlayColor:       accent.withValues(alpha: 0.1),
        trackHeight:        4,
      ),

      iconTheme:        IconThemeData(color: text,         size: 24),
      primaryIconTheme: const IconThemeData(color: Colors.white, size: 24),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(Color text, Color muted) => TextTheme(
    displayLarge:   AppTextStyles.h1.copyWith(color: text),
    displayMedium:  AppTextStyles.h2.copyWith(color: text),
    displaySmall:   AppTextStyles.h3.copyWith(color: text),
    headlineLarge:  AppTextStyles.h3.copyWith(color: text),
    headlineMedium: AppTextStyles.h4.copyWith(color: text),
    headlineSmall:  AppTextStyles.h5.copyWith(color: text),
    titleLarge:     AppTextStyles.h5.copyWith(color: text),
    titleMedium:    AppTextStyles.h6.copyWith(color: text),
    titleSmall:     AppTextStyles.labelLg.copyWith(color: text),
    bodyLarge:      AppTextStyles.bodyLg.copyWith(color: text),
    bodyMedium:     AppTextStyles.body.copyWith(color: text),
    bodySmall:      AppTextStyles.bodySm.copyWith(color: muted),
    labelLarge:     AppTextStyles.label.copyWith(color: text),
    labelMedium:    AppTextStyles.label.copyWith(color: muted),
    labelSmall:     AppTextStyles.labelSm.copyWith(color: muted),
  );
}