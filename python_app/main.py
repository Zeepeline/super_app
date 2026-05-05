import os
import sys
import json
import threading
try:
    from http.server import BaseHTTPRequestHandler, HTTPServer, ThreadingHTTPServer
except ImportError:
    from http.server import BaseHTTPRequestHandler, HTTPServer
    ThreadingHTTPServer = HTTPServer 
import requests

# Force unbuffered output for real-time logging
try:
    sys.stdout.reconfigure(line_buffering=True)
except:
    pass

# Add paths for libraries and source
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(current_dir, "site-packages"))
sys.path.append(current_dir)

# Import check for debugging
try:
    import internetarchive as ia
    print("Python Worker: Libraries imported successfully.")
except Exception as e:
    print(f"Python Worker: IMPORT ERROR: {e}")

from book_service import BookService

# Global state
book_service = BookService()
dart_port = os.environ.get("DART_PORT")

class WorkerHandler(BaseHTTPRequestHandler):
    def _send_response(self, data, status=200):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def do_POST(self):
        print(f"Python Worker: Received POST {self.path}")
        try:
            if self.path == '/books/search':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data)
                query = data.get('query', '')
                print(f"Python Worker: Searching books for: {query}")
                results = book_service.search_all(query)
                self._send_response({"results": results})
                
            elif self.path == '/books/download':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data)
                threading.Thread(target=self._download_book_task, args=(data,)).start()
                self._send_response({"status": "download_started"})

            elif self.path == '/get_url':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data)
                video_id = data.get('video_id')
                url = self._get_youtube_url(video_id)
                if url:
                    self._send_response({"url": url})
                else:
                    self._send_response({"error": "Failed to get URL"}, status=400)

            elif self.path == '/download':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data)
                
                # Send response immediately to unblock Flutter
                self._send_response({"status": "ok"})
                
                # Start download in a separate thread
                threading.Thread(target=self._download_youtube_task, args=(data,)).start()

            elif self.path == '/update_dart_port':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data)
                global dart_port
                dart_port = data.get('port')
                print(f"Python Worker: Dart port updated to: {dart_port}")
                self._send_response({"status": "ok"})
            
            else:
                self._send_response({"error": "Not found"}, status=404)
        except Exception as e:
            print(f"Python Worker Error: {e}")
            self._send_response({"error": str(e)}, status=500)

    def _get_youtube_url(self, video_id):
        try:
            import yt_dlp
            url = f"https://www.youtube.com/watch?v={video_id}"
            ydl_opts = {
                'format': 'bestaudio[ext=m4a]/bestaudio/best', # Prefer m4a for iOS/Android compatibility
                'quiet': True,
                'no_warnings': True,
            }
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                return info.get('url')
        except Exception as e:
            print(f"YT-DLP Error getting URL: {e}")
            return None

    def _download_youtube_task(self, data):
        url = data.get('url')
        output_path = data.get('output_path')
        video_id = data.get('video_id')
        
        print(f"Python Worker: Starting YT download for {video_id}")
        print(f"Python Worker: Destination: {output_path}")

        try:
            import yt_dlp
            
            def progress_hook(d):
                if d['status'] == 'downloading':
                    p_str = d.get('_percent_str', '0%').replace('%', '').strip()
                    try:
                        progress = float(p_str) / 100
                        print(f"Python Worker: Progress {video_id} -> {p_str}%")
                        self._notify_dart_progress(video_id, "downloading", progress)
                    except: pass
                elif d['status'] == 'finished':
                    print(f"Python Worker: Finished downloading {video_id}, now processing...")
                    self._notify_dart_progress(video_id, "processing", 0.95)

            ydl_opts = {
                'format': 'bestaudio[ext=m4a]/bestaudio/best',
                'outtmpl': output_path,
                'progress_hooks': [progress_hook],
                'quiet': False, # Set to False for better debugging in logs
                'no_warnings': False,
                'nocheckcertificate': True,
            }
            
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                print(f"Python Worker: Calling ydl.download for {url}")
                ydl.download([url])
                
            print(f"Python Worker: YT Download task COMPLETED for {video_id}")
            self._notify_dart_progress(video_id, "done", 1.0)
        except Exception as e:
            error_msg = f"YT-DLP Download Fatal Error: {str(e)}"
            print(f"Python Worker: {error_msg}")
            self._notify_dart_progress(video_id, "error", 0, error=error_msg)

    def _download_book_task(self, data):
        url = data.get('url')
        book_id = data.get('id')
        title = data.get('title', 'Unknown Book')
        author = data.get('author', 'Unknown Author')
        ext = data.get('format', 'pdf').lower()
        if '/' in ext: ext = ext.split('/')[-1]
        source = data.get('source', 'Unknown')
        
        # Get actual direct download link
        url = book_service.get_download_link(source, book_id, url)
        
        filename = f"{title} - {author}.{ext}".replace('/', '_')
        save_dir = os.path.join(os.path.expanduser('~'), 'Documents', 'SoundWave', 'Books')
        os.makedirs(save_dir, exist_ok=True)
        save_path = os.path.join(save_dir, filename)

        print(f"Python Worker: Downloading {title} to {save_path}...")
        
        try:
            # Notify Dart that download is starting
            self._notify_dart_progress(book_id, "downloading", 0)
            
            response = requests.get(url, stream=True, timeout=30)
            total_size = int(response.headers.get('content-length', 0))
            
            with open(save_path, 'wb') as f:
                if total_size == 0:
                    f.write(response.content)
                else:
                    downloaded = 0
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            downloaded += len(chunk)
                            # Notify progress every 10%
                            # self._notify_dart_progress(book_id, "downloading", int(downloaded/total_size*100))

            print(f"Python Worker: Download finished: {save_path}")
            self._notify_dart_progress(book_id, "done", 100, save_path=save_path)
            
        except Exception as e:
            print(f"Python Worker Download Error: {e}")
            self._notify_dart_progress(book_id, "error", 0, error=str(e))

    def _notify_dart_progress(self, task_id, status, progress, save_path=None, error=None):
        global dart_port
        if dart_port:
            try:
                payload = {
                    "videoId": task_id,
                    "status": status,
                    "progress": progress,
                    "save_path": save_path,
                    "error": error
                }
                print(f"Python Worker: Notifying Dart (Port {dart_port}) -> Status: {status}, Progress: {progress}")
                resp = requests.post(
                    f"http://127.0.0.1:{dart_port}/progress", 
                    json=payload, 
                    timeout=2
                )
                if resp.status_code != 200:
                    print(f"Python Worker: Dart returned status {resp.status_code}")
            except Exception as e:
                print(f"Python Worker: Failed to notify Dart: {e}")
        else:
            print("Python Worker: Cannot notify Dart - dart_port is NOT set!")

    def do_GET(self):
        if self.path == '/status':
            self._send_response({"status": "ok", "worker": "ready", "dart_port": dart_port})
        else:
            self._send_response({"error": "Not found"}, status=404)

def notify_dart_ready(port):
    global dart_port
    print(f"Python Worker: Initializing handshake. Dart Port: {dart_port}")
    if dart_port:
        try:
            resp = requests.post(
                f"http://127.0.0.1:{dart_port}/progress",
                json={"status": "worker_ready", "port": port},
                timeout=5
            )
            print(f"Python Worker: Handshake sent. Response: {resp.status_code}")
        except Exception as e:
            print(f"Python Worker: Handshake failed: {e}")
    else:
        print("Python Worker: DART_PORT not set during startup.")

def run(server_class=ThreadingHTTPServer, handler_class=WorkerHandler, port=9000):
    while port < 9100:
        try:
            server_address = ('127.0.0.1', port)
            httpd = server_class(server_address, handler_class)
            print(f"--- Python Worker started on http://127.0.0.1:{port} ---")
            threading.Thread(target=notify_dart_ready, args=(port,)).start()
            httpd.serve_forever()
            break
        except OSError:
            port += 1

if __name__ == "__main__":
    run()
