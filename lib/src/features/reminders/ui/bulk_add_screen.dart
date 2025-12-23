import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../data/image_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';
import '../notifications/notification_service.dart';

class BulkAddScreen extends StatefulWidget {
  const BulkAddScreen({
    super.key,
    required this.repo,
    required this.notifications,
  });

  final RemindersRepo repo;
  final NotificationService notifications;

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  final picker = ImagePicker();
  final store = ImageStore();

  List<XFile> selected = [];
  int activeIndex = 0;

  DateTime remindAt = DateTime.now().add(const Duration(hours: 3));
  final TextEditingController noteTemplate = TextEditingController();

  Future<void> _pickMultiple() async {
    final files = await picker.pickMultiImage(imageQuality: 90);
    if (files.isEmpty) return;
    setState(() {
      selected = files;
      activeIndex = 0;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: remindAt,
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(remindAt),
    );
    if (t == null) return;

    setState(() => remindAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _applyQuick(Duration delta) {
    setState(() => remindAt = DateTime.now().add(delta));
  }

  Future<void> _saveAll() async {
    if (selected.isEmpty) return;

    final now = DateTime.now();
    final note = noteTemplate.text.trim();

    final List<PhotoReminder> list = [];

    for (final x in selected) {
      final savedPath = await store.saveImage(x.path);
      final r = PhotoReminder(
        id: const Uuid().v4(),
        imagePath: savedPath,
        dateTaken: now,
        remindAt: remindAt,
        note: note,
        createdAt: now,
      );
      list.add(r);
    }

    await widget.repo.addMany(list);

    for (final r in list) {
      await widget.notifications.scheduleReminder(
        reminderId: r.id,
        remindAt: r.remindAt,
        note: r.note,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Add', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton.icon(
            onPressed: _pickMultiple,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Pick'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            if (selected.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.playlist_add_rounded, size: 54, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(height: 12),
                      const Text('Select multiple photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _pickMultiple,
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('Pick Photos'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selected.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final isActive = i == activeIndex;
                    return GestureDetector(
                      onTap: () => setState(() => activeIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 78,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            width: 2,
                            color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(selected[i].path), fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    File(selected[activeIndex].path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Remind at', style: TextStyle(fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text(df.format(remindAt), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDateTime,
                              icon: const Icon(Icons.calendar_month_rounded),
                              label: const Text('Pick date/time'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(label: const Text('Tonight'), onPressed: () => _applyQuick(const Duration(hours: 6))),
                          ActionChip(label: const Text('Tomorrow AM'), onPressed: () => _applyQuick(const Duration(hours: 14))),
                          ActionChip(label: const Text('+1 day'), onPressed: () => _applyQuick(const Duration(days: 1))),
                          ActionChip(label: const Text('+1 week'), onPressed: () => _applyQuick(const Duration(days: 7))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteTemplate,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'Note template (optional)…'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _saveAll,
                              icon: const Icon(Icons.save_rounded),
                              label: Text('Save All (${selected.length})'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
