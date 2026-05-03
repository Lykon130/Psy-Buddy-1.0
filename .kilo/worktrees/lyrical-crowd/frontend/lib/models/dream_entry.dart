class DreamEntry {
  final String id;
  final String username;
  final String title;
  final String content;
  final String? emotion;   // ✅ add emotion
  final DateTime timestamp;

  DreamEntry({
    required this.id,
    required this.username,
    required this.title,
    required this.content,
    this.emotion,
    required this.timestamp,
  });

  factory DreamEntry.fromJson(Map<String, dynamic> json) {
    return DreamEntry(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      emotion: json['emotion'], // ✅ parse emotion
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'title': title,
      'content': content,
      'emotion': emotion,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
