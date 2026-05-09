import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/core/widgets/live_activity_island.dart';
import 'package:super_app/features/ai_assistant/presentation/pages/ai_chat_page.dart';
import 'package:super_app/features/home/presentation/pages/home_page.dart';
import 'package:super_app/features/library/presentation/pages/library_page.dart';
import 'package:super_app/features/search/presentation/pages/search_page.dart';
import 'package:super_app/features/settings/presentation/pages/settings_page.dart';
import 'package:super_app/features/youtube/presentation/pages/youtube_page.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  static final RxInt _currentIndex = 0.obs;

  static final List<Widget> _pages = [
    const YouTubePage(),
    const HomePage(),
    const SearchPage(),
    const LibraryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AiChatPage()),
            );
          },
          backgroundColor: AppTheme.kPrimaryColor,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.chat, color: Colors.black, size: 30),
        ),
      ),
      body: Stack(
        children: [
          Obx(() => IndexedStack(index: _currentIndex.value, children: _pages)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildBottomNavigationBar()],
            ),
          ),
          const Positioned(top: 0, left: 10, child: LiveActivityIsland()),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundColor.withOpacity(0.4),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Obx(
            () => BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex.value,
              onTap: (index) => _currentIndex.value = index,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.music_note_outlined),
                  activeIcon: Icon(
                    Icons.music_note,
                    color: AppTheme.kPrimaryColor,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(
                    Icons.dashboard,
                    color: AppTheme.kPrimaryColor,
                  ),
                  label: 'Discover',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search, color: AppTheme.kPrimaryColor),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(
                    Icons.library_music,
                    color: AppTheme.kPrimaryColor,
                  ),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(
                    Icons.settings,
                    color: AppTheme.kPrimaryColor,
                  ),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
