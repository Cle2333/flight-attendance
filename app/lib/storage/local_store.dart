import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/record.dart';
import '../models/settings.dart';
import '../models/user.dart';

/// 本地存储：本地模式 + 持久 token
class LocalStore {
  static const _kToken = 'token';
  static const _kRefreshToken = 'refreshToken';
  static const _kUser = 'user';
  static const _kLocalMode = 'localMode';
  static const _kLocalRecords = 'localRecords';
  static const _kLocalSettings = 'localSettings';
  static const _kLocalUser = 'localUser';
  static const _kLastTakeoff = 'lastTakeoff';
  static const _kBaseUrl = 'baseUrl';

  final SharedPreferences _prefs;
  LocalStore(this._prefs);

  static Future<LocalStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStore(prefs);
  }

  // ====== 基础 ======
  String? getToken() => _prefs.getString(_kToken);
  Future<void> setToken(String? t) async {
    if (t == null) {
      await _prefs.remove(_kToken);
    } else {
      await _prefs.setString(_kToken, t);
    }
  }

  String? getRefreshToken() => _prefs.getString(_kRefreshToken);
  Future<void> setRefreshToken(String? t) async {
    if (t == null) {
      await _prefs.remove(_kRefreshToken);
    } else {
      await _prefs.setString(_kRefreshToken, t);
    }
  }

  bool isLocalMode() => _prefs.getBool(_kLocalMode) ?? false;
  Future<void> setLocalMode(bool v) => _prefs.setBool(_kLocalMode, v);

  AppUser? getUser() {
    final s = _prefs.getString(_kUser);
    if (s == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setUser(AppUser? u) async {
    if (u == null) {
      await _prefs.remove(_kUser);
    } else {
      await _prefs.setString(_kUser, jsonEncode(u.toJson()));
    }
  }

  String? getBaseUrl() => _prefs.getString(_kBaseUrl);
  Future<void> setBaseUrl(String url) => _prefs.setString(_kBaseUrl, url);

  // ====== 本地模式数据 ======
  List<FlightRecord> getLocalRecords() {
    final s = _prefs.getString(_kLocalRecords);
    if (s == null) return [];
    try {
      final list = jsonDecode(s) as List;
      return list
          .map((e) => FlightRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setLocalRecords(List<FlightRecord> rs) async {
    final list = rs.map((r) => r.toJson()).toList();
    await _prefs.setString(_kLocalRecords, jsonEncode(list));
  }

  AppSettings getLocalSettings() {
    final s = _prefs.getString(_kLocalSettings);
    if (s == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> setLocalSettings(AppSettings s) async {
    await _prefs.setString(_kLocalSettings, jsonEncode(s.toJson()));
  }

  Future<void> setLocalUser(AppUser u) async {
    await _prefs.setString(_kLocalUser, jsonEncode(u.toJson()));
    await setUser(u);
  }

  AppUser? getLocalUser() {
    final s = _prefs.getString(_kLocalUser);
    if (s == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  DateTime? getLastTakeoff() {
    final s = _prefs.getString(_kLastTakeoff);
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  Future<void> setLastTakeoff(DateTime? t) async {
    if (t == null) {
      await _prefs.remove(_kLastTakeoff);
    } else {
      await _prefs.setString(_kLastTakeoff, t.toUtc().toIso8601String());
    }
  }

  /// 退出本地模式时清空所有本地数据
  Future<void> clearLocal() async {
    await _prefs.remove(_kLocalRecords);
    await _prefs.remove(_kLocalSettings);
    await _prefs.remove(_kLocalUser);
    await _prefs.remove(_kLastTakeoff);
    await _prefs.remove(_kLocalMode);
  }
}
