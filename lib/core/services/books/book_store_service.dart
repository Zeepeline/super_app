import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/services/ai/gemini_service.dart';
import 'package:super_app/core/services/books/book_library_service.dart';
import 'package:super_app/features/book_search/domain/entities/book_search_result.dart';
import 'package:super_app/features/book_search/domain/repositories/book_search_repository.dart';

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
      Return the response ONLY as a JSON list of objects with these keys: "title", "author", "genre", "reason", "coverUrl".
      For "coverUrl", use a direct image URL of the book cover if possible (e.g., from OpenLibrary or Google Books), 
      otherwise use a high-quality Unsplash image URL related to the book's theme.
      Example: [{"title": "1984", "author": "George Orwell", "genre": "Dystopian", "reason": "Because you like political thrillers.", "coverUrl": "https://images.unsplash.com/photo-1541963463532-d68292c34b19?q=80&w=400"}]
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
      debugPrint("Error getting AI recommendations: $e");
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
        coverUrl:
            "https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=400",
      ),
      BookRecommendation(
        title: "Atomic Habits",
        author: "James Clear",
        genre: "Psychology",
        reason: "The definitive guide to building good habits.",
        coverUrl:
            "https://images.unsplash.com/photo-1589998059171-988d887df646?q=80&w=400",
      ),
      BookRecommendation(
        title: "Sapiens",
        author: "Yuval Noah Harari",
        genre: "History",
        reason: "Explores the history and future of humanity.",
        coverUrl:
            "https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=400",
      ),
    ];
  }

  Future<Map<String, dynamic>> getBookMetadata(
    String title,
    String author,
  ) async {
    try {
      final prompt =
          """
      You are a book metadata expert. Provide details for the book "$title" by "$author".
      Return the response ONLY as a JSON object with these keys: "synopsis", "genreTags" (list), "publishDate".
      If you don't know the exact book, provide a likely professional description based on the title/author.
      Example: {"synopsis": "...", "genreTags": ["Fiction", "History"], "publishDate": "2020"}
      """;

      final response = await _geminiService.getChatResponse(prompt);

      String jsonStr = response;
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0];
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0];
      }

      return jsonDecode(jsonStr);
    } catch (e) {
      debugPrint("Error getting book metadata: $e");
      return {
        "synopsis": "No description available for this local file.",
        "genreTags": ["LOCAL"],
        "publishDate": "Unknown",
      };
    }
  }

  Future<List<BookRecommendation>> getSimilarBooks(
    String title,
    String author,
  ) async {
    try {
      final prompt =
          """
      You are a world-class librarian. Recommend 3 books similar to "$title" by "$author".
      Return the response ONLY as a JSON list of objects with these keys: "title", "author", "genre", "reason", "coverUrl".
      For "coverUrl", use a direct image URL of the book cover or a high-quality relevant Unsplash image.
      """;

      final response = await _geminiService.getChatResponse(prompt);

      String jsonStr = response;
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0];
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0];
      }

      final List<dynamic> data = jsonDecode(jsonStr);
      return data.map((item) => BookRecommendation.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Error getting similar books: $e");
      return _getDefaultRecommendations().take(2).toList();
    }
  }

  Future<List<BookRecommendation>> getPopularBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final cachedDate = prefs.getString('popular_books_date');
      final cachedData = prefs.getString('popular_books_data');

      if (cachedDate == today && cachedData != null) {
        final List<dynamic> data = jsonDecode(cachedData);
        return data.map((item) => BookRecommendation.fromJson(item)).toList();
      }

      const prompt = """
      You are a world-class librarian. List 5 of the most popular and trending books released in 2024 or 2025.
      Return the response ONLY as a JSON list of objects with these keys: "title", "author", "genre", "reason", "coverUrl".
      For "coverUrl", provide a direct image URL of the book cover (e.g. from OpenLibrary) or a very high quality Unsplash image related to the theme.
      """;

      final response = await _geminiService.getChatResponse(prompt);

      String jsonStr = response;
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0];
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0];
      }

      // Save to cache
      await prefs.setString('popular_books_date', today);
      await prefs.setString('popular_books_data', jsonStr);

      final List<dynamic> data = jsonDecode(jsonStr);
      return data.map((item) => BookRecommendation.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Error getting popular books: $e");
      return _getDefaultRecommendations();
    }
  }
}

class BookRecommendation {
  final String title;
  final String author;
  final String genre;
  final String reason;
  final String? coverUrl;

  BookRecommendation({
    required this.title,
    required this.author,
    required this.genre,
    required this.reason,
    this.coverUrl,
  });

  factory BookRecommendation.fromJson(Map<String, dynamic> json) {
    return BookRecommendation(
      title: json['title'] ?? 'Unknown',
      author: json['author'] ?? 'Unknown',
      genre: json['genre'] ?? 'General',
      reason: json['reason'] ?? '',
      coverUrl: json['coverUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'genre': genre,
    'reason': reason,
    'coverUrl': coverUrl,
  };
}
