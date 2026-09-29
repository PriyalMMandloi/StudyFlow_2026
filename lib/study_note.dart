class StudyNote {
  const StudyNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.subject,
  });

  final String id;
  final String userId;
  final String title;
  final String content;
  final String? subject;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StudyNote.fromJson(Map<String, dynamic> json) => StudyNote(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        subject: json['subject'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class StudyNoteDraft {
  const StudyNoteDraft({
    required this.title,
    required this.content,
    this.subject,
  });

  final String title;
  final String content;
  final String? subject;
}

List<StudyNote> filterStudyNotes(Iterable<StudyNote> notes, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return notes.toList();
  return notes.where((note) {
    return note.title.toLowerCase().contains(normalizedQuery) ||
        note.content.toLowerCase().contains(normalizedQuery) ||
        (note.subject?.toLowerCase().contains(normalizedQuery) ?? false);
  }).toList();
}
