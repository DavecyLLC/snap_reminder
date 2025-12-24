import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_theme.dart';
import 'src/services/notifications_service.dart';

import 'src/features/reminders/data/photos_store.dart';
import 'src/features/reminders/data/reminders_repo.dart';
import 'src/features/reminders/ui/reminders_home_screen.dart';
import 'src/features/reminders/ui/add_reminder_screen.dart';
import 'src/features/reminders/ui/edit_reminder_screen.dart';
import 'src/features/reminders/ui/reminder_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final repo = RemindersRepo();
  await repo.init();

  final photosStore = PhotosStore();

  // Requests notification permissions + timezone init
  await NotificationsService.instance.init();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => RemindersHomeScreen(repo: repo, photosStore: photosStore),
      ),
      GoRoute(
        path: '/add',
        builder: (_, __) => AddReminderScreen(repo: repo, photosStore: photosStore),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (_, state) => ReminderDetailScreen(
          repo: repo,
          photosStore: photosStore,
          reminderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/edit/:id',
        builder: (_, state) => EditReminderScreen(
          repo: repo,
          photosStore: photosStore,
          reminderId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  runApp(MyApp(router: router));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pic Reminder',
      theme: AppTheme.darkPurple(),
      routerConfig: router,
      builder: (context, child) {
        // Tap anywhere to dismiss keyboard
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child!,
        );
      },
    );
  }
}
