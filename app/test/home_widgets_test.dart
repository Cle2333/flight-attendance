import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_attendance_app/theme/app_theme.dart';
import 'package:flight_attendance_app/widgets/premium_home_ui.dart';

Widget _card({bool compact = true}) => CountdownHeroCard(
  lastTakeoff: DateTime(2026, 10, 27, 18, 24),
  countdown: '03:18:24',
  precisionLabel: '秒级',
  totalRecords: 12,
  currentStreak: 4,
  compact: compact,
);

void main() {
  testWidgets('欢迎页在手机尺寸下无溢出且卡片高度自适应', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FlightAtmosphere(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const WelcomeHeader(greeting: '晚上好', nickname: '用户'),
                    const SizedBox(height: 32),
                    _card(),
                    const Spacer(),
                    const QuotePanel(quote: '飞行是对天空的诗意探索。', onNext: _noop),
                    const SizedBox(height: 16),
                    const TakeoffPrompt(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CountdownHeroCard)).height,
      lessThan(400),
    );
  });

  testWidgets('桌面主卡限制最大宽度并保持内容高度', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: _card(compact: false),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(CountdownHeroCard));
    expect(size.width, lessThanOrEqualTo(620));
    expect(size.height, lessThan(500));
  });
}

void _noop() {}
