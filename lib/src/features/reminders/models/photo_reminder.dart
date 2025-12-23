class PhotoReminder {
  PhotoReminder({
    required this.id,
    required this.imagePath,
    required this.dateTaken,
    required this.remindAt,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String imagePath;
  final DateTime dateTaken;
  final DateTime remindAt;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'dateTaken': dateTaken.toIso8601String(),
      'remindAt': remindAt.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static PhotoReminder fromMap(Map<String, dynamic> map) {
    return PhotoReminder(
      id: map['id'] as String,
      imagePath: map['imagePath'] as String,
      dateTaken: DateTime.parse(map['dateTaken'] as String),
      remindAt: DateTime.parse(map['remindAt'] as String),
      note: map['note'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
