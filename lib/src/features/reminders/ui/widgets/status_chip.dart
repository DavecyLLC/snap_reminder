import 'package:flutter/material.dart';

enum ReminderStatus { upcoming, today, overdue }

ReminderStatus statusFor(DateTime remindAt) {
  final now = DateTime.now();

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  if (sameDay(remindAt, now)) return ReminderStatus.today;
  if (remindAt.isBefore(now)) return ReminderStatus.overdue;
  return ReminderStatus.upcoming;
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final ReminderStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String text;
    Color bg;

    switch (status) {
      case ReminderStatus.today:
        text = 'Today';
        bg = cs.primary.withOpacity(0.22);
        break;
      case ReminderStatus.overdue:
        text = 'Overdue';
        bg = Colors.red.withOpacity(0.22);
        break;
      case ReminderStatus.upcoming:
        text = 'Upcoming';
        bg = Colors.green.withOpacity(0.20);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
