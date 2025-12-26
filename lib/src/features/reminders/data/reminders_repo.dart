import 'package:hive_flutter/hive_flutter.dart';
import '../models/photo_reminder.dart';

class RemindersRepo {
  static const String boxName = 'remindersBox';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  List<PhotoReminder> all() {
    final list = _box.values
        .whereType<Map>()
        .map((e) => PhotoReminder.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int count() => _box.length;

  PhotoReminder? getById(String id) {
    final value = _box.get(id);
    if (value is Map) {
      return PhotoReminder.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  Future<void> add(PhotoReminder reminder) async {
    await _box.put(reminder.id, reminder.toMap());
  }

  Future<void> addMany(List<PhotoReminder> reminders) async {
    for (final r in reminders) {
      await _box.put(r.id, r.toMap());
    }
  }
  
  Future<void> upsert(PhotoReminder reminder) async {
    await _box.put(reminder.id, reminder.toMap());
  }

  Future<void> removeById(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
