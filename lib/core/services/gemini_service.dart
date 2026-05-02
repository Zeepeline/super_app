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

  GenerativeModel _createModel(String modelName, String apiKey) {
    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(
        "Anda adalah SoundWave AI, asisten personal cerdas yang terintegrasi penuh dengan semua data user di aplikasi SoundWave.\n\n"
        "KEMAMPUAN ANDA:\n"
        "1. AKSES DATA: Anda MEMILIKI AKSES ke library musik, catatan, jurnal, mood tracker, dan daftar tugas user melalui sistem RAG terintegrasi. Data yang diberikan di konteks adalah data NYATA dari device user.\n"
        "2. SUMBER DATA: Jika ada data konteks yang diberikan, gunakan itu sebagai sumber utama. Sebutkan bahwa informasi berasal dari 'koleksi/data kamu' agar terasa personal.\n"
        "3. AKURASI: Jawab HANYA berdasarkan data yang tersedia. Jangan mengarang data yang tidak ada di konteks. Jika data tidak cukup, katakan jujur.\n"
        "4. FORMAT: Gunakan Markdown (Bold, bullet list, blockquote untuk lirik) agar rapi.\n"
        "5. BAHASA: Bahasa Indonesia santai tapi cerdas. To-the-point, tidak bertele-tele.\n\n"
        "LARANGAN KERAS:\n"
        "- JANGAN PERNAH mengatakan 'saya tidak punya akses ke library/data pribadi Anda'.\n"
        "- JANGAN PERNAH memberikan disclaimer tentang privasi jika data sudah ada di konteks.\n"
        "- JANGAN mengarang lirik lagu. Jika tidak tahu, katakan sejujurnya.\n"
        "- JANGAN memberikan permintaan maaf yang berlebihan.",
      ),
      generationConfig: GenerationConfig(
        maxOutputTokens: 1000,
        temperature: 0.7,
        topP: 0.9,
      ),
    );
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
