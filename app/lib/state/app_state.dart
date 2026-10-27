import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/api_client.dart' show ApiClient;
import '../api/api_exception.dart';
import '../models/record.dart';
import '../models/settings.dart';
import '../models/user.dart';
import '../storage/local_store.dart';

/// 全局应用状态。GetX 注入。
///
/// **离线优先**：只要本地有缓存的 token/user，server 暂时挂掉时：
///  - App 仍然能打开（不黑屏）
///  - records / settings 显示本地缓存
///  - 起飞 / 改设置 / 改记录 都本地保存 + banner 提示
///  - server 恢复后用户手动点"重试"或下一次刷新时回到在线模式
class AppState extends GetxController {
  final LocalStore store;
  final ApiClient api;

  AppState({required this.store, required this.api});

  // ====== 会话 ======
  final RxBool isLocalMode = false.obs;

  /// 用户**手动选了"本地模式"**（设置页里切换）—— 不会因为网络问题自动切
  final RxBool isManualLocalMode = false.obs;

  /// 网络不可达导致暂时离线（与 isLocalMode 正交）
  final RxBool offline = false.obs;

  final Rxn<AppUser> currentUser = Rxn<AppUser>();
  final RxBool booted = false.obs;

  // ====== 数据 ======
  final RxList<FlightRecord> records = <FlightRecord>[].obs;
  final Rx<AppSettings> settings = const AppSettings().obs;

  // ====== 起飞 ======
  final Rxn<DateTime> lastTakeoff = Rxn<DateTime>();

  // ====== 主题 ======
  /// 主题模式 —— light / dark / system
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  void setThemeMode(ThemeMode m) {
    themeMode.value = m;
  }

  /// 应用启动 —— 不抛异常，永远完成
  Future<void> bootstrap() async {
    isManualLocalMode.value = store.isLocalMode();
    isLocalMode.value = isManualLocalMode.value;
    api.setToken(store.getToken());

    if (isLocalMode.value) {
      // 用户上次明确选了本地模式：纯本地，不碰网络
      _hydrateFromLocal();
    } else {
      // 上次在线：先把本地缓存填上让 UI 立刻有东西看，再后台尝试刷新
      final cachedUser = store.getUser();
      final cachedSettings = store.getLocalSettings();
      if (cachedUser != null) {
        currentUser.value = cachedUser;
        records.assignAll(store.getLocalRecords());
        settings.value = cachedSettings;
        lastTakeoff.value = store.getLastTakeoff() ??
            (records.isNotEmpty
                ? records
                    .map((r) => r.time)
                    .reduce((a, b) => a.isAfter(b) ? a : b)
                : null);
      }
      // 后台刷新 —— 失败仅打日志 + 设置 offline 标志
      await _safeRefresh();
    }
    booted.value = true;
  }

