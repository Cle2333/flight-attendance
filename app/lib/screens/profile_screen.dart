import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/picker_modals.dart';

/// 项目仓库地址 —— 「关于」行点击后跳转
const _kRepoUrl = 'https://github.com/Cle2333/flight-attendance-web';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    final r = context.r;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final user = state.currentUser.value;
        final isLocal = state.isManualLocalMode.value;
        final avatar = user?.avatar?.isNotEmpty == true ? user!.avatar! : '✈️';
        final nickname = user?.nickname ?? '用户';
        final id = isLocal
            ? '本地模式'
            : 'ID: USER-${(user?.id ?? 0).toString().padLeft(4, '0')}';

        return ListView(
          padding: EdgeInsets.only(bottom: r.gapLg),
          children: [
            Container(
              margin: r.padFromLTRB(1.4, 0.8, 1.4, 0),
              padding: r.padFromLTRB(1.4, 1.6, 1.4, 1.4),
              decoration: BoxDecoration(
                color: context.palette.card,
                borderRadius: BorderRadius.circular(r.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Get.dialog(
                      AvatarPicker(
                        current: avatar,
                        onPick: (e) => state.updateAvatar(e),
                      ),
                    ),
                    child: Container(
                      width: r.avatarLg,
                      height: r.avatarLg,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(avatar, style: TextStyle(fontSize: r.text2xl * 1.4)),
                    ),
                  ),
                  SizedBox(height: r.gapSm * 0.95),
                  GestureDetector(
                    onTap: () => Get.dialog(
                      NicknameEditor(
                        current: nickname,
                        onSave: state.updateNickname,
                      ),
                    ),
                    child: Text(
                      nickname,
                      style: TextStyle(
                        fontSize: r.textXl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: r.gapXs * 0.5),
                  Text(
                    id,
                    style: TextStyle(
                      fontSize: r.textSm,
                      color: context.palette.textSecondary,
                    ),
                  ),
                  SizedBox(height: r.gapLg * 0.7),
                  Container(height: 1, color: context.palette.border),
                  SizedBox(height: r.gapLg * 0.6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProfileStat(n: '${state.totalRecords}', l: '总起飞'),
                      _ProfileStat(n: '${state.currentStreak}', l: '连续天数'),
                      _ProfileStat(n: '${state.badges}', l: '徽章'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: r.gapMd),
            _Group(
              children: [
                _Row(
                  icon: '✏️',
                  color: context.palette.primaryBg,
                  title: '修改昵称',
                  subtitle: '当前: $nickname',
                  onTap: () => Get.dialog(
                    NicknameEditor(
                      current: nickname,
                      onSave: state.updateNickname,
                    ),
                  ),
                ),
                _Row(
                  icon: '🖼️',
                  color: context.palette.infoBg,
                  title: '更换头像',
                  subtitle: '选择喜欢的头像',
                  onTap: () => Get.dialog(
                    AvatarPicker(
                      current: avatar,
                      onPick: state.updateAvatar,
                    ),
                  ),
                ),
              ],
            ),
            _Group(
              children: [
                _Row(
                  icon: '⏱️',
                  color: context.palette.primaryBg,
                  title: '计时精度',
                  subtitle: '当前: ${state.settings.value.precisionEnum.displayName}',
                  onTap: () => Get.dialog(
                    PrecisionPicker(
                      current: state.settings.value.precisionEnum,
                      onPick: (p) => state.updatePrecision(p.name),
                    ),
                  ),
                ),
                _Row(
                  icon: '🎆',
                  color: context.palette.infoBg,
                  title: '起飞特效',
                  subtitle: '当前: ${state.settings.value.effectEmoji}',
                  onTap: () => Get.dialog(
                    EffectEmojiPicker(
                      current: state.settings.value.effectEmoji,
                      onPick: state.updateEffectEmoji,
                    ),
                  ),
                ),
                _Row(
                  icon: '💬',
                  color: context.palette.warningBg,
                  title: '机长语录',
                  subtitle: '${state.settings.value.quotes.length} 条',
                  onTap: () => Get.dialog(
                    QuotesEditor(
                      initial: state.settings.value.quotes,
                      onSave: state.updateQuotes,
                    ),
                  ),
                ),
              ],
            ),
            _Group(
              children: [
                _Row(
                  icon: '🔄',
                  color: context.palette.primaryBg,
                  title: isLocal ? '切换到云端模式' : '切换到本地模式',
                  subtitle: '当前: ${isLocal ? '本地模式' : '云端模式'}',
                  onTap: () async {
                    if (isLocal) {
                      await state.logout();
                    } else {
                      await state.enterLocalMode();
                    }
                  },
                ),
                _Row(
                  icon: '🚪',
                  color: context.palette.dangerBg,
                  iconColor: AppColors.danger,
                  title: '退出登录',
                  subtitle: null,
                  onTap: () async {
                    final ok = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('退出登录'),
                        content: Text(isLocal
                            ? '退出本地模式？本地数据将被清空。'
                            : '确定要退出登录？'),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.danger),
                            onPressed: () => Get.back(result: true),
                            child: const Text('退出'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await state.logout();
                    }
                  },
                ),
              ],
            ),
            // 外观 —— 主题模式切换
            _Group(
              children: [
                Obx(() {
                  final mode = state.themeMode.value;
                  String label;
                  switch (mode) {
                    case ThemeMode.light:
                      label = '当前: 浅色';
                      break;
                    case ThemeMode.dark:
                      label = '当前: 深色';
                      break;
                    case ThemeMode.system:
                      label = '当前: 跟随系统';
                      break;
                  }
                  return _Row(
                    icon: mode == ThemeMode.dark ? '🌙' : '☀️',
                    color: context.palette.primaryBg,
                    title: '外观主题',
                    subtitle: label,
                    onTap: () async {
                      final picked = await Get.dialog<ThemeMode>(
                        AlertDialog(
                          title: const Text('选择主题'),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ThemeOption(
                                mode: ThemeMode.system,
                                current: mode,
                                label: '跟随系统',
                                icon: '📱',
                              ),
                              _ThemeOption(
                                mode: ThemeMode.light,
                                current: mode,
                                label: '浅色',
                                icon: '☀️',
                              ),
                              _ThemeOption(
                                mode: ThemeMode.dark,
                                current: mode,
                                label: '深色',
                                icon: '🌙',
                              ),
                            ],
                          ),
                        ),
                      );
                      if (picked != null) {
                        state.setThemeMode(picked);
                      }
                    },
                  );
                }),
              ],
            ),

            // ── 关于本应用 —— 跳转 GitHub 仓库 ───────
            _Group(
              children: [
                _Row(
                  icon: 'ℹ️',
                  color: context.palette.primaryBg,
                  title: '关于本应用',
                  subtitle: 'github.com/Cle2333/flight-attendance-web',
                  onTap: () => _openRepo(context),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

/// 调起系统浏览器打开项目仓库 —— 打开不了则用 snackbar 提示手动访问
Future<void> _openRepo(BuildContext context) async {
  final uri = Uri.parse(_kRepoUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    Get.snackbar(
      '无法打开浏览器',
      '请手动访问: $_kRepoUrl',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String n;
  final String l;
  const _ProfileStat({required this.n, required this.l});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      children: [
        Text(
          n,
          style: TextStyle(
            fontSize: r.text2xl * 0.95,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: r.gap2xs),
        Text(
          l,
          style: TextStyle(
            fontSize: r.textXs,
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      margin: r.padFromLTRB(1.4, 0.8, 1.4, 0),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(r.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                  height: 1,
                  color: context.palette.border,
                  indent: r.gapMd,
                  endIndent: r.gapMd),
          ],
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final ThemeMode current;
  final String label;
  final String icon;
  const _ThemeOption({
    required this.mode,
    required this.current,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final isSelected = mode == current;
    return InkWell(
      onTap: () => Get.back(result: mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: r.text2xl)),
            SizedBox(width: r.gapMd),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: r.textMd,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppColors.primary, size: r.iconMd),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: r.padHV(1.0, 0.875),
          child: Row(
            children: [
              Container(
                width: r.touchTarget,
                height: r.touchTarget,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(r.radiusSm * 0.85),
                ),
                alignment: Alignment.center,
                child: Text(icon,
                    style: TextStyle(
                      fontSize: r.textMd,
                      color: iconColor,
                    )),
              ),
              SizedBox(width: r.gapSm * 0.95),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: r.textMd,
                          fontWeight: FontWeight.w500,
                        )),
                    if (subtitle != null) ...[
                      SizedBox(height: r.gap2xs),
                      Text(subtitle!,
                          style: TextStyle(
                            fontSize: r.textXs,
                            color: context.palette.textSecondary,
                          )),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: r.iconMd, color: context.palette.textLight),
            ],
          ),
        ),
      ),
    );
  }
}