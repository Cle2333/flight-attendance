import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 响应式工具 -- 所有尺寸都用"屏幕宽度的分数"推导,clamp 在合理范围。
///
/// 用法:
/// ```dart
/// // 原来
/// EdgeInsets.all(16)              →  EdgeInsets.all(context.r.gapMd)
/// SizedBox(height: 12)            →  SizedBox(height: context.r.gapSm)
/// fontSize: 14                    →  fontSize: context.r.textBase
/// width: 30, height: 30           →  SizedBox(width: context.r.touchTarget, height: context.r.touchTarget)
/// ```
///
/// 设计原则:
/// - **基准** = 390px(iPhone 14 / 标准手机)
/// - **下限** = 0.85(保证 320px 小屏不爆)
/// - **上限** = 1.6(4K 显示器不失控)
/// - **gap / radius / text 三套独立缩放**,避免文字和间距绑死
/// - **图标 / 头像** 有最小尺寸(不会缩到看不见)
class Responsive {
  final BuildContext context;
  const Responsive(this.context);

  // ── 屏幕尺寸 ─────────────────────────────────────────────
  Size get size => MediaQuery.of(context).size;
  double get width => size.width;
  double get height => size.height;

  // ── 主题调色板(跟随 light/dark)─────────────────────────────────
  AppPalette get palette =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

  // ── 断点(Material 3)──────────────────────────────────
  bool get isCompact => width < 600;
  bool get isMedium => width >= 600 && width < 1024;
  bool get isExpanded => width >= 1024 && width < 1440;
  bool get isLarge => width >= 1440;
  bool get isDesktop => width >= 1024;

  // ── 缩放因子 ────────────────────────────────────────────
  static const double _refW = 390.0; // 基准宽度
  double get _scale => (width / _refW).clamp(0.85, 1.6);
  double get _scaleBig => isDesktop
      ? (width / _refW).clamp(0.85, 1.05)
      : (width / _refW).clamp(0.85, 1.4); // 字体用:桌面压上限到 1.05 防止溢出,移动端 1.4
  double get _scaleIcon => (width / _refW).clamp(0.9, 1.5); // 图标用

  // ── gap(间距)──────────────────────────────────────────
  // 基础 gap = 屏幕宽度的 ~4.4%,clamp 在 [14, 28]
  // (窄高度场景由 overlay 内部用 Spacer 弹性分隔处理,不再靠收紧 gap 硬扛)
  double get _gapUnit => (width * 0.044).clamp(14.0, 28.0);

  double get gap2xs => _gapUnit * 0.25; // 3.5 ~ 7   - 图标内边距
  double get gapXs => _gapUnit * 0.5; // 7   ~ 14  - 紧凑间距
  double get gapSm => _gapUnit * 0.75; // 10.5~ 21  - 段内间距
  double get gapMd => _gapUnit; // 14  ~ 28  - 默认间距
  double get gapLg => _gapUnit * 1.4; // 19.6~ 39  - 段间/卡片内 padding
  double get gapXl => _gapUnit * 2.0; // 28  ~ 56  - 大间距
  double get gap2xl => _gapUnit * 3.0; // 42  ~ 84  - 超大间距(页面间距)

  // ── radius(圆角)────────────────────────────────────────
  // 圆角随 gap 同比例缩放,下限 8,上限 32
  double get _rUnit => (width * 0.035).clamp(8.0, 32.0);
  double get radiusXs => _rUnit * 0.5; // 4  ~ 16
  double get radiusSm => _rUnit * 0.75; // 6  ~ 24
  double get radiusMd => _rUnit; // 8  ~ 32
  double get radiusLg => _rUnit * 1.5; // 12 ~ 48
  double get radiusXl => _rUnit * 2.0; // 16 ~ 64

  // ── text(字号)──────────────────────────────────────────
  // 字体缩放稍温和,避免 4K 上变得夸张
  double get textXs => 11.0 * _scaleBig; // ~10 ~ 15
  double get textSm => 13.0 * _scaleBig; // ~12 ~ 18
  double get textBase => 14.0 * _scaleBig; // ~12 ~ 19
  double get textMd => 15.0 * _scaleBig; // ~13 ~ 21
  double get textLg => 17.0 * _scaleBig; // ~15 ~ 23
  double get textXl => 20.0 * _scaleBig; // ~17 ~ 27
  double get text2xl => 24.0 * _scaleBig; // ~21 ~ 33
  double get text3xl => 28.0 * _scaleBig; // ~24 ~ 39
  double get text4xl => 36.0 * _scaleBig; // ~31 ~ 50
  double get textDisplay =>
      64.0 * _scaleBig.clamp(0.85, 1.1); // 倒计时大字:上限更紧,避免桌面放大过头撑爆 overlay

  // ── icon(图标)──────────────────────────────────────────
  double get iconXs => 14.0 * _scaleIcon; // ~13 ~ 21
  double get iconSm => 16.0 * _scaleIcon; // ~14 ~ 24
  double get iconMd => 20.0 * _scaleIcon; // ~18 ~ 30
  double get iconLg => 24.0 * _scaleIcon; // ~22 ~ 36
  double get iconXl => 32.0 * _scaleIcon; // ~29 ~ 48
  double get icon2xl => 44.0 * _scaleIcon; // ~40 ~ 66

