import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:flight_attendance_app/models/profile.dart';
import 'package:flight_attendance_app/services/avatar_service.dart';

void main() {
  late Directory root;
  late AvatarService service;

  setUp(() async {
    root = Directory(
      p.join(
        Directory.current.path,
        '.dart_tool',
        'avatar_service_test_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await root.create(recursive: true);
    service = AvatarService(supportDirectoryProvider: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('头像保存为相对路径并可从应用目录解析', () async {
    final source = File(p.join(root.path, 'source.png'));
    await source.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );

    final stored = await service.storeFromPath(source.path);
    final resolved = await service.resolvePath(stored);

    expect(stored, startsWith('avatars/'));
    expect(p.isAbsolute(stored), isFalse);
    expect(await File(resolved).readAsBytes(), await source.readAsBytes());

    await service.deleteManagedFile(stored);
    expect(await File(resolved).exists(), isFalse);
  });

  test('源文件不存在时抛 FileSystemException', () async {
    await expectLater(
      service.storeFromPath(p.join(root.path, 'missing.png')),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('超过 10 MB 的图片被拒绝', () async {
    final source = File(p.join(root.path, 'large.png'));
    await source.writeAsBytes(List<int>.filled(10 * 1024 * 1024 + 1, 0));

    await expectLater(
      service.storeFromPath(source.path),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('10 MB'),
        ),
      ),
    );
  });

  test('非法扩展名被拒绝', () async {
    final source = File(p.join(root.path, 'avatar.txt'));
    await source.writeAsString('not an image');

    await expectLater(
      service.storeFromPath(source.path),
      throwsA(isA<FormatException>()),
    );
  });

  test('扩展名为 png 但内容不是图片时被拒绝', () async {
    final source = File(p.join(root.path, 'fake.png'));
    await source.writeAsString('not an image');

    await expectLater(
      service.storeFromPath(source.path),
      throwsA(isA<FormatException>()),
    );
  });

  test('清理头像时不会删除应用头像目录外的文件', () async {
    final outside = File(p.join(root.path, 'outside.png'));
    await outside.writeAsBytes([1, 2, 3]);

    await service.deleteManagedFile(outside.path);

    expect(await outside.exists(), isTrue);
  });

  test('LocalProfile 可以显式清除头像路径', () {
    const profile = LocalProfile(
      nickname: '机长',
      avatarPath: 'avatars/avatar.png',
    );
    expect(profile.copyWith(clearAvatarPath: true).avatarPath, isNull);
  });
}
