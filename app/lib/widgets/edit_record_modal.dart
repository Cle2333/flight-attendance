import 'package:flutter/material.dart';

import '../models/record.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';

/// 编辑单条记录的起飞时间
class EditRecordModal extends StatefulWidget {
  final FlightRecord record;
  final void Function(DateTime newTime) onSave;

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

  @override
  void initState() {
    super.initState();
    _date = DateTime(widget.record.time.year, widget.record.time.month, widget.record.time.day);
    _time = TimeOfDay(hour: widget.record.time.hour, minute: widget.record.time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radiusLg)),
      backgroundColor: context.palette.card,
      child: Padding(
        padding: r.padAll(1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '编辑起飞时间',
              style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: r.gapMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    icon: Icon(Icons.calendar_today, size: r.iconSm),
                    label: Text(DateFormatters.dateOnly(_date)),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (t != null) setState(() => _time = t);
                    },
                    icon: Icon(Icons.access_time, size: r.iconSm),
                    label: Text(
                      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: r.gapLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final newTime = DateTime(
                        _date.year,
                        _date.month,
                        _date.day,
                        _time.hour,
                        _time.minute,
                      );
                      widget.onSave(newTime);
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
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