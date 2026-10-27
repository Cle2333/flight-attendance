import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';

/// 自定义日历：周视图 + 可展开月视图
///
/// 完全无状态 —— 展开状态由调用方通过 [expandedNotifier] 注入
/// (用 `ValueNotifier<bool>`),月份切换通过 [onMonthChanged] 回调,
/// 日期标记通过 [hasRecordOn] 闭包,日期点击通过 [onDateTapped] 回调。
class CalendarWidget extends StatelessWidget {
  final DateTime currentDate;
  final ValueChanged<int> onMonthChanged; // -1: prev month, +1: next month
  final bool Function(DateTime) hasRecordOn;
  final ValueChanged<DateTime> onDateTapped;

  /// 展开状态由外部持有 —— 通常调用方会在自己的 controller 里持有一个
  /// `final expanded = false.obs`,这里传 `controller.expanded` 即可。
  /// 如果不传,默认使用静态 fallback(共享同一个状态,不推荐多个 widget 共用)。
  final ValueNotifier<bool>? expandedNotifier;

  /// 兼容旧调用方:不传 expandedNotifier 时,所有 widget 共用这个全局
  /// ValueNotifier(适合单实例场景)。多个实例同时存在会互相影响。
  static final _defaultExpanded = ValueNotifier(false);

  const CalendarWidget({
    super.key,
    required this.currentDate,
    required this.onMonthChanged,
    required this.hasRecordOn,
    required this.onDateTapped,
    this.expandedNotifier,
  });

  void _toggleExpanded() {
    final notifier = expandedNotifier ?? _defaultExpanded;
    notifier.value = !notifier.value;
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final expanded = expandedNotifier ?? _defaultExpanded;
    return Container(
      margin: r.padH(1.4),
      padding: r.padAll(1.125),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHead(context),
          SizedBox(height: r.gapSm),
          ValueListenableBuilder<bool>(
            valueListenable: expanded,
            builder: (_, isExpanded, __) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isExpanded) _buildWeek(context),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: isExpanded
                        ? Padding(
                            padding: EdgeInsets.only(top: r.gapSm),
                            child: _buildMonth(context),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(height: r.gapXs * 0.5),
                  Center(
                    child: GestureDetector(
                      onTap: _toggleExpanded,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: r.padV(0.5),
                        child: Text(
                          isExpanded ? '收起月视图' : '展开月视图',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: r.textSm,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHead(BuildContext context) {
    final r = context.r;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormatters.monthLabel(currentDate),
          style: TextStyle(fontSize: r.textMd, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            _navBtn(context, '‹', () => onMonthChanged(-1)),
            SizedBox(width: r.gapXs),
            _navBtn(context, '›', () => onMonthChanged(1)),
          ],
        ),
      ],
    );
  }

  Widget _navBtn(BuildContext context, String label, VoidCallback onTap) {
    final r = context.r;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r.radiusLg),
      child: Container(
        width: r.touchTarget * 0.85,
        height: r.touchTarget * 0.85,
        decoration: BoxDecoration(
          border: Border.all(color: context.palette.border),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: context.palette.textSecondary,
            fontSize: r.textBase,
          ),
        ),
      ),
    );
  }

  Widget _buildWeek(BuildContext context) {
    final r = context.r;
    final d = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final mondayOffset = (d.weekday - 1);
    final monday = d.subtract(Duration(days: mondayOffset));
    final today = DateTime.now();
    final labels = ['一', '二', '三', '四', '五', '六', '日'];

    return Row(
      children: List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        final isToday = isSameDay(day, today);
        final marked = hasRecordOn(day);
        return Expanded(
          child: GestureDetector(
            onTap: () => onDateTapped(day),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: r.padV(0.5),
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(r.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: r.textXs,
                      color: isToday
                          ? Colors.white.withValues(alpha: 0.8)
                          : context.palette.textLight,
                    ),
                  ),
                  SizedBox(height: r.gapXs * 0.5),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: r.textLg,
                      fontWeight: FontWeight.w600,
                      color: isToday ? Colors.white : context.palette.text,
                    ),
                  ),
                  SizedBox(height: r.gapXs * 0.5),
                  Container(
                    width: r.dotSm,
                    height: r.dotSm,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? Colors.white
                          : (marked ? AppColors.primary : Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMonth(BuildContext context) {
    final r = context.r;
    final year = currentDate.year;
    final month = currentDate.month;
    final first = DateTime(year, month, 1);
    var firstWeekday = first.weekday - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    final labels = ['一', '二', '三', '四', '五', '六', '日'];
    final cellSize = r.gapLg * 2.0;  // 日历单元格高度

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: TextStyle(
                        fontSize: r.textXs,
                        color: context.palette.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: r.gapXs * 0.5),
        ...List.generate(6, (row) {
          return Row(
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final day = idx - firstWeekday + 1;
              if (day < 1 || day > daysInMonth) {
                return Expanded(child: SizedBox(height: cellSize));
              }
              final d = DateTime(year, month, day);
              final isToday = isSameDay(d, today);
              final marked = hasRecordOn(d);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDateTapped(d),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: cellSize,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: cellSize * 0.85,
                          height: cellSize * 0.85,
                          decoration: BoxDecoration(
                            color: isToday ? AppColors.primary : null,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: r.textSm,
                              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                              color: isToday ? Colors.white : context.palette.text,
                            ),
                          ),
                        ),
                        if (marked)
                          Positioned(
                            bottom: cellSize * 0.1,
                            child: Container(
                              width: r.dotSm,
                              height: r.dotSm,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday ? Colors.white : AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}