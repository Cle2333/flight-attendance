import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/api_client.dart';
import 'app.dart';
import 'state/app_state.dart';
import 'storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final store = await LocalStore.create();
  final api = ApiClient(store);
  final state = AppState(store: store, api: api);

  // **离线优先**：先 runApp 让 UI 立刻可见，bootstrap 在后台跑。
  // 这样即便 server 挂了、token 失效、要 8 秒超时，App 也能立刻用本地缓存渲染。
  runApp(FlightAttendanceApp(appState: state));

  // fire-and-forget —— AppState.bootstrap 内部所有失败都不会冒出来
  // ignore: discarded_futures
  state.bootstrap();
}
