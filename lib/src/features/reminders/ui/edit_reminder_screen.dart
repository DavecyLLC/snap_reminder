import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/notifications_service.dart';
import '../../../utils/pickers.dart';
import '../data/photos_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';

class EditReminderScreen extends StatefulWidget {
  const EditReminderScreen({
    super.key,
    required this.repo,
    required this.photosStore,
    this.reminderId,
    this.initialImagePath,
  });

  final RemindersRepo repo;
  final PhotosStore photosStore;

  /// If set -> editing an existing reminder
  final String? reminderId;

  /// If set -> creating a new reminder with this local file path
  final String? initialImagePath;

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _noteCtrl = TextEditingController();

  PhotoReminder? _reminder;
  DateTime _remindAt = DateTime.now();
  bool _saving = false;

  /// Temp camera file path shown immediately until user saves.
  String? _tempCameraPath;

  /// Local file path picked from gallery (create-mode).
  String? _pickedLocalPath;

  bool get _isEditMode => (widget.reminderId ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();

    final p = widget.initialImagePath;
    if (!_isEditMode && p != null && p.trim().isNotEmpty) {
      _pickedLocalPath = p.trim();
    }
  }

  void _load() {
    if (!_isEditMode) {
      _reminder = null;
      _noteCtrl.text = '';
      _remindAt = DateTime.now();
      return;
    }

    _reminder = widget.repo.getById(widget.reminderId!);
    final r = _reminder;
    if (r != null) {
      _noteCtrl.text = r.note;
      _remindAt = r.remindAt;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _retakePhoto() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (shot == null) return;

    setState(() => _tempCameraPath = shot.path);
  }

  void _removeTempPhoto() => setState(() => _tempCameraPath = null);

  Future<void> _pickTime() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 16));

    final date = await safePickDate(
      initialDate: _remindAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;

    final time = await safeShowTimePicker(
      initialTime: TimeOfDay.fromDateTime(_remindAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _remindAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // Must have an image
    final hasTemp = (_tempCameraPath ?? '').trim().isNotEmpty;
    final hasPicked = (_pickedLocalPath ?? '').trim().isNotEmpty;
    final existingHasImage = (_reminder?.assetId.isNotEmpty ?? false) ||
        ((_reminder?.legacyImagePath ?? '').trim().isNotEmpty);

    if (!hasTemp && !hasPicked && !existingHasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // If user retook photo, save it to Photos and use assetId.
      final temp = _tempCameraPath;
      String assetId = _reminder?.assetId ?? '';
      String? legacyPath = _reminder?.legacyImagePath;

      if (temp != null && temp.trim().isNotEmpty) {
        assetId = await widget.photosStore.saveToPhotos(temp);
        legacyPath = null;
      } else if (!_isEditMode) {
        // Create-mode: use the picked local path as legacy image path (no Photos save)
        final p = (_pickedLocalPath ?? '').trim();
        if (p.isNotEmpty) {
          assetId = '';
          legacyPath = p;
        }
      }

      final now = DateTime.now();

      final PhotoReminder toSave;
      if (_isEditMode) {
        final r = _reminder;
        if (r == null) {
          throw Exception('Reminder not found');
        }

        toSave = PhotoReminder(
          id: r.id,
          assetId: assetId,
          legacyImagePath: legacyPath,
          dateTaken: r.dateTaken,
          remindAt: _remindAt,
          note: _noteCtrl.text.trim(),
          createdAt: r.createdAt,
        );
      } else {
        toSave = PhotoReminder(
          id: _newId(),
          assetId: assetId,
          legacyImagePath: legacyPath,
          dateTaken: now,
          remindAt: _remindAt,
          note: _noteCtrl.text.trim(),
          createdAt: now,
        );
      }

      await widget.repo.upsert(toSave);

      await NotificationsService.instance.scheduleReminder(
        reminderId: toSave.id,
        remindAt: toSave.remindAt,
        title: 'Photo reminder',
        body: toSave.note.isNotEmpty ? toSave.note : 'Tap to view your photo',
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

  @override
  Widget build(BuildContext context) {
    final hasTemp = (_tempCameraPath ?? '').trim().isNotEmpty;
    final title = _isEditMode ? 'Edit reminder' : 'New reminder';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _EditImagePreview(
            photosStore: widget.photosStore,
            reminder: _reminder,
            tempCameraPath: _tempCameraPath,
            pickedLocalPath: _pickedLocalPath,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _saving ? null : _retakePhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
              if (hasTemp)
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
            label: Text(_isEditMode ? 'Save changes' : 'Save reminder'),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}  ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class _EditImagePreview extends StatelessWidget {
  const _EditImagePreview({
    required this.photosStore,
    required this.reminder,
    required this.tempCameraPath,
    required this.pickedLocalPath,
  });

  final PhotosStore photosStore;
  final PhotoReminder? reminder;
  final String? tempCameraPath;
  final String? pickedLocalPath;

  @override
  Widget build(BuildContext context) {
    final temp = tempCameraPath;
    if (temp != null && temp.trim().isNotEmpty) {
      return _PhotoBox(
        child: Image.file(
          File(temp),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }

    final picked = pickedLocalPath;
    if (picked != null && picked.trim().isNotEmpty) {
      return _PhotoBox(
        child: Image.file(
          File(picked),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }

    final r = reminder;
    if (r == null) {
      return const _PhotoBox(
        child: Center(child: Icon(Icons.image_not_supported_outlined)),
      );
    }

    if (r.assetId.isNotEmpty) {
      return FutureBuilder<File?>(
        future: photosStore.getFileFromAssetId(r.assetId),
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

    final legacy = r.legacyImagePath;
    if (legacy != null && legacy.isNotEmpty) {
      return _PhotoBox(
        child: Image.file(
          File(legacy),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Center(child: Icon(Icons.image_not_supported_outlined)),
        ),
      );
    }

    return const _PhotoBox(
      child: Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ColoredBox(
          color: Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface,
          child: child,
        ),
      ),
    );
  }
}
