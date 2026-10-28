import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/local_avatar.dart';

/// 宽屏应用的液体玻璃侧边栏。
class DesktopSidebar extends StatelessWidget {
  final int index;
  final String? avatarPath;
  final ValueChanged<int> onChanged;

  const DesktopSidebar({
    super.key,
    required this.index,
    required this.onChanged,
    this.avatarPath,
  });

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.calendar_today_outlined,
    Icons.person_outline,
  ];

  static const _labels = ['首页', '记录', '我的'];

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const itemHeight = 70.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
            blurRadius: 32,
            offset: const Offset(8, 12),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 26,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            padding: EdgeInsets.all(r.gapMd),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.card.withValues(alpha: isDark ? 0.52 : 0.76),
                  palette.surfaceMuted.withValues(alpha: isDark ? 0.34 : 0.46),
                  AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(r.radiusXl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.13)
                    : Colors.white.withValues(alpha: 0.76),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BrandHeader(isDark: isDark, avatarPath: avatarPath),
                SizedBox(height: r.gapLg),
                Container(
                  height: 1,
                  color: palette.border.withValues(alpha: 0.60),
                ),
                SizedBox(height: r.gapLg),
                Text(
                  '工作台',
                  style: TextStyle(
                    fontSize: r.textXs,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: palette.textLight,
                  ),
                ),
                SizedBox(height: r.gapSm),
                SizedBox(
                  height: itemHeight * _labels.length,
                  child: Column(
                    children: List.generate(_labels.length, (i) {
                      return SizedBox(
                        height: itemHeight,
                        child: _SidebarTab(
                          icon: _icons[i],
                          label: _labels[i],
                          active: i == index,
                          onTap: () => onChanged(i),
                        ),
                      );
                    }),
                  ),
                ),
                const Spacer(),
                _LocalStatus(isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool isDark;
  final String? avatarPath;

  const _BrandHeader({required this.isDark, required this.avatarPath});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    return Row(
      children: [
        LocalAvatar(
          imagePath: avatarPath,
          size: r.touchTarget * 1.25,
          iconSize: r.iconLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        SizedBox(width: r.gapSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FLIGHT LOG',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.textSm,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: palette.text,
                ),
              ),
              SizedBox(height: r.gap2xs),
              Text(
                'LOCAL · PRIVATE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.textXs * 0.82,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: isDark ? palette.textLight : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (active) return;
            HapticFeedback.selectionClick();
            onTap();
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(vertical: r.gap2xs),
            padding: EdgeInsets.symmetric(horizontal: r.gapSm),
            decoration: BoxDecoration(
              color: active
                  ? (isDark ? palette.card : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(r.radiusLg),
              border: active
                  ? Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.94),
                    )
                  : null,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.16 : 0.07,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: active ? 1.08 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      icon,
                      size: r.iconMd,
                      color: active ? AppColors.primary : palette.textLight,
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: r.textMd,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.primary : palette.textSecondary,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalStatus extends StatelessWidget {
  final bool isDark;

  const _LocalStatus({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    return Container(
      padding: r.padAll(0.75),
      decoration: BoxDecoration(
        color: palette.surfaceMuted.withValues(alpha: isDark ? 0.34 : 0.50),
        borderRadius: BorderRadius.circular(r.radiusLg),
        border: Border.all(color: palette.border.withValues(alpha: 0.56)),
      ),
      child: Row(
        children: [
          Container(
            width: r.gapXs,
            height: r.gapXs,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: r.gapXs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本地 SQLite',
                  style: TextStyle(
                    fontSize: r.textXs,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
                SizedBox(height: r.gap2xs),
                Text(
                  '数据仅保存在本机',
                  style: TextStyle(
                    fontSize: r.textXs * 0.86,
                    color: palette.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
