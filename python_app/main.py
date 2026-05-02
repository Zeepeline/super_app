"""
main.py — Entry point for the SoundWave Python Backend.
Runs Flask as a background thread inside Serious Python.

Features:
- RAG system (ChromaDB + Gemini Embedding)
- yt-dlp download & streaming
- RESTful API on dynamic port
"""

import os
import sys
import json
import logging
import threading
import traceback
import urllib.request
from logging.handlers import RotatingFileHandler

# ========== SETUP LOGGING ==========
try:
    import config
    os.makedirs(config.LOGS_DIR, exist_ok=True)
    handler = RotatingFileHandler(
        config.LOG_FILE,
        maxBytes=config.LOG_MAX_BYTES,
        backupCount=config.LOG_BACKUP_COUNT,
    )
    handler.setFormatter(logging.Formatter(config.LOG_FORMAT))
    logging.basicConfig(level=logging.INFO, handlers=[handler])
except Exception:
    logging.basicConfig(level=logging.INFO)

logger = logging.getLogger("main")

# ========== GLOBAL STATE ==========
dart_port = None


def send_to_dart(port, data):
    """Send data back to Flutter via HTTP POST."""
    global dart_port
    target_port = port or dart_port
    if not target_port:
        return
    url = f"http://127.0.0.1:{target_port}/progress"
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=2) as response:
            return response.read()
    except Exception:
        pass


# ========== YT-DLP FUNCTIONS (preserved from original) ==========
def my_hook(d, port, video_id):
    if d["status"] == "downloading":
        total = d.get("total_bytes") or d.get("total_bytes_estimate")
        if total:
            downloaded = d.get("downloaded_bytes", 0)
            progress = downloaded / total
            send_to_dart(
                port,
                {"videoId": video_id, "progress": progress, "status": "downloading"},
            )
    elif d["status"] == "finished":
        send_to_dart(
            port,
            {"videoId": video_id, "progress": 1.0, "status": "processing"},
        )


def download_task(url, output_path, port, video_id):
    try:
        import yt_dlp

        ydl_opts = {
            "format": "140/bestaudio[ext=m4a]/bestaudio",
            "outtmpl": output_path,
            "progress_hooks": [lambda d: my_hook(d, port, video_id)],
            "quiet": True,
            "no_warnings": True,
            "nocheckcertificate": True,
            "noplaylist": True,
            "headers": {
                "User-Agent": (
                    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                    "AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/120.0.0.0 Safari/537.36"
                ),
            },
        }

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])

        send_to_dart(
            port, {"videoId": video_id, "progress": 1.0, "status": "done"}
        )
    except Exception:
        send_to_dart(
            port,
            {
                "videoId": video_id,
                "progress": 0.0,
                "status": "error",
                "error": traceback.format_exc(),
            },
        )


