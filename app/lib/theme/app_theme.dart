import 'package:flutter/material.dart';

/// 航班打卡主题色 —— 对齐旧 web 前端的设计 token
///
/// 这里只保留 light/dark 共同的 brand 色 + 排行榜用色。
/// 所有 light/dark 各自的 surface / text / semantic token 都走 [AppPalette]。
class AppColors {
  // ── 主色 (light/dark 共用) ──
  static const primary = Color(0xFF3B82F6);
  static const primaryLight = Color(0xFF60A5FA);
  static const primaryDark = Color(0xFF2563EB);
  static const accent = Color(0xFF93C5FD);
  static const accentLight = Color(0xFFDBEAFE);

  // ── 状态色 (light/dark 共用 — 中间饱和度,作为 icon/raw 用) ──
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // ── 排行榜用色 (light/dark 共用 — 色彩本身在不同背景下都足够亮) ──
  static const lbFirst = Color(0xFF93C5FD);
  static const lbSecond = Color(0xFFBFDBFE);
  static const lbThird = Color(0xFFC4B5FD);
  static const lbFourth = Color(0xFFA5B4FC);
  static const lbFifth = Color(0xFFBAE6FD);
}

/// Light 主题的 palette token 原始值。实际渲染走 [AppPalette.light]。
class _LightPaletteTokens {
  // ── Surface ──
  static const bg = Color(0xFFF0F4F8);            // slate-50
  static const card = Color(0xFFFFFFFF);           // white
  static const surfaceMuted = Color(0xFFF1F5F9);   // slate-100 — tabs/次按钮 bg
  static const border = Color(0xFFE2E8F0);         // slate-200

  // ── Text ──
  static const text = Color(0xFF1E293B);           // slate-800
  static const textSecondary = Color(0xFF64748B);  // slate-500
  static const textLight = Color(0xFF94A3B8);      // slate-400

  // ── Brand ──
  static const primaryBg = Color(0xFFEFF6FF);      // blue-50

  // ── Semantic: success (green) ──
  static const successBg = Color(0xFFDCFCE7);      // green-100
  static const successText = Color(0xFF15803D);    // green-700

  // ── Semantic: warning (amber) ──
  static const warningBg = Color(0xFFFEF3C7);      // amber-100
  static const warningText = Color(0xFF92400E);    // amber-800

  // ── Semantic: danger (red) ──
  static const dangerBg = Color(0xFFFECACA);       // red-100
  static const dangerText = Color(0xFFB91C1C);     // red-700

  // ── Semantic: info (purple) ──
  static const infoBg = Color(0xFFF3E8FF);         // purple-100

  // ── Dock ──
  static const dockBg = Color(0xFFF1F5F9);         // slate-100(用时再 withValues 0.72)
  static const dockBorder = Color.fromARGB(0x80, 0xFF, 0xFF, 0xFF); // white 50%
}

/// Dark 主题的 palette token 原始值。实际渲染走 [AppPalette.dark]。
class _DarkPaletteTokens {
  // ── Surface ──
  static const bg = Color(0xFF0F172A);             // slate-900
  static const card = Color(0xFF1E293B);           // slate-800
  static const surfaceMuted = Color(0xFF334155);   // slate-700 — tabs/次按钮 bg(比 card 浅一档)
  static const border = Color(0xFF334155);         // slate-700

  // ── Text ──
  static const text = Color(0xFFF1F5F9);           // slate-100
  static const textSecondary = Color(0xFFCBD5E1);  // slate-300
  static const textLight = Color(0xFF94A3B8);      // slate-400

  // ── Brand ──
  static const primaryBg = Color(0xFF1E3A8A);      // blue-800

  // ── Semantic: success (green) ──
  static const successBg = Color(0xFF14532D);      // green-900
  static const successText = Color(0xFF4ADE80);    // green-400

  // ── Semantic: warning (amber) ──
  static const warningBg = Color(0xFF78350F);      // amber-900
  static const warningText = Color(0xFFFCD34D);    // amber-300

  // ── Semantic: danger (red) ──
  static const dangerBg = Color(0xFF7F1D1D);       // red-900
  static const dangerText = Color(0xFFFCA5A5);     // red-300

  // ── Semantic: info (purple) ──
  static const infoBg = Color(0xFF6B21A8);         // purple-800

  // ── Dock ──
  static const dockBg = Color(0xFF475569);         // slate-600(用时再 withValues 0.72)
  static const dockBorder = Color.fromARGB(0x14, 0xFF, 0xFF, 0xFF); // white 8%
}

/// BuildContext 扩展 —— `context.palette.bg` / `context.palette.text` 等。
/// 优先读 ThemeExtension(跟随主题切换),fallback 到默认 AppPalette.light。
extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
///
/// 使用方法:
/// ```dart
/// final palette = Theme.of(context).extension(AppPalette);
/// Container(color: palette.bg, child: ...)
/// ```
class AppPalette extends ThemeExtension<AppPalette> {
  // ── Surface ──
  final Color bg;
  final Color card;
  final Color surfaceMuted;   // tabs/次按钮 bg、排行榜 >5 默认色
  final Color border;

  // ── Text ──
  final Color text;
  final Color textSecondary;
  final Color textLight;

  // ── Brand ──
  final Color primaryBg;

  // ── Semantic: success ──
  final Color successBg;
  final Color successText;

