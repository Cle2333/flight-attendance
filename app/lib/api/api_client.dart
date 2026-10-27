import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../models/record.dart';
import '../models/settings.dart';
import '../models/user.dart';
import '../storage/local_store.dart';

/// 从 `flutter run --dart-define=API_BASE_URL=...` 读取的全局默认后端地址
const _kApiBaseUrl = String.fromEnvironment('API_BASE_URL');

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// REST 客户端 —— 内部根据 localMode 切换"真后端"和"本地存储"
class ApiClient {
  final LocalStore store;
  String baseUrl;
  String? _token;
  String? _refreshToken;
  http.Client _client;

  /// 防 401 刷新时并发触发的 mutex
  Future<bool>? _refreshFuture;

  ApiClient(this.store, {String? baseUrl})
      : baseUrl = baseUrl ?? _resolveBaseUrl(store),
        _client = http.Client() {
    _token = store.getToken();
    _refreshToken = store.getRefreshToken();
  }

  /// 测试用：注入 mock http client（AppState.bootstrap 的离线场景用）
  @visibleForTesting
  void setHttpClient(http.Client client) {
    _client = client;
  }

  static String _resolveBaseUrl(LocalStore store) {
    if (_kApiBaseUrl.isNotEmpty) return _kApiBaseUrl;
    final saved = store.getBaseUrl();
    if (saved != null && saved.isNotEmpty) return saved;
    return _defaultBaseUrl();
  }

  static String _defaultBaseUrl() {
    // 默认走公网 HTTPS 域名。如果用户在「服务器设置」里改了地址就以那个为准。
    return 'https://flight.cmach.qzz.io';
  }

  Future<void> updateBaseUrl(String url) async {
    baseUrl = url;
    await store.setBaseUrl(url);
  }

  String? get token => _token;
  void setToken(String? t) {
    _token = t;
  }

  String? get refreshToken => _refreshToken;

