import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
}