  /// 后台拉取最新数据。**永不抛异常**。失败置 offline=true。
  Future<void> _safeRefresh() async {
    if (currentUser.value == null) return; // 没登录用户就不请求
    try {
      await refreshAll();
      offline.value = false;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // token 失效 —— 清登录态让用户重新登录
        await api.logout();
        currentUser.value = null;
        offline.value = false;
      } else {
        // 其他（网络/5xx/超时）→ 离线 + 保留本地缓存
        offline.value = true;
      }
    } catch (_) {
      offline.value = true;
    }
  }

  /// 从本地 SharedPreferences 装填 UI（纯本地模式用）
  void _hydrateFromLocal() {
    currentUser.value = store.getLocalUser() ??
        const AppUser(id: 0, account: 'local', nickname: '本地用户', avatar: '✈️');
    records.assignAll(store.getLocalRecords());
    settings.value = store.getLocalSettings();
    lastTakeoff.value = store.getLastTakeoff() ??
        (records.isNotEmpty
            ? records.map((r) => r.time).reduce((a, b) => a.isAfter(b) ? a : b)
            : null);
  }

  /// 显式拉取最新（用户下拉刷新 / "重试连接"按钮）
  Future<void> refreshAll() async {
    final user = await api.getUserProfile();
    currentUser.value = user;
    await store.setUser(user);
    final fetched = await api.getRecords();
    records.assignAll(fetched);
    // 同步一份到本地缓存（断网时还能看）
    await store.setLocalRecords(fetched);
    final s = await api.getSettings();
    settings.value = s;
    await store.setLocalSettings(s);
    if (records.isNotEmpty) {
      lastTakeoff.value =
          records.map((r) => r.time).reduce((a, b) => a.isAfter(b) ? a : b);
      await store.setLastTakeoff(lastTakeoff.value);
    } else {
      lastTakeoff.value = null;
      await store.setLastTakeoff(null);
    }
    offline.value = false;
  }

  /// 用户主动重试连接（顶栏 banner 里的"重试"按钮）
  Future<bool> retryConnection() async {
    if (isLocalMode.value) {
      // 手动本地模式不重试
      return false;
    }
    await _safeRefresh();
    return !offline.value;
  }

  // ====== 认证 ======
  Future<void> login(String account, String password) async {
    final u = await api.login(account, password);
    isLocalMode.value = false;
    isManualLocalMode.value = false;
    await store.setLocalMode(false);
    currentUser.value = u;
    await refreshAll();
    offline.value = false;
  }

  Future<void> register(String account, String password, String nickname) async {
    final u = await api.register(account, password, nickname);
    isLocalMode.value = false;
    isManualLocalMode.value = false;
    await store.setLocalMode(false);
    currentUser.value = u;
    await refreshAll();
    offline.value = false;
  }

  Future<void> enterLocalMode() async {
    isLocalMode.value = true;
    isManualLocalMode.value = true;
    await store.setLocalMode(true);
    offline.value = false;
    final u = store.getLocalUser() ??
        const AppUser(id: 0, account: 'local', nickname: '本地用户', avatar: '✈️');
    currentUser.value = u;
    await store.setUser(u);
    await store.setLocalUser(u);
    _hydrateFromLocal();
  }

  Future<void> logout() async {
    if (isLocalMode.value) {
      await store.clearLocal();
      records.clear();
      settings.value = const AppSettings();
      lastTakeoff.value = null;
      currentUser.value = null;
      isLocalMode.value = false;
      isManualLocalMode.value = false;
      offline.value = false;
    } else {
      await api.logout();
      records.clear();
      settings.value = const AppSettings();
      lastTakeoff.value = null;
      currentUser.value = null;
      offline.value = false;
    }
  }

  Future<void> switchMode() async {
    if (isLocalMode.value) {
      await logout();
    } else {
      await enterLocalMode();
    }
  }

  // ====== 起飞 ======
  /// 用户在 sync 完成前就点了「完成」加备注的现场。
  /// 存住 localId → note，等 [takeOff] 那条 sync 返回 serverId 后补发 PUT。
  /// 只有在云端模式下有意义，本地模式不会走 sync。
  final Map<int, String> _pendingNotesByLocalId = {};

  /// 双击起飞。乐观更新：立刻本地插入一条 record(返回给调用方进行 UI 反馈)，
  /// 云端同步放到后台，不阻塞前台交互。
  Future<FlightRecord> takeOff() async {
    final now = DateTime.now();
    // 1. 先本地插入 —— UI 立刻拿到 record，粒子/成功提示正常触发
    final record = _takeOffLocal(now);

    // 2. 后台同步到服务器
    if (!isLocalMode.value) {
      unawaited(_syncRecordToCloud(record));
    }

    return record;
  }

  /// 后台同步单条记录到服务器。成功后将 serverId 写回 record，
  /// 顺带补发用户在 sync 完成前设的 pending note。
  Future<void> _syncRecordToCloud(FlightRecord local) async {
    try {
      final serverId = await api.addRecord(local.time, '');
      // 在 records 里找到那条 local-id 的记录，写上 serverId
      final idx = records.indexWhere((r) => r.id == local.id);
      if (idx >= 0) {
        final old = records[idx];
        final synced = old.copyWith(serverId: serverId);
        records[idx] = synced;
        // fire-and-forget 持久化
        store.setLocalRecords(records);

        // 如果用户在 sync 期间已经加了备注，补发 PUT
        final pendingNote = _pendingNotesByLocalId.remove(local.id);
        if (pendingNote != null && pendingNote != synced.note) {
          unawaited(_syncNoteToCloud(serverId, synced.time, pendingNote));
        }
      }
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 500) {
        offline.value = true;
      }
      // 4xx 不当作离线(请求本身有问题)
    } catch (_) {
      offline.value = true;
    }
  }

  FlightRecord _takeOffLocal(DateTime now) {
    final id = records.isEmpty
        ? 1
        : records.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
    final r = FlightRecord(id: id, userId: 0, time: now);
    records.add(r);
    store.setLocalRecords(records); // fire-and-forget 持久化
    lastTakeoff.value = now;
    store.setLastTakeoff(now);
    return r;
  }

  /// 设置最后一条记录的备注。乐观更新：本地立刻更新 + 立即返回，
  /// 云端同步放到后台，不阻塞 overlay 关闭。
  Future<void> setLastRecordNote(String note) async {
    if (records.isEmpty) return;
    final idx = records.length - 1;
    final last = records[idx];

    // 1. 本地先更新
    _updateRecordLocal(idx, note);

    // 2. 后台同步到服务器
    if (isLocalMode.value) return;
    if (last.serverId != null) {
      // 早已同步过，直接 PUT
      unawaited(_syncNoteToCloud(last.serverId!, last.time, note));
    } else {
      // 还没 sync 完成 —— 记录下来，等 [_syncRecordToCloud] 拿到 serverId 后补发
      _pendingNotesByLocalId[last.id] = note;
    }
  }

  Future<void> _syncNoteToCloud(int serverRecordId, DateTime time, String note) async {
    try {
      await api.updateRecord(serverRecordId, time, note);
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 500) {
        offline.value = true;
      }
    } catch (_) {
      offline.value = true;
    }
  }

  void _updateRecordLocal(int idx, String note) {
    final r = records[idx];
    records[idx] = r.copyWith(note: note);
    store.setLocalRecords(records);
  }

  // ====== 设置 ======
  Future<void> updatePrecision(String p) async {
    settings.value = settings.value.copyWith(precision: p);
    if (isLocalMode.value) {
      await store.setLocalSettings(settings.value);
      return;
    }
    try {
      await api.updateSettings(precision: p);
      await store.setLocalSettings(settings.value);
    } catch (_) {
      offline.value = true;
      await store.setLocalSettings(settings.value);
    }
  }

  Future<void> updateEffectEmoji(String e) async {
    settings.value = settings.value.copyWith(effectEmoji: e);
    if (isLocalMode.value) {
      await store.setLocalSettings(settings.value);
      return;
    }
    try {
      await api.updateSettings(effectEmoji: e);
      await store.setLocalSettings(settings.value);
    } catch (_) {
      offline.value = true;
      await store.setLocalSettings(settings.value);
    }
  }

  Future<void> updateQuotes(List<String> quotes) async {
    settings.value = settings.value.copyWith(quotes: quotes);
    if (isLocalMode.value) {
      await store.setLocalSettings(settings.value);
      return;
    }
    try {
      await api.updateSettings(quotes: quotes);
      await store.setLocalSettings(settings.value);
    } catch (_) {
      offline.value = true;
      await store.setLocalSettings(settings.value);
    }
  }

  // ====== 用户 ======
  Future<void> updateNickname(String nickname) async {
    final updated = currentUser.value?.copyWith(nickname: nickname);
    currentUser.value = updated;
    if (updated != null) {
      await store.setUser(updated);
      if (isLocalMode.value) {
        await store.setLocalUser(updated);
        return;
      }
    }
    if (isLocalMode.value) return;
    try {
      final u = await api.updateUserProfile(nickname: nickname);
      currentUser.value = u;
      await store.setUser(u);
    } catch (_) {
      offline.value = true;
    }
  }

  Future<void> updateAvatar(String avatar) async {
    final updated = currentUser.value?.copyWith(avatar: avatar);
    currentUser.value = updated;
    if (updated != null) {
      await store.setUser(updated);
      if (isLocalMode.value) {
        await store.setLocalUser(updated);
        return;
      }
    }
    if (isLocalMode.value) return;
    try {
      final u = await api.updateUserProfile(avatar: avatar);
      currentUser.value = u;
      await store.setUser(u);
    } catch (_) {
      offline.value = true;
    }
  }

  // ====== 单条记录 ======
  /// [id] 可以是本地 id 或 serverId(_edit_record_modal 那边可能拿不到 serverId)
  Future<void> updateRecord(int id, DateTime time, String note) async {
    // 先按 serverId 找，没找到再按本地 id 找
    var idx = records.indexWhere((r) => r.serverId == id);
    idx = idx >= 0 ? idx : records.indexWhere((r) => r.id == id);
    if (isLocalMode.value) {
      if (idx != -1) _updateRecordLocal(idx, note);
      return;
    }
    final targetId = idx >= 0 ? (records[idx].serverId ?? records[idx].id) : id;
    try {
      await api.updateRecord(targetId, time, note);
      await refreshAll();
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 500) {
        offline.value = true;
        if (idx != -1) _updateRecordLocal(idx, note);
        return;
      }
      rethrow;
    } catch (_) {
      offline.value = true;
      if (idx != -1) _updateRecordLocal(idx, note);
    }
  }

  Future<void> deleteRecord(int id) async {
    final idx = records.indexWhere((r) => r.id == id);
    if (isLocalMode.value) {
      if (idx != -1) {
        records.removeAt(idx);
        await store.setLocalRecords(records);
        _recomputeLastTakeoff();
      }
      return;
    }
    try {
      await api.deleteRecord(id);
      await refreshAll();
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 500) {
        offline.value = true;
        if (idx != -1) {
          records.removeAt(idx);
          await store.setLocalRecords(records);
          _recomputeLastTakeoff();
        }
        return;
      }
      rethrow;
    } catch (_) {
      offline.value = true;
      if (idx != -1) {
        records.removeAt(idx);
        await store.setLocalRecords(records);
        _recomputeLastTakeoff();
      }
    }
  }

  void _recomputeLastTakeoff() {
    if (records.isEmpty) {
      lastTakeoff.value = null;
      store.setLastTakeoff(null);
    } else {
      lastTakeoff.value =
          records.map((r) => r.time).reduce((a, b) => a.isAfter(b) ? a : b);
      store.setLastTakeoff(lastTakeoff.value);
    }
  }

  // ====== 派生（getter）======
  // ⚠️ 这些不是 Rx。GetX 不会自动追踪它们。
  //    UI 里使用时**必须**包在 Obx(() => ...)，否则值变了 UI 不重画。
  //    例子：Obx(() => Text('${state.totalRecords}'))
  int get totalRecords => records.length;

  int get currentStreak {
    if (records.isEmpty) return 0;
    final set = records
        .map((r) => DateTime(r.time.year, r.time.month, r.time.day))
        .toSet();
    int streak = 0;
    var d = DateTime.now();
    var d0 = DateTime(d.year, d.month, d.day);
    while (set.contains(d0)) {
      streak++;
      d0 = d0.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int? get averageTakeoffHour {
    if (records.isEmpty) return null;
    final hours = records.map((r) => r.time.hour);
    final avg = hours.reduce((a, b) => a + b) / hours.length;
    return avg.round();
  }

  int get badges => records.length ~/ 10;

  bool hasRecordOn(DateTime d) {
    final d0 = DateTime(d.year, d.month, d.day);
    return records.any((r) =>
        r.time.year == d0.year &&
        r.time.month == d0.month &&
        r.time.day == d0.day);
  }

  // ====== 后端地址 ======
  String get baseUrl => api.baseUrl;
  Future<void> updateBaseUrl(String url) async {
    await api.updateBaseUrl(url);
  }
}