  Map<String, String> _headers([bool needAuth = true]) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (needAuth && _token != null) {
      h['Authorization'] = 'Bearer $_token';
    }
    return h;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool needAuth = true,
    Duration? timeout,
  }) async {
    var data = await _rawRequest(method, path,
        body: body, needAuth: needAuth, timeout: timeout);

    // 401 + 有 refresh token → 尝试自动续期
    if (data == null && needAuth && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        data = await _rawRequest(method, path,
            body: body, needAuth: needAuth, timeout: timeout);
      }
    }

    if (data == null) {
      throw ApiException('未登录或 token 无效', statusCode: 401);
    }
    return data;
  }

  Future<Map<String, dynamic>?> _rawRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool needAuth = true,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final effectiveTimeout = timeout ?? const Duration(seconds: 8);
    http.Response res;
    try {
      switch (method) {
        case 'GET':
          res = await _client.get(uri, headers: _headers(needAuth)).timeout(effectiveTimeout);
          break;
        case 'POST':
          res = await _client.post(uri, headers: _headers(needAuth),
              body: body == null ? null : jsonEncode(body)).timeout(effectiveTimeout);
          break;
        case 'PUT':
          res = await _client.put(uri, headers: _headers(needAuth),
              body: body == null ? null : jsonEncode(body)).timeout(effectiveTimeout);
          break;
        case 'DELETE':
          res = await _client.delete(uri, headers: _headers(needAuth)).timeout(effectiveTimeout);
          break;
        default:
          throw ApiException('不支持的 HTTP 方法: $method');
      }
    } on TimeoutException {
      throw ApiException('请求超时');
    } on http.ClientException catch (e) {
      throw ApiException('网络错误: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('服务器响应格式错误: ${e.message}');
    } catch (e) {
      throw ApiException('请求失败: $e');
    }

    if (res.statusCode == 401) {
      // 让上层走 refresh 逻辑
      return null;
    }

    final bodyText = utf8.decode(res.bodyBytes);
    Map<String, dynamic> data;
    try {
      data = jsonDecode(bodyText) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('服务器返回非 JSON: ${res.statusCode}');
    }
    if (data['success'] != true) {
      throw ApiException(
        data['message'] as String? ?? '请求失败 (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return data;
  }

  /// 并发安全：多个 401 同时来只刷一次
  Future<bool> _tryRefresh() async {
    if (_refreshToken == null) return false;
    final existing = _refreshFuture;
    if (existing != null) return existing;
    final fut = _doRefresh();
    _refreshFuture = fut;
    try {
      return await fut;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefresh() async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/refresh');
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        await _clearTokens();
        return false;
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (data['success'] != true) {
        await _clearTokens();
        return false;
      }
      final d = data['data'] as Map<String, dynamic>;
      _token = d['accessToken'] as String?;
      _refreshToken = d['refreshToken'] as String?;
      await store.setToken(_token);
      await store.setRefreshToken(_refreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _clearTokens() async {
    _token = null;
    _refreshToken = null;
    await store.setToken(null);
    await store.setRefreshToken(null);
    await store.setUser(null);
  }

  // ==================== Auth ====================
  Future<AppUser> login(String account, String password) async {
    final data = await _rawPostNoAuth('/api/auth/login',
        {'account': account, 'password': password});
    return _persistAuthData(data, fallbackNickname: account);
  }

  Future<AppUser> register(String account, String password, String nickname) async {
    final data = await _rawPostNoAuth('/api/auth/register',
        {'account': account, 'password': password, 'nickname': nickname});
    return _persistAuthData(data, fallbackNickname: nickname);
  }

  Future<Map<String, dynamic>> _rawPostNoAuth(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response res;
    try {
      res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw ApiException('请求超时');
    } on http.ClientException catch (e) {
      throw ApiException('网络错误: ${e.message}');
    }
    final bodyText = utf8.decode(res.bodyBytes);
    Map<String, dynamic> data;
    try {
      data = jsonDecode(bodyText) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('服务器返回非 JSON: ${res.statusCode}');
    }
    if (data['success'] != true) {
      throw ApiException(
        data['message'] as String? ?? '请求失败 (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return data;
  }

  AppUser _persistAuthData(Map<String, dynamic> data, {required String fallbackNickname}) {
    final d = data['data'] as Map<String, dynamic>;
    _token = d['accessToken'] as String;
    _refreshToken = d['refreshToken'] as String;
    store.setToken(_token);
    store.setRefreshToken(_refreshToken);
    final u = AppUser(
      id: (d['userId'] as num).toInt(),
      account: d['account'] as String,
      nickname: d['nickname'] as String? ?? fallbackNickname,
      role: d['role'] as String?,
    );
    store.setUser(u);
    return u;
  }

  Future<void> logout() async {
    final rt = _refreshToken;
    // 先撤销服务器端 refresh token（best-effort，失败也清本地）
    if (rt != null) {
      try {
        final uri = Uri.parse('$baseUrl/api/auth/logout');
        await _client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': rt}),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {
        // 忽略网络错误
      }
    }
    await _clearTokens();
  }

  // ==================== User ====================
  Future<AppUser> getUserProfile() async {
    final data = await _request('GET', '/api/user/profile');
    return AppUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AppUser> updateUserProfile({String? nickname, String? avatar}) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatar != null) body['avatar'] = avatar;
    final data = await _request('PUT', '/api/user/profile', body: body);
    return AppUser.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ==================== Records ====================
  Future<List<FlightRecord>> getRecords() async {
    final data = await _request('GET', '/api/records');
    final list = (data['data'] as List? ?? []);
    return list
        .map((e) => FlightRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> addRecord(DateTime time, String note) async {
    final data = await _request(
      'POST',
      '/api/records',
      body: {'time': time.toUtc().toIso8601String(), 'note': note},
    );
    return ((data['data'] as Map<String, dynamic>)['id'] as num).toInt();
  }

  Future<void> updateRecord(int id, DateTime time, String note) async {
    await _request(
      'PUT',
      '/api/records/$id',
      body: {'time': time.toUtc().toIso8601String(), 'note': note},
    );
  }

  Future<void> deleteRecord(int id) async {
    await _request('DELETE', '/api/records/$id');
  }

  Future<void> syncRecords(List<Map<String, dynamic>> records) async {
    await _request('POST', '/api/records/sync', body: {'records': records});
  }

  // ==================== Settings ====================
  Future<AppSettings> getSettings() async {
    final data = await _request('GET', '/api/settings');
    return AppSettings.fromJson(data['data'] as Map<String, dynamic>?);
  }

  Future<void> updateSettings({
    String? precision,
    String? effect,
    String? effectEmoji,
    String? theme,
    List<String>? quotes,
  }) async {
    final body = <String, dynamic>{};
    if (precision != null) body['precision'] = precision;
    if (effect != null) body['effect'] = effect;
    if (effectEmoji != null) body['effectEmoji'] = effectEmoji;
    if (theme != null) body['theme'] = theme;
    if (quotes != null) body['quotes'] = quotes;
    await _request('PUT', '/api/settings', body: body);
  }

  // ==================== Admin ====================
  Future<List<LeaderboardEntry>> getLeaderboard({String type = 'all'}) async {
    final data = await _request(
      'GET',
      '/api/admin/leaderboard?type=$type',
      needAuth: false,
    );
    final list = (data['data'] as List? ?? []);
    return list
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminStats> getAdminStats() async {
    final data = await _request('GET', '/api/admin/stats');
    return AdminStats.fromJson(data['data'] as Map<String, dynamic>);
  }
}
