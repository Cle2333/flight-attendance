import 'package:flutter/material.dart';

import '../models/record_statistics.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class AchievementGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final bool embedded;

  const AchievementGrid({
    super.key,
    required this.achievements,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final unlocked = achievements.where((item) => item.unlocked).length;

    return Container(
      margin: embedded ? EdgeInsets.zero : r.padH(1.4),
      padding: r.padAll(1.1),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🏅 徽章',
                style: TextStyle(
                  fontSize: r.textLg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '已解锁 $unlocked / ${achievements.length}',
                style: TextStyle(
                  fontSize: r.textXs,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: r.gapSm),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = embedded && constraints.maxWidth < 480 ? 1 : 2;
              final cardWidth =
                  (constraints.maxWidth - r.gapSm * (columns - 1)) / columns;
              return Wrap(
                spacing: r.gapSm,
                runSpacing: r.gapSm,
                children: achievements.map((achievement) {
                  return SizedBox(
                    width: cardWidth,
                    child: _AchievementCard(achievement: achievement),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final unlocked = achievement.unlocked;
    final current = achievement.current.clamp(0, achievement.target);

    return Container(
      padding: r.padAll(0.8),
      decoration: BoxDecoration(
        color: unlocked
            ? context.palette.primaryBg
            : context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(r.radiusMd),
        border: Border.all(
          color: unlocked ? AppColors.primary : context.palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: r.textXl,
                  color: unlocked ? null : context.palette.textLight,
                ),
              ),
              const Spacer(),
              Icon(
                unlocked ? Icons.verified : Icons.lock_outline,
                size: r.iconSm,
                color: unlocked ? AppColors.primary : context.palette.textLight,
              ),
            ],
          ),
          SizedBox(height: r.gapXs),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: r.textSm,
              fontWeight: FontWeight.w700,
              color: unlocked ? null : context.palette.textSecondary,
            ),
          ),
          SizedBox(height: r.gap2xs),
          Text(
            unlocked
                ? achievement.description
                : '$current / ${achievement.target}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: r.textXs,
              color: context.palette.textSecondary,
            ),
          ),
          SizedBox(height: r.gapXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(r.radiusXl),
            child: LinearProgressIndicator(
              value: achievement.progress,
              minHeight: 4,
              backgroundColor: context.palette.border,
              color: unlocked ? AppColors.primary : context.palette.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
