import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;

import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/rag_service.dart';
import 'ai_chat_state.dart';
import 'chat_message.dart';

class AiChatCubit extends Cubit<AiChatState> {
  final GeminiService _geminiService;
  final RagService _ragService;
  final List<ChatMessage> _history = [];

  AiChatCubit(this._geminiService, this._ragService) : super(AiChatInitial()) {
    // Sync library in background when chat starts
    _ragService.syncAllTracks();

    // Initial welcome message from AI
    _history.add(
      ChatMessage(
        content: ai.Content.model([
          ai.TextPart(
            "Halo! Saya SoundWave AI, asisten personal cerdasmu. "
            "Saya sudah terhubung dengan koleksi musik dan data pribadimu. "
            "Ada yang bisa saya bantu hari ini?",
          ),
        ]),
        timestamp: DateTime.now(),
      ),
    );
    emit(AiChatLoaded(List.from(_history)));
  }

  Future<void> sendMessage(String message, {bool isRetry = false}) async {
    if (message.trim().isEmpty) return;

    // Add user message to history if not a retry
    if (!isRetry) {
      _history.add(
        ChatMessage(
          content: ai.Content.text(message),
          timestamp: DateTime.now(),
        ),
      );
    }
    emit(AiChatLoading(List.from(_history)));

    try {
      // 1. RAG: Cari konteks dari library lokal
      final localContext = await _ragService.getLocalContext(message);

      // 2. Gabungkan konteks ke pesan (Augmentation)
      String finalPrompt = message;
      if (localContext != null) {
        finalPrompt = "$localContext\n\n"
            "Pertanyaan User: $message\n\n"
            "Instruksi: Jawablah pertanyaan user dengan mengacu pada data library lokal di atas jika relevan. "
            "Jika tidak relevan, gunakan pengetahuan umum Anda.";
      }

      final response = await _geminiService.getChatResponse(
        finalPrompt,
        // Hanya kirim 6 pesan terakhir sebagai konteks untuk hemat token
        history: _history.length > 7
            ? _history
                .sublist(_history.length - 7, _history.length - 1)
                .map((e) => e.content)
                .toList()
            : _history
                .take(_history.length - 1)
                .map((e) => e.content)
                .toList(),
      );

      // Add AI response to history
      _history.add(
        ChatMessage(
          content: ai.Content.model([ai.TextPart(response)]),
          timestamp: DateTime.now(),
        ),
      );
      emit(AiChatLoaded(List.from(_history)));
    } catch (e) {
      // If error, add the error message as an AI response so user can see it
      final errorMessage = e.toString();
      _history.add(
        ChatMessage(
          content: ai.Content.model([ai.TextPart(errorMessage)]),
          timestamp: DateTime.now(),
        ),
      );
      emit(AiChatError(errorMessage, List.from(_history)));
    }
  }

  Future<void> retryLastMessage() async {
    if (_history.isEmpty) return;

    // Cari pesan user terakhir
    String? lastUserMessage;
    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].content.role == 'user') {
        final text = _history[i]
            .content
            .parts
            .whereType<ai.TextPart>()
            .map((e) => e.text)
            .join();
        lastUserMessage = text;

        // Hapus semua pesan setelah pesan user ini (yaitu pesan error/gagal)
        _history.removeRange(i + 1, _history.length);
        break;
      }
    }

    if (lastUserMessage != null) {
      await sendMessage(lastUserMessage, isRetry: true);
    }
  }

  void clearChat() {
    _history.clear();
    _history.add(
      ChatMessage(
        content: ai.Content.model([
          ai.TextPart(
            "Halo! Saya asisten musik SoundWave. Ada yang bisa saya bantu?",
          ),
        ]),
        timestamp: DateTime.now(),
      ),
    );
    emit(AiChatLoaded(List.from(_history)));
  }
}
