// 离线优先 —— server 完全挂掉时 App 也能跑通核心流程的回归测试。
//
// 模拟场景：
//   1. shared_preferences 有上次登录留下的 user/token + records 缓存
//   2. HTTP client 全部失败（模拟后端宕机 / 端口未监听）
//   3. AppState.bootstrap() 必须不抛、records 立即显示本地缓存、offline 置 true
//   4. 本地打卡走 fallback，不抛异常
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flight_attendance_app/api/api_client.dart';
import 'package:flight_attendance_app/state/app_state.dart';
import 'package:flight_attendance_app/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({
      'token': 'fake-jwt-token',
      'user': jsonEncode({
        'id': 42,
        'account': 'alice',
        'nickname': 'Alice',
        'avatar': '✈️',
      }),
      'localRecords': jsonEncode([
        {
          'id': 1,
          'userId': 42,
          'time': '2026-06-18T10:00:00.000Z',
          'note': 'cached from last online session',
          'createdAt': '2026-06-18T10:00:00.000Z',
        }
      ]),
      'baseUrl': 'http://127.0.0.1:9', // 端口 9 = discard，几乎肯定连不上
    });
  });

  test('bootstrap 不抛异常且 records 从本地缓存加载', () async {
    // 所有请求都 throw —— 模拟 server 不可达
    final mock = MockClient((req) async {
      throw http.ClientException('Connection refused (simulated)');
    });

    final store = await LocalStore.create();
    final api = ApiClient(store);
    api.setHttpClient(mock);
    final state = AppState(store: store, api: api);

    // 核心断言：不抛
    await state.bootstrap();

    expect(state.booted.value, true);
    expect(state.currentUser.value?.account, 'alice');
    expect(state.records.length, 1);
    expect(state.records.first.note, 'cached from last online session');
    expect(state.offline.value, true,
        reason: '网络不可达时 offline 应被置 true');
  });

  test('离线时本地打卡不抛', () async {
    final mock = MockClient((req) async {
      throw http.ClientException('Connection refused (simulated)');
    });

    final store = await LocalStore.create();
    final api = ApiClient(store);
    api.setHttpClient(mock);
    final state = AppState(store: store, api: api);
    await state.bootstrap();

    final before = state.records.length;
    // 本地打卡 —— 不应抛，因为 AppState.takeOff 内部会降级到本地
    final r = await state.takeOff();
    expect(r.id, isNotNull);
    expect(state.records.length, before + 1);
    expect(state.offline.value, true);
  });

  test('网络恢复后 offline 应被解除', () async {
    var shouldFail = true;
    final mock = MockClient((req) async {
      if (shouldFail) {
        throw http.ClientException('still down');
      }
      // 按路径分发响应 —— 模拟 server 恢复
      final path = req.url.path;
      if (path == '/api/user/profile') {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': 42, 'account': 'alice', 'nickname': 'Alice', 'avatar': '✈️'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path == '/api/records') {
        return http.Response(
          jsonEncode({'success': true, 'data': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (path == '/api/settings') {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'precision_setting': 'second',
              'effect': 'plane',
              'theme': 'dark',
              'effectEmoji': '✈️',
              'quotes': <String>[],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"success":true,"data":{}}', 200,
          headers: {'content-type': 'application/json'});
    });

    final store = await LocalStore.create();
    final api = ApiClient(store);
    api.setHttpClient(mock);
    final state = AppState(store: store, api: api);
    await state.bootstrap();
    expect(state.offline.value, true);

    shouldFail = false;
    final ok = await state.retryConnection();
    expect(ok, true);
    expect(state.offline.value, false);
  });
}
