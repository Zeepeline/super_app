
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/core/services/download_service.dart';
import 'package:super_app/features/home/data/datasources/home_local_data_source.dart';
import 'package:super_app/features/home/data/models/track_model.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:super_app/injection_container.dart';
import 'package:super_app/core/theme/app_theme.dart';

class YouTubeWebViewController extends GetxController {
  late final WebViewController controller;
  final RxBool isLoading = true.obs;
  final _uuid = const Uuid();

  @override
  void onInit() {
    super.onInit();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            isLoading.value = true;
          },
          onPageFinished: (String url) {
            isLoading.value = false;
            cleanUIAndSniff();
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse('https://m.youtube.com'));
  }

  void cleanUIAndSniff() {
    controller.runJavaScript('''
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          #header-bar, .header-bar, #koya-header, .search-container,
          ytd-masthead, #masthead-container, ytm-masthead,
          .modern-sharing-ui, .ytd-popup-container,
          .yt-spec-button-shape-next--call-to-action {
            display: none !important;
          }
        `;
        document.head.appendChild(style);
      })();
    ''');
  }

  Future<void> downloadCurrent(BuildContext context) async {
    final url = await controller.currentUrl();
    if (url != null && url.contains('watch?v=')) {
      final watchId = url.split('v=')[1].split('&')[0];
      final title = await controller.getTitle() ?? 'YouTube Download';

      final downloadService = sl<DownloadService>();
      final localDataSource = sl<HomeLocalDataSource>();

      Get.snackbar(
        'Download',
        'Starting download for: $title',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.kPrimaryColor,
        colorText: Colors.black,
      );

      try {
        final result = await downloadService.downloadTrack(
          url: url,
          trackId: _uuid.v4(),
        );
        if (result != null) {
          final track = TrackModel(
            idField: _uuid.v4(),
            titleField: title,
            artistField: 'YouTube',
            albumArtUrlField: 'https://img.youtube.com/vi/$watchId/0.jpg',
            audioUrlField: result,
            durationField: '0:00',
            localPathField: result,
            isFavoriteField: false,
          );
          await sl<HomeLocalDataSource>().addImportedTracks([track]);
          Get.snackbar(
            'Success',
            'Download complete: $title',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.kPrimaryColor,
            colorText: Colors.black,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Download failed: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } else {
      Get.snackbar(
        'Alert',
        'Please navigate to a YouTube video first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
      );
    }
  }
}

class YouTubeWebViewPage extends StatelessWidget {
  const YouTubeWebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final YouTubeWebViewController x =
        Get.isRegistered<YouTubeWebViewController>()
        ? Get.find<YouTubeWebViewController>()
        : Get.put(YouTubeWebViewController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'Web Downloader',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => x.controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.kPrimaryColor),
            onPressed: () => x.downloadCurrent(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: x.controller),
          Obx(() {
            if (x.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.kPrimaryColor),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
