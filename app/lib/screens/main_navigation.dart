import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/controllers/navigation_controller.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'main_dock.dart';
import 'profile_screen.dart';
import 'records_screen.dart';

/// App 主壳：3 个本地功能 tab 的 IndexedStack + 底部 dock。
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  static const _screens = <Widget>[
    HomeScreen(),
    RecordsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(NavigationController());
    final r = context.r;

    return Scaffold(
      extendBody: false,
      backgroundColor: r.palette.bg,
      body: Obx(
        () => IndexedStack(
          sizing: StackFit.expand,
          index: nav.selectedIndex.value,
          children: _screens,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CenteredFrame(
          maxWidth: r.compactPanelMaxWidth,
          padding: EdgeInsets.only(bottom: r.gapSm),
          child: Obx(
            () =>
                MainDock(index: nav.selectedIndex.value, onChanged: nav.select),
          ),
        ),
      ),
    );
  }
}
