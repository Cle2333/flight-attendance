import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_attendance_app/screens/main_dock.dart';
import 'package:flight_attendance_app/theme/app_theme.dart';

void main() {
  testWidgets('主界面只保留三个纯本地 tab', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          bottomNavigationBar: MainDock(index: 0, onChanged: (_) {}),
        ),
      ),
    );

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('排行'), findsNothing);
  });
}
