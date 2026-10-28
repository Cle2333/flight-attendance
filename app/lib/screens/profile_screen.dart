import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/profile.dart';
import '../services/record_file_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/local_avatar.dart';
import '../widgets/manual_record_dialog.dart';
import '../widgets/picker_modals.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    final r = context.r;

    return SafeArea(
      bottom: false,
      child: Obx(() {
        final profile = state.profile.value ?? const LocalProfile();
        final avatarPath = state.avatarDisplayPath.value;
        final nickname = profile.nickname;

        if (r.isDesktop) {
          return _buildDesktop(context, state, avatarPath, nickname, r);
        }
        return _buildMobile(context, state, avatarPath, nickname, r);
      }),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    AppState state,
    String? avatarPath,
    String nickname,
    Responsive r,
  ) {
    return ListView(
      padding: EdgeInsets.only(bottom: r.gapLg),
      children: [
        Padding(
          padding: r.padFromLTRB(1.2, 0.9, 1.2, 0.5),
          child: const _ProfilePageHeader(
            title: '我的',
            subtitle: '本地资料、偏好与数据管理',
          ),
        ),
        _buildIdentityCard(context, state, avatarPath, nickname, r),
        SizedBox(height: r.gapMd),
        ..._buildSettingsGroups(context, state, avatarPath, nickname),
        _buildFooter(context, r, center: true),
      ],
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    AppState state,
    String? avatarPath,
    String nickname,
    Responsive r,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(r.gapMd, r.gapMd, r.gapMd, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfilePageHeader(
            title: '我的',
            subtitle: '本地资料、偏好与数据管理',
            desktop: true,
          ),
          SizedBox(height: r.gapMd),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: r.gapLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildIdentityCard(
                          context,
                          state,
                          avatarPath,
                          nickname,
                          r,
                          desktop: true,
                        ),
                        SizedBox(height: r.gapMd),
                        _StorageSummaryCard(state: state, embedded: true),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: r.gapMd),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: r.gapLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel(text: '设置', embedded: true),
                        ..._buildSettingsGroups(
                          context,
                          state,
                          avatarPath,
                          nickname,
                          embedded: true,
                        ),
                        _buildFooter(context, r, center: false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(
    BuildContext context,
    AppState state,
    String? avatarPath,
    String nickname,
    Responsive r, {
    bool desktop = false,
  }) {
    return Container(
      margin: desktop ? EdgeInsets.zero : r.padH(1.4),
      padding: r.padFromLTRB(1.4, desktop ? 1.7 : 1.6, 1.4, 1.4),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(r.radiusXl),
        border: Border.all(
          color: context.palette.border.withValues(alpha: 0.52),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickAvatar(state),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                LocalAvatar(
                  imagePath: avatarPath,
                  size: desktop ? r.avatarLg * 1.15 : r.avatarLg,
                  iconSize: r.icon2xl,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: Container(
                    width: r.touchTarget * 0.75,
                    height: r.touchTarget * 0.75,
                    decoration: BoxDecoration(
                      color: context.palette.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.palette.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: r.iconSm,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.gapSm),
          GestureDetector(
            onTap: () => Get.dialog(
              NicknameEditor(current: nickname, onSave: state.updateNickname),
            ),
            child: Text(
              nickname,
              style: TextStyle(
                fontSize: desktop ? r.text2xl : r.textXl,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          SizedBox(height: r.gapXs * 0.5),
          Text(
            '全部数据仅保存在本机',
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
    );
  }

  List<Widget> _buildSettingsGroups(
    BuildContext context,
    AppState state,
    String? avatarPath,
    String nickname, {
    bool embedded = false,
  }) {
    return [
      _Group(
        embedded: embedded,
        children: [
          _Row(
            icon: '✏️',
            color: context.palette.primaryBg,
            title: '修改昵称',
            subtitle: '当前：$nickname',
            onTap: () => Get.dialog(
              NicknameEditor(current: nickname, onSave: state.updateNickname),
            ),
          ),
          _Row(
            icon: '🖼️',
            color: context.palette.infoBg,
            title: '上传头像',
            subtitle: avatarPath == null ? '从本地选择图片' : '已使用本地图片',
            onTap: () => _pickAvatar(state),
          ),
        ],
      ),
      _Group(
        embedded: embedded,
        children: [
          _Row(
            icon: '⏱️',
            color: context.palette.primaryBg,
            title: '计时精度',
            subtitle: '当前：${state.settings.value.precisionEnum.displayName}',
            onTap: () => Get.dialog(
              PrecisionPicker(
                current: state.settings.value.precisionEnum,
                onPick: (precision) => state.updatePrecision(precision.name),
              ),
            ),
          ),
          _Row(
            icon: '🎆',
            color: context.palette.infoBg,
            title: '起飞特效',
            subtitle: '当前：${state.settings.value.effectEmoji}',
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
        embedded: embedded,
        children: [
          _Row(
            icon: '✍️',
            color: context.palette.successBg,
            title: '手动补录记录',
            subtitle: '逐条补录旧版本数据，支持批量输入多行',
            onTap: () => _openManualRecordDialog(state),
          ),
          _Row(
            icon: '📥',
            color: context.palette.primaryBg,
            title: '从文件导入',
            subtitle: '支持 JSON 备份与 CSV 表格，重复记录自动跳过',
            onTap: () => _importRecords(state),
          ),
          _Row(
            icon: '📤',
            color: context.palette.primaryBg,
            title: '导出 JSON 备份',
            subtitle: '包含时间、感受和记录创建时间',
            onTap: () => _exportRecords(state, RecordExportFormat.json),
          ),
          _Row(
            icon: '📤',
            color: context.palette.infoBg,
            title: '导出 CSV 表格',
            subtitle: '可用 Excel、Numbers 等表格软件打开',
            onTap: () => _exportRecords(state, RecordExportFormat.csv),
          ),
          _Row(
            icon: '💾',
            color: context.palette.warningBg,
            title: '本地 SQLite 数据库',
            subtitle: '${state.totalRecords} 条记录 · 点击查看文件位置',
            onTap: () => Get.dialog(
              AlertDialog(
                title: const Text('本地数据位置'),
                content: SelectableText(state.database.location),
                actions: [
                  TextButton(onPressed: Get.back, child: const Text('知道了')),
                ],
              ),
            ),
          ),
        ],
      ),
      _Group(
        embedded: embedded,
        children: [
          _Row(
            icon: state.themeMode.value == ThemeMode.dark ? '🌙' : '☀️',
            color: context.palette.primaryBg,
            title: '外观主题',
            subtitle: switch (state.themeMode.value) {
              ThemeMode.light => '当前：浅色',
              ThemeMode.dark => '当前：深色',
              ThemeMode.system => '当前：跟随系统',
            },
            onTap: () async {
              final mode = state.themeMode.value;
              final picked = await Get.dialog<ThemeMode>(
                AlertDialog(
                  title: const Text('外观主题'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ThemeOption(
                        mode: ThemeMode.system,
                        current: mode,
                        label: '跟随系统',
                        icon: '⚙️',
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
              if (picked != null) await state.setThemeMode(picked);
            },
          ),
        ],
      ),
    ];
  }

  Widget _buildFooter(
    BuildContext context,
    Responsive r, {
    required bool center,
  }) {
    return Padding(
      padding: r.padFromLTRB(1.6, 0.6, 1.6, 0),
      child: Text(
        '航班打卡 · 纯本地版\n不上传、不登录、不联网',
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: r.textXs,
          color: context.palette.textLight,
          height: 1.6,
        ),
      ),
    );
  }

  Future<void> _openManualRecordDialog(AppState state) async {
    await Get.dialog(ManualRecordDialog(state: state));
  }

  Future<void> _pickAvatar(AppState state) async {
    try {
      final path = await state.chooseAvatar();
      if (path == null) return;
      Get.snackbar('头像已更新', '头像图片已保存到本机', snackPosition: SnackPosition.BOTTOM);
    } catch (error) {
      final message = switch (error) {
        FormatException(:final message) => message,
        FileSystemException(:final message) => message,
        _ => '请选择 10 MB 以内的 PNG、JPG、WEBP 或 BMP 图片',
      };
      Get.snackbar('头像上传失败', message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _importRecords(AppState state) async {
    try {
      final picked = await state.fileService.pickImportFile();
      if (picked == null) return;
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('确认导入'),
          content: Text(
            '文件：${picked.name}\n'
            '读取到 ${picked.records.length} 条记录。\n'
            '导入时按“起飞时间 + 感受”去重，不会覆盖已有记录。',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('开始导入'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final summary = await state.importRecords(picked.records);
      Get.snackbar(
        '导入完成',
        '新增 ${summary.added} 条，跳过重复 ${summary.skipped} 条',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar('导入失败', '$error', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _exportRecords(AppState state, RecordExportFormat format) async {
    try {
      final path = await state.fileService.exportRecords(state.records, format);
      if (path == null) return;
      Get.snackbar('导出完成', path, snackPosition: SnackPosition.BOTTOM);
    } catch (error) {
      Get.snackbar('导出失败', '$error', snackPosition: SnackPosition.BOTTOM);
    }
  }
}

class _ProfilePageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool desktop;

  const _ProfilePageHeader({
    required this.title,
    required this.subtitle,
    this.desktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: desktop ? r.text3xl : r.text2xl,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: r.gap2xs),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: r.textXs,
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool embedded;

  const _SectionLabel({required this.text, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: embedded
          ? EdgeInsets.only(bottom: r.gapXs)
          : r.padFromLTRB(1.4, 0.2, 1.4, 0.6),
      child: Text(
        text,
        style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StorageSummaryCard extends StatelessWidget {
  final AppState state;
  final bool embedded;

  const _StorageSummaryCard({required this.state, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      margin: embedded ? EdgeInsets.zero : r.padH(1.4),
      padding: r.padAll(1.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.palette.card,
            Color.lerp(context.palette.card, AppColors.primary, 0.08)!,
          ],
        ),
        borderRadius: BorderRadius.circular(r.radiusLg),
        border: Border.all(
          color: context.palette.border.withValues(alpha: 0.52),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: r.touchTarget,
            height: r.touchTarget,
            decoration: BoxDecoration(
              color: context.palette.primaryBg,
              borderRadius: BorderRadius.circular(r.radiusSm),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.storage_rounded,
              color: AppColors.primary,
              size: r.iconMd,
            ),
          ),
          SizedBox(width: r.gapSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本地数据空间',
                  style: TextStyle(
                    fontSize: r.textSm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: r.gap2xs),
                Text(
                  '${state.totalRecords} 条记录 · 全部保存在 SQLite',
                  style: TextStyle(
                    fontSize: r.textXs,
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            fontSize: r.textLg,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
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
  final bool embedded;

  const _Group({required this.children, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      margin: embedded
          ? EdgeInsets.only(bottom: r.gapSm)
          : r.padFromLTRB(1.4, 0.8, 1.4, 0),
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
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                color: context.palette.border,
                indent: r.gapMd,
                endIndent: r.gapMd,
              ),
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
      child: Padding(
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
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
                child: Text(icon, style: TextStyle(fontSize: r.textMd)),
              ),
              SizedBox(width: r.gapSm * 0.95),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: r.textMd,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: r.gap2xs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.textXs,
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: r.iconMd,
                color: context.palette.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
