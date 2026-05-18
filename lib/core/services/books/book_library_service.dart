import 'dart:developer' as dev;
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_app/core/utils/hive_box_constants.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';

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
      final box = Hive.box(HiveBoxConstants.booksMetadataBox);

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

            // Merge with metadata from Hive
            final metadata = box.get(book.id) as Map?;
            LocalBook finalBook = book;

            if (metadata != null) {
              finalBook = LocalBook(
                id: book.id,
                title: book.title,
                author: book.author,
                path: book.path,
                format: book.format,
                coverPath: book.coverPath,
                dateAdded: book.dateAdded,
                synopsis: metadata['synopsis'],
                genreTags: (metadata['genreTags'] as List?)?.cast<String>(),
                publishDate: metadata['publishDate'],
              );
            }

            // If no manual cover found, try to extract from metadata
            if (finalBook.coverPath == null) {
              final extractedPath = await _coverService.getCoverPath(path);
              if (extractedPath != null) {
                books.add(
                  LocalBook(
                    id: finalBook.id,
                    title: finalBook.title,
                    author: finalBook.author,
                    path: finalBook.path,
                    format: finalBook.format,
                    coverPath: extractedPath,
                    dateAdded: finalBook.dateAdded,
                    synopsis: finalBook.synopsis,
                    genreTags: finalBook.genreTags,
                    publishDate: finalBook.publishDate,
                  ),
                );
              } else {
                books.add(finalBook);
              }
            } else {
              books.add(finalBook);
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
      final fileName = path.split('/').last;
      await Hive.box(HiveBoxConstants.booksMetadataBox).delete(fileName);
      await file.delete();
      dev.log("Deleted book: $path", name: "BookLibrary");
    }
  }

  Future<void> updateBookMetadata(LocalBook book) async {
    try {
      final box = Hive.box(HiveBoxConstants.booksMetadataBox);
      await box.put(book.id, {
        'synopsis': book.synopsis,
        'genreTags': book.genreTags,
        'publishDate': book.publishDate,
      });
      dev.log("Saved metadata for book: ${book.title}", name: "BookLibrary");
    } catch (e) {
      dev.log("Error saving book metadata: $e", name: "BookLibrary");
    }
  }
}
