import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/notifications_service.dart';
import '../data/photos_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';

class EditReminderScreen extends StatefulWidget {
  final RemindersRepo repo;
  final PhotosStore photosStore;
  final String reminderId;

  const EditReminderScreen({
    super.key,
    required this.repo,
    required this.photosStore,
    required this.reminderId,
  });

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final _picker = ImagePicker();

  PhotoReminder? _r;
  final _noteCtrl = TextEditingController();
  DateTime _remindAt = DateTime.now();
  bool _saving = false;

  // If user retakes, we keep a temp camera path until Save.
  String? _tempCameraPath;

  @override
  void initState() {
    super.initState();
    _r = widget.repo.getById(widget.reminderId);

    if (_r != null) {
      _noteCtrl.text = _r!.note;
      _remindAt = _r!.remindAt;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _retakePhoto() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final shot = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (shot == null) return;

    setState(() {
      _tempCameraPath = shot.path; // show immediately
    });
  }

  Future<void> _pickTime() async {
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

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final r = _r;
    if (r == null) return;

    setState(() => _saving = true);
    try {
      // If user retook photo, save it to Photos and replace assetId.
      String newAssetId = r.assetId;
      String? newLegacyPath = r.legacyImagePath;

      if (_tempCameraPath != null && _tempCameraPath!.trim().isNotEmpty) {
        newAssetId = await widget.photosStore.saveToPhotos(_tempCameraPath!);
        newLegacyPath = null; // once we have Photos, we don't need legacy path
      }

      final updated = PhotoReminder(
        id: r.id,
        assetId: newAssetId,
        legacyImagePath: newLegacyPath,
        dateTaken: r.dateTaken,
        remindAt: _remindAt,
        note: _noteCtrl.text.trim(),
        createdAt: r.createdAt,
      );

      await widget.repo.upsert(updated);

      await NotificationsService.instance.scheduleReminder(
        reminderId: updated.id,
        remindAt: updated.remindAt,
        title: 'Photo reminder',
        body: updated.note.isNotEmpty ? updated.note : 'Tap to view your photo',
      );

      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final r = _r;
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit')),
        body: const Center(child: Text('Reminder not found')),
      );
    }

    final hasTemp = _tempCameraPath != null && _tempCameraPath!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit reminder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // ✅ Image preview (temp retake first, otherwise existing)
          _EditImagePreview(
            photosStore: widget.photosStore,
            reminder: r,
            tempCameraPath: _tempCameraPath,
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _saving ? null : _retakePhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Retake photo'),
              ),
              if (hasTemp)
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => setState(() => _tempCameraPath = null),
                  icon: const Icon(Icons.close),
                  label: const Text('Remove'),
                ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickTime,
                icon: const Icon(Icons.schedule),
                label: const Text('Pick time'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Note'),
            maxLines: 3,
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              title: const Text('Remind at'),
              subtitle: Text(_fmt(_remindAt)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _saving ? null : _pickTime,
            ),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Save changes'),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }
}

class _EditImagePreview extends StatelessWidget {
  final PhotosStore photosStore;
  final PhotoReminder reminder;
  final String? tempCameraPath;

  const _EditImagePreview({
    required this.photosStore,
    required this.reminder,
    required this.tempCameraPath,
  });

  @override
  Widget build(BuildContext context) {
    // 1) If user retook photo, show temp immediately
    final tp = tempCameraPath;
    if (tp != null && tp.trim().isNotEmpty) {
      return _PhotoBox(
        child: Image.file(
          File(tp),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }

    // 2) Otherwise show existing saved image from Photos assetId
    if (reminder.assetId.isNotEmpty) {
      return FutureBuilder<File?>(
        future: photosStore.getFileFromAssetId(reminder.assetId),
        builder: (context, snap) {
          final f = snap.data;
          if (f == null) {
            return const _PhotoBox(
              child: Center(child: Icon(Icons.image_not_supported_outlined)),
            );
          }
          return _PhotoBox(child: Image.file(f, fit: BoxFit.cover));
        },
      );
    }

    // 3) Legacy fallback (may not exist after reinstall)
    final legacy = reminder.legacyImagePath;
    if (legacy != null && legacy.isNotEmpty) {
      return _PhotoBox(
        child: Image.file(
          File(legacy),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      );
    }

    return const _PhotoBox(
      child: Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  final Widget child;
  const _PhotoBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ColoredBox(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          child: child,
        ),
      ),
    );
  }
}
