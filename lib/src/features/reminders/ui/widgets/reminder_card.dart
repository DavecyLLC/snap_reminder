import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/photos_store.dart';
import '../../models/photo_reminder.dart';

class ReminderCard extends StatelessWidget {
  final PhotoReminder reminder;
  final PhotosStore photosStore;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.photosStore,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: _Thumb(reminder: reminder, photosStore: photosStore),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.note.isNotEmpty ? reminder.note : 'Photo reminder',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(_fmt(reminder.remindAt), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _Thumb extends StatelessWidget {
  final PhotoReminder reminder;
  final PhotosStore photosStore;

  const _Thumb({required this.reminder, required this.photosStore});

  @override
  Widget build(BuildContext context) {
    // ✅ New reminders: load from Photos assetId
    if (reminder.assetId.isNotEmpty) {
      return FutureBuilder<File?>(
        future: photosStore.getFileFromAssetId(reminder.assetId),
        builder: (context, snap) {
          final f = snap.data;
          if (f == null) {
            return const ColoredBox(
              color: Colors.black12,
              child: Center(child: Icon(Icons.image_not_supported_outlined)),
            );
          }
          return Image.file(f, fit: BoxFit.cover);
        },
      );
    }

    // Legacy reminders: try to load old file path (may not exist after reinstall)
    final legacy = reminder.legacyImagePath;
    if (legacy != null && legacy.isNotEmpty) {
      final file = File(legacy);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Colors.black12,
          child: Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      );
    }

    return const ColoredBox(
      color: Colors.black12,
      child: Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}
