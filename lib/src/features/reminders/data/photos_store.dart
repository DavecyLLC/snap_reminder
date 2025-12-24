import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

class PhotosStore {
  /// Save an image file to the device Photos / Gallery and return the assetId.
  /// You likely already have this; keep it consistent.
  Future<String> saveToPhotos(String filePath) async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) {
      throw Exception('Photos permission not granted');
    }

    final entity = await PhotoManager.editor.saveImageWithPath(filePath);
    if (entity == null) {
      throw Exception('Failed to save image to Photos');
    }
    return entity.id; // assetId
  }

  /// Convert assetId to a usable File (temp file path provided by the OS).
  Future<File?> getFileFromAssetId(String assetId) async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return null;

    final entity = await AssetEntity.fromId(assetId);
    if (entity == null) return null;

    return entity.file; // temp file returned by platform
  }

  /// ✅ Delete a photo from the Photos/Gallery by its assetId.
  /// Use with care: on iOS a confirmation may appear. On Android 30+ it may move to trash.
  Future<bool> deleteFromPhotos(String assetId) async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) return false;

    final deletedIds = await PhotoManager.editor.deleteWithIds(<String>[assetId]);
    return deletedIds.contains(assetId);
  }
}
