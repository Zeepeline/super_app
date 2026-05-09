import os
import sys
import json
import threading
import time
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

# --- KONFIGURASI PATH ---
try:
    current_dir = os.path.dirname(os.path.abspath(__file__))
except:
    current_dir = os.getcwd()

sys.path.append(os.path.join(current_dir, "site-packages"))
sys.path.append(current_dir)

DART_PORT = os.environ.get("DART_PORT")

# --- HANDLER ---
class WorkerHandler(BaseHTTPRequestHandler):
    def _send_json(self, data, status=200):
        try:
            self.send_response(status)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode('utf-8'))
        except: pass

    def log_message(self, format, *args):
        """Suppress default HTTP log messages."""
        pass

    def do_GET(self):
        if self.path == '/status':
            self._send_json({"status": "alive"})
        else:
            self._send_json({"error": "Not found"}, status=404)

    def do_POST(self):
        global DART_PORT
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else b'{}'
            data = json.loads(body)

            if self.path == '/update_dart_port':
                DART_PORT = str(data.get('port'))
                self._send_json({"status": "ok"})

            elif self.path == '/search':
                self._send_json({"status": "searching"})
                threading.Thread(
                    target=self._task_search,
                    args=(data.get('query', ''), data.get('port', DART_PORT)),
                    daemon=True,
                ).start()

            elif self.path == '/download':
                # YouTube audio download via yt-dlp
                url = data.get('url', '')
                output_path = data.get('output_path', '')
                port = data.get('port', DART_PORT)
                video_id = data.get('video_id', '')
                self._send_json({"status": "downloading"})
                threading.Thread(
                    target=self._task_download,
                    args=(url, output_path, port, video_id),
                    daemon=True,
                ).start()

            elif self.path == '/get_url':
                # Get stream URL for a YouTube video (synchronous)
                video_id = data.get('video_id', '')
                result = self._task_get_url_sync(video_id)
                self._send_json(result)

            elif self.path == '/books/download':
                # Book download from mirror URL
                book_id = data.get('id', '')
                url = data.get('url', '')
                title = data.get('title', '')
                source = data.get('source', '')
                save_path = data.get('save_path', '')
                port = DART_PORT
                threading.Thread(
                    target=self._task_download_book,
                    args=(book_id, url, title, source, port, save_path),
                    daemon=True,
                ).start()
                self._send_json({"status": "downloading"})

            elif self.path == '/yt_search':
                # Search songs via ytmusicapi
                query = data.get('query', '')
                result = self._task_yt_search_sync(query)
                self._send_json(result)

            elif self.path == '/yt_smart_playlist':
                # Create smart playlist via ytmusicapi
                query = data.get('query', '')
                result = self._task_yt_playlist_sync(query)
                self._send_json(result)
            
            elif self.path == '/books/search':
                # Search books synchronously
                query = data.get('query', '')
                result = self._task_search_sync(query)
                self._send_json(result)

            else:
                self._send_json({"error": f"Unknown path: {self.path}"}, status=404)

        except Exception as e:
            self._send_json({"error": str(e)}, status=500)

    # ======================= TASKS =======================

    def _task_search(self, query, port):
        """Search books across multiple sources."""
        try:
            from book_service import BookService
            service = BookService()
            results = service.search_all(query)
            self._notify_flutter(port, {"status": "search_results", "results": results})
        except Exception as e:
            self._notify_flutter(port, {"status": "error", "message": str(e)})

    def _task_search_sync(self, query):
        """Search books synchronously."""
        try:
            from book_service import BookService
            service = BookService()
            results = service.search_all(query)
            return {"status": "ok", "results": results}
        except Exception as e:
            return {"status": "error", "message": str(e), "results": []}

    def _task_download(self, url, output_path, port, video_id):
        """Download YouTube audio using yt-dlp."""
        try:
            import yt_dlp

            def progress_hook(d):
                if d.get('status') == 'downloading':
                    total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
                    downloaded = d.get('downloaded_bytes', 0)
                    if total > 0:
                        pct = downloaded / total
                        self._notify_flutter(port, {
                            "status": "progress",
                            "videoId": video_id,
                            "progress": round(pct, 2),
                            "message": f"Downloading... {int(pct * 100)}%",
                        })
                elif d.get('status') == 'finished':
                    self._notify_flutter(port, {
                        "status": "progress",
                        "videoId": video_id,
                        "progress": 0.95,
                        "message": "Download complete, processing...",
                    })

            ydl_opts = {
                'format': 'bestaudio[ext=m4a]/bestaudio/best',
                'outtmpl': output_path,
                'quiet': True,
                'no_warnings': True,
                'progress_hooks': [progress_hook],
                'socket_timeout': 30,
                'retries': 3,
                'http_headers': {
                    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
                },
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])

            self._notify_flutter(port, {
                "status": "done",
                "videoId": video_id,
                "message": "Download complete",
            })

        except Exception as e:
            self._notify_flutter(port, {
                "status": "error",
                "videoId": video_id,
                "message": str(e),
            })

    def _task_get_url_sync(self, video_id):
        """Get stream URL for a YouTube video using yt-dlp (synchronous)."""
        try:
            import yt_dlp

            ydl_opts = {
                'format': 'bestaudio[ext=m4a]/bestaudio/best',
                'quiet': True,
                'no_warnings': True,
                'skip_download': True,
                'socket_timeout': 20,
                'nocheckcertificate': True,
                'noplaylist': True,
                'http_headers': {
                    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
                },
            }

            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(
                    f"https://www.youtube.com/watch?v={video_id}",
                    download=False,
                )
                stream_url = info.get('url', '')
                return {"status": "ok", "url": stream_url, "video_id": video_id}

        except Exception as e:
            return {"status": "error", "url": None, "message": str(e)}

    def _task_download_book(self, book_id, url, title, source, port, save_path):
        """Download a book file from a URL."""
        try:
            import requests as req_lib

            # Jika Internet Archive, cari link download yang sebenarnya
            if source == "Internet Archive":
                try:
                    from book_service import BookService
                    service = BookService()
                    resolved_url = service.get_download_link(source, book_id, url)
                    if resolved_url:
                        url = resolved_url
                except:
                    pass

            self._notify_flutter(port, {
                "status": "progress",
                "videoId": book_id,
                "progress": 0.05,
                "message": f"Starting download: {title}",
            })

            # Tentukan folder download
            downloads_dir = save_path
            if not downloads_dir:
                downloads_dir = os.path.join(current_dir, "downloads")
            
            os.makedirs(downloads_dir, exist_ok=True)

            # Tentukan nama file berdasarkan URL
            ext = ".pdf"
            low_url = url.lower()
            if ".epub" in low_url: ext = ".epub"
            elif ".mobi" in low_url: ext = ".mobi"
            elif ".pdf" in low_url: ext = ".pdf"

            safe_title = "".join(c for c in title if c.isalnum() or c in (' ', '-', '_')).strip()
            filename = f"{safe_title}{ext}"
            filepath = os.path.join(downloads_dir, filename)

            # Download file
            response = req_lib.get(url, stream=True, timeout=60, headers={
                'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
            })
            response.raise_for_status()

            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0

            with open(filepath, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
                    downloaded += len(chunk)
                    if total_size > 0:
                        pct = downloaded / total_size
                        self._notify_flutter(port, {
                            "status": "progress",
                            "videoId": book_id,
                            "progress": round(0.1 + pct * 0.85, 2),
                            "message": f"Downloading... {int(pct * 100)}%",
                        })

            self._notify_flutter(port, {
                "status": "done",
                "videoId": book_id,
                "message": "Download complete",
                "filepath": filepath,
            })

        except Exception as e:
            self._notify_flutter(port, {
                "status": "error",
                "videoId": book_id,
                "message": str(e),
            })

    def _task_yt_search_sync(self, query):
        """Search songs on YT Music (synchronous)."""
        try:
            from yt_service import YTMusicService
            service = YTMusicService()
            results = service.search_songs(query)
            return {"status": "ok", "results": results}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def _task_yt_playlist_sync(self, query):
        """Get playlist suggestion on YT Music (synchronous)."""
        try:
            from yt_service import YTMusicService
            service = YTMusicService()
            result = service.get_playlist_suggestions(query)
            if result:
                return {"status": "ok", "playlist": result}
            return {"status": "error", "message": "No playlist found"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # ===================== HELPER =====================

    def _notify_flutter(self, port, payload):
        """Send a JSON payload back to Flutter's progress server."""
        if not port or port == 'None': return
        try:
            req = urllib.request.Request(
                f"http://127.0.0.1:{port}/progress",
                data=json.dumps(payload).encode('utf-8'),
                headers={'Content-Type': 'application/json'},
            )
            with urllib.request.urlopen(req, timeout=5) as r:
                pass
        except:
            pass

# --- STARTUP LOGIC ---
def start_worker():
    print(f"🐍 [Python Worker] Memulai di: {current_dir}")
    print(f"🐍 [Python Worker] DART_PORT Awal: {DART_PORT}")

    try:
        server = HTTPServer(('127.0.0.1', 0), WorkerHandler)
        port = server.server_port
        print(f"🐍 [Python Worker] Server AKTIF di Port: {port}")

        # Laporkan port ke Flutter
        if DART_PORT:
            def handshake():
                time.sleep(1)
                for attempt in range(5):
                    try:
                        print(f"🐍 [Python Worker] Handshake attempt {attempt + 1}...")
                        payload = json.dumps({"status": "worker_ready", "port": port}).encode('utf-8')
                        req = urllib.request.Request(
                            f"http://127.0.0.1:{DART_PORT}/progress",
                            data=payload,
                            headers={'Content-Type': 'application/json'},
                        )
                        with urllib.request.urlopen(req, timeout=5) as r:
                            print("🐍 [Python Worker] Handshake BERHASIL!")
                            return
                    except Exception as e:
                        print(f"🐍 [Python Worker] Handshake attempt {attempt + 1} gagal: {e}")
                        time.sleep(2)
                print("🐍 [Python Worker] Semua handshake attempts gagal.")

            threading.Thread(target=handshake, daemon=True).start()

        server.serve_forever()
    except Exception as e:
        print(f"🐍 [Python FATAL ERROR] {e}")
        time.sleep(5)

if __name__ == "__main__":
    start_worker()
