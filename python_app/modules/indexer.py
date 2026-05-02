"""
indexer.py — Flask blueprint for indexing documents into ChromaDB.
Supports all document types: music, book, todo, note, journal, mood.
Auto-enriches music and book entries from external APIs.
"""

import logging
import threading

from flask import Blueprint, request, jsonify

from modules import db_manager, gemini_client, preprocessor, enricher

logger = logging.getLogger("indexer")

bp = Blueprint("indexer", __name__, url_prefix="/index")


def _validate_json(required_fields):
    """Validate incoming JSON request."""
    data = request.get_json(silent=True)
    if not data:
        return None, jsonify({"status": "error", "message": "Invalid JSON", "code": "ERR_INVALID_JSON"}), 400

    missing = [f for f in required_fields if f not in data]
    if missing:
        return None, jsonify({
            "status": "error",
            "message": f"Missing fields: {', '.join(missing)}",
            "code": "ERR_MISSING_FIELD",
        }), 400

    return data, None, None


def _build_text(parts):
    """Build a single text from multiple parts for embedding."""
    return " | ".join(str(p) for p in parts if p)


def _index_document(source_type, text, metadata):
    """Core indexing logic: preprocess → embed → store."""
    # Preprocess
    lang = metadata.get("language", "id")
    do_chunk = source_type in ("note", "journal", "book")
    chunks = preprocessor.preprocess(text, lang=lang, do_chunk=do_chunk)

    if not chunks:
        return {"status": "error", "message": "Empty text after preprocessing", "code": "ERR_EMPTY_TEXT"}

    indexed_ids = []

    for i, chunk in enumerate(chunks):
        # Embed
        embedding = gemini_client.embed_text(chunk)
        if embedding is None:
            logger.warning(f"Embedding failed for chunk {i}")
            continue

        # Generate ID
        doc_id = metadata.get("doc_id") or db_manager.generate_doc_id()
        if len(chunks) > 1:
            doc_id = f"{doc_id}_chunk_{i}"

        # Store
        meta = {**metadata, "chunk_index": i, "total_chunks": len(chunks)}
        success = db_manager.upsert_document(
            doc_id=doc_id,
            text=chunk,
            embedding=embedding,
            source_type=source_type,
            metadata=meta,
        )

        if success:
            indexed_ids.append(doc_id)

    if indexed_ids:
        return {"status": "ok", "data": {"doc_ids": indexed_ids, "chunks": len(indexed_ids)}}
    else:
        return {"status": "error", "message": "Failed to index", "code": "ERR_INDEX_FAILED"}


# ========== ENDPOINTS ==========

