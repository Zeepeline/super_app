import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_categories.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final GetCategories getCategories;

  SearchBloc({required this.getCategories}) : super(SearchInitial()) {
    on<LoadSearchPageEvent>((event, emit) async {
      emit(SearchLoading());
      final categoriesEither = await getCategories(NoParams());

      categoriesEither.fold(
        (failure) => emit(SearchError(failure.message)),
        (categories) => emit(SearchLoaded(categories)),
      );
    });
  }
}
