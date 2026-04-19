import 'dart:io';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/injection_container.dart';

class LiveActivityIsland extends StatelessWidget {
  final RxBool _isExpanded = false.obs;
  final AudioHandler _audioHandler = sl<AudioHandler>();

  LiveActivityIsland({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: _audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return StreamBuilder<PlaybackState>(
          stream: _audioHandler.playbackState,
          builder: (context, playbackSnapshot) {
            final playbackState = playbackSnapshot.data;
            final isPlaying = playbackState?.playing ?? false;

            // Only show if media is loaded
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _isExpanded.value = !_isExpanded.value,
                    child: Obx(
                      () => AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        width: _isExpanded.value ? 340 : 200,
                        height: _isExpanded.value ? 84 : 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(
                            _isExpanded.value ? 28 : 20,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.kPrimaryColor.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: -5,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            _isExpanded.value ? 28 : 20,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _isExpanded.value
                                    ? _buildExpanded(mediaItem, isPlaying)
                                    : _buildCollapsed(mediaItem, isPlaying),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  ImageProvider _getArtImageProvider(Uri uri) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return NetworkImage(uri.toString());
    }
    return FileImage(File(uri.toFilePath()));
  }

  Widget _buildArtImage(Uri uri, double width, double height) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return Image.network(
        uri.toString(),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(uri.toFilePath()),
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Widget _buildCollapsed(MediaItem mediaItem, bool isPlaying) {
    return Row(
      key: const ValueKey('collapsed'),
      children: [
        // Album art circle
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: mediaItem.artUri != null
                ? DecorationImage(
                    image: _getArtImageProvider(mediaItem.artUri!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: mediaItem.artUri == null
              ? const Icon(
                  Icons.music_note,
                  size: 14,
                  color: AppTheme.kPrimaryColor,
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mediaItem.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildWaveform(isPlaying),
      ],
    );
  }

  Widget _buildExpanded(MediaItem mediaItem, bool isPlaying) {
    return Column(
      key: const ValueKey('expanded'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: mediaItem.artUri != null
                  ? _buildArtImage(mediaItem.artUri!, 52, 52)
                  : Container(
                      width: 52,
                      height: 52,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(
                        Icons.music_note,
                        color: AppTheme.kPrimaryColor,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mediaItem.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  Text(
                    mediaItem.artist ?? 'Unknown Artist',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                if (isPlaying) {
                  _audioHandler.pause();
                } else {
                  _audioHandler.play();
                }
              },
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppTheme.kPrimaryColor,
                size: 32,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildProgressBar(mediaItem.duration),
      ],
    );
  }

  Widget _buildProgressBar(Duration? totalDuration) {
    if (totalDuration == null) return const SizedBox.shrink();

    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final progress = totalDuration.inMilliseconds > 0
            ? position.inMilliseconds / totalDuration.inMilliseconds
            : 0.0;

        return Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kPrimaryColor, Color(0xFF00E5FF)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kPrimaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaveform(bool isPlaying) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return _WaveformBar(index: index, isPlaying: isPlaying);
      }),
    );
  }
}

class _WaveformBar extends StatefulWidget {
  final int index;
  final bool isPlaying;

  const _WaveformBar({required this.index, required this.isPlaying});

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_WaveformBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 3,
          height: 6 + (10 * _controller.value),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: AppTheme.kPrimaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
