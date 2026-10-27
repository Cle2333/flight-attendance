import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// 底部液体玻璃导航：滑动胶囊 + 毛玻璃背景。
class MainDock extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const MainDock({super.key, required this.index, required this.onChanged});

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.calendar_today_outlined,
    Icons.person_outline,
  ];

  static const _activeIcons = <IconData>[
    Icons.home_rounded,
    Icons.calendar_month_rounded,
    Icons.person_rounded,
  ];

  static const _labels = ['首页', '记录', '我的'];

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: r.gapMd),
      height: r.navBarH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.card.withValues(alpha: isDark ? 0.50 : 0.70),
                  palette.surfaceMuted.withValues(alpha: isDark ? 0.38 : 0.48),
                  AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(r.radiusXl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.13)
                    : Colors.white.withValues(alpha: 0.74),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _icons.length;
                final inset = r.gapXs * 0.55;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      left: itemWidth * index + inset,
                      top: inset,
                      width: itemWidth - inset * 2,
                      height: constraints.maxHeight - inset * 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Colors.white.withValues(alpha: 0.19),
                                    AppColors.primary.withValues(alpha: 0.20),
                                    Colors.white.withValues(alpha: 0.06),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.92),
                                    Colors.white.withValues(alpha: 0.58),
                                    AppColors.primary.withValues(alpha: 0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(r.radiusLg),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.16)
                                : Colors.white.withValues(alpha: 0.94),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.16 : 0.07,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: isDark ? 0.16 : 0.10,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_icons.length, (i) {
                        return Expanded(
                          child: DockTab(
                            icon: _icons[i],
                            activeIcon: _activeIcons[i],
                            label: _labels[i],
                            active: i == index,
                            onTap: () => onChanged(i),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class DockTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const DockTab({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;

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
          child: AnimatedScale(
            scale: active ? 1.045 : 1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    active ? activeIcon : icon,
                    size: r.iconMd,
                    color: active ? AppColors.primary : palette.textLight,
                  ),
                  SizedBox(height: r.gap2xs),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: r.textXs,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppColors.primary : palette.textLight,
                      letterSpacing: active ? 0.2 : 0,
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
