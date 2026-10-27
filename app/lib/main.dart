import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/database_factory.dart';
import 'data/legacy_migration.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await initializeDatabaseFactory();
    final database = await AppDatabase.open();
    await LegacyMigration.run(database);
    final state = AppState(database: database);
    runApp(FlightAttendanceApp(appState: state));
    unawaited(state.bootstrap());
  } catch (error) {
    runApp(_StartupFailureApp(message: '本地数据初始化失败：$error'));
  }
}

class _StartupFailureApp extends StatelessWidget {
  final String message;

  const _StartupFailureApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✈️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    '航班打卡无法启动',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
