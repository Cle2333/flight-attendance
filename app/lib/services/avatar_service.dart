import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AvatarService {
  static const _imageGroup = XTypeGroup(
    label: '图片',
    extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
    mimeTypes: ['image/png', 'image/jpeg', 'image/webp', 'image/bmp'],
  );
  static const _maxBytes = 10 * 1024 * 1024;
  static const _allowedExtensions = {'.png', '.jpg', '.jpeg', '.webp', '.bmp'};

  final Future<Directory> Function() _supportDirectoryProvider;

  AvatarService({Future<Directory> Function()? supportDirectoryProvider})
    : _supportDirectoryProvider =
          supportDirectoryProvider ?? getApplicationSupportDirectory;

  Future<String?> pickAndStore() async {
    final selected = await openFile(
      acceptedTypeGroups: const [_imageGroup],
      confirmButtonText: '选择头像',
    );
    if (selected == null) return null;
    return storeFromPath(selected.path);
  }

  Future<String> storeFromPath(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('头像文件不存在');
    }
    final length = await source.length();
    if (length > _maxBytes) {
      throw const FormatException('头像图片不能超过 10 MB');
    }

    final extension = p.extension(sourcePath).toLowerCase();
    if (!_allowedExtensions.contains(extension)) {
      throw const FormatException('请选择 PNG、JPG、WEBP 或 BMP 格式的图片');
    }
    final header = await source
        .openRead(0, 16)
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    if (!_hasValidImageHeader(header)) {
      throw const FormatException('所选文件不是有效的图片');
    }

    final directory = await _avatarsDirectory();
    await directory.create(recursive: true);
    final fileName =
        'avatar_${DateTime.now().microsecondsSinceEpoch}$extension';
    final target = File(p.join(directory.path, fileName));
    await source.copy(target.path);
    return 'avatars/$fileName';
  }

  Future<String> resolvePath(String storedPath) async {
    if (p.isAbsolute(storedPath)) return storedPath;
    final root = await _supportDirectoryProvider();
    return p.join(root.path, storedPath);
  }

  Future<void> deleteManagedFile(String? storedPath) async {
    if (storedPath == null || storedPath.isEmpty) return;
    try {
      final directory = await _avatarsDirectory();
      final resolved = await resolvePath(storedPath);
      if (!p.isWithin(directory.path, resolved)) return;
      final file = File(resolved);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 清理旧头像失败不影响已经完成的头像替换。
    }
  }

  bool _hasValidImageHeader(List<int> bytes) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[i] != signature[i]) return false;
      }
      return true;
    }

    final png = startsWith(const [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    final jpeg = startsWith(const [0xFF, 0xD8, 0xFF]);
    final bmp = startsWith(const [0x42, 0x4D]);
    final webp =
        bytes.length >= 12 &&
        startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    return png || jpeg || bmp || webp;
  }

  Future<Directory> _avatarsDirectory() async {
    final root = await _supportDirectoryProvider();
    return Directory(p.join(root.path, 'avatars'));
  }
}
