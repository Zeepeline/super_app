import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  const videoId = 'VideoId_HERE'; // Replace with a real ID for testing
  try {
    final manifest = await yt.videos.closedCaptions.getManifest(videoId);
    print('Available captions: ${manifest.tracks.length}');
    for (var track in manifest.tracks) {
      print(' - ${track.language.name} (${track.language.code})');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
