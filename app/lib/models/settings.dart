import '../utils/formatters.dart';

/// 用户设置
class AppSettings {
  final String precision; // 'second' | 'minute' | 'hour'
  final String effect; // 'plane' (旧字段，保留)
  final String effectEmoji; // 起飞粒子 emoji
  final String theme; // 'dark' (旧字段，保留)
  final List<String> quotes;

  const AppSettings({
    this.precision = 'second',
    this.effect = 'plane',
    this.effectEmoji = '✈️',
    this.theme = 'dark',
    this.quotes = const [
      '飞行是对天空的诗意探索。',
      '天空是飞行员的画布。',
      '每一次起飞都是一次冒险。',
    ],
  });

  CountdownPrecision get precisionEnum =>
      CountdownPrecisionX.fromString(precision);

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();
    var q = json['quotes'];
    List<String> quoteList;
    if (q is List) {
      quoteList = q.map((e) => e.toString()).toList();
    } else if (q is String) {
      // server 端存储用 '\\n' 分隔（老代码）
      quoteList = q.split('\\n').where((e) => e.isNotEmpty).toList();
    } else {
      quoteList = const [];
    }
    return AppSettings(
      precision: json['precision_setting'] as String? ?? 'second',
      effect: json['effect'] as String? ?? 'plane',
      effectEmoji: json['effectEmoji'] as String? ?? '✈️',
      theme: json['theme'] as String? ?? 'dark',
      quotes: quoteList.isEmpty
          ? const [
              '飞行是对天空的诗意探索。',
              '天空是飞行员的画布。',
              '每一次起飞都是一次冒险。',
            ]
          : quoteList,
    );
  }

  Map<String, dynamic> toJson() => {
        'precision': precision,
        'effect': effect,
        'theme': theme,
        'quotes': quotes,
      };

  AppSettings copyWith({
    String? precision,
    String? effect,
    String? effectEmoji,
    String? theme,
    List<String>? quotes,
  }) =>
      AppSettings(
        precision: precision ?? this.precision,
        effect: effect ?? this.effect,
        effectEmoji: effectEmoji ?? this.effectEmoji,
        theme: theme ?? this.theme,
        quotes: quotes ?? this.quotes,
      );
}

/// 排行榜上的用户条目
class LeaderboardEntry {
  final int id;
  final String account;
  final String nickname;
  final String avatar;
  final int count;

  const LeaderboardEntry({
    required this.id,
    required this.account,
    required this.nickname,
    required this.avatar,
    required this.count,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        account: json['username'] as String? ?? '',
        nickname: json['nickname'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '✈️',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

/// 管理员面板统计数据
class AdminStats {
  final int totalUsers;
  final int totalRecords;
  final int todayRecords;

  const AdminStats({
    required this.totalUsers,
    required this.totalRecords,
    required this.todayRecords,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
        totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
        todayRecords: (json['todayRecords'] as num?)?.toInt() ?? 0,
      );
}
