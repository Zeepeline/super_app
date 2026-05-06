import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

class UserMemoryService {
  static const String memoryBoxName = 'user_memory_structured_box';
  late Box<String> _memoryBox;

  Future<void> initialize() async {
    _memoryBox = await Hive.openBox<String>(memoryBoxName);
  }

  /// Menyimpan fakta secara terstruktur: { "subject": "user", "predicate": "likes", "object": "jazz" }
  /// Ini lebih efisien untuk pencarian dan kompresi data.
  Future<void> saveFact({
    required String subject,
    required String predicate,
    required String object,
  }) async {
    final factId = "${subject.toLowerCase()}_${predicate.toLowerCase()}";
    final data = {
      "s": subject,
      "p": predicate,
      "o": object,
      "t": DateTime.now().millisecondsSinceEpoch,
    };

    // Simpan/Overwrite fakta yang sama (misal: "favorite_genre" di-update)
    await _memoryBox.put(factId, jsonEncode(data));
    log("UserMemory: Fact saved/updated: $factId -> $object");
  }

  /// Mengambil semua memori dalam format string yang compact untuk AI.
  String getCompactMemory() {
    if (_memoryBox.isEmpty) return "Belum ada memori tersimpan.";

    final facts = _memoryBox.values.map((v) {
      final data = jsonDecode(v);
      return "${data['s']} ${data['p']} ${data['o']}";
    }).toList();

    return facts.join(". ");
  }

  /// Mencari fakta spesifik berdasarkan subjek atau predikat.
  String? getFact(String subject, String predicate) {
    final factId = "${subject.toLowerCase()}_${predicate.toLowerCase()}";
    final val = _memoryBox.get(factId);
    if (val == null) return null;
    return jsonDecode(val)['o'];
  }

  /// Mencari fakta yang relevan (Simple Semantic-ish search).
  List<String> findRelevantFacts(String query) {
    final keywords = query.toLowerCase().split(' ');
    return _memoryBox.values
        .where((v) {
          final data = jsonDecode(v);
          final factStr = "${data['s']} ${data['p']} ${data['o']}"
              .toLowerCase();
          return keywords.any((kw) => kw.length > 3 && factStr.contains(kw));
        })
        .map((v) {
          final data = jsonDecode(v);
          return "${data['s']} ${data['p']} ${data['o']}";
        })
        .toList();
  }

  /// Graph-based Search: Mencari semua fakta yang terhubung dengan entitas tertentu.
  List<String> findRelatedFacts(List<String> entities) {
    if (entities.isEmpty) return [];

    final results = <String>{};
    for (var entity in entities) {
      final normalizedEntity = entity.toLowerCase();
      for (var v in _memoryBox.values) {
        final data = jsonDecode(v);
        if (data['s'].toString().toLowerCase().contains(normalizedEntity) ||
            data['o'].toString().toLowerCase().contains(normalizedEntity)) {
          results.add("${data['s']} ${data['p']} ${data['o']}");
        }
      }
    }
    return results.toList();
  }

  Future<void> clearAll() async {
    await _memoryBox.clear();
  }
}
