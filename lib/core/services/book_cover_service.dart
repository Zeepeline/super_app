import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class BookCoverService {
  Future<String?> getCoverPath(String bookPath) async {
    try {
      final file = File(bookPath);
      if (!await file.exists()) return null;

      // Generate a unique filename for the cache based on the book path
      final bytes = utf8.encode(bookPath);
      final hash = sha256.convert(bytes).toString();

      final cacheDir = await getTemporaryDirectory();
      final coverCacheDir = Directory('${cacheDir.path}/book_covers');
      if (!await coverCacheDir.exists()) {
        await coverCacheDir.create(recursive: true);
      }

      final cachePath = '${coverCacheDir.path}/$hash.jpg';
      final cacheFile = File(cachePath);

      if (await cacheFile.exists()) {
        return cachePath;
      }

      // If not cached, extract based on format
      if (bookPath.toLowerCase().endsWith('.pdf')) {
        return await _extractPdfCover(bookPath, cachePath);
      } else if (bookPath.toLowerCase().endsWith('.epub')) {
        return await _extractEpubCover(bookPath, cachePath);
      }
    } catch (e) {
      dev.log("Error getting cover path: $e", name: "BookCover");
    }
    return null;
  }

  Future<String?> _extractPdfCover(String bookPath, String cachePath) async {
    PdfDocument? document;
    PdfPage? page;
    try {
      dev.log("Opening PDF document: $bookPath", name: "BookCover");
      document = await PdfDocument.openFile(bookPath);
      page = await document.getPage(1);

      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
        quality: 80,
      );

      if (pageImage != null) {
        await File(cachePath).writeAsBytes(pageImage.bytes);
        dev.log(
          "Successfully extracted PDF cover to $cachePath",
          name: "BookCover",
        );
        return cachePath;
      }
    } catch (e) {
      dev.log(
        "Detailed error extracting PDF cover for $bookPath: $e",
        name: "BookCover",
        error: e,
      );
    } finally {
      await page?.close();
      await document?.close();
    }
    return null;
  }

  Future<String?> _extractEpubCover(String bookPath, String cachePath) async {
    // Skipping EPUB cover extraction for now as requested
    return null;
  }
}
