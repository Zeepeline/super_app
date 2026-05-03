import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService() : _storage = const FlutterSecureStorage();

  static const String _geminiApiKeysList = 'gemini_api_keys_list';

  Future<void> addGeminiApiKey(String key) async {
    final currentKeys = await getGeminiApiKeys();
    if (!currentKeys.contains(key)) {
      currentKeys.add(key);
      await _storage.write(
        key: _geminiApiKeysList,
        value: currentKeys.join(','),
      );
    }
  }

  Future<List<String>> getGeminiApiKeys() async {
    final value = await _storage.read(key: _geminiApiKeysList);
    if (value == null || value.isEmpty) return [];
    return value.split(',');
  }

  Future<void> deleteGeminiApiKey(String key) async {
    final currentKeys = await getGeminiApiKeys();
    currentKeys.remove(key);
    await _storage.write(key: _geminiApiKeysList, value: currentKeys.join(','));
  }

  // Legacy support for single key if needed, or we can just redirect to list
  Future<String?> getGeminiApiKey() async {
    final keys = await getGeminiApiKeys();
    return keys.isNotEmpty ? keys.first : null;
  }

  Future<void> saveGeminiApiKey(String key) => addGeminiApiKey(key);
}
