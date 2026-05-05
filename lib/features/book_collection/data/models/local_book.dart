import 'dart:io';

class LocalBook {
  final String id;
  final String title;
  final String author;
  final String path;
  final String format;
  final String? coverPath;
  final DateTime? dateAdded;
  final int lastReadPage;
  final String? synopsis;
  final List<String>? genreTags;
  final String? publishDate;

  LocalBook({
    required this.id,
    required this.title,
    required this.author,
    required this.path,
    required this.format,
    this.coverPath,
    this.dateAdded,
    this.lastReadPage = 1,
    this.synopsis,
    this.genreTags,
    this.publishDate,
  });

  factory LocalBook.fromFile(String path) {
    final file = File(path);
    final fileName = path.split('/').last;
    final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
    final ext = fileName.substring(fileName.lastIndexOf('.') + 1).toUpperCase();
    final parentPath = file.parent.path;

    String title = nameWithoutExt;
    String author = 'Unknown';

    if (nameWithoutExt.contains(' - ')) {
      final parts = nameWithoutExt.split(' - ');
      title = parts[0];
      author = parts[1];
    }

    // Try to find a matching cover image in the same directory
    String? coverPath;
    final possibleExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    for (var imgExt in possibleExtensions) {
      final imgPath = '$parentPath/$nameWithoutExt$imgExt';
      if (File(imgPath).existsSync()) {
        coverPath = imgPath;
        break;
      }
    }

    return LocalBook(
      id: fileName,
      title: title,
      author: author,
      path: path,
      format: ext,
      coverPath: coverPath,
      dateAdded: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LocalBook(title: $title, author: $author, format: $format, cover: ${coverPath != null ? "FOUND" : "NULL"}, path: $path)';
  }
}
