import os
import sys
import json
import urllib.request
import traceback
import time
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

# Global state
active_downloads = {}
dart_port = None

def send_to_dart(port, data):
    global dart_port
    target_port = port or dart_port
    if not target_port: return
    url = f"http://127.0.0.1:{target_port}/progress"
    req = urllib.request.Request(
        url, 
        data=json.dumps(data).encode("utf-8"), 
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=2) as response:
            return response.read()
    except: pass

def my_hook(d, port, video_id):
    if d['status'] == 'downloading':
        total = d.get('total_bytes') or d.get('total_bytes_estimate')
        if total:
            downloaded = d.get('downloaded_bytes', 0)
            progress = downloaded / total
            send_to_dart(port, {
                "videoId": video_id,
                "progress": progress,
                "status": "downloading"
            })
    elif d['status'] == 'finished':
        send_to_dart(port, {
            "videoId": video_id,
            "progress": 1.0,
            "status": "processing"
        })

def download_task(url, output_path, port, video_id):
    try:
        import yt_dlp
        
        ydl_opts = {
            # Format 140 is the standard YouTube AAC m4a audio
            'format': '140/bestaudio[ext=m4a]/bestaudio', 
            'outtmpl': output_path,
            'progress_hooks': [lambda d: my_hook(d, port, video_id)],
            'quiet': True,
            'no_warnings': True,
            'nocheckcertificate': True,
            'noplaylist': True,
            'headers': {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            }
        }

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
            
        send_to_dart(port, {
            "videoId": video_id,
            "progress": 1.0,
            "status": "done"
        })
    except Exception as e:
        send_to_dart(port, {
            "videoId": video_id,
            "progress": 0.0,
            "status": "error",
            "error": traceback.format_exc()
        })

class CommandHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/status':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok", "version": "1.0.1"}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/update_dart_port':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            params = json.loads(post_data)
            new_port = params.get('port')
            if new_port:
                global dart_port
                dart_port = str(new_port)
                print(f"Python Worker: Updated Dart port to {dart_port}")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")
        elif self.path == '/download':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            params = json.loads(post_data)
            
            url = params.get('url')
            output_path = params.get('output_path')
            port = params.get('port')
            video_id = params.get('video_id')
            
            # Start download in a separate thread
            thread = threading.Thread(
                target=download_task, 
                args=(url, output_path, port, video_id)
            )
            thread.start()
            
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")
        elif self.path == '/get_url':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            params = json.loads(post_data)
            
            video_id = params.get('video_id')
            url = f"https://www.youtube.com/watch?v={video_id}"
            
            try:
                import yt_dlp
                ydl_opts = {
                    'format': '140/bestaudio[ext=m4a]/bestaudio',
                    'quiet': True,
                    'no_warnings': True,
                    'nocheckcertificate': True,
                    'noplaylist': True,
                }
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    info = ydl.extract_info(url, download=False)
                    stream_url = info.get('url')
                    
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"url": stream_url}).encode('utf-8'))
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        return # keep it quiet

def main():
    global dart_port
    # Use a dynamic port for the Python worker to avoid 'Address already in use' errors
    server = HTTPServer(('127.0.0.1', 0), CommandHandler)
    worker_port = server.server_port
    
    # Send "Ready" message to Dart with the assigned port
    env_dart_port = os.environ.get("DART_PORT")
    if env_dart_port:
        dart_port = env_dart_port
        send_to_dart(dart_port, {"status": "worker_ready", "port": worker_port})

    print(f"Python Worker starting on port {worker_port}...")
    server.serve_forever()

if __name__ == "__main__":
    main()
