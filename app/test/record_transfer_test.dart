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

  test('兼容旧版 data 数组、字段别名和秒级时间戳', () {
    final result = RecordTransfer.decodeDetailed('''
{
  "success": true,
  "data": [
    {"id": 7, "timestamp": 1714552200, "remark": "旧版补录", "user_id": 2}
  ]
}
''');

    expect(result.records, hasLength(1));
    expect(result.records.single.note, '旧版补录');
    expect(result.records.single.time.toUtc(), DateTime.utc(2024, 5, 1, 8, 30));
    expect(result.issues, isEmpty);
  });

  test('兼容嵌套 data.records 并保留有效记录、报告坏记录', () {
    final result = RecordTransfer.decodeDetailed('''
{
  "data": {
    "records": [
      {"event_time": "2024-05-01T08:30:00Z", "feeling": "第一条"},
      {"note": "缺少时间"}
    ]
  }
}
''');

    expect(result.records, hasLength(1));
    expect(result.records.single.note, '第一条');
    expect(result.issues, hasLength(1));
    expect(result.issues.single.itemNumber, 2);
  });

  test('批量手动输入支持空格、Tab、逗号和竖线备注', () {
    final result = RecordTransfer.decodeManualLines('''
2024-05-01 08:30 第一次起飞
2024-05-02 19:10, 天气很好
2024-05-03 21:45 | 夜航
2024-05-04 06:20\t早班
''');

    expect(result.records, hasLength(4));
    expect(result.records[0].note, '第一次起飞');
    expect(result.records[1].note, '天气很好');
    expect(result.records[2].note, '夜航');
    expect(result.records[3].note, '早班');
    expect(result.issues, isEmpty);
  });

  test('批量手动输入会保留有效行并报告错误行', () {
    final result = RecordTransfer.decodeManualLines('''
2024-05-01 08:30 有效
格式错误的一行
2024-13-40 99:99 无效日期
''');

    expect(result.records, hasLength(1));
    expect(result.records.single.note, '有效');
    expect(result.issues, hasLength(2));
    expect(result.issues.first.itemNumber, 2);
    expect(result.issues.last.itemNumber, 3);
  });

  test('CSV 支持中文表头', () {
    final result = RecordTransfer.decodeDetailed('''
时间,备注
2024-05-01 08:30:00,旧记录
''');

    expect(result.records.single.note, '旧记录');
    expect(result.records.single.time, DateTime(2024, 5, 1, 8, 30));
  });

  test('空文件给出明确错误', () {
    expect(() => RecordTransfer.decode('   '), throwsFormatException);
  });
}
