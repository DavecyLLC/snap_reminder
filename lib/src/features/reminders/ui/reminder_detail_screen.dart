import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/reminders_repo.dart';
import '../models/photo_reminder.dart';
import '../notifications/notification_service.dart';
import 'widgets/status_chip.dart';

class ReminderDetailScreen extends StatelessWidget {
  const ReminderDetailScreen({
    super.key,
    required this.reminder,
    required this.repo,
    required this.notifications,
  });

  final PhotoReminder reminder;
  final RemindersRepo repo;
  final NotificationService notifications;

  @override
  Widget build(BuildContext context) {
    final dfFull = DateFormat('EEEE, MMMM d • h:mm a');
    final status = statusFor(reminder.remindAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              await repo.removeById(reminder.id);
              await notifications.cancelReminder(reminder.id);
              if (context.mounted) context.pop();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Hero(
              tag: reminder.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(
                    File(reminder.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(status: status),
                        const Spacer(),
                        Text(
                          dfFull.format(reminder.remindAt),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _RowLabel(
                      label: 'Date taken',
                      value: DateFormat('MMM d, yyyy • h:mm a').format(reminder.dateTaken),
                    ),
                    const SizedBox(height: 8),
                    _RowLabel(
                      label: 'Note',
                      value: reminder.note.isEmpty ? '—' : reminder.note,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await repo.removeById(reminder.id);
                              await notifications.cancelReminder(reminder.id);
                              if (context.mounted) context.pop();
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded),
                            label: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
