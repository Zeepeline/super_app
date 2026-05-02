"""
rag.py — Flask blueprint for RAG chat & search endpoints.
Implements hybrid retrieval (semantic + metadata filter) with re-ranking
and intent-based prompt templates.
"""

import logging
from datetime import datetime, timedelta

from flask import Blueprint, request, jsonify

from modules import db_manager, gemini_client, query_analyzer, preprocessor
import config

logger = logging.getLogger("rag")

bp = Blueprint("rag", __name__, url_prefix="/rag")


# ========== RE-RANKING ==========
def rerank(query, results, analysis):
    """
    Re-rank results based on:
    - Recency: newer documents get a boost
    - Tag match: query keywords in document tags
    - Status match: e.g., query about "done" boosts done items
    - Distance inversion: lower distance = higher score
    """
    keywords = analysis.get("keywords", [])
    intent = analysis.get("intent", "search")

    scored = []
    for item in results:
        meta = item.get("metadata", {})
        distance = item.get("distance", 1.0)

        # Base score (invert distance: 0 distance = 1.0 score)
        score = max(0, 1.0 - distance)

        # Recency boost
        updated = meta.get("updated_at", "")
        if updated:
            try:
                dt = datetime.fromisoformat(updated)
                days_old = (datetime.utcnow() - dt).days
                if days_old < 7:
                    score += config.RERANK_RECENCY_BOOST
                elif days_old < 30:
                    score += config.RERANK_RECENCY_BOOST * 0.5
            except (ValueError, TypeError):
                pass

        # Tag match boost
        tags = meta.get("tags", "").lower()
        if tags and keywords:
            matching = sum(1 for kw in keywords if kw in tags)
            score += matching * config.RERANK_TAG_MATCH_BOOST

        # Title/artist keyword boost
        title = meta.get("title", "").lower()
        artist = meta.get("author_or_artist", "").lower()
        if keywords:
            for kw in keywords:
                if kw in title:
                    score += 0.2
                if kw in artist:
                    score += 0.2

        # Status match boost
        status = meta.get("status", "").lower()
        query_lower = query.lower()
        if status:
            if "selesai" in query_lower and status in ("done", "finished"):
                score += config.RERANK_STATUS_MATCH_BOOST
            elif "pending" in query_lower and status == "pending":
                score += config.RERANK_STATUS_MATCH_BOOST

        item["score"] = score
        scored.append(item)

    # Sort by score descending
    scored.sort(key=lambda x: x["score"], reverse=True)
    return scored


def _build_context(results):
    """Build context string from retrieval results for the prompt."""
    if not results:
        return "Tidak ada data relevan ditemukan di database."

    context = f"Ditemukan {len(results)} data relevan:\n\n"
    for i, item in enumerate(results, 1):
        meta = item.get("metadata", {})
        source = meta.get("source_type", "unknown")
        title = meta.get("title", "")
        artist = meta.get("author_or_artist", "")
        text = item.get("text", "")

        context += f"--- Data #{i} [{source}] ---\n"
        if title:
            context += f"Judul: {title}\n"
        if artist:
            context += f"Artis/Penulis: {artist}\n"
        if text:
            preview = text[:300] + "..." if len(text) > 300 else text
            context += f"Detail: {preview}\n"

        # Add relevant metadata
        for key in ["genre", "tags", "status", "mood_score", "rating", "date_ref"]:
            val = meta.get(key, "")
            if val:
                context += f"{key}: {val}\n"

        context += "\n"

    return context


def _build_prompt(query, context, intent):
    """Build the final prompt using intent-based templates."""
    template = config.PROMPT_TEMPLATES.get(intent, config.PROMPT_TEMPLATES["search"])
    return template.format(context=context, query=query)


# ========== ENDPOINTS ==========

@bp.route("/chat", methods=["POST"])
def rag_chat():
    """
    Main RAG chat endpoint.
    Flow: analyze query → retrieve → rerank → build prompt → return context.
    
    Note: Actual LLM generation is done by Flutter/Dart side (GeminiService).
    This endpoint returns the augmented prompt with context.
    """
    data = request.get_json(silent=True)
    if not data or "query" not in data:
        return jsonify({"status": "error", "message": "query is required"}), 400

    query = data["query"]

    # 1. Analyze query
    analysis = query_analyzer.analyze_query(query)
    logger.info(f"Query analysis: {analysis}")

    # 2. Preprocess query for embedding
    processed = preprocessor.preprocess(query, lang=analysis.get("language", "id"))
    search_text = " ".join(processed) if processed else query

    # 3. Embed query
    query_embedding = gemini_client.embed_text(search_text)

    results = []
    if query_embedding:
        # 4. Build metadata filter
        where_filter = None
        detected = analysis.get("detected_types", [])
        if detected and len(detected) < len(config.DOC_TYPES):
            if len(detected) == 1:
                where_filter = {"source_type": detected[0]}
            else:
                where_filter = {"source_type": {"$in": detected}}

        # 5. Retrieve from ChromaDB
        results = db_manager.query_similar(
            query_embedding=query_embedding,
            n_results=config.DEFAULT_TOP_K * 2,  # Get extra for reranking
            where_filter=where_filter,
        )

        # 6. Re-rank
        results = rerank(query, results, analysis)
        results = results[:config.DEFAULT_TOP_K]  # Trim to top-K

    # 7. Build context & prompt
    context = _build_context(results)
    intent = analysis.get("intent", "search")
    augmented_prompt = _build_prompt(query, context, intent)

    return jsonify({
        "status": "ok",
        "data": {
            "context": augmented_prompt,
            "intent": intent,
            "detected_types": analysis.get("detected_types", []),
            "num_results": len(results),
        },
    }), 200


