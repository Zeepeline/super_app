import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

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
          FunctionDeclaration(
            'generate_smart_playlist',
            'Membuat dan meracik playlist musik pintar berdasarkan permintaan user menggunakan YouTube Music dan mengembalikannya ke UI obrolan.',
            Schema(
              SchemaType.object,
              properties: {
                'query': Schema(
                  SchemaType.string,
                  description: 'Permintaan user (suasana hati, aktivitas, atau nama artis).',
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
          debugPrint("GeminiService: Model $modelName failed - $lastError");
          final isQuotaExceeded =
              lastError.contains('429') ||
              lastError.toLowerCase().contains('quota exceeded') ||
              lastError.toLowerCase().contains('exceeded your current quota');
          if (isQuotaExceeded) break;
          continue;
        }
      }
    }
    debugPrint("GeminiService: All agentic models failed. Last error: $lastError");
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
          debugPrint("GeminiService Error [$modelName]: $lastError");
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

  Future<String> getTaskRecommendation({
    required String kbContent,
    required String currentTime,
    required String userContext,
  }) async {
    final apiKeys = await getApiKeys();
    if (apiKeys.isEmpty) return "API Key missing.";

    final prompt = """
Anda adalah AI Produktivitas Pakar. Gunakan Knowledge Base (KB) di bawah ini untuk memberikan 1 rekomendasi tugas yang paling relevan untuk user saat ini.

KNOWLEDGE BASE:
$kbContent

KONTEKS SAAT INI:
- Jam: $currentTime
- Status User: $userContext

TUGAS ANDA:
Berikan rekomendasi tugas dalam format JSON berikut agar aplikasi bisa otomatis mengisi form:
{
  "title": "Judul Tugas",
  "description": "Deskripsi singkat dan motivasi",
  "category": "Work/Personal/Fitness/Reading",
  "priority": "low/medium/high",
  "estimated_minutes": 30,
  "subtasks": ["subtask 1", "subtask 2"]
}

Hanya berikan JSON, tanpa teks tambahan.
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
    return "Gagal mengambil rekomendasi.";
  }

  Future<String> createSmartPlaylist({
    required String trackListJson,
    required String userQuery,
  }) async {
    final apiKeys = await getApiKeys();
    if (apiKeys.isEmpty) return "API Key missing.";

    final prompt = """
Anda adalah Kurator Musik Profesional. Gunakan daftar lagu (Library) user di bawah ini untuk membuat playlist yang sesuai dengan permintaan user.

LIBRARY USER (JSON):
$trackListJson

PERMINTAAN USER:
"$userQuery"

TUGAS ANDA:
1. Analisis permintaan user (suasana hati, aktivitas, atau waktu).
2. Pilih maksimal 10 lagu dari LIBRARY USER yang paling cocok.
3. Jika tidak ada lagu yang benar-benar pas, pilih yang paling mendekati nuansanya.
4. Berikan respon dalam format JSON berikut:
{
  "playlist_name": "Nama Playlist Kreatif",
  "reason": "Alasan singkat kenapa lagu-lagu ini dipilih dalam Bahasa Indonesia",
  "tracks": [
    {"id": "track_id_1", "title": "Judul Lagu 1", "artist": "Artis 1"},
    ...
  ]
}

Hanya berikan JSON, tanpa teks tambahan. Jika tidak ada lagu sama sekali di library, kembalikan JSON dengan list tracks kosong.
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
    return "Gagal membuat playlist.";
  }

  Future<String> createYoutubeSmartPlaylist({
    required String userQuery,
  }) async {
    final apiKeys = await getApiKeys();
    if (apiKeys.isEmpty) return "API Key missing.";

    final prompt = """
Anda adalah Kurator Musik YouTube Music Profesional. Buatlah playlist yang sempurna berdasarkan permintaan user menggunakan pengetahuan luas Anda tentang musik dunia.

PERMINTAAN USER:
"$userQuery"

TUGAS ANDA:
1. Analisis permintaan user (suasana hati, aktivitas, atau waktu).
2. Pilih 7-10 lagu populer atau berkualitas yang tersedia di YouTube Music.
3. Berikan respon dalam format JSON berikut:
{
  "playlist_name": "Nama Playlist Kreatif",
  "reason": "Alasan singkat kenapa lagu-lagu ini dipilih dalam Bahasa Indonesia",
  "tracks": [
    {"title": "Judul Lagu 1", "artist": "Artis 1"},
    {"title": "Judul Lagu 2", "artist": "Artis 2"},
    ...
  ]
}

Hanya berikan JSON, tanpa teks tambahan.
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
    return "Gagal membuat playlist YouTube.";
  }

  Future<void> deleteApiKey(String key) async {
    await _secureStorage.deleteGeminiApiKey(key);
  }
}
