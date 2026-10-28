import 'dart:convert';

import '../models/record.dart';

class RecordImportIssue {
  final int itemNumber;
  final String message;

  const RecordImportIssue(this.itemNumber, this.message);
}

class RecordImportResult {
  final List<FlightRecord> records;
  final List<RecordImportIssue> issues;

  const RecordImportResult({required this.records, required this.issues});

  bool get hasRecords => records.isNotEmpty;
  bool get hasIssues => issues.isNotEmpty;
}

/// JSON 备份与 CSV 表格共用的编解码器。
class RecordTransfer {
  static const jsonFormat = 'flight-attendance-backup';
  static const formatVersion = 1;
  static const _timeKeys = [
    'time',
    'event_time',
    'timestamp',
    'takeoff_time',
    'created_at',
    'createdAt',
  ];
  static const _noteKeys = [
    'note',
    'remark',
    'feeling',
    'mood',
    'content',
    '备注',
    '感受',
  ];

  static String encodeJson(
    Iterable<FlightRecord> records, {
    DateTime? exportedAt,
  }) {
    final payload = {
      'format': jsonFormat,
      'version': formatVersion,
      'exported_at': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'records': records.map((record) => record.toTransferJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 严格解析：存在任何坏记录时直接失败，适合内部校验。
  static List<FlightRecord> decode(String content) {
    final result = decodeDetailed(content);
    if (result.issues.isNotEmpty) {
      final first = result.issues.first;
      throw FormatException('第 ${first.itemNumber} 条：${first.message}');
    }
    return result.records;
  }

  /// 宽松解析：保留可识别记录，并返回无法解析的条目。
  static RecordImportResult decodeDetailed(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('导入内容为空');
    }
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      return _decodeJsonDetailed(trimmed);
    }
    return _decodeCsvDetailed(trimmed);
  }

  static String encodeCsv(Iterable<FlightRecord> records) {
    final buffer = StringBuffer('time,note,created_at\r\n');
    for (final record in records) {
      final values = [
        record.time.toUtc().toIso8601String(),
        record.note,
        record.createdAt?.toUtc().toIso8601String() ?? '',
      ];
      buffer.writeln(values.map(_csvCell).join(','));
    }
    return buffer.toString();
  }

  static RecordImportResult _decodeJsonDetailed(String content) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const FormatException('JSON 格式不正确');
    }

    final rawRecords = _extractRecordList(decoded);
    if (rawRecords == null) {
      throw const FormatException('没有找到可导入的打卡记录数组');
    }

