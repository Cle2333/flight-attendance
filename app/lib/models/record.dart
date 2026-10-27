/// 一次"起飞"打卡
class FlightRecord {
  final int id;
  final int userId;
  final DateTime time;
  final String note;
  final DateTime? createdAt;

  /// 云端 id —— null 表示这条记录还没同步到服务器
  /// (本地模式创建，或者云端模式刚起飞但 POST 还没返回)。
  /// 有值时就用这个 id 去 PUT/DELETE 服务器，不要用 [id]。
  final int? serverId;

  const FlightRecord({
    required this.id,
    required this.userId,
    required this.time,
    this.note = '',
    this.createdAt,
    this.serverId,
  });

  FlightRecord copyWith({
    int? id,
    int? userId,
    DateTime? time,
    String? note,
    DateTime? createdAt,
    int? serverId,
  }) {
    return FlightRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      time: time ?? this.time,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      serverId: serverId ?? this.serverId,
    );
  }

  factory FlightRecord.fromJson(Map<String, dynamic> json) => FlightRecord(
        id: (json['id'] as num?)?.toInt() ?? 0,
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        time: DateTime.parse(json['time'] as String).toLocal(),
        note: json['note'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String).toLocal()
            : null,
        // 服务器数据本身就有真实 id，serverId == id
        serverId: (json['id'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'time': time.toUtc().toIso8601String(),
        'note': note,
        if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
        if (serverId != null) 'server_id': serverId,
      };
}
