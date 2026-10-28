import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/record.dart';
import '../state/app_state.dart';
import '../state/controllers/records_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/achievement_grid.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/monthly_report_card.dart';
import '../widgets/stats_grid.dart';
import 'record_detail_screen.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<RecordsController>()
        ? Get.find<RecordsController>()
        : Get.put<RecordsController>(RecordsController());
    final state = Get.find<AppState>();
    final r = context.r;

    return SafeArea(
      bottom: false,
      child: r.isDesktop
          ? _buildDesktop(context, ctrl, state, r)
          : _buildMobile(context, ctrl, state, r),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    RecordsController ctrl,
    AppState state,
    Responsive r,
  ) {
    return ListView(
      padding: EdgeInsets.only(bottom: r.gapLg),
      children: [
        Padding(
          padding: r.padFromLTRB(1.2, 0.9, 1.2, 0.5),
          child: const _RecordsPageHeader(
            title: '航班记录',
            subtitle: '日历、月报与每一次起飞',
          ),
        ),
        Obx(
          () => CalendarWidget(
            currentDate: ctrl.calDate.value,
            onMonthChanged: ctrl.shiftMonth,
            hasRecordOn: state.hasRecordOn,
            onDateTapped: ctrl.navigateToDay,
            expandedNotifier: ctrl.calendarExpanded,
          ),
        ),
        SizedBox(height: r.gapMd),
        const _SectionLabel(text: '快速统计'),
        _buildQuickStats(context, state),
        SizedBox(height: r.gapMd),
        Obx(
          () => MonthlyReportCard(
            report: state.monthlyReport(ctrl.calDate.value),
          ),
        ),
        SizedBox(height: r.gapMd),
        Obx(() => AchievementGrid(achievements: state.achievements)),
        SizedBox(height: r.gapXs),
        _buildRecordToggle(context, ctrl, r),
        _buildMobileRecordList(context, ctrl, state, r),
      ],
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    AppState state, {
    bool stacked = false,
    bool flush = false,
  }) {
    return Obx(() {
      final total = state.totalRecords;
      final streak = state.currentStreak;
      final cards = [
        StatCard(
          icon: '✈️',
          iconBg: context.palette.primaryBg,
          value: '$total',
          label: '总起飞次数',
        ),
        StatCard(
          icon: '🔥',
          iconBg: context.palette.successBg,
          value: '$streak',
          label: '连续天数',
        ),
      ];

      return Padding(
        padding: flush ? EdgeInsets.zero : context.r.padH(1.4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (stacked) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i < cards.length - 1) SizedBox(height: context.r.gapSm),
                  ],
                ],
              );
            }
            final cardWidth = (constraints.maxWidth - context.r.gapSm) / 2;
            return Wrap(
              spacing: context.r.gapSm,
              runSpacing: context.r.gapSm,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildRecordToggle(
    BuildContext context,
    RecordsController ctrl,
    Responsive r,
  ) {
    return GestureDetector(
      onTap: ctrl.toggleDetail,
      behavior: HitTestBehavior.opaque,
      child: Obx(
        () => Container(
          margin: r.padHV(1.4, 0.8),
          padding: r.padHV(1.0, 1.0),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '查看起飞记录',
                style: TextStyle(
                  fontSize: r.textMd,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: ctrl.detailOpen.value ? 0.25 : 0,
                child: Icon(
                  Icons.chevron_right,
                  size: r.iconMd,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileRecordList(
    BuildContext context,
    RecordsController ctrl,
    AppState state,
    Responsive r,
  ) {
    return Obx(() {
      final grouped = ctrl.groupedRecords(state.records);
      final detailOpen = ctrl.detailOpen.value;
      return AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: detailOpen
            ? Padding(
                padding: r.padFromLTRB(1.4, 0, 1.4, 0),
                child: grouped.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: r.gapXl),
                        child: Center(
                          child: Text(
                            '暂无记录',
                            style: TextStyle(color: context.palette.textLight),
                          ),
                        ),
                      )
                    : Column(
                        children: _buildGroupedRecordRows(context, ctrl, state),
                      ),
              )
            : const SizedBox.shrink(),
      );
    });
  }

  Widget _buildDesktop(
    BuildContext context,
    RecordsController ctrl,
    AppState state,
    Responsive r,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.gapMd, r.gapMd, r.gapMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _RecordsPageHeader(
            title: '航班记录',
            subtitle: '日历、月报与每一次起飞',
            desktop: true,
          ),
          SizedBox(height: r.gapMd),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: r.gapMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(() => _buildDesktopCalendar(context, ctrl, state)),
                        SizedBox(height: r.gapMd),
                        const _SectionLabel(text: '快速统计', flush: true),
                        _buildQuickStats(
                          context,
                          state,
                          stacked: true,
                          flush: true,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: r.gapMd),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: r.gapMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(
                          () => MonthlyReportCard(
                            report: state.monthlyReport(ctrl.calDate.value),
                            embedded: true,
                          ),
                        ),
                        SizedBox(height: r.gapMd),
                        Obx(
                          () => AchievementGrid(
                            achievements: state.achievements,
                            embedded: true,
                          ),
                        ),
                        SizedBox(height: r.gapMd),
                        _buildDesktopRecordCard(context, ctrl, state, r),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCalendar(
    BuildContext context,
    RecordsController ctrl,
    AppState state,
  ) {
    return CalendarWidget(
      currentDate: ctrl.calDate.value,
      onMonthChanged: ctrl.shiftMonth,
      hasRecordOn: state.hasRecordOn,
      onDateTapped: ctrl.navigateToDay,
      expandedNotifier: ctrl.calendarExpanded,
      embedded: true,
    );
  }

  Widget _buildDesktopRecordCard(
    BuildContext context,
    RecordsController ctrl,
    AppState state,
    Responsive r,
  ) {
    return Obx(() {
      final grouped = ctrl.groupedRecords(state.records);
      return Container(
        margin: EdgeInsets.zero,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '起飞记录',
                  style: TextStyle(
                    fontSize: r.textLg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: r.padHV(0.55, 0.22),
                  decoration: BoxDecoration(
                    color: context.palette.primaryBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${state.records.length} 条',
                    style: TextStyle(
                      fontSize: r.textXs,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: r.gapSm),
            if (grouped.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.gapXl),
                child: Center(
                  child: Text(
                    '还没有起飞记录',
                    style: TextStyle(color: context.palette.textLight),
                  ),
                ),
              )
            else
              ..._buildGroupedRecordRows(context, ctrl, state),
          ],
        ),
      );
    });
  }

  List<Widget> _buildGroupedRecordRows(
    BuildContext context,
    RecordsController ctrl,
    AppState state,
  ) {
    final r = context.r;
    final grouped = ctrl.groupedRecords(state.records);
    return grouped.entries.expand((entry) {
      final records = entry.value;
      return [
        Padding(
          padding: r.padFromLTRB(0.2, 0.7, 0.2, 0.4),
          child: Text(
            entry.key,
            style: TextStyle(
              fontSize: r.textXs,
              color: context.palette.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...records.asMap().entries.map((item) {
          return Padding(
            padding: EdgeInsets.only(bottom: r.gapSm * 0.8),
            child: _RecordItem(
              record: item.value,
              indexInDay: records.length - item.key,
            ),
          );
        }),
      ];
    }).toList();
  }
}

class _RecordsPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool desktop;

  const _RecordsPageHeader({
    required this.title,
    required this.subtitle,
    this.desktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Row(
      children: [
        Container(
          width: r.touchTarget * (desktop ? 1.25 : 1.05),
          height: r.touchTarget * (desktop ? 1.25 : 1.05),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(r.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.flight_takeoff_rounded,
            color: Colors.white,
            size: r.iconLg,
          ),
        ),
        SizedBox(width: r.gapSm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: desktop ? r.text3xl : r.text2xl,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            SizedBox(height: r.gap2xs),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: r.textXs,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool flush;

  const _SectionLabel({required this.text, this.flush = false});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: flush
          ? EdgeInsets.only(bottom: r.gapXs)
          : r.padFromLTRB(1.4, 0.2, 1.4, 0.6),
      child: Text(
        text,
        style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final FlightRecord record;
  final int indexInDay;
  const _RecordItem({required this.record, required this.indexInDay});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final t = DateFormatters.timeHM(record.time);
    final noteText = record.note.isEmpty ? '' : ' · ${record.note}';
    return Material(
      color: context.palette.card,
      borderRadius: BorderRadius.circular(r.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(r.radiusLg),
        onTap: () => Get.to(() => RecordDetailScreen(recordId: record.id)),
        child: Container(
          padding: r.padAll(0.875),
          decoration: BoxDecoration(
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
              Container(
                width: r.touchTarget * 1.2,
                height: r.touchTarget * 1.2,
                decoration: BoxDecoration(
                  color: context.palette.primaryBg,
                  borderRadius: BorderRadius.circular(r.radiusSm),
                ),
                alignment: Alignment.center,
                child: Text('✈️', style: TextStyle(fontSize: r.textXl)),
              ),
              SizedBox(width: r.gapSm * 0.95),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '第 $indexInDay 次起飞',
                      style: TextStyle(
                        fontSize: r.textMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: r.gap2xs),
                    Text(
                      '$t$noteText',
                      style: TextStyle(
                        fontSize: r.textXs,
                        color: context.palette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: r.padHV(0.5, 0.2),
                decoration: BoxDecoration(
                  color: context.palette.successBg,
                  borderRadius: BorderRadius.circular(r.radiusXl),
                ),
                child: Text(
                  '已完成',
                  style: TextStyle(
                    fontSize: r.textXs,
                    fontWeight: FontWeight.w600,
                    color: context.palette.successText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
