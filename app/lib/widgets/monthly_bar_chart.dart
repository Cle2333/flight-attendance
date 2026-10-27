import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// 当月每日起飞次数柱状图。
class MonthlyBarChart extends StatelessWidget {
  final Map<int, int> dailyCounts;
  final int daysInMonth;

  const MonthlyBarChart({
    super.key,
    required this.dailyCounts,
    required this.daysInMonth,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final maxCount = dailyCounts.values.fold<int>(0, math.max);
    final labelDays = <int>{1, 5, 10, 15, 20, 25, daysInMonth};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '每日起飞次数',
              style: TextStyle(fontSize: r.textMd, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              maxCount == 0 ? '暂无数据' : '单日最高 $maxCount 次',
              style: TextStyle(
                fontSize: r.textXs,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: r.gapSm),
        SizedBox(
          height: r.gapXl * 5.2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(daysInMonth, (index) {
              final day = index + 1;
              final count = dailyCounts[day] ?? 0;
              final ratio = maxCount == 0 ? 0.0 : count / maxCount;
              return Expanded(
                child: Tooltip(
                  message: '$day 日：$count 次起飞',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.gap2xs / 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final height = count == 0
                                  ? 2.0
                                  : math.max(
                                      4.0,
                                      constraints.maxHeight * ratio,
                                    );
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: count == 0
                                        ? context.palette.border
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(r.radiusSm / 2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: r.gap2xs),
                        SizedBox(
                          height: r.textXs * 1.5,
                          child: Text(
                            labelDays.contains(day) ? '$day' : '',
                            style: TextStyle(
                              fontSize: r.textXs * 0.85,
                              color: context.palette.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
