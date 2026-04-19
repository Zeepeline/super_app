import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String title;
  final Color color;
  final String imageUrl;

  const CategoryEntity({
    required this.id,
    required this.title,
    required this.color,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, title, color, imageUrl];
}
