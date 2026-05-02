import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  final VoidCallback onFinish;

  const OnboardingPage({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: Stack(
        children: [
          // Background Image with Rotation and Gradients
          Positioned.fill(
            child: Stack(
              children: [
                Positioned(
                  right: -100,
                  top: -50,
                  bottom: -50,
                  width: MediaQuery.of(context).size.width * 1.5,
                  child: Transform.rotate(
                    angle: -0.05, // Subtle rotation from design
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuABikIIDCwQJ8hrj_QF1BKJZCCCKhnQnHb4NRsfwgN2HFx-c3SsiHTspzRRaMlmw3T2yekHvrbtVdqE8ZbRgfddICy7cHWU7AkeneS_uvb5Rq6eZq1F3QLZFKUME3X2FyJuXx0ITnsTIiMtr7YrCVXpnOUnw4VxmgPCUMjMxjUL2Zp9IjdXiIokUGGR3gC9bR-A2ez26Q5Ni-JEFfo_qp_nRvZ1f0k8tpx6c20RCXNzVrxH9uIOt7hz_JMze47PJu7b3WY7kVtxIWM',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Layered Gradients for Tonal Depth
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.kBackgroundColor.withValues(alpha: 0.6),
                          AppTheme.kBackgroundColor,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [AppTheme.kBackgroundColor, Colors.transparent],
                        stops: [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Header Logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 64,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.graphic_eq,
                      color: AppTheme.kPrimaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SONIC CURATOR',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: AppTheme.kPrimaryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content Canvas
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  // Badge Cluster
                  _buildLiveBadge(context),
                  const SizedBox(height: 24),
                  // Headline Cluster
                  _buildHeadline(context),
                  const SizedBox(height: 48),
                  // CTA Section
                  _buildCTA(context),
                  const SizedBox(height: 64),
                  // Scroll Indicator
                  Center(
                    child: Container(
                      width: 1,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppTheme.kPrimaryColor, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'NOW LIVE: OBSIDIAN RHYTHM',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.kPrimaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 56,
              height: 0.95,
              fontWeight: FontWeight.w800,
              letterSpacing: -2.0,
            ),
            children: [
              const TextSpan(text: 'Your music,\n'),
              TextSpan(
                text: 'curated',
                style: AppTheme.curatedStyle.copyWith(
                  fontSize: 88,
                  height: 0.8,
                ),
              ),
              const TextSpan(text: ' for\nyour soul'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Experience sound like never before with personalized playlists and high-fidelity streaming.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.kOnSurfaceVariantColor,
            fontSize: 18,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onFinish,
          child: Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.kPrimaryColor,
                  AppTheme.kPrimaryContainerColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kPrimaryColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'Get Started',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onFinish,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ALREADY A CURATOR? ',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.kOnSurfaceVariantColor,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'Log In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.kPrimaryColor,
                  decorationThickness: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
