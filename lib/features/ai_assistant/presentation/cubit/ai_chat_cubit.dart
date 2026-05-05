import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:super_app/core/services/ai/gemini_service.dart';
import 'package:super_app/core/services/ai/rag_service.dart';
import 'package:super_app/core/services/ai/voice_service.dart';
import 'package:super_app/features/ai_assistant/data/models/chat_message_model.dart';

import '../../../../core/services/media/audio_handler.dart';
import '../../../../core/utils/hive_box_constants.dart';
import '../../../../injection_container.dart';
import 'ai_chat_state.dart';
import 'chat_message.dart';

class AiChatCubit extends Cubit<AiChatState> {
  final RagService _ragService;
  final VoiceService _voiceService;
  final List<ChatMessage> _history = [];
  late Box<ChatMessageModel> _chatBox;
  bool _isCallMode = false;
  bool _hasApiKey = true;

  AiChatCubit(this._ragService, this._voiceService) : super(AiChatInitial()) {
    _initChat();
  }

  Future<void> checkApiKey() async {
    final keys = await sl<GeminiService>().getApiKeys();
    final previousApiKeyStatus = _hasApiKey;
    _hasApiKey = keys.isNotEmpty;

    // Emit new state if there's a change in the API key presence
    if (previousApiKeyStatus != _hasApiKey && state is! AiChatInitial) {
      emit(
        AiChatLoaded(
          List.from(_history),
          isCallMode: _isCallMode,
          hasApiKey: _hasApiKey,
        ),
      );
    }
  }

  Future<void> _initChat() async {
    await checkApiKey();
    _chatBox = await Hive.openBox<ChatMessageModel>(HiveBoxConstants.chatBox);

    if (_chatBox.isEmpty) {
      final welcome = ChatMessage(
        content: ai.Content.model([
          ai.TextPart(
            "Halo! Saya asisten musik SoundWave. Ada yang bisa saya bantu? "
            "Saya bisa merekomendasikan lagu berdasarkan suasana hatimu atau "
            "memberikan informasi tentang artis favoritmu.",
          ),
        ]),
        timestamp: DateTime.now(),
      );
      _history.add(welcome);
      await _chatBox.add(ChatMessageModel.fromEntity(welcome));
    } else {
      _history.addAll(_chatBox.values.map((m) => m.toEntity()));
    }

    emit(AiChatLoaded(List.from(_history), hasApiKey: _hasApiKey));
  }

  Future<void> toggleCallMode() async {
    await checkApiKey();
    if (!_hasApiKey) {
      emit(
        AiChatLoaded(
          List.from(_history),
          isCallMode: _isCallMode,
          hasApiKey: false,
        ),
      );
      return;
    }

    _isCallMode = !_isCallMode;
    if (!_isCallMode) {
      await _voiceService.stopSpeaking();
      await _voiceService.stopListening();
      // Kembalikan AudioSession ke mode musik
      await _restoreAudioSessionToMusic();
      emit(
        AiChatLoaded(
          List.from(_history),
          isCallMode: false,
          hasApiKey: _hasApiKey,
        ),
      );
    } else {
      // Stop musik & ubah AudioSession ke mode recording
      await sl<AudioHandler>().stop();
      await _switchAudioSessionToRecording();

      emit(AiChatLoaded(List.from(_history), isCallMode: true));
      startVoiceListening();
    }
  }