  // ── 控件尺寸 ─────────────────────────────────────────────
  double get touchTarget => 36.0 * _scale.clamp(1.0, 1.3); // 按钮/可点元素最小尺寸,36-46
  double get buttonH => _gapUnit * 3.25; // 主按钮高度,45-91
  double get buttonHsm => _gapUnit * 2.5; // 次按钮,35-70
  double get inputH => _gapUnit * 3.0; // 输入框高度,42-84
  /// 底部导航(dock)高度 —— 单独按宽度算，不再走 _gapUnit(后者会被
  /// clamp 到 28，把桌面端钉死在 112)。
  ///
  /// 下限 56 保持小屏触感，ratio 0.06 跟屏幕走：
  ///   - 1024 屏:max(56, 61) = 61
  ///   - 1440 屏:max(56, 86) = 86
  ///   - 1920 屏:max(56, 115) = 115
  double get navBarH => math.max(56.0, width * 0.06);

  double get avatarSm => _gapUnit * 2.25; // 小头像,31-63
  double get avatarMd => _gapUnit * 3.0; // 中头像,42-84
  double get avatarLg => _gapUnit * 4.0; // 大头像,56-112

  double get dotSm => _gapUnit * 0.3; // 小圆点 4-8

  // ── padding helpers ──────────────────────────────────────
  EdgeInsets padAll(double f) => EdgeInsets.all(_gapUnit * f);
  EdgeInsets padH(double f) => EdgeInsets.symmetric(horizontal: _gapUnit * f);
  EdgeInsets padV(double f) => EdgeInsets.symmetric(vertical: _gapUnit * f);
  EdgeInsets padHV(double h, double v) =>
      EdgeInsets.symmetric(horizontal: _gapUnit * h, vertical: _gapUnit * v);
  EdgeInsets padFromLTRB(double l, double t, double r, double b) =>
      EdgeInsets.fromLTRB(
        _gapUnit * l,
        _gapUnit * t,
        _gapUnit * r,
        _gapUnit * b,
      );

  /// 屏幕水平 padding -- 手机窄、桌面宽
  EdgeInsets get screenPaddingH =>
      EdgeInsets.symmetric(horizontal: _gapUnit * 1.4);

  /// 底部安全留白 — 当前 main_navigation 用 extendBody:false,
  /// Scaffold 自动让 body 停在 dock 上方,这里只用于参考/历史。
  // 不再提供 bottomNavSafeGap。

  // ── 桌面端容器 ──────────────────────────────────────────
  /// 主内容最大宽 —— 移动端保持手机列宽,桌面端放宽以铺展开。
  ///  - 手机/平板(< 1024): 480(沿用旧 web 风格的手机列)
  ///  - 桌面(>= 1024): 1200(给首页/记录/排行更多展示空间)
  double get contentMaxWidth => isDesktop ? 1200.0 : 480.0;
  double get contentMaxWidthWide => 720.0; // 兼容旧代码 / 平板

  /// 紧凑面板最大宽 —— 底部 dock、桌面端侧栏卡片等都走这个。
  ///
  /// 下限 480(手机列宽基准,保证 4 个 tab 不挤),比例 0.5 跟屏幕宽度走。
  ///   - 1024 屏:max(480, 512) = 512
  ///   - 1440 屏:max(480, 720) = 720
  ///   - 1920 屏:max(480, 960) = 960
  /// dock 在宽屏上是横向延展的药丸，而不是挤在中间的小药丸。
  double get compactPanelMaxWidth => 480;

  /// body 末端需要给 dock 留的高度 = dock 自身高 + 一段安全间距。
  /// 配合 Scaffold(extendBody: true),body 不会被 dock 遮挡。
  double get dockReservedHeight => navBarH + gapMd;

  // ── SizedBox helpers ─────────────────────────────────────
  SizedBox vGap(double f) => SizedBox(height: _gapUnit * f);
  SizedBox hGap(double f) => SizedBox(width: _gapUnit * f);
}

/// BuildContext 扩展 -- `context.r.gapMd` / `context.r.textBase`
extension ResponsiveExt on BuildContext {
  Responsive get r => Responsive(this);
}

/// 桌面端把内容居中并约束在"手机列"宽度内。
///
/// - 移动端(< 1024):保持全宽
/// - 桌面端(>= 1024):居中,最大宽 480(可覆盖)
///
/// **重要**:不用 Align,是因为这个 widget 可能被放进 Scaffold.bottomNavigationBar
/// (无界高度)也能放进 Scaffold.body(有界高度)。Align 需要有界高度,
/// 否则会返回无穷大,导致 Scaffold body 被算成 0。
/// 改用 `Padding` + `SizedBox` 在两种情况下都安全。
class CenteredFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const CenteredFrame({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 父容器实际能给的宽度 vs 设定的最大宽度,取小者
        final targetW = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;
        // 水平 margin = (父宽 - 目标宽) / 2,起到水平居中效果
        final hMargin = (constraints.maxWidth - targetW) / 2;
        // 用 Padding 代替 Align 在无界高度的父容器里也不会出错。
        // SizedBox 强制子组件拿到紧密宽度约束,下游 Stack/Column 才知道多宽。
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hMargin.clamp(0.0, double.infinity),
          ),
          child: SizedBox(
            width: targetW,
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        );
      },
    );
  }
}

/// 文本 + 颜色 token(去掉 MediaQuery 调用)
class FontSize {
  static double base(BuildContext c) => c.r.textBase;
  static double sm(BuildContext c) => c.r.textSm;
  static double md(BuildContext c) => c.r.textMd;
  static double lg(BuildContext c) => c.r.textLg;
  static double xl(BuildContext c) => c.r.textXl;
  static double xxl(BuildContext c) => c.r.text2xl;
  static double display(BuildContext c) => c.r.textDisplay;
}
