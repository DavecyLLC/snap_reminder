// lib/src/features/reminders/ui/bulk_add_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../services/notifications_service.dart';
import '../../../utils/pickers.dart'; // ✅ PATCH: use safePickDate/safeShowTimePicker
import '../data/image_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';

class BulkAddScreen extends StatefulWidget {
  final RemindersRepo repo;
  final ImageStore imageStore;

  const BulkAddScreen({
    super.key,
    required this.repo,
    required this.imageStore,
  });

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  final _picker = ImagePicker();

  final _noteCtrl = TextEditingController();
  DateTime _remindAt = DateTime.now().add(const Duration(hours: 1));
  bool _saving = false;

  List<XFile> _selected = [];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // ✅ PATCH: root-navigator-safe pickers + micro delays (prevents keyboard-toggle crash)
  Future<void> _pickRemindAt() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 16));

    final now = DateTime.now();

    final date = await safePickDate(
      initialDate: _remindAt,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null) return;

    // let date route fully close
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

  Future<void> _pickMany() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 16));

    final files = await _picker.pickMultiImage(imageQuality: 90);
    if (files.isEmpty || !mounted) return;

    setState(() => _selected = files);
  }

  Future<void> _saveBulk() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selected.isEmpty) {
      await _pickMany();
      if (_selected.isEmpty) return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final note = _noteCtrl.text.trim();

      final reminders = <PhotoReminder>[];
      for (final x in _selected) {
        final stored = await widget.imageStore.saveImage(x.path);
        final r = PhotoReminder(
          id: const Uuid().v4(),
          imagePath: stored,
          dateTaken: now,
          remindAt: _remindAt,
          note: note,
          createdAt: now,
        );
        reminders.add(r);
      }

      await widget.repo.addMany(reminders);

      for (final r in reminders) {
        await NotificationsService.instance.scheduleReminder(
          reminderId: r.id,
          remindAt: r.remindAt,
          title: 'Photo reminder',
          body: r.note.isNotEmpty ? r.note : 'Tap to view your photo',
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk add')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _saving ? null : _pickMany,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_selected.isEmpty ? 'Pick photos' : 'Pick again (${_selected.length})'),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _saveBulk,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Save all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selected.isNotEmpty) ...[
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selected.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(File(_selected[i].path), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (applies to all)'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Remind at'),
              subtitle: Text(_fmt(_remindAt)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _saving ? null : _pickRemindAt,
            ),
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
