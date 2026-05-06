import os
import sys
import json
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

# Try to get ThreadingHTTPServer (Python 3.7+)
try:
    from http.server import ThreadingHTTPServer
except ImportError:
    ThreadingHTTPServer = HTTPServer

# Use urllib as fallback for logging to avoid dependency issues on startup
import urllib.request
import urllib.error

# Add paths for libraries and source
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(current_dir, "site-packages"))
sys.path.append(current_dir)

dart_port = os.environ.get("DART_PORT")

def log_to_dart(message):
    """Relays logs to Dart console via urllib (standard library)"""
    print(f"Python Worker: {message}")
    if not dart_port:
        return
    try:
        payload = json.dumps({
            "status": "log",
            "message": f"🐍 [Python Worker] {message}"
        }).encode('utf-8')
        
        req = urllib.request.Request(
            f"http://127.0.0.1:{dart_port}/progress",
            data=payload,
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req, timeout=1) as response:
            pass
    except:
        pass

log_to_dart("Process started. Checking libraries...")

# Now safe to try importing heavy dependencies
try:
    import requests
    log_to_dart("Library 'requests' loaded.")
except ImportError:
    log_to_dart("CRITICAL: 'requests' library NOT FOUND in site-packages!")

# Pre-define classes to avoid NameError if import fails
BookService = None
AudiobookService = None

try:
    log_to_dart("Importing book_service...")
    from book_service import BookService
except Exception as e:
    log_to_dart(f"ERROR importing book_service: {e}")

try:
    log_to_dart("Importing audiobook_service...")
    from audiobook_service import AudiobookService
except Exception as e:
    log_to_dart(f"ERROR importing audiobook_service: {e}")

