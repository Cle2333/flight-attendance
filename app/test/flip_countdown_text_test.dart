import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flight_attendance_app/widgets/flip_countdown_text.dart';

void main() {
  testWidgets('倒计时只翻转变化的数字并在结束后移除旧数字', (tester) async {
    final text = ValueNotifier<String>('00:00:58');
    addTearDown(text.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder<String>(
              valueListenable: text,
              builder: (context, value, child) {
                return FlipCountdownText(
                  text: value,
                  style: const TextStyle(fontSize: 44),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('8'), findsOneWidget);
    expect(find.text('9'), findsNothing);

    text.value = '00:00:59';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.text('8'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('8'), findsNothing);
    expect(find.text('9'), findsOneWidget);
  });
}
