import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:hive/hive.dart';

import '../../../../core/utils/hive_box_constants.dart';
import '../../presentation/cubit/chat_message.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: HiveBoxConstants.chatMessageTypeId)
class ChatMessageModel {
  @HiveField(0)
  final String role;
  @HiveField(1)
  final String text;
  @HiveField(2)
  final DateTime timestamp;

  ChatMessageModel({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      role: entity.content.role ?? 'user',
      text: entity.content.parts
          .whereType<ai.TextPart>()
          .map((e) => e.text)
          .join(),
      timestamp: entity.timestamp,
    );
  }

  ChatMessage toEntity() {
    return ChatMessage(
      content: role == 'user'
          ? ai.Content.text(text)
          : ai.Content.model([ai.TextPart(text)]),
      timestamp: timestamp,
    );
  }
}
