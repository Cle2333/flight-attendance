import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/profile.dart';
import '../models/record.dart';
import '../models/settings.dart';

class ImportSummary {
  final int added;
  final int skipped;

  const ImportSummary({required this.added, required this.skipped});
}

/// 本机 SQLite 数据访问层。所有业务数据均保存在这里。
class AppDatabase {
  static const databaseName = 'flight_attendance.db';
  static const _metaProfile = 'profile';
  static const _metaSettings = 'settings';
  static const _metaTheme = 'theme_mode';

  final Database _database;
  final String location;

  AppDatabase._(this._database, this.location);

  static Future<AppDatabase> open({String? path}) async {
    final databasePath = path ?? p.join(await getDatabasesPath(), databaseName);
    final database = await openDatabase(
      databasePath,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_time TEXT NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_records_event_time ON records(event_time DESC)',
        );
        await db.execute('''
          CREATE TABLE app_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return AppDatabase._(database, databasePath);
  }

  Future<List<FlightRecord>> loadRecords() async {
    final rows = await _database.query(
      'records',
      orderBy: 'event_time DESC, id DESC',
    );
    return rows.map(FlightRecord.fromDatabaseRow).toList();
  }

  Future<FlightRecord> insertRecord({
    required DateTime time,
    String note = '',
    DateTime? createdAt,
  }) async {
    final record = FlightRecord(
      id: 0,
      time: time,
      note: note,
      createdAt: createdAt ?? DateTime.now(),
    );
    final id = await _database.insert('records', record.toDatabase());
    return record.copyWith(id: id);
  }

  Future<void> updateRecord(
    int id, {
    required DateTime time,
    required String note,
  }) async {
    final changed = await _database.update(
      'records',
      {'event_time': time.toUtc().toIso8601String(), 'note': note},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed == 0) {
      throw StateError('要修改的记录不存在');
    }
  }

  Future<void> deleteRecord(int id) async {
    final changed = await _database.delete(
      'records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed == 0) {
      throw StateError('要删除的记录不存在');
    }
  }

  Future<ImportSummary> importRecords(Iterable<FlightRecord> records) async {
    final candidates = records.toList();
    if (candidates.isEmpty) {
      return const ImportSummary(added: 0, skipped: 0);
    }

    return _database.transaction((txn) async {
      final existingRows = await txn.query(
        'records',
        columns: ['event_time', 'note'],
      );
      final existing = existingRows.map((row) {
        final eventTime = DateTime.parse(
          row['event_time'] as String,
        ).toUtc().toIso8601String();
        return '$eventTime\u0000${row['note'] as String? ?? ''}';
      }).toSet();

      var added = 0;
      var skipped = 0;
      final batch = txn.batch();
      for (final record in candidates) {
        final fingerprint = record.fingerprint;
        if (!existing.add(fingerprint)) {
          skipped++;
          continue;
        }
        batch.insert(
          'records',
          FlightRecord(
            id: 0,
            time: record.time,
            note: record.note,
            createdAt: record.createdAt ?? DateTime.now(),
          ).toDatabase(),
        );
        added++;
      }
      if (added > 0) await batch.commit(noResult: true);
      return ImportSummary(added: added, skipped: skipped);
    });
  }

  Future<LocalProfile?> loadProfile() async {
    final value = await _readMeta(_metaProfile);
    if (value == null) return null;
    try {
      return LocalProfile.fromJson(_decodeMap(value));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(LocalProfile profile) =>
      _writeMeta(_metaProfile, jsonEncode(profile.toJson()));

  Future<AppSettings> loadSettings() async {
    final value = await _readMeta(_metaSettings);
    if (value == null) return const AppSettings();
    try {
      return AppSettings.fromJson(_decodeMap(value));
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) =>
      _writeMeta(_metaSettings, jsonEncode(settings.toJson()));

  Future<String?> loadThemeMode() => _readMeta(_metaTheme);

  Future<void> saveThemeMode(String themeMode) =>
      _writeMeta(_metaTheme, themeMode);

  Future<String?> getMeta(String key) => _readMeta(key);

  Future<void> setMeta(String key, String value) => _writeMeta(key, value);

  Future<String?> _readMeta(String key) async {
    final rows = await _database.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> _writeMeta(String key, String value) async {
    await _database.insert('app_meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() => _database.close();

  static Map<String, dynamic> _decodeMap(String value) =>
      jsonDecode(value) as Map<String, dynamic>;
}
