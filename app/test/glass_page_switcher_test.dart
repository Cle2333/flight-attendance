import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_attendance_app/widgets/glass_page_switcher.dart';

void main() {
  testWidgets('页面切换保留旧页到动画结束并显示目标页', (tester) async {
    final target = ValueNotifier<int>(0);
    addTearDown(target.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: target,
          builder: (context, index, child) {
            return GlassPageSwitcher(
              index: index,
              children: const [
                ColoredBox(
                  key: ValueKey('page-0'),
                  color: Colors.red,
                  child: Center(child: Text('首页内容')),
                ),
                ColoredBox(
                  key: ValueKey('page-1'),
                  color: Colors.green,
                  child: Center(child: Text('记录内容')),
                ),
                ColoredBox(
                  key: ValueKey('page-2'),
                  color: Colors.blue,
                  child: Center(child: Text('我的内容')),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const ValueKey('page-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-1')), findsNothing);

    target.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const ValueKey('page-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-1')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('page-0')), findsNothing);
    expect(find.byKey(const ValueKey('page-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
