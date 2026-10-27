import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';

/// 起飞成功遮罩 —— 选感受 / 自定义 / 完成
///
/// 布局策略(桌面/手机统一):
///   Column 居中堆叠 —— emoji / 标题 / 时间 / 感受 grid / 完成按钮
///   LayoutBuilder 按可用高度算缩放因子 k,自动适配窄高度场景(避免 overflow)
///   CenteredFrame 用 contentMaxWidth(桌面 1200 / 手机 480)居中
class TakeoffSuccessOverlay extends StatefulWidget {
  final DateTime time;
  final ValueChanged<String> onComplete;
  final VoidCallback onDismiss;

  const TakeoffSuccessOverlay({
    super.key,
    required this.time,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  State<TakeoffSuccessOverlay> createState() => _TakeoffSuccessOverlayState();
}

class _TakeoffSuccessOverlayState extends State<TakeoffSuccessOverlay>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _presets = ['🔥 太爽了', '💫 燃尽了', '😰 后悔了'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    widget.onComplete(_selected ?? '');
  }

  Future<void> _showCustomDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('写下你的感受'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(hintText: '例如：飞向云端'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _selected = result);
      await _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: CenteredFrame(
              maxWidth: r.contentMaxWidth,
              child: SlideTransition(
                position: _slide,
                child: _buildContent(r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 统一布局 —— Column + Spacer 弹性分隔,不再用 SizedBox 撑间距。
  ///
  /// 设计:
  ///   - 顶部三个 Text(emoji / 标题 / 时间):自然高度,字号由 Responsive scale
  ///   - 中部 grid:用 Flexible 拿剩余空间,grid 自身按内容布局,
  ///     ConstrainedBox(maxHeight: ...) 限制最大高度防止短高场景溢
  ///   - 底部按钮:自然高度
  ///   - 两个 Spacer 弹性吸收 Column 剩余高度,内容总是垂直居中
  ///
  /// 短高场景下 grid 自动缩小(由 maxHeight clamp 控制),
  /// 不会撑爆 Column。
  Widget _buildContent(Responsive r) {
    final gridMaxW = r.compactPanelMaxWidth;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('✈️', style: TextStyle(fontSize: r.text3xl * 1.5)),
        const Spacer(),
        Text(
          '起飞成功！',
          style: TextStyle(
            color: Colors.white,
            fontSize: r.text3xl,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: r.gapXs),
        Text(
          DateFormatters.timeHM(widget.time),
          style: TextStyle(
            color: Colors.white,
            fontSize: r.textLg,
          ),
        ),
        const Spacer(),
        // grid 限宽,按 cellAspectRatio 自然计算高度,
        // 不被 ConstrainedBox 压 —— Spacer 自动收为 0。
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: gridMaxW),
          child: Padding(
            padding: r.padH(2.4),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              mainAxisSpacing: r.gapMd,
              crossAxisSpacing: r.gapMd,
              children: _buttons(),
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _complete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            padding: r.padHV(2.6, 1.0),
            shape: const StadiumBorder(),
            elevation: 4,
            shadowColor: Colors.black26,
            textStyle: TextStyle(
              fontSize: r.textLg,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('完成记录'),
        ),
      ],
    );
  }

  List<Widget> _buttons() {
    return [
      ..._presets.map(
        (p) => _FeelingButton(
          label: p,
          selected: _selected == p,
          onTap: () => setState(() => _selected = p),
        ),
      ),
      _FeelingButton(
        label: '✏️ 自定义感受',
        selected: false,
        onTap: _showCustomDialog,
      ),
    ];
  }
}

class _FeelingButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FeelingButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(r.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.radiusMd),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: r.textMd,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}