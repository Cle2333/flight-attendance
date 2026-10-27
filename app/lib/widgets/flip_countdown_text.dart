import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 逐字符翻页倒计时。只有发生变化的数字会翻转，其余字符保持静止。
class FlipCountdownText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const FlipCountdownText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  Widget build(BuildContext context) {
    final characters = text.split('');
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final character in characters)
              if (RegExp(r'[0-9]').hasMatch(character))
                _FlipDigit(value: character, style: style, duration: duration)
              else
                Text(character, style: style),
          ],
        ),
      ),
    );
  }
}

class _FlipDigit extends StatelessWidget {
  final String value;
  final TextStyle style;
  final Duration duration;

  const _FlipDigit({
    required this.value,
    required this.style,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return _FlipTransition(animation: animation, child: child);
          },
          child: Text(value, key: ValueKey(value), style: style),
        ),
      ),
    );
  }
}

class _FlipTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FlipTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final progress = animation.value.clamp(0.0, 1.0);
        final angle = (1 - progress) * math.pi / 2;
        final shade = (1 - progress) * 0.34;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateX(angle);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: Stack(
            alignment: Alignment.center,
            children: [
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: shade),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
