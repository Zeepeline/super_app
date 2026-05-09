import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:super_app/core/services/ai/ai_tools_service.dart';
import 'package:super_app/core/services/books/book_library_service.dart';
import 'package:super_app/core/services/notifications/smart_notification_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/ai_assistant/presentation/pages/ai_chat_page.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/features/book_collection/presentation/pages/book_collection_page.dart';
import 'package:super_app/features/book_reader/presentation/pages/book_reader_page.dart';
import 'package:super_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:super_app/features/main_wrapper.dart';
import 'package:super_app/features/nfc/presentation/pages/nfc_scanner_page.dart';
import 'package:super_app/injection_container.dart';

class ObsidianHomePage extends StatelessWidget {
  const ObsidianHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookLibraryService = sl<BookLibraryService>();

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildGreeting(context),
                const SizedBox(height: 24),
                const _AiSmartNotificationCard(),
                const SizedBox(height: 40),
                _buildQuickActions(context),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QUICK RESUME',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(
                      'View All',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                FutureBuilder<List<LocalBook>>(
                  future: bookLibraryService.getDownloadedBooks(),
                  builder: (context, snapshot) {
                    final latestBook =
                        (snapshot.hasData && snapshot.data!.isNotEmpty)
                        ? snapshot.data!.first
                        : null;

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.kSurfaceContainerLowColor,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        children: [
                          if (latestBook != null)
                            FutureBuilder<Map<String, int>>(
                              future: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final current =
                                    prefs.getInt(
                                      'book_progress_${latestBook.id}',
                                    ) ??
                                    0;
                                final total =
                                    prefs.getInt(
                                      'book_total_${latestBook.id}',
                                    ) ??
                                    0;
                                return {'current': current, 'total': total};
                              }(),
                              builder: (context, progressSnapshot) {
                                final current =
                                    progressSnapshot.data?['current'] ?? 0;
                                final total =
                                    progressSnapshot.data?['total'] ?? 0;
                                final percent = total > 0
                                    ? (current / total)
                                    : 0.0;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookReaderPage(book: latestBook),
                                      ),
                                    );
                                  },
                                  child: _buildStatusRow(
                                    context,
                                    icon: Icons.book_outlined,
                                    label: 'NOW READING',
                                    title: latestBook.title,
                                    subtitle: ' • ${latestBook.author}',
                                    trailing: Text(
                                      '${(percent * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: AppTheme.kPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    progress: percent,
                                  ),
                                );
                              },
                            )
                          else
                            _buildStatusRow(
                              context,
                              icon: Icons.book_outlined,
                              label: 'NOW READING',
                              title: 'No books yet',
                              subtitle: '',
                              trailing: const Text('0%'),
                              progress: 0.0,
                            ),
                          const SizedBox(height: 24),
                          _buildStatusRow(
                            context,
                            icon: Icons.music_note_outlined,
                            label: 'NOW PLAYING',
                            title: 'Ambient Obsidian',
                            subtitle: ' • Lofi Girl',
                            trailing: const Row(
                              children: [
                                _VisualizerBar(height: 12),
                                SizedBox(width: 2),
                                _VisualizerBar(height: 18),
                                SizedBox(width: 2),
                                _VisualizerBar(height: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
                // _buildQuickResume(context),
                // const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=100',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Obsidian Rhythm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () async {
            await sl<SmartNotificationService>().showSmartNotification(
              id: 888,
              actionType: 'test_manual',
              itemName: 'Latihan Fokus',
              additionalContext: 'User sedang mencoba fitur notifikasi cerdas.',
            );
          },
          icon: const Icon(
            Icons.notifications_active_outlined,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good evening, User',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '85% creative peak reached today.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String title,
    String? subtitle,
    required Widget trailing,
    double? progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.kSurfaceContainerHighestColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppTheme.kPrimaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,

                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.kSurfaceContainerHighestColor,
              valueColor: const AlwaysStoppedAnimation(AppTheme.kPrimaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.music_note_outlined, 'label': 'Music'},
      {'icon': Icons.menu_book_outlined, 'label': 'Reader'},
      {'icon': Icons.nfc_outlined, 'label': 'NFC'},
      {'icon': Icons.check_circle_outline, 'label': 'Tasks'},
      {'icon': Icons.psychology_outlined, 'label': 'AI'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Calendar'},
      {'icon': Icons.memory_outlined, 'label': 'Neural'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Stats'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ACTIONS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: () {
                if (action['label'] == 'Music') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainWrapper(),
                    ),
                  );
                } else if (action['label'] == 'Reader') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookCollectionPage(),
                    ),
                  );
                } else if (action['label'] == 'NFC') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NfcScannerPage(),
                    ),
                  );
                } else if (action['label'] == 'Tasks') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardPage(),
                    ),
                  );
                } else if (action['label'] == 'AI') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiChatPage()),
                  );
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.kSurfaceContainerLowColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: AppTheme.kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['label'] as String,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VisualizerBar extends StatelessWidget {
  final double height;
  const _VisualizerBar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.kPrimaryColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _AiSmartNotificationCard extends StatelessWidget {
  const _AiSmartNotificationCard();

  @override
  Widget build(BuildContext context) {
    final aiService = sl<AiToolsService>();

    return FutureBuilder<String>(
      future: aiService.getAiInsights(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.05),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        }

        final message = snapshot.data ?? "Semoga harimu menyenangkan!";

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.kPrimaryColor.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.kPrimaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.kPrimaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.kPrimaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SMART INSIGHT',
                    style: GoogleFonts.inter(
                      color: AppTheme.kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