  Future<void> _switchAudioSessionToRecording() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        ),
      );
      await session.setActive(true);
      print("AiChatCubit: AudioSession → playAndRecord ✓");
    } catch (e) {
      print("AiChatCubit: AudioSession config gagal: $e");
    }
  }

  Future<void> _restoreAudioSessionToMusic() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      print("AiChatCubit: AudioSession → music ✓");
    } catch (e) {
      print("AiChatCubit: AudioSession restore gagal: $e");
    }
  }

  Future<void> startVoiceListening() async {
    await checkApiKey();
    if (!_hasApiKey) {
      emit(
        AiChatLoaded(
          List.from(_history),
          isCallMode: _isCallMode,
          hasApiKey: false,
        ),
      );
      return;
    }

    if (state is AiChatListening) {
      await _voiceService.stopListening();
      emit(
        AiChatLoaded(
          List.from(_history),
          isCallMode: _isCallMode,
          hasApiKey: _hasApiKey,
        ),
      );
      return;
    }

    emit(
      AiChatListening(
        List.from(_history),
        isCallMode: _isCallMode,
        hasApiKey: _hasApiKey,
      ),
    );

    await _voiceService.startListening(
      onResult: (text) {
        if (text.isNotEmpty) {
          sendMessage(text);
        }
      },
      onSilence: () {
        if (state is AiChatListening) {
          emit(
            AiChatLoaded(
              List.from(_history),
              isCallMode: _isCallMode,
              hasApiKey: _hasApiKey,
            ),
          );
        }
      },
    );
  }

  Future<void> sendMessage(String message, {bool isRetry = false}) async {
    if (message.trim().isEmpty) return;

    await checkApiKey();
    if (!_hasApiKey) {
      emit(
        AiChatLoaded(
          List.from(_history),
          isCallMode: _isCallMode,
          hasApiKey: false,
        ),
      );
      return;
    }

    if (!isRetry) {
      final userMsg = ChatMessage(
        content: ai.Content.text(message),
        timestamp: DateTime.now(),
      );
      _history.add(userMsg);
      await _chatBox.add(ChatMessageModel.fromEntity(userMsg));
    }
    emit(
      AiChatLoading(
        List.from(_history),
        isCallMode: _isCallMode,
        hasApiKey: _hasApiKey,
      ),
    );

    try {
      List<ai.Content> geminiHistory = _history.length > 7
          ? _history
                .sublist(_history.length - 7, _history.length - 1)
                .map((e) => e.content)
                .toList()
          : _history.take(_history.length - 1).map((e) => e.content).toList();

      // Gemini API REQUIRES the history to start with a 'user' message
      while (geminiHistory.isNotEmpty && geminiHistory.first.role != 'user') {
        geminiHistory.removeAt(0);
      }

      final response = await _ragService.processQuery(
        message,
        history: geminiHistory,
        isCallMode: _isCallMode,
      );

      final aiMsg = ChatMessage(
        content: ai.Content.model([ai.TextPart(response)]),
        timestamp: DateTime.now(),
      );
      _history.add(aiMsg);
      await _chatBox.add(ChatMessageModel.fromEntity(aiMsg));

      emit(
        AiChatLoaded(
          List.from(_history),
          isCallMode: _isCallMode,
          hasApiKey: _hasApiKey,
        ),
      );

      // If in Call Mode, speak the response
      if (_isCallMode) {
        await _voiceService.speak(
          response,
          onComplete: () {
            // After AI finishes speaking, start listening again for the next user input
            if (_isCallMode) {
              startVoiceListening();
            }
          },
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      final errorMsg = ChatMessage(
        content: ai.Content.model([ai.TextPart(errorMessage)]),
        timestamp: DateTime.now(),
      );
      _history.add(errorMsg);
      emit(
        AiChatError(errorMessage, List.from(_history), isCallMode: _isCallMode),
      );

      if (_isCallMode) {
        await _voiceService.speak(
          "Maaf, terjadi kesalahan. Silakan coba lagi.",
        );
      }
    }
  }

  Future<void> retryLastMessage() async {
    if (_history.isEmpty) return;

    String? lastUserMessage;
    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].content.role == 'user') {
        final text = _history[i].content.parts
            .whereType<ai.TextPart>()
            .map((e) => e.text)
            .join();
        lastUserMessage = text;
        _history.removeRange(i + 1, _history.length);
        final keysToRemove = _chatBox.keys.skip(i + 1).toList();
        await _chatBox.deleteAll(keysToRemove);
        break;
      }
    }

    if (lastUserMessage != null) {
      await sendMessage(lastUserMessage, isRetry: true);
    }
  }

  Future<void> clearChat() async {
    await _chatBox.clear();
    _history.clear();

    final welcome = ChatMessage(
      content: ai.Content.model([
        ai.TextPart(
          "Halo! Saya asisten musik SoundWave. Ada yang bisa saya bantu?",
        ),
      ]),
      timestamp: DateTime.now(),
    );
    _history.add(welcome);
    await _chatBox.add(ChatMessageModel.fromEntity(welcome));

    emit(AiChatLoaded(List.from(_history), isCallMode: _isCallMode));
  }
}
