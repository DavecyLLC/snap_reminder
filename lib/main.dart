import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app/app_theme.dart';
import 'src/features/reminders/data/reminders_repo.dart';
import 'src/features/reminders/models/photo_reminder.dart';
import 'src/features/reminders/notifications/notification_service.dart';
import 'src/features/reminders/ui/bulk_add_screen.dart';
import 'src/features/reminders/ui/reminder_detail_screen.dart';
import 'src/features/reminders/ui/reminders_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final repo = RemindersRepo();
  await repo.init();

  final notifications = NotificationService();

  runApp(PicReminderApp(repo: repo, notifications: notifications));
}

class PicReminderApp extends StatefulWidget {
  const PicReminderApp({
    super.key,
    required this.repo,
    required this.notifications,
  });

  final RemindersRepo repo;
  final NotificationService notifications;

  @override
  State<PicReminderApp> createState() => _PicReminderAppState();
}

class _PicReminderAppState extends State<PicReminderApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => RemindersHomeScreen(
          repo: widget.repo,
          notifications: widget.notifications,
        ),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final reminder = state.extra as PhotoReminder;
              return ReminderDetailScreen(
                reminder: reminder,
                repo: widget.repo,
                notifications: widget.notifications,
              );
            },
          ),
          GoRoute(
            path: 'bulk',
            builder: (context, state) => BulkAddScreen(
              repo: widget.repo,
              notifications: widget.notifications,
            ),
          ),
        ],
      ),

      // Notification tap route (opens by id)
      GoRoute(
        path: '/open/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final r = widget.repo.getById(id);
          if (r == null) {
            return const Scaffold(
              body: Center(child: Text('Reminder not found')),
            );
          }
          return ReminderDetailScreen(
            reminder: r,
            repo: widget.repo,
            notifications: widget.notifications,
          );
        },
      ),
    ],
  );

  @override
  void initState() {
    super.initState();

    widget.notifications.init(
      onTapReminder: (id) {
        _router.go('/open/$id');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pic Reminder',
      theme: AppTheme.dark(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
