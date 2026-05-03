import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/journal_entry.dart';
import '../models/dream_entry.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000"; // Change for production
  static const Duration _timeout = Duration(seconds: 10);

  // ======================
  // Common Response Handler
  // ======================
  static dynamic _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    } else {
      try {
        final error = jsonDecode(res.body);
        if (error is Map && error.containsKey('detail')) {
          throw Exception(error['detail']);
        }
      } catch (_) {}
      throw Exception("Server error: ${res.statusCode}");
    }
  }

  static Future<T> _safeRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SocketException {
      throw Exception("No internet connection");
    } on HttpException {
      throw Exception("Could not connect to the server");
    } on FormatException {
      throw Exception("Invalid response format");
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ======================
  // CHAT
  // ======================
  static Future<List<Map<String, dynamic>>> fetchChatSessions(String username) {
    return _safeRequest(() async {
      final res = await http
          .get(Uri.parse('$baseUrl/chat/history/$username'))
          .timeout(_timeout);
      return List<Map<String, dynamic>>.from(_handleResponse(res));
    });
  }

  static Future<List<ChatMessage>> fetchSessionMessages(
      String username, String sessionId) {
    return _safeRequest(() async {
      final res = await http
          .get(Uri.parse('$baseUrl/chat/history/$username/$sessionId'))
          .timeout(_timeout);
      final List data = _handleResponse(res);
      return data.map((m) => ChatMessage.fromJson(m)).toList();
    });
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required String username,
    required String message,
    required String persona,
    String? sessionId,
  }) {
    return _safeRequest(() async {
      final res = await http
          .post(
            Uri.parse('$baseUrl/chat/'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": username,
              "message": message,
              "persona": persona,
              "session_id": sessionId,
            }),
          )
          .timeout(_timeout);
      return _handleResponse(res);
    });
  }

  // ======================
  // JOURNAL
  // ======================
  static Future<List<JournalEntry>> fetchJournalEntries(String username) {
    return _safeRequest(() async {
      final res = await http
          .get(Uri.parse('$baseUrl/journal/$username'))
          .timeout(_timeout);
      final List data = _handleResponse(res);
      return data.map((j) => JournalEntry.fromJson(j)).toList();
    });
  }

  static Future<JournalEntry> addJournalEntry(
  String username,
  String title,
  String content,
) {
  return _safeRequest(() async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/journal/'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "username": username, // ✅ added this
            "title": title,
            "content": content,
          }),
        )
        .timeout(_timeout);
    return JournalEntry.fromJson(_handleResponse(res));
  });
}

  // ======================
  // DREAMS
  // ======================
  static Future<List<DreamEntry>> fetchDreamEntries(String username) {
    return _safeRequest(() async {
      final res = await http
          .get(Uri.parse('$baseUrl/dreams/$username'))
          .timeout(_timeout);
      final List data = _handleResponse(res);
      return data.map((d) => DreamEntry.fromJson(d)).toList();
    });
  }

  static Future<DreamEntry> addDreamEntry(
    String username,
    String title,
    String content,
  ) {
    return _safeRequest(() async {
      final res = await http
          .post(
            Uri.parse('$baseUrl/dreams/'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "username": username,
              "title": title,
              "content": content,
            }),
          )
          .timeout(_timeout);
      return DreamEntry.fromJson(_handleResponse(res));
    });
  }

  // ======================
  // MOOD
  // ======================
  static Future<Map<String, dynamic>> fetchMoodData(
    String username, {
    int days = 7,
  }) {
    return _safeRequest(() async {
      final res = await http
          .get(Uri.parse('$baseUrl/mood/$username?days=$days'))
          .timeout(_timeout);
      return _handleResponse(res);
    });
  }
}
