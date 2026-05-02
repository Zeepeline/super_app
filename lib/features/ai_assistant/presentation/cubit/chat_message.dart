import 'package:google_generative_ai/google_generative_ai.dart' as ai;

class ChatMessage {
  final ai.Content content;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.timestamp,
  });
}
