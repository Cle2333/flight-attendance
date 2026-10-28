import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../state/controllers/navigation_controller.dart';
import '../utils/responsive.dart';
import '../widgets/glass_page_switcher.dart';
import 'desktop_sidebar.dart';
import 'home_screen.dart';
import 'main_dock.dart';
import 'profile_screen.dart';
import 'records_screen.dart';

/// App 主壳：宽屏使用液体玻璃侧边栏，窄屏使用底部液体玻璃 dock。
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
    final state = Get.find<AppState>();
    final r = context.r;

    return Obx(() {
      final index = nav.selectedIndex.value;
      final avatarPath = state.profile.value?.avatarPath;
      if (r.isDesktop) {
        return _buildDesktop(context, r, nav, index, avatarPath);
      }
      return _buildMobile(context, r, nav, index);
    });
  }

  Widget _buildDesktop(
    BuildContext context,
    Responsive r,
    NavigationController nav,
    int index,
    String? avatarPath,
  ) {
    final sidebarWidth = (r.width * 0.18).clamp(216.0, 250.0).toDouble();
    return Scaffold(
      backgroundColor: r.palette.bg,
      body: Row(
        children: [
          SafeArea(
            right: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(r.gapLg, r.gapLg, 0, r.gapLg),
              child: SizedBox(
                width: sidebarWidth,
                child: DesktopSidebar(
                  index: index,
                  onChanged: nav.select,
                  avatarPath: avatarPath,
                ),
              ),
            ),
          ),
          Expanded(
            child: GlassPageSwitcher(index: index, children: _screens),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    Responsive r,
    NavigationController nav,
    int index,
  ) {
    return Scaffold(
      extendBody: false,
      backgroundColor: r.palette.bg,
      body: GlassPageSwitcher(index: index, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CenteredFrame(
          maxWidth: r.compactPanelMaxWidth,
          padding: EdgeInsets.only(bottom: r.gapSm),
          child: MainDock(index: index, onChanged: nav.select),
        ),
      ),
    );
  }
}
