import 'package:super_app/features/book_search/domain/entities/book_search_result.dart';

class BookSearchResultModel extends BookSearchResult {
  BookSearchResultModel({
    required super.source,
    required super.id,
    required super.title,
    required super.author,
    required super.format,
    super.size,
    super.publisher,
    super.year,
    super.mirror,
    super.coverUrl,
  });

  factory BookSearchResultModel.fromJson(Map<String, dynamic> json) {
    return BookSearchResultModel(
      source: json['source'] ?? 'Unknown',
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      format: json['format'] ?? 'Unknown',
      size: json['size'],
      publisher: json['publisher'],
      year: json['year']?.toString(),
      mirror: json['mirror'],
      coverUrl: json['cover_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'id': id,
      'title': title,
      'author': author,
      'format': format,
      'size': size,
      'publisher': publisher,
      'year': year,
      'mirror': mirror,
      'cover_url': coverUrl,
    };
  }
}
