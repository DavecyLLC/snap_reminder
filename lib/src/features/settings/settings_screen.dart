import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../reminders/data/reminders_repo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.repo});

  final RemindersRepo repo;

  static const String _privacyPolicyUrl =
      'https://davecyllc.github.io/pic-reminder-privacy/';

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final uri = Uri.parse(_privacyPolicyUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Privacy Policy')),
      );
    }
  }

  Future<void> _confirmAndClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all reminders?'),
        content: const Text(
          'This removes all reminders from the app.\n\n'
          'Note: image files are not deleted here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await repo.clearAll();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All reminders cleared.')),
    );
  }

  Future<PackageInfo> _pkg() => PackageInfo.fromPlatform();

  Future<bool?> _notificationsEnabled() async {
    final plugin = FlutterLocalNotificationsPlugin();

    // Android supports a direct check
    final android = await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    if (android != null) return android;

    // iOS: checkPermissions() exists, but fields differ by version.
    // In 19.5.0, it exposes isEnabled.
    final ios = await plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();
    if (ios != null) {
      return ios.isEnabled ?? false;
    }

    // Web/Windows/other: unknown -> don't show a scary OFF state
    return null;
  }

  Future<void> _openAppSettings(BuildContext context) async {
    // Works on iOS and Android (opens this app’s settings page).
    final uri = Uri.parse('app-settings:');
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open system settings')),
      );
    }
  }

  Widget _statusPill({
    required String text,
    required bool ok,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: ok
            ? Colors.green.withOpacity(0.18)
            : Colors.orange.withOpacity(0.18),
        border: Border.all(
          color: ok
              ? Colors.green.withOpacity(0.35)
              : Colors.orange.withOpacity(0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: ok ? Colors.greenAccent : Colors.orangeAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = repo.count();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications indicator
          FutureBuilder<bool?>(
            future: _notificationsEnabled(),
            builder: (context, snap) {
              final enabled = snap.data;

              if (enabled == null) {
                return const SizedBox.shrink();
              }

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Notifications'),
                  subtitle: Text(
                    enabled
                        ? 'Enabled'
                        : 'Disabled — turn on notifications to get reminders',
                  ),
                  trailing: enabled
                      ? _statusPill(text: 'ON', ok: true)
                      : TextButton(
                          onPressed: () => _openAppSettings(context),
                          child: const Text('Open Settings'),
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Privacy Policy
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openPrivacyPolicy(context),
            ),
          ),

          const SizedBox(height: 12),

          // Clear All
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: const Text('Clear all reminders'),
              subtitle: Text('Current count: $count'),
              onTap: () => _confirmAndClearAll(context),
            ),
          ),

          const SizedBox(height: 12),

          // About
          FutureBuilder<PackageInfo>(
            future: _pkg(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final info = snap.data!;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(info.appName),
                  subtitle: Text(
                    'Version ${info.version} (${info.buildNumber})\n'
                    'Made by Davecy LLC',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
