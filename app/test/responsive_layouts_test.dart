import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_attendance_app/models/record.dart';
import 'package:flight_attendance_app/models/record_statistics.dart';
import 'package:flight_attendance_app/screens/desktop_sidebar.dart';
import 'package:flight_attendance_app/theme/app_theme.dart';
import 'package:flight_attendance_app/widgets/achievement_grid.dart';
import 'package:flight_attendance_app/widgets/calendar_widget.dart';
import 'package:flight_attendance_app/widgets/monthly_report_card.dart';
import 'package:flight_attendance_app/widgets/stats_grid.dart';

void main() {
  testWidgets('桌面侧边栏显示完整导航且无溢出', (tester) async {
    await _setSize(tester, const Size(240, 760));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: DesktopSidebar(index: 1, onChanged: _noop)),
      ),
    );

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('本地 SQLite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('记录组件在手机单栏下无溢出', (tester) async {
    await _setSize(tester, const Size(390, 844));
    await tester.pumpWidget(_recordsPreview(desktop: false));
    expect(find.text('航班记录'), findsOneWidget);
    expect(find.text('快速统计'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('记录组件在桌面双栏下无溢出', (tester) async {
    await _setSize(tester, const Size(1280, 860));
    await tester.pumpWidget(_recordsPreview(desktop: true));
    expect(find.text('航班记录'), findsOneWidget);
    expect(find.text('起飞记录'), findsOneWidget);
    await tester.pump();
  });
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _recordsPreview({required bool desktop}) {
  final record = FlightRecord(
    id: 1,
    time: DateTime.now().subtract(const Duration(hours: 2)),
    note: '布局测试',
  );
  final report = RecordStatistics.monthlyReport([record], DateTime.now());
  final achievements = RecordStatistics.achievements(
    totalRecords: 1,
    longestStreak: 1,
  );

  Widget header() => const Row(
    children: [
      Icon(Icons.flight_takeoff_rounded, color: Colors.blue, size: 36),
      SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '航班记录',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 3),
          Text('日历、月报与每一次起飞'),
        ],
      ),
    ],
  );

  final left = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CalendarWidget(
        currentDate: DateTime.now(),
        onMonthChanged: _noop,
        hasRecordOn: (_) => true,
        onDateTapped: (_) {},
        expandedNotifier: ValueNotifier(false),
      ),
      const SizedBox(height: 16),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          '快速统计',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            StatCard(
              icon: '✈️',
              iconBg: Color(0xFFEFF6FF),
              value: '1',
              label: '总起飞次数',
            ),
            SizedBox(height: 12),
            StatCard(
              icon: '🔥',
              iconBg: Color(0xFFDCFCE7),
              value: '1',
              label: '连续天数',
            ),
          ],
        ),
      ),
    ],
  );

  final right = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MonthlyReportCard(report: report),
      const SizedBox(height: 16),
      AchievementGrid(achievements: achievements),
      const SizedBox(height: 16),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '起飞记录',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );

  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: SafeArea(
        child: desktop
            ? Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 330,
                            child: SingleChildScrollView(child: left),
                          ),
                          const SizedBox(width: 28),
                          Expanded(child: SingleChildScrollView(child: right)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                children: [
                  Padding(padding: const EdgeInsets.all(20), child: header()),
                  left,
                  right,
                  const SizedBox(height: 24),
                ],
              ),
      ),
    ),
  );
}

void _noop(int _) {}
