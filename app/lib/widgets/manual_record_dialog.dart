import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/app_database.dart';
import '../models/record.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import 'bulk_record_dialog.dart';

class ManualRecordDialog extends StatefulWidget {
  final AppState state;

  const ManualRecordDialog({super.key, required this.state});

  @override
  State<ManualRecordDialog> createState() => _ManualRecordDialogState();
}

class _ManualRecordDialogState extends State<ManualRecordDialog> {
  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _noteController;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _time = TimeOfDay.fromDateTime(now);
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  DateTime get _selectedTime =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _save({required bool continueEntry}) async {
    if (_saving) return;
    final selected = _selectedTime;
    if (selected.isAfter(DateTime.now())) {
      Get.snackbar('时间无效', '不能补录未来时间的记录', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final note = _noteController.text.trim();
    final fingerprint = FlightRecord(
      id: 0,
      time: selected,
      note: note,
    ).fingerprint;
    if (widget.state.records.any(
      (record) => record.fingerprint == fingerprint,
    )) {
      Get.snackbar(
        '记录已存在',
        '相同时间和感受的记录已经存在',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.state.addRecordAt(selected, note: note);
      if (!mounted) return;
      Get.snackbar(
        '补录成功',
        '已保存 ${DateFormatters.timeFull(selected)}',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (continueEntry) {
        final now = DateTime.now();
        setState(() {
          _date = DateTime(now.year, now.month, now.day);
          _time = TimeOfDay.fromDateTime(now);
          _noteController.clear();
          _saving = false;
        });
      } else {
        Get.back();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      Get.snackbar('补录失败', '$error', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _openBulkEntry() async {
    final summary = await Get.dialog<ImportSummary>(
      BulkRecordDialog(state: widget.state),
    );
    if (summary == null || !mounted) return;
    Get.snackbar(
      '批量补录完成',
      '新增 ${summary.added} 条，跳过重复 ${summary.skipped} 条',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      backgroundColor: context.palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.radiusXl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
                      Icons.edit_calendar_rounded,
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
                          '手动补录记录',
                          style: TextStyle(
                            fontSize: r.textXl,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '旧版本没有导出时，可以在这里逐条录入',
                          style: TextStyle(
                            fontSize: r.textXs,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Get.back(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: r.gapMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text(DateFormatters.dateOnly(_date)),
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _time,
                              );
                              if (picked != null) {
                                setState(() => _time = picked);
                              }
                            },
                      icon: const Icon(Icons.access_time_rounded),
                      label: Text(
                        '${_time.hour.toString().padLeft(2, '0')}:'
                        '${_time.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.gapMd),
              TextField(
                controller: _noteController,
                enabled: !_saving,
                maxLength: 120,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '当时的感受（可选）',
                  hintText: '例如：第一次独自旅行',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: r.gapSm),
              OutlinedButton.icon(
                onPressed: _saving ? null : _openBulkEntry,
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('批量输入多条记录'),
              ),
              SizedBox(height: r.gapLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => _save(continueEntry: true),
                      child: const Text('保存并继续'),
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _save(continueEntry: false),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存'),
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
