import 'package:get/get.dart';

import '../../api/api_exception.dart';
import '../../models/settings.dart';
import '../app_state.dart';
import 'navigation_controller.dart';

/// 排行榜页面状态 —— type/week|all、loading、错误、条目。
///
/// 抽 controller 的好处:
///   - 切 tab 不会重建整个 screen(只 setState 太重,Obx 更细粒度)
///   - 排行榜数据可以扩展(加缓存、加分页、加搜索)都在 controller 里,
///     不污染 widget
///
/// 刷新策略:
///   - 首次创建(onInit):拉一次
///   - 每次切回排行榜 tab(由 NavigationController 驱动):重新拉一次,
///     保证切回去后看到的是最新数据
class LeaderboardController extends GetxController {
  final AppState _state = Get.find<AppState>();
  final NavigationController _nav = Get.find<NavigationController>();

  static const _tabIndex = 2; // LeaderboardScreen 是 IndexedStack 第 3 个 tab

  final RxString type = 'week'.obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();
  final RxList<LeaderboardEntry> entries = <LeaderboardEntry>[].obs;

  Worker? _tabWatcher;

  /// 节流：所有刷新入口(onInit / tab 切换 / switchType)
  /// 都走 _throttledRefresh(),5 秒内不重复刷。
  static const _throttleMs = 5000;
  DateTime _lastRefreshAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void onInit() {
    super.onInit();
    // 首屏创建:不走节流(用户刚打开,一定要刷)
    refresh(force: true);
    // 监听 NavigationController 的 selectedIndex,
    // 每次切到排行榜 tab 时重新拉数据(走节流)。
    _tabWatcher = ever<int>(_nav.selectedIndex, (idx) {
      if (idx == _tabIndex) {
        _throttledRefresh();
      }
    });
  }

  @override
  void onClose() {
    _tabWatcher?.dispose();
    super.onClose();
  }

  /// 受节流限制的刷新(tab 切换 / switchType 共用),5 秒内不重复刷
  void _throttledRefresh() {
    final now = DateTime.now();
    if (now.difference(_lastRefreshAt).inMilliseconds < _throttleMs) {
      // ignore: avoid_print
      print('[LeaderboardController] throttled, skip refresh');
      // 节流命中:静默返回,保留现有 entries,
      // 避免 loading 期间被显示为空(切换后闪一下"暂无数据")
      return;
    }
    refresh();
  }

  /// 拉取排行榜数据
  ///  - force=true: 跳过节流(首屏初始化用)
  ///  - 默认: 受节流限制
  // ignore: annotate_overrides
  Future<void> refresh({bool force = false}) async {
    if (!force) {
      final now = DateTime.now();
      if (now.difference(_lastRefreshAt).inMilliseconds < _throttleMs) {
        // ignore: avoid_print
        print('[LeaderboardController] throttled (in refresh), skip');
        return;
      }
    }
    _lastRefreshAt = DateTime.now();
    // ignore: avoid_print
    print('[LeaderboardController] refresh start, type=${type.value}, force=$force');
    loading.value = true;
    error.value = null;
    // 不预先清空 entries —— loading 期间 UI 仍显示上一份缓存数据,
    // 请求返回后再整体替换。如果原本就是空(首屏),Obx 会自然显示"暂无数据"。
    try {
      final list = await _state.api.getLeaderboard(type: type.value);
      // ignore: avoid_print
      print('[LeaderboardController] refresh ok, got ${list.length} entries');
      entries.assignAll(list);
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (e) {
      error.value = '加载失败';
      // ignore: avoid_print
      print('[LeaderboardController] refresh error: $e');
    } finally {
      loading.value = false;
    }
  }

  void switchType(String t) {
    // ignore: avoid_print
    print('[LeaderboardController] switchType: $t (current=${type.value})');
    if (type.value == t) return;
    type.value = t;
    // switchType 也走节流(避免快点击跳跳塔),
    // entries 不预先 clear —— loading 期间 UI 仍显示原数据,
    // 新数据来了一并替换。
    _throttledRefresh();
  }
}