import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'flip_countdown_text.dart';

/// 首页背景：低饱和渐变、光晕与一条若隐若现的飞行轨迹。
class FlightAtmosphere extends StatelessWidget {
  final Widget child;

  const FlightAtmosphere({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTint = Color.lerp(
      palette.bg,
      AppColors.primary,
      isDark ? 0.18 : 0.08,
    )!;
    final accentTint = Color.lerp(
      palette.bg,
      AppColors.accent,
      isDark ? 0.08 : 0.16,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.bg, primaryTint, accentTint, palette.bg],
              stops: const [0, 0.34, 0.66, 1],
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -100,
          child: _GlowOrb(
            size: 380,
            color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.14),
          ),
        ),
        Positioned(
          bottom: -180,
          left: -150,
          child: _GlowOrb(
            size: 420,
            color: AppColors.accent.withValues(alpha: isDark ? 0.10 : 0.18),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _FlightPathPainter(
                lineColor: AppColors.primary.withValues(
                  alpha: isDark ? 0.30 : 0.22,
                ),
                accentColor: AppColors.accent.withValues(
                  alpha: isDark ? 0.18 : 0.28,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _FlightPathPainter extends CustomPainter {
  final Color lineColor;
  final Color accentColor;

  const _FlightPathPainter({
    required this.lineColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-size.width * 0.08, size.height * 0.58)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.34,
        size.width * 0.48,
        size.height * 0.50,
        size.width * 0.70,
        size.height * 0.27,
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.10,
        size.width * 0.93,
        size.height * 0.14,
        size.width * 1.06,
        size.height * 0.01,
      );

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, path, paint);

    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.82, size.height * 0.18),
        radius: math.min(size.width, size.height) * 0.28,
      ),
      math.pi * 0.76,
      math.pi * 0.82,
      false,
      arcPaint,
    );

    final metric = path.computeMetrics().first;
    for (final fraction in [0.18, 0.46, 0.74]) {
      final tangent = metric.getTangentForOffset(metric.length * fraction);
      if (tangent == null) continue;
      canvas.drawCircle(
        tangent.position,
        fraction == 0.46 ? 3.2 : 2.1,
        Paint()..color = accentColor,
      );
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 5, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlightPathPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.accentColor != accentColor;
  }
}

/// 首页左对齐欢迎标题区。
class WelcomeHeader extends StatelessWidget {
  final String greeting;
  final String nickname;
  final bool large;

