import 'package:flutter_test/flutter_test.dart';
import 'package:flight_attendance_app/models/record.dart';
import 'package:flight_attendance_app/models/record_statistics.dart';

FlightRecord record(DateTime time, {int id = 0, String note = ''}) =>
    FlightRecord(id: id, time: time, note: note);

void main() {
  group('RecordStatistics', () {
    test('平均起飞时间按 24 小时环形均值计算', () {
      final average = RecordStatistics.averageClockTime([
        DateTime(2026, 10, 1, 23, 50),
        DateTime(2026, 10, 2, 0, 10),
      ]);

      expect(average, isNotNull);
      expect(average!.label, '00:00');
    });

    test('月报统计总数、活跃天数、最忙一天和上月对比', () {
      final records = [
        record(DateTime(2026, 10, 1, 9), id: 1),
        record(DateTime(2026, 10, 1, 18), id: 2),
        record(DateTime(2026, 10, 3, 12), id: 3),
        record(DateTime(2026, 9, 20, 12), id: 4),
      ];

      final report = RecordStatistics.monthlyReport(
        records,
        DateTime(2026, 10, 15),
      );

      expect(report.total, 3);
      expect(report.activeDays, 2);
      expect(report.busiestDay, 1);
      expect(report.busiestDayCount, 2);
      expect(report.previousMonthTotal, 1);
      expect(report.monthOverMonthDelta, 2);
      expect(report.daysInMonth, 31);
      expect(report.averageTime, isNotNull);
    });

    test('连续天数与最长连续天数按自然日计算', () {
      final now = DateTime(2026, 10, 27, 10);
      final records = [
        record(DateTime(2026, 10, 25, 9), id: 1),
        record(DateTime(2026, 10, 26, 9), id: 2),
        record(DateTime(2026, 10, 27, 9), id: 3),
        record(DateTime(2026, 10, 20, 9), id: 4),
        record(DateTime(2026, 10, 21, 9), id: 5),
      ];

      expect(RecordStatistics.currentStreak(records, now: now), 3);
      expect(RecordStatistics.longestStreak(records), 3);
    });

    test('徽章按记录总数和最长连续天数解锁', () {
      final achievements = RecordStatistics.achievements(
        totalRecords: 10,
        longestStreak: 7,
      );

      expect(achievements.where((item) => item.unlocked).length, 3);
      expect(
        achievements.firstWhere((item) => item.id == 'ten-flights').unlocked,
        isTrue,
      );
      expect(
        achievements.firstWhere((item) => item.id == 'fifty-flights').unlocked,
        isFalse,
      );
    });
  });
}
