import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/record_transfer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';

class BulkRecordDialog extends StatefulWidget {
  final AppState state;

  const BulkRecordDialog({super.key, required this.state});

  @override
  State<BulkRecordDialog> createState() => _BulkRecordDialogState();
}

class _BulkRecordDialogState extends State<BulkRecordDialog> {
  final _controller = TextEditingController();
  RecordImportResult? _result;
  String? _parseError;
  var _importing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _duplicateCount {
    final result = _result;
    if (result == null) return 0;
    final seen = widget.state.records
        .map((record) => record.fingerprint)
        .toSet();
    var duplicates = 0;
    for (final record in result.records) {
      if (!seen.add(record.fingerprint)) duplicates++;
    }
    return duplicates;
  }

  String get _rangeLabel {
    final records = _result?.records;
    if (records == null || records.isEmpty) return '--';
    final sorted = [...records]..sort((a, b) => a.time.compareTo(b.time));
    final first = DateFormatters.dateOnly(sorted.first.time);
    final last = DateFormatters.dateOnly(sorted.last.time);
    return first == last ? first : '$first 至 $last';
  }

  void _parse() {
    try {
      final result = RecordTransfer.decodeManualLines(_controller.text);
      setState(() {
        _result = result;
        _parseError = null;
      });
    } catch (error) {
      setState(() {
        _result = null;
        _parseError = error is FormatException ? error.message : '$error';
      });
    }
  }

  Future<void> _import() async {
    final result = _result;
    if (result == null || !result.hasRecords || _importing) return;
    setState(() => _importing = true);
    try {
      final summary = await widget.state.importRecords(result.records);
      if (mounted) Get.back(result: summary);
    } catch (error) {
      if (!mounted) return;
      setState(() => _importing = false);
      Get.snackbar(
        '批量导入失败',
        error is FormatException ? error.message : '$error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final result = _result;
    final canImport = result != null && result.hasRecords && !_importing;

    return Dialog(
      backgroundColor: context.palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: r.padAll(1.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: r.touchTarget,
                    height: r.touchTarget,
                    decoration: BoxDecoration(
                      color: context.palette.primaryBg,
                      borderRadius: BorderRadius.circular(r.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.playlist_add_rounded,
                      color: AppColors.primary,
                      size: r.iconMd,
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '批量手动补录',
                          style: TextStyle(
                            fontSize: r.textXl,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '每行一条：YYYY-MM-DD HH:mm 备注',
                          style: TextStyle(
                            fontSize: r.textXs,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: r.gapMd),
              TextField(
                controller: _controller,
                minLines: 8,
                maxLines: 12,
                enabled: !_importing,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      '2024-05-01 08:30 第一次起飞\n'
                      '2024-05-02 19:10 天气很好\n'
                      '2024-05-03 21:45',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: context.palette.surfaceMuted.withValues(
                    alpha: 0.42,
                  ),
                ),
                onChanged: (_) {
                  if (_result != null || _parseError != null) {
                    setState(() {
                      _result = null;
                      _parseError = null;
                    });
                  }
                },
              ),
              SizedBox(height: r.gapSm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '支持空格、Tab、逗号或竖线分隔备注',
                      style: TextStyle(
                        fontSize: r.textXs,
                        color: context.palette.textLight,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _importing ? null : _parse,
                    icon: const Icon(Icons.manage_search_rounded, size: 18),
                    label: const Text('解析预览'),
                  ),
                ],
              ),
              if (_parseError != null) ...[
                SizedBox(height: r.gapMd),
                _MessageCard(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.danger,
                  text: _parseError!,
                ),
              ],
              if (result != null) ...[
                SizedBox(height: r.gapMd),
                _PreviewCard(
                  total: result.records.length,
                  duplicates: _duplicateCount,
                  errors: result.issues.length,
                  range: _rangeLabel,
                  issues: result.issues,
                ),
              ],
              SizedBox(height: r.gapLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _importing ? null : () => Get.back(),
                      child: const Text('取消'),
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: canImport ? _import : null,
                      icon: _importing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download_done_rounded),
                      label: Text(
                        result == null
                            ? '先解析预览'
                            : '导入 ${result.records.length} 条',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final int total;
  final int duplicates;
  final int errors;
  final String range;
  final List<RecordImportIssue> issues;

  const _PreviewCard({
    required this.total,
    required this.duplicates,
    required this.errors,
    required this.range,
    required this.issues,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: r.padAll(1.0),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(r.radiusLg),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: r.gapSm,
            runSpacing: r.gapXs,
            children: [
              _PreviewStat(label: '可识别', value: '$total 条'),
              _PreviewStat(label: '重复', value: '$duplicates 条'),
              _PreviewStat(label: '错误', value: '$errors 条'),
            ],
          ),
          SizedBox(height: r.gapXs),
          Text(
            '时间范围：$range',
            style: TextStyle(
              fontSize: r.textXs,
              color: context.palette.textSecondary,
            ),
          ),
          if (issues.isNotEmpty) ...[
            SizedBox(height: r.gapSm),
            for (final issue in issues.take(5))
              Padding(
                padding: EdgeInsets.only(bottom: r.gap2xs),
                child: Text(
                  '第 ${issue.itemNumber} 行：${issue.message}',
                  style: TextStyle(
                    fontSize: r.textXs,
                    color: context.palette.dangerText,
                  ),
                ),
              ),
            if (issues.length > 5)
              Text(
                '另有 ${issues.length - 5} 条错误未展开',
                style: TextStyle(
                  fontSize: r.textXs,
                  color: context.palette.textLight,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: r.padHV(0.55, 0.25),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: r.textXs,
          fontWeight: FontWeight.w600,
          color: context.palette.textSecondary,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _MessageCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: r.padAll(0.8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(r.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: r.iconSm),
          SizedBox(width: r.gapXs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: r.textXs, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
