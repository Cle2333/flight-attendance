import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/particle_burst.dart';
import '../widgets/premium_home_ui.dart';
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
        Positioned.fill(
          child: GestureDetector(
            onTapUp: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: FlightAtmosphere(
              child: SafeArea(
                bottom: false,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 720),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Obx(() {
                    final precision = state.settings.value.precisionEnum;
                    final last = state.lastTakeoff.value;
                    final countdown = last == null
                        ? switch (precision) {
                            CountdownPrecision.second => '--:--:--',
                            CountdownPrecision.minute => '--:--',
                            CountdownPrecision.hour => '-- 小时',
                          }
                        : formatDuration(
                            DateTime.now().difference(last),
                            precision,
                          );
                    final quotes = state.settings.value.quotes;
                    final quote = quotes.isEmpty
                        ? '每一次起飞都是一次冒险'
                        : quotes[_quoteIndex % quotes.length];
                    final nickname = state.profile.value?.nickname ?? '用户';

                    if (r.isDesktop) {
                      return _buildDesktopLayout(
                        r: r,
                        state: state,
                        nickname: nickname,
                        countdown: countdown,
                        lastTakeoff: last,
                        quote: quote,
                      );
                    }
                    return _buildMobileLayout(
                      r: r,
                      state: state,
                      nickname: nickname,
                      countdown: countdown,
                      lastTakeoff: last,
                      quote: quote,
                    );
                  }),
                ),
              ),
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

  Widget _buildMobileLayout({
    required Responsive r,
    required AppState state,
    required String nickname,
    required String countdown,
    required DateTime? lastTakeoff,
    required String quote,
  }) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(r.gapLg, r.gapMd, r.gapLg, r.gapMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WelcomeHeader(greeting: _greeting(), nickname: nickname),
                SizedBox(height: r.gapXl),
                CountdownHeroCard(
                  lastTakeoff: lastTakeoff,
                  countdown: countdown,
                  precisionLabel:
                      state.settings.value.precisionEnum.displayName,
                  totalRecords: state.totalRecords,
                  currentStreak: state.currentStreak,
                  compact: true,
                ),
                const Spacer(),
                QuotePanel(quote: quote, onNext: _nextQuote),
                SizedBox(height: r.gapMd),
                const TakeoffPrompt(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout({
    required Responsive r,
    required AppState state,
    required String nickname,
    required String countdown,
    required DateTime? lastTakeoff,
    required String quote,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = r.gapLg;
        final vertical = r.gapLg;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: max(0, constraints.maxHeight - vertical * 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WelcomeHeader(
                        greeting: _greeting(),
                        nickname: nickname,
                        large: true,
                      ),
                      SizedBox(height: r.gap2xl),
                      QuotePanel(quote: quote, onNext: _nextQuote),
                      SizedBox(height: r.gapLg),
                      const TakeoffPrompt(alignStart: true),
                    ],
                  ),
                ),
                SizedBox(width: r.gap2xl),
                Expanded(
                  flex: 6,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: CountdownHeroCard(
                        lastTakeoff: lastTakeoff,
                        countdown: countdown,
                        precisionLabel:
                            state.settings.value.precisionEnum.displayName,
                        totalRecords: state.totalRecords,
                        currentStreak: state.currentStreak,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
