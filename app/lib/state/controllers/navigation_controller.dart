import 'package:get/get.dart';

/// 底部 3 个 tab 的当前选中下标。
class NavigationController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void select(int index) {
    if (index < 0 || index > 2) return;
    selectedIndex.value = index;
  }
}
