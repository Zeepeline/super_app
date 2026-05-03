import 'package:mobile_rag_engine/mobile_rag_engine.dart';

import '../../features/home/data/models/track_model.dart';

class RagIndexerService {
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileRag.initialize(
        tokenizerAsset: 'assets/rag/tokenizer.json',
        modelAsset: 'assets/rag/model.onnx',
        deferIndexWarmup: true,
      );

      // Wait for index to be ready
      if (!MobileRag.instance.isIndexReady) {
        await MobileRag.instance.warmupFuture;
      }

      _isInitialized = true;
      print("RagIndexerService: Initialized successfully");
    } catch (e) {
      print("RagIndexerService: Initialization failed: $e");
    }
  }

  /// Menghapus data lama dan melakukan re-index seluruh library.
  Future<void> reindexLibrary(List<TrackModel> tracks) async {
    await initialize();

    // mobile_rag_engine handles deduplication by ID,
    // but for a clean state we can rebuild.
    // Note: If the package supports clear(), use it.

    for (final track in tracks) {
      await indexTrack(track);
    }

    await MobileRag.instance.rebuildIndex();
  }

  Future<void> indexTrack(TrackModel track) async {
    await initialize();

    final content = _buildSearchableContent(track);

    try {
      // mobile_rag_engine 0.17.0 facade does not take metadata directly in addDocument.
      // We prepend important metadata to the content to make it searchable.
      final augmentedContent = "[ID: ${track.idField}] $content";
      await MobileRag.instance.addDocument(augmentedContent);
      print("RagIndexerService: Indexed track ${track.titleField}");
    } catch (e) {
      print("RagIndexerService: Failed to index track ${track.titleField}: $e");
    }
  }

  /// Menyimpan hasil pencarian API luar ke dalam RAG (Semantic Caching).
  Future<void> indexExternalData(
    String content,
    Map<String, dynamic> metadata,
  ) async {
    await initialize();
    try {
      // Prepend metadata as searchable context
      final metadataStr = metadata.entries
          .map((e) => "${e.key}: ${e.value}")
          .join(", ");
      final augmentedContent = "[$metadataStr] $content";
      await MobileRag.instance.addDocument(augmentedContent);
    } catch (e) {
      print("RagIndexerService: Failed to index external data: $e");
    }
  }

  String _buildSearchableContent(TrackModel track) {
    final buffer = StringBuffer();
    buffer.write("Title: ${track.titleField}. ");
    buffer.write("Artist: ${track.artistField}. ");
    buffer.write("Album: ${track.albumField}. ");
    if (track.plainLyricsField != null && track.plainLyricsField!.isNotEmpty) {
      buffer.write("Lyrics: ${track.plainLyricsField}");
    }
    return buffer.toString();
  }
}
