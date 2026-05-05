import '../../domain/entities/book_search_result.dart';
import '../../domain/repositories/book_search_repository.dart';
import '../datasources/book_remote_datasource.dart';

class BookSearchRepositoryImpl implements BookSearchRepository {
  final BookRemoteDataSource remoteDataSource;

  BookSearchRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<BookSearchResult>> searchBooks(String query) async {
    return await remoteDataSource.searchBooks(query);
  }
}
