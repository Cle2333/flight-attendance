import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';
import '../models/record.dart';
import '../models/settings.dart';
import 'app_database.dart';

class LegacyMigrationResult {
  final ImportSummary importSummary;
  final bool profileMigrated;
  final bool settingsMigrated;

  const LegacyMigrationResult({
    required this.importSummary,
    required this.profileMigrated,
    required this.settingsMigrated,
  });

  static const empty = LegacyMigrationResult(
    importSummary: ImportSummary(added: 0, skipped: 0),
    profileMigrated: false,
    settingsMigrated: false,
  );
}

/// 把旧版 SharedPreferences 中的记录/资料/设置一次性迁入 SQLite。
///
/// 迁移不会删除旧记录；但会立即移除历史 token、刷新 token 和服务器地址，
/// 避免纯本地版本继续保留联网凭据。
class LegacyMigration {
  static const _flagKey = 'legacy_migration_v1';
  static const _doneValue = 'done';

  static Future<LegacyMigrationResult> run(AppDatabase database) async {
    if (await database.getMeta(_flagKey) == _doneValue) {
      return LegacyMigrationResult.empty;
    }

    final prefs = await SharedPreferences.getInstance();
    final records = _readRecords(prefs);
    final summary = await database.importRecords(records);

    var profileMigrated = false;
    if (await database.loadProfile() == null) {
      final profile = _readProfile(prefs);
      if (profile != null) {
        await database.saveProfile(profile);
        profileMigrated = true;
      }
    }

    var settingsMigrated = false;
    final rawSettings = prefs.getString('localSettings');
    if (rawSettings != null) {
      try {
        final json = jsonDecode(rawSettings) as Map<String, dynamic>;
        await database.saveSettings(AppSettings.fromJson(json));
        settingsMigrated = true;
      } catch (_) {
        // 坏数据不阻塞启动。
      }
    }

    await database.setMeta(_flagKey, _doneValue);
    for (final key in ['token', 'refreshToken', 'baseUrl', 'localMode']) {
      await prefs.remove(key);
    }

    return LegacyMigrationResult(
      importSummary: summary,
      profileMigrated: profileMigrated,
      settingsMigrated: settingsMigrated,
    );
  }

  static List<FlightRecord> _readRecords(SharedPreferences prefs) {
    final raw = prefs.getString('localRecords');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                FlightRecord.fromTransferJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static LocalProfile? _readProfile(SharedPreferences prefs) {
    for (final key in ['localUser', 'user']) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return LocalProfile.fromJson(json);
      } catch (_) {
        // 尝试下一个旧 key。
      }
    }
    return null;
  }
}
