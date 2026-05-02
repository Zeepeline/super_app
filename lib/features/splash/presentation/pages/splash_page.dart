import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashPage({super.key, required this.onFinish});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Start timer to finish splash
    Timer(const Duration(milliseconds: 3500), () {
      widget.onFinish();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: Stack(
        children: [
          // Ambient Depth Blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.kPrimaryColor.withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  AppTheme.kPrimaryColor.withOpacity(0.05),
                  BlendMode.srcATop,
                ),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.kPrimaryContainerColor.withOpacity(0.05),
              ),
            ),
          ),

          // Central Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with Neon Glow
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Glow
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.kPrimaryColor.withOpacity(0.2),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Main Icon
                      Container(
                        width: 200,
                        height: 200,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.kPrimaryColor.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: ClipOval(
                          child: Container(
                            color: AppTheme.kSurfaceContainerHighestColor,
                            child: Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuClOfx-j1s8OMCuVfnppzYVjJgjDks9rzuLZ9hM-TC-Q0MnIF0wh9THq8V93K8Zdc5JdXiTMXEe7q42s09qRE4o9Dik21dsTozbvC461AEtsH8uf4V6yBh4lAP4hyV_ufPbMsXFFh2CjXJ5oF1fnM6LFWDPAG95BLm1Q2WIXEJruYCTSJlDL7Q5Jd1Npizm4eemidBPPPUPd3VvFcRaoYB-AEA4r-FV2qHpq8lWymOa0wNDY97KnwRPkCwMTCPa9yr7Tti3lBinn7Y',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.music_note,
                                  color: AppTheme.kPrimaryColor,
                                  size: 80,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Brand Typography
                Center(
                  child: Text(
                    'OBSIDIAN RHYTHM',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.kOnBackgroundColor,
                      letterSpacing: 8.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'THE DIGITAL CURATOR',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.kOnSurfaceVariantColor,
                    letterSpacing: 4.0,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Version Anchor
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 1,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.kPrimaryColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'v1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.kOnSurfaceVariantColor.withOpacity(0.5),
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
