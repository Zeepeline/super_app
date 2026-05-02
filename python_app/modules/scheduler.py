"""
scheduler.py — Background tasks for daily enrichment.
Uses threading.Timer for lightweight scheduling (no heavy deps).
"""

import logging
import threading
from datetime import datetime

from modules import enricher, db_manager, gemini_client

logger = logging.getLogger("scheduler")

_timer = None
_INTERVAL_HOURS = 12  # Run every 12 hours


def start():
    """Start the background scheduler."""
    logger.info("Scheduler started")
    _schedule_next()


def stop():
    """Stop the scheduler."""
    global _timer
    if _timer:
        _timer.cancel()
        _timer = None
    logger.info("Scheduler stopped")


def _schedule_next():
    """Schedule the next run."""
    global _timer
    _timer = threading.Timer(_INTERVAL_HOURS * 3600, _run_tasks)
    _timer.daemon = True
    _timer.start()


def _run_tasks():
    """Execute all scheduled tasks."""
    logger.info("Running scheduled tasks...")

    try:
        _fetch_and_index_daily_context()
    except Exception as e:
        logger.error(f"Daily context task failed: {e}")

    # Schedule next run
    _schedule_next()


def _fetch_and_index_daily_context():
    """Fetch daily quote & holidays, index to ChromaDB."""
    data = enricher.fetch_daily_context()
    if not data:
        logger.warning("No daily context data fetched")
        return

    today = data.get("date", datetime.utcnow().strftime("%Y-%m-%d"))

    # Build text
    parts = [f"Tanggal: {today}"]
    if data.get("quote"):
        parts.append(f"Quote of the day: \"{data['quote']}\" — {data.get('quote_author', 'Unknown')}")
    if data.get("holiday_today"):
        parts.append(f"Hari libur hari ini: {data['holiday_today']}")

    text = " | ".join(parts)

    # Embed and store
    embedding = gemini_client.embed_text(text)
    if embedding:
        doc_id = f"daily_{today}"
        db_manager.upsert_document(
            doc_id=doc_id,
            text=text,
            embedding=embedding,
            source_type="daily_context",
            metadata={
                "date_ref": today,
                "title": f"Daily Context {today}",
            },
        )
        logger.info(f"Indexed daily context for {today}")
    else:
        logger.warning("Failed to embed daily context")


def run_once_now():
    """Run the daily tasks immediately (useful for setup)."""
    threading.Thread(target=_run_tasks, daemon=True).start()
