import '../utils/formatters.dart';

/// 本地偏好设置。
class AppSettings {
  final String precision; // 'second' | 'minute' | 'hour'
  final String effectEmoji;
  final List<String> quotes;

  const AppSettings({
    this.precision = 'second',
    this.effectEmoji = '✈️',
    this.quotes = const ['飞行是对天空的诗意探索。', '天空是飞行员的画布。', '每一次起飞都是一次冒险。'],
  });

  CountdownPrecision get precisionEnum =>
      CountdownPrecisionX.fromString(precision);

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();
    final rawQuotes = json['quotes'];
    List<String> quoteList;
    if (rawQuotes is List) {
      quoteList = rawQuotes.map((e) => e.toString()).toList();
    } else if (rawQuotes is String) {
      quoteList = rawQuotes.split('\\n').where((e) => e.isNotEmpty).toList();
    } else {
      quoteList = const [];
    }
    return AppSettings(
      precision:
          (json['precision'] ?? json['precision_setting']) as String? ??
          'second',
      effectEmoji: json['effectEmoji'] as String? ?? '✈️',
      quotes: quoteList.isEmpty
          ? const ['飞行是对天空的诗意探索。', '天空是飞行员的画布。', '每一次起飞都是一次冒险。']
          : quoteList,
    );
  }

  Map<String, dynamic> toJson() => {
    'precision': precision,
    'effectEmoji': effectEmoji,
    'quotes': quotes,
  };

  AppSettings copyWith({
    String? precision,
    String? effectEmoji,
    List<String>? quotes,
  }) {
    return AppSettings(
      precision: precision ?? this.precision,
      effectEmoji: effectEmoji ?? this.effectEmoji,
      quotes: quotes ?? this.quotes,
    );
  }
}
