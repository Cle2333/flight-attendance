import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:flight_attendance_app/services/avatar_service.dart';

void main() {
  test('头像图片复制到应用目录并替换旧文件', () async {
    final root = Directory(
      p.join(
        Directory.current.path,
        '.dart_tool',
        'avatar_service_test_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    final source = File(p.join(root.path, 'source.png'));
    await source.parent.create(recursive: true);
    await source.writeAsBytes([1, 2, 3, 4, 5]);

    final service = AvatarService(supportDirectoryProvider: () async => root);
    final first = await service.storeFromPath(source.path);
    expect(await File(first).readAsBytes(), [1, 2, 3, 4, 5]);
    expect(p.isWithin(p.join(root.path, 'avatars'), first), isTrue);

    final second = await service.storeFromPath(
      source.path,
      previousPath: first,
    );
    expect(second, isNot(first));
    expect(await File(second).exists(), isTrue);
    expect(await File(first).exists(), isFalse);
  });
}