@bp.route("/music", methods=["POST"])
def index_music():
    """Index a music track (+ auto-enrich from MusicBrainz/iTunes)."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    title = data.get("title", "")
    artist = data.get("artist", "")
    if not title:
        return jsonify({"status": "error", "message": "title is required"}), 400

    # Build rich text for embedding
    parts = [
        f"Judul: {title}",
        f"Artis: {artist}" if artist else "",
        f"Album: {data.get('album', '')}" if data.get("album") else "",
        f"Genre: {data.get('genre', '')}" if data.get("genre") else "",
        f"Tahun: {data.get('year', '')}" if data.get("year") else "",
        f"Mood: {data.get('mood', '')}" if data.get("mood") else "",
        f"Catatan: {data.get('notes', '')}" if data.get("notes") else "",
    ]

    # Auto-enrich in background (don't block response)
    enriched_data = {}
    try:
        enriched_data = enricher.enrich_music(title, artist) or {}
        if enriched_data:
            # Add enriched info to text
            if enriched_data.get("genre"):
                parts.append(f"Genre (enriched): {enriched_data['genre']}")
            if enriched_data.get("year"):
                parts.append(f"Tahun (enriched): {enriched_data['year']}")
    except Exception as e:
        logger.warning(f"Enrichment skipped for {title}: {e}")

    text = _build_text(parts)
    metadata = {
        "doc_id": data.get("id") or db_manager.generate_doc_id(),
        "title": title,
        "author_or_artist": artist,
        "genre": enriched_data.get("genre", data.get("genre", "")),
        "tags": data.get("tags", ""),
        "language": data.get("language", "mixed"),
        "enriched": "true" if enriched_data else "false",
    }

    result = _index_document("music", text, metadata)
    return jsonify(result), 200 if result["status"] == "ok" else 500


@bp.route("/book", methods=["POST"])
def index_book():
    """Index a book (+ auto-enrich from OpenLibrary/Google Books)."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    title = data.get("title", "")
    author = data.get("author", "")
    if not title:
        return jsonify({"status": "error", "message": "title is required"}), 400

    parts = [
        f"Judul Buku: {title}",
        f"Penulis: {author}" if author else "",
        f"Genre: {data.get('genre', '')}" if data.get("genre") else "",
        f"Sinopsis: {data.get('synopsis', '')}" if data.get("synopsis") else "",
        f"Status: {data.get('status', '')}" if data.get("status") else "",
        f"Rating: {data.get('rating', '')}" if data.get("rating") else "",
        f"Review: {data.get('review', '')}" if data.get("review") else "",
    ]

    # Auto-enrich
    enriched_data = {}
    try:
        enriched_data = enricher.enrich_book(title, author) or {}
        if enriched_data:
            desc = enriched_data.get("description_gb") or enriched_data.get("description_ol", "")
            if desc:
                parts.append(f"Deskripsi (enriched): {desc}")
            if enriched_data.get("subjects"):
                parts.append(f"Subjek: {enriched_data['subjects']}")
    except Exception as e:
        logger.warning(f"Book enrichment skipped for {title}: {e}")

    text = _build_text(parts)
    metadata = {
        "doc_id": data.get("id") or db_manager.generate_doc_id(),
        "title": title,
        "author_or_artist": author,
        "genre": data.get("genre", ""),
        "status": data.get("status", ""),
        "rating": data.get("rating", ""),
        "language": data.get("language", "id"),
        "enriched": "true" if enriched_data else "false",
    }

    result = _index_document("book", text, metadata)
    return jsonify(result), 200 if result["status"] == "ok" else 500


@bp.route("/todo", methods=["POST"])
def index_todo():
    """Index a todo/task."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    title = data.get("title", "")
    if not title:
        return jsonify({"status": "error", "message": "title is required"}), 400

    parts = [
        f"Task: {title}",
        f"Deskripsi: {data.get('description', '')}" if data.get("description") else "",
        f"Kategori: {data.get('category', '')}" if data.get("category") else "",
        f"Prioritas: {data.get('priority', '')}" if data.get("priority") else "",
        f"Status: {data.get('status', 'pending')}",
        f"Due: {data.get('due_date', '')}" if data.get("due_date") else "",
        f"Catatan: {data.get('notes', '')}" if data.get("notes") else "",
    ]

    text = _build_text(parts)
    metadata = {
        "doc_id": data.get("id") or db_manager.generate_doc_id(),
        "title": title,
        "tags": data.get("tags", ""),
        "status": data.get("status", "pending"),
        "date_ref": data.get("due_date", ""),
        "language": "id",
    }

    result = _index_document("todo", text, metadata)
    return jsonify(result), 200 if result["status"] == "ok" else 500


@bp.route("/note", methods=["POST"])
def index_note():
    """Index a note."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    text = data.get("content", data.get("text", ""))
    if not text:
        return jsonify({"status": "error", "message": "content is required"}), 400

    title = data.get("title", text[:50])
    parts = [
        f"Catatan: {title}",
        text,
    ]

    metadata = {
        "doc_id": data.get("id") or db_manager.generate_doc_id(),
        "title": title,
        "tags": data.get("tags", ""),
        "language": data.get("language", "id"),
    }

    result = _index_document("note", _build_text(parts), metadata)
    return jsonify(result), 200 if result["status"] == "ok" else 500


