import 'package:equatable/equatable.dart';
import 'chat_message.dart';

abstract class AiChatState extends Equatable {
  const AiChatState();

  @override
  List<Object?> get props => [];
}

class AiChatInitial extends AiChatState {}

class AiChatLoading extends AiChatState {
  final List<ChatMessage> history;
  const AiChatLoading(this.history);

  @override
  List<Object?> get props => [history];
}

class AiChatLoaded extends AiChatState {
  final List<ChatMessage> history;
  const AiChatLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class AiChatError extends AiChatState {
  final String message;
  final List<ChatMessage> history;
  const AiChatError(this.message, this.history);

  @override
  List<Object?> get props => [message, history];
}
