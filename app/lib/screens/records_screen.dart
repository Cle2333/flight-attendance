import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/record.dart';
import '../state/app_state.dart';
import '../state/controllers/records_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/stats_grid.dart';
import 'record_detail_screen.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(RecordsController());
    final state = Get.find<AppState>();
    final r = context.r;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(bottom: r.gapLg),
        children: [
          Padding(
            padding: r.padFromLTRB(1.4, 1.0, 1.4, 0.8),
            child: Text(
              '✈️ 航班记录',
              style: TextStyle(fontSize: r.text2xl, fontWeight: FontWeight.w800),
            ),
          ),
          Obx(() => CalendarWidget(
                currentDate: ctrl.calDate.value,
                onMonthChanged: ctrl.shiftMonth,
                hasRecordOn: state.hasRecordOn,
                onDateTapped: ctrl.navigateToDay,
                expandedNotifier: ctrl.calendarExpanded,
              )),
          SizedBox(height: r.gapMd),
          Padding(
            padding: r.padFromLTRB(1.4, 0.4, 1.4, 0.6),
            child: Text(
              '快速统计',
              style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
            ),
          ),
          // ⚠️ 必须包 Obx：getter 读 records.length，records 是 RxList，
          // 没 Obx 永远不刷新。
          // ⚠️⚠️ 而且 Rx 读取必须放在 Obx builder 的**同步**作用域里！
          //    GetX 只追踪 builder 返回 widget 之前同步执行的 Rx 访问。
          //    如果把 state.xxx 放在 LayoutBuilder/Builder/FutureBuilder 的
          //    builder 里，GetX 看不到，会报 "improper use of GetX"。
          Obx(() {
            // 先读 — 让 GetX 追到
            final total = state.totalRecords;
            final streak = state.currentStreak;
            final avg = state.averageTakeoffHour;
            final badges = state.badges;
            final avgText = avg == null
                ? '--:--'
                : '${avg.toString().padLeft(2, '0')}:00';

            return Padding(
              padding: r.padH(1.4),
              // Wrap 代替 GridView —— 卡片高度跟 StatCard 自身内容走,
              // 不再用硬编码的 childAspectRatio 撑高。
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 2 列:每列宽度 = (总宽 - 间距) / 2
                  final cardW = (constraints.maxWidth - r.gapSm) / 2;
                  return Wrap(
                    spacing: r.gapSm,
                    runSpacing: r.gapSm,
                    children: [
                      SizedBox(
                        width: cardW,
                        child: StatCard(
                          icon: '✈️',
                          iconBg: context.palette.primaryBg,
                          value: '$total',
                          label: '总起飞次数',
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        child: StatCard(
                          icon: '🔥',
                          iconBg: context.palette.successBg,
                          value: '$streak',
                          label: '连续天数',
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        child: StatCard(
                          icon: '⏰',
                          iconBg: context.palette.warningBg,
                          value: avgText,
                          label: '平均起飞时间',
                        ),
                      ),
                      SizedBox(
                        width: cardW,
                        child: StatCard(
                          icon: '🏆',
                          iconBg: context.palette.infoBg,
                          value: '$badges',
                          label: '徽章',
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
          SizedBox(height: r.gapXs),
          GestureDetector(
            onTap: ctrl.toggleDetail,
            behavior: HitTestBehavior.opaque,
            child: Obx(() => Container(
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
                )),
          ),
          Obx(() {
            final records = state.records;
            final grouped = ctrl.groupedRecords(records);
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
                              children:
                                  grouped.entries.expand((entry) {
                                final recs = entry.value;
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
                                  ...recs.asMap().entries.map((e) {
                                    final i = e.key;
                                    final rec = e.value;
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: r.gapSm * 0.8),
                                      child: _RecordItem(
                                        record: rec,
                                        indexInDay: recs.length - i,
                                      ),
                                    );
                                  }),
                                ];
                              }).toList(),
                            ),
                    )
                  : const SizedBox.shrink(),
            );
          }),
        ],
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