@bp.route("/journal", methods=["POST"])
def index_journal():
    """Index a journal entry."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    text = data.get("content", data.get("text", ""))
    if not text:
        return jsonify({"status": "error", "message": "content is required"}), 400

    metadata = {
        "doc_id": data.get("id") or db_manager.generate_doc_id(),
        "title": data.get("title", ""),
        "tags": data.get("tags", ""),
        "date_ref": data.get("date", ""),
        "language": data.get("language", "id"),
    }

    result = _index_document("journal", text, metadata)
    return jsonify(result), 200 if result["status"] == "ok" else 500


@bp.route("/mood", methods=["POST"])
def index_mood():
    """Index a mood tracker entry."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    score = data.get("mood_score", 5)
    parts = [
        f"Mood Score: {score}/10",
        f"Deskripsi: {data.get('description', '')}" if data.get("description") else "",
        f"Tanggal: {data.get('date', '')}",
    ]

    metadata = {
        "doc_id": data.get("id") or db_manager.generate_doc_id(),
        "mood_score": str(score),
        "date_ref": data.get("date", ""),
        "tags": data.get("tags", ""),
        "language": "id",
    }

    result = _index_document("mood", _build_text(parts), metadata)
    return jsonify(result), 200 if result["status"] == "ok" else 500


@bp.route("/batch", methods=["POST"])
def index_batch():
    """Bulk index an array of documents."""
    data = request.get_json(silent=True)
    if not data or not isinstance(data, list):
        return jsonify({"status": "error", "message": "Expected JSON array"}), 400

    results = {"success": 0, "failed": 0, "doc_ids": []}

    for item in data:
        source_type = item.get("source_type", "music")
        title = item.get("title", "")
        artist = item.get("artist", "")

        parts = [
            f"Judul: {title}",
            f"Artis: {artist}" if artist else "",
            f"Album: {item.get('album', '')}" if item.get("album") else "",
        ]

        text = _build_text(parts)
        metadata = {
            "doc_id": item.get("id") or db_manager.generate_doc_id(),
            "title": title,
            "author_or_artist": artist,
            "language": "mixed",
        }

        res = _index_document(source_type, text, metadata)
        if res["status"] == "ok":
            results["success"] += 1
            results["doc_ids"].extend(res["data"]["doc_ids"])
        else:
            results["failed"] += 1

    return jsonify({"status": "ok", "data": results}), 200


@bp.route("/update/<doc_id>", methods=["PUT"])
def update_document(doc_id):
    """Update an existing document."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"status": "error", "message": "Invalid JSON"}), 400

    data["doc_id"] = doc_id
    source_type = data.get("source_type", "music")

    # Rebuild text from data
    text = data.get("text", _build_text([
        data.get("title", ""),
        data.get("artist", data.get("author", "")),
        data.get("content", ""),
    ]))

    metadata = {k: v for k, v in data.items() if k != "text"}
    result = _index_document(source_type, text, metadata)
    return jsonify(result), 200 if result["status"] == "ok" else 500


@bp.route("/delete/<doc_id>", methods=["DELETE"])
def delete_document_endpoint(doc_id):
    """Delete a document by ID."""
    success = db_manager.delete_document(doc_id)
    if success:
        return jsonify({"status": "ok", "data": {"deleted": doc_id}}), 200
    return jsonify({"status": "error", "message": "Delete failed"}), 500


@bp.route("/reindex_all", methods=["POST"])
def reindex_all():
    """Re-embed all documents (useful when embedding model changes)."""
    col = db_manager.get_collection()
    if col is None:
        return jsonify({"status": "error", "message": "DB unavailable"}), 500

    count = col.count()
    if count == 0:
        return jsonify({"status": "ok", "data": {"reindexed": 0}}), 200

    # Run in background
    def _do_reindex():
        try:
            all_docs = col.get(include=["documents", "metadatas"])
            reindexed = 0
            for i, doc_id in enumerate(all_docs["ids"]):
                text = all_docs["documents"][i] if all_docs["documents"] else ""
                if not text:
                    continue
                embedding = gemini_client.embed_text(text)
                if embedding:
                    meta = all_docs["metadatas"][i] if all_docs["metadatas"] else {}
                    col.update(
                        ids=[doc_id],
                        embeddings=[embedding],
                        metadatas=[meta],
                    )
                    reindexed += 1
            logger.info(f"Reindexed {reindexed}/{count} documents")
        except Exception as e:
            logger.error(f"Reindex error: {e}")

    threading.Thread(target=_do_reindex, daemon=True).start()
    return jsonify({"status": "ok", "data": {"message": f"Reindexing {count} docs in background"}}), 200
