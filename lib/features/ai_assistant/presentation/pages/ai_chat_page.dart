import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/services/music/smart_playlist_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/music_player/domain/entities/track_entity.dart';
import '../../../../features/music_player/presentation/widgets/chat_playlist_card.dart';
import '../../../../injection_container.dart';
import '../../../../features/music_player/presentation/pages/music_player_page.dart';
import '../../../../features/music_player/presentation/cubit/player_cubit.dart';
import '../cubit/ai_chat_cubit.dart';
import '../cubit/ai_chat_state.dart';
import 'ai_abilities_page.dart';
import 'ai_configuration_page.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _requestPermission();
    // Tunggu sebentar sampai data ter-load dan list rendered
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _scrollToBottom(immediate: true);
    });
  }

  Future<void> _requestPermission() async {
    // Meminta kedua izin yang dibutuhkan iOS
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.speech,
    ].request();

    print("AiChatPage: Status Mikrofon: ${statuses[Permission.microphone]}");
    print("AiChatPage: Status Speech: ${statuses[Permission.speech]}");

    if (statuses[Permission.microphone]!.isPermanentlyDenied ||
        statuses[Permission.speech]!.isPermanentlyDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Izin mikrofon atau pengenalan suara ditolak permanen. Aktifkan di pengaturan.",
              ),
              action: SnackBarAction(
                label: "PENGATURAN",
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }
      });
    }
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AiChatCubit>(),
      child: BlocConsumer<AiChatCubit, AiChatState>(
        listener: (context, state) {
          _scrollToBottom();
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppTheme.kBackgroundColor,
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  // Background Elements
                  _buildBackground(),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(context, state),
                        Expanded(
                          child: state.isCallMode
                              ? _buildCallModeUI(context, state)
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(20),
                                  itemCount:
                                      state.history.length +
                                      (state is AiChatLoading ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == state.history.length) {
                                      return _buildLoadingBubble();
                                    }
                                    final message = state.history[index];
                                    final content = message.content;
                                    final isUser = content.role == 'user';
                                    final text = content.parts
                                        .whereType<ai.TextPart>()
                                        .map((e) => e.text)
                                        .join();

                                    final isLast =
                                        index == state.history.length - 1;
                                    final isSecondLast =
                                        index == state.history.length - 2;
                                    final showRetry =
                                        isLast && state is AiChatError;

                                    // Tampilkan indikator error di bubble user jika pesan setelahnya error
                                    final hasError =
                                        isUser &&
                                        isSecondLast &&
                                        state is AiChatError;

                                    return _ChatBubble(
                                      text: text,
                                      isUser: isUser,
                                      isError: hasError,
                                      timestamp: message.timestamp,
                                      onRetry: showRetry
                                          ? () => context
                                                .read<AiChatCubit>()
                                                .retryLastMessage()
                                          : null,
                                    );
                                  },
                                ),
                        ),
                        if (!state.isCallMode) _buildInputArea(context, state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCallModeUI(BuildContext context, AiChatState state) {
    String status = "Terhubung";
    String subStatus = "Siap untuk mengobrol";

    if (state is AiChatListening) {
      status = "Mendengarkan...";
      subStatus = "Bicaralah, saya mendengarkan";
    } else if (state is AiChatLoading) {
      status = "Sedang Berpikir...";
      subStatus = "Menganalisis koleksi ritme Anda";
    } else if (state is AiChatLoaded && !state.isCallMode) {
      // This case shouldn't happen in Call Mode, but safety first
      status = "Siap";
      subStatus = "Ketuk untuk bicara";
    } else if (state is AiChatLoaded) {
      status = "Asisten Berbicara...";
      subStatus = "Memberikan rekomendasi untukmu";
    }

    return Stack(
      children: [
        // Ambient Glow Background
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.kPrimaryColor.withOpacity(0.15),
                  AppTheme.kBackgroundColor.withOpacity(0.0),
                ],
                radius: 0.8,
              ),
            ),
          ),
        ),

        // Content
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Central Visualizer Section
            Stack(
              alignment: Alignment.center,
              children: [
                // Ripples
                _OrbRipple(isListening: state is AiChatListening),
                _OrbRipple(
                  isListening: state is AiChatListening,
                  delay: const Duration(milliseconds: 1500),
                ),

                // The Sonic Orb
                _SonicOrb(isLoading: state is AiChatLoading),
              ],
            ),

            const SizedBox(height: 48),

            // Status Information
            Text(
              status,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subStatus,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.kOnSurfaceVariantColor,
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // Waveform Section
            if (state is AiChatListening ||
                state is AiChatLoading ||
                (state is AiChatLoaded && state.isCallMode))
              const _WaveformVisualizer(),

            const SizedBox(height: 40),

            // Call Controls Component
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _CallControlBar(
                onEndCall: () => context.read<AiChatCubit>().toggleCallMode(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.kPrimaryColor.withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AiChatState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.kPrimaryColor,
                  child: Icon(Icons.psychology, color: Colors.black, size: 20),
                ),
                SizedBox(width: 12),

                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     const Text(
                //       'SoundWave AI',
                //       style: TextStyle(
                //         color: Colors.white,
                //         fontSize: 16,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //     Row(
                //       children: [
                //         Container(
                //           width: 8,
                //           height: 8,
                //           decoration: const BoxDecoration(
                //             color: AppTheme.kPrimaryColor,
                //             shape: BoxShape.circle,
                //           ),
                //         ),
                //         const SizedBox(width: 4),
                //         const Text(
                //           'Online',
                //           style: TextStyle(
                //             color: AppTheme.kPrimaryColor,
                //             fontSize: 12,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
          // Debug STT Test Button
          // IconButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const SttTestPage()),
          //     );
          //   },
          //   icon: const Icon(Icons.bug_report, color: Colors.amber, size: 22),
          // ),
          IconButton(
            onPressed: () {
              if (!state.hasApiKey) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Silakan masukkan API Key Gemini terlebih dahulu di menu pengaturan.',
                    ),
                  ),
                );
                return;
              }
              context.read<AiChatCubit>().toggleCallMode();
            },
            icon: Icon(
              Icons.phone_in_talk_rounded,
              color: state.isCallMode
                  ? AppTheme.kPrimaryColor
                  : (!state.hasApiKey ? Colors.white38 : Colors.white),
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiAbilitiesPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: AppTheme.kBackgroundColor,
                  title: const Text(
                    'Hapus Chat',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin menghapus seluruh riwayat chat ini?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.white24),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AiChatCubit>().clearChat();
                        Navigator.pop(dialogContext);
                      },
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: AppTheme.kPrimaryColor),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiConfigurationPage(),
                ),
              ).then((_) {
                if (context.mounted) {
                  context.read<AiChatCubit>().checkApiKey();
                }
              });
            },
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, AiChatState state) {
    if (!state.hasApiKey) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AiConfigurationPage(),
              ),
            ).then((_) {
              if (context.mounted) {
                context.read<AiChatCubit>().checkApiKey();
              }
            });
          },
          icon: const Icon(Icons.key, color: Colors.black),
          label: const Text(
            'Masukkan API Key untuk Memulai',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.kPrimaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Tanya sesuatu tentang musik...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // GestureDetector(
          //   onTap: () {
          //     context.read<AiChatCubit>().startVoiceListening();
          //   },
          //   child: Container(
          //     width: 48,
          //     height: 48,
          //     decoration: BoxDecoration(
          //       color: state is AiChatListening
          //           ? AppTheme.kPrimaryColor
          //           : Colors.white.withOpacity(0.1),
          //       shape: BoxShape.circle,
          //     ),
          //     child: Icon(
          //       Icons.mic_rounded,
          //       color: state is AiChatListening ? Colors.black : Colors.white,
          //     ),
          //   ),
          // ),

          // const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_messageController.text.isNotEmpty) {
                context.read<AiChatCubit>().sendMessage(
                  _messageController.text,
                );
                _messageController.clear();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.kPrimaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _SonicOrb extends StatefulWidget {
  final bool isLoading;
  const _SonicOrb({required this.isLoading});

  @override
  State<_SonicOrb> createState() => _SonicOrbState();
}

class _SonicOrbState extends State<_SonicOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 192,
      height: 192,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.kPrimaryColor, AppTheme.kPrimaryContainerColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kPrimaryColor.withOpacity(0.3),
            blurRadius: 60,
            spreadRadius: -15,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.kSurfaceColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // The AI Core Image
            Center(
              child: Image.network(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBksNnZwnDogkVhFELO6yOov2XD10LqUN7j6XfUELcwGJ67Nfr5WfCH8YOdurH_JMNmP_7jKKFpkYt_8iSAKhyT5zSLMzW6zSgPS8ZOkJ_N-zB_D_pgE9lyU34gexyYYrITqtIUixgjtbSFUfrFrBj77yxGnNr58EzDXFtv3IebR2LIKMOtKFoyVFAdJqE5NO58f3eaCK3g6kcQMjwB48_YqBcU68qKBVhVnHUJuzst0wSzKgB_BlHJn-0lsPgU8Q2SSJoAKzOQ9Ig",
                fit: BoxFit.cover,
                width: 200,
                height: 200,
                opacity: const AlwaysStoppedAnimation(0.8),
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.psychology,
                  color: AppTheme.kPrimaryColor,
                  size: 80,
                ),
              ),
            ),
            // Inner Pulse Overlay
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.kPrimaryColor.withOpacity(0.1),
              ),
            ),
            if (widget.isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.kPrimaryColor,
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrbRipple extends StatefulWidget {
  final bool isListening;
  final Duration delay;
  const _OrbRipple({required this.isListening, this.delay = Duration.zero});

  @override
  State<_OrbRipple> createState() => _OrbRippleState();
}

class _OrbRippleState extends State<_OrbRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.25, 1.0, 0.5, 1.0),
      ),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 0.0), weight: 80),
    ]).animate(_controller);

    if (widget.isListening) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.repeat();
      });
    }
  }

  @override
  void didUpdateWidget(_OrbRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.kPrimaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformVisualizer extends StatelessWidget {
  const _WaveformVisualizer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(9, (index) {
          final delays = [1.2, 1.0, 1.4, 0.8, 1.1, 1.3, 0.9, 1.2, 1.5];
          final heights = [
            16.0,
            32.0,
            48.0,
            40.0,
            24.0,
            56.0,
            40.0,
            24.0,
            16.0,
          ];
          final opacities = [0.4, 0.6, 0.8, 1.0, 0.9, 1.0, 0.7, 0.5, 0.3];

          return _WaveformBar(
            height: heights[index],
            color: AppTheme.kPrimaryColor.withOpacity(opacities[index]),
            duration: Duration(milliseconds: (delays[index] * 1000).toInt()),
          );
        }),
      ),
    );
  }
}

