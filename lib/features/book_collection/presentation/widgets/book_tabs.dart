import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';

class BookTabs extends StatelessWidget {
  final List<String> tabs;
  final String selectedTab;

  const BookTabs({super.key, required this.tabs, this.selectedTab = 'All'});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab == selectedTab;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.kPrimaryColor
                  : AppTheme.kSurfaceContainerLowColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tab,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
