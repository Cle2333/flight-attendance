import 'dart:io';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Windows/Linux 使用 FFI；Android/iOS/macOS 使用官方 sqflite 平台实现。
Future<void> initializeDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
  }
}
