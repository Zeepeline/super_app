# SoundWave Python Worker API Documentation

This worker acts as a background service for the SoundWave Flutter app. It handles heavy lifting like book searching, YouTube stream extraction, and media downloading.

## Base URL
The worker dynamically binds to a port starting from `9000`. Check the Flutter logs for `--- Python Worker started on http://127.0.0.1:XXXX ---`.

---

## Endpoints

### 1. Status Check
Check if the worker is alive and ready.
- **Method:** `GET`
- **Path:** `/status`
- **Response:**
  ```json
  {
    "status": "ok",
    "worker": "ready"
  }
  ```

### 2. Book Search
Search for books across multiple sources (Internet Archive, Project Gutenberg).
- **Method:** `POST`
- **Path:** `/books/search`
- **Body:**
  ```json
  {
    "query": "string (e.g., 'Digital Minimalism')"
  }
  ```
- **Response:**
  ```json
  {
    "results": [
      {
        "source": "Internet Archive",
        "id": "item_id",
        "title": "Book Title",
        "author": "Author Name",
        "format": "EPUB/PDF",
        "cover_url": "https://...",
        "mirror": "https://..."
      }
    ]
  }
  ```

### 3. YouTube Stream Extractor
Get a direct audio streaming URL for a YouTube video.
- **Method:** `POST`
- **Path:** `/get_url`
- **Body:**
  ```json
  {
    "video_id": "string (e.g., 'dQw4w9WgXcQ')"
  }
  ```
- **Response:**
  ```json
  {
    "url": "https://rr1---sn-..."
  }
  ```

### 4. YouTube Audio Download
Download and convert YouTube video to M4A audio.
- **Method:** `POST`
- **Path:** `/download`
- **Body:**
  ```json
  {
    "url": "https://www.youtube.com/watch?v=...",
    "output_path": "absolute_path_on_device",
    "video_id": "taskId_for_progress_tracking"
  }
  ```
- **Description:** This starts a background thread. Progress is sent to the `DART_PORT` provided during worker startup.

### 5. Update Dart Port
Update the port used to notify the Flutter app about task progress.
- **Method:** `POST`
- **Path:** `/update_dart_port`
- **Body:**
  ```json
  {
    "port": 1234
  }
  ```

---

## Architecture Note
This API is built using Python's native `http.server` to keep the dependency footprint minimal for mobile deployment. It leverages `yt-dlp` for media extraction and `requests` for communication.
