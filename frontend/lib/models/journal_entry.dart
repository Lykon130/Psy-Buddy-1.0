// lib/models/journal_entry.dart
class JournalEntry {
  final String id;
  final String username;
  final String title;
  final String content;
  final DateTime timestamp;
  final String emotion;
  final double emotionScore;

  JournalEntry({
    required this.id,
    required this.username,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.emotion,
    required this.emotionScore,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      emotion: json['emotion'] ?? 'neutral',
      emotionScore: (json['emotion_score'] ?? 0).toDouble(),
    );
  }
}