  // ── Semantic: warning ──
  final Color warningBg;
  final Color warningText;

  // ── Semantic: danger ──
  final Color dangerBg;
  final Color dangerText;

  // ── Semantic: info ──
  final Color infoBg;

  // ── Dock ──
  final Color dockBg;          // 完整色,用时再 withValues 0.72
  final Color dockBorder;      // 已带 alpha

  const AppPalette({
    required this.bg,
    required this.card,
    required this.surfaceMuted,
    required this.border,
    required this.text,
    required this.textSecondary,
    required this.textLight,
    required this.primaryBg,
    required this.successBg,
    required this.successText,
    required this.warningBg,
    required this.warningText,
    required this.dangerBg,
    required this.dangerText,
    required this.infoBg,
    required this.dockBg,
    required this.dockBorder,
  });

  /// 默认 light 主题色
  static const light = AppPalette(
    bg: _LightPaletteTokens.bg,
    card: _LightPaletteTokens.card,
    surfaceMuted: _LightPaletteTokens.surfaceMuted,
    border: _LightPaletteTokens.border,
    text: _LightPaletteTokens.text,
    textSecondary: _LightPaletteTokens.textSecondary,
    textLight: _LightPaletteTokens.textLight,
    primaryBg: _LightPaletteTokens.primaryBg,
    successBg: _LightPaletteTokens.successBg,
    successText: _LightPaletteTokens.successText,
    warningBg: _LightPaletteTokens.warningBg,
    warningText: _LightPaletteTokens.warningText,
    dangerBg: _LightPaletteTokens.dangerBg,
    dangerText: _LightPaletteTokens.dangerText,
    infoBg: _LightPaletteTokens.infoBg,
    dockBg: _LightPaletteTokens.dockBg,
    dockBorder: _LightPaletteTokens.dockBorder,
  );

  /// dark 主题色
  static const dark = AppPalette(
    bg: _DarkPaletteTokens.bg,
    card: _DarkPaletteTokens.card,
    surfaceMuted: _DarkPaletteTokens.surfaceMuted,
    border: _DarkPaletteTokens.border,
    text: _DarkPaletteTokens.text,
    textSecondary: _DarkPaletteTokens.textSecondary,
    textLight: _DarkPaletteTokens.textLight,
    primaryBg: _DarkPaletteTokens.primaryBg,
    successBg: _DarkPaletteTokens.successBg,
    successText: _DarkPaletteTokens.successText,
    warningBg: _DarkPaletteTokens.warningBg,
    warningText: _DarkPaletteTokens.warningText,
    dangerBg: _DarkPaletteTokens.dangerBg,
    dangerText: _DarkPaletteTokens.dangerText,
    infoBg: _DarkPaletteTokens.infoBg,
    dockBg: _DarkPaletteTokens.dockBg,
    dockBorder: _DarkPaletteTokens.dockBorder,
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? card,
    Color? surfaceMuted,
    Color? border,
    Color? text,
    Color? textSecondary,
    Color? textLight,
    Color? primaryBg,
    Color? successBg,
    Color? successText,
    Color? warningBg,
    Color? warningText,
    Color? dangerBg,
    Color? dangerText,
    Color? infoBg,
    Color? dockBg,
    Color? dockBorder,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textLight: textLight ?? this.textLight,
      primaryBg: primaryBg ?? this.primaryBg,
      successBg: successBg ?? this.successBg,
      successText: successText ?? this.successText,
      warningBg: warningBg ?? this.warningBg,
      warningText: warningText ?? this.warningText,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerText: dangerText ?? this.dangerText,
      infoBg: infoBg ?? this.infoBg,
      dockBg: dockBg ?? this.dockBg,
      dockBorder: dockBorder ?? this.dockBorder,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      primaryBg: Color.lerp(primaryBg, other.primaryBg, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      dockBg: Color.lerp(dockBg, other.dockBg, t)!,
      dockBorder: Color.lerp(dockBorder, other.dockBorder, t)!,
    );
  }
}

/// 主题里的尺寸用移动端基准值写死（ThemeData 在 GetMaterialApp.theme
/// 时构造，那时还没有 BuildContext）。需要响应式的样式请在 widget 里用
/// `context.r.xxx` 覆盖（这些 token 仍会被 widget 级样式覆盖）。
class _Baseline {
  // 移动端基准值，对应 iPhone 14 (390x844)
  static const double gap = 16.0;
  static const double gapSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double textMd = 15.0;
  static const double textLg = 17.0;
  static const double buttonH = 52.0;
}

class AppTheme {
  static ThemeData light() => _build(brightness: Brightness.light, palette: AppPalette.light);
  static ThemeData dark() => _build(brightness: Brightness.dark, palette: AppPalette.dark);

  static ThemeData _build({required Brightness brightness, required AppPalette palette}) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: palette.card,
        error: AppColors.danger,
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
      fontFamily: 'PingFang SC',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: palette.text,
          fontSize: _Baseline.textLg,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: palette.text),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Baseline.radiusLg),
        ),
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _Baseline.gap,
          vertical: _Baseline.gapSm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          borderSide: BorderSide(color: palette.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          borderSide: BorderSide(color: palette.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: palette.textLight),
        labelStyle: TextStyle(color: palette.textSecondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(_Baseline.buttonH),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: _Baseline.textMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Baseline.radiusMd),
          ),
        ),
      ),
    );
  }
}