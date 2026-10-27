import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';

/// 头像选择
class AvatarPicker extends StatefulWidget {
  final String current;
  final ValueChanged<String> onPick;
  const AvatarPicker({super.key, required this.current, required this.onPick});

  static const _emojis = [
    '✈️', '🚀', '🌟', '🎉', '💫', '🔥', '⚡', '🎯',
    '🦅', '🕊️', '🛸', '🎈', '🌈', '☀️', '🌙', '⭐',
  ];

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  late String _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radiusLg)),
      backgroundColor: context.palette.card,
      // 限制最大宽 + childAspectRatio:1.5，避免桌面端 GridView
      // 把格子拉成正方大块撑爆对话框
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: r.padAll(1.25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '选择头像',
                style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: r.gapMd),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5, // 格子宽于高
                mainAxisSpacing: r.gapSm,
                crossAxisSpacing: r.gapSm,
                children: AvatarPicker._emojis.map((e) {
                  final isSelected = e == _selected;
                  return InkWell(
                    onTap: () => setState(() => _selected = e),
                    borderRadius: BorderRadius.circular(r.radiusSm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? context.palette.primaryBg : context.palette.card,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : context.palette.border,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(r.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: TextStyle(fontSize: r.text2xl * 1.3)),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: r.gapMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.onPick(_selected);
                        Navigator.pop(context);
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 起飞特效 emoji 选择（少 8 个）
class EffectEmojiPicker extends StatefulWidget {
  final String current;
  final ValueChanged<String> onPick;
  const EffectEmojiPicker({super.key, required this.current, required this.onPick});

  static const _emojis = ['✈️', '🚀', '🌟', '🎉', '💫', '🔥', '⚡', '🎯'];

  @override
  State<EffectEmojiPicker> createState() => _EffectEmojiPickerState();
}

class _EffectEmojiPickerState extends State<EffectEmojiPicker> {
  late String _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radiusLg)),
      backgroundColor: context.palette.card,
      // 限制最大宽 + childAspectRatio:1.5，避免桌面端 GridView
      // 把格子拉成正方大块撑爆对话框
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: r.padAll(1.25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '起飞特效 Emoji',
                style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: r.gapMd),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5, // 格子宽于高
                mainAxisSpacing: r.gapSm,
                crossAxisSpacing: r.gapSm,
                children: EffectEmojiPicker._emojis.map((e) {
                  final isSelected = e == _selected;
                  return InkWell(
                    onTap: () => setState(() => _selected = e),
                    borderRadius: BorderRadius.circular(r.radiusSm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? context.palette.primaryBg : context.palette.card,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : context.palette.border,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(r.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: TextStyle(fontSize: r.text2xl * 1.3)),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: r.gapMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.onPick(_selected);
                        Navigator.pop(context);
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 计时精度选择
class PrecisionPicker extends StatefulWidget {
  final CountdownPrecision current;
  final ValueChanged<CountdownPrecision> onPick;
  const PrecisionPicker({super.key, required this.current, required this.onPick});

  @override
  State<PrecisionPicker> createState() => _PrecisionPickerState();
}

class _PrecisionPickerState extends State<PrecisionPicker> {
  late CountdownPrecision _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radiusLg)),
      backgroundColor: context.palette.card,
      child: Padding(
        padding: r.padAll(1.25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '计时精度',
              style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: r.gapMd),
            RadioGroup<CountdownPrecision>(
              groupValue: _selected,
              onChanged: (v) {
                if (v != null) setState(() => _selected = v);
              },
              child: Column(
                children: CountdownPrecision.values
                    .map((p) => RadioListTile<CountdownPrecision>(
                          value: p,
                          title: Text(p.displayName),
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: r.gapXs),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onPick(_selected);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 昵称编辑
class NicknameEditor extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSave;
  const NicknameEditor({super.key, required this.current, required this.onSave});

  @override
  State<NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends State<NicknameEditor> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radiusLg)),
      backgroundColor: context.palette.card,
      child: Padding(
        padding: r.padAll(1.25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '修改昵称',
              style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: r.gapMd),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(hintText: '请输入新昵称'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final v = _ctrl.text.trim();
                      if (v.isEmpty) return;
                      if (v.length > 20) return;
                      widget.onSave(v);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 机长语录编辑
class QuotesEditor extends StatefulWidget {
  final List<String> initial;
  final ValueChanged<List<String>> onSave;
  const QuotesEditor({super.key, required this.initial, required this.onSave});

  @override
  State<QuotesEditor> createState() => _QuotesEditorState();
}

class _QuotesEditorState extends State<QuotesEditor> {
  late final List<TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    final init = widget.initial.isEmpty ? [''] : widget.initial;
    _ctrls = init.map((q) => TextEditingController(text: q)).toList();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _add() {
    setState(() => _ctrls.add(TextEditingController()));
  }

  void _remove(int i) {
    if (_ctrls.length <= 1) return;
    setState(() {
      _ctrls[i].dispose();
      _ctrls.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radiusLg)),
      backgroundColor: context.palette.card,
      child: Padding(
        padding: r.padAll(1.25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '机长语录',
              style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: r.gapSm),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: r.gapXl * 11),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_ctrls.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: r.gapXs),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ctrls[i],
                              decoration: const InputDecoration(hintText: '一条语录'),
                            ),
                          ),
                          SizedBox(width: r.gapXs),
                          IconButton(
                            onPressed: () => _remove(i),
                            icon: Icon(Icons.delete_outline,
                                color: AppColors.danger, size: r.iconMd),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _add,
              icon: Icon(Icons.add, size: r.iconMd),
              label: const Text('添加语录'),
            ),
            SizedBox(height: r.gapSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final list = _ctrls
                          .map((c) => c.text.trim())
                          .where((s) => s.isNotEmpty)
                          .toList();
                      widget.onSave(list);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 后端地址配置
class ServerConfigModal extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSave;
  const ServerConfigModal({super.key, required this.current, required this.onSave});

  @override
  State<ServerConfigModal> createState() => _ServerConfigModalState();
}

class _ServerConfigModalState extends State<ServerConfigModal> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radiusLg)),
      backgroundColor: context.palette.card,
      child: Padding(
        padding: r.padAll(1.25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '服务器地址',
              style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: r.gapXs),
            Text(
              '默认 https://flight.cmach.qzz.io',
              style: TextStyle(fontSize: r.textXs, color: context.palette.textSecondary),
            ),
            SizedBox(height: r.gapSm),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://flight.cmach.qzz.io',
              ),
            ),
            SizedBox(height: r.gapMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final v = _ctrl.text.trim();
                      if (v.isEmpty) return;
                      widget.onSave(v);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}