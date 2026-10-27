import 'package:flutter/material.dart' show ThemeMode;
import 'package:get/get.dart';

import '../data/app_database.dart';
import '../models/profile.dart';
import '../models/record.dart';
import '../models/record_statistics.dart';
import '../models/settings.dart';
import '../services/record_file_service.dart';

/// 纯本地应用状态。所有写操作先落 SQLite，再同步内存状态。
class AppState extends GetxController {
  final AppDatabase database;
  final RecordFileService fileService;

  AppState({required this.database, RecordFileService? fileService})
    : fileService = fileService ?? RecordFileService();

  final RxBool booted = false.obs;
  final Rxn<String> startupError = Rxn<String>();
  final Rxn<LocalProfile> profile = Rxn<LocalProfile>();
  final RxList<FlightRecord> records = <FlightRecord>[].obs;
  final Rx<AppSettings> settings = const AppSettings().obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rxn<DateTime> lastTakeoff = Rxn<DateTime>();

  Future<void> bootstrap() async {
    try {
      final loadedProfile = await database.loadProfile();
      profile.value = loadedProfile ?? const LocalProfile();
      if (loadedProfile == null) {
        await database.saveProfile(profile.value!);
      }
      settings.value = await database.loadSettings();
      themeMode.value = _themeModeFromString(await database.loadThemeMode());
      await reloadRecords();
    } catch (error) {
      startupError.value = '本地数据库初始化失败：$error';
    } finally {
      booted.value = true;
    }
  }

  Future<void> reloadRecords() async {
    records.assignAll(await database.loadRecords());
    _sortRecords();
    _recomputeLastTakeoff();
  }

  Future<FlightRecord> takeOff() => addRecordAt(DateTime.now());

  /// 供测试与数据恢复使用；正常打卡走 [takeOff]。
  Future<FlightRecord> addRecordAt(DateTime time, {String note = ''}) async {
    final record = await database.insertRecord(time: time, note: note);
    records.add(record);
    _sortRecords();
    _recomputeLastTakeoff();
    return record;
  }

  Future<void> updateRecord(int id, DateTime time, String note) async {
    await database.updateRecord(id, time: time, note: note);
    final index = records.indexWhere((record) => record.id == id);
    if (index >= 0) {
      records[index] = records[index].copyWith(time: time, note: note);
      _sortRecords();
    }
    // 修改时间后必须立即重算；这是倒计时不刷新的根因修复点。
    _recomputeLastTakeoff();
  }

  Future<void> setLastRecordNote(String note) async {
    if (records.isEmpty) return;
    final latest = records.first;
    await updateRecord(latest.id, latest.time, note);
  }

  Future<void> deleteRecord(int id) async {
    await database.deleteRecord(id);
    records.removeWhere((record) => record.id == id);
    _recomputeLastTakeoff();
  }

  Future<ImportSummary> importRecords(Iterable<FlightRecord> incoming) async {
    final summary = await database.importRecords(incoming);
    await reloadRecords();
    return summary;
  }

  Future<void> updatePrecision(String precision) async {
    settings.value = settings.value.copyWith(precision: precision);
    await database.saveSettings(settings.value);
  }

  Future<void> updateEffectEmoji(String emoji) async {
    settings.value = settings.value.copyWith(effectEmoji: emoji);
    await database.saveSettings(settings.value);
  }

  Future<void> updateQuotes(List<String> quotes) async {
    settings.value = settings.value.copyWith(quotes: quotes);
    await database.saveSettings(settings.value);
  }

  Future<void> updateNickname(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) return;
    final updated = (profile.value ?? const LocalProfile()).copyWith(
      nickname: trimmed,
    );
    profile.value = updated;
    await database.saveProfile(updated);
  }

  Future<void> updateAvatar(String avatar) async {
    if (avatar.trim().isEmpty) return;
    final updated = (profile.value ?? const LocalProfile()).copyWith(
      avatar: avatar,
    );
    profile.value = updated;
    await database.saveProfile(updated);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await database.saveThemeMode(mode.name);
  }

  int get totalRecords => records.length;

  int get currentStreak => RecordStatistics.currentStreak(records);

  int get longestStreak => RecordStatistics.longestStreak(records);

  AverageClockTime? get averageTakeoffTime =>
      RecordStatistics.averageClockTime(records.map((record) => record.time));

  MonthlyReport monthlyReport(DateTime month) =>
      RecordStatistics.monthlyReport(records, month);

  List<Achievement> get achievements => RecordStatistics.achievements(
    totalRecords: totalRecords,
    longestStreak: longestStreak,
  );

  int get badges => achievements.where((item) => item.unlocked).length;

  bool hasRecordOn(DateTime day) => records.any(
    (record) =>
        record.time.year == day.year &&
        record.time.month == day.month &&
        record.time.day == day.day,
  );

  void _sortRecords() {
    records.sort((a, b) {
      final byTime = b.time.compareTo(a.time);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
  }

  void _recomputeLastTakeoff() {
    DateTime? latest;
    for (final record in records) {
      if (latest == null || record.time.isAfter(latest)) {
        latest = record.time;
      }
    }
    lastTakeoff.value = latest;
  }

  ThemeMode _themeModeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
