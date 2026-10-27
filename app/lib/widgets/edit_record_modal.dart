import 'package:flutter/material.dart';

import '../models/record.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';

/// 编辑单条记录的起飞时间与感受。
class EditRecordModal extends StatefulWidget {
  final FlightRecord record;
  final Future<void> Function(DateTime newTime, String note) onSave;

  const EditRecordModal({
    super.key,
    required this.record,
    required this.onSave,
  });

  @override
  State<EditRecordModal> createState() => _EditRecordModalState();
}

class _EditRecordModalState extends State<EditRecordModal> {
  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _noteController;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.record.time.year,
      widget.record.time.month,
      widget.record.time.day,
    );
    _time = TimeOfDay(
      hour: widget.record.time.hour,
      minute: widget.record.time.minute,
    );
    _noteController = TextEditingController(text: widget.record.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final newTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    try {
      await widget.onSave(newTime, _noteController.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.radiusLg),
      ),
      backgroundColor: context.palette.card,
      child: Padding(
        padding: r.padAll(1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '编辑起飞记录',
              style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: r.gapMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                            );
                            if (date != null) setState(() => _date = date);
                          },
                    icon: Icon(Icons.calendar_today, size: r.iconSm),
                    label: Text(DateFormatters.dateOnly(_date)),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _time,
                            );
                            if (time != null) setState(() => _time = time);
                          },
                    icon: Icon(Icons.access_time, size: r.iconSm),
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
              maxLines: 2,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: '本次起飞的感受（可选）',
                hintText: '例如：终于等到这一天',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: r.gapSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
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
    );
  }
}
