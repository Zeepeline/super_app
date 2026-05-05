import 'dart:convert';

import 'package:super_app/core/services/book_library_service.dart';
import 'package:super_app/core/services/gemini_service.dart';

import '../../features/book_search/domain/entities/book_search_result.dart';
import '../../features/book_search/domain/repositories/book_search_repository.dart';

class BookStoreService {
  final BookLibraryService _libraryService;
  final GeminiService _geminiService;
  final BookSearchRepository _searchRepository;

  BookStoreService(
    this._libraryService,
    this._geminiService,
    this._searchRepository,
  );

  Future<List<BookRecommendation>> getAiRecommendations() async {
    try {
      final localBooks = await _libraryService.getDownloadedBooks();
      if (localBooks.isEmpty) {
        return _getDefaultRecommendations();
      }

      final bookList = localBooks
          .take(5)
          .map((b) => "${b.title} by ${b.author}")
          .join(", ");

      final prompt =
          """
      You are a world-class librarian. Based on these books the user is reading: $bookList,
      recommend 5 other famous books they might enjoy.
      Return the response ONLY as a JSON list of objects with these keys: "title", "author", "genre", "reason".
      Example: [{"title": "1984", "author": "George Orwell", "genre": "Dystopian", "reason": "Because you like political thrillers."}]
      """;

      final response = await _geminiService.getChatResponse(prompt);

      // Basic JSON extraction from markdown
      String jsonStr = response;
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0];
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0];
      }

      final List<dynamic> data = jsonDecode(jsonStr);
      return data.map((item) => BookRecommendation.fromJson(item)).toList();
    } catch (e) {
      print("Error getting AI recommendations: $e");
      return _getDefaultRecommendations();
    }
  }

  Future<List<BookSearchResult>> getBooksByGenre(String genre) async {
    // We can use the existing search repository but pass the genre as query
    // Or we could extend the repository for specific genre searching
    return _searchRepository.searchBooks(genre);
  }

  List<BookRecommendation> _getDefaultRecommendations() {
    return [
      BookRecommendation(
        title: "Digital Minimalism",
        author: "Cal Newport",
        genre: "Self-Help",
        reason: "A must-read for better focus in the digital age.",
      ),
      BookRecommendation(
        title: "Atomic Habits",
        author: "James Clear",
        genre: "Psychology",
        reason: "The definitive guide to building good habits.",
      ),
      BookRecommendation(
        title: "Sapiens",
        author: "Yuval Noah Harari",
        genre: "History",
        reason: "Explores the history and future of humanity.",
      ),
    ];
  }
}

class BookRecommendation {
  final String title;
  final String author;
  final String genre;
  final String reason;

  BookRecommendation({
    required this.title,
    required this.author,
    required this.genre,
    required this.reason,
  });

  factory BookRecommendation.fromJson(Map<String, dynamic> json) {
    return BookRecommendation(
      title: json['title'] ?? 'Unknown',
      author: json['author'] ?? 'Unknown',
      genre: json['genre'] ?? 'General',
      reason: json['reason'] ?? '',
    );
  }
}
