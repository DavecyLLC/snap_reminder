// lib/src/features/reminders/ui/add_reminder_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../services/notifications_service.dart';
import '../../../utils/pickers.dart';
import '../data/photos_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';

class AddReminderScreen extends StatefulWidget {
  final RemindersRepo repo;
  final PhotosStore photosStore;

  const AddReminderScreen({
    super.key,
    required this.repo,
    required this.photosStore,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _noteCtrl = TextEditingController();

  String? _tempCameraPath;
  DateTime _remindAt = DateTime.now().add(const Duration(hours: 1));
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 16));

    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (shot == null || !mounted) return;

    setState(() => _tempCameraPath = shot.path);
  }

  Future<void> _pickTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 16));

    // ✅ EXACT snippet (matches pickers.dart signature)
    final date = await safePickDate(initialDate: _remindAt);
    if (date == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;

    final time = await safeShowTimePicker(
      initialTime: TimeOfDay.fromDateTime(_remindAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _remindAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if ((_tempCameraPath ?? '').trim().isEmpty) {
      await _takePhoto();
      if ((_tempCameraPath ?? '').trim().isEmpty) return;
    }

    setState(() => _saving = true);
    try {
      final finalPath = (_tempCameraPath ?? '').trim();
      if (finalPath.isEmpty) return;

      final assetId = await widget.photosStore.saveToPhotos(finalPath);

      final now = DateTime.now();
      final reminder = PhotoReminder(
        id: const Uuid().v4(),
        assetId: assetId,
        legacyImagePath: null,
        dateTaken: now,
        remindAt: _remindAt,
        note: _noteCtrl.text.trim(),
        createdAt: now,
      );

      await widget.repo.add(reminder);

      await NotificationsService.instance.scheduleReminder(
        reminderId: reminder.id,
        remindAt: reminder.remindAt,
        title: 'Photo reminder',
        body: reminder.note.isNotEmpty ? reminder.note : 'Tap to view your photo',
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _removeTempPhoto() => setState(() => _tempCameraPath = null);

  @override
  Widget build(BuildContext context) {
    final path = (_tempCameraPath ?? '').trim();
    final hasPhoto = path.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Add reminder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _saving ? null : _takePhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(hasPhoto ? 'Retake' : 'Take photo'),
              ),
              if (hasPhoto)
                OutlinedButton.icon(
                  onPressed: _saving ? null : _removeTempPhoto,
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
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save'),
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
