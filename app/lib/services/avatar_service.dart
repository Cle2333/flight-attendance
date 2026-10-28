import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AvatarService {
  static const _imageGroup = XTypeGroup(
    label: '图片',
    extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
  );
  static const _maxBytes = 10 * 1024 * 1024;
  static const _allowedExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.bmp'};

  final Future<Directory> Function() _supportDirectoryProvider;

  AvatarService({Future<Directory> Function()? supportDirectoryProvider})
    : _supportDirectoryProvider =
          supportDirectoryProvider ?? getApplicationSupportDirectory;

  Future<String?> pickAndStore({String? previousPath}) async {
    final selected = await openFile(
      acceptedTypeGroups: const [_imageGroup],
      confirmButtonText: '选择头像',
    );
    if (selected == null) return null;
    return storeFromPath(selected.path, previousPath: previousPath);
  }

  Future<String> storeFromPath(
    String sourcePath, {
    String? previousPath,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('头像文件不存在');
    }
    final length = await source.length();
    if (length > _maxBytes) {
      throw const FormatException('头像图片不能超过 10 MB');
    }

    var extension = p.extension(sourcePath).toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      extension = '.png';
    }

    final root = await _supportDirectoryProvider();
    final directory = Directory(p.join(root.path, 'avatars'));
    await directory.create(recursive: true);
    final target = File(
      p.join(
        directory.path,
        'avatar_${DateTime.now().microsecondsSinceEpoch}$extension',
      ),
    );
    await source.copy(target.path);
    if (previousPath != null) {
      final previous = File(previousPath);
      if (p.isWithin(directory.path, previous.path) &&
          await previous.exists()) {
        await previous.delete();
      }
    }
    return target.path;
  }
}
