import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: Get.find<AppState>().baseUrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Get.find<AppState>().updateBaseUrl(_ctrl.text.trim());
      if (mounted) {
        Get.back();
        Get.snackbar('已保存', '下次请求生效',
            snackPosition: SnackPosition.BOTTOM,
            margin: EdgeInsets.all(context.r.gapMd));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      appBar: AppBar(title: const Text('服务器设置')),
      body: CenteredFrame(
        maxWidth: r.contentMaxWidth,
        child: Padding(
          padding: r.padAll(1.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '后端 API 地址',
                style: TextStyle(fontSize: r.textLg, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: r.gapXs),
              Text(
                '默认 https://flight.cmach.qzz.io；本地调试可改局域网 IP',
                style: TextStyle(fontSize: r.textSm, color: context.palette.textSecondary),
              ),
              SizedBox(height: r.gapMd),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'https://flight.cmach.qzz.io',
                ),
              ),
              SizedBox(height: r.gapLg),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        width: r.gapMd * 1.25,
                        height: r.gapMd * 1.25,
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}