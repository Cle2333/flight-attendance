import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 本地图片头像；没有图片时显示统一的占位图形，不再使用 emoji 角色。
class LocalAvatar extends StatelessWidget {
  final String? imagePath;
  final double size;
  final double? iconSize;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const LocalAvatar({
    super.key,
    required this.imagePath,
    required this.size,
    this.iconSize,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final file = imagePath == null ? null : File(imagePath!);
    final hasImage = file != null;
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.primary],
        ),
        border: border,
        boxShadow: boxShadow,
      ),
      child: ClipOval(
        child: hasImage
            ? Image.file(
                file,
                key: ValueKey(imagePath),
                fit: BoxFit.cover,
                cacheWidth: cacheSize,
                cacheHeight: cacheSize,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    _Placeholder(iconSize: iconSize),
              )
            : _Placeholder(iconSize: iconSize),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double? iconSize;

  const _Placeholder({this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: iconSize ?? 28,
      ),
    );
  }
}
