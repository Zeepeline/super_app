import 'package:mobile_rag_engine/mobile_rag_engine.dart';
import 'package:super_app/features/home/data/models/track_model.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';

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

  Future<void> indexTrack(TrackModel track) async {
    await initialize();
    if (!_isInitialized) return;

    final content = _buildSearchableContent(track);

    try {
      final augmentedContent = "[TRACK_ID: ${track.idField}] $content";
      await MobileRag.instance.addDocument(augmentedContent);
      print("RagIndexerService: Indexed track ${track.titleField}");
    } catch (e) {
      print("RagIndexerService: Failed to index track ${track.titleField}: $e");
    }
  }

  Future<void> indexBook(LocalBook book) async {
    await initialize();
    if (!_isInitialized) return;

    final content = _buildSearchableBookContent(book);

    try {
      final augmentedContent = "[BOOK_ID: ${book.id}] $content";
      await MobileRag.instance.addDocument(augmentedContent);
      print("RagIndexerService: Indexed book ${book.title}");
    } catch (e) {
      print("RagIndexerService: Failed to index book ${book.title}: $e");
    }
  }

  /// Menghapus data lama dan melakukan re-index seluruh library (Musik & Buku).
  Future<void> reindexLibrary({
    List<TrackModel>? tracks,
    List<LocalBook>? books,
  }) async {
    await initialize();

    if (tracks != null) {
      for (final track in tracks) {
        await indexTrack(track);
      }
    }

    if (books != null) {
      for (final book in books) {
        await indexBook(book);
      }
    }

    if (_isInitialized) {
      try {
        await MobileRag.instance.rebuildIndex();
      } catch (e) {
        print("RagIndexerService: Failed to rebuild index: $e");
      }
    }
  }

  /// Menyimpan hasil pencarian API luar ke dalam RAG (Semantic Caching).
  Future<void> indexExternalData(
    String content,
    Map<String, dynamic> metadata,
  ) async {
    await initialize();
    if (!_isInitialized) return;
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

  String _buildSearchableBookContent(LocalBook book) {
    final buffer = StringBuffer();
    buffer.write("Book Title: ${book.title}. ");
    buffer.write("Author: ${book.author}. ");
    if (book.synopsis != null) {
      buffer.write("Synopsis: ${book.synopsis}. ");
    }
    if (book.genreTags != null && book.genreTags!.isNotEmpty) {
      buffer.write("Genres: ${book.genreTags!.join(', ')}. ");
    }
    return buffer.toString();
  }
}
