"""
db_manager.py — ChromaDB singleton & CRUD utilities.
Handles persistent vector storage with backup/recovery.
"""

import os
import json
import shutil
import logging
import uuid
from datetime import datetime

try:
    import chromadb
    from chromadb.config import Settings
except ImportError:
    chromadb = None

import config

logger = logging.getLogger("db_manager")

_client = None
_collection = None


def get_client():
    """Get or create ChromaDB PersistentClient singleton."""
    global _client
    if _client is None:
        if chromadb is None:
            logger.error("chromadb not installed")
            return None
        try:
            _client = chromadb.PersistentClient(
                path=config.CHROMA_DIR,
                settings=Settings(anonymized_telemetry=False),
            )
            logger.info(f"ChromaDB client initialized at {config.CHROMA_DIR}")
        except Exception as e:
            logger.error(f"Failed to init ChromaDB: {e}")
            # Attempt recovery
            _try_recover()
            try:
                _client = chromadb.PersistentClient(
                    path=config.CHROMA_DIR,
                    settings=Settings(anonymized_telemetry=False),
                )
            except Exception as e2:
                logger.error(f"Recovery failed: {e2}")
                return None
    return _client


def get_collection():
    """Get or create the main RAG collection."""
    global _collection
    if _collection is not None:
        return _collection

    client = get_client()
    if client is None:
        return None

    try:
        _collection = client.get_or_create_collection(
            name=config.CHROMA_COLLECTION_NAME,
            metadata={"hnsw:space": config.CHROMA_DISTANCE_FN},
        )
        logger.info(
            f"Collection '{config.CHROMA_COLLECTION_NAME}' ready "
            f"({_collection.count()} docs)"
        )
        return _collection
    except Exception as e:
        logger.error(f"Failed to get collection: {e}")
        return None


def generate_doc_id():
    """Generate a UUID v4 for document identification."""
    return str(uuid.uuid4())


def upsert_document(
    doc_id,
    text,
    embedding,
    source_type,
    metadata=None,
):
    """Insert or update a document in ChromaDB."""
    col = get_collection()
    if col is None:
        return False

    now = datetime.utcnow().isoformat()
    meta = {
        "doc_id": doc_id,
        "source_type": source_type,
        "updated_at": now,
        "text_preview": text[:100] if text else "",
    }

    if metadata:
        # Flatten metadata — ChromaDB only supports str/int/float/bool
        for k, v in metadata.items():
            if v is not None:
                meta[k] = str(v) if not isinstance(v, (int, float, bool)) else v

    # Set created_at only if new
    try:
        existing = col.get(ids=[doc_id])
        if existing and existing["ids"]:
            old_meta = existing["metadatas"][0] if existing["metadatas"] else {}
            meta["created_at"] = old_meta.get("created_at", now)
        else:
            meta["created_at"] = now
    except Exception:
        meta["created_at"] = now

    try:
        col.upsert(
            ids=[doc_id],
            documents=[text],
            embeddings=[embedding],
            metadatas=[meta],
        )
        logger.info(f"Upserted doc {doc_id} ({source_type})")
        return True
    except Exception as e:
        logger.error(f"Upsert failed for {doc_id}: {e}")
        return False


def delete_document(doc_id):
    """Delete a document from ChromaDB by its ID."""
    col = get_collection()
    if col is None:
        return False
    try:
        col.delete(ids=[doc_id])
        logger.info(f"Deleted doc {doc_id}")
        return True
    except Exception as e:
        logger.error(f"Delete failed for {doc_id}: {e}")
        return False


def query_similar(
    query_embedding,
    n_results=None,
    where_filter=None,
):
    """Query ChromaDB for similar documents."""
    col = get_collection()
    if col is None:
        return []

    n = n_results or config.DEFAULT_TOP_K

    try:
        kwargs = {
            "query_embeddings": [query_embedding],
            "n_results": min(n, col.count()) if col.count() > 0 else 1,
            "include": ["documents", "metadatas", "distances"],
        }
        if where_filter:
            kwargs["where"] = where_filter

        results = col.query(**kwargs)

        # Flatten results into a list of dicts
        items = []
        if results and results["ids"] and results["ids"][0]:
            for i, doc_id in enumerate(results["ids"][0]):
                items.append({
                    "doc_id": doc_id,
                    "text": results["documents"][0][i] if results["documents"] else "",
                    "metadata": results["metadatas"][0][i] if results["metadatas"] else {},
                    "distance": results["distances"][0][i] if results["distances"] else 1.0,
                })
        return items
    except Exception as e:
        logger.error(f"Query failed: {e}")
        return []


def get_stats():
    """Get collection statistics."""
    col = get_collection()
    if col is None:
        return {"status": "unavailable", "count": 0}

    try:
        count = col.count()
        # Count by source_type
        type_counts = {}
        for dtype in config.DOC_TYPES:
            try:
                res = col.get(where={"source_type": dtype}, include=[])
                type_counts[dtype] = len(res["ids"]) if res and res["ids"] else 0
            except Exception:
                type_counts[dtype] = 0

        return {
            "status": "ok",
            "total_documents": count,
            "by_type": type_counts,
        }
    except Exception as e:
        logger.error(f"Stats failed: {e}")
        return {"status": "error", "count": 0, "error": str(e)}


def backup_db():
    """Create a backup of the ChromaDB directory."""
    backup_dir = config.CHROMA_DIR + "_backup"
    try:
        if os.path.exists(backup_dir):
            shutil.rmtree(backup_dir)
        if os.path.exists(config.CHROMA_DIR):
            shutil.copytree(config.CHROMA_DIR, backup_dir)
            logger.info(f"DB backed up to {backup_dir}")
            return True
    except Exception as e:
        logger.warning(f"Backup failed: {e}")
    return False


def _try_recover():
    """Attempt to recover ChromaDB from backup."""
    backup_dir = config.CHROMA_DIR + "_backup"
    if os.path.exists(backup_dir):
        try:
            if os.path.exists(config.CHROMA_DIR):
                shutil.rmtree(config.CHROMA_DIR)
            shutil.copytree(backup_dir, config.CHROMA_DIR)
            logger.info("DB recovered from backup")
        except Exception as e:
            logger.error(f"Recovery from backup failed: {e}")
    else:
        # No backup — just recreate fresh
        if os.path.exists(config.CHROMA_DIR):
            shutil.rmtree(config.CHROMA_DIR)
        os.makedirs(config.CHROMA_DIR, exist_ok=True)
        logger.warning("No backup found, recreated fresh DB")
