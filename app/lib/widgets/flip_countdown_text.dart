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

class _FlipDigit extends StatefulWidget {
  final String value;
  final TextStyle style;
  final Duration duration;

  const _FlipDigit({
    required this.value,
    required this.style,
    required this.duration,
  });

  @override
  State<_FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<_FlipDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _currentValue;
  late String _previousValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _previousValue = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1;
  }

  @override
  void didUpdateWidget(covariant _FlipDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.value == widget.value) return;
    _previousValue = _currentValue;
    _currentValue = widget.value;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: TextSpan(text: '0', style: widget.style),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble() + 2;
    final height = painter.height.ceilToDouble() + 2;

    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;
            if (progress <= 0 || progress >= 1) {
              return _buildStatic(width, height);
            }
            if (progress < 0.5) {
              final fold = progress * 2;
              return _buildFirstHalf(width, height, fold);
            }
            final unfold = (progress - 0.5) * 2;
            return _buildSecondHalf(width, height, unfold);
          },
        ),
      ),
    );
  }

  Widget _buildStatic(double width, double height) {
    return Center(child: Text(_currentValue, style: widget.style));
  }

  Widget _buildFirstHalf(double width, double height, double fold) {
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0018)
      ..rotateX(fold * math.pi / 2);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: transform,
            child: _DigitHalf(
              value: _previousValue,
              style: widget.style,
              width: width,
              height: height,
              top: true,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _DigitHalf(
            value: _previousValue,
            style: widget.style,
            width: width,
            height: height,
            top: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondHalf(double width, double height, double unfold) {
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0018)
      ..rotateX(-(1 - unfold) * math.pi / 2);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _DigitHalf(
            value: _currentValue,
            style: widget.style,
            width: width,
            height: height,
            top: true,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: transform,
            child: _DigitHalf(
              value: _currentValue,
              style: widget.style,
              width: width,
              height: height,
              top: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _DigitHalf extends StatelessWidget {
  final String value;
  final TextStyle style;
  final double width;
  final double height;
  final bool top;

  const _DigitHalf({
    required this.value,
    required this.style,
    required this.width,
    required this.height,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: width,
        height: height / 2,
        child: OverflowBox(
          alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
          minWidth: width,
          maxWidth: width,
          minHeight: height,
          maxHeight: height,
          child: SizedBox(
            width: width,
            height: height,
            child: Align(
              alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
              child: Text(value, style: style),
            ),
          ),
        ),
      ),
    );
  }
}
