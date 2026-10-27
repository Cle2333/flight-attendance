import 'package:flutter/material.dart';

/// 保留所有页面状态，并以轻微方向位移、淡入淡出和缩放切换页面。
class GlassPageSwitcher extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const GlassPageSwitcher({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 440),
  });

  @override
  State<GlassPageSwitcher> createState() => _GlassPageSwitcherState();
}

class _GlassPageSwitcherState extends State<GlassPageSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  late int _previousIndex;
  late int _currentIndex;
  var _direction = 1.0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.index;
    _currentIndex = widget.index;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1;
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant GlassPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.index == widget.index) return;
    _previousIndex = oldWidget.index;
    _currentIndex = widget.index;
    _direction = widget.index > oldWidget.index ? 1 : -1;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final progress = _curve.value;
        return Stack(
          fit: StackFit.expand,
          children: List.generate(widget.children.length, (index) {
            final isCurrent = index == _currentIndex;
            final isPrevious = index == _previousIndex && !isCurrent;
            final opacity = isCurrent
                ? progress
                : isPrevious
                ? 1 - progress
                : 0.0;
            final offset = isCurrent
                ? Offset(_direction * 30 * (1 - progress), 0)
                : Offset(-_direction * 18 * progress, 0);
            final scale = isCurrent
                ? 0.992 + 0.008 * progress
                : 1 - 0.004 * progress;

            return Offstage(
              offstage: opacity <= 0,
              child: IgnorePointer(
                ignoring: !isCurrent,
                child: Opacity(
                  opacity: opacity.clamp(0, 1),
                  child: Transform.translate(
                    offset: offset,
                    child: Transform.scale(
                      scale: scale,
                      child: RepaintBoundary(child: widget.children[index]),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
