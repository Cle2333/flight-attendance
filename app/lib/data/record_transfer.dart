import 'dart:convert';

import '../models/record.dart';

/// JSON 备份与 CSV 表格共用的编解码器。
class RecordTransfer {
  static const jsonFormat = 'flight-attendance-backup';
  static const formatVersion = 1;

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

  static List<FlightRecord> decode(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('文件内容为空');
    }
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      return _decodeJson(trimmed);
    }
    return _decodeCsv(trimmed);
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

  static List<FlightRecord> _decodeJson(String content) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const FormatException('JSON 格式不正确');
    }

    List<dynamic> rawRecords;
    if (decoded is List) {
      rawRecords = decoded;
    } else if (decoded is Map && decoded['records'] is List) {
      rawRecords = decoded['records'] as List;
    } else {
      throw const FormatException('JSON 中没有找到 records 数组');
    }

    return rawRecords.map((item) {
      if (item is! Map) {
        throw const FormatException('JSON 记录必须是对象');
      }
      return FlightRecord.fromTransferJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  static List<FlightRecord> _decodeCsv(String content) {
    final rows = _parseCsv(content);
    if (rows.isEmpty) throw const FormatException('CSV 文件为空');

    final header = rows.first
        .map((value) => value.trim().replaceFirst('\uFEFF', '').toLowerCase())
        .toList();
    final timeIndex = header.indexOf('time');
    final noteIndex = header.indexOf('note');
    final createdAtIndex = header.indexOf('created_at');
    if (timeIndex < 0) {
      throw const FormatException('CSV 缺少 time 列');
    }

    final records = <FlightRecord>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((value) => value.trim().isEmpty)) continue;
      if (timeIndex >= row.length) {
        throw FormatException('CSV 第 ${i + 1} 行缺少时间');
      }
      final json = <String, dynamic>{
        'time': row[timeIndex],
        if (noteIndex >= 0 && noteIndex < row.length) 'note': row[noteIndex],
        if (createdAtIndex >= 0 && createdAtIndex < row.length)
          'created_at': row[createdAtIndex],
      };
      records.add(FlightRecord.fromTransferJson(json));
    }
    return records;
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

  static String _csvCell(String value) {
    if (!value.contains(RegExp(r'[",\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
