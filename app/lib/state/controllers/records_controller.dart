import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/record.dart';
import '../../screens/record_detail_screen.dart';
import '../../utils/formatters.dart';
import '../app_state.dart';

/// 航班记录页状态 —— 当前日历月、详情展开态、按天分组的列表。
///
/// 抽 controller 让 RecordsScreen 变无状态 widget,数据驱动的部分
/// (records → 按 dayLabel 分组)集中在 controller,便于以后扩展
/// (筛选条件、搜索词、缓存)。
class RecordsController extends GetxController {
  final AppState _state = Get.find<AppState>();

  /// 当前日历显示的月份(任意一天就行,只取 year/month)
  final Rx<DateTime> calDate = DateTime.now().obs;

  /// "查看起飞记录" 折叠面板是否展开
  final RxBool detailOpen = false.obs;

  /// 日历是否展开为月视图
  final ValueNotifier<bool> calendarExpanded = ValueNotifier(false);

  void shiftMonth(int delta) {
    final d = calDate.value;
    calDate.value = DateTime(d.year, d.month + delta, d.day);
  }

  void toggleDetail() {
    detailOpen.value = !detailOpen.value;
  }

  /// 把 records 倒序、按 dayLabel 分组 —— 给 _RecordItem 列表用。
  Map<String, List<FlightRecord>> groupedRecords(List<FlightRecord> records) {
    final sorted = [...records]..sort((a, b) => b.time.compareTo(a.time));
    final grouped = <String, List<FlightRecord>>{};
    for (final r in sorted) {
      grouped.putIfAbsent(DateFormatters.dayLabel(r.time), () => []).add(r);
    }
    return grouped;
  }

  /// 跳到指定日期的记录详情(如果有)。
  void navigateToDay(DateTime d) {
    final list = _state.records
        .where((r) => isSameDay(r.time, d))
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    if (list.isEmpty) return;
    Get.to(() => RecordDetailScreen(recordId: list.first.id));
  }

  @override
  void onClose() {
    calendarExpanded.dispose();
    super.onClose();
  }
}