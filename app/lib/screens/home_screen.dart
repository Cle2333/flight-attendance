import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/particle_burst.dart';
import '../widgets/takeoff_success_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _countdownTimer;
  int _quoteIndex = 0;
  final _rand = Random();

  DateTime? _lastTap;
  Offset _lastTapPos = Offset.zero;

  DateTime? _pendingTakeoff;
  final List<_ParticleLayer> _particleLayers = [];
  int _particleKey = 0;

  @override
  void initState() {
    super.initState();
    _pickQuote();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _pickQuote() {
    final quotes = Get.find<AppState>().settings.value.quotes;
    if (quotes.isEmpty) return;
    _quoteIndex = _rand.nextInt(quotes.length);
  }

  void _nextQuote() {
    final quotes = Get.find<AppState>().settings.value.quotes;
    if (quotes.isEmpty) return;
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % quotes.length;
    });
  }

  void _handleTap(TapUpDetails details) {
    final now = DateTime.now();
    final pos = details.localPosition;
    // 桌面/移动的双击容差按屏幕宽度比例算 —— 30 写死太小/太大都不行
    final tapTolerance = MediaQuery.of(context).size.shortestSide * 0.04;
    if (_lastTap != null &&
        now.difference(_lastTap!).inMilliseconds < 300 &&
        (pos - _lastTapPos).distance < tapTolerance) {
      _takeOff(pos);
      _lastTap = null;
    } else {
      _lastTap = now;
      _lastTapPos = pos;
    }
  }

  Future<void> _takeOff(Offset localPos) async {
    final state = Get.find<AppState>();
    final record = await state.takeOff();
    if (!mounted) return;
    setState(() {
      _particleKey++;
      _particleLayers.add(
        _ParticleLayer(
          key: ValueKey(_particleKey),
          emoji: state.settings.value.effectEmoji,
          center: localPos,
        ),
      );
      _pendingTakeoff = record.time;
    });
  }

  Future<void> _completeTakeoff(String note) async {
    if (note.isNotEmpty) {
      await Get.find<AppState>().setLastRecordNote(note);
    }
    if (mounted) {
      setState(() => _pendingTakeoff = null);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '凌晨好';
    if (h < 12) return '早上好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    final r = context.r;

    return Stack(
      children: [
        // Positioned.fill —— 不再套 CenteredFrame,让桌面端主内容
        // 铺满整个 IndexedStack 宽度。内部 Column 用 crossAxisAlignment:
        // center 居中,空白从两侧流出,看上去仍是居中的。
        Positioned.fill(
          child: GestureDetector(
            onTapUp: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              bottom: false,
              child: r.isDesktop
                  ? _buildDesktopLayout(r, state)
                  : _buildMobileLayout(r, state),
            ),
          ),
        ),

        for (final layer in _particleLayers)
          ParticleBurst(
            key: layer.key,
            emoji: layer.emoji,
            center: layer.center,
            onComplete: () {
              if (mounted) {
                setState(() => _particleLayers.remove(layer));
              }
            },
          ),

        if (_pendingTakeoff != null)
          TakeoffSuccessOverlay(
            time: _pendingTakeoff!,
            onDismiss: () => setState(() => _pendingTakeoff = null),
            onComplete: _completeTakeoff,
          ),
      ],
    );
  }

  /// 手机端:纵向堆叠,顶/中/底三块用 Spacer 撑开(原设计)
  Widget _buildMobileLayout(Responsive r, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 问候 + 👋 同行,昵称在下一行 —— 跟桌面端结构完全一致,
        // 桌面端手机端统一居中。
        Padding(
          padding: r.padFromLTRB(0, 0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _greeting(),
                    style: TextStyle(
                      fontSize: r.textXl,
                      color: context.palette.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: r.gapXs),
                  Padding(
                    padding: EdgeInsets.only(bottom: r.gap2xs),
                    child: Text('👋',
                        style: TextStyle(fontSize: r.text2xl)),
                  ),
                ],
              ),
              SizedBox(height: r.gapXs),
              Obx(
                () => Text(
                  state.currentUser.value?.nickname ?? '用户',
                  style: TextStyle(
                    fontSize: r.text4xl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Obx(() {
          final last = state.lastTakeoff.value;
          if (last == null || state.records.isEmpty) {
            return const SizedBox.shrink();
          }
          final diff = DateTime.now().difference(last);
          final display = formatDuration(
            diff,
            state.settings.value.precisionEnum,
          );
          return Column(
            children: [
              Text(
                '距离上次起飞',
                style: TextStyle(
                  fontSize: r.textLg,
                  color: context.palette.textSecondary,
                ),
              ),
              SizedBox(height: r.gapSm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: r.textDisplay,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          );
        }),
        const Spacer(),
        GestureDetector(
          onTap: _nextQuote,
          child: Obx(() {
            final quotes = state.settings.value.quotes;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                quotes.isEmpty
                    ? '每一次起飞都是一次冒险'
                    : quotes[_quoteIndex % quotes.length],
                key: ValueKey(_quoteIndex),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.textBase,
                  color: context.palette.textLight,
                ),
              ),
            );
          }),
        ),
        SizedBox(height: r.gapLg),
        Text(
          '双击屏幕起飞',
          style: TextStyle(
            fontSize: r.textLg,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: r.gapLg),
      ],
    );
  }

  /// 桌面端:纵向三段,每段都居中
  ///   - 顶部:问候 + 昵称 + 👋(昵称和 emoji 一行,问候在上,整体居中)
  ///   - 中部:距离上次起飞 + 大字 display(居中)
  ///   - 底部:quote + "双击屏幕起飞" 提示(居中)
  /// Spacer 三段分隔,使各段在垂直方向也均匀分布。
  Widget _buildDesktopLayout(Responsive r, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── 顶部:问候 + 昵称 + 👋 居中横排 ──────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _greeting(),
              style: TextStyle(
                fontSize: r.textXl,
                color: context.palette.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: r.gapXs),
            // 昵称 + 👋 emoji 同行,emoji 紧跟在文字后
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Obx(
                  () => Text(
                    state.currentUser.value?.nickname ?? '用户',
                    style: TextStyle(
                      fontSize: r.text4xl,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                SizedBox(width: r.gapXs),
                Padding(
                  padding: EdgeInsets.only(bottom: r.gap2xs),
                  child: Text('👋',
                      style: TextStyle(fontSize: r.text2xl)),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        // ── 中部:倒计时大字,居中 ──────────────────────
        Obx(() {
          final last = state.lastTakeoff.value;
          if (last == null || state.records.isEmpty) {
            return const SizedBox.shrink();
          }
          final diff = DateTime.now().difference(last);
          final display = formatDuration(
            diff,
            state.settings.value.precisionEnum,
          );
          return Column(
            children: [
              Text(
                '距离上次起飞',
                style: TextStyle(
                  fontSize: r.textLg,
                  color: context.palette.textSecondary,
                ),
              ),
              SizedBox(height: r.gapSm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: r.textDisplay,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          );
        }),
        const Spacer(),
        // ── 底部:quote + 起飞提示,居中 ────────────────────
        Column(
          children: [
            GestureDetector(
              onTap: _nextQuote,
              child: Obx(() {
                final quotes = state.settings.value.quotes;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    quotes.isEmpty
                        ? '每一次起飞都是一次冒险'
                        : quotes[_quoteIndex % quotes.length],
                    key: ValueKey(_quoteIndex),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.textBase,
                      color: context.palette.textLight,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: r.gapLg),
            Text(
              '双击屏幕起飞',
              style: TextStyle(
                fontSize: r.textLg,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: r.gapLg),
      ],
    );
  }
}

class _ParticleLayer {
  final ValueKey<int> key;
  final String emoji;
  final Offset center;
  _ParticleLayer({
    required this.key,
    required this.emoji,
    required this.center,
  });
}
