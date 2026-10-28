import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../data/record_transfer.dart';
import '../models/record.dart';

enum RecordExportFormat { json, csv }

class PickedRecordContent {
  final String name;
  final String content;

  const PickedRecordContent({required this.name, required this.content});
}

class PickedRecordFile {
  final String name;
  final List<FlightRecord> records;

  const PickedRecordFile({required this.name, required this.records});
}

class RecordFileService {
  static const _jsonGroup = XTypeGroup(
    label: 'JSON 备份',
    extensions: ['json'],
    mimeTypes: ['application/json'],
  );
  static const _csvGroup = XTypeGroup(
    label: 'CSV 表格',
    extensions: ['csv'],
    mimeTypes: ['text/csv'],
  );

  Future<PickedRecordContent?> pickImportContent() async {
    final file = await openFile(
      acceptedTypeGroups: const [_jsonGroup, _csvGroup],
      confirmButtonText: '导入',
    );
    if (file == null) return null;
    return PickedRecordContent(
      name: file.name,
      content: await file.readAsString(),
    );
  }

  Future<PickedRecordFile?> pickImportFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [_jsonGroup, _csvGroup],
      confirmButtonText: '导入',
    );
    if (file == null) return null;
    final content = await file.readAsString();
    return PickedRecordFile(
      name: file.name,
      records: RecordTransfer.decode(content),
    );
  }

  Future<String?> exportRecords(
    List<FlightRecord> records,
    RecordExportFormat format,
  ) async {
    final isCsv = format == RecordExportFormat.csv;
    final extension = isCsv ? 'csv' : 'json';
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final suggestedName = '航班打卡-$stamp.$extension';
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [isCsv ? _csvGroup : _jsonGroup],
      confirmButtonText: '导出',
    );
    if (location == null) return null;

    final content = isCsv
        ? RecordTransfer.encodeCsv(records)
        : RecordTransfer.encodeJson(records);
    final bytes = Uint8List.fromList(utf8.encode(content));
    final file = XFile.fromData(
      bytes,
      mimeType: isCsv ? 'text/csv' : 'application/json',
      name: suggestedName,
    );
    await file.saveTo(location.path);
    return location.path;
  }
}