class _WaveformBar extends StatefulWidget {
  final double height;
  final Color color;
  final Duration duration;

  const _WaveformBar({
    required this.height,
    required this.color,
    required this.duration,
  });

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation =
        Tween<double>(begin: 4.0, end: widget.height).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed)
            _controller.reverse();
          else if (status == AnimationStatus.dismissed)
            _controller.forward();
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: _animation.value,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}

class _CallControlBar extends StatelessWidget {
  final VoidCallback onEndCall;
  const _CallControlBar({required this.onEndCall});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(48),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.kSurfaceContainerHighestColor.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(48),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ControlIconButton(
                icon: Icons.volume_up_rounded,
                label: "Speaker",
                onTap: () {},
              ),
              _ControlIconButton(
                icon: Icons.mic_rounded,
                label: "Mute",
                onTap: () {},
              ),
              _ControlIconButton(
                icon: Icons.call_end_rounded,
                label: "Akhiri",
                isEndCall: true,
                onTap: onEndCall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEndCall;

  const _ControlIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEndCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isEndCall ? 64 : 56,
            height: isEndCall ? 64 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEndCall
                  ? Colors.redAccent
                  : AppTheme.kSurfaceContainerHighColor,
              boxShadow: isEndCall
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: isEndCall ? 32 : 24),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              color: isEndCall
                  ? Colors.redAccent
                  : AppTheme.kOnSurfaceVariantColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isError;
  final DateTime timestamp;
  final VoidCallback? onRetry;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isUser && isError)
            const Padding(
              padding: EdgeInsets.only(right: 8, bottom: 12),
              child: Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesan disalin ke clipboard'),
                    behavior: SnackBarBehavior.floating,
                    width: 200,
                    backgroundColor: AppTheme.kPrimaryColor,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppTheme.kPrimaryColor.withOpacity(0.9)
                          : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 20),
                      ),
                      border: Border.all(
                        color: isUser
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: _buildMessageContent(context),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Coba lagi',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: AppTheme.kPrimaryColor,
                        elevation: 4,
                        shadowColor: AppTheme.kPrimaryColor.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (text.startsWith('[SMART_PLAYLIST_JSON:') && text.endsWith(']')) {
      try {
        final jsonString = text.substring(21, text.length - 1);
        final data = jsonDecode(jsonString);

        final tracksList = (data['tracks'] as List).map((t) {
          return TrackEntity(
            id: t['id'],
            title: t['title'],
            artist: t['artist'],
            album: 'Smart Playlist',
            albumArtUrl: t['albumArtUrl'] ?? '',
            audioUrl: '', // resolved later by ytExplode
            duration: Duration(seconds: t['duration_seconds'] ?? 0),
            localPath: null,
            isFavorite: false,
            syncedLyrics: null,
            plainLyrics: null,
          );
        }).toList();

        final response = SmartPlaylistResponse(
          playlistName: data['playlistName'] ?? 'Playlist',
          reason: data['reason'] ?? '',
          tracks: tracksList,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Berikut playlist yang saya buatkan untuk Anda:",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 8),
            ChatPlaylistCard(response: response),
          ],
        );
      } catch (e) {
        // Fallback if parsing fails
      }
    } else if (text.startsWith('[DOWNLOAD_MUSIC_JSON:') && text.endsWith(']')) {
      try {
        final jsonString = text.substring(21, text.length - 1);
        final data = jsonDecode(jsonString);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selesai mencari! Saya telah memulai proses download lagu ini untuk Anda:",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _DownloadMusicCard(
              title: data['title'] ?? 'Lagu',
              artist: data['artist'] ?? 'Unknown Artist',
              thumbnail: data['thumbnail'] ?? '',
              videoId: data['videoId'] ?? '',
            ),
          ],
        );
      } catch (e) {
        // Fallback
      }
    }

    return MarkdownBody(
      data: text,
      selectable: false,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: isUser ? Colors.black : Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
        strong: TextStyle(
          color: isUser ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        em: TextStyle(
          color: isUser ? Colors.black : Colors.white,
          fontStyle: FontStyle.italic,
        ),
        listBullet: TextStyle(color: isUser ? Colors.black : Colors.white70),
        h1: TextStyle(
          color: isUser ? Colors.black : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: isUser ? Colors.black : Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: isUser ? Colors.black : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        blockquote: TextStyle(
          color: isUser ? Colors.black.withOpacity(0.7) : Colors.white70,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: isUser
              ? Colors.black.withOpacity(0.05)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _DownloadMusicCard extends StatelessWidget {
  final String title;
  final String artist;
  final String thumbnail;
  final String videoId;

  const _DownloadMusicCard({
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnail.isNotEmpty
                    ? Image.network(
                        thumbnail,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.white.withOpacity(0.1),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to music player
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MusicPlayerPage(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
              label: const Text(
                "Putar Lagu",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
