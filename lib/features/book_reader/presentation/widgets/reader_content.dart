import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:pdfx/pdfx.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';

class ReaderContent extends StatefulWidget {
  final LocalBook book;
  final bool isVerticalMode;
  final int? jumpToPage;
  final int initialPage;
  final Function(int currentPage, int totalPages)? onPageChanged;

  const ReaderContent({
    super.key,
    required this.book,
    this.isVerticalMode = false,
    this.jumpToPage,
    this.initialPage = 1,
    this.onPageChanged,
  });

  @override
  State<ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends State<ReaderContent> {
  PdfController? _pdfController;
  EpubController? _epubController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final format = widget.book.format.toLowerCase();
    if (format == 'pdf') {
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.book.path),
        initialPage: widget.initialPage,
      );
    } else if (format == 'epub') {
      _epubController = EpubController();
    }
  }

  @override
  void didUpdateWidget(covariant ReaderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jumpToPage != null &&
        widget.jumpToPage != oldWidget.jumpToPage) {
      if (_pdfController != null) {
        _pdfController!.jumpToPage(widget.jumpToPage!);
      }
      // Untuk EPUB, flutter_epub_viewer biasanya butuh penanganan berbeda
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    // _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = widget.book.format.toLowerCase();

    if (format == 'pdf' && _pdfController != null) {
      return PdfView(
        controller: _pdfController!,
        scrollDirection: widget.isVerticalMode
            ? Axis.vertical
            : Axis.horizontal,
        pageSnapping: true,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        onPageChanged: (page) {
          if (widget.onPageChanged != null) {
            widget.onPageChanged!(page, _pdfController!.pagesCount ?? 0);
          }
        },
      );
    } else if (format == 'epub' && _epubController != null) {
      return EpubViewer(
        epubController: _epubController!,
        epubSource: EpubSource.fromFile(File(widget.book.path)),
        displaySettings: EpubDisplaySettings(
          // scrollMode: widget.isVerticalMode ? EpubScrollMode.all : EpubScrollMode.none,
        ),
        // onPageChanged: (value) {
        //   // flutter_epub_viewer biasanya memberikan informasi progress/halaman
        //   debugPrint('Epub page changed: $value');
        // },
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Format $format tidak didukung atau file tidak dapat dibuka.',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
  }
}
