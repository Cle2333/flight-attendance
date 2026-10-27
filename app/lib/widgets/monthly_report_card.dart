import 'package:flutter/material.dart';

import '../models/record_statistics.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import 'monthly_bar_chart.dart';
import 'stats_grid.dart';

class MonthlyReportCard extends StatelessWidget {
  final MonthlyReport report;

  const MonthlyReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final busiest = report.busiestDay == null
        ? '--'
        : '${report.month.month}/${report.busiestDay}';
    final busiestLabel = report.busiestDay == null
        ? '本月暂无记录'
        : '${report.busiestDayCount} 次起飞';
    final averageLabel = report.averageTime?.label ?? '--:--';

    return Container(
      margin: r.padH(1.4),
      padding: r.padAll(1.1),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(r.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📊 本月报告',
                style: TextStyle(
                  fontSize: r.textLg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                DateFormatters.monthLabel(report.month),
                style: TextStyle(
                  fontSize: r.textXs,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: r.gapMd),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - r.gapSm) / 2;
              return Wrap(
                spacing: r.gapSm,
                runSpacing: r.gapSm,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      icon: '✈️',
                      iconBg: context.palette.primaryBg,
                      value: '${report.total}',
                      label: '本月起飞 · ${report.monthOverMonthLabel}',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      icon: '📅',
                      iconBg: context.palette.successBg,
                      value: '${report.activeDays}/${report.daysInMonth}',
                      label: '有记录的天数',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      icon: '🏙️',
                      iconBg: context.palette.warningBg,
                      value: busiest,
                      label: busiestLabel,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: StatCard(
                      icon: '🕰️',
                      iconBg: context.palette.infoBg,
                      value: averageLabel,
                      label: '平均起飞时间',
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: r.gapMd),
          MonthlyBarChart(
            dailyCounts: report.dailyCounts,
            daysInMonth: report.daysInMonth,
          ),
        ],
      ),
    );
  }
}
