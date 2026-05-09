import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';

class VinylRecord extends StatefulWidget {
  final String albumArtUrl;
  final bool isPlaying;

  const VinylRecord({
    super.key,
    required this.albumArtUrl,
    required this.isPlaying,
  });

  @override
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(VinylRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow behind the vinyl
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: widget.isPlaying
                      ? [
                          BoxShadow(
                            color: AppTheme.kPrimaryColor.withValues(alpha: 0.15 +
                                  0.15 *
                                      math.sin(
                                        _rotationController.value * 2 * math.pi,),
                            ),
                            blurRadius:
                                30 +
                                10 *
                                    math.sin(
                                      _rotationController.value * 2 * math.pi,
                                    ),
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
              );
            },
          ),

          // Rotating vinyl disc
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: child,
              );
            },
            child: FractionallySizedBox(
              widthFactor: 0.95,
              heightFactor: 0.95,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _VinylPainter(),
                  child: Center(
                    // Center album art label (38% of vinyl)
                    child: FractionallySizedBox(
                      widthFactor: 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF111111),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: -3,
                            ),
                          ],
                        ),
                        child: CachedNetworkImage(
                          imageUrl: widget.albumArtUrl,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.kSurfaceContainerLowColor,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.music_note,
                                color: AppTheme.kPrimaryColor.withOpacity(0.3),
                                size: 32,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.kSurfaceContainerHighestColor,
                                  AppTheme.kBackgroundColor,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.music_note,
                                color: AppTheme.kPrimaryColor.withOpacity(0.4),
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Center spindle hole
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.kBackgroundColor,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Base black disc
    final basePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, basePaint);

    // Groove lines (repeating concentric rings)
    final grooveDarkPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final grooveLightPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw vinyl grooves from ~22% to ~90% radius
    final innerLimit = radius * 0.22;
    final outerLimit = radius * 0.92;
    for (double r = innerLimit; r < outerLimit; r += 3.0) {
      final paint = (r.toInt() % 2 == 0) ? grooveDarkPaint : grooveLightPaint;
      canvas.drawCircle(center, r, paint);
    }

    // Subtle light reflections on the grooves
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double r = radius * 0.35; r < radius * 0.85; r += 12) {
      canvas.drawCircle(center, r, highlightPaint);
    }

    // Radial gradient overlay for depth
    final overlayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.02),
          Colors.transparent,
          Colors.white.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.45, 0.55, 0.65],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
