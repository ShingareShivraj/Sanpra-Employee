class ChatReactionModel {
  final String reaction;
  final int count;
  final bool reactedByMe;

  const ChatReactionModel({
    required this.reaction,
    required this.count,
    required this.reactedByMe,
  });

  factory ChatReactionModel.fromJson(Map<String, dynamic> json) {
    return ChatReactionModel(
      reaction: json['reaction']?.toString() ?? '',
      count: _toInt(json['count']),
      reactedByMe: _toBool(json['reacted_by_me']),
    );
  }

  ChatReactionModel copyWith({
    String? reaction,
    int? count,
    bool? reactedByMe,
  }) {
    return ChatReactionModel(
      reaction: reaction ?? this.reaction,
      count: count ?? this.count,
      reactedByMe: reactedByMe ?? this.reactedByMe,
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return const {'1', 'true', 'yes', 'on'}
        .contains(value?.toString().toLowerCase());
  }
}
