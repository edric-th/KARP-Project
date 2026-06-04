import 'package:frontend/services/api_client.dart';

/// One reply from the in-process Gemini assistant (POST /api/chatbot/query).
class ChatReply {
  final String response;
  final String intentCategory;
  final bool isEmergency;
  final bool disclaimerAdded;
  final double confidenceScore;

  const ChatReply({
    required this.response,
    this.intentCategory = 'general',
    this.isEmergency = false,
    this.disclaimerAdded = false,
    this.confidenceScore = 0,
  });

  factory ChatReply.fromJson(Map<String, dynamic> j) => ChatReply(
        response: (j['response'] ?? '').toString(),
        intentCategory: (j['intentCategory'] ?? 'general').toString(),
        isEmergency: j['isEmergency'] == true,
        disclaimerAdded: j['disclaimerAdded'] == true,
        confidenceScore:
            j['confidenceScore'] is num ? (j['confidenceScore'] as num).toDouble() : 0,
      );
}

class ChatService {
  ChatService(this._api);
  final ApiClient _api;

  /// Send a message to the assistant. The backend keys conversation memory by
  /// the authenticated user, so [sessionId] is optional.
  Future<ChatReply> query(String message, {String? sessionId}) async {
    final data = await _api.post('/chatbot/query', auth: true, body: {
      'message': message,
      'sessionId': ?sessionId,
    });
    return ChatReply.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
