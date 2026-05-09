import os
import json
from ytmusicapi import YTMusic

class YTMusicService:
    def __init__(self):
        # Inisialisasi tanpa auth (public mode)
        self.yt = YTMusic()

    def search_songs(self, query, limit=5):
        """Mencari lagu di YouTube Music."""
        try:
            results = self.yt.search(query, filter="songs", limit=limit)
            parsed_results = []
            for item in results:
                # Ambil thumbnail terbaik
                thumbnails = item.get('thumbnails', [])
                album_art = thumbnails[-1]['url'] if thumbnails else ''
                
                # Ambil artist
                artists = item.get('artists', [])
                artist_name = ", ".join([a['name'] for a in artists]) if artists else 'Unknown Artist'
                
                parsed_results.append({
                    'id': item.get('videoId'),
                    'title': item.get('title'),
                    'artist': artist_name,
                    'album': item.get('album', {}).get('name', 'Single'),
                    'duration_seconds': item.get('duration_seconds', 0),
                    'albumArtUrl': album_art
                })
            return parsed_results
        except Exception as e:
            print(f"Error search_songs: {e}")
            return []

    def get_playlist_suggestions(self, query, limit=10):
        """Mencari playlist atau album berdasarkan query."""
        try:
            # Kita bisa mencari playlist yang sudah ada
            results = self.yt.search(query, filter="playlists", limit=1)
            if results:
                playlist_id = results[0]['browseId']
                playlist_data = self.yt.get_playlist(playlist_id, limit=limit)
                
                tracks = []
                for item in playlist_data.get('tracks', []):
                    artists = item.get('artists', [])
                    artist_name = ", ".join([a['name'] for a in artists]) if artists else 'Unknown Artist'
                    thumbnails = item.get('thumbnails', [])
                    album_art = thumbnails[-1]['url'] if thumbnails else ''
                    
                    tracks.append({
                        'id': item.get('videoId'),
                        'title': item.get('title'),
                        'artist': artist_name,
                        'album': item.get('album', {}).get('name', 'Playlist'),
                        'duration_seconds': item.get('duration_seconds', 0),
                        'albumArtUrl': album_art
                    })
                
                return {
                    'playlistName': playlist_data.get('title'),
                    'reason': f"Playlist berdasarkan pencarian '{query}'",
                    'tracks': tracks
                }
            return None
        except Exception as e:
            print(f"Error get_playlist_suggestions: {e}")
            return None
