import 'package:get/get.dart';

/// 底部 4 个 tab 的当前选中下标。
///
/// 提到 controller 是为了让其他 widget(如首页想跳到"记录" tab、
/// 通知 badge 想知道当前在哪一 tab)能直接读到选中状态,而不是
/// 各自去 setState 同步一份。
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void select(int i) {
    if (i < 0 || i > 3) return;
    selectedIndex.value = i;
  }
}