/// Local SQLite model for the private My Notes feature.
///
/// This model intentionally contains no employee, company, role, sharing, or
/// cloud-sync fields. Notes belong only to the current app installation.
class NoteModel {
  static const String tableName = 'notes';

  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContent = 'content';
  static const String columnIsPinned = 'is_pinned';
  static const String columnColorValue = 'color_value';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  /// Zero means that the UI should use its default note-card color.
  static const int defaultColorValue = 0;

  final int? id;
  final String title;
  final String content;
  final bool isPinned;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    this.id,
    required this.title,
    required this.content,
    this.isPinned = false,
    this.colorValue = defaultColorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromMap(Map<String, Object?> map) {
    final createdAt = _date(map[columnCreatedAt]);
    return NoteModel(
      id: _nullableInt(map[columnId]),
      title: _string(map[columnTitle]),
      content: _string(map[columnContent]),
      isPinned: _bool(map[columnIsPinned]),
      colorValue: _int(
        map[columnColorValue],
        fallback: defaultColorValue,
      ),
      createdAt: createdAt,
      updatedAt: _date(map[columnUpdatedAt], fallback: createdAt),
    );
  }

  /// Converts the note to the row format expected by SQLite.
  ///
  /// Pass [includeId] as false for inserts because SQLite generates the
  /// primary key automatically. Updates and general serialization include it.
  Map<String, Object?> toMap({bool includeId = true}) {
    return <String, Object?>{
      if (includeId && id != null) columnId: id,
      columnTitle: title,
      columnContent: content,
      columnIsPinned: isPinned ? 1 : 0,
      columnColorValue: colorValue,
      columnCreatedAt: createdAt.toUtc().toIso8601String(),
      columnUpdatedAt: updatedAt.toUtc().toIso8601String(),
    };
  }

  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    bool? isPinned,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isNew => id == null;
  bool get hasCustomColor => colorValue != defaultColorValue;
  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;

  String get displayTitle =>
      title.trim().isEmpty ? 'Untitled Note' : title.trim();

  String get preview {
    final normalized = content
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized;
  }
}

/// Short alias for code that follows the specification's `Note` naming.
typedef Note = NoteModel;

String _string(Object? value) => value?.toString() ?? '';

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return const {'1', 'true', 'yes', 'on'}
      .contains(value?.toString().trim().toLowerCase());
}

DateTime _date(Object? value, {DateTime? fallback}) {
  final text = value?.toString().trim() ?? '';
  final parsed = text.isEmpty ? null : DateTime.tryParse(text);
  return parsed?.toLocal() ?? fallback ?? DateTime.now();
}
