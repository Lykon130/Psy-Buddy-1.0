class ChatMessage {
  final String id;
  final String sender; // "user" or "assistant"
  final String message;
  final DateTime timestamp;
  final bool isUser;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.isUser,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      sender: json['role'] ?? '',
      message: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isUser: (json['role'] ?? '') == 'user',
    );
  }
}
