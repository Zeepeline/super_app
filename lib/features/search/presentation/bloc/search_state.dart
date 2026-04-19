import 'package:equatable/equatable.dart';
import '../../domain/entities/category_entity.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<CategoryEntity> categories;

  const SearchLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object> get props => [message];
}
