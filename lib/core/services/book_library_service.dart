import 'dart:developer' as dev;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../features/book_collection/data/models/local_book.dart';
import 'book_cover_service.dart';

class BookLibraryService {
  final BookCoverService _coverService;

  BookLibraryService(this._coverService);

  Future<List<LocalBook>> getDownloadedBooks() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${directory.path}/SoundWave/Books');

      dev.log("Scanning for books in: ${booksDir.path}", name: "BookLibrary");

      if (!await booksDir.exists()) {
        dev.log("Books directory does not exist yet.", name: "BookLibrary");
        return [];
      }

      final List<FileSystemEntity> files = await booksDir.list().toList();
      dev.log(
        "Found ${files.length} total files in directory.",
        name: "BookLibrary",
      );

      final List<LocalBook> books = [];

      for (var entity in files) {
        if (entity is File) {
          final path = entity.path;
          if (path.endsWith('.pdf') ||
              path.endsWith('.epub') ||
              path.endsWith('.mobi')) {
            final book = LocalBook.fromFile(path);
            
            // If no manual cover found, try to extract from metadata
            if (book.coverPath == null) {
              final extractedPath = await _coverService.getCoverPath(path);
              if (extractedPath != null) {
                books.add(LocalBook(
                  id: book.id,
                  title: book.title,
                  author: book.author,
                  path: book.path,
                  format: book.format,
                  coverPath: extractedPath,
                  dateAdded: book.dateAdded,
                ));
              } else {
                books.add(book);
              }
            } else {
              books.add(book);
            }
            dev.log("Parsed book: ${books.last}", name: "BookLibrary");
          }
        }
      }

      dev.log(
        "Successfully parsed ${books.length} books.",
        name: "BookLibrary",
      );
      // Sort by title
      books.sort((a, b) => a.title.compareTo(b.title));
      return books;
    } catch (e) {
      dev.log("Error scanning books: $e", name: "BookLibrary", error: e);
      return [];
    }
  }

  Future<void> deleteBook(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      dev.log("Deleted book: $path", name: "BookLibrary");
    }
  }
}

