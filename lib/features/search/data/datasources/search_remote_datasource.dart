import 'package:flutter/material.dart';
import '../models/category_model.dart';

abstract class SearchRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
}

class MockSearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      const CategoryModel(
        id: 'c1',
        title: 'Electronic',
        color: Color(0xFFE91E63),
        imageUrl:
            'https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&q=80&w=150',
      ),
      const CategoryModel(
        id: 'c2',
        title: 'Indie Rock',
        color: Color(0xFF2196F3),
        imageUrl:
            'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?auto=format&fit=crop&q=80&w=150',
      ),
      const CategoryModel(
        id: 'c3',
        title: 'Lo-Fi',
        color: Color(0xFFFF9800),
        imageUrl:
            'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&q=80&w=150',
      ),
      const CategoryModel(
        id: 'c4',
        title: 'Jazz Noir',
        color: Color(0xFF673AB7),
        imageUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&q=80&w=150',
      ),
    ];
  }
}