  const WelcomeHeader({
    super.key,
    required this.greeting,
    required this.nickname,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    final now = DateTime.now();
    final weekday = const ['一', '二', '三', '四', '五', '六', '日'][now.weekday - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.gapSm,
                vertical: r.gap2xs * 1.35,
              ),
              decoration: BoxDecoration(
                color: palette.card.withValues(alpha: 0.64),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: palette.border.withValues(alpha: 0.72),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flight_takeoff_rounded,
                    size: r.iconXs,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: r.gapXs),
                  Text(
                    'FLIGHT LOG',
                    style: TextStyle(
                      fontSize: r.textXs,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: palette.text,
                    ),
                  ),
                  SizedBox(width: r.gapXs),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: r.gap2xs),
                  Text(
                    'LOCAL',
                    style: TextStyle(
                      fontSize: r.textXs * 0.82,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: palette.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!r.isCompact) ...[
              const Spacer(),
              Text(
                '${now.month}月${now.day}日 · 周$weekday',
                style: TextStyle(
                  fontSize: r.textXs,
                  fontWeight: FontWeight.w500,
                  color: palette.textLight,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: large ? r.gap2xl : r.gapXl),
        Text(
          '$greeting，',
          style: TextStyle(
            fontSize: large ? r.textLg : r.textBase,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 2.2,
          ),
        ),
        SizedBox(height: r.gapXs),
        Text(
          nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: large ? r.textDisplay : r.text4xl * 1.15,
            height: 0.98,
            fontWeight: FontWeight.w800,
            letterSpacing: large ? -2.6 : -1.8,
            color: palette.text,
          ),
        ),
        SizedBox(height: r.gapSm),
        Text(
          '把每一次起飞，留在自己的航迹里。',
          style: TextStyle(
            fontSize: large ? r.textMd : r.textSm,
            height: 1.5,
            color: palette.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// 玻璃质感的主倒计时卡片。
class CountdownHeroCard extends StatelessWidget {
  final DateTime? lastTakeoff;
  final String countdown;
  final String precisionLabel;
  final int totalRecords;
  final int currentStreak;
  final bool compact;

  const CountdownHeroCard({
    super.key,
    required this.lastTakeoff,
    required this.countdown,
    required this.precisionLabel,
    required this.totalRecords,
    required this.currentStreak,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final caption = lastTakeoff == null
        ? '双击任意位置，记录你的第一次起飞'
        : '上次起飞 · ${_monthDay(lastTakeoff!)} ${_hourMinute(lastTakeoff!)}';

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(r.gapLg * (compact ? 1.0 : 1.2)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  palette.card.withValues(alpha: 0.92),
                  Color.lerp(palette.card, AppColors.primary, 0.24)!,
                ]
              : [
                  Colors.white.withValues(alpha: 0.94),
                  Color.lerp(Colors.white, AppColors.primary, 0.10)!,
                ],
        ),
        borderRadius: BorderRadius.circular(r.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.13),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: compact ? -18 : -8,
            bottom: -22,
            child: Transform.rotate(
              angle: -0.24,
              child: Icon(
                Icons.flight_rounded,
                size: compact ? 118 : 156,
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.08 : 0.055,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusPill(
                    text: lastTakeoff == null ? '等待首次起飞' : '距上次起飞',
                    active: lastTakeoff != null,
                  ),
                  const Spacer(),
                  _MutedPill(text: '$precisionLabel更新'),
                ],
              ),
              SizedBox(height: compact ? r.gapLg : r.gapXl),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: FlipCountdownText(
                  text: countdown,
                  style: TextStyle(
                    fontSize: r.textDisplay * (compact ? 1.08 : 1.30),
                    height: 0.95,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -3.4,
                    color: isDark
                        ? AppColors.accentLight
                        : AppColors.primaryDark,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(height: r.gapMd),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: r.iconSm,
                    color: palette.textLight,
                  ),
                  SizedBox(width: r.gapXs),
                  Expanded(
                    child: Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: r.textSm,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.gapLg),
              Container(
                height: 1,
                color: palette.border.withValues(alpha: 0.72),
              ),
              SizedBox(height: r.gapMd),
              Row(
                children: [
                  Expanded(
                    child: _MetaStat(label: '累计起飞', value: '$totalRecords 次'),
                  ),
                  Container(
                    width: 1,
                    height: r.gapXl,
                    color: palette.border.withValues(alpha: 0.72),
                  ),
                  Expanded(
                    child: _MetaStat(label: '连续记录', value: '$currentStreak 天'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthDay(DateTime date) => '${date.month}月${date.day}日';

  String _hourMinute(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool active;

  const _StatusPill({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    final color = active ? AppColors.success : AppColors.warning;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.gapSm,
        vertical: r.gap2xs * 1.25,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: r.gap2xs,
            height: r.gap2xs,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: r.gapXs),
          Text(
            text,
            style: TextStyle(
              fontSize: r.textXs,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedPill extends StatelessWidget {
  final String text;

  const _MutedPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.gapSm,
        vertical: r.gap2xs * 1.25,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: r.textXs,
          fontWeight: FontWeight.w600,
          color: palette.textLight,
        ),
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  final String label;
  final String value;

  const _MetaStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: r.textXs,
            color: palette.textLight,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: r.gap2xs),
        Text(
          value,
          style: TextStyle(
            fontSize: r.textMd,
            fontWeight: FontWeight.w700,
            color: palette.text,
          ),
        ),
      ],
    );
  }
}

/// 可点击切换的语录卡片。
class QuotePanel extends StatelessWidget {
  final String quote;
  final VoidCallback onNext;

  const QuotePanel({super.key, required this.quote, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onNext,
        borderRadius: BorderRadius.circular(r.radiusLg),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: r.gapMd, vertical: r.gapSm),
          decoration: BoxDecoration(
            color: palette.card.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(r.radiusLg),
            border: Border.all(color: palette.border.withValues(alpha: 0.58)),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: r.gapXl,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日语录',
                      style: TextStyle(
                        fontSize: r.textXs * 0.9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: palette.textLight,
                      ),
                    ),
                    SizedBox(height: r.gap2xs),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Text(
                        quote,
                        key: ValueKey(quote),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.textSm,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: r.gapXs),
              Icon(
                Icons.autorenew_rounded,
                size: r.iconSm,
                color: palette.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 双击起飞提示。
class TakeoffPrompt extends StatelessWidget {
  final bool alignStart;

  const TakeoffPrompt({super.key, this.alignStart = false});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Align(
      alignment: alignStart ? Alignment.centerLeft : Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.ads_click_rounded,
            size: r.iconSm,
            color: AppColors.primary,
          ),
          SizedBox(width: r.gapXs),
          Text(
            '双击任意位置 · 立即起飞',
            style: TextStyle(
              fontSize: r.textSm,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
