import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../services/notifications_service.dart';
import '../data/photos_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';

class AddReminderScreen extends StatefulWidget {
  final RemindersRepo repo;
  final PhotosStore photosStore;

  const AddReminderScreen({super.key, required this.repo, required this.photosStore});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _picker = ImagePicker();
  final _noteCtrl = TextEditingController();

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
    final shot = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (shot == null) return;
    setState(() => _tempCameraPath = shot.path);
  }

  Future<void> _retakePhoto() async => _takePhoto();

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

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _tempCameraPath != null;

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
                child: Image.file(File(_tempCameraPath!), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
          ],

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _saving ? null : (hasPhoto ? _retakePhoto : _takePhoto),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(hasPhoto ? 'Retake' : 'Take photo'),
              ),
              if (hasPhoto)
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
