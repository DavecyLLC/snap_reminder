import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/notifications_service.dart';
import '../data/photos_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';
import 'photo_viewer_screen.dart';

class ReminderDetailScreen extends StatelessWidget {
  const ReminderDetailScreen({
    super.key,
    required this.repo,
    required this.photosStore,
    required this.reminderId,
  });

  final RemindersRepo repo;
  final PhotosStore photosStore;
  final String reminderId;

  @override
  Widget build(BuildContext context) {
    final PhotoReminder? r = repo.getById(reminderId);

    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminder')),
        body: const Center(child: Text('Reminder not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _shareReminder(context, r),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TapToEnlargePhoto(reminder: r, photosStore: photosStore),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.note.isNotEmpty ? r.note : 'Photo reminder',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text('Remind at: ${_fmt(r.remindAt)}'),
                  const SizedBox(height: 6),
                  Text('Created: ${_fmt(r.createdAt)}'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _deleteReminder(context, r),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReminder(BuildContext context, PhotoReminder r) async {
    final file = await _resolveFile(r);

    final dt = DateFormat('EEE, MMM d • h:mm a').format(r.remindAt);
    final text = [
      'Picture Reminder',
      'Remind at: $dt',
      if (r.note.trim().isNotEmpty) 'Note: ${r.note.trim()}',
    ].join('\n');

    if (file == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo file not available to share.')),
        );
      }
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? (box.localToGlobal(Offset.zero) & box.size)
        : const Rect.fromLTWH(0, 0, 1, 1);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
      sharePositionOrigin: origin,
    );

  }
  

  Future<void> _deleteReminder(BuildContext context, PhotoReminder r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: const Text('This will remove the reminder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await repo.removeById(r.id);
    await NotificationsService.instance.cancelReminder(r.id);

    if (context.mounted) Navigator.pop(context);
  }

  Future<File?> _resolveFile(PhotoReminder reminder) async {
    if (reminder.assetId.isNotEmpty) {
      return photosStore.getFileFromAssetId(reminder.assetId);
    }

    final legacy = reminder.legacyImagePath;
    if (legacy != null && legacy.isNotEmpty) {
      final f = File(legacy);
      if (await f.exists()) return f;
    }

    return null;
  }

  static String _fmt(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _TapToEnlargePhoto extends StatelessWidget {
  const _TapToEnlargePhoto({
    required this.reminder,
    required this.photosStore,
  });

  final PhotoReminder reminder;
  final PhotosStore photosStore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _resolveFile(),
      builder: (context, snap) {
        final file = snap.data;

        return GestureDetector(
          onTap: file == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoViewerScreen(imageFile: file),
                    ),
                  );
                },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: file == null
                      ? const ColoredBox(
                          color: Colors.black12,
                          child: Center(
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                        )
                      : Image.file(file, fit: BoxFit.cover),
                ),
              ),
              if (file != null)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_out_map,
                            size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Tap to enlarge',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _resolveFile() async {
    if (reminder.assetId.isNotEmpty) {
      return photosStore.getFileFromAssetId(reminder.assetId);
    }

    final legacy = reminder.legacyImagePath;
    if (legacy != null && legacy.isNotEmpty) {
      final f = File(legacy);
      if (await f.exists()) return f;
    }

    return null;
  }
}
