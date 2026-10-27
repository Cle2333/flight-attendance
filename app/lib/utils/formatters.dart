import 'package:intl/intl.dart';

class DateFormatters {
  static String monthLabel(DateTime d) => '${d.year} 年 ${d.month} 月';

  static String timeHM(DateTime d) => DateFormat('HH:mm').format(d);

  static String timeFull(DateTime d) => DateFormat('yyyy-MM-dd HH:mm:ss').format(d);

  static String timeLocal(DateTime d) =>
      DateFormat('yyyy-MM-dd HH:mm').format(d);

  static String dateOnly(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String dayLabel(DateTime d) => '${d.year}年${d.month}月${d.day}日';
}

/// 倒计时显示精度
enum CountdownPrecision { second, minute, hour }

extension CountdownPrecisionX on CountdownPrecision {
  String get label => switch (this) {
        CountdownPrecision.second => '秒',
        CountdownPrecision.minute => '分钟',
        CountdownPrecision.hour => '小时',
      };

  String get displayName => switch (this) {
        CountdownPrecision.second => '秒级',
        CountdownPrecision.minute => '分钟级',
        CountdownPrecision.hour => '小时级',
      };

  static CountdownPrecision fromString(String? s) {
    return switch (s) {
      'minute' => CountdownPrecision.minute,
      'hour' => CountdownPrecision.hour,
      _ => CountdownPrecision.second,
    };
  }
}

/// 格式化"距上次起飞"时长
String formatDuration(Duration d, CountdownPrecision p) {
  switch (p) {
    case CountdownPrecision.second:
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    case CountdownPrecision.minute:
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      return '$h:$m';
    case CountdownPrecision.hour:
      return '${d.inHours} 小时';
  }
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
