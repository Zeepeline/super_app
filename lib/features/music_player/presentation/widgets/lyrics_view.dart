import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/features/music_player/presentation/controllers/player_ui_controller.dart';

class LyricsView extends StatefulWidget {
  final String? syncedLyrics;
  final String? plainLyrics;

  const LyricsView({super.key, this.syncedLyrics, this.plainLyrics});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final PlayerUIController controller = Get.find<PlayerUIController>();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  StreamSubscription<Duration>? _positionSubscription;
  int _activeIndex = -1;

  @override
  void initState() {
    super.initState();
    // Update lyrics in controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateLyrics(widget.syncedLyrics);
      _listenToPosition();
    });
  }

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.syncedLyrics != oldWidget.syncedLyrics) {
      controller.updateLyrics(widget.syncedLyrics);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenToPosition() {
    _positionSubscription = controller.positionStream.listen((position) {
      if (controller.lyrics.isEmpty) return;

      final index = _findActiveIndex(position);
      if (index != _activeIndex) {
        setState(() {
          _activeIndex = index;
        });
        if (_activeIndex != -1) {
          _scrollToCurrent(_activeIndex);
        }
      }
    });
  }

  int _findActiveIndex(Duration position) {
    if (controller.lyrics.isEmpty) return -1;

    // Binary search for O(log n) efficiency
    int low = 0;
    int high = controller.lyrics.length - 1;
    int index = -1;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (controller.lyrics[mid].startTime <= position) {
        index = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return index;
  }

  void _scrollToCurrent(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[index];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          alignment: 0.15,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = screenHeight * 0.15;

    return Obx(() {
      if (controller.lyrics.isNotEmpty) {
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(top: topPadding, bottom: screenHeight * 0.7),
          itemCount: controller.lyrics.length,
          itemBuilder: (context, index) {
            final lyric = controller.lyrics[index];
            final isActive = index == _activeIndex;

            _itemKeys[index] ??= GlobalKey();

            return AnimatedContainer(
              key: _itemKeys[index],
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
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
      }

      if (widget.plainLyrics != null && widget.plainLyrics!.isNotEmpty) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Text(
            widget.plainLyrics!,
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
