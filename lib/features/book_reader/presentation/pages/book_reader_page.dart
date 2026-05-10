import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';

import '../widgets/reader_content.dart';
import '../widgets/reader_controls.dart';
import '../widgets/reader_header.dart';

class BookReaderPage extends StatefulWidget {
  final LocalBook book;

  const BookReaderPage({super.key, required this.book});

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  bool _isVerticalMode = false;
  int _currentPage = 1;
  int _totalPages = 0;
  int? _jumpTargetPage;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('book_progress_${widget.book.id}') ?? 1;
    setState(() {
      _currentPage = savedPage;
      _isLoadingProgress = false;
    });
  }

  Future<void> _saveProgress(int page, int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('book_progress_${widget.book.id}', page);
    if (total > 0) {
      await prefs.setInt('book_total_${widget.book.id}', total);
    }
  }

  void _toggleScrollMode() {
    setState(() {
      _isVerticalMode = !_isVerticalMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProgress) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: ReaderContent(
              book: widget.book,
              isVerticalMode: _isVerticalMode,
              initialPage: _currentPage,
              jumpToPage: _jumpTargetPage,
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page;
                  _totalPages = total;
                });
                _saveProgress(page, total);
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ReaderHeader(title: widget.book.title),
          ),
          // Progress Bar & Page Indicator
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 100,
              ), // Di atas ReaderControls
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_totalPages > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Page $_currentPage of $_totalPages (${((_currentPage / _totalPages) * 100).toInt()}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_totalPages > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.kPrimaryColor,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: AppTheme.kPrimaryColor,
                          overlayColor: AppTheme.kPrimaryColor.withOpacity(0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _currentPage.toDouble().clamp(
                            1,
                            _totalPages.toDouble(),
                          ),
                          min: 1,
                          max: _totalPages.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _jumpTargetPage = value.toInt();
                              _currentPage = value.toInt();
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ReaderControls(
              book: widget.book,
              isVerticalMode: _isVerticalMode,
              onToggleMode: _toggleScrollMode,
            ),
          ),
        ],
      ),
    );
  }
}
