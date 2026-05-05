import 'package:google_generative_ai/google_generative_ai.dart';

import '../infrastructure/secure_storage_service.dart';

class GeminiService {
  final SecureStorageService _secureStorage;

  // Daftar model PERSIS sesuai urutan yang Anda berikan
  final List<String> _modelPriorityList = [
    'gemini-3.1-flash-lite-preview',
    'gemini-3.1-pro',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.5-pro',
    'gemini-2-flash',
    'gemini-2-flash-lite',
    'gemini-3-flash',
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
        ? "Anda adalah SoundWave AI Voice Assistant (Mode Telepon).\n"
              "SIFAT: Hangat, singkat, cerdas. Anda adalah persona hasil fine-tuning.\n"
              "GRAPH-AUGMENTED RAG:\n"
              "1. SELALU hubungkan informasi baru. Jika user bilang suka artis X, panggil 'save_user_fact' (User, suka, X).\n"
              "2. Gunakan KONTEKS MEMORI (Graph) yang diberikan untuk mempersonalisasi jawaban.\n"
              "3. SINGKAT: Maksimal 2 kalimat, tanpa markdown."
        : "Anda adalah SoundWave AI (Super App Expert).\n"
              "SIFAT: Asisten cerdas, pakar musik dan literasi dunia.\n"
              "KEMAMPUAN:\n"
              "1. PRIORITAS LOKAL: Jika user bertanya tentang lagu/buku, selalu cek library lokal dulu pakai 'search_library' atau 'search_books'.\n"
              "2. PENGETAHUAN UMUM: Jika tidak ada di library, gunakan pengetahuan luas Anda untuk memberikan informasi, sinopsis, atau rekomendasi dari dunia luar.\n"
              "3. TINDAKAN: Jika user tertarik pada lagu yang tidak ada di library, tawarkan untuk mendownloadnya menggunakan 'download_music'.\n"
              "4. MEMORI: Simpan fakta preferensi user ke Graph Memory agar Anda makin kenal dengan selera mereka.";

    // Definisi Tools untuk Function Calling
    final List<Tool> availableTools = [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            'play_track',
            'Memutar lagu berdasarkan judul atau query.',
            Schema(
              SchemaType.object,
              properties: {
                'query': Schema(
                  SchemaType.string,
                  description: 'Judul lagu atau nama artis.',
                ),
              },
              requiredProperties: ['query'],
            ),
          ),
          FunctionDeclaration(
            'pause_music',
            'Menghentikan musik yang sedang diputar.',
            Schema(SchemaType.object),
          ),
          FunctionDeclaration(
            'search_library',
            'Mencari lagu di library musik lokal user.',
            Schema(
              SchemaType.object,
              properties: {
                'query': Schema(
                  SchemaType.string,
                  description: 'Kata kunci pencarian.',
                ),
              },
              requiredProperties: ['query'],
            ),
          ),
          FunctionDeclaration(
            'search_books',
            'Mencari buku di library buku/e-book lokal user berdasarkan judul, penulis, atau sinopsis.',
            Schema(
              SchemaType.object,
              properties: {
                'query': Schema(
                  SchemaType.string,
                  description: 'Kata kunci pencarian buku.',
                ),
              },
              requiredProperties: ['query'],
            ),
          ),
          FunctionDeclaration(
            'get_lyrics',
            'Mendapatkan lirik lagu tertentu.',
            Schema(
              SchemaType.object,
              properties: {
                'query': Schema(SchemaType.string, description: 'Judul lagu.'),
              },
              requiredProperties: ['query'],
            ),
          ),
          FunctionDeclaration(
            'save_user_fact',
            'Menyimpan fakta terstruktur tentang preferensi user ke memori jangka panjang.',
            Schema(
              SchemaType.object,
              properties: {
                'subject': Schema(
                  SchemaType.string,
                  description: 'Subjek (misal: "User", "Artist").',
                ),
                'predicate': Schema(
                  SchemaType.string,
                  description:
                      'Relasi (misal: "suka", "benci", "sering_putar").',
                ),
                'object': Schema(
                  SchemaType.string,
                  description: 'Objek fakta (misal: "Jazz", "Taylor Swift").',
                ),
              },
              requiredProperties: ['subject', 'predicate', 'object'],
            ),
          ),
          FunctionDeclaration(
            'get_user_memories',
            'Mengambil semua informasi yang diingat tentang user untuk personalisasi.',
            Schema(SchemaType.object),
          ),
          FunctionDeclaration(
            'set_system_volume',
            'Mengatur volume sistem perangkat.',
            Schema(
              SchemaType.object,
              properties: {
                'percent': Schema(
                  SchemaType.integer,
                  description: 'Persentase volume 0-100.',
                ),
              },
              requiredProperties: ['percent'],
            ),
          ),
          FunctionDeclaration(
            'get_system_status',
            'Mendapatkan status baterai, koneksi, dan volume sistem saat ini.',
            Schema(SchemaType.object),
          ),
          FunctionDeclaration(
            'get_device_info',
            'Mendapatkan informasi model perangkat dan versi aplikasi.',
            Schema(SchemaType.object),
          ),
          FunctionDeclaration(
            'download_music',
            'Mendownload lagu baru dari YouTube ke library lokal.',
            Schema(
              SchemaType.object,
              properties: {
                'query': Schema(
                  SchemaType.string,
                  description: 'Judul lagu, artis, atau URL YouTube.',
                ),
              },
              requiredProperties: ['query'],
            ),
          ),
        ],
      ),
    ];

    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      tools: availableTools,
      systemInstruction: Content.text(systemPrompt),
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
          final isQuotaExceeded =
              lastError.contains('429') ||
              lastError.toLowerCase().contains('quota exceeded') ||
              lastError.toLowerCase().contains('exceeded your current quota');
          if (isQuotaExceeded) break;
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
          print("GeminiService Error [$modelName]: $lastError");
          // If the error is 429 or quota exceeded, break inner loop and try next API Key
          final isQuotaExceeded =
              lastError.contains('429') ||
              lastError.toLowerCase().contains('quota exceeded') ||
              lastError.toLowerCase().contains('exceeded your current quota');
          if (isQuotaExceeded) {
            break;
          }
          // For other errors, try next model with same API Key
          continue;
        }
      }
    }

    if (lastError != null) {
      final isQuotaExceeded =
          lastError.contains('429') ||
          lastError.toLowerCase().contains('quota exceeded') ||
          lastError.toLowerCase().contains('exceeded your current quota');

      if (lastError.contains('503')) {
        return "Semua model Google sedang sibuk. Mohon coba lagi nanti.";
      } else if (isQuotaExceeded) {
        return "Batas limit (Quota) API Key Anda telah tercapai. Silakan tunggu sekitar 1 menit atau tambah API Key baru di Konfigurasi.";
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
