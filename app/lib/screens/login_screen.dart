import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/controllers/login_controller.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'server_config_screen.dart';

/// 登录/注册页 —— 无状态 widget,所有 form/loading/message 状态在 [LoginController]。
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(LoginController());
    final r = context.r;
    return Scaffold(
      backgroundColor: r.palette.bg,
      body: SafeArea(
        child: Stack(
          children: [
            CenteredFrame(
              maxWidth: r.contentMaxWidth,
              child: SingleChildScrollView(
                padding: r.padH(2.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: r.gap2xl),
                      Container(
                        width: r.gap2xl * 1.05,
                        height: r.gap2xl * 1.05,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(r.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.flight,
                          color: Colors.white,
                          size: r.icon2xl,
                        ),
                      ),
                      SizedBox(height: r.gapLg),
                      Text(
                        '航班打卡',
                        style: TextStyle(
                          fontSize: r.text3xl,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: r.gapXs * 0.6),
                      Text(
                        '记录每一次起飞',
                        style: TextStyle(
                          fontSize: r.textBase,
                          color: context.palette.textSecondary,
                        ),
                      ),
                      SizedBox(height: r.gap2xl),
                      TextField(
                        controller: ctrl.accountCtrl,
                        decoration: const InputDecoration(labelText: '账号'),
                      ),
                      Obx(() => !ctrl.isLogin.value
                          ? Padding(
                              padding: EdgeInsets.only(top: r.gapSm),
                              child: TextField(
                                controller: ctrl.nicknameCtrl,
                                decoration:
                                    const InputDecoration(labelText: '昵称'),
                              ),
                            )
                          : const SizedBox.shrink()),
                      SizedBox(height: r.gapSm),
                      TextField(
                        controller: ctrl.passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: '密码'),
                      ),
                      Obx(() => !ctrl.isLogin.value
                          ? Padding(
                              padding: EdgeInsets.only(top: r.gapSm),
                              child: TextField(
                                controller: ctrl.confirmCtrl,
                                obscureText: true,
                                decoration:
                                    const InputDecoration(labelText: '确认密码'),
                              ),
                            )
                          : const SizedBox.shrink()),
                      SizedBox(height: r.gapLg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_box,
                                  size: r.iconSm, color: context.palette.textSecondary),
                              SizedBox(width: r.gapXs * 0.6),
                              Text('记住我',
                                  style: TextStyle(
                                      color: context.palette.textSecondary,
                                      fontSize: r.textSm)),
                            ],
                          ),
                          GestureDetector(
                            onTap: ctrl.toggleMode,
                            behavior: HitTestBehavior.opaque,
                            child: Obx(() => Text(
                                  ctrl.isLogin.value ? '注册账号' : '返回登录',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: r.textSm,
                                  ),
                                )),
                          ),
                        ],
                      ),
                      SizedBox(height: r.gapLg),
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() => FilledButton(
                              onPressed:
                                  ctrl.loading.value ? null : ctrl.submit,
                              child: ctrl.loading.value
                                  ? SizedBox(
                                      width: r.gapMd * 1.25,
                                      height: r.gapMd * 1.25,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      ctrl.isLogin.value ? '登录' : '注册'),
                            )),
                      ),
                      SizedBox(height: r.gapSm),
                      Obx(() {
                        final msg = ctrl.message.value;
                        if (msg == null) return const SizedBox.shrink();
                        return Text(
                          msg,
                          style: TextStyle(
                            color: ctrl.messageType.value == MessageType.error
                                ? AppColors.danger
                                : AppColors.success,
                            fontSize: r.textSm,
                          ),
                        );
                      }),
                      SizedBox(height: r.gapLg),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: ctrl.enterLocal,
                          icon: const Text('📱'),
                          label: const Text('本地模式（无需登录）'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: context.palette.surfaceMuted,
                            foregroundColor: context.palette.textSecondary,
                            minimumSize: Size.fromHeight(r.buttonHsm),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(r.radiusMd)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: r.gapXs,
              right: r.gapXs,
              child: SafeArea(
                child: IconButton(
                  icon: Icon(Icons.settings_outlined,
                      size: r.iconMd, color: context.palette.textLight),
                  onPressed: () => Get.to(() => const ServerConfigScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}