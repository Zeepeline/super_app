import 'package:super_app/features/book_search/domain/entities/book_search_result.dart';

abstract class BookSearchRepository {
  Future<List<BookSearchResult>> searchBooks(String query);
}
