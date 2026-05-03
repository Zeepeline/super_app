import 'package:google_generative_ai/google_generative_ai.dart';

import 'secure_storage_service.dart';

class GeminiService {
  final SecureStorageService _secureStorage;

  // Daftar model PERSIS sesuai urutan yang Anda berikan
  final List<String> _modelPriorityList = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.5-pro',
    'gemini-2-flash',
    'gemini-2-flash-lite',
    'gemini-3-flash',
    'gemini-3.1-flash-lite',
    'gemini-3.1-pro',
    'gemini-2.5-flash-live',
    'gemini-3-flash-live',
  ];

  List<String> get activeModels => List.unmodifiable(_modelPriorityList);

  GeminiService(this._secureStorage);

  Future<List<String>> getApiKeys() async {
    return await _secureStorage.getGeminiApiKeys();
  }

  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.addGeminiApiKey(apiKey);
  }

  Future<bool> hasApiKey() async {
    final keys = await getApiKeys();
    return keys.isNotEmpty;
  }

  Future<String?> getApiKey() async {
    return await _secureStorage.getGeminiApiKey();
  }

  GenerativeModel _createModel(
    String modelName,
    String apiKey, {
    List<Tool>? tools,
    bool isCallMode = false,
  }) {
    final String systemPrompt = isCallMode
        ? "Anda adalah asisten musik SoundWave dalam mode Voice Call (Telepon).\n"
              "Rules:\n"
              "1. NATIVE AUDIO DIALOG: Jawab layaknya manusia sedang berbicara di telepon. Gunakan bahasa Indonesia sehari-hari yang luwes, santai, namun cerdas.\n"
              "2. SINGKAT & PADAT: Jawab langsung pada intinya, maksimal 2-3 kalimat pendek agar tidak terlalu lama dibacakan oleh TTS.\n"
              "3. TANPA FORMAT TEKS: DILARANG KERAS menggunakan Markdown (seperti **bold**, *italic*, atau # header) atau simbol kompleks karena akan dibacakan secara literal oleh TTS.\n"
              "4. AGENT: Anda memiliki akses ke tools untuk memutar lagu, menjeda, atau mencari library. Gunakan tools jika user memberikan perintah.\n"
              "5. AKURASI: Jika ditanya lirik atau trivia, sebutkan secara singkat dan jelas."
        : "Anda adalah SoundWave AI, pakar musik global yang akurat dan informatif.\n"
              "Rules:\n"
              "1. AKURASI ADALAH PRIORITAS: Jangan pernah mengarang lirik lagu. Jika tidak tahu, katakan sejujurnya.\n"
              "2. TO-THE-POINT: Jangan memberikan permintaan maaf yang panjang atau penjelasan robotik. Jawab langsung permintaan user.\n"
              "3. FORMAT: Gunakan Markdown (Bold untuk judul/artis, blockquote untuk lirik) agar rapi.\n"
              "4. KONTEKS: Berikan sedikit trivia menarik jika memberikan lirik atau rekomendasi.\n"
              "5. BAHASA: Gunakan bahasa Indonesia yang santai tapi tetap profesional dan cerdas.\n"
              "6. AGENT: Anda memiliki akses ke tools untuk memutar lagu, menjeda, atau mencari library. Gunakan tools jika user memberikan perintah.";

    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      tools: tools,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: 1000,
        temperature: 0.7,
        topP: 0.9,
      ),
    );
  }

  Future<GenerateContentResponse?> getAgenticResponse(
    String prompt, {
    List<Content>? history,
    List<Tool>? tools,
    bool isCallMode = false,
  }) async {
    final apiKeys = await getApiKeys();
    if (apiKeys.isEmpty) return null;

    String? lastError;
    for (String apiKey in apiKeys) {
      for (String modelName in _modelPriorityList) {
        try {
          final model = _createModel(
            modelName,
            apiKey,
            tools: tools,
            isCallMode: isCallMode,
          );
          final chat = model.startChat(history: history);
          return await chat.sendMessage(Content.text(prompt));
        } catch (e) {
          lastError = e.toString();
          print("GeminiService: Model $modelName failed - $lastError");
          if (lastError.contains('429')) break;
          continue;
        }
      }
    }
    print("GeminiService: All agentic models failed. Last error: $lastError");
    return null;
  }

  Future<String> getChatResponse(
    String prompt, {
    List<Content>? history,
  }) async {
    final apiKeys = await getApiKeys();
    if (apiKeys.isEmpty) {
      return "API Key belum diatur. Silakan masuk ke menu Konfigurasi AI (ikon gear di atas) untuk memasukkan kunci Anda.";
    }

    String? lastError;

    // Outer loop: Try each API Key
    for (String apiKey in apiKeys) {
      // Inner loop: Try each model in priority list
      for (String modelName in _modelPriorityList) {
        try {
          final model = _createModel(modelName, apiKey);
          final chat = model.startChat(history: history);
          final response = await chat.sendMessage(Content.text(prompt));

          if (response.text != null) {
            return response.text!;
          }
        } catch (e) {
          lastError = e.toString();
          // If the error is 429 (limit), break inner loop and try next API Key
          if (lastError.contains('429')) {
            break;
          }
          // For other errors, try next model with same API Key
          continue;
        }
      }
    }

    if (lastError != null) {
      if (lastError.contains('503')) {
        return "Semua model Google sedang sibuk. Mohon coba lagi nanti.";
      } else if (lastError.contains('429')) {
        return "Batas limit SEMUA API Key Anda telah tercapai. Silakan tambah key baru atau tunggu beberapa saat.";
      }
    }
    return "Waduh, semua model AI di list sedang kendala. Pastikan API Key Anda valid dan coba lagi ya!";
  }

  Future<String> getRecommendation(String userContext) async {
    final apiKeys = await getApiKeys();
    if (apiKeys.isEmpty) return "API Key missing.";

    final prompt =
        """
    You are a music expert assistant. Based on the following user music context, 
    provide 3 personalized song recommendations. 
    Explain why you chose each one briefly.
    
    User Context: $userContext
    """;

    for (String apiKey in apiKeys) {
      for (String modelName in _modelPriorityList) {
        try {
          final model = _createModel(modelName, apiKey);
          final response = await model.generateContent([Content.text(prompt)]);
          if (response.text != null) {
            return response.text!;
          }
        } catch (e) {
          if (e.toString().contains('429')) break;
          continue;
        }
      }
    }
    return "Gagal mengambil rekomendasi. Coba lagi nanti.";
  }

  Future<void> deleteApiKey(String key) async {
    await _secureStorage.deleteGeminiApiKey(key);
  }
}