# ========== FLASK APP ==========
def create_app():
    """Create and configure the Flask application."""
    try:
        from flask import Flask, request, jsonify
    except ImportError:
        logger.error("Flask not installed, falling back to basic server")
        return None

    app = Flask(__name__)
    app.config["JSON_AS_ASCII"] = False

    # Register RAG blueprints
    try:
        from modules.health import bp as health_bp
        from modules.indexer import bp as indexer_bp
        from modules.rag import bp as rag_bp

        app.register_blueprint(health_bp)
        app.register_blueprint(indexer_bp)
        app.register_blueprint(rag_bp)
        logger.info("RAG modules registered")
    except Exception as e:
        logger.warning(f"Could not register RAG modules: {e}")

    # ========== YT-DLP ENDPOINTS ==========
    @app.route("/status", methods=["GET"])
    def yt_status():
        return jsonify({"status": "ok", "version": "2.0.0"}), 200

    @app.route("/update_dart_port", methods=["POST"])
    def update_dart_port_endpoint():
        global dart_port
        data = request.get_json(silent=True)
        if data and data.get("port"):
            dart_port = str(data["port"])
            logger.info(f"Updated Dart port to {dart_port}")
        return "OK", 200

    @app.route("/download", methods=["POST"])
    def download():
        data = request.get_json(silent=True)
        if not data:
            return "Bad request", 400

        url = data.get("url")
        output_path = data.get("output_path")
        port = data.get("port")
        video_id = data.get("video_id")

        thread = threading.Thread(
            target=download_task, args=(url, output_path, port, video_id)
        )
        thread.start()
        return "OK", 200

    @app.route("/get_url", methods=["POST"])
    def get_url():
        data = request.get_json(silent=True)
        if not data:
            return "Bad request", 400

        video_id = data.get("video_id")
        url = f"https://www.youtube.com/watch?v={video_id}"

        try:
            import yt_dlp

            ydl_opts = {
                "format": "140/bestaudio[ext=m4a]/bestaudio",
                "quiet": True,
                "no_warnings": True,
                "nocheckcertificate": True,
                "noplaylist": True,
            }
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                stream_url = info.get("url")

            return jsonify({"url": stream_url}), 200
        except Exception as e:
            return str(e), 500

    # ========== SETUP ENDPOINTS ==========
    @app.route("/setup/download_stopwords", methods=["POST"])
    def setup_stopwords():
        try:
            from modules import enricher
            success = enricher.download_stopwords()
            if success:
                return jsonify({"status": "ok", "message": "Stopwords updated"}), 200
            return jsonify({"status": "error", "message": "Download failed"}), 500
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 500

    @app.route("/setup/status", methods=["GET"])
    def setup_status():
        checks = {
            "stopwords_file": os.path.exists(config.STOPWORDS_FILE),
            "abbreviations_file": os.path.exists(config.ABBREVIATIONS_FILE),
            "chroma_dir": os.path.exists(config.CHROMA_DIR),
            "gemini_key_set": bool(os.environ.get(config.GEMINI_API_KEY_ENV)),
        }
        all_ok = all(checks.values())
        return jsonify({
            "status": "ok" if all_ok else "incomplete",
            "data": checks,
        }), 200

    # Suppress Flask request logging
    log = logging.getLogger("werkzeug")
    log.setLevel(logging.WARNING)

    return app


# ========== MAIN ==========
def main():
    global dart_port

    env_dart_port = os.environ.get("DART_PORT")
    if env_dart_port:
        dart_port = env_dart_port

    # Pass Gemini API key from env (Flutter sets this)
    gemini_key = os.environ.get("GEMINI_API_KEY", "")
    if gemini_key:
        logger.info("Gemini API key found in environment")

    # Try Flask first
    app = create_app()

    if app:
        # Initialize RAG modules
        try:
            from modules import db_manager, preprocessor, scheduler

            # Init ChromaDB
            db_manager.get_collection()

            # Load stopwords
            preprocessor.load_stopwords()

            # Start background scheduler
            scheduler.start()

            logger.info("RAG system initialized")
        except Exception as e:
            logger.warning(f"RAG init warning (non-fatal): {e}")

        # Start Flask on dynamic port
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.bind(("127.0.0.1", 0))
        worker_port = sock.getsockname()[1]
        sock.close()

        # Notify Dart
        if dart_port:
            send_to_dart(dart_port, {"status": "worker_ready", "port": worker_port})

        logger.info(f"Flask server starting on port {worker_port}")

        # Run Flask (threaded for concurrent requests)
        app.run(
            host="127.0.0.1",
            port=worker_port,
            threaded=True,
            use_reloader=False,
        )
    else:
        # Fallback: basic HTTP server (if Flask not available)
        logger.warning("Flask unavailable, using fallback HTTP server")
        _run_fallback_server()


def _run_fallback_server():
    """Minimal HTTP server fallback if Flask is not installed."""
    from http.server import BaseHTTPRequestHandler, HTTPServer

    class FallbackHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/status":
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(
                    json.dumps({"status": "ok", "version": "2.0.0-fallback"}).encode()
                )
            else:
                self.send_response(404)
                self.end_headers()

        def do_POST(self):
            content_length = int(self.headers.get("Content-Length", 0))
            post_data = self.rfile.read(content_length) if content_length else b""

            if self.path == "/update_dart_port":
                global dart_port
                params = json.loads(post_data)
                dart_port = str(params.get("port", ""))
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK")

            elif self.path == "/download":
                params = json.loads(post_data)
                thread = threading.Thread(
                    target=download_task,
                    args=(
                        params.get("url"),
                        params.get("output_path"),
                        params.get("port"),
                        params.get("video_id"),
                    ),
                )
                thread.start()
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK")
            else:
                self.send_response(404)
                self.end_headers()

        def log_message(self, format, *args):
            return

    server = HTTPServer(("127.0.0.1", 0), FallbackHandler)
    worker_port = server.server_port

    if dart_port:
        send_to_dart(dart_port, {"status": "worker_ready", "port": worker_port})

    logger.info(f"Fallback server on port {worker_port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
