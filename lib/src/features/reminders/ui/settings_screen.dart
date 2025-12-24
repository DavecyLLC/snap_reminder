// lib/src/features/reminders/ui/settings_screen.dart
import 'package:flutter/material.dart';
import '../data/reminders_repo.dart';

class SettingsScreen extends StatelessWidget {
  final RemindersRepo repo;

  const SettingsScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Clear all reminders'),
              subtitle: Text('Current count: ${repo.count()}'),
              trailing: const Icon(Icons.delete_forever_outlined),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear everything?'),
                    content: const Text('This removes all reminders (images are not deleted here).'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                    ],
                  ),
                );
                if (ok == true) {
                  await repo.clearAll();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Note: Clearing reminders does not delete stored image files in this screen.\n'
            'Deletes from Home/Detail do delete the image file.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

