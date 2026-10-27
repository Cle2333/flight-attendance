import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// 底部 dock 栏 —— 圆角毛玻璃容器 + 4 个 tab
class MainDock extends StatelessWidget {
  /// 当前选中 tab 的下标
  final int index;

  /// tab 被点击时回调，参数是新选中的下标
  final ValueChanged<int> onChanged;

  const MainDock({
    super.key,
    required this.index,
    required this.onChanged,
  });

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.calendar_today_outlined,
    Icons.emoji_events_outlined,
    Icons.person_outline,
  ];

  static const _labels = ['首页', '记录', '排行', '我的'];

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: r.gapMd),
      height: r.navBarH,
      decoration: BoxDecoration(
        // 用 palette token，light/dark 各自走自己的 dockBg(都是 0.72 alpha)
        color: context.palette.dockBg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(r.radiusXl),
        border: Border.all(color: context.palette.dockBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.radiusXl),
        child: Row(
          children: List.generate(_icons.length, (i) {
            return Expanded(
              child: DockTab(
                icon: _icons[i],
                label: _labels[i],
                active: i == index,
                onTap: () => onChanged(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// 单个 tab —— 图标 + 文字，选中时有动画背景
class DockTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const DockTab({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 选中态的背景胶囊 —— light 用 card(白)，dark 用 surfaceMuted
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: active ? r.gapXl * 1.4 : 0,
            height: r.buttonHsm,
            decoration: BoxDecoration(
              color: active ? context.palette.card : Colors.transparent,
              borderRadius: BorderRadius.circular(r.radiusMd),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
          // 图标 + 文字
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: r.iconMd,
                color: active ? AppColors.primary : context.palette.textLight,
              ),
              SizedBox(height: r.gap2xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: r.textXs,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? AppColors.primary : context.palette.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}