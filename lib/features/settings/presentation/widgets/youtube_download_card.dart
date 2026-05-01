import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class YoutubeDownloadCard extends StatefulWidget {
  final Function(String) onDownload;
  final bool isDownloading;
  final String? stage;
  final double? progress;

  const YoutubeDownloadCard({
    super.key,
    required this.onDownload,
    this.isDownloading = false,
    this.stage,
    this.progress,
  });

  @override
  State<YoutubeDownloadCard> createState() => _YoutubeDownloadCardState();
}

class _YoutubeDownloadCardState extends State<YoutubeDownloadCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isDownloading
              ? AppTheme.kPrimaryColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.download_for_offline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YouTube Downloader',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Convert video to local MP3',
                    style: TextStyle(color: Color(0xFFadaaaa), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.isDownloading) ...[
            Text(
              widget.stage ?? 'Processing...',
              style: const TextStyle(
                color: AppTheme.kPrimaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                color: AppTheme.kPrimaryColor,
                minHeight: 6,
              ),
            ),
          ] else ...[
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: AppTheme.kPrimaryColor,
              decoration: InputDecoration(
                hintText: 'Paste YouTube URL here...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.2),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.kPrimaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    widget.onDownload(_controller.text);
                    _controller.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kPrimaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'DOWNLOAD & CONVERT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
