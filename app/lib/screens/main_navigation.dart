import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../state/controllers/navigation_controller.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'main_dock.dart';
import 'profile_screen.dart';
import 'records_screen.dart';

/// App 主壳：4 个 tab 的 IndexedStack + 底部 dock
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  static const _screens = <Widget>[
    HomeScreen(),
    RecordsScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(NavigationController());
    final state = Get.find<AppState>();
    final r = context.r;

    return Scaffold(
      // 不延伸 body —— 让 Scaffold 自动把 body 限制在 dock 上方,
      // 彻底避免任何"dock 遮挡内容"的隐患。
      // 各个 screen 自己负责自己的 bottom padding(列表用 gapLg,
      // 首页用 Spacer 自然分布)。
      extendBody: false,
      backgroundColor: r.palette.bg,
      body: Column(
        children: [
          // 离线 banner —— 只在 (在线模式 + 网络不可达) 时出现
          Obx(() {
            if (!state.offline.value || state.isLocalMode.value) {
              return const SizedBox.shrink();
            }
            return _OfflineBanner(
              onRetry: () async {
                final ok = await state.retryConnection();
                if (!ok) {
                  Get.snackbar(
                    '仍不可达',
                    '服务器没响应，继续本地保存',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                }
              },
            );
          }),

          // 主内容:IndexedStack 让 4 个 screen 都活着,切换无重建。
          // 必须 StackFit.expand —— IndexedStack 默认 loose 会让 children 拿到
          // maxWidth=infinity,导致 HomeScreen 的 Stack/Column 按内容自然宽度
          // 渲染(~300px),桌面端 IndexedStack 自身坍缩到该宽度。
          Expanded(
            child: Obx(() => IndexedStack(
                  sizing: StackFit.expand,
                  index: nav.selectedIndex.value,
                  children: _screens,
                )),
          ),
        ],
      ),

      // 底部 dock —— 已拆到 main_dock.dart
      // 走 compactPanelMaxWidth,保持浮动药丸观感(不跟主内容一起拉到全宽)
      bottomNavigationBar: SafeArea(
        top: false,
        child: CenteredFrame(
          maxWidth: r.compactPanelMaxWidth,
          padding: EdgeInsets.only(bottom: r.gapSm),
          child: Obx(() => MainDock(
                index: nav.selectedIndex.value,
                onChanged: nav.select,
              )),
        ),
      ),
    );
  }
}

/// 顶部黄条 —— server 不可达时提醒，本地缓存可用、所有操作仍工作
class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _OfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Material(
      color: context.palette.warningBg,
      child: SafeArea(
        bottom: false,
        child: CenteredFrame(
          maxWidth: r.contentMaxWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.gapSm,
              vertical: r.gapSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: r.iconMd * 0.9,
                  color: context.palette.warningText,
                ),
                SizedBox(width: r.gapXs),
                Expanded(
                  child: Text(
                    '无法连接服务器，已切换到本地保存',
                    style: TextStyle(
                      fontSize: r.textSm,
                      color: context.palette.warningText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: context.palette.warningText,
                    padding: EdgeInsets.symmetric(
                      horizontal: r.gapXs,
                      vertical: r.gap2xs,
                    ),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('重试', style: TextStyle(fontSize: r.textSm)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
