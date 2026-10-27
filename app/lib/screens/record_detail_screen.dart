import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/responsive.dart';
import '../widgets/edit_record_modal.dart';

class RecordDetailScreen extends StatelessWidget {
  final int recordId;
  const RecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context) {
    final state = Get.find<AppState>();
    final r = context.r;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('起飞详情'),
      ),
      body: CenteredFrame(
        maxWidth: r.contentMaxWidth,
        child: Obx(() {
          final r0 = state.records.firstWhere(
            (e) => e.id == recordId,
            orElse: () => state.records.isNotEmpty
                ? state.records.first
                : (throw StateError('记录不存在')),
          );
          final t = r0.time;

          return ListView(
            padding: r.padFromLTRB(1.4, 0, 1.4, 1.4),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.palette.card,
                  borderRadius: BorderRadius.circular(r.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: '起飞时间',
                      value: DateFormatters.timeFull(t),
                    ),
                    Divider(height: 1, color: context.palette.border),
                    _DetailRow(
                      label: '感受',
                      value: r0.note.isEmpty ? '（无）' : r0.note,
                    ),
                    Divider(height: 1, color: context.palette.border),
                    Padding(
                      padding: r.padAll(1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '状态',
                            style: TextStyle(
                              fontSize: r.textBase,
                              color: context.palette.textSecondary,
                            ),
                          ),
                          Container(
                            padding: r.padHV(0.5, 0.2),
                            decoration: BoxDecoration(
                              color: context.palette.successBg,
                              borderRadius: BorderRadius.circular(r.radiusXl),
                            ),
                            child: Text(
                              '已完成',
                              style: TextStyle(
                                fontSize: r.textXs,
                                fontWeight: FontWeight.w600,
                                color: context.palette.successText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: r.gapLg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await Get.dialog(
                          EditRecordModal(
                            record: r0,
                            onSave: (newTime) => state.updateRecord(
                                r0.id, newTime, r0.note),
                          ),
                        );
                      },
                      child: const Text('编辑'),
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final confirm = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('删除起飞记录'),
                            content: const Text('确定删除这条记录？'),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('取消'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.danger),
                                onPressed: () => Get.back(result: true),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await state.deleteRecord(r0.id);
                          if (Get.isOverlaysOpen == false &&
                              Get.currentRoute == '/RecordDetailScreen') {
                            Get.back();
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      child: const Text('删除'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: r.padAll(1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: r.textBase,
              color: context.palette.textSecondary,
            ),
          ),
          SizedBox(width: r.gapMd),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: r.textBase, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}