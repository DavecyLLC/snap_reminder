// lib/src/utils/pickers.dart
import 'package:flutter/material.dart';
import '../../app_nav.dart';

Future<DateTime?> safePickDate({
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final ctx = rootNavKey.currentContext;
  if (ctx == null) return null;

  final now = DateTime.now();
  return showDatePicker(
    context: ctx,
    initialDate: initialDate,
    firstDate: firstDate ?? now.subtract(const Duration(days: 365)),
    lastDate: lastDate ?? now.add(const Duration(days: 3650)),
    useRootNavigator: true,
  );
}

Future<TimeOfDay?> safeShowTimePicker({
  required TimeOfDay initialTime,
}) async {
  final ctx = rootNavKey.currentContext;
  if (ctx == null) return null;

  return showTimePicker(
    context: ctx,
    initialTime: initialTime,

    // ✅ brings back the keyboard icon (dial <-> input toggle)
    initialEntryMode: TimePickerEntryMode.dial,

    useRootNavigator: true,
    builder: (context, child) {
      if (child == null) return const SizedBox.shrink();

      final mq = MediaQuery.of(context);

      // ✅ keep safe MediaQuery (no removeViewInsets)
      return MediaQuery(
        data: mq.copyWith(
          textScaler: TextScaler.noScaling,
        ),
        child: child,
      );
    },
  );
}
