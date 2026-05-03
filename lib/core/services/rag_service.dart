import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_rag_engine/mobile_rag_engine.dart';

import 'ai_tools_service.dart';
import 'gemini_service.dart';

class RagService {
  final GeminiService _geminiService;
  final AiToolsService _aiToolsService;

  RagService(this._geminiService, this._aiToolsService);

  Future<String> processQuery(
    String query, {
    List<Content>? history,
    bool isCallMode = false,
  }) async {
    // 1. Search Local Context (Offline RAG)
    String context = "";
    try {
      if (MobileRag.instance.isIndexReady) {
        final ragResult = await MobileRag.instance.search(
          query,
          tokenBudget: 1500,
        );
        context = ragResult.context.text;
      }
    } catch (e) {
      print("RagService: RAG Search failed: $e");
    }

    // 2. Define Tools for Gemini
    final tools = [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            'play_music',
            'Memutar lagu berdasarkan judul, nama artis, atau ID',
            Schema(
              SchemaType.object,
              properties: {
                'query': Schema(
                  SchemaType.string,
                  description: 'Judul lagu, artis, atau ID lagu',
                ),
              },
              // required: ['query'],
            ),
          ),
          FunctionDeclaration(
            'pause_music',
            'Menghentikan musik yang sedang diputar',
            Schema(SchemaType.object, properties: {}),
          ),
          FunctionDeclaration(
            'resume_music',
            'Melanjutkan musik yang dijeda',
            Schema(SchemaType.object, properties: {}),
          ),
          FunctionDeclaration(
            'skip_next',
            'Memutar lagu selanjutnya',
            Schema(SchemaType.object, properties: {}),
          ),
        ],
      ),
    ];

    // 3. Prepare Prompt with Context
    final prompt =
        """
DATA LOKAL DARI LIBRARY USER (Gunakan ini jika user bertanya tentang lagunya):
$context

PERTANYAAN USER: $query
""";

    // 4. Get Agentic Response from Gemini
    final response = await _geminiService.getAgenticResponse(
      prompt,
      history: history,
      tools: tools,
      isCallMode: isCallMode,
    );

    if (response == null) return "Maaf, terjadi kesalahan saat menghubungi AI.";

    // 5. Handle Function Calls
    final functionCalls = response.functionCalls;

    if (functionCalls.isNotEmpty) {
      final call = functionCalls.first;

      print(
        "RagService: Gemini triggered tool: ${call.name} with args: ${call.args}",
      );

      switch (call.name) {
        case 'play_music':
          final q = call.args['query'] as String;
          return await _aiToolsService.playTrack(q);
        case 'pause_music':
          return await _aiToolsService.pauseMusic();
        case 'resume_music':
          return await _aiToolsService.resumeMusic();
        case 'skip_next':
          return await _aiToolsService.skipNext();
      }
    }

    return response.text ?? "Selesai.";
  }
}
