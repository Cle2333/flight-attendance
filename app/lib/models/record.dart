/// 一条本地起飞打卡记录。
///
/// 记录只存在于本机 SQLite，不再包含用户 ID、服务器 ID 或同步状态。
class FlightRecord {
  final int id;
  final DateTime time;
  final String note;
  final DateTime? createdAt;

  const FlightRecord({
    required this.id,
    required this.time,
    this.note = '',
    this.createdAt,
  });

  factory FlightRecord.fromDatabaseRow(Map<String, Object?> row) {
    return FlightRecord(
      id: (row['id'] as num).toInt(),
      time: DateTime.parse(row['event_time'] as String).toLocal(),
      note: row['note'] as String? ?? '',
      createdAt: row['created_at'] == null
          ? null
          : DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  factory FlightRecord.fromTransferJson(Map<String, dynamic> json) {
    final rawTime = json['time'] ?? json['event_time'];
    if (rawTime is! String || rawTime.isEmpty) {
      throw const FormatException('记录缺少有效的时间字段');
    }
    final parsedTime = DateTime.tryParse(rawTime);
    if (parsedTime == null) {
      throw FormatException('无法解析记录时间：$rawTime');
    }
    final rawCreatedAt = json['created_at'];
    return FlightRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      time: parsedTime.toLocal(),
      note: json['note'] as String? ?? '',
      createdAt: rawCreatedAt is String
          ? DateTime.tryParse(rawCreatedAt)?.toLocal()
          : null,
    );
  }

  Map<String, Object?> toDatabase() => {
    'event_time': time.toUtc().toIso8601String(),
    'note': note,
    'created_at': (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
  };

  Map<String, dynamic> toTransferJson() => {
    'time': time.toUtc().toIso8601String(),
    'note': note,
    if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
  };

  String get fingerprint => '${time.toUtc().toIso8601String()}\u0000$note';

  FlightRecord copyWith({
    int? id,
    DateTime? time,
    String? note,
    DateTime? createdAt,
  }) {
    return FlightRecord(
      id: id ?? this.id,
      time: time ?? this.time,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
