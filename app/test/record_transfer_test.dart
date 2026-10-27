import 'package:flutter_test/flutter_test.dart';
import 'package:flight_attendance_app/data/record_transfer.dart';
import 'package:flight_attendance_app/models/record.dart';

void main() {
  final records = [
    FlightRecord(
      id: 1,
      time: DateTime(2026, 10, 27, 8, 30, 15),
      note: '天气很好',
      createdAt: DateTime(2026, 10, 27, 8, 30, 20),
    ),
    FlightRecord(
      id: 2,
      time: DateTime(2026, 10, 27, 18, 5),
      note: '他说"起飞了"，然后笑了\n第二行',
      createdAt: DateTime(2026, 10, 27, 18, 6),
    ),
  ];

  test('JSON 导入导出保留时间与备注', () {
    final encoded = RecordTransfer.encodeJson(
      records,
      exportedAt: DateTime(2026, 10, 27, 20),
    );
    final decoded = RecordTransfer.decode(encoded);

    expect(decoded.length, 2);
    expect(decoded.first.time, records.first.time);
    expect(decoded.first.note, records.first.note);
    expect(decoded.last.note, records.last.note);
  });

  test('CSV 支持逗号、引号和换行备注', () {
    final encoded = RecordTransfer.encodeCsv(records);
    final decoded = RecordTransfer.decode(encoded);

    expect(decoded.length, 2);
    expect(decoded.last.time, records.last.time);
    expect(decoded.last.note, records.last.note);
  });

  test('兼容旧版 JSON 数组记录', () {
    final decoded = RecordTransfer.decode('''
[
  {"time":"2026-10-27T08:30:15.000Z","note":"旧记录","user_id":1}
]
''');

    expect(decoded.single.note, '旧记录');
    expect(decoded.single.time.toUtc(), DateTime.utc(2026, 10, 27, 8, 30, 15));
  });

  test('空文件给出明确错误', () {
    expect(() => RecordTransfer.decode('   '), throwsFormatException);
  });
}
