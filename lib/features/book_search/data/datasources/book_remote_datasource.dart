import 'package:dio/dio.dart';
import 'package:super_app/core/services/python_worker_service.dart';
import 'package:super_app/injection_container.dart';
import '../models/book_search_result_model.dart';

abstract class BookRemoteDataSource {
  Future<List<BookSearchResultModel>> searchBooks(String query);
}

class BookRemoteDataSourceImpl implements BookRemoteDataSource {
  final Dio dio;

  BookRemoteDataSourceImpl(this.dio);

  @override
  Future<List<BookSearchResultModel>> searchBooks(String query) async {
    final workerService = sl<PythonWorkerService>();
    
    if (!workerService.isReady) {
      // Small attempt to init if not ready, but mostly relies on main() init
      await workerService.initWorker();
    }

    final port = workerService.workerPort;
    if (port == null) {
      throw Exception("Python Worker is starting up. Please wait a few seconds and try again.");
    }

    try {
      final response = await dio.post(
        'http://127.0.0.1:$port/books/search',
        data: {'query': query},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List results = response.data['results'];
        return results.map((json) => BookSearchResultModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to search books: ${response.statusMessage}");
      }
    } catch (e) {
      throw Exception("Error communicating with Python Worker: $e");
    }
  }
}