# Global state
log_to_dart("Initializing global services...")
book_service = BookService() if BookService else None
audiobook_service = AudiobookService() if AudiobookService else None
log_to_dart("Global services ready.")

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
                log_to_dart(f"Searching books for: {query}")
                
                if not book_service:
                    self._send_response({"error": "BookService is not available (Import failed)"}, status=503)
                    return
                    
                results = book_service.search_all(query)
                self._send_response({"results": results})
                
            elif self.path == '/books/download':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data)
                
                if not book_service:
                    self._send_response({"error": "BookService is not available"}, status=503)
                    return
                    
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
            
            elif self.path == '/audiobook/info':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data)
                pdf_path = data.get('path')
                
                if not audiobook_service:
                    self._send_response({"error": "AudiobookService is not available (Import failed)"}, status=503)
                    return
                    
                info = audiobook_service.get_pdf_metadata(pdf_path)
                self._send_response(info)

            elif self.path == '/audiobook/read_page':
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data)
                
                if not audiobook_service:
                    self._send_response({"error": "AudiobookService is not available (Import failed)"}, status=503)
                    return
                    
                pdf_path = data.get('path')
                page_num = data.get('page', 0)
                voice = data.get('voice', 'id-ID-ArdiNeural')
                
                # 1. Extract text
                text = audiobook_service.extract_text(pdf_path, page_num)
                if not text:
                    self._send_response({"error": "No text found on this page"}, status=400)
                    return
                
                # 2. Generate Audio
                filename = f"page_{page_num}_{os.path.basename(pdf_path)}.mp3"
                audio_path = audiobook_service.process_page_sync(text, filename, voice)
                
                if audio_path:
                    self._send_response({
                        "audio_path": audio_path,
                        "text": text[:200] + "..." # Return preview of text
                    })
                else:
                    self._send_response({"error": "Failed to generate speech"}, status=500)
            
            else:
                self._send_response({"error": "Not found"}, status=404)
        except Exception as e:
            print(f"Python Worker Error: {e}")
            self._send_response({"error": str(e)}, status=500)

    def _get_youtube_url(self, video_id):
        try:
            import yt_dlp
            url = f"https://www.youtube.com/watch?v={video_id}"
            log_to_dart(f"Strategy 2: Python Worker fetching URL for {video_id}...")
            ydl_opts = {
                'format': 'bestaudio[ext=m4a]/bestaudio/best',
                'quiet': True,
                'no_warnings': True,
                'nocheckcertificate': True,
                'user_agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Mobile/15E148 Safari/604.1',
            }
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                final_url = info.get('url')
                if final_url:
                    log_to_dart(f"Strategy 2 SUCCESS: Found URL for {video_id}")
                return final_url
        except Exception as e:
            log_to_dart(f"Strategy 2 FAILED (yt-dlp error): {e}")
            return None

    def _download_youtube_task(self, data):
        url = data.get('url')
        output_path = data.get('output_path')
        video_id = data.get('video_id')
        
        log_to_dart(f"Starting YouTube download for {video_id}")
        log_to_dart(f"Destination: {output_path}")

        try:
            import yt_dlp
            
            def progress_hook(d):
                if d['status'] == 'downloading':
                    p_str = d.get('_percent_str', '0%').replace('%', '').strip()
                    try:
                        progress = float(p_str) / 100
                        # Only log every 20% to avoid flooding
                        if int(float(p_str)) % 20 == 0:
                            log_to_dart(f"Download Progress {video_id}: {p_str}%")
                        self._notify_dart_progress(video_id, "downloading", progress)
                    except: pass
                elif d['status'] == 'finished':
                    log_to_dart(f"Finished downloading {video_id}, now processing...")
                    self._notify_dart_progress(video_id, "processing", 0.95)

            ydl_opts = {
                'format': 'bestaudio[ext=m4a]/bestaudio/best',
                'outtmpl': output_path,
                'progress_hooks': [progress_hook],
                'quiet': True,
                'no_warnings': True,
                'nocheckcertificate': True,
            }
            
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
                
            log_to_dart(f"YouTube Download COMPLETED for {video_id}")
            self._notify_dart_progress(video_id, "done", 1.0)
        except Exception as e:
            error_msg = f"YT-DLP Download Fatal Error: {str(e)}"
            log_to_dart(error_msg)
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
        if dart_port:
            try:
                payload = json.dumps({
                    "videoId": task_id,
                    "status": status,
                    "progress": progress,
                    "save_path": save_path,
                    "error": error
                }).encode('utf-8')
                
                req = urllib.request.Request(
                    f"http://127.0.0.1:{dart_port}/progress",
                    data=payload,
                    headers={'Content-Type': 'application/json'}
                )
                with urllib.request.urlopen(req, timeout=2) as response:
                    if response.status != 200:
                        log_to_dart(f"Dart returned status {response.status}")
            except Exception as e:
                log_to_dart(f"Failed to notify Dart: {e}")
        else:
            log_to_dart("Cannot notify Dart - dart_port is NOT set!")

    def do_GET(self):
        if self.path == '/status':
            self._send_response({"status": "ok", "worker": "ready", "dart_port": dart_port})
        else:
            self._send_response({"error": "Not found"}, status=404)

def notify_dart_ready(port):
    log_to_dart(f"Initializing handshake. Dart Port: {dart_port}")
    if dart_port:
        try:
            payload = json.dumps({
                "status": "worker_ready", 
                "port": port
            }).encode('utf-8')
            
            req = urllib.request.Request(
                f"http://127.0.0.1:{dart_port}/progress",
                data=payload,
                headers={'Content-Type': 'application/json'}
            )
            with urllib.request.urlopen(req, timeout=5) as response:
                log_to_dart(f"Handshake sent. Response: {response.status}")
        except Exception as e:
            log_to_dart(f"Handshake failed: {e}")
    else:
        log_to_dart("DART_PORT not set during startup.")

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
    try:
        run()
    except Exception as e:
        log_to_dart(f"FATAL STARTUP ERROR: {e}")
        # Final attempt to print to stderr if logging fails
        sys.stderr.write(f"FATAL: {e}\n")
