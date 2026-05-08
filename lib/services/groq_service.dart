import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const int _maxMessages = 20; // max context messages sent to Groq

  static const String _systemPrompt = '''
You are SwiftSync AI, a friendly and helpful assistant built into the SwiftSync chat app.
You help users with questions, conversations, and anything they need.
Be concise, friendly, and conversational. Keep responses short unless the user asks for detail.
You are not ChatGPT or any other AI — you are SwiftSync AI.
''';

  /// Sends conversation history to Groq and returns the AI response text.
  /// [messages] is a list of {role: 'user'|'assistant', text: '...'} maps.
  Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    try {
      // Take last _maxMessages to stay within token limits
      final recentMessages = messages.length > _maxMessages
          ? messages.sublist(messages.length - _maxMessages)
          : messages;

      // Build Groq message format
      final groqMessages = [
        {'role': 'system', 'content': _systemPrompt},
        ...recentMessages.map((m) => {
              'role': m['role'] as String,
              'content': m['text'] as String,
            }),
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': groqMessages,
          'max_tokens': 1024,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']['message'] ?? 'Groq API error');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timed out. Please try again.');
      }
      rethrow;
    }
  }
}