import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStore {
  static const _folderName = 'reminder_images';

  Future<String> saveImage(String sourcePath) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(baseDir.path, _folderName));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath);
    final filename = '${const Uuid().v4()}$ext';
    final destPath = p.join(imagesDir.path, filename);

    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
