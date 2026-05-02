import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/features/music_player/presentation/pages/music_player_page.dart';
import 'package:super_app/features/youtube/presentation/controllers/youtube_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class YouTubePage extends StatefulWidget {
  const YouTubePage({super.key});

  @override
  State<YouTubePage> createState() => _YouTubePageState();
}

class _YouTubePageState extends State<YouTubePage> {
  late final WebViewController _webController;
  bool _isLoading = true;
  bool _isInitialLoad = true;
  String? _lastPlayedId; // Avoid redundant play triggers

  @override
  void initState() {
    super.initState();

    // Special configuration for iOS to allow inline playback and prevent black screen fullscreen
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    // Get YouTubeController to use its play logic
    final ytController = Get.find<YouTubeController>();

    _webController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            final url = change.url;
            if (url != null && url.contains('watch?v=')) {
              final uri = Uri.parse(url);
              final videoId = uri.queryParameters['v'];
              if (videoId != null && videoId != _lastPlayedId) {
                _lastPlayedId = videoId;

                // 1. Mute and Pause the video in WebView immediately.
                _safeRunJavaScript('''
                  var media = document.querySelector("video");
                  if (media) {
                    media.muted = true;
                    media.pause();
                  }
                ''');

                // 2. Play natively via YouTubeController and PlayerCubit
                ytController.playFromYouTube(
                  videoId,
                  playerCubit: context.read<PlayerCubit>(),
                );

                // 3. Navigate to MusicPlayerPage for our own experience
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MusicPlayerPage(),
                  ),
                );
              }
            }
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            // Mitigate iOS null challenge crash by providing a handler
            debugPrint('Auth request for \${request.host}');
          },
          onPageStarted: (String url) {
            if (_isInitialLoad) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (_isInitialLoad) {
              setState(() {
                _isLoading = false;
                _isInitialLoad = false;
              });
            }
            // Force Dark Mode, Prevent Zooming, and Block Ads
            _safeRunJavaScript('''
              // 1. Lock Viewport (Anti-Zoom)
              var meta = document.createElement('meta');
              meta.name = 'viewport';
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              document.getElementsByTagName('head')[0].appendChild(meta);
              
              // 2. Inject CSS for Dark Mode, Ad Blocking, and Layout Spacing
              var style = document.createElement('style');
              style.innerHTML = `
                html, body { 
                  background-color: #000000 !important; 
                  overflow-x: hidden !important;
                  padding-top: \${72 + MediaQuery.of(context).padding.top}px !important;    /* Dynamic Space for Header */
                  padding-bottom: 200px !important; /* Space for MiniPlayer + Nav */
                }
                
                /* Ad Blocking */
                ytm-ad-slot, .ad-container, .ad-div, #player-ads, .ytp-ad-module, 
                .ytp-ad-overlay-container, ytm-promoted-item-renderer, 
                ytm-companion-ad-renderer, .ytm-video-ads { 
                  display: none !important; 
                }
                
                /* Refined Fullscreen Prevention */
                .fullscreen-overlay, .ytm-player-overlay { pointer-events: none !important; background: transparent !important; }
              `;
              document.head.appendChild(style);

              // 3. Persistent Ad Remover & Audio Muter
              setInterval(function() {
                // Remove ad elements
                var ads = document.querySelectorAll('ytm-ad-slot, .ad-container, #player-ads, .ytm-video-ads, ytm-promoted-item-renderer');
                for (var i = 0; i < ads.length; i++) {
                  ads[i].remove();
                }
                
                // Mute and Pause any video in WebView to prevent double audio/ads
                var videos = document.querySelectorAll('video');
                for (var i = 0; i < videos.length; i++) {
                  videos[i].muted = true;
                  videos[i].pause();
                }

                // Skip video ads if possible
                var skipBtn = document.querySelector('.ytp-ad-skip-button, .ytp-ad-skip-button-modern');
                if (skipBtn) skipBtn.click();
              }, 500); // Check every 500ms for aggressive blocking
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView Error: \${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://music.youtube.com'));
  }

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    final searchUrl =
        'https://music.youtube.com/search?q=${Uri.encodeComponent(query)}';
    _webController.loadRequest(Uri.parse(searchUrl));
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  Future<void> _safeRunJavaScript(String script) async {
    try {
      await _webController.runJavaScript(script);
    } catch (e) {
      debugPrint('JS Execution Error (Ignored): \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: Stack(
        children: [
          // WebView Content - Fullscreen height
          WebViewWidget(controller: _webController),

          // Loading Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: AppTheme.kBackgroundColor,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.kPrimaryColor,
                  ),
                ),
              ),
            ),

          // Floating Blurred Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(
              isSearching: _isSearching,
              searchController: _searchController,
              onSearchToggle: () {
                setState(() {
                  _isSearching = !_isSearching;
                });
              },
              onSearchSubmit: _handleSearch,
              onBack: () async {
                if (await _webController.canGoBack()) {
                  _webController.goBack();
                }
              },
              onRefresh: () {
                _webController.reload();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onSearchToggle;
  final Function(String) onSearchSubmit;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _Header({
    required this.isSearching,
    required this.searchController,
    required this.onSearchToggle,
    required this.onSearchSubmit,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: (isSearching ? 136 : 72) + topPadding,
          padding: EdgeInsets.only(top: topPadding, left: 20, right: 12),
          decoration: BoxDecoration(
            color: AppTheme.kBackgroundColor.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: Column(
            children: [
              // Top Row: Logo & Actions
              SizedBox(
                height: 70,
                child: Row(
                  children: [
                    // Logo/Title Area
                    const Icon(
                      Icons.play_circle_filled_rounded,
                      color: AppTheme.kPrimaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUTUBE MUSIC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.kPrimaryColor,
                              letterSpacing: 2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Streaming',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.white70,
                      ),
                      onPressed: onBack,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 22,
                        color: Colors.white70,
                      ),
                      onPressed: onRefresh,
                    ),
                    IconButton(
                      icon: Icon(
                        isSearching
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        size: 24,
                        color: isSearching
                            ? AppTheme.kPrimaryColor
                            : Colors.white70,
                      ),
                      onPressed: onSearchToggle,
                    ),
                  ],
                ),
              ),

              // Bottom Row: Search Field (Animated)
              if (isSearching)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Cari lagu, artis, atau album...',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: onSearchSubmit,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
