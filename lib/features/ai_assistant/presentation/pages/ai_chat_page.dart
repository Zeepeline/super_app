import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../cubit/ai_chat_cubit.dart';
import '../cubit/ai_chat_state.dart';
import '../cubit/chat_message.dart';
import 'ai_configuration_page.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AiChatCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppTheme.kBackgroundColor,
            body: Stack(
              children: [
                // Background Elements
                _buildBackground(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: BlocConsumer<AiChatCubit, AiChatState>(
                          listener: (context, state) {
                            _scrollToBottom();
                          },
                          builder: (context, state) {
                            List<ChatMessage> history = [];
                            bool isLoading = false;

                            if (state is AiChatLoaded) {
                              history = state.history;
                            } else if (state is AiChatLoading) {
                              history = state.history;
                              isLoading = true;
                            } else if (state is AiChatError) {
                              history = state.history;
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(20),
                              itemCount: history.length + (isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == history.length) {
                                  return _buildLoadingBubble();
                                }
                                final message = history[index];
                                final content = message.content;
                                final isUser = content.role == 'user';
                                final text = content.parts
                                    .whereType<ai.TextPart>()
                                    .map((e) => e.text)
                                    .join();

                                final isLast = index == history.length - 1;
                                final isSecondLast =
                                    index == history.length - 2;
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
                            );
                          },
                        ),
                      ),
                      _buildInputArea(context),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
                color: AppTheme.kPrimaryColor.withValues(alpha: 0.1),
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

  Widget _buildHeader(BuildContext context) {
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
          Expanded(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.kPrimaryColor,
                  child: Icon(Icons.psychology, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SoundWave AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: AppTheme.kPrimaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiConfigurationPage(),
                ),
              );
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.2),
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

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
          const SizedBox(width: 12),
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
                          ? AppTheme.kPrimaryColor.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 20),
                      ),
                      border: Border.all(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: MarkdownBody(
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
                        listBullet: TextStyle(
                          color: isUser ? Colors.black : Colors.white70,
                        ),
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
                          color: isUser
                              ? Colors.black.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.8),
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: isUser
                              ? Colors.black.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(
                              color: isUser
                                  ? Colors.black26
                                  : AppTheme.kPrimaryColor.withValues(
                                      alpha: 0.5,
                                    ),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
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
}
