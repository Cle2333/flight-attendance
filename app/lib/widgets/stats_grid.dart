import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// 单个统计卡片 —— 横向布局：icon 左，数字+标签右
///
/// 设计要点：
/// - 用 Row 而非 Column，让卡片可以很宽很扁也不溢出
/// - value 用 FittedBox(scaleDown)，超长数字自动缩
/// - label 加 ellipsis，防止「平均起飞时间」这种长文本撑爆
class StatCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String value;
  final String label;
  const StatCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: r.padAll(0.85),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(r.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左：图标方块
          Container(
            width: r.touchTarget * 0.85,
            height: r.touchTarget * 0.85,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(r.radiusSm * 0.85),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: TextStyle(fontSize: r.textLg)),
          ),
          SizedBox(width: r.gapSm),

          // 右：数字 + 标签
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: r.textLg,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                SizedBox(height: r.gap2xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: r.textXs,
                    color: context.palette.textSecondary,
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