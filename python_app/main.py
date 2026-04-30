import os
import sys
import json
import urllib.request
import traceback
import time
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

# Global state to track downloads
active_downloads = {}

def send_to_dart(port, data):
    if not port: return
    url = f"http://127.0.0.1:{port}/progress"
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
    def do_POST(self):
        if self.path == '/download':
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
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        return # keep it quiet

def main():
    # Use a fixed port for the Python worker
    worker_port = 9000
    
    # Send "Ready" message to Dart if port was passed in env
    dart_port = os.environ.get("DART_PORT")
    if dart_port:
        send_to_dart(dart_port, {"status": "worker_ready", "port": worker_port})

    print(f"Python Worker starting on port {worker_port}...")
    server = HTTPServer(('127.0.0.1', worker_port), CommandHandler)
    server.serve_forever()

if __name__ == "__main__":
    main()
