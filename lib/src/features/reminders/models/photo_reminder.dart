class PhotoReminder {
  PhotoReminder({
    required this.id,
    required this.assetId,
    required this.dateTaken,
    required this.remindAt,
    required this.note,
    required this.createdAt,
    this.legacyImagePath,
  });

  final String id;

  /// ✅ New: survives reinstall (stored in Photos library)
  final String assetId;

  /// Old reminders may have only this (and it may not exist after reinstall)
  final String? legacyImagePath;

  final DateTime dateTaken;
  final DateTime remindAt;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'assetId': assetId,
        'legacyImagePath': legacyImagePath,
        'dateTaken': dateTaken.toIso8601String(),
        'remindAt': remindAt.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  static PhotoReminder fromMap(Map<String, dynamic> map) {
    // ✅ Backward compatible:
    // older records used: imagePath
    final legacyPath = (map['legacyImagePath'] as String?) ?? (map['imagePath'] as String?);

    final assetId = (map['assetId'] as String?) ??
        (map['photoId'] as String?) ??
        ''; // empty means “not migrated / legacy only”

    return PhotoReminder(
      id: (map['id'] as String?) ?? '',
      assetId: assetId,
      legacyImagePath: legacyPath,
      dateTaken: DateTime.tryParse((map['dateTaken'] ?? '').toString()) ?? DateTime.now(),
      remindAt: DateTime.tryParse((map['remindAt'] ?? '').toString()) ?? DateTime.now(),
      note: (map['note'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
