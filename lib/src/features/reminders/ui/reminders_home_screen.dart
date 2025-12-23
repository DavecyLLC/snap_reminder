import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../data/image_store.dart';
import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';
import '../notifications/notification_service.dart';
import 'widgets/reminder_card.dart';
import 'widgets/status_chip.dart';

class RemindersHomeScreen extends StatefulWidget {
  const RemindersHomeScreen({
    super.key,
    required this.repo,
    required this.notifications,
  });

  final RemindersRepo repo;
  final NotificationService notifications;

  @override
  State<RemindersHomeScreen> createState() => _RemindersHomeScreenState();
}

class _RemindersHomeScreenState extends State<RemindersHomeScreen> {
  final picker = ImagePicker();
  final store = ImageStore();

  String filter = 'All';
  List<PhotoReminder> _items = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = widget.repo.all();
    });
  }

  List<PhotoReminder> get items {
    final now = DateTime.now();

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    return _items.where((r) {
      switch (filter) {
        case 'Today':
          return sameDay(r.remindAt, now);
        case 'Upcoming':
          return r.remindAt.isAfter(now);
        case 'Overdue':
          return r.remindAt.isBefore(now) && !sameDay(r.remindAt, now);
        default:
          return true;
      }
    }).toList();
  }

  Future<DateTime?> _pickDateTime() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (d == null) return null;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (t == null) return null;

    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _addFrom(ImageSource source) async {
    final x = await picker.pickImage(source: source, imageQuality: 90);
    if (x == null) return;

    final remindAt = await _pickDateTime();
    if (remindAt == null) return;

    final savedPath = await store.saveImage(x.path);
    final now = DateTime.now();

    final reminder = PhotoReminder(
      id: const Uuid().v4(),
      imagePath: savedPath,
      dateTaken: now,
      remindAt: remindAt,
      note: '',
      createdAt: now,
    );

    await widget.repo.add(reminder);

    await widget.notifications.scheduleReminder(
      reminderId: reminder.id,
      remindAt: reminder.remindAt,
      note: reminder.note,
    );

    _reload();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pick from gallery'),
              onTap: () {
                Navigator.pop(context);
                _addFrom(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _addFrom(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Bulk add'),
              onTap: () {
                Navigator.pop(context);
                context.push('/bulk');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label) {
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: filter == label,
        onSelected: (_) => setState(() => filter = label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _filterButton('All'),
                    const SizedBox(width: 10),
                    _filterButton('Today'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _filterButton('Upcoming'),
                    const SizedBox(width: 10),
                    _filterButton('Overdue'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_rounded,
                        size: 56, color: Colors.white.withOpacity(0.6)),
                    const SizedBox(height: 14),
                    const Text(
                      'Picture-first reminders',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openAddSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add reminder'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final r = items[i];
                  return ReminderCard(
                    reminder: r,
                    subtitle: df.format(r.remindAt),
                    chip: StatusChip(status: statusFor(r.remindAt)),
                    onTap: () => context.push('/detail', extra: r),
                  );
                },
              ),
            ),
    );
  }
}
