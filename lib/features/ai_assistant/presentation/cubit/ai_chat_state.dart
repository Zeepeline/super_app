import 'package:equatable/equatable.dart';

import 'chat_message.dart';

abstract class AiChatState extends Equatable {
  final List<ChatMessage> history;
  final bool isCallMode;
  final bool hasApiKey;

  const AiChatState({
    this.history = const [],
    this.isCallMode = false,
    this.hasApiKey = true,
  });

  @override
  List<Object?> get props => [history, isCallMode, hasApiKey];
}

class AiChatInitial extends AiChatState {}

class AiChatLoading extends AiChatState {
  const AiChatLoading(
    List<ChatMessage> history, {
    bool isCallMode = false,
    bool hasApiKey = true,
  }) : super(history: history, isCallMode: isCallMode, hasApiKey: hasApiKey);
}

class AiChatLoaded extends AiChatState {
  const AiChatLoaded(
    List<ChatMessage> history, {
    bool isCallMode = false,
    bool hasApiKey = true,
  }) : super(history: history, isCallMode: isCallMode, hasApiKey: hasApiKey);
}

class AiChatListening extends AiChatState {
  const AiChatListening(
    List<ChatMessage> history, {
    bool isCallMode = false,
    bool hasApiKey = true,
  }) : super(history: history, isCallMode: isCallMode, hasApiKey: hasApiKey);
}

class AiChatError extends AiChatState {
  final String message;
  const AiChatError(
    this.message,
    List<ChatMessage> history, {
    bool isCallMode = false,
    bool hasApiKey = true,
  }) : super(history: history, isCallMode: isCallMode, hasApiKey: hasApiKey);

  @override
  List<Object?> get props => [message, history, isCallMode, hasApiKey];
}
