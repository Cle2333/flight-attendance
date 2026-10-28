import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flight_attendance_app/data/app_database.dart';
import 'package:flight_attendance_app/data/database_factory.dart';
import 'package:flight_attendance_app/data/legacy_migration.dart';
import 'package:flight_attendance_app/services/avatar_service.dart';
import 'package:flight_attendance_app/data/record_transfer.dart';
import 'package:flight_attendance_app/models/profile.dart';
import 'package:flight_attendance_app/models/record.dart';
import 'package:flight_attendance_app/models/settings.dart';
import 'package:flight_attendance_app/state/app_state.dart';

void main() {
  setUpAll(initializeDatabaseFactory);

  late AppDatabase database;

  setUp(() async {
    database = await AppDatabase.open(path: ':memory:');
  });

  tearDown(() => database.close());

  test('SQLite 记录增改删可持久化', () async {
    final inserted = await database.insertRecord(
      time: DateTime(2026, 10, 27, 9, 10),
      note: '第一次',
    );
    await database.updateRecord(
      inserted.id,
      time: DateTime(2026, 10, 27, 10, 20),
      note: '改过时间',
    );

    final loaded = await database.loadRecords();
    expect(loaded.length, 1);
    expect(loaded.single.note, '改过时间');
    expect(loaded.single.time, DateTime(2026, 10, 27, 10, 20));

    await database.deleteRecord(inserted.id);
    expect(await database.loadRecords(), isEmpty);
  });

  test('导入按时间和备注去重', () async {
    final original = FlightRecord(
      id: 0,
      time: DateTime(2026, 10, 27, 9, 10),
      note: '重复记录',
    );
    final first = await database.importRecords([original]);
    final second = await database.importRecords([original]);

    expect(first.added, 1);
    expect(second.added, 0);
    expect(second.skipped, 1);
    expect((await database.loadRecords()).length, 1);
  });

  test('资料、设置和主题写入 app_meta', () async {
    await database.saveProfile(
      const LocalProfile(nickname: '机长', avatarPath: 'C:/avatars/pilot.png'),
    );
    await database.saveSettings(
      const AppSettings(precision: 'minute', effectEmoji: '🚀'),
    );
    await database.saveThemeMode('dark');

    final profile = await database.loadProfile();
    expect(profile!.nickname, '机长');
    expect(profile.avatarPath, 'C:/avatars/pilot.png');
    expect((await database.loadSettings()).precision, 'minute');
    expect(await database.loadThemeMode(), 'dark');
  });

  test('修改较旧记录为最新时间后，lastTakeoff 立即同步', () async {
    final state = AppState(database: database);
    await state.bootstrap();
    final older = await state.addRecordAt(
      DateTime(2026, 10, 27, 8),
      note: '较早',
    );
    final newer = await state.addRecordAt(
      DateTime(2026, 10, 27, 9),
      note: '较新',
    );

    expect(state.lastTakeoff.value, newer.time);

    final editedTime = DateTime(2026, 10, 27, 10, 30);
    await state.updateRecord(older.id, editedTime, '改到最新');

    expect(state.lastTakeoff.value, editedTime);
    expect(state.records.first.id, older.id);
    expect(state.records.first.note, '改到最新');

    await state.deleteRecord(older.id);
    expect(state.lastTakeoff.value, newer.time);
  });

  test('旧版本地缓存迁移到 SQLite 并移除联网凭据', () async {
    SharedPreferences.setMockInitialValues({
      'localRecords': jsonEncode([
        {
          'id': 1,
          'user_id': 0,
          'time': '2026-10-27T08:30:15.000Z',
          'note': '旧记录',
        },
      ]),
      'localUser': jsonEncode({'nickname': '老机长', 'avatar': '🧑‍✈️'}),
      'localSettings': jsonEncode({
        'precision': 'minute',
        'effectEmoji': '🚀',
        'quotes': ['旧语录'],
      }),
      'token': 'legacy-token-value',
      'refreshToken': 'legacy-refresh-token',
      'baseUrl': 'https://old.example.com',
      'localMode': true,
    });

    final result = await LegacyMigration.run(database);
    final prefs = await SharedPreferences.getInstance();

    expect(result.importSummary.added, 1);
    expect((await database.loadRecords()).single.note, '旧记录');
    expect((await database.loadProfile())!.nickname, '老机长');
    expect((await database.loadSettings()).precision, 'minute');
    expect(prefs.getString('token'), isNull);
    expect(prefs.getString('refreshToken'), isNull);
    expect(prefs.getString('baseUrl'), isNull);

    await LegacyMigration.run(database);
    expect((await database.loadRecords()).length, 1);
  });

  test('取消头像选择不写入资料', () async {
    final state = AppState(
      database: database,
      avatarService: _CancelAvatarService(),
    );
    await state.bootstrap();
    final before = state.profile.value!.avatarPath;

    final result = await state.chooseAvatar();

    expect(result, isNull);
    expect(state.profile.value!.avatarPath, before);
    expect(state.avatarDisplayPath.value, isNull);
  });

  test('头像落库保存相对路径并解析为展示路径', () async {
    final state = AppState(
      database: database,
      avatarService: _ResultAvatarService(),
    );
    await state.bootstrap();

    final displayPath = await state.chooseAvatar();

    expect(displayPath, 'C:/app-data/avatars/new.png');
    expect(state.profile.value!.avatarPath, 'avatars/new.png');
    expect(state.avatarDisplayPath.value, displayPath);
    expect((await database.loadProfile())!.avatarPath, 'avatars/new.png');
  });

  test('导入后立即刷新记录和倒计时', () async {
    final state = AppState(database: database);
    await state.bootstrap();
    final imported = FlightRecord(
      id: 0,
      time: DateTime(2026, 10, 27, 12),
      note: '导入记录',
    );

    final summary = await state.importRecords([imported]);

    expect(summary.added, 1);
    expect(state.records.single.note, '导入记录');
    expect(state.lastTakeoff.value, imported.time);
    expect(RecordTransfer.encodeJson(state.records), contains('导入记录'));
  });
}

class _CancelAvatarService extends AvatarService {
  @override
  Future<String?> pickAndStore() async => null;
}

class _ResultAvatarService extends AvatarService {
  @override
  Future<String?> pickAndStore() async => 'avatars/new.png';

  @override
  Future<String> resolvePath(String storedPath) async =>
      'C:/app-data/$storedPath';

  @override
  Future<void> deleteManagedFile(String? storedPath) async {}
}
