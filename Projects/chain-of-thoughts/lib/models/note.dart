import 'dart:convert';

class Note {
  Note({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.text,
    required this.transcript,
    required this.intent,
    required this.topics,
    required this.audioPath,
    required this.archived,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String text;
  final String transcript;
  final String intent;
  final List<String> topics;
  final String? audioPath;
  final bool archived;

  Note copyWith({
    String? text,
    String? transcript,
    String? intent,
    List<String>? topics,
    String? audioPath,
    bool? archived,
    required DateTime updatedAt,
  }) {
    return Note(
      id: id,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      text: text ?? this.text,
      transcript: transcript ?? this.transcript,
      intent: intent ?? this.intent,
      topics: topics ?? this.topics,
      audioPath: audioPath ?? this.audioPath,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'text': text,
      'transcript': transcript,
      'intent': intent,
      'topics': topics,
      'audioPath': audioPath,
      'archived': archived,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      text: json['text'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      intent: json['intent'] as String? ?? '',
      topics: (json['topics'] as List<dynamic>? ?? []).cast<String>(),
      audioPath: json['audioPath'] as String?,
      archived: json['archived'] as bool? ?? false,
    );
  }

  static List<Note> listFromJson(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = (data['notes'] as List<dynamic>? ?? []);
    return items
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<Note> notes) {
    final data = {'notes': notes.map((note) => note.toJson()).toList()};
    return jsonEncode(data);
  }
}
