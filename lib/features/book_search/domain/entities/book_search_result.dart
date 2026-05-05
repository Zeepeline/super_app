class BookSearchResult {
  final String source;
  final String id;
  final String title;
  final String author;
  final String format;
  final String? size;
  final String? publisher;
  final String? year;
  final String? mirror;
  final String? coverUrl;

  BookSearchResult({
    required this.source,
    required this.id,
    required this.title,
    required this.author,
    required this.format,
    this.size,
    this.publisher,
    this.year,
    this.mirror,
    this.coverUrl,
  });
}
