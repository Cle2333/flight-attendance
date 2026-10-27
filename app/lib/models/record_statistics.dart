import 'dart:math' as math;

import 'record.dart';

/// 24 小时制起飞时间的环形均值。
///
/// 例如 23:50 与 00:10 的均值应为 00:00，而不是普通的 12:00。
class AverageClockTime {
  final int secondsSinceMidnight;

  const AverageClockTime(this.secondsSinceMidnight);

  String get label {
    final hour = (secondsSinceMidnight ~/ 3600).toString().padLeft(2, '0');
    final minute = ((secondsSinceMidnight % 3600) ~/ 60).toString().padLeft(
      2,
      '0',
    );
    return '$hour:$minute';
  }
}

/// 月度报告的完整统计结果。
class MonthlyReport {
  final DateTime month;
  final int total;
  final int activeDays;
  final int? busiestDay;
  final int busiestDayCount;
  final AverageClockTime? averageTime;
  final int previousMonthTotal;
  final Map<int, int> dailyCounts;

  const MonthlyReport({
    required this.month,
    required this.total,
    required this.activeDays,
    required this.busiestDay,
    required this.busiestDayCount,
    required this.averageTime,
    required this.previousMonthTotal,
    required this.dailyCounts,
  });

  int get daysInMonth => DateTime(month.year, month.month + 1, 0).day;

  int get monthOverMonthDelta => total - previousMonthTotal;

  String get monthOverMonthLabel {
    if (previousMonthTotal == 0) {
      return total == 0 ? '与上月持平' : '上月无记录';
    }
    final delta = monthOverMonthDelta;
    if (delta == 0) return '与上月持平';
    final sign = delta > 0 ? '+' : '';
    return '$sign$delta 次';
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int current;
  final int target;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.current,
    required this.target,
  });

  bool get unlocked => current >= target;

  double get progress => (current / target).clamp(0, 1).toDouble();
}

class RecordStatistics {
  static AverageClockTime? averageClockTime(Iterable<DateTime> times) {
    var sinSum = 0.0;
    var cosSum = 0.0;
    var count = 0;
    for (final time in times) {
      final fraction =
          (time.hour * 3600 + time.minute * 60 + time.second) / 86400;
      final angle = fraction * 2 * math.pi;
      sinSum += math.sin(angle);
      cosSum += math.cos(angle);
      count++;
    }
    if (count == 0) return null;

    final magnitude = math.sqrt(sinSum * sinSum + cosSum * cosSum) / count;
    // 时间几乎均匀分散在一天时，"平均时间"没有稳定含义。
    if (magnitude < 0.05) return null;

    var angle = math.atan2(sinSum, cosSum);
    if (angle < 0) angle += 2 * math.pi;
    final seconds = ((angle / (2 * math.pi)) * 86400).round() % 86400;
    return AverageClockTime(seconds);
  }

  static MonthlyReport monthlyReport(
    Iterable<FlightRecord> records,
    DateTime month,
  ) {
    final dailyCounts = <int, int>{};
    final times = <DateTime>[];
    for (final record in records) {
      if (record.time.year == month.year && record.time.month == month.month) {
        dailyCounts.update(
          record.time.day,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        times.add(record.time);
      }
    }

    int? busiestDay;
    var busiestDayCount = 0;
    for (final entry in dailyCounts.entries) {
      if (entry.value > busiestDayCount) {
        busiestDay = entry.key;
        busiestDayCount = entry.value;
      }
    }

    final previousMonth = DateTime(month.year, month.month - 1);
    final previousMonthTotal = records
        .where(
          (record) =>
              record.time.year == previousMonth.year &&
              record.time.month == previousMonth.month,
        )
        .length;

    return MonthlyReport(
      month: DateTime(month.year, month.month),
      total: times.length,
      activeDays: dailyCounts.length,
      busiestDay: busiestDay,
      busiestDayCount: busiestDayCount,
      averageTime: averageClockTime(times),
      previousMonthTotal: previousMonthTotal,
      dailyCounts: dailyCounts,
    );
  }

  static int currentStreak(Iterable<FlightRecord> records, {DateTime? now}) {
    final days = _uniqueDays(records);
    if (days.isEmpty) return 0;
    var cursor = _dayOnly(now ?? DateTime.now());
    if (!days.contains(cursor)) return 0;
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int longestStreak(Iterable<FlightRecord> records) {
    final days = _uniqueDays(records).toList()..sort();
    if (days.isEmpty) return 0;
    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static List<Achievement> achievements({
    required int totalRecords,
    required int longestStreak,
  }) {
    return [
      Achievement(
        id: 'first-flight',
        title: '初次起飞',
        description: '完成第 1 次打卡',
        icon: '🛫',
        current: totalRecords,
        target: 1,
      ),
      Achievement(
        id: 'ten-flights',
        title: '十次起飞',
        description: '累计完成 10 次打卡',
        icon: '🎫',
        current: totalRecords,
        target: 10,
      ),
      Achievement(
        id: 'fifty-flights',
        title: '飞行常客',
        description: '累计完成 50 次打卡',
        icon: '🧳',
        current: totalRecords,
        target: 50,
      ),
      Achievement(
        id: 'hundred-flights',
        title: '百次起飞',
        description: '累计完成 100 次打卡',
        icon: '🏅',
        current: totalRecords,
        target: 100,
      ),
      Achievement(
        id: 'seven-day-streak',
        title: '连续七天',
        description: '连续 7 天都有起飞',
        icon: '🔥',
        current: longestStreak,
        target: 7,
      ),
      Achievement(
        id: 'thirty-day-streak',
        title: '月度全勤',
        description: '连续 30 天都有起飞',
        icon: '🏆',
        current: longestStreak,
        target: 30,
      ),
    ];
  }

  static Set<DateTime> _uniqueDays(Iterable<FlightRecord> records) {
    return records.map((record) => _dayOnly(record.time)).toSet();
  }

  static DateTime _dayOnly(DateTime time) =>
      DateTime(time.year, time.month, time.day);
}
