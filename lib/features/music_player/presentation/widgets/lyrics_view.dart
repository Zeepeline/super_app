import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/features/music_player/domain/models/lyric_line.dart';
import 'package:super_app/features/music_player/presentation/controllers/player_ui_controller.dart';

class LyricsView extends StatelessWidget {
  final String? syncedLyrics;
  final String? plainLyrics;
  final PlayerUIController controller = Get.find<PlayerUIController>();
  final ScrollController _scrollController = ScrollController();
  
  // Use a map to store keys for each lyric line
  final Map<int, GlobalKey> _itemKeys = {};

  LyricsView({super.key, this.syncedLyrics, this.plainLyrics});

  void _scrollToCurrent(int index) {
    final key = _itemKeys[index];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        alignment: 0.15, // Keep active lyric at 15% from the top
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = screenHeight * 0.15;

    // Update lyrics in controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateLyrics(syncedLyrics);
    });

    return Obx(() {
      if (controller.lyrics.isNotEmpty) {
        return StreamBuilder<Duration>(
          stream: controller.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;

            // Find active index
            int activeIndex = -1;
            for (int i = 0; i < controller.lyrics.length; i++) {
              if (position >= controller.lyrics[i].startTime) {
                activeIndex = i;
              } else {
                break;
              }
            }

            // Trigger scroll with centering
            if (activeIndex != -1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToCurrent(activeIndex);
              });
            }

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(top: topPadding, bottom: screenHeight * 0.7),
              itemCount: controller.lyrics.length,
              itemBuilder: (context, index) {
                final lyric = controller.lyrics[index];
                final isActive = index == activeIndex;

                // Create or reuse key for this index
                _itemKeys[index] ??= GlobalKey();

                return AnimatedContainer(
                  key: _itemKeys[index],
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    lyric.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isActive ? 26 : 20,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            );
          },
        );
      }

      if (plainLyrics != null && plainLyrics!.isNotEmpty) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Text(
            plainLyrics!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Lyrics not available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    });
  }
}
