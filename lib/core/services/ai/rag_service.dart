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
    String graphContext = "";
    try {
      // Vector Search
      if (MobileRag.instance.isIndexReady) {
        final ragResult = await MobileRag.instance.search(
          query,
          tokenBudget: 1500,
        );
        context = ragResult.context.text;
      }

      // Graph Search (Entity-Linker)
      // Ekstrak entitas sederhana dari query
      final words = query.split(' ').where((w) => w.length > 3).toList();
      final relatedFacts = _aiToolsService.getMemoryService().findRelatedFacts(words);
      if (relatedFacts.isNotEmpty) {
        graphContext = relatedFacts.map((f) => "- $f").join("\n");
      }
    } catch (e) {
      print("RagService: Search failed: $e");
    }

    // 2. Tools sudah didefinisikan secara global di GeminiService
    final List<Tool>? tools = null; 

    // 3. Prepare Prompt with Augmented Context (Hybrid RAG)
    final prompt =
        """
KONTEKS LIBRARY (Vektor):
$context

KONTEKS MEMORI/HUBUNGAN (Graph):
$graphContext

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
        case 'play_track':
        case 'play_music':
          final q = call.args['query'] as String;
          return await _aiToolsService.playTrack(q);
        case 'pause_music':
          return await _aiToolsService.pauseMusic();
        case 'resume_music':
          return await _aiToolsService.resumeMusic();
        case 'skip_next':
          return await _aiToolsService.skipNext();
        case 'search_library':
          final q = call.args['query'] as String;
          return await _aiToolsService.searchLibrary(q);
        case 'get_lyrics':
          final q = call.args['query'] as String;
          return await _aiToolsService.getLyrics(q);
        case 'save_user_fact':
          final s = call.args['subject'] as String;
          final p = call.args['predicate'] as String;
          final o = call.args['object'] as String;
          return await _aiToolsService.saveUserFact(s, p, o);
        case 'get_user_memories':
          return await _aiToolsService.getUserMemories();
        case 'set_system_volume':
          final p = (call.args['percent'] as num).toInt();
          return await _aiToolsService.setSystemVolume(p);
        case 'get_system_status':
          return await _aiToolsService.getSystemStatus();
        case 'get_device_info':
          return await _aiToolsService.getDeviceInfo();
        case 'download_music':
          final q = call.args['query'] as String;
          return await _aiToolsService.downloadMusic(q);
      }
    }

    return response.text ?? "Selesai.";
  }
}
