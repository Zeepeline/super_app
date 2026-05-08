import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/book_search_result.dart';
import '../../domain/repositories/book_search_repository.dart';

// Events
abstract class BookSearchEvent {}

class PerformBookSearch extends BookSearchEvent {
  final String query;
  PerformBookSearch(this.query);
}

// States
abstract class BookSearchState {}

class BookSearchInitial extends BookSearchState {}

class BookSearchLoading extends BookSearchState {}

class BookSearchLoaded extends BookSearchState {
  final List<BookSearchResult> results;
  BookSearchLoaded(this.results);
}

class BookSearchError extends BookSearchState {
  final String message;
  BookSearchError(this.message);
}

// Bloc
class BookSearchBloc extends Bloc<BookSearchEvent, BookSearchState> {
  final BookSearchRepository repository;

  BookSearchBloc(this.repository) : super(BookSearchInitial()) {
    on<PerformBookSearch>((event, emit) async {
      if (event.query.isEmpty) {
        emit(BookSearchInitial());
        return;
      }

      emit(BookSearchLoading());
      try {
        final results = await repository.searchBooks(event.query);
        emit(BookSearchLoaded(results));
      } catch (e) {
        emit(BookSearchError(e.toString()));
      }
    });
  }
}