    final records = <FlightRecord>[];
    final issues = <RecordImportIssue>[];
    for (var i = 0; i < rawRecords.length; i++) {
      final item = rawRecords[i];
      if (item is! Map) {
        issues.add(RecordImportIssue(i + 1, '记录必须是对象'));
        continue;
      }
      try {
        records.add(_parseRecordMap(Map<String, dynamic>.from(item)));
      } catch (error) {
        issues.add(RecordImportIssue(i + 1, _errorMessage(error)));
      }
    }
    return RecordImportResult(records: records, issues: issues);
  }

  static List<dynamic>? _extractRecordList(dynamic value) {
    if (value is List) return value;
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    if (_looksLikeRecord(map)) return [map];

    for (final key in [
      'records',
      'data',
      'items',
      'checkins',
      'takeoffs',
      'localRecords',
    ]) {
      if (!map.containsKey(key)) continue;
      final nested = _extractRecordList(map[key]);
      if (nested != null) return nested;
    }
    return null;
  }

  static bool _looksLikeRecord(Map<String, dynamic> map) {
    return _timeKeys.any(map.containsKey);
  }

  static FlightRecord _parseRecordMap(Map<String, dynamic> map) {
    dynamic rawTime;
    for (final key in _timeKeys) {
      if (map[key] != null) {
        rawTime = map[key];
        break;
      }
    }
    final time = _parseDateTime(rawTime);
    if (time == null) {
      throw const FormatException('缺少有效时间');
    }

    String note = '';
    for (final key in _noteKeys) {
      if (map[key] != null) {
        note = map[key].toString().trim();
        break;
      }
    }
    final createdAt = _parseDateTime(map['created_at'] ?? map['createdAt']);

    return FlightRecord(id: 0, time: time, note: note, createdAt: createdAt);
  }

  /// 手动批量输入：每行一条，格式为 `YYYY-MM-DD HH:mm 备注`。
  static RecordImportResult decodeManualLines(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final records = <FlightRecord>[];
    final issues = <RecordImportIssue>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      try {
        records.add(_parseManualLine(line));
      } catch (error) {
        issues.add(RecordImportIssue(i + 1, _errorMessage(error)));
      }
    }
    return RecordImportResult(records: records, issues: issues);
  }

  static FlightRecord _parseManualLine(String line) {
    final match = RegExp(
      r'^\s*(\d{4}[-/]\d{1,2}[-/]\d{1,2})[\sT]+(\d{1,2}:\d{2}(?::\d{2})?)\s*(.*)$',
    ).firstMatch(line);
    if (match == null) {
      throw const FormatException('格式应为“YYYY-MM-DD HH:mm 备注”');
    }
    final date = match.group(1)!.replaceAll('/', '-');
    final time = match.group(2)!;
    final parsed = _parseManualDateTime(date, time);
    if (parsed == null) {
      throw const FormatException('日期或时间无效');
    }
    final note = match
        .group(3)!
        .trim()
        .replaceFirst(RegExp(r'^[|,，\t]+\s*'), '')
        .trim();
    return FlightRecord(id: 0, time: parsed, note: note);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is num) return _fromEpoch(value);
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final numeric = num.tryParse(text);
    if (numeric != null) return _fromEpoch(numeric);
    if (!_hasValidDatePrefix(text)) return null;
    final parsed = DateTime.tryParse(text);
    return parsed?.toLocal();
  }

  static DateTime? _parseManualDateTime(String date, String time) {
    final dateMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(date);
    final timeMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(time);
    if (dateMatch == null || timeMatch == null) return null;
    final year = int.parse(dateMatch.group(1)!);
    final month = int.parse(dateMatch.group(2)!);
    final day = int.parse(dateMatch.group(3)!);
    final hour = int.parse(timeMatch.group(1)!);
    final minute = int.parse(timeMatch.group(2)!);
    final second = int.tryParse(timeMatch.group(3) ?? '') ?? 0;
    if (!_isValidDateTimeParts(year, month, day, hour, minute, second)) {
      return null;
    }
    return DateTime(year, month, day, hour, minute, second);
  }

  static bool _hasValidDatePrefix(String text) {
    final match = RegExp(
      r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})(?:[T\s](\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    ).firstMatch(text);
    if (match == null) return true;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = int.tryParse(match.group(4) ?? '') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '') ?? 0;
    final second = int.tryParse(match.group(6) ?? '') ?? 0;
    return _isValidDateTimeParts(year, month, day, hour, minute, second);
  }

  static bool _isValidDateTimeParts(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
  ) {
    if (month < 1 || month > 12) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;
    if (second < 0 || second > 59) return false;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return day >= 1 && day <= daysInMonth;
  }

  static DateTime? _fromEpoch(num value) {
    final raw = value.toInt();
    if (raw.abs() >= 100000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch(raw).toLocal();
    }
    if (raw.abs() >= 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
    }
    if (raw.abs() >= 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000).toLocal();
    }
    return null;
  }

  static RecordImportResult _decodeCsvDetailed(String content) {
    final rows = _parseCsv(content);
    if (rows.isEmpty) throw const FormatException('CSV 文件为空');

    final header = rows.first
        .map((value) => value.trim().replaceFirst('\uFEFF', '').toLowerCase())
        .toList();
    int findColumn(List<String> aliases) {
      return header.indexWhere(aliases.contains);
    }

    final timeIndex = findColumn([
      'time',
      'event_time',
      'timestamp',
      'takeoff_time',
      '起飞时间',
      '时间',
    ]);
    final noteIndex = findColumn([
      'note',
      'remark',
      'feeling',
      'mood',
      'content',
      '备注',
      '感受',
    ]);
    final createdAtIndex = findColumn(['created_at', 'createdat']);
    if (timeIndex < 0) {
      throw const FormatException('CSV 缺少时间列');
    }

    final records = <FlightRecord>[];
    final issues = <RecordImportIssue>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((value) => value.trim().isEmpty)) continue;
      try {
        if (timeIndex >= row.length) {
          throw const FormatException('缺少时间');
        }
        records.add(
          _parseRecordMap({
            'time': row[timeIndex],
            if (noteIndex >= 0 && noteIndex < row.length)
              'note': row[noteIndex],
            if (createdAtIndex >= 0 && createdAtIndex < row.length)
              'created_at': row[createdAtIndex],
          }),
        );
      } catch (error) {
        issues.add(RecordImportIssue(i + 1, _errorMessage(error)));
      }
    }
    return RecordImportResult(records: records, issues: issues);
  }

  static List<List<String>> _parseCsv(String content) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '"') {
        if (inQuotes && i + 1 < content.length && content[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(field.toString());
        field.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else {
        field.write(char);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    if (inQuotes) throw const FormatException('CSV 引号没有闭合');
    return rows;
  }

  static String _errorMessage(Object error) {
    if (error is FormatException) return error.message;
    return '无法解析记录';
  }

  static String _csvCell(String value) {
    if (!value.contains(RegExp(r'[",\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