@bp.route("/search", methods=["POST"])
def rag_search():
    """Pure similarity search — returns raw results without prompt building."""
    data = request.get_json(silent=True)
    if not data or "query" not in data:
        return jsonify({"status": "error", "message": "query is required"}), 400

    query = data["query"]
    n = data.get("n_results", config.DEFAULT_TOP_K)

    # Embed & search
    processed = preprocessor.preprocess(query)
    search_text = " ".join(processed) if processed else query
    query_embedding = gemini_client.embed_text(search_text)

    if not query_embedding:
        return jsonify({"status": "error", "message": "Embedding failed"}), 500

    # Optional filter
    where_filter = None
    source_type = data.get("source_type")
    if source_type:
        where_filter = {"source_type": source_type}

    results = db_manager.query_similar(
        query_embedding=query_embedding,
        n_results=n,
        where_filter=where_filter,
    )

    return jsonify({
        "status": "ok",
        "data": {
            "results": results,
            "count": len(results),
        },
    }), 200


@bp.route("/stats", methods=["GET"])
def rag_stats():
    """Get collection statistics."""
    stats = db_manager.get_stats()
    return jsonify({"status": "ok", "data": stats}), 200


@bp.route("/analyze_pattern", methods=["POST"])
def analyze_pattern():
    """Analyze patterns from user data."""
    data = request.get_json(silent=True)
    if not data or "query" not in data:
        return jsonify({"status": "error", "message": "query is required"}), 400

    query = data["query"]
    analysis = query_analyzer.analyze_query(query)
    analysis["intent"] = "analyze"

    # Get more results for pattern analysis
    processed = preprocessor.preprocess(query)
    search_text = " ".join(processed) if processed else query
    query_embedding = gemini_client.embed_text(search_text)

    results = []
    if query_embedding:
        results = db_manager.query_similar(
            query_embedding=query_embedding,
            n_results=20,  # More results for analysis
        )

    context = _build_context(results)
    prompt = _build_prompt(query, context, "analyze")

    return jsonify({
        "status": "ok",
        "data": {"context": prompt, "num_results": len(results)},
    }), 200


@bp.route("/recommendations/music", methods=["GET"])
def recommend_music():
    """Music recommendations based on recent context."""
    # Get recent mood/journal entries for context
    col = db_manager.get_collection()
    if col is None:
        return jsonify({"status": "error", "message": "DB unavailable"}), 500

    # Search for mood-related content
    search_text = "rekomendasi musik suasana hati mood"
    embedding = gemini_client.embed_text(search_text)

    results = []
    if embedding:
        results = db_manager.query_similar(
            query_embedding=embedding,
            n_results=10,
        )

    context = _build_context(results)
    prompt = _build_prompt(
        "Rekomendasikan musik dari library user berdasarkan konteks terkini",
        context,
        "recommend",
    )

    return jsonify({"status": "ok", "data": {"context": prompt}}), 200


@bp.route("/recommendations/books", methods=["GET"])
def recommend_books():
    """Book recommendations based on reading history."""
    search_text = "rekomendasi buku bacaan selanjutnya"
    embedding = gemini_client.embed_text(search_text)

    results = []
    if embedding:
        results = db_manager.query_similar(
            query_embedding=embedding,
            n_results=10,
            where_filter={"source_type": "book"},
        )

    context = _build_context(results)
    prompt = _build_prompt(
        "Rekomendasikan buku selanjutnya berdasarkan riwayat bacaan user",
        context,
        "recommend",
    )

    return jsonify({"status": "ok", "data": {"context": prompt}}), 200


@bp.route("/daily_summary", methods=["GET"])
def daily_summary():
    """Generate daily summary context."""
    search_text = "hari ini ringkasan todo mood jurnal"
    embedding = gemini_client.embed_text(search_text)

    results = []
    if embedding:
        # Get all types for cross-data summary
        results = db_manager.query_similar(
            query_embedding=embedding,
            n_results=15,
        )

    context = _build_context(results)
    prompt = _build_prompt(
        "Buat ringkasan hari ini berdasarkan data user",
        context,
        "analyze",
    )

    return jsonify({"status": "ok", "data": {"context": prompt}}), 200
