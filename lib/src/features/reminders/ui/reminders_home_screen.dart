import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../services/notifications_service.dart';
import '../data/photos_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';
import 'widgets/reminder_card.dart';

class RemindersHomeScreen extends StatefulWidget {
  final RemindersRepo repo;
  final PhotosStore photosStore;

  const RemindersHomeScreen({
    super.key,
    required this.repo,
    required this.photosStore,
  });

  @override
  State<RemindersHomeScreen> createState() => _RemindersHomeScreenState();
}

class _RemindersHomeScreenState extends State<RemindersHomeScreen> {
  final _picker = ImagePicker();

  List<PhotoReminder> _items = [];

  String? _tempCameraPath;
  final _noteCtrl = TextEditingController();

  DateTime _remindAt = DateTime.now().add(const Duration(hours: 1));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _items = widget.repo.all());

  Future<void> _pickRemindAt() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
      initialDate: _remindAt,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_remindAt),
    );
    if (time == null) return;

    setState(() {
      _remindAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _takePhoto() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final shot = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (shot == null) return;
    setState(() => _tempCameraPath = shot.path);
  }

  Future<void> _retakePhoto() async => _takePhoto();

  Future<void> _clearTempPhoto() async {
    setState(() => _tempCameraPath = null);
  }

  Future<void> _saveQuick() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_tempCameraPath == null) {
      await _takePhoto();
      if (_tempCameraPath == null) return;
    }

    setState(() => _saving = true);
    try {
      final assetId = await widget.photosStore.saveToPhotos(_tempCameraPath!);

      final now = DateTime.now();
      final r = PhotoReminder(
        id: const Uuid().v4(),
        assetId: assetId,
        legacyImagePath: null,
        dateTaken: now,
        remindAt: _remindAt,
        note: _noteCtrl.text.trim(),
        createdAt: now,
      );

      await widget.repo.add(r);

      await NotificationsService.instance.scheduleReminder(
        reminderId: r.id,
        remindAt: r.remindAt,
        title: 'Photo reminder',
        body: r.note.isNotEmpty ? r.note : 'Tap to view your photo',
      );

      setState(() {
        _tempCameraPath = null;
        _noteCtrl.clear();
        _remindAt = DateTime.now().add(const Duration(hours: 1));
      });

      _reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved reminder')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// ✅ Deletes reminder + notification + photo source (best effort).
  Future<void> _deleteReminder(PhotoReminder r) async {
    // 1) delete reminder record first
    await widget.repo.removeById(r.id);

    // 2) cancel scheduled notification
    await NotificationsService.instance.cancelReminder(r.id);

    // 3) delete from Photos (assetId)
    if (r.assetId.isNotEmpty) {
      try {
        await widget.photosStore.deleteFromPhotos(r.assetId);
      } catch (_) {}
    }

    // 4) delete legacy file if it exists
    final legacy = r.legacyImagePath;
    if (legacy != null && legacy.isNotEmpty) {
      try {
        final f = File(legacy);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }

    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(onPressed: () => context.push('/add'), icon: const Icon(Icons.add)),
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          _QuickAddCard(
            tempPath: _tempCameraPath,
            noteController: _noteCtrl,
            remindAt: _remindAt,
            saving: _saving,
            onTakePhoto: _takePhoto,
            onRetakePhoto: _retakePhoto,
            onClearPhoto: _clearTempPhoto,
            onPickTime: _pickRemindAt,
            onSave: _saveQuick,
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 28),
              child: Center(child: Text('No reminders yet')),
            )
          else
            ..._items.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReminderCard(
                    reminder: r,
                    photosStore: widget.photosStore,
                    onTap: () async {
                      await context.push('/detail/${r.id}');
                      _reload();
                    },
                    onLongPress: () async {
                      await context.push('/edit/${r.id}');
                      _reload();
                    },
                    onDelete: () => _deleteReminder(r),
                  ),
                )),
        ],
      ),
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  final String? tempPath;
  final TextEditingController noteController;
  final DateTime remindAt;
  final bool saving;

  final VoidCallback onTakePhoto;
  final VoidCallback onRetakePhoto;
  final VoidCallback onClearPhoto;
  final VoidCallback onPickTime;
  final VoidCallback onSave;

  const _QuickAddCard({
    required this.tempPath,
    required this.noteController,
    required this.remindAt,
    required this.saving,
    required this.onTakePhoto,
    required this.onRetakePhoto,
    required this.onClearPhoto,
    required this.onPickTime,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = tempPath != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick add', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            if (hasPhoto) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.file(File(tempPath!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: saving ? null : (hasPhoto ? onRetakePhoto : onTakePhoto),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(hasPhoto ? 'Retake' : 'Photo'),
                ),
                if (hasPhoto)
                  OutlinedButton.icon(
                    onPressed: saving ? null : onClearPhoto,
                    icon: const Icon(Icons.close),
                    label: const Text('Remove'),
                  ),
                OutlinedButton.icon(
                  onPressed: saving ? null : onPickTime,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Time'),
                ),
              ],
            ),

            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 2,
            ),

            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Remind at'),
                subtitle: Text(_fmt(remindAt)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: saving ? null : onPickTime,
              ),
            ),

            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }
}
