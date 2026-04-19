
void main() {
  final titles = [
    "Blinding Lights [Official Music Video]",
    "Starboy (feat. Daft Punk) [Official Video]",
    "Save Your Tears (Lyric Video)",
    "Die For You (ft. Ariana Grande) [Audio]",
    "Artist - Song Title [HD]",
  ];

  for (var title in titles) {
    print('Original: $title');
    print('Cleaned:  ${cleanMetadata(title)}');
    print('---');
  }
}

String cleanMetadata(String text) {
  if (text.isEmpty) return text;
  
  return text
      // Remove common YouTube tags in brackets/parentheses
      .replaceAll(RegExp(r'\(Official.*?\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Official.*?\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Lyric.*?Video\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Lyric.*?Video\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Music.*?Video\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Music.*?Video\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Video\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Video\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Audio\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Audio\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Visualizer\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Visualizer\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Explicit\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Explicit\]', caseSensitive: false), '')
      // Remove features
      .replaceAll(RegExp(r'\(feat\..*?\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(ft\..*?\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'feat\..*$', caseSensitive: false), '')
      // Remove anything else in brackets (often junk)
      .replaceAll(RegExp(r'\[.*?\]'), '')
      // Clean up whitespace
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
