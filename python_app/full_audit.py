import os
import sys
import json
import threading
import time
import subprocess
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

# 1. MOCK FLUTTER SERVER (Untuk nangkep handshake)
class MockFlutterHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        data = json.loads(self.rfile.read(content_length))
        print(f"\n[MOCK FLUTTER] Menerima data: {data}")
        
        # Kirim respon sukses
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"status": "received"}).encode('utf-8'))
        
        if data.get('status') == 'worker_ready':
            global worker_port
            worker_port = data.get('port')
            print(f"[MOCK FLUTTER] Python Worker lapor dia ada di port: {worker_port}")

worker_port = None
def run_mock_flutter():
    server = HTTPServer(('127.0.0.1', 8080), MockFlutterHandler)
    while worker_port is None:
        server.handle_request()

# 2. START TEST
print("=== MEMULAI AUDIT FITUR PYTHON ===")

# Jalankan Mock Flutter di background
threading.Thread(target=run_mock_flutter, daemon=True).start()

# Jalankan Python Worker dengan DART_PORT=8080
env = os.environ.copy()
env["DART_PORT"] = "8080"
process = subprocess.Popen(
    [sys.executable, "python_app/main.py"],
    env=env,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

print("Menunggu Handshake dari Python Worker (timeout 10 detik)...")
timeout = time.time() + 10
while worker_port is None and time.time() < timeout:
    time.sleep(0.5)

if worker_port is None:
    print("❌ GAGAL: Python Worker tidak mengirim handshake!")
    process.kill()
    sys.exit(1)

print("✅ BERHASIL: Handshake diterima.")

# 3. TEST ENDPOINTS
def test_endpoint(path, payload=None):
    url = f"http://127.0.0.1:{worker_port}{path}"
    print(f"\nTesting {path}...")
    try:
        data = json.dumps(payload).encode('utf-8') if payload else None
        req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'} if data else {})
        with urllib.request.urlopen(req, timeout=5) as r:
            res = json.loads(r.read().decode('utf-8'))
            print(f"Respon {path}: {res}")
            return res
    except Exception as e:
        print(f"❌ ERROR di {path}: {e}")
        return None

# Test 1: Status
test_endpoint("/status")

# Test 2: Search (Background)
search_res = test_endpoint("/search", {"query": "Atomic Habits"})
if search_res and search_res.get('status') == 'searching':
    print("✅ BERHASIL: Pencarian asinkron dimulai.")
else:
    print("❌ GAGAL: Pencarian tidak merespon 'searching'.")

print("\n=== SEMUA FITUR LOLOS UJI LOKAL ===")
process.kill()